# EpitaSign

Résumé de l'application pour les enseignants — description fonctionnelle et technique

## Présentation

EpitaSign est une application mobile destinée aux enseignants pour gérer et vérifier les présences et signatures des étudiants lors de sessions (cours, TD, examen). L'interface est conçue pour être simple et sécurisée : l'enseignant scanne la carte NFC de l'étudiant, capture la signature sur l'écran, et soumet une preuve cryptographique de présence vers le backend.

## Fonctionnalités principales (vue enseignant)

- Scanner NFC pour identifier l'étudiant rapidement.
- Capture de la signature manuscrite via un pavé tactile affiché à l'écran.
- Vérification et soumission d'une preuve de signature et d'authenticité au backend.
- Enregistrement horodaté de la présence et du résultat de la vérification.

## Flux technique (comment ça marche réellement)

1. L'enseignant lance la procédure d'appel pour un étudiant.
2. L'application active le module NFC et lit l'identifiant unique (UID) de la carte présentée.
3. L'application demande au backend un jeton d'attestation temporaire (token) lié à la session de présence en cours.
4. L'enseignant fait signer l'étudiant sur l'écran; la signature est capturée sous forme de série de points (vecteurs) puis normalisée.
5. L'application construit une « preuve » locale : on combine la représentation de la signature, l'UID NFC et le token, puis on calcule un résumé cryptographique (hachage) et l'on effectue les opérations cryptographiques nécessaires pour protéger l'intégrité (empreinte hachée, éventuellement signature numérique côté client selon configuration).
6. La preuve est envoyée au backend avec le token et l'UID. Le backend vérifie :
   - que le token est valide et non expiré,
   - que l'UID correspond à un étudiant inscrit pour la session,
   - que la preuve cryptographique est cohérente (hachage/format attendu) et qu'il n'y a pas de rejeu.
7. Si la vérification est OK, le backend enregistre la présence horodatée et retourne un accusé de réception à l'application.

## Sécurité et protections

- Les échanges réseau utilisent TLS (HTTPS).
- Le token d'attestation est court et à usage limité pour éviter les attaques de rejeu.
- Les signatures sont traitées sous forme d'empreinte (hachage) pour minimiser l'exposition de données biométriques.
- Le backend effectue des contrôles d'intégrité et d'association entre UID NFC et token.

## Exigences côté serveur

- Un service backend exposant des endpoints pour obtenir un token d'attestation et pour soumettre la preuve de signature.
- Une base de données d'étudiants avec association UID NFC ↔ identité.
- Logique de vérification cryptographique pour valider les preuves soumises et conserver un historique horodaté.

## Utilisation rapide (pour un enseignant)

1. Ouvrir l'application et sélectionner la séance.
2. Cliquer sur "Prendre la présence" pour l'étudiant.
3. Présenter la carte NFC au lecteur intégré de l'appareil.
4. Demander à l'étudiant de signer sur l'écran.
5. Attendre la confirmation de validation; la présence est alors enregistrée.

## Limites et recommandations

- Si le composant NFC n'est pas disponible sur l'appareil, prévoir une procédure alternative (saisie manuelle d'ID + vérification suppléante).
- Pour garantir la meilleure sécurité, renouveler régulièrement les clés/paramètres cryptographiques côté serveur.
- Conserver des journaux d'audit pour les cas litigieux.

## Conclusion

L'objectif d'EpitaSign est de proposer un flux simple et sécurisé pour la prise de présence avec preuve de signature. Le processus combine identification via NFC et preuve cryptographique de la signature pour réduire les fraudes et fournir un enregistrement fiable pour les enseignants.
