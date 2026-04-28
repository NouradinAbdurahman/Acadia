import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { JWT } from "npm:google-auth-library@9.0.0";

serve(async (req: Request) => {
  try {
    const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountStr) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT is not set");
    }
    const trimmedServiceAccount = serviceAccountStr.trim();
    const normalizedServiceAccount =
      (trimmedServiceAccount.startsWith("'") && trimmedServiceAccount.endsWith("'")) ||
      (trimmedServiceAccount.startsWith('"') && trimmedServiceAccount.endsWith('"'))
        ? trimmedServiceAccount.slice(1, -1)
        : trimmedServiceAccount;
    const serviceAccount = JSON.parse(normalizedServiceAccount);
    
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const body = await req.json();
    console.log("RAW BODY:", body);
    const { token, title, body: messageBody, type, referenceId, priority } = body;
    
    const { access_token } = await jwtClient.authorize();
    const projectId = serviceAccount.project_id;
    
    const message = {
      message: {
        token: token,
        notification: {
          title: title,
          body: messageBody,
        },
        android: {
          priority: priority === "HIGH" ? "HIGH" : "NORMAL",
        },
        data: {
          type: type || "default",
          id: referenceId || "",
        },
      },
    };

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${access_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      }
    );
    
    const fcmText = await response.text();
    return new Response(
      JSON.stringify({
        ok: response.ok,
        status: response.status,
        fcmResponse: fcmText,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    )
  }
})
