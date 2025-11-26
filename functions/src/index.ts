import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

admin.initializeApp();

/**
 * Trigger when any game document is written.
 * Detects when a game goes from full -> has open spot,
 * then notifies all users currently on the waitlist.
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
        body: `A spot is now available in "${title}".`,
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