import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp();

export const sendGroupMessageNotification = functions.database
  .ref("/groups/{groupId}/messages/{messageId}")
  .onCreate(async (snapshot: functions.database.DataSnapshot, context: functions.EventContext) => {
    const message = snapshot.val();
    const groupId = context.params.groupId;
    const senderId = message.senderId;

    // Grup üyelerini al
    const groupSnap = await admin.database().ref(`/groups/${groupId}/members`).once("value");
    const members = groupSnap.val() ? Object.keys(groupSnap.val()) : [];

    // Her üyeye (gönderen hariç) push gönder
    for (const userId of members) {
      if (userId === senderId) continue;
      const userSnap = await admin.database().ref(`/users/${userId}/fcmToken`).once("value");
      const fcmToken = userSnap.val();
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Yeni Grup Mesajı",
            body: `${message.senderName}: ${message.content}`,
          },
          data: {
            groupId,
            messageId: message.id,
          },
        });
      }
    }
    return null;
  });

export const sendNotificationOnNewNotification = functions.database
  .ref("/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.val();
    const userId = notification.userId;
    const title = notification.title;
    const body = notification.body;
    const data = notification.data || {};

    // Kullanıcının FCM tokenını al
    const tokenSnap = await admin.database().ref(`users/${userId}/fcmToken`).once("value");
    const fcmToken = tokenSnap.val();
    if (!fcmToken) {
      console.log("FCM token bulunamadı:", userId);
      return null;
    }

    // Push bildirimi gönder
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    });
    console.log("Push bildirimi gönderildi:", userId, title);
    return null;
  });
