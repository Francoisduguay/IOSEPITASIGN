# Firebase Setup

Cette app est maintenant structuree pour utiliser Firebase Auth, Cloud Functions, Firestore et Storage.

## 1. Creer le projet Firebase

1. Va sur <https://console.firebase.google.com>.
2. Cree un projet, par exemple `epitasign`.
3. Ajoute une app iOS.
4. Mets le bundle ID actuel du projet Xcode : `com.test.epitasign`.
5. Telecharge `GoogleService-Info.plist`.
6. Ajoute ce fichier dans le dossier `epitasign/` via Xcode, avec la target `epitasign` cochee.

## 2. Ajouter les SDK Firebase dans Xcode

Dans Xcode :

1. `File > Add Package Dependencies`.
2. URL :

```text
https://github.com/firebase/firebase-ios-sdk
```

3. Ajoute au target `epitasign` :
   - `FirebaseAuth`
   - `FirebaseFunctions`
   - `FirebaseCore`

Le code compile aussi sans ces SDK, mais il utilise alors les mocks.

## 3. Activer Firebase Auth

Dans Firebase Console :

1. `Authentication > Sign-in method`.
2. Active `Email/Password`.
3. Cree un utilisateur avec une adresse `@epita.fr`.

L'app refuse les emails qui ne finissent pas par `@epita.fr`.

## 4. Creer Firestore et Storage

Dans Firebase Console :

1. Cree Firestore en mode production.
2. Cree Storage.
3. Les rules sont dans :
   - `firebase/firestore.rules`
   - `firebase/storage.rules`

## 5. Installer Firebase CLI

Depuis le dossier `firebase/` :

```bash
npm install -g firebase-tools
firebase login
firebase use --add
```

Copie ensuite :

```bash
cp .firebaserc.example .firebaserc
```

Puis remplace `TON_PROJECT_ID_FIREBASE` par l'id du projet Firebase.

## 6. Configurer le hash des cartes

Le backend ne stocke pas l'UID NFC brut. Il stocke un hash :

```text
sha256(CARD_HASH_PEPPER + ":" + UID_CARTE)
```

Configure le secret :

```bash
firebase functions:params:set CARD_HASH_PEPPER
```

Mets une valeur longue et secrete.

Pour calculer le hash d'une carte a mettre dans `studentCardHashes` :

```bash
node scripts/hash-card.js "04:82:62:72:4A:1C:90" "TON_CARD_HASH_PEPPER"
```

## 7. Deployer le backend

Depuis le dossier `firebase/` :

```bash
cd functions
npm install
cd ..
firebase deploy --only functions,firestore:rules,storage
```

## 8. Donnees Firestore minimales

Il faut creer ces documents.

### `users/{uid}`

```json
{
  "email": "prenom.nom@epita.fr",
  "role": "student",
  "studentCardHashes": ["HASH_SHA256_DE_LA_CARTE"]
}
```

Pour mettre quelqu'un prof manuellement :

```json
{
  "role": "teacher"
}
```

Pour un admin :

```json
{
  "role": "admin"
}
```

### `courses/mock-ios-course`

```json
{
  "title": "Programmation iOS",
  "room": "B312",
  "startsAt": "timestamp Firebase",
  "endsAt": "timestamp Firebase"
}
```

Pour l'instant l'app envoie `mock-ios-course`. Plus tard, on le remplacera par l'id du cours actif dans l'emploi du temps.

## 9. NFC iPhone

Ta carte est detectee comme :

```text
ISO 14443-3A / MIFARE DESFire EV3
Technologies: Type A, IsoDep
```

L'app utilise `NFCTagReaderSession` avec `iso14443`.

Important : une carte DESFire EV3 est generalement chiffree. Sans les cles de l'ecole, on ne lit pas le contenu securise. L'app lit donc l'identifiant technique disponible, puis le serveur verifie que cette carte est rattachee au compte utilisateur.

## 10. Xcode NFC

J'ai ajoute :

- l'entitlement NFC `TAG`
- `NFCReaderUsageDescription`

Dans Apple Developer / Signing & Capabilities, verifie que `Near Field Communication Tag Reading` est active pour l'App ID.
