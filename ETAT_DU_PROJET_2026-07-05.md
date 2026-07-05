# CAARCO — État du projet
**Date du scan : 5 juillet 2026** · Rédigé après scan complet du dépôt `D:\Mon projet\CAARCO`

---

## 1. L'application

**CAARCO** est une application mobile (Android en priorité, iOS dans un second temps) de **transport de marchandises et de déménagement au Cameroun** — positionnée comme *« l'Uber du déménagement »*. Elle met en relation :

- des **clients** (particuliers, commerçants, PME) qui ont besoin de faire transporter un colis, déménager, ou faire livrer une marchandise,
- et des **transporteurs** (moto-taxi, tricycle, pick-up, camion léger/lourd) qui acceptent des courses via l'app.

Le projet a deux volets :

| Volet | Emplacement | Stack |
|---|---|---|
| **Application mobile** | `D:\Mon projet\CAARCO\App` | React Native 0.81.5 + Expo SDK 54, Supabase, Notchpay |
| **Site vitrine** | `D:\CAARCO-WEB` (séparé) | Next.js 16 + Tailwind v4 + Google Sheets CMS |

⚠️ **Point à vérifier avec toi** : le dossier `D:\CAARCO-WEB` référencé dans `MEMORY.md` comme "déployé, live sur `caarco-web.vercel.app`" **n'existe pas sur cette machine** (`D:\` ne contient pas ce dossier). Soit il a été développé/déployé depuis un autre environnement (Cowork cloud, autre PC), soit il a été déplacé/supprimé localement. À clarifier — sinon je ne peux pas auditer le site web dans ce document, je me base uniquement sur ce que `MEMORY.md` en dit.

Un ancien dossier `D:\CAARCO` (copie complète, ~4 Go, avant le déménagement du 4 juillet) traîne toujours à la racine du disque D:. Non touché — à supprimer une fois que tu as confirmé que `D:\Mon projet\CAARCO` fonctionne correctement.

---

## 2. Objectif du projet

- **Mission** : offrir un moyen simple, rapide et fiable de transporter des marchandises au Cameroun, pour 4 usages : **livraison express**, **déménagement**, **logistique d'entreprise**, **transport ponctuel**.
- **Modèle économique** : CAARCO ne manipule **aucun argent client**. Le client paie le transporteur **directement**, en espèces ou Mobile Money, hors de l'app. CAARCO se rémunère en vendant aux transporteurs des **Tokens de Course (TC)** via Notchpay (MTN/Orange Money) ; 1 TC = 1 FCFA ; une commission de 20 % du prix de la course est déduite en TC du solde du transporteur à chaque livraison.
- **Pourquoi ce modèle** : la V1 avec séquestre de l'argent client a été **refusée par Google Play** (activité financière non agréée). Le pivot vers les TC (le transporteur seul manipule de l'argent, sous forme de crédits prépayés) est la réponse à ce refus.
- **Marché cible V1** : Cameroun uniquement (géofencing), langue française uniquement, monnaie XAF exclusivement.
- **Prochaine étape stratégique** : soumission Play Store, puis extension progressive (multi-villes, iOS dans ~3 mois).

---

## 3. Réalisations actuelles (chiffres vérifiés au scan)

| Élément | Quantité |
|---|---|
| Écrans mobile | **67** (18 client, 18 transporteur, 18 admin, 4 auth, 9 partagés) |
| Services métier (`App/src/services`) | **31** |
| Migrations SQL (`App/supabase/migrations` — dossier actif) | **103** |
| Edge Functions Supabase (`App/supabase/functions`) | **12** |
| Composants UI Atelier CAARCO | 18+ (Galet, Sillon, Plaquette, Pastille, Cachet…) |
| Tests automatisés | **0** |
| Documents business produits | 11 (CDC, contrat transporteur, CGU, pitch decks, one-pager…) |

**Fonctionnalités au-delà du cahier des charges initial**, déjà codées : wallet client (obsolète depuis le pivot TC, voir §4), programme de fidélité avec paliers/streaks/VIP, parrainage avec commissions automatiques, chat + appel temps réel client↔transporteur, packs d'abonnement transporteur, génération de reçus PDF, tutoriels first-run, mode maintenance global, support hors-ligne (cache + file d'attente).

**Le cœur fonctionnel de l'app est donc largement construit.** Le travail restant est concentré sur la sécurisation du modèle économique, le nettoyage de la dette technique, et le déploiement — pas sur l'écriture de nouvelles fonctionnalités.

---

## 4. Ce qui a été fait / ce qui ne l'a pas encore été

### ✅ Fait et solide
- Design system Atelier CAARCO complet et cohérent (tokens, typographie, composants), appliqué sur l'ensemble des écrans.
- Auth Supabase (téléphone + mot de passe), navigation par rôle, RLS activé sur toutes les tables.
- Flux client complet : commande → estimation prix → recherche transporteur → suivi GPS temps réel → OTP → notation.
- Flux transporteur complet : dashboard, acceptation de course avec timer, navigation, validation OTP, gains.
- Back-office admin : KYC, litiges, finances, configuration tarifs en live.
- Sécurité de base : JWT en SecureStore (Keychain/Keystore), HMAC-SHA256 obligatoire sur le webhook Notchpay, montants plafonnés, URL WebView validée par hostname exact.
- Build Android local fonctionnel (APK généré et testé sur téléphone physique).
- Système de "courses programmées" avec matching automatique et escalade admin (migration 086, le 3 juillet).
- **Audit de sécurité complet réalisé le 3 juillet 2026** (`DIAGNOSTIC_AUDIT_2026-07-03.md`), avec correctifs appliqués **côté code** le jour même (`CORRECTIONS_2026-07-03.md`) :
  - crédit TC illimité gratuit (faille critique) → corrigé
  - commission de 20 % contournable → corrigée, débit désormais atomique et dérivé du prix stocké
  - contournement de l'OTP (en ligne et hors ligne) → corrigé

### 🔴 Fait dans le code, mais **PAS ENCORE ACTIF EN PRODUCTION** — priorité n°1
Les correctifs de sécurité ci-dessus existent en migration SQL (`085_securite_tc_et_courses.sql`) mais **n'ont pas été exécutés sur le Supabase de production**. Tant que ce n'est pas fait, les failles critiques (crédit TC gratuit, commission contournable) restent exploitables en prod. C'est une action que je ne peux pas faire à ta place (accès Dashboard Supabase requis) :
1. Ouvrir Supabase → SQL Editor → exécuter `App/supabase/migrations/085_securite_tc_et_courses.sql`
2. Redéployer les 4 Edge Functions modifiées localement mais jamais publiées : `notifier-transporteurs`, `moneroo-webhook`, `initier-paiement`, `initier-recharge`
3. Redéployer la migration 086 (courses programmées) si pas encore fait

### 🟠 Dette technique connue
- **103 migrations avec des doublons de numéro** (056×3, 057×2, 058×2, 060×2, 061×2, 062×2) → risque d'ordre d'application non déterministe sur un futur `db reset`.
- **Deux dossiers `supabase/` distincts dans le repo** : `D:\Mon projet\CAARCO\supabase` (76 migrations, 6 fonctions, ancien modèle Moneroo) et `D:\Mon projet\CAARCO\App\supabase` (103 migrations, 12 fonctions, modèle TC actuel). Le second est le dossier actif — mais la coexistence des deux est une source de confusion évidente et un risque si quelqu'un modifie le mauvais dossier par erreur.
- **6 écrans du modèle financier abandonné** (Wallet, Recharge, Paiement, PayerTransporteur, Retrait, Encaissement) toujours présents dans le repo bien que hors bundle — motif de refus Play Store si un reviewer les atteint quand même. Suppression bloquée dans l'environnement Cowork, à faire depuis VS Code.
- Boutons morts pointant vers une route de paiement supprimée (`AccueilScreen`, `SuiviScreen`).
- **Zéro test automatisé** sur un flux qui gère de l'argent (TC, commission) — risque de régression silencieuse.
- APK à 52,4 Mo, objectif < 30 Mo pour le Play Store — pas encore optimisé.
- Bug ouvert non résolu : le bouton "Payer" (achat de TC) dans `MesTokensScreen` ne fait rien — suspicion d'Edge Function `notchpay-init-achat-tc` non déployée ou secrets Notchpay absents côté Supabase. En attente d'un log Metro pour diagnostiquer.

### 📋 Pas encore fait
- Redéploiement des migrations/fonctions ci-dessus (bloquant, voir plus haut)
- Tests du paiement Notchpay en sandbox → production
- Compte Google Play Console (25 USD, jamais créé à ce stade)
- Assets Play Store (screenshots, icône 512px, feature graphic)
- Immatriculation OHADA de CAARCO (prérequis légal avant lancement)
- Recrutement des 50 premiers transporteurs fondateurs
- OnboardingScreen (3 slides) — absent du code malgré la spec
- 5 documents business sur 10 encore à produire (fiches de poste, term sheet investisseur, kit presse, plan de communication, tableau de bord financier)
- Connexion du domaine `caarco.cm` au site Vercel (si le site web est bien déployé quelque part)
- V2 : multi-villes (Douala, Yaoundé, Bamenda), Notchpay+Lygos en fallback, IA de validation des produits interdits

---

## 5. Propositions pour suivre où tu en es

**Pour un suivi rapide sans relire tout le code**, je recommande trois choses concrètes :

1. **Un tableau de bord "3 colonnes" simple** (`STATUT.md` à la racine, mis à jour à chaque session) : *Bloquant* / *En cours* / *Fait cette semaine*. Le fichier `MEMORY.md` actuel est excellent comme journal historique (624 lignes, très détaillé) mais trop long pour un coup d'œil rapide — il mélange l'historique complet de 9 sessions avec l'état présent. Séparer les deux : `MEMORY.md` garde l'historique, un nouveau fichier court porte uniquement le statut courant.

2. **Une checklist "Prêt pour le Play Store"** à cocher au fur et à mesure — techniquement (migrations déployées, tests, APK < 30 Mo) et administrativement (compte Play Console, OHADA, assets). Aujourd'hui cette information existe mais est éparpillée entre `MEMORY.md`, `DIAGNOSTIC_AUDIT_2026-07-03.md` et `CORRECTIONS_2026-07-03.md`.

3. **Vérifier et documenter l'état réel du site web** `D:\CAARCO-WEB` — dossier introuvable sur cette machine alors qu'il est décrit comme "en production". Sans ça, ce document reste incomplet sur la moitié "site web" du projet.

## Ce que j'en pense

Le code est **bien plus avancé que ce à quoi on s'attendrait pour un projet à ce stade** — l'essentiel des écrans, services et back-office existe et semble structuré proprement (design system respecté, RLS actif, architecture claire). Le vrai risque aujourd'hui n'est **pas fonctionnel, il est opérationnel** : les correctifs de sécurité critiques (crédit TC gratuit, commission contournable) sont écrits mais pas appliqués en production — c'est littéralement une faille qui vide le modèle économique tant que la migration `085` n'est pas exécutée sur Supabase. Je le mettrais en tête de liste avant toute autre action, y compris avant de continuer à ajouter des fonctionnalités.

Le deuxième point qui me frappe est la **dette de "nettoyage"** plus que de "construction" : deux dossiers Supabase concurrents, des écrans morts non supprimés, des migrations dupliquées. Rien de grave individuellement, mais cumulé ça complique chaque session de travail (risque de modifier le mauvais fichier). Un sprint de nettoyage ciblé (1-2 jours) avant le sprint Play Store me semble plus rentable que d'attaquer directement les tâches de lancement.
