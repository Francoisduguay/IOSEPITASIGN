# EpitaSign

Fiche technique de l'application enseignant

## Presentation

EpitaSign est une application mobile de signature de presence pour les enseignants. Elle permet a un professeur de consulter son emploi du temps, d'ouvrir la classe du cours en cours, de faire signer les etudiants presents, de corriger une signature validee par erreur et de retirer un retard lorsqu'il est justifie.

L'application ne demande pas au professeur de qualifier manuellement un etudiant comme absent. Le retard est d'abord deduit automatiquement par le systeme a partir de l'heure de signature et des horaires officiels du cours. Le professeur garde toutefois la main pour retirer un retard lorsqu'une situation le justifie.

## Roles

EpitaSign distingue deux roles applicatifs :

- `teacher` : acces enseignant, limite a l'emploi du temps, au cours actuel et a la collecte des signatures.
- `student` : acces etudiant, utilise pour les operations liees a l'identite et aux preuves de presence.

Aucun role d'administration n'est expose dans l'application mobile enseignant. Les operations de gestion des utilisateurs, des cartes, des groupes, des exports et des corrections globales relevent du backend ou d'outils internes separes.

## Perimetre enseignant

Depuis l'application, un enseignant peut :

- consulter son emploi du temps ;
- ouvrir la fiche du cours actuellement en cours ;
- afficher la liste des etudiants attendus pour ce cours ;
- faire signer un etudiant ;
- annuler localement une signature si elle a ete validee par erreur ;
- retirer le retard calcule pour un etudiant ;
- suivre le nombre d'etudiants signes et restant a signer.

L'enseignant ne declare pas les absences depuis cette interface. Un etudiant qui ne signe pas reste simplement dans l'etat `A signer` pendant le cours. Si un etudiant signe apres le seuil de 15 minutes, le systeme le classe en retard ; le professeur peut ensuite retirer ce retard.

## Etats metier

### Etat d'un etudiant dans la classe

Pour l'enseignant, un etudiant a seulement deux etats visibles :

- `A signer` : aucune signature validee pour cet etudiant sur la seance.
- `Signe` : une signature a ete collectee et acceptee pour cet etudiant.

### Etat calcule par le systeme

Le backend peut ensuite calculer des statuts administratifs a partir des donnees horodatees :

- `present` : signature validee dans les 15 premieres minutes du cours.
- `late` : signature validee plus de 15 minutes apres le debut du cours.
- `unsigned` : aucune signature validee pour la seance.
- `rejected` : tentative de signature refusee pour raison technique ou de validation.

Le retard est donc d'abord une consequence automatique de la date de debut du cours et de l'horodatage de signature. La correction du retard reste une action explicite du professeur.

## Flux enseignant

1. Le professeur se connecte avec son compte EPITA.
2. L'application charge son profil et verifie le role `teacher`.
3. L'enseignant arrive sur son emploi du temps.
4. Il selectionne le cours en cours.
5. L'application affiche la classe rattachee a cette seance.
6. Pour chaque etudiant present, l'enseignant lance la signature.
7. L'etudiant signe sur l'ecran.
8. L'application controle la qualite minimale de la signature.
9. La signature est envoyee au backend avec les informations de seance et d'identite.
10. Si la validation reussit, l'etudiant passe a l'etat `Signe`.
11. Si la signature est en retard, le professeur peut retirer le retard apres verification.

## Flux technique de signature

La validation d'une signature suit une sequence stricte :

1. L'application recupere le cours courant et son identifiant de seance.
2. L'enseignant selectionne l'etudiant qui doit signer.
3. L'application demande au backend un token d'attestation temporaire pour la seance et l'etudiant.
4. L'etudiant trace sa signature sur le panneau tactile.
5. L'application collecte les points de signature, la duree, la taille du trace et les metriques de mouvement.
6. L'application verifie localement les contraintes minimales :
   - nombre minimal de points ;
   - duree minimale ;
   - amplitude minimale du trace ;
   - complexite suffisante du mouvement.
7. L'application genere une preuve de signature a partir des donnees normalisees.
8. Le backend verifie le token, l'etudiant, la seance et l'integrite de la preuve.
9. Le backend enregistre l'horodatage de signature et la preuve associee.
10. Le statut administratif est calcule a partir de l'heure de debut du cours :
   - signature avant `debut du cours + 15 minutes` : presence normale ;
   - signature apres `debut du cours + 15 minutes` : retard.
11. Si le professeur retire le retard, le statut repasse a `present`. Le backend conserve l'horodatage original et enregistre la correction comme une action distincte.

## Donnees manipulees

Les principales donnees fonctionnelles sont :

- profil utilisateur : identifiant, email, role ;
- cours : identifiant, titre, salle, heure de debut, heure de fin ;
- seance : cours courant, classe rattachee, liste des etudiants attendus ;
- etudiant : identifiant, nom, rattachement a la classe ;
- signature : points du trace, metriques, duree, image ou representation normalisee ;
- preuve : empreinte cryptographique, token d'attestation, horodatage ;
- enregistrement de presence : etudiant, cours, statut calcule, date de signature ;
- correction de retard : etudiant, cours, professeur, date de correction, motif ou commentaire si requis.

## Securite

EpitaSign applique plusieurs protections :

- authentification obligatoire avec un compte EPITA ;
- controle du role avant affichage des fonctionnalites enseignant ;
- token d'attestation temporaire pour chaque operation de signature ;
- expiration courte des tokens pour limiter les rejeux ;
- validation locale de la signature avant envoi ;
- verification serveur de l'association entre etudiant, cours et token ;
- horodatage serveur utilise pour le calcul des retards ;
- conservation de l'horodatage initial meme lorsqu'un retard est retire ;
- journalisation des corrections de retard effectuees par un professeur ;
- stockage des signatures dans un espace controle ;
- journalisation des validations et refus.

Le calcul du retard doit toujours s'appuyer sur l'heure serveur, pas sur l'heure locale du telephone, afin d'eviter les incoherences ou manipulations.

## Cas d'erreur

L'application doit gerer les erreurs suivantes :

- cours non disponible ou hors plage horaire ;
- etudiant absent de la liste de la classe ;
- token expire ;
- signature trop courte ou insuffisamment complexe ;
- perte reseau pendant l'envoi ;
- refus serveur lors de la verification ;
- tentative de signature deja validee.
- tentative de retrait de retard sur une signature non retardee.

Dans ces cas, l'enseignant voit un message explicite et peut relancer la signature lorsque l'erreur est recuperable.

## Limites operationnelles

- Une signature ne doit etre possible que pour le cours actuellement en cours.
- Le professeur peut retirer un retard, mais ne doit pas modifier l'horodatage original.
- Une correction globale de presence doit passer par un outil interne separe.
- Les exports et historiques consolides sont produits cote backend, pas depuis l'interface de collecte enseignant.

## Resume

EpitaSign fournit au professeur une interface limitee et rapide pour collecter les signatures de presence pendant son cours. L'application se concentre sur l'action terrain : voir la classe actuelle, faire signer les etudiants, corriger une signature immediate et retirer un retard justifie. Le retard est calcule automatiquement a partir de l'horodatage serveur, avec un seuil de 15 minutes apres le debut du cours, puis reste corrigeable par le professeur sans modifier la trace originale.
