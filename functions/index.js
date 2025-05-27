const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// تهيئة Firebase Admin إذا لم تكن مهيأة بالفعل
if (!admin.apps.length) {
  admin.initializeApp();
}

// إشعار العروض الجديدة
exports.sendOfferNotification = onDocumentCreated(
  'offers/{offerId}',
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log('No snapshot data—skipping.');
      return;
    }

    const data = snap.data();
    const productId = event.params.offerId;
    const title = data?.title ?? '';
    const description = data?.description ?? '';
    const price = data?.price?.toString() ?? '';

    console.log('▶ New offer:', { productId, title, description, price });

    const message = {
      topic: 'offers',
      notification: {
        title: `عرض جديد: ${title}`,
        body: description,
      },
      data: {
        productId,
        title,
        price,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: 'offer',
      },
      android: {
        priority: 'HIGH',
      },
    };

    try {
      await admin.firestore()
        .collection('notifications')
        .doc(productId)
        .set({
          productId,
          title,
          description,
          price,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          type: 'offer',
        });

      const resp = await admin.messaging().send(message);
      console.log('✅ Offer notification sent:', resp);
    } catch (err) {
      console.error('❌ Error sending offer notification:', err);
    }

    return null;
  }
);

// إشعار الطلبات الجديدة للمزارعين
exports.sendFarmerOrderNotification = onDocumentCreated(
  'users/{farmerId}/farmer_orders/{orderId}',
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log('No farmer order snapshot data—skipping.');
      return;
    }

    const orderData = snap.data();
    const farmerId = event.params.farmerId;
    const orderId = event.params.orderId;

    console.log('▶ New farmer order:', { farmerId, orderId });

    try {
      // استخراج بيانات الطلب
      const userData = orderData?.userData || {};
      const cartItems = orderData?.cartItems || [];
      const buyerName = userData.name || 'مشتري';
      const buyerPhone = userData.phone || '';
      const itemCount = cartItems.length;
      
      // حساب المجموع الكلي
      const totalPrice = cartItems.reduce((sum, item) => {
        return sum + (item.totalPrice || 0);
      }, 0);

      // الحصول على FCM token للمزارع
      const farmerDoc = await admin.firestore()
        .collection('users')
        .doc(farmerId)
        .get();

      if (!farmerDoc.exists) {
        console.log(`Farmer ${farmerId} not found`);
        return;
      }

      const farmerData = farmerDoc.data();
      const fcmToken = farmerData?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token found for farmer ${farmerId}`);
        return;
      }

      // إعداد رسالة الإشعار
      const notificationTitle = 'طلب جديد وارد!';
      const notificationBody = `طلب جديد من ${buyerName} - ${itemCount} منتج بقيمة ${totalPrice} دينار`;
console.log(`📲 FCM token to notify: ${fcmToken}`);

      const message = {
        token: fcmToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          orderId: orderId,
          farmerId: farmerId,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          itemCount: itemCount.toString(),
          totalPrice: totalPrice.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'farmer_order',
          screen: 'farmer_orders',
        },
        android: {
          priority: 'HIGH',
          notification: {
            icon: '@mipmap/ic_launcher',
            color: '#2196F3',
            sound: 'default',
            channelId: 'farmer_orders_channel',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              alert: {
                title: notificationTitle,
                body: notificationBody,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // إرسال الإشعار
      const response = await admin.messaging().send(message);
      console.log('✅ Farmer order notification sent:', response);

      // حفظ الإشعار في قاعدة البيانات للمزارع
      await admin.firestore()
        .collection('users')
        .doc(farmerId)
        .collection('notifications')
        .doc(orderId)
        .set({
          orderId: orderId,
          title: notificationTitle,
          body: notificationBody,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          itemCount: itemCount,
          totalPrice: totalPrice,
          isRead: false,
          type: 'farmer_order',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log('✅ Farmer order notification saved to database');

    } catch (error) {
      
      console.error('❌ Error sending farmer order notification:', error);
    }

    return null;
  }

);