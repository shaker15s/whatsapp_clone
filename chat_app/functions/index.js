const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * لما رسالة جديدة تتبعت، بيبعت push notification حقيقي للطرف التاني
 * حتى لو التطبيق مقفول تمامًا.
 */
exports.onNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const chatId = event.params.chatId;

    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    const participants = chatDoc.data().participants;
    const recipientId = participants.find((id) => id !== message.senderId);

    const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
    const fcmToken = recipientDoc.data()?.fcmToken;
    if (!fcmToken) return;

    const senderDoc = await admin.firestore().collection("users").doc(message.senderId).get();
    const senderName = senderDoc.data()?.username || "حد ما";

    let body;
    switch (message.type) {
      case "image": body = "📷 صورة"; break;
      case "audio": body = "🎤 رسالة صوتية"; break;
      case "location": body = "📍 شارك موقعه"; break;
      default: body = message.content;
    }

    await admin.messaging().send({
      token: fcmToken,
      notification: { title: senderName, body },
      data: { chatId, type: "message" },
      android: { priority: "high" },
    });
  }
);

/**
 * لما مكالمة جديدة تتعمل (status: ringing)، بيبعت إشعار عالي الأولوية
 * (data-only) عشان التطبيق يقدر يعرض شاشة "مكالمة واردة" حتى لو مقفول.
 */
exports.onNewCall = onDocumentCreated("calls/{callId}", async (event) => {
  const call = event.data.data();
  if (call.status !== "ringing") return;

  const calleeDoc = await admin.firestore().collection("users").doc(call.calleeId).get();
  const fcmToken = calleeDoc.data()?.fcmToken;
  if (!fcmToken) return;

  const callerDoc = await admin.firestore().collection("users").doc(call.callerId).get();
  const callerName = callerDoc.data()?.username || "حد ما";

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: call.type === "video" ? "مكالمة فيديو واردة" : "مكالمة صوتية واردة",
      body: callerName,
    },
    data: { callId: event.params.callId, type: "call" },
    android: { priority: "high" },
  });
});
