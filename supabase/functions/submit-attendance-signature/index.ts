import {createClient} from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {corsHeaders} from "../_shared/cors.ts";

type Payload = {
  courseId?: string;
  tokenId?: string;
  signatureBase64PNG?: string;
  signatureMetrics?: {
    pointCount?: number;
    duration?: number;
    width?: number;
    height?: number;
  };
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {headers: corsHeaders});
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Connexion requise.");

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {global: {headers: {Authorization: authHeader}}}
    );

    const {data: userData, error: userError} = await supabase.auth.getUser();
    if (userError || !userData.user) throw new Error("Utilisateur invalide.");

    const email = userData.user.email?.toLowerCase() ?? "";
    if (!email.endsWith("@epita.fr")) throw new Error("Adresse EPITA requise.");

    const payload = await req.json() as Payload;
    const courseId = requireString(payload.courseId, "courseId");
    const tokenId = requireString(payload.tokenId, "tokenId");
    const signatureBase64PNG = requireString(payload.signatureBase64PNG, "signatureBase64PNG");
    validateSignatureMetrics(payload.signatureMetrics);

    const {data: token, error: tokenError} = await supabase
      .from("attendance_tokens")
      .select("id,user_id,course_id,expires_at,used_at")
      .eq("id", tokenId)
      .maybeSingle();

    if (tokenError || !token) throw new Error("Token introuvable.");
    if (token.user_id !== userData.user.id || token.course_id !== courseId || token.used_at) {
      throw new Error("Token invalide.");
    }
    if (new Date(token.expires_at).getTime() < Date.now()) {
      throw new Error("Token expire.");
    }

    const recordId = crypto.randomUUID();
    const signatureStoragePath = `${userData.user.id}/${recordId}.png`;
    const signatureBytes = Uint8Array.from(atob(signatureBase64PNG), (char) => char.charCodeAt(0));
    if (signatureBytes.byteLength < 300) throw new Error("Signature vide ou invalide.");

    const {error: uploadError} = await supabase.storage
      .from("signatures")
      .upload(signatureStoragePath, signatureBytes, {
        contentType: "image/png",
        upsert: false,
      });

    if (uploadError) throw new Error("Upload signature impossible.");

    const {error: tokenUpdateError} = await supabase
      .from("attendance_tokens")
      .update({used_at: new Date().toISOString()})
      .eq("id", tokenId)
      .is("used_at", null);

    if (tokenUpdateError) throw new Error("Token deja utilise.");

    const {error: recordError} = await supabase
      .from("attendance_records")
      .insert({
        id: recordId,
        user_id: userData.user.id,
        course_id: courseId,
        token_id: tokenId,
        status: "signed",
        signature_storage_path: signatureStoragePath,
        signature_metrics: payload.signatureMetrics,
      });

    if (recordError) throw new Error("Creation presence impossible.");

    return json({
      attendanceRecordId: recordId,
      signatureStoragePath,
    });
  } catch (error) {
    return json({error: String(error instanceof Error ? error.message : error)}, 400);
  }
});

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`Champ ${field} manquant.`);
  }

  return value.trim();
}

function validateSignatureMetrics(metrics: Payload["signatureMetrics"]): void {
  if (
    !metrics ||
    typeof metrics.pointCount !== "number" ||
    typeof metrics.duration !== "number" ||
    typeof metrics.width !== "number" ||
    typeof metrics.height !== "number" ||
    metrics.pointCount < 32 ||
    metrics.duration <= 0.5 ||
    Math.max(metrics.width, metrics.height) < 250
  ) {
    throw new Error("Signature insuffisante.");
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {...corsHeaders, "Content-Type": "application/json"},
  });
}
