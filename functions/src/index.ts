import * as admin from "firebase-admin";
import { onDocumentWritten, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

/**
 * Trigger when any game document is written.
 * Detects when a game goes from full -> has open spot,
 * then notifies all users currently on the waitlist.
 * All waitlisted users get the same notification - first to join gets the spot.
 */
export const notifyWaitlistOnSpotOpen = onDocumentWritten(
  {
    document: "games/{gameId}",
    region: "us-east1",
  },
  async (event) => {
    const beforeSnap = event.data?.before;
    const afterSnap = event.data?.after;

    if (!beforeSnap || !afterSnap || !beforeSnap.exists || !afterSnap.exists) {
      // Ignore creates/deletes for now – only handle updates.
      return;
    }

    const before = beforeSnap.data() as any;
    const after = afterSnap.data() as any;

    if (!before || !after) return;

    const beforeParticipants: string[] = before.participants || [];
    const afterParticipants: string[] = after.participants || [];
    const maxPlayers: number = after.maxPlayers || 0;
    const waitlist: string[] = after.waitlist || [];
    const title: string = after.title || "Your game";

    // Was full before, now has at least one free spot
    const wasFull = beforeParticipants.length >= (before.maxPlayers || maxPlayers);
    const nowHasSpot = afterParticipants.length < maxPlayers;

    if (!wasFull || !nowHasSpot) {
      // No transition from full -> has spot, nothing to do
      return;
    }

    if (waitlist.length === 0) {
      // Nobody on waitlist to notify
      return;
    }

    const db = admin.firestore();
    const userDocs = await Promise.all(
      waitlist.map((uid) => db.collection("users").doc(uid).get())
    );

    const tokens: string[] = [];
    for (const doc of userDocs) {
      if (!doc.exists) continue;
      const data = doc.data() || {};
      const userTokens: string[] = data.fcmTokens || [];
      tokens.push(...userTokens);
    }

    const uniqueTokens = Array.from(new Set(tokens)).filter(Boolean);
    if (uniqueTokens.length === 0) {
      console.log("No FCM tokens found for waitlisted users");
      return;
    }

    const message = {
      notification: {
        title: "A spot just opened!",
        body: `A spot is available in "${title}". Join quickly - first come, first served!`,
      },
      data: {
        type: "spot_open",
        gameId: afterSnap.id,
        title,
      },
      tokens: uniqueTokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `Sent spot_open notification to ${uniqueTokens.length} tokens. Success: ${response.successCount}, Failures: ${response.failureCount}`
      );
    } catch (err) {
      console.error("Error sending spot_open notification:", err);
    }
  }
);

/**
 * Send push notifications whenever a new notification document is created
 * in Firestore at notifications/{notificationId}.
 *
 * This enables OUTSIDE-APP notifications for:
 * - player joined
 * - player left
 * - waitlist promoted
 * - game start reminders
 * - any future notification types
 */
export const sendPushNotification = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: "us-east1",
  },
  async (event:any) => {
    const snap = event.data;
    if (!snap) return;

    const notif = snap.data() as any;
    const userId: string = notif.userId;
    const message: string = notif.message ?? "";
    const type: string = notif.type ?? "";
    const gameId: string | undefined = notif.gameId;

    console.log(`[sendPushNotification] New notification created for user=${userId}`);

    const db = admin.firestore();
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.log(`[sendPushNotification] User ${userId} not found.`);
      return;
    }

    const userData = userDoc.data() || {};
    const tokens: string[] = userData.fcmTokens || [];

    if (!tokens.length) {
      console.log(`[sendPushNotification] User ${userId} has no FCM tokens.`);
      return;
    }

    const payload = {
      tokens,
      notification: {
        title: "GameLink",
        body: message,
      },
      data: {
        type,
        gameId: gameId ?? "",
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(payload);
      console.log(
        `[sendPushNotification] Sent to ${tokens.length} tokens. Success=${response.successCount}, Failure=${response.failureCount}`
      );
    } catch (err) {
      console.error("[sendPushNotification] Error sending push:", err);
    }
  }
);

/**
 * Scheduled function: send game start reminders ~1 hour before start.
 *
 * Runs every 5 minutes, finds games starting in the next hour
 * that have not had reminders sent yet, and pushes a notification
 * to all participants.
 */
export const sendGameStartReminders = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "us-east1",
  },
  async (event: any) => {
    const db = admin.firestore();
    const now = new Date();

    // Window: games starting between now and 1 hour from now
    const inOneHour = new Date(now.getTime() + 60 * 60 * 1000);

    // Small buffer to avoid double-sending if clock jitters
    const tenMinutesAgo = new Date(now.getTime() - 10 * 60 * 1000);

    console.log(
      `[sendGameStartReminders] Checking games between ${tenMinutesAgo.toISOString()} and ${inOneHour.toISOString()}`
    );

    const gamesSnap = await db
      .collection("games")
      .where("date", ">=", tenMinutesAgo)
      .where("date", "<=", inOneHour)
      .get();

    if (gamesSnap.empty) {
      console.log("[sendGameStartReminders] No games in window.");
      return;
    }

    for (const gameDoc of gamesSnap.docs) {
      const gameData = gameDoc.data() as any;

      // Skip cancelled games or games that already had reminders
      if (gameData.isCancelled) {
        continue;
      }
      if (gameData.reminderSent === true) {
        continue;
      }

      const title: string = gameData.title || "Your game";
      const participants: string[] = gameData.participants || [];

      if (!participants.length) {
        console.log(
          `[sendGameStartReminders] Game ${gameDoc.id} has no participants. Skipping.`
        );
        continue;
      }

      // Collect tokens for all participants
      const userDocs = await Promise.all(
        participants.map((uid) => db.collection("users").doc(uid).get())
      );

      const tokens: string[] = [];
      for (const userDoc of userDocs) {
        if (!userDoc.exists) continue;
        const userData = userDoc.data() || {};
        const userTokens: string[] = userData.fcmTokens || [];
        tokens.push(...userTokens);
      }

      const uniqueTokens = Array.from(new Set(tokens)).filter(Boolean);
      if (!uniqueTokens.length) {
        console.log(
          `[sendGameStartReminders] No FCM tokens found for participants of game ${gameDoc.id}.`
        );
        // Still mark reminderSent to avoid repeated checks
        await gameDoc.ref.update({ reminderSent: true });
        continue;
      }

      const payload = {
        tokens: uniqueTokens,
        notification: {
          title: "Game starting soon",
          body: `Your game "${title}" starts in about an hour.`,
        },
        data: {
          type: "game_start_reminder",
          gameId: gameDoc.id,
        },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(payload);
        console.log(
          `[sendGameStartReminders] Game ${gameDoc.id}: sent reminders to ${uniqueTokens.length} tokens. Success=${response.successCount}, Failure=${response.failureCount}`
        );

        // Mark that reminders were sent so we don't send again
        await gameDoc.ref.update({ reminderSent: true });
      } catch (err) {
        console.error(
          `[sendGameStartReminders] Error sending reminders for game ${gameDoc.id}:`,
          err
        );
      }
    }
  }
);

