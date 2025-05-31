const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// تهيئة Firebase Admin إذا لم تكن مهيأة بالفعل
if (!admin.apps.length) {
  admin.initializeApp();
}

const ADMIN_EMAIL = 'ahmed.roma22@gmail.com';

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
      // إرسال الإشعار للعامة
      const resp = await admin.messaging().send(message);
      console.log('✅ Offer notification sent:', resp);

      // حفظ الإشعار لجميع المستخدمين في sub-collections
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      const batch = admin.firestore().batch();
      
      usersSnapshot.docs.forEach(userDoc => {
        const notificationRef = admin.firestore()
          .collection('users')
          .doc(userDoc.id)
          .collection('notifications')
          .doc(productId);
        
        batch.set(notificationRef, {
          productId,
          title,
          description,
          price,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          type: 'offer',
        });
      });

      await batch.commit();
      console.log('✅ Offer notifications saved to all users sub-collections');

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
      const isCustomProductOrder = orderData?.is_custom_product_order || false;
      const isAdminNotification = orderData?.admin_notification || false;
      
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

      // تخصيص رسالة الإشعار حسب نوع الطلب
      let notificationTitle = 'طلب جديد وارد!';
      let notificationBody = `طلب جديد من ${buyerName} - ${itemCount} منتج بقيمة ${totalPrice} دينار`;
      
      if (isCustomProductOrder && isAdminNotification) {
        notificationTitle = 'طلب منتج مخصص جديد!';
        notificationBody = `طلب منتج مخصص من ${buyerName} - ${itemCount} منتج بقيمة ${totalPrice} دينار`;
      }

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
          isCustomProductOrder: isCustomProductOrder.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: isCustomProductOrder && isAdminNotification ? 'admin_custom_order' : 'farmer_order',
          screen: 'farmer_orders',
        },
        android: {
          priority: 'HIGH',
          notification: {
            icon: '@mipmap/ic_launcher',
            color: isCustomProductOrder && isAdminNotification ? '#FF6B35' : '#2196F3', // لون مختلف للطلبات المخصصة
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

      // حفظ الإشعار في sub-collection للمزارع/الأدمن
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
          type: isCustomProductOrder && isAdminNotification ? 'admin_custom_order' : 'farmer_order',
          isCustomProductOrder: isCustomProductOrder,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ ${isCustomProductOrder && isAdminNotification ? 'Admin custom product' : 'Farmer'} order notification saved to sub-collection`);

      // إذا كان هذا طلب منتج مخصص، تأكد من إرسال إشعار للأدمن أيضاً
      if (isCustomProductOrder && !isAdminNotification) {
        await sendNotificationToAdmin(orderId, orderData);
      }

    } catch (error) {
      console.error('❌ Error sending farmer order notification:', error);
    }

    return null;
  }
);

// دالة مساعدة لإرسال إشعار للأدمن
async function sendNotificationToAdmin(orderId, orderData) {
  try {
    // البحث عن الأدمن
    const adminQuery = await admin.firestore()
      .collection('users')
      .where('email', '==', ADMIN_EMAIL)
      .limit(1)
      .get();

    if (adminQuery.empty) {
      console.log('Admin not found');
      return;
    }

    const adminDoc = adminQuery.docs[0];
    const adminId = adminDoc.id;
    const adminData = adminDoc.data();
    const adminFcmToken = adminData?.fcmToken;

    if (!adminFcmToken) {
      console.log('No FCM token found for admin');
      return;
    }

    // إعداد رسالة الإشعار للأدمن
    const userData = orderData?.userData || {};
    const cartItems = orderData?.cartItems || [];
    const buyerName = userData.name || 'مشتري';
    const itemCount = cartItems.length;
    const totalPrice = cartItems.reduce((sum, item) => {
      return sum + (item.totalPrice || 0);
    }, 0);

    const adminMessage = {
      token: adminFcmToken,
      notification: {
        title: 'طلب منتج مخصص جديد!',
        body: `طلب منتج مخصص من ${buyerName} - ${itemCount} منتج بقيمة ${totalPrice} دينار`,
      },
      data: {
        orderId: orderId,
        buyerName: buyerName,
        itemCount: itemCount.toString(),
        totalPrice: totalPrice.toString(),
        isCustomProductOrder: 'true',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: 'admin_custom_order',
        screen: 'farmer_orders',
      },
      android: {
        priority: 'HIGH',
        notification: {
          icon: '@mipmap/ic_launcher',
          color: '#FF6B35', // لون برتقالي للطلبات المخصصة
          sound: 'default',
          channelId: 'admin_orders_channel',
        },
      },
    };

    // إرسال الإشعار للأدمن
    const adminResponse = await admin.messaging().send(adminMessage);
    console.log('✅ Admin notification sent for custom product order:', adminResponse);

  } catch (error) {
    console.error('❌ Error sending admin notification:', error);
  }
}