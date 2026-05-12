# Supabase Setup

L'app utilise maintenant Supabase a la place de Firebase.

## 1. Creer le projet Supabase

1. Va sur <https://supabase.com/dashboard>.
2. Cree un projet.
3. Garde ces deux valeurs :
   - `Project URL`
   - `anon public key`

Dans Xcode, remplace les placeholders Info.plist generes :

```text
SUPABASE_URL = https://TON_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY = TON_ANON_PUBLIC_KEY
```

Ces valeurs sont dans `Target epitasign > Build Settings`, recherche `SUPABASE`.

## 2. Ajouter le SDK Supabase dans Xcode

Dans Xcode :

```text
File > Add Package Dependencies...
```

URL :

```text
https://github.com/supabase/supabase-swift
```

Ajoute le produit :

```text
Supabase
```

a la target :

```text
epitasign
```

## 3. Configurer Auth

Dans Supabase Dashboard :

```text
Authentication > Providers > Email
```

Active Email.

Puis cree un utilisateur de test avec une adresse :

```text
prenom.nom@epita.fr
```

L'app refuse les emails qui ne finissent pas par `@epita.fr`.

## 4. Appliquer le schema SQL

Installe le CLI Supabase si besoin :

```bash
npm install -g supabase
```

Depuis la racine du repo :

```bash
supabase login
supabase link --project-ref TON_PROJECT_REF
supabase db push
```

Le schema est dans :

```text
supabase/migrations/20260512120000_initial_schema.sql
```

Il cree :

- `profiles`
- `student_cards`
- `courses`
- `attendance_tokens`
- `attendance_records`
- bucket Storage prive `signatures`
- policies RLS

## 5. Configurer le secret de hash NFC

Ta carte est detectee comme :

```text
ISO 14443-3A / MIFARE DESFire EV3
UID: 04:82:62:72:4A:1C:90
```

Sans les cles de l'ecole, on ne lit probablement pas le contenu chiffre DESFire. L'app lit donc l'identifiant NFC disponible, et Supabase compare un hash cote serveur.

Configure le secret :

```bash
supabase secrets set CARD_HASH_PEPPER="UNE_LONGUE_VALEUR_SECRETE"
```

Calcule le hash de ta carte :

```bash
cd supabase
node scripts/hash-card.js "04:82:62:72:4A:1C:90" "UNE_LONGUE_VALEUR_SECRETE"
```

## 6. Ajouter les donnees minimales

Dans Supabase SQL Editor, apres creation de ton utilisateur Auth, recupere son UUID puis execute :

```sql
insert into public.profiles (id, email, role)
values (
  'UUID_UTILISATEUR_AUTH',
  'prenom.nom@epita.fr',
  'student'
);

insert into public.student_cards (user_id, tag_hash, label)
values (
  'UUID_UTILISATEUR_AUTH',
  'HASH_DE_LA_CARTE',
  'Carte etudiante'
);

insert into public.courses (id, title, room, starts_at, ends_at)
values (
  'mock-ios-course',
  'Programmation iOS',
  'B312',
  now() - interval '10 minutes',
  now() + interval '90 minutes'
);
```

Pour mettre quelqu'un prof :

```sql
update public.profiles
set role = 'teacher'
where email = 'prof@epita.fr';
```

## 7. Deployer les Edge Functions

Depuis la racine du repo :

```bash
supabase functions deploy request-attendance-token
supabase functions deploy submit-attendance-signature
```

## 8. NFC cote Apple

J'ai deja ajoute :

- `NFCReaderUsageDescription`
- entitlement `com.apple.developer.nfc.readersession.formats = TAG`

Dans Xcode, verifie aussi :

```text
Target epitasign > Signing & Capabilities > Near Field Communication Tag Reading
```

Le scan doit etre teste sur un vrai iPhone.
