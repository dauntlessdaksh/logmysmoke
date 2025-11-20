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

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
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
    // NEW API: Uses .send() instead of .sendToDevice()
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

async function runScheduled(mode: "motivation" | "reminder") {
  const snapshot = await usersCol
    .where("notificationsEnabled", "==", true)
    .get();
  
  const batchPromises: Promise<any>[] = [];

  snapshot.forEach((doc) => {
    const data = doc.data();
    const token = data.fcmToken as string | undefined;
    if (!token) return;

    if (mode === "motivation") {
      const motivations = Array.isArray(data.motivations)
        ? data.motivations
        : [];
      const message = motivations.length
        ? pickRandom(motivations)
        : "Keep going — you are doing great!";
      
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
// PRODUCTION SCHEDULES
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

// ============================================================
// TEST FUNCTION (Every 1 Min)
// ============================================================
