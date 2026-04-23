import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

initializeApp();

const db = getFirestore();
const discordWebhookUrl = defineSecret("DISCORD_WEBHOOK_URL");
const sendGridApiKey = defineSecret("SENDGRID_API_KEY");
const feedbackToEmail = defineSecret("FEEDBACK_TO_EMAIL");
const feedbackFromEmail = defineSecret("FEEDBACK_FROM_EMAIL");
const RATE_LIMIT_SECONDS = 10;

type NotificationType =
  | "join"
  | "registered_app_on_join"
  | "app_registered"
  | "test_joined"
  | "test_ended"
  | "app_start"
  | "app_end";

type RequestData = {
  type?: unknown;
  userName?: unknown;
  appName?: unknown;
  appDescription?: unknown;
  playUrl?: unknown;
  message?: unknown;
};

type FeedbackRequestData = {
  message?: unknown;
};

type AdminBroadcastData = {
  title?: unknown;
  body?: unknown;
};

function asSafeText(value: unknown, maxLength = 1000): string {
  if (typeof value !== "string") {
    return "";
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return "";
  }
  const collapsed = trimmed.replace(/\s+/g, " ");
  const noMassMentions = collapsed
    .replace(/@everyone/gi, "[everyone]")
    .replace(/@here/gi, "[here]");
  return noMassMentions.slice(0, maxLength);
}

function assertType(value: unknown): NotificationType {
  const allowed: NotificationType[] = [
    "join",
    "registered_app_on_join",
    "app_registered",
    "test_joined",
    "test_ended",
    "app_start",
    "app_end",
  ];
  if (typeof value !== "string" || !allowed.includes(value as NotificationType)) {
    throw new HttpsError("invalid-argument", "invalid type");
  }
  return value as NotificationType;
}

function buildDiscordContent(type: NotificationType, data: RequestData): string {
  const userName = asSafeText(data.userName, 80) || "\u30e6\u30fc\u30b6\u30fc";
  const appName = asSafeText(data.appName, 120) || "\u30a2\u30d7\u30ea";
  const appDescription = asSafeText(data.appDescription, 1000);
  const playUrl = asSafeText(data.playUrl, 500);
  const extraMessage = asSafeText(data.message, 1000);

  if (extraMessage) {
    return extraMessage;
  }

  switch (type) {
    case "join":
      return `\u{1F389} ${userName} \u3055\u3093\u304cDiscord\u306b\u53c2\u52a0\u3057\u307e\u3057\u305f`;
    case "registered_app_on_join": {
      const summary = appDescription || "\uff08\u672a\u5165\u529b\uff09";
      return `\u{1F195} ${userName} \u3055\u3093\u304c\u767b\u9332\u3057\u305f\u30c6\u30b9\u30c8\u30a2\u30d7\u30ea: ${appName} ${playUrl}\n\u30c6\u30b9\u30c8\u6982\u8981: ${summary}`;
    }
    case "app_registered":
    case "app_start":
      return `\u{1F195} \u65b0\u3057\u3044\u30c6\u30b9\u30c8\u30a2\u30d7\u30ea\u304c\u767b\u9332\u3055\u308c\u307e\u3057\u305f: ${appName} ${playUrl}`;
    case "test_joined":
      return `\u{1F389} ${userName} \u304c ${appName} \u306e\u30c6\u30b9\u30c8\u306b\u53c2\u52a0\u3057\u307e\u3057\u305f`;
    case "test_ended":
    case "app_end":
      return `\u2705 ${userName} \u304c ${appName} \u306e\u30c6\u30b9\u30c8\u3092\u7d42\u4e86\u3057\u307e\u3057\u305f`;
  }
}

async function enforceRateLimit(userId: string): Promise<void> {
  const rateDocRef = db.collection("discordRateLimits").doc(userId);
  const now = Timestamp.now();
  const nowMs = now.toMillis();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(rateDocRef);
    const lastSentAt = snap.get("lastSentAt") as Timestamp | undefined;
    if (lastSentAt) {
      const diffMs = nowMs - lastSentAt.toMillis();
      if (diffMs < RATE_LIMIT_SECONDS * 1000) {
        throw new HttpsError("resource-exhausted", "rate limit exceeded");
      }
    }
    tx.set(
      rateDocRef,
      {
        lastSentAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
  });
}

export const sendDiscordNotification = onCall(
  {
    region: "asia-northeast1",
    secrets: [discordWebhookUrl],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const type = assertType(request.data?.type);
    const content = buildDiscordContent(type, request.data as RequestData);
    if (content.length < 1 || content.length > 1000) {
      throw new HttpsError("invalid-argument", "content length must be 1-1000");
    }

    await enforceRateLimit(request.auth.uid);

    const url = discordWebhookUrl.value();
    if (!url) {
      console.error("DISCORD_WEBHOOK_URL is not set");
      return { ok: false, error: "webhook not configured" };
    }

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify({
          content,
          allowed_mentions: {
            parse: [],
          },
        }),
      });

      if (!response.ok) {
        const body = await response.text();
        console.error("Discord webhook failed", {
          status: response.status,
          body,
          uid: request.auth.uid,
          type,
        });
        return { ok: false, error: `discord_http_${response.status}` };
      }

      console.log("Discord webhook sent", {
        uid: request.auth.uid,
        type,
      });
      return { ok: true };
    } catch (error) {
      console.error("Discord webhook error", {
        error,
        uid: request.auth.uid,
        type,
      });
      return { ok: false, error: "network_error" };
    }
  },
);

export const submitAdminFeedback = onCall(
  {
    region: "asia-northeast1",
    secrets: [sendGridApiKey, feedbackToEmail, feedbackFromEmail],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const message = asSafeText(
      (request.data as FeedbackRequestData | undefined)?.message,
      2000,
    );
    if (!message) {
      throw new HttpsError("invalid-argument", "message is required");
    }

    const userId = request.auth.uid;
    const userDoc = await db.collection("users").doc(userId).get();
    const usernameRaw = userDoc.get("username");
    const username = asSafeText(usernameRaw, 80) || "ユーザー";

    const subject = `[HIRAKU] ご意見箱 from ${username}`;
    const textBody = [
      "HIRAKU ご意見箱",
      `userId: ${userId}`,
      `username: ${username}`,
      "",
      "message:",
      message,
    ].join("\n");

    const toEmail = feedbackToEmail.value();
    const fromEmail = feedbackFromEmail.value();
    const apiKey = sendGridApiKey.value();

    if (!toEmail || !fromEmail || !apiKey) {
      console.error("Feedback email secrets are missing");
      throw new HttpsError("failed-precondition", "email config missing");
    }

    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: toEmail }] }],
        from: { email: fromEmail },
        subject,
        content: [{ type: "text/plain", value: textBody }],
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      console.error("SendGrid failed", {
        status: response.status,
        body,
        userId,
      });
      throw new HttpsError("internal", "email send failed");
    }

    await db.collection("adminFeedback").add({
      userId,
      username,
      message,
      createdAt: Timestamp.now(),
      status: "sent_to_email",
    });

    return { ok: true };
  },
);

export const publishAdminBroadcast = onDocumentCreated(
  {
    region: "asia-northeast1",
    document: "adminBroadcasts/{broadcastId}",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const raw = snapshot.data() as AdminBroadcastData;
    const title = asSafeText(raw.title, 80) || "HIRAKUからのお知らせ";
    const body = asSafeText(raw.body, 400);
    const broadcastId = event.params.broadcastId;

    if (!body) {
      await snapshot.ref.set(
        {
          status: "invalid",
          reason: "body is required",
          processedAt: Timestamp.now(),
        },
        { merge: true },
      );
      return;
    }

    const createdAt = Timestamp.now();
    const usersSnapshot = await db.collection("users").get();

    let batch = db.batch();
    let ops = 0;
    let written = 0;

    for (const userDoc of usersSnapshot.docs) {
      const notificationRef = userDoc.ref.collection("adminNotifications").doc();
      batch.set(notificationRef, {
        title,
        body,
        createdAt,
        isRead: false,
        sourceBroadcastId: broadcastId,
      });
      ops += 1;
      written += 1;

      if (ops >= 450) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }

    if (ops > 0) {
      await batch.commit();
    }

    await getMessaging().send({
      topic: "hiraku_all",
      notification: {
        title,
        body,
      },
      data: {
        kind: "admin_broadcast",
        broadcastId,
      },
    });

    await snapshot.ref.set(
      {
        status: "published",
        notifiedUserCount: written,
        processedAt: Timestamp.now(),
      },
      { merge: true },
    );
  },
);
