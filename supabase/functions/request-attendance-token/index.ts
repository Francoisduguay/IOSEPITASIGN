import {createClient} from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {corsHeaders} from "../_shared/cors.ts";
import {sha256Hex} from "../_shared/crypto.ts";

type Payload = {
  courseId?: string;
  tagIdentifier?: string;
  tagType?: string;
  technologies?: string[];
  scannedAt?: string;
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
    const tagIdentifier = requireString(payload.tagIdentifier, "tagIdentifier").toUpperCase();
    const pepper = Deno.env.get("CARD_HASH_PEPPER");
    if (!pepper) throw new Error("CARD_HASH_PEPPER manquant.");

    const tagHash = await sha256Hex(`${pepper}:${tagIdentifier}`);

    const {data: card, error: cardError} = await supabase
      .from("student_cards")
      .select("id")
      .eq("user_id", userData.user.id)
      .eq("tag_hash", tagHash)
      .maybeSingle();

    if (cardError || !card) throw new Error("Cette carte n'est pas rattachee au compte.");

    const {data: course, error: courseError} = await supabase
      .from("courses")
      .select("id")
      .eq("id", courseId)
      .maybeSingle();

    if (courseError || !course) throw new Error("Cours introuvable.");

    const expiresAt = new Date(Date.now() + 120_000);
    const {data: token, error: tokenError} = await supabase
      .from("attendance_tokens")
      .insert({
        user_id: userData.user.id,
        course_id: courseId,
        tag_hash: tagHash,
        tag_type: payload.tagType ?? null,
        technologies: Array.isArray(payload.technologies) ? payload.technologies : [],
        expires_at: expiresAt.toISOString(),
      })
      .select("id")
      .single();

    if (tokenError || !token) throw new Error("Impossible de creer le token.");

    return json({
      tokenId: token.id,
      expiresAt: expiresAt.getTime(),
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

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {...corsHeaders, "Content-Type": "application/json"},
  });
}
