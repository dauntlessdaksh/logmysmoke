import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const usersCol = db.collection("users");

const REMINDERS = [
  "Remember to log your cigarette — every log helps you quit!",
  "Quick reminder: log your cigarette intake for today.",
  "Tracking helps: please record any cigarettes you smoked today.",
  "Small step: open LogMySmoke and log your cigarette if you've smoked.",
  "A gentle nudge: don't forget to log your smoking today.",
  "Track the wins: please log any cigarettes today.",
  "Logging keeps you accountable — add your smoke now.",
  "Your progress matters — quickly log your cigarette.",
  "Record it — it helps you beat the habit.",
  "Don't forget to log — your future self will thank you.",
];

function pickRandom<T>(arr: T[]) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/**
 * Helper: Truncate text if user types a very long motivation.
 */
function truncateText(text: string, maxLength: number = 120): string {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + "...";
}

/**
 * Helper - send a notification using the NEW HTTP v1 API
 */
async function sendNotificationToToken(
  token: string,
  title: string,
  body: string,
  type: string
) {
  try {
    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type, 
      },
    };

    const res = await admin.messaging().send(message);
    console.log("Successfully sent message:", res);
    return res;
  } catch (e) {
    console.error("sendNotification error", e);
    return null;
  }
}

/**
 * CORE LOGIC: Iterates through ALL users with notifications enabled.
 */
async function runScheduled(mode: "motivation" | "reminder") {
  const snapshot = await usersCol
    .where("notificationsEnabled", "==", true)
    .get();
  
  const batchPromises: Promise<any>[] = [];

  console.log(`Processing ${snapshot.size} users.`);

  snapshot.forEach((doc) => {
    const data = doc.data();
    const token = data.fcmToken as string | undefined;
    
    if (!token) return;

    if (mode === "motivation") {
      const motivations = Array.isArray(data.motivations)
        ? (data.motivations as string[]) 
        : [];
      
      let message = motivations.length
        ? pickRandom(motivations)
        : "Keep going — you are doing great!";
      
      message = truncateText(message);

      batchPromises.push(
        sendNotificationToToken(token, "Motivation", message, "motivation")
      );
    } else {
      const message = pickRandom(REMINDERS);
      batchPromises.push(
        sendNotificationToToken(token, "Reminder", message, "reminder")
      );
    }
  });

  await Promise.all(batchPromises);
}

// ============================================================
// 1. EXPLICIT CALLABLE FUNCTION (NEW)
// ============================================================
// Called directly from Flutter. No race conditions.
export const triggerWelcome = functions.https.onCall(async (data, context) => {
  // 1. Security: Ensure user is logged in
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be logged in to trigger notifications."
    );
  }

  const userId = context.auth.uid;
  console.log(`Explicit welcome trigger for user: ${userId}`);

  // 2. Fetch the user's token from Firestore
  const userDoc = await usersCol.doc(userId).get();
  const userData = userDoc.data();
  const token = userData?.fcmToken;

  if (!token) {
    console.log("No token found for user.");
    return { success: false, message: "No token found" };
  }

  // 3. Send the notification
  await sendNotificationToToken(
    token,
    "Welcome to LogMySmoke",
    "Remember why you started. We are here to help!",
    "welcome"
  );

  return { success: true };
});


// ============================================================
// 2. SCHEDULED TASKS
// ============================================================

export const sendMorningMotivation = functions.pubsub
  .schedule("0 9 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("sendMorningMotivation running");
    await runScheduled("motivation");
    return null;
  });

export const sendMiddayReminder = functions.pubsub
  .schedule("0 12 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("sendMiddayReminder running");
    await runScheduled("reminder");
    return null;
  });

export const sendEveningMotivation = functions.pubsub
  .schedule("0 17 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("sendEveningMotivation running");
    await runScheduled("motivation");
    return null;
  });

export const sendNightReminder = functions.pubsub
  .schedule("0 20 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("sendNightReminder running");
    await runScheduled("reminder");
    return null;
  });