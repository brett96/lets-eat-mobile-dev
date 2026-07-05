/**
 * Cloud Functions for "Let's Eat!" push notifications.
 *
 * The Flutter client handles permission, FCM-token registration (stored in
 * `users/{uid}.fcmTokens`), and receiving messages. These functions are the
 * server-side *send* half:
 *   - notify group members when a new chat message is posted
 *   - notify group members when a vote resolves to a winning restaurant
 *
 * Deploy with:  firebase deploy --only functions
 */
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();

/**
 * Collects the FCM tokens of every member of a group except `excludeUid`.
 */
async function tokensForGroup(
  memberUids: string[],
  excludeUid?: string
): Promise<string[]> {
  const recipients = memberUids.filter((uid) => uid !== excludeUid);
  if (recipients.length === 0) return [];

  const userDocs = await db.getAll(
    ...recipients.map((uid) => db.doc(`users/${uid}`))
  );

  const tokens: string[] = [];
  for (const doc of userDocs) {
    const list = (doc.get("fcmTokens") as string[] | undefined) ?? [];
    tokens.push(...list);
  }
  // De-duplicate.
  return [...new Set(tokens)];
}

/**
 * Removes tokens that FCM reports as invalid/unregistered so the stored set
 * doesn't grow stale.
 */
async function pruneInvalidTokens(
  memberUids: string[],
  invalidTokens: string[]
): Promise<void> {
  if (invalidTokens.length === 0) return;
  const invalid = new Set(invalidTokens);
  await Promise.all(
    memberUids.map(async (uid) => {
      const ref = db.doc(`users/${uid}`);
      const snap = await ref.get();
      const list = (snap.get("fcmTokens") as string[] | undefined) ?? [];
      const kept = list.filter((t) => !invalid.has(t));
      if (kept.length !== list.length) {
        await ref.update({ fcmTokens: kept });
      }
    })
  );
}

async function sendToTokens(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
  memberUids: string[]
): Promise<void> {
  if (tokens.length === 0) return;
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: "high" },
  });

  const invalid: string[] = [];
  response.responses.forEach((r, i) => {
    if (
      !r.success &&
      (r.error?.code === "messaging/registration-token-not-registered" ||
        r.error?.code === "messaging/invalid-registration-token")
    ) {
      invalid.push(tokens[i]);
    }
  });
  await pruneInvalidTokens(memberUids, invalid);
  logger.info(
    `Sent ${response.successCount}/${tokens.length} notifications; pruned ${invalid.length} stale tokens.`
  );
}

/** New group chat message -> notify the other members. */
export const onGroupMessage = onDocumentCreated(
  "groups/{groupId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const groupSnap = await db.doc(`groups/${event.params.groupId}`).get();
    const memberUids = (groupSnap.get("memberUids") as string[]) ?? [];
    const groupName = (groupSnap.get("name") as string) ?? "Your group";
    const senderUid = message.senderUid as string;
    const senderName = (message.senderName as string) ?? "Someone";
    const text = (message.text as string) ?? "";

    const tokens = await tokensForGroup(memberUids, senderUid);
    await sendToTokens(
      tokens,
      groupName,
      `${senderName}: ${text}`,
      { type: "chat", groupId: event.params.groupId },
      memberUids
    );
  }
);

/** Group vote resolves to a winner -> notify all members. */
export const onGroupResult = onDocumentUpdated(
  "groups/{groupId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const newResult = after.resultRestaurantId as string | undefined;
    // Only fire on a fresh, non-empty result.
    if (!newResult || newResult === before.resultRestaurantId) return;

    const memberUids = (after.memberUids as string[]) ?? [];
    const groupName = (after.name as string) ?? "Your group";

    const tokens = await tokensForGroup(memberUids);
    await sendToTokens(
      tokens,
      groupName,
      "The group picked a restaurant! Tap to see where you're eating.",
      { type: "result", groupId: event.params.groupId },
      memberUids
    );
  }
);
