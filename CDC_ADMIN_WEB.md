# CDC — Back-office admin CAARCO en ligne (web)
**Créé le** : 2026-07-17
**Demandeur** : Cedric Timene
**Objectif** : accéder au back-office admin depuis n'importe quel navigateur, n'importe où, sans passer par le poste de développement ni par l'application mobile.

---

## 1. Décisions prises (2026-07-17)

| Sujet | Décision |
|---|---|
| Hébergement | **Vercel** (là où tourne déjà `caarco-web.vercel.app`) |
| Domaine | Pas encore acheté → démarrage sur l'URL Vercel gratuite, domaine branché plus tard |
| Compte `admin` | **Réparer** : lui attribuer un vrai numéro pour le rendre connectable |
| Compte `697028122` | **Changer le numéro** du compte existant (garde historique + droits super-admin) |

**En attente** : les deux numéros de téléphone réels de Cedric.

---

## 2. État des lieux — vérifié, pas supposé

### 2.1 Ce qui est déjà en place ✅

- **Le support web existe déjà dans le code.** `RootNavigator.js` (l. 68-80) teste `Platform.OS === 'web'` ; `App.js` (l. 40, 104, 138) neutralise déjà le splash natif et les animations incompatibles web. `react-native-web` (~0.21) et `react-dom` (19.1) sont installés (`App/package.json`).
- **`npx expo export --platform web` compile déjà l'ensemble du bundle sans erreur** (vérifié Session 12, 2026-07-07).
- **L'admin est déjà isolé** derrière `AdminNavigator.js` → `AdminShell.js` (23 écrans dans `App/src/screens/admin/`).
- **La barrière 2FA est déjà câblée** : `AdminAvecMFA` dans `RootNavigator.js` (l. 35-64) impose le défi TOTP avant d'ouvrir `AdminNavigator`.
- **Le socle serveur est complet** (diagnostic du 2026-07-17, `scripts/diagnostic_supabase.sql`) : migrations 085 → 108 **toutes appliquées**, RLS par rôle, `is_admin()`, `is_super_admin()`, `admin_aal_suffisant()`, `role_security_trigger` actif.

### 2.2 Ce qui bloquait 🔴 — tous résolus le 2026-07-17

| # | Problème | Preuve | État |
|---|---|---|---|
| B1 | Aucun compte admin n'avait le 2FA activé | `auth.mfa_factors` vide pour les 2 admins | ✅ Résolu — `679570886` a un facteur TOTP `verified` (revérifié en base le 2026-07-17) |
| B2 | Le compte `admin` était inutilisable | `REGEX_TEL = /^[0-9]{8,15}$/` — `auth.js:7` rejette `admin` avant tout appel réseau | ✅ Résolu — compte supprimé (un seul admin conservé) |
| B3 | Le numéro 697028122 n'appartenait pas à Cedric | Déclaré par Cedric le 2026-07-17 | ✅ Résolu — migré vers `679570886` |

