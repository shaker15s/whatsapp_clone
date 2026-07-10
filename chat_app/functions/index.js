const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const AGORA_APP_ID = process.env.AGORA_APP_ID || "";
const AGORA_APP_CERT = process.env.AGORA_APP_CERT || "";

// ─── Notifications ─────────────────────────────────────────────────────

/**
 * When a new message is created, push notifications to the recipient
 * even when the app is fully closed.
 */
exports.onNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const chatId = event.params.chatId;

    const chatDoc = await admin
      .firestore()
      .collection("chats")
      .doc(chatId)
      .get();
    const participants = chatDoc.data()?.participants || [];
    const recipientId = participants.find((id) => id !== message.senderId);
    if (!recipientId) return;

    const recipientDoc = await admin
      .firestore()
      .collection("users")
      .doc(recipientId)
      .get();
    const fcmToken = recipientDoc.data()?.fcmToken;
    if (!fcmToken) return;

    const senderDoc = await admin
      .firestore()
      .collection("users")
      .doc(message.senderId)
      .get();
    const senderName = senderDoc.data()?.name || "حد ما";

    let body;
    switch (message.type) {
      case "image":
        body = "📷 صورة";
        break;
      case "audio":
        body = "🎤 رسالة صوتية";
        break;
      case "location":
        body = "📍 شارك موقعه";
        break;
      default:
        body = message.content;
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
 * When a new call document is created (status: ringing), push a high-priority
 * data-only notification so the app can show an "incoming call" screen
 * even when fully closed.
 */
exports.onNewCall = onDocumentCreated("calls/{callId}", async (event) => {
  const call = event.data.data();
  if (call.status !== "ringing") return;

  const calleeDoc = await admin
    .firestore()
    .collection("users")
    .doc(call.calleeId)
    .get();
  const fcmToken = calleeDoc.data()?.fcmToken;
  if (!fcmToken) return;

  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(call.callerId)
    .get();
  const callerName = callerDoc.data()?.name || "حد ما";

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title:
        call.type === "video"
          ? "مكالمة فيديو واردة"
          : "مكالمة صوتية واردة",
      body: callerName,
    },
    data: { callId: event.params.callId, type: "call" },
    android: { priority: "high" },
  });
});

// ─── Agora Token Server ─────────────────────────────────────────────────

/**
 * Generates an Agora RTC token for voice/video calls.
 * The token is scoped to a specific channel + user, expires in 2 hours.
 *
 * Call from the client:
 *   final token = await FirebaseFunctions.instance
 *       .httpsCallable('getAgoraToken').call({'channel': 'chatId', 'uid': myUid});
 */
exports.getAgoraToken = onCall(async (request) => {
  // Auth check
  if (!request.auth) {
    throw new Error("Unauthenticated");
  }

  const uid = request.auth.uid;
  const channel = request.data?.channel || "default";
  const uidParam = request.data?.uid || uid;

  if (!AGORA_APP_ID || !AGORA_APP_CERT) {
    console.error("Agora credentials not configured. Set AGORA_APP_ID and AGORA_APP_CERT env vars.");
    throw new Error("Server misconfigured: Agora credentials missing.");
  }

  try {
    // Dynamic import of the Agora token builder
    const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

    const expirationTimeInSeconds = 3600; // 1 hour
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERT,
      channel,
      uidParam,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    return {
      token,
      appId: AGORA_APP_ID,
      channel,
      uid: uidParam,
    };
  } catch (err) {
    console.error("Agora token generation failed:", err);
    throw new Error("Failed to generate Agora token.");
  }
});
