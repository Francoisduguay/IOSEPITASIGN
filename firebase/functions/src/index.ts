import {createHash} from "crypto";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineString} from "firebase-functions/params";

initializeApp();

const cardHashPepper = defineString("CARD_HASH_PEPPER");
const tokenTTLSeconds = 120;

type RequestTokenPayload = {
  courseId?: string;
  tagIdentifier?: string;
  tagType?: string;
  technologies?: string[];
  scannedAt?: string;
};

type SubmitSignaturePayload = {
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

export const requestAttendanceToken = onCall(async (request) => {
  const uid = requireUid(request.auth?.uid);
  const email = String(request.auth?.token.email ?? "").toLowerCase();
  requireEpitaEmail(email);

  const data = request.data as RequestTokenPayload;
  const courseId = requireString(data.courseId, "courseId");
  const tagIdentifier = requireString(data.tagIdentifier, "tagIdentifier");

  const db = getFirestore();
  const userSnap = await db.doc(`users/${uid}`).get();

  if (!userSnap.exists) {
    throw new HttpsError("failed-precondition", "Profil utilisateur introuvable.");
  }

  const user = userSnap.data() ?? {};
  const tagHash = hashCardTag(tagIdentifier);
  const allowedCards = Array.isArray(user.studentCardHashes) ? user.studentCardHashes : [];

  if (!allowedCards.includes(tagHash)) {
    throw new HttpsError("permission-denied", "Cette carte n'est pas rattachee a ton compte.");
  }

  const courseSnap = await db.doc(`courses/${courseId}`).get();
  if (!courseSnap.exists) {
    throw new HttpsError("failed-precondition", "Cours introuvable.");
  }

  const expiresAt = Timestamp.fromMillis(Date.now() + tokenTTLSeconds * 1000);
  const tokenRef = db.collection("attendanceTokens").doc();

  await tokenRef.set({
    uid,
    email,
    courseId,
    tagHash,
    tagType: data.tagType ?? null,
    technologies: Array.isArray(data.technologies) ? data.technologies : [],
    scannedAt: data.scannedAt ?? null,
    expiresAt,
    used: false,
    createdAt: FieldValue.serverTimestamp()
  });

  return {
    tokenId: tokenRef.id,
    expiresAt: expiresAt.toMillis()
  };
});

export const submitAttendanceSignature = onCall(async (request) => {
  const uid = requireUid(request.auth?.uid);
  const email = String(request.auth?.token.email ?? "").toLowerCase();
  requireEpitaEmail(email);

  const data = request.data as SubmitSignaturePayload;
  const courseId = requireString(data.courseId, "courseId");
  const tokenId = requireString(data.tokenId, "tokenId");
  const signatureBase64PNG = requireString(data.signatureBase64PNG, "signatureBase64PNG");
  const metrics = data.signatureMetrics ?? {};

  validateSignatureMetrics(metrics);

  const db = getFirestore();
  const tokenRef = db.doc(`attendanceTokens/${tokenId}`);
  const tokenSnap = await tokenRef.get();

  if (!tokenSnap.exists) {
    throw new HttpsError("failed-precondition", "Token introuvable.");
  }

  const token = tokenSnap.data() ?? {};
  const expiresAt = token.expiresAt as Timestamp | undefined;

  if (token.uid !== uid || token.courseId !== courseId || token.used === true) {
    throw new HttpsError("permission-denied", "Token invalide.");
  }

  if (!expiresAt || expiresAt.toMillis() < Date.now()) {
    throw new HttpsError("deadline-exceeded", "Token expire.");
  }

  const recordRef = db.collection("attendanceRecords").doc();
  const signaturePath = `signatures/${uid}/${recordRef.id}.png`;
  const signatureBuffer = Buffer.from(signatureBase64PNG, "base64");

  if (signatureBuffer.byteLength < 300) {
    throw new HttpsError("invalid-argument", "Signature vide ou invalide.");
  }

  await getStorage().bucket().file(signaturePath).save(signatureBuffer, {
    contentType: "image/png",
    resumable: false,
    metadata: {
      cacheControl: "private, max-age=0"
    }
  });

  await db.runTransaction(async (tx) => {
    const freshToken = await tx.get(tokenRef);
    const freshData = freshToken.data() ?? {};

    if (freshData.used === true) {
      throw new HttpsError("permission-denied", "Token deja utilise.");
    }

    tx.update(tokenRef, {
      used: true,
      usedAt: FieldValue.serverTimestamp()
    });

    tx.set(recordRef, {
      uid,
      email,
      courseId,
      tokenId,
      status: "signed",
      signatureStoragePath: signaturePath,
      signatureMetrics: metrics,
      signedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp()
    });
  });

  return {
    attendanceRecordId: recordRef.id,
    signatureStoragePath: signaturePath
  };
});

function requireUid(uid: string | undefined): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }

  return uid;
}

function requireEpitaEmail(email: string): void {
  if (!email.endsWith("@epita.fr")) {
    throw new HttpsError("permission-denied", "Adresse EPITA requise.");
  }
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `Champ ${field} manquant.`);
  }

  return value.trim();
}

function validateSignatureMetrics(metrics: NonNullable<SubmitSignaturePayload["signatureMetrics"]>): void {
  if (
    typeof metrics.pointCount !== "number" ||
    typeof metrics.duration !== "number" ||
    typeof metrics.width !== "number" ||
    typeof metrics.height !== "number" ||
    metrics.pointCount < 32 ||
    metrics.duration <= 0.5 ||
    Math.max(metrics.width, metrics.height) < 250
  ) {
    throw new HttpsError("invalid-argument", "Signature insuffisante.");
  }
}

function hashCardTag(tagIdentifier: string): string {
  return createHash("sha256")
    .update(`${cardHashPepper.value()}:${tagIdentifier.toUpperCase()}`)
    .digest("hex");
}