> Plus aucun bloquant avant la mise en ligne. Le Lot B (point d'entrée web dédié) peut démarrer.

---

## 3. Périmètre

### Dans le périmètre
- Un point d'entrée web servant **uniquement** le parcours admin : connexion → défi 2FA → `AdminShell`.
- Déploiement Vercel + branchement d'un domaine ultérieur.
- Correction de B1, B2, B3.

### Hors périmètre
- Réécriture des 23 écrans admin (ils sont réutilisés tels quels).
- Refonte visuelle (chantier D, `REFONTE_TRACKING.md`) — indépendante.
- Écrans client / transporteur : **volontairement absents** du bundle web.
- Toute modification du modèle de données ou des RPC.

---

## 4. Architecture cible

```
Navigateur (n'importe où)
   │  HTTPS
   ▼
Vercel — site statique (export web Expo, admin uniquement)
   │  supabase-js (clé anon, publique par nature)
   ▼
Supabase (Frankfurt)
   └─ RLS + is_admin() + is_super_admin() + admin_aal_suffisant()
      ↑ C'est ICI qu'est la sécurité, pas dans le front.
```

**Point clé** : exposer cette page publiquement n'ouvre aucun accès. Le front ne détient aucun secret (la clé `anon` est publique par conception) et tout est arbitré côté serveur. Une URL publique sans identifiants ne donne rien.

### 4.1 Option retenue — point d'entrée web dédié

Créer un point d'entrée web qui monte l'arbre de providers existant mais **n'importe jamais** `ClientNavigator` ni `TransporteurNavigator`.

Effets : bundle plus léger (les écrans client/TR, la carte Leaflet, l'audio, le GPS sortent du build), surface d'attaque réduite, et impossibilité pour un client de « tomber » sur l'URL de l'admin.

### 4.2 Repli si blocage technique

`npx expo export --platform web` du bundle **complet**, déployé tel quel. Fonctionne immédiatement (le web est déjà géré) mais expose aussi les parcours client/TR sur la même URL. **Acceptable pour un test, pas pour la cible.**

---

## 5. Sécurité — prérequis non négociables

1. **2FA TOTP activé sur tout compte admin** avant la mise en ligne (`SecuriteAdminScreen`, Google Authenticator). Rappel : `AdminAvecMFA` ne bloque *pas* un compte sans facteur — c'est un garde-fou anti-verrouillage, pas une protection. Sans 2FA activé, la barrière ne sert à rien.
2. **Un seul super-admin par personne réelle.** Aucun compte à identifiant générique ou devinable.
3. **`SUPABASE_SERVICE_ROLE_KEY` jamais dans le build web.** Seule `EXPO_PUBLIC_SUPABASE_ANON_KEY` est embarquée.
4. **`EXPO_PUBLIC_APP_ENV=production`** sur Vercel — exclut la remise à zéro totale du build (Sprint 1).
5. **Pas de secret dans le repo.** `scripts/reset_mdp_admin.sql` ne contient que des **emplacements** de mots de passe (vérifié le 2026-07-17, Session 28 : réécrit pour cibler l'unique compte `679570886@caarco.local`, jamais de vraie valeur). ⚠️ La vraie fuite du 2026-07-17 n'était PAS dans ce fichier mais dans `MEMORY.md` (mots de passe en clair dans le journal Session 26bis) — **assainie** ; jamais entrée dans l'historique git (vérifié `git log -S`).
6. Vérifier que `audit_admin` journalise bien les actions faites depuis le web (migration 093 déjà appliquée).

---

## 6. Lots

### Lot A — Débloquer les comptes (prérequis, ~30 min) — ✅ CLOS le 2026-07-17
- A1. ✅ Fait — `679570886` (Cedric Timene) est l'unique super-admin en base.
- A2. ✅ Fait, **différemment que prévu** : le compte `admin` a été **supprimé** plutôt que réparé — un seul compte admin au lieu de deux (tranche la question ouverte en §8.2 de ce document).
- A3. ✅ Fait — 2FA TOTP activé et vérifié sur `679570886`.
- A4. ✅ Confirmé par `scripts/diagnostic_supabase.sql` relancé le 2026-07-17 (lecture seule, Management API) : `679570886 — ✅ 2FA actif (totp)`, migrations 085→108 toutes appliquées, `role_security_trigger` actif.

**B1, B2, B3 de la section 2.2 sont donc tous résolus.** Rien ne bloque plus l'ouverture du Lot B.

### Lot B — Point d'entrée web admin (~2-4 h) — ✅ CLOS le 2026-07-17 (Session 28)
- B1. ✅ Fait — `src/navigation/RootNavigator.web.js` créé (commit `d99d53f0`). Metro le résout à la place de `RootNavigator.js` sur cible web ; il **n'importe jamais** `ClientNavigator` ni `TransporteurNavigator`. Parcours : connexion → défi 2FA (`AdminAvecMFA`, aal2) → `AdminNavigator` ; compte non-admin → écran « Espace réservé à l'administration » (les navigateurs client/TR ne sont jamais montés).
- B2. ✅ Rien à faire — le repli `localStorage` de `supabase.js` (SecureStore indispo sur web) **existait déjà** (l. 15-26). Seul correctif natif nécessaire : `gpsBackground.js` appelait `TaskManager.defineTask` au niveau module (crash au chargement web) → gardé derrière `Platform.OS !== 'web'` (no-op sur mobile). L'audio (`services/audio`) reste dans le bundle via `AuthContext` (provider partagé), sans risque : jamais déclenché pour un compte admin.
- B3. ✅ Fait — `npx expo export --platform web` compile (bundle unique 2,81 MB). **Vérifié par analyse du bundle** : `RootNavigator.js` absent (chaînes exclusives `tutoriel_vu_onboarding`/`AppelEntrantOverlay`/`useNotifsMessages` = 0), donc navigateurs client/TR exclus. Leaflet/OSRM/Nominatim présents **uniquement** via l'écran admin `OperationsAdminScreen` (carte des opérations) — légitime. Clé anon + URL Supabase bien embarquées.
- B4. ✅ **Fait le 2026-07-17 (Session 28)** — test navigateur validé par Cedric : connexion admin `679570886` → défi 2FA → navigation dans les 23 écrans OK ; compte non-admin → écran « Connexion impossible ». Aucun écran ne casse en navigateur (audit préalable : seuls `PublicitesAdmin` (image-picker/file-system, appelés au clic + garde `isWeb`) et `SecuriteAdminScreen` (WebView du QR, déjà géré) touchent au natif ; `MFAChallengeScreen` est RN pur).

> **⚠️ Découverte Session 28 (résolue) :** `ConfigTarifsScreen.js:37` calcule `resetDisponible = EXPO_PUBLIC_APP_ENV !== 'production'` — il expose une **modale de remise à zéro destructive** quand `APP_ENV` n'est pas `production`. Le `dist-web` servi pour B4 avait été buildé **sans** la variable → la remise à zéro était accessible. Corrigé au Lot C : `dist-web` régénéré avec `EXPO_PUBLIC_APP_ENV=production` inliné dans le bundle (vérifié : 0 accès runtime restant à la variable).

### Lot C — Déploiement Vercel (~1 h) — ⏳ Bundle prêt (Session 28), déploiement à faire par Cedric

**Approche retenue : déploiement du bundle statique PRÉ-BUILDÉ** (plus simple et plus sûr que de laisser Vercel builder). La variable `EXPO_PUBLIC_APP_ENV=production` (et l'URL/clé anon Supabase) sont **déjà inlinées** dans `App/dist-web` — Vercel n'a donc qu'à servir des fichiers statiques, aucune build ni variable d'env à configurer côté Vercel. Cela garantit aussi que la remise à zéro reste désactivée sans dépendre d'un réglage Vercel correct.

- **Pré-requis (déjà fait Session 28)** : `cd App && EXPO_PUBLIC_APP_ENV=production npx expo export --platform web --output-dir dist-web`, puis copier `scripts/vercel-admin.json` → `App/dist-web/vercel.json` (routage SPA ; l'export écrase le dossier, donc recopier après chaque rebuild).
- C1. Projet Vercel **distinct** de `caarco-web`.
- C2. Déploiement du dossier statique via la CLI Vercel (nécessite le compte Vercel de Cedric — non exécutable côté agent) :
  ```
  npm i -g vercel                 # si pas déjà installé
  cd "D:\Mon projet\CAARCO\App\dist-web"
  vercel --prod
  # → Set up and deploy? Y | Link to existing? N | Project name: caarco-admin
  # → Framework preset: Other | Build command: (vide) | Output dir: ./
  ```
- C3. Vercel renvoie une URL gratuite (ex. `caarco-admin.vercel.app`).
- C4. Test depuis un **autre appareil / autre réseau** : connexion `679570886` + 2FA → 23 écrans ; confirmer que la modale de remise à zéro (ConfigTarifs) est **absente**.

> Alternative (si build par Vercel via un dépôt git) : root dir `App`, build `npx expo export --platform web --output-dir dist-web`, output `dist-web`, et **là** il faut définir `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`, `EXPO_PUBLIC_APP_ENV=production` dans les env Vercel. Bloqué aujourd'hui : `App/` n'a pas de remote GitHub (cf. §3.4 de `CDC_TRAVAUX_EN_COURS.md`). D'où le choix du déploiement pré-buildé.

### Lot D — Domaine (plus tard, quand acheté)
- D1. Achat du domaine.
- D2. Sous-domaine `admin.<domaine>` → Vercel (enregistrement DNS CNAME).
- D3. HTTPS automatique (Vercel s'en charge).

---

## 7. Risques identifiés

| Risque | Parade |
|---|---|
| `expo-secure-store` indisponible sur web → session non persistée, voire crash au démarrage | Lot B2 : vérifier le repli `supabase.js` sur `localStorage` côté web |
| Modules natifs (push, GPS, audio) important du code incompatible web | Le point d'entrée dédié les exclut en grande partie ; à valider écran par écran |
| Perte d'accès admin pendant la manœuvre sur les comptes | `admin_revoquer_administrateur` refuse de retirer le dernier super-admin ; ne jamais toucher aux deux comptes dans la même minute |
| 23 écrans admin conçus pour un écran de téléphone → inconfort sur desktop | Hors périmètre (chantier D). Fonctionnel avant beau. |

---

## 8. Ce qui reste à trancher

1. **Les deux numéros réels de Cedric** (bloque le Lot A).
2. Faut-il vraiment **deux** comptes admin ? Un seul super-admin bien protégé est plus simple à sécuriser qu'un compte de secours mal suivi.
3. Le domaine : quand il sera acheté (Lot D).
