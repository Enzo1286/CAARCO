# CDC — Travaux en cours CAARCO (vue consolidée)
**Créé le** : 2026-07-17
**Objectif** : un seul document qui liste tout ce qui est ouvert sur le projet en ce moment, pour ne rien perdre et savoir dans quel ordre trancher. Ne remplace aucun document existant (`REFONTE_TRACKING.md`, `CDC_ADMIN_WEB.md`, `MEMORY.md`) — les résume et les met en relation.

> **⚠️ L'application est déjà disponible publiquement sur le Google Play Store** (confirmé par Cedric le 2026-07-17). Ce n'est plus un chantier pré-lancement : tout ce qui suit est du travail **post-lancement**, avec des utilisateurs réels potentiellement concernés dès aujourd'hui. Les mentions « avant lancement Play Store » trouvées dans les documents plus anciens (`CLAUDE.md`, `SPRINT_4.md`) sont dépassées.

---

## 0. Vérification préalable (demandée par Cedric avant toute action)

Avant d'écrire ce document, vérification que les 2 derniers correctifs de la session précédente ne dérangent rien de ce qui s'est fait depuis (compte admin, chantier admin web) :

- **Suppression de `fix_terminer_livraison.sql`** (commit `9b3d6442`) — toujours en place, aucun fichier de ce nom recréé depuis. Sans rapport avec le travail du chantier admin web.
- **Réparation de `npx babel --presets babel-preset-expo`** (commit `e8465f32`, ajout de `@babel/cli`) — `package.json` non modifié depuis, le correctif est intact.
- **Aucun conflit détecté.** Le travail fait entre-temps (migration des comptes admin, `CDC_ADMIN_WEB.md`, migrations 107/108, écrans motif d'annulation) est indépendant et cohérent avec l'état confirmé en base le 2026-07-17 (mémoire `etat-base-supabase-prod`) : migrations 085→108 toutes appliquées en production, un seul super-admin (`679570886`), 2FA vérifié.
- **L'application est déjà en ligne sur le Play Store** (confirmé par Cedric) — voir l'avertissement en tête de document.

---

## 1. Chantier « Admin web en ligne » — `CDC_ADMIN_WEB.md`

Chantier ouvert aujourd'hui (2026-07-17). Détail complet dans `CDC_ADMIN_WEB.md` — résumé de l'avancement réel constaté dans le code/la base :

| Lot | Contenu | État constaté |
|---|---|---|
| A1 | Migrer `697028122` → numéro réel de Cedric | ✅ Fait — `679570886` est l'unique super-admin (vérifié en base) |
| A2 | Réparer le compte `admin` | ✅ Fait, mais **différemment que prévu** : le compte a été **supprimé** plutôt que réparé (décision implicite tranchant la question ouverte §8.2 de `CDC_ADMIN_WEB.md` — un seul super-admin, pas deux) |
| A3 | Activer le 2FA sur les comptes admin | ✅ Fait — revérifié en base le 2026-07-17 (lecture seule, Management API) : facteur TOTP `verified` sur `679570886` |
| A4 | Re-lancer le diagnostic, confirmer 2FA actif | ✅ Fait — `scripts/diagnostic_supabase.sql` relancé le 2026-07-17 : migrations 085→108 toutes appliquées, `679570886 — ✅ 2FA actif (totp)`, `role_security_trigger` actif |
| B | Point d'entrée web dédié (sans écrans client/TR) | ✅ **CLOS le 2026-07-17 (Session 28)** — B1-B3 (commit `d99d53f0`) + B4 test navigateur validé par Cedric (connexion + 2FA + 23 écrans OK). |
| C | Déploiement Vercel | 🔄 **Bundle prêt (Session 28)** : `App/dist-web` régénéré avec `EXPO_PUBLIC_APP_ENV=production` inliné + `vercel.json` SPA. Déploiement CLI à faire par Cedric (compte Vercel requis). |
| D | Domaine personnalisé | ⏳ Pas commencé (attend l'achat du domaine) |

**Lots A et B clos.** Lot C : le bundle statique pré-buildé est prêt ; il ne reste que la commande `vercel --prod` depuis le compte de Cedric (voir `CDC_ADMIN_WEB.md` §6 Lot C).

**⚠️ Découverte Session 28 (résolue)** : `ConfigTarifsScreen.js:37` exposait une modale de **remise à zéro destructive** tant que `EXPO_PUBLIC_APP_ENV != production`. Le `dist-web` de B4 était buildé sans la variable → remise à zéro accessible. Corrigé en régénérant `dist-web` avec la variable inlinée (vérifié bundle : 0 accès runtime restant).

**Décision déjà actée par les faits, à confirmer avec Cedric** : un seul compte admin (`679570886`), pas deux — cohérent avec la remarque §8.2 du CDC (« un seul super-admin bien protégé est plus simple à sécuriser »).

---

## 2. Chantier « Refonte visuelle » — `REFONTE_TRACKING.md`

Chantier D clos pour 18/18 lots. Reste ouvert (inchangé depuis la session précédente, aucun conflit avec le chantier admin web) :

1. **Lot bloqué (4 écrans)** — `ProfilScreen.js` (sexe/date_naissance), `MerciScreen.js`/`PointsScreen.js` (déjà migrés sur `jalons_client` côté fonctionnel, refonte visuelle jamais faite), `PacksAbonnementScreen.js` (commission dynamique déjà branchée, refonte visuelle jamais faite). Ce sont les seuls écrans du chantier D à n'avoir eu **que** des corrections fonctionnelles, jamais la passe visuelle Stitch appliquée aux 60 autres écrans. Ces écrans sont fonctionnels et déjà utilisés par de vrais utilisateurs (app en ligne) — ce qui reste est uniquement visuel, pas bloquant pour l'usage.
2. **3 configurations mortes** (Lots 16/18) — à rebrancher ou retirer, décision Cedric.
3. **`capture-auto.ps1`/Maestro** — toujours bloqué, nécessite le téléphone Android physique de Cedric en USB ; le flow Maestro ne couvre de toute façon aucun écran admin.

---

## 3. Hygiène du dépôt (nouveau, constaté aujourd'hui)

### 3.1 Travail non commité dans `App/`
Du travail réel et cohérent (pas des brouillons) est actuellement modifié/non suivi sans commit :

- **Migrations 107 et 108** (déjà appliquées en base de production, confirmé par le diagnostic du jour) : `users.updated_at` manquante (cassait l'annulation d'une course planifiée déjà assignée — bug réel corrigé), `courses.motif_annulation` (support de l'auto-annulation serveur d'une course planifiée dépassée).
- **`courses-programmees-cron`** : nouvelle étape d'auto-annulation des courses planifiées dont l'heure est dépassée sans avoir démarré.
- **Écrans client/transporteur** (`Cachet.js`, `CourseDetailClientScreen.js`, `CourseScreen.js`, `CoursePlanifieeDetailScreen.js`, `HistoriqueScreen.js`, `MesCoursesPlanifieesScreen.js`, `CoursesTransporteurScreen.js`, `MesReservationsScreen.js`, `RevenusScreen.js`) : affichage du motif d'annulation, plumbing cohérent avec les 2 migrations ci-dessus.
- **`SecuriteAdminScreen.js`** : rendu du QR 2FA compatible web (préparation Lot B du chantier admin web).
- **`app.json`** : `version` à `1.1.0`, `versionCode` à `26` — plusieurs builds `prod` ont visiblement eu lieu depuis la session précédente (dernier connu : versionCode 9). **Ne pas re-bumper sans demander la dernière version réelle sur Play Console** (règle déjà en mémoire, cf. incident du 2026-07-10).
- **`fr.js`/`en.js`** : 3 nouvelles clés (probablement `coursesPlanifiees.detailAnnulee*`).

→ **Rien de tout ça n'est cassé ni en conflit.** ✅ **Commité le 2026-07-17** : correctif « annulation automatique + motif » (commit `c646e6df`, 14 fichiers) + bump `app.json` séparé (commit `aaf2fa68`, version 1.1.0 / versionCode 26). `SecuriteAdminScreen.js` (prépa Lot B) laissé non commité à ce moment-là.

### 3.2 Nouveaux scripts SQL à la racine (`scripts/`)
`diagnostic_supabase.sql`, `migrer_compte_admin.sql`, `reset_mdp_admin.sql`, `vercel-admin.json` — legitimes, liés au chantier admin web, non commités.
- **`reset_mdp_admin.sql`** : ✅ vérifié/réécrit le 2026-07-17 (Session 28) — ne contient que des **emplacements** ; ciblait les anciens emails périmés (`697028122@`/`admin@`), corrigé pour l'unique compte actuel `679570886@caarco.local`. Prêt à être exécuté par Cedric dans le SQL Editor (il colle son nouveau mot de passe).
- **⚠️ Vraie fuite trouvée ailleurs (Session 28)** : les mots de passe en clair signalés au journal 26bis n'étaient PAS dans le fichier SQL mais dans **`MEMORY.md`** lui-même (lignes 521/523). **Assainis** ; vérifié absents de l'historique git (`git log -S`) — jamais commités/poussés.
- **Rotation du mdp `679570886`** : Cedric a choisi la voie SQL, mais l'appel Management API (modif d'identifiant prod) est **bloqué par le classifieur du harness** en mode auto. → Cedric l'exécute lui-même via `reset_mdp_admin.sql` (SQL Editor), ou le change depuis l'écran Sécurité de l'app. 2FA inchangé = aucun risque de verrouillage.

### 3.3 Fichiers parasites à la racine — ✅ SUPPRIMÉS le 2026-07-17 (Session 28)
13 fichiers fantômes racine (débris de collage terminal) supprimés après confirmation de Cedric : `!frFlat[k])`, `'`, `,`, `,-,-,`, `0`, `07`, `_wtest_5` (3 o, « ok »), `m[0]).join('')...`, `t.type`, `{`, `{,`, `{,+`, `{})`. Tous vides (0 o) sauf `_wtest_5`. Vérifié : plus aucun fantôme à la racine ni dans `App/`.
Dans `App/` : `!nomsVus.has(...)`, `,`, `NOW()`, `NOW())`, `{`, `{,`, `{,+`, plus 2 scripts ponctuels legitimes mais jetables une fois utilisés (`fix.js`, `restore_alpha.js` — outils de recherche/remplacement en masse déjà exécutés) et `crash_log.txt`/`CAARCO_logcat.txt`/`crash.log`/`crash2.log` (logs de debug, à archiver ou supprimer selon utilité).

### 3.4 Sous-module `App/` sans remote GitHub
Toujours vrai — aucun `.gitmodules`, aucun `origin` configuré. Tous les commits (dont `e8465f32`/`9b3d6442` de la session précédente et le travail non commité ci-dessus) restent locaux. Décision Cedric requise : créer un dépôt GitHub dédié, ou continuer en local uniquement.

### 3.5 Racine `supabase/.temp/linked-project.json`
Réapparu en untracked — c'est le cache local du CLI Supabase (régénéré à chaque `supabase link`), pas les 85 migrations supprimées au Sprint 2/Chantier A. Déjà couvert par `.gitignore` de `App/` mais le dossier `supabase/` racine n'a pas son propre `.gitignore` (celui d'`App/` ne s'applique qu'à `App/`). Sans risque, mais à ignorer explicitement pour éviter un futur commit accidentel.

---

## 4. Décisions attendues de Cedric — vue unique

| # | Sujet | Chantier | Urgence |
|---|---|---|---|
| ~~1~~ | ~~Finaliser l'enrôlement 2FA sur `679570886`~~ | Admin web A3 | ✅ Déjà fait, confirmé en base le 2026-07-17 |
| 2 | Confirmer : un seul compte admin, pas deux | Admin web | Déjà actée par les faits, confirmation formelle utile |
| ~~2bis~~ | ~~Démarrer le Lot B~~ | Admin web | ✅ Lot B clos (B1-B4). Reste : **Lot C** = `vercel --prod` depuis le compte Vercel de Cedric (bundle prêt) |
| 2ter | **Changer le mdp admin `679570886`** (voir §3.2) | Sécurité | Exposition locale seulement (jamais poussé) → faible ; à faire par Cedric (SQL Editor ou écran Sécurité) |
| 3 | Autoriser le commit du travail « annulation automatique + motif » | Hygiène dépôt | App déjà en ligne → gain immédiat de fiabilité du dépôt, faible risque |
| 4 | Trancher les 4 écrans du Lot bloqué (refonte visuelle) | Chantier D | App déjà en ligne → amélioration post-lancement, pas bloquant pour l'usage |
| 5 | Trancher les 3 configurations mortes | Chantier D | Pas urgent |
| 6 | Remote GitHub pour `App/` — créer ou rester local | Hygiène dépôt | Pas urgent, mais risque de perte si le poste a un problème |
| ~~7~~ | ~~Confirmer la suppression des fichiers parasites~~ | Hygiène dépôt | ✅ Fait Session 28 (13 fichiers supprimés) |
| 8 | `capture-auto.ps1`/Maestro — accès au téléphone physique | Chantier D | Nécessite le matériel de Cedric |

---

## 5. Ce que je peux faire seul dès accord (sans repasser par une nouvelle question)

- Committer le travail « annulation automatique + motif » (point 3) dans `App/`, avec vérification préalable que `reset_mdp_admin.sql` ne contient pas de vraie valeur avant tout `git add`.
- Supprimer les fichiers parasites listés (point 7) une fois le chemin exact confirmé.
- Archiver/supprimer `fix.js`, `restore_alpha.js`, les logs crash — une fois confirmé qu'ils sont jetables.
- Ignorer `supabase/.temp/` à la racine (ajout `.gitignore`) pour éviter tout commit accidentel futur.
- Une fois le 2FA finalisé (point 1) : relancer `scripts/diagnostic_supabase.sql` pour confirmer A4, puis démarrer le Lot B (point d'entrée web dédié) du chantier admin web.

Rien de tout ça n'a été exécuté — ce document sert de base à la prochaine discussion avec Cedric.
