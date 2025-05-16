//const functions = require("firebase-functions");
//const { onDocumentCreated } = require('firebase-functions/v2/firestore');
//const admin = require("firebase-admin");
// admin.initializeApp();

// exports.sendOfferNotification = functions.https.onCall(async (data, context) => {
//   try {

//     console.log("البيانات المستلمة:", data);

//     const productId = data?.productId;
//     const title = data?.title;
//     const description = data?.description;
//     const price = data?.price;

 
//     console.log("Product ID:", productId);
//     console.log("العنوان:", title);
//     console.log("الوصف:", description);
//     console.log("السعر:", price);
// const message = {
//   topic: "offers",
//   notification: {
//     title: `عرض جديد: ${title}`,
//     body: description,
//   },
//   data: {
//     productId: productId,
//     title: title,
//     price: price,
//     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//     type: 'offer',
//   },
// };

// /*     // حفظ الإشعار في Firestore
//     await admin.firestore().collection("notifications").doc(cleanProductId).set({
//       cleanProductId,
//       title,
//       description,
//       price,
//       isRead: false,
//       createdAt: admin.firestore.FieldValue.serverTimestamp(),
//       type: "offer",
//     }); */

//     // إرسال إشعار FCM
//     const response = await admin.messaging().send(message);
//     console.log("تم إرسال الإشعار بنجاح:", response);
    
//     return { success: true };
//   } catch (error) {
//     console.error("❌ خطأ:", error);
//     throw new functions.https.HttpsError(
//       "internal", 
//       "فشل الإشعار", 
//       error.message
//     );
//   }
// });
// تهيئة الـ Admin SDK (الإصدار الحديث)
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendOfferNotification = onDocumentCreated(
  'offers/{offerId}',
  async (event) => {
    // 1. المستند الجديد
    const snap = event.data;                     // <-- DocumentSnapshot
    if (!snap) {
      console.log('No snapshot data—skipping.');
      return;
    }

    // 2. بيانات المستند وكود الوثيقة
    const data      = snap.data();               // { title, description, price, ... }
    const productId = event.params.offerId;      // قيمة offerId من المسار

    const title       = data?.title   ?? '';
    const description = data?.description ?? '';
    const price       = data?.price?.toString() ?? '';

    console.log('▶ New offer:', { productId, title, description, price });

    const message = {
  topic: 'offers',
  notification: {
    title: `عرض جديد: ${title}`,
    body: description,
  },
  data: {
    productId, title, price,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    type: 'offer',
  },

  // لو تحتاج أولوية عالية للأندرويد:
  android: {
    priority: 'HIGH',
  },
  
  // ولو تحتاج أولوية عالية للأجهزة بنظام iOS:
  // apns: {
  //   headers: { 'apns-priority': '10' },
  // },
};

    try {
      // 4. (اختياري) خزّن إشعار في Firestore
      await admin.firestore()
        .collection('notifications')
        .doc(productId)
        .set({
          productId, title, description, price,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          type: 'offer',
        });

      // 5. أرسل إشعار FCM
      const resp = await admin.messaging().send(message);
      console.log('✅ Notification sent:', resp);
    } catch (err) {
      console.error('❌ Error sending notification:', err);
    }

    return null;
  }
);