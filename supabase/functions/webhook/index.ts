import { serve } from "https://deno.land/std/http/server.ts";

// base64url 인코딩
function base64UrlEncode(bytes: ArrayBuffer | Uint8Array): string {
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let str = "";
  for (const b of arr) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// PEM 문자열을 ArrayBuffer 로 변환
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "")
    .replace(/\n/g, "")
    .replace(/\\n/g, "");


    console.info("FIREBASE_PRIVATE_KEY b64:", b64);

  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

// RS256 JWT 생성
async function createJwt(): Promise<string> {
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  const privateKeyPem = Deno.env.get("FIREBASE_PRIVATE_KEY");

  if (!clientEmail || !privateKeyPem) {
    throw new Error("FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY not set");
  }

  console.info("FIREBASE_PRIVATE_KEY:", privateKeyPem);

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 60 * 60, // 1시간
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encoder = new TextEncoder();

  const headerB64 = base64UrlEncode(encoder.encode(JSON.stringify(header)));
  const payloadB64 = base64UrlEncode(encoder.encode(JSON.stringify(payload)));

  const unsignedJwt = `${headerB64}.${payloadB64}`;

  const keyBuffer = pemToArrayBuffer(privateKeyPem);

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBuffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(unsignedJwt),
  );

  const signatureB64 = base64UrlEncode(signature);

  return `${unsignedJwt}.${signatureB64}`;
}

// OAuth2 토큰 발급
async function getAccessToken(): Promise<string> {
  const jwt = await createJwt();

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }).toString(),
  });

  const json = await res.json();
  if (!res.ok) {
    console.error("OAuth2 token error:", json);
    throw new Error("Failed to get access token");
  }

  return json.access_token as string;
}

// ----------------------
// 🔥 webhook 시작
// ----------------------
serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("ONLY POST ALLOWED", { status: 405 });
    }

    // 트리거에서 보내온 JSON
    const payload = await req.json();
    console.log("📥 Incoming Webhook Payload:", payload);

    const {
      user_id,
      title,
      body,
      alarm_type,
      item_id,
      room_id,
      token,
    } = payload;

    if (!token) {
      return new Response("Missing FCM token", { status: 400 });
    }

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    if (!projectId) {
      return new Response("Missing FIREBASE_PROJECT_ID", { status: 500 });
    }

    const accessToken = await getAccessToken();

    const fcmEndpoint =
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const messageBody = {
      message: {
        token,
        notification: {
          title: title ?? "알림",
          body: body ?? "",
        },
        data: {
          alarm_type: alarm_type ?? "",
          item_id: item_id ?? "",
          room_id: room_id ?? "",
        },
      },
    };

    const fcmRes = await fetch(fcmEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify(messageBody),
    });

    const fcmText = await fcmRes.text();

    console.log("🔥 FCM STATUS:", fcmRes.status);
    console.log("🔥 FCM RESPONSE:", fcmText);

    return new Response(
      JSON.stringify({
        ok: true,
        fcm_status: fcmRes.status,
        fcm_response: fcmText,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Webhook Error:", err);
    return new Response("Internal Error", { status: 500 });
  }
});
