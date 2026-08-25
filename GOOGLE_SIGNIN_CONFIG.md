# Connexion Google — Guide de configuration CAARCO

> ## 🔎 ÉTAT VÉRIFIÉ — 24/08/2026 (session 43)
>
> Erreur `DEVELOPER_ERROR` (10) reproduite en direct sur le Xiaomi
> (`ConnectionResult{statusCode=DEVELOPER_ERROR}` dans le logcat). Le refus
> tombe **avant** l'affichage du sélecteur de comptes.
>
> Vérifications faites côté machine et téléphone — toutes CONFORMES :
>
> | Point | Constat |
> |---|---|
> | Signature réelle de l'APK installé (`apksigner`) | `5E:8F:16:…:F6:25` (clé debug) |
> | Client Android `716255645989-aegjdd…` | package `com.caarco.app`, empreinte `5e8f16…` ✅ |
> | Client Android `716255645989-aocosag…` | empreinte `bf1f6f…` (upload key **= clé de signature Play**, confirmé par Cedric) ✅ |
> | Doublons package+SHA (cause connue d'erreur 10) | aucun ✅ |
> | Client Web `716255645989-rk3kk5…` | même projet, présent dans le bundle ✅ |
> | URI de redirection Supabase | accepté par Google (flux OAuth testé) ✅ |
> | Écran de consentement | **En production** (confirmé par Cedric) ✅ |
>
> Les deux empreintes SHA-1 sont déclarées (`firebase apps:android:sha:list`).
>
> **Restent à vérifier** (non accessibles depuis le poste de dev) :
> 1. Google Auth Platform → **Accès aux données** : les scopes `openid`,
>    `userinfo.email`, `userinfo.profile` doivent y être déclarés.
> 2. **Cache Google Play Services** du téléphone (refus mis en cache lors des
>    tentatives du 22/08) → vider le cache + redémarrer.
>
> **Garde-fou livré** : interrupteur distant `google_signin_actif`
> (migration 153 + `src/services/configPublique.js`). Tant que la clé n'est pas
> à `'true'`, le bouton « Continuer avec Google » n'est pas affiché — aucun
> utilisateur ne peut donc tomber sur ce message. Migration **non appliquée**.

---

> ## ✅ CONFIGURATION TERMINÉE — 22/08/2026 (session 38)
>
> Les sections 1 à 6 ci-dessous sont **faites et vérifiées**. Elles restent en
> place comme référence, mais il n'y a plus rien à y exécuter :
>
> | Étape | État |
> |---|---|
> | 1. Clients OAuth Web + Android | ✅ créés (projet Firebase `caarco-19a88`) |
> | 2. Les 3 SHA-1 | ✅ déclarés |
> | 3. Provider Google Supabase | ✅ activé — Client ID **Web** en tête, **Android** en second |
> | 4. `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` | ✅ rempli (`App/.env` l. 27) ; Android en l. 40 |
> | 5. Migration 139 | ✅ déjà appliquée en prod (index partiel, 0 doublon / 32 comptes) |
> | 6. Recompilation | ✅ faite, Client ID confirmé inliné dans le bundle, APK installé |
> | 7. Tests 1 à 10 | ❌ **AUCUN déroulé** — voir le blocage ci-dessous |
>
> **Un seul point reste à ta main** : vérifier que l'écran de consentement OAuth
> est **publié** (« En production », pas « Test ») dans Google Cloud Console.
> En mode Test, seuls les comptes déclarés testeurs peuvent se connecter.
>
> ### ⛔ Ce qui bloque les tests (sans rapport avec Google)
>
> L'APK **debug** est un *dev-client* : il n'exécute pas son bundle embarqué, il
> attend un serveur Metro — et il échoue à le charger
> (`DevLauncherManifestParser.kt:30`). Réseau, manifeste, bundle, câblage natif et
> schéma URI ont tous été vérifiés bons ; un proxy espion a montré que l'app reçoit
> une réponse non-2xx **sans émettre la moindre requête** (réponse synthétique
> d'OkHttp). Détail complet dans `MEMORY.md`, session 38.
>
> **Contournement pour dérouler les tests : construire un APK RELEASE**
> (`build-release-usb.ps1`) — autonome, sans Metro, et plus fidèle à la production
> puisqu'il est signé avec l'upload key. Fermer Chrome avant : il faut de la RAM.
>
> ℹ️ Ajouté au passage, non commité : le schéma `caarco` (`app.json` +
> `AndroidManifest.xml`), qui n'existait nulle part. À recouper avec le retour
> Notchpay `caarco://tokens-confirmes` décrit dans CLAUDE.md.

---

> Le code est terminé et livré (voir « Ce qui a été codé » en bas).
> Il reste **3 actions manuelles** que je ne peux pas faire à ta place :
> les consoles Google Cloud et Supabase, puis la recompilation native.

---

## ⚠️ Point à trancher avant tout : la vérification du numéro par SMS

Le brief demandait « envoyer un OTP par SMS » pour vérifier le numéro d'un
utilisateur Google. **Ce n'est pas réalisable en l'état** : CAARCO n'a aucun
fournisseur SMS dans sa stack.

Le code OTP à 4 chiffres qui existe déjà dans l'app est le **code de livraison**
— il est affiché à l'écran du client puis dicté au transporteur, il n'a jamais
transité par SMS.

Ce qui a été livré : le numéro est enregistré **tel que déclaré**, exactement
comme à l'inscription classique par téléphone + mot de passe. Le niveau de
confiance est donc identique à celui d'aujourd'hui — ni meilleur, ni pire.

Deux garde-fous ont quand même été posés :

- un **numéro déjà utilisé est refusé** (contrôle applicatif + index unique en
  base, migration 139) ;
- la validation passe par une **seule fonction** (`completerProfilTelephone`),
  donc y insérer une vraie vérification SMS plus tard ne touchera qu'un fichier.

Si tu veux une vérification réelle, il faut choisir un fournisseur SMS
(Twilio, Vonage, ou un agrégateur local MTN/Orange Cameroun) — c'est un coût
récurrent par SMS. Dis-le-moi et je branche l'Edge Function.

---

## 1. Google Cloud Console — créer les identifiants OAuth

👉 https://console.cloud.google.com

1. **Sélectionner (ou créer) le projet** — si l'app utilise déjà Firebase pour
   les notifications push, prends **le même projet** que celui du fichier
   `App/android/app/google-services.json`.
2. **APIs et services → Écran de consentement OAuth**
   - Type : **Externe**
   - Nom de l'application : `CAARCO`
   - E-mail d'assistance : `cdtimene@gmail.com`
   - Domaine : `caarco-web.vercel.app` (ou le domaine final)
   - Publier l'application (sinon seuls les comptes testeurs peuvent se connecter)
3. **APIs et services → Identifiants → Créer des identifiants → ID client OAuth**

   **a) Client « Application Web »** ← c'est celui dont le code a besoin
   - Type : Application Web
   - Nom : `CAARCO Web (Supabase)`
   - URI de redirection autorisés :
     `https://dxwkikaniawpfljvteog.supabase.co/auth/v1/callback`
   - ➡️ **Copier le Client ID ET le Client Secret** (les deux vont dans Supabase)

   **b) Client « Android »** ← indispensable, même s'il n'apparaît nulle part dans le code
   - Type : Android
   - Nom : `CAARCO Android`
   - Nom du package : `com.caarco.app`
   - Empreinte SHA-1 : voir §2

> **Pourquoi le Client ID *Web* dans une app Android ?**
> C'est l'**audience** du jeton d'identité que Supabase vérifie côté serveur.
> Le client Android sert uniquement à Google pour authentifier l'APK (package +
> signature). Inverser les deux est l'erreur n°1 sur cette intégration.

---

## 2. Empreintes SHA-1 à déclarer

Il faut déclarer **plusieurs** empreintes sur le client Android (on peut en
ajouter autant qu'on veut, et en ajouter après coup).

### a) Debug (tests avec `build-debug.ps1` / `npm run android`)

Déjà relevée pour toi — c'est le keystore de debug Android standard :

```
5E:8F:16:06:2E:A3:CD:2C:4A:0D:54:78:76:BA:A6:F3:8C:AB:F6:25
```

### b) Upload key (le keystore local `caarco-release.keystore`)

À relever toi-même (la commande contient le mot de passe du keystore) :

```powershell
cd "D:\Mon projet\CAARCO\App\android\app"
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore caarco-release.keystore -alias caarco-release
# → saisir le mot de passe du keystore, puis copier la ligne "SHA 1:"
```

### c) 🔴 App signing key (Play Store) — **la plus importante**

CAARCO est déjà publiée sur le Play Store, donc Google **re-signe** l'AAB avec
sa propre clé. L'APK installé par tes utilisateurs ne porte **pas** la signature
de ton keystore local. Sans cette empreinte-là, la connexion Google marchera en
debug et échouera en production.

👉 Play Console → CAARCO → **Test et versions → Intégrité de l'application**
→ *Certificat de la clé de signature de l'application* → copier le **SHA-1**.

**Les trois empreintes doivent être ajoutées au client Android** (a et b pour
tes tests, c pour la production).

---

## 3. Supabase Dashboard — activer le provider Google

👉 https://supabase.com/dashboard → projet CAARCO → **Authentication → Providers → Google**

1. Activer **Enable Sign in with Google**
2. **Client ID (for OAuth)** : le Client ID **Web** de l'étape 1a
3. **Client Secret** : le secret du même client Web
4. **Authorized Client IDs** : y ajouter **le Client ID Android** de l'étape 1b
   *(champ souvent oublié — c'est lui qui autorise le jeton natif d'Android ;
   sans lui, Supabase renvoie « Unacceptable audience in id_token »)*
5. Enregistrer

---

## 4. Renseigner la clé dans l'app

Fichier `App/.env`, ligne déjà créée, vide pour l'instant :

```
EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID=1234567890-xxxxxxxxxxxx.apps.googleusercontent.com
```

⚠️ **Client ID *Web*** ici aussi, pas l'Android.
Tant que la valeur est vide, le bouton affiche
« La connexion Google n'est pas configurée sur cette version ». C'est voulu :
aucun crash, juste un message.

> Si tu utilises un jour **EAS Build cloud** (`eas build`), il faudra aussi
> ajouter cette variable aux blocs `env` de `App/eas.json` — les builds cloud ne
> lisent pas `.env`. Les scripts locaux (`build-debug.ps1`,
> `build-release-desktop.ps1`) le lisent, eux : rien à faire de ce côté.

---

## 5. Appliquer la migration 139 (base de données)

`App/supabase/migrations/139_google_signin_telephone_unique.sql`

Ajoute un **index unique** sur `users.telephone`. Sans lui, deux comptes
pourraient revendiquer le même numéro — ce qui casserait l'appel du transporteur
et la remise du code de livraison.

Opération sans danger : aucun DROP, aucune ligne modifiée, uniquement un index.
La migration s'interrompt d'elle-même avec un message clair si des doublons
existent déjà.

👉 Supabase Dashboard → **SQL Editor** → **nouvel onglet VIDE** → coller le
fichier **entier et seul** → Run.
*(rappel : le SQL Editor exécute tout l'onglet, même la partie hors écran)*

---

## 6. Recompiler l'application

`@react-native-google-signin/google-signin` (v16.1.4) contient du code natif.
**Un rechargement JS ne suffit pas** — il faut une recompilation :

```powershell
cd "D:\Mon projet\CAARCO"
.\build-debug.ps1          # ou : cd App ; npm run android
```

Le module natif est aussi la raison pour laquelle il est chargé **paresseusement**
dans `App/src/services/googleAuth.js` : si tu lances le bundle JS contre un APK
non recompilé, l'app démarre normalement et seul le bouton Google renvoie un
message d'erreur, au lieu de planter au lancement.

⚠️ Rappel RAM : garder au moins 2 Go libres avant un build release
(cf. `metro.config.js`, `maxWorkers = 2`).

---

## 7. Tests à faire sur le téléphone

| # | Scénario | Résultat attendu |
|---|----------|------------------|
| 1 | « Continuer avec Google », **nouveau** compte | Écran « Presque terminé ! » demandant le numéro |
| 2 | Saisir un numéro **libre** → Continuer | Entrée dans l'app côté client, nom repris de Google |
| 3 | Saisir un numéro **déjà utilisé** | « Ce numéro est déjà associé à un compte CAARCO. » |
| 4 | Saisir 8 chiffres au lieu de 9 | « Le numéro doit contenir 9 chiffres. » |
| 5 | « Annuler (Déconnexion) » | Retour à l'écran de connexion, session fermée |
| 6 | Tuer l'app et la rouvrir après le test 2 | Reconnexion directe, **pas** de redemande du numéro |
| 7 | Fermer le sélecteur de compte Google | Aucune erreur affichée, écran inchangé |
| 8 | Se reconnecter avec Google, **compte déjà complété** | Entrée directe dans l'app |
| 9 | Mode avion pendant l'étape 2 | Message d'erreur, **pas** de blocage sur l'écran de complétion |
| 10 | Compte téléphone + mot de passe classique | Fonctionne exactement comme avant |

---

## Ce qui a été codé

| Fichier | Rôle |
|---|---|
| `App/src/services/googleAuth.js` | Sélecteur de compte Google, chargement natif paresseux, erreurs traduites, annulation silencieuse |
| `App/src/services/googleAuth.web.js` | Refus propre côté web (le back-office admin ne doit pas embarquer le module natif) |
| `App/src/services/auth.js` | `seConnecterAvecGoogle()`, `completerProfilTelephone()`, `obtenirProfilOuNull()`, oubli du compte Google à la déconnexion |
| `App/src/context/AuthContext.js` | Nouvel état `etatProfil` : `anonyme` / `chargement` / `incomplet` / `complet` |
| `App/src/navigation/RootNavigator.js` | Barrière : profil incomplet → `CompleterProfilScreen`, sans accès possible à l'app |
| `App/src/screens/auth/ConnexionScreen.js` | Bouton Google branché |
| `App/src/screens/auth/CompleterProfilScreen.js` | Enregistrement du numéro, contrôles, déconnexion |
| `App/src/i18n/fr.js` · `en.js` | Libellés `auth.completerProfil.*` et `auth.connexion.google/ou/erreurGoogle` |
| `App/supabase/migrations/139_…sql` | Index unique sur `users.telephone` |
| `App/.env` | `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` (à remplir) |

### Comment l'app sait qu'il faut afficher « Compléter mon profil »

C'était la question architecturale du brief. La réponse **ne passe pas** par une
navigation manuelle depuis l'écran de connexion — elle est déclarative :

1. `signInWithIdToken` ouvre une session Supabase, mais ne crée **aucune** ligne
   dans `public.users` (aucun trigger sur `auth.users` dans ce projet).
2. `AuthContext` charge le profil avec `obtenirProfilOuNull` — qui distingue
   **« aucune ligne »** d'une **erreur réseau**. C'est la distinction critique :
   sans elle, une simple coupure réseau renverrait un utilisateur établi vers
   l'écran de complétion.
3. Il en dérive `etatProfil`.
4. `RootNavigator` monte l'écran correspondant. `CompleterProfilScreen` est
   **seul dans son Stack** : aucun retour vers l'app n'est possible, la seule
   sortie est la déconnexion.
5. Une fois le numéro enregistré, `rafraichirProfil()` fait passer `etatProfil`
   à `complet` et l'app se monte toute seule.

`CompleterProfilScreen` a été **sorti** du Stack non authentifié où il se
trouvait : il y était inatteignable, puisqu'un utilisateur Google a bel et bien
une session (`user` non nul).

### Deux conséquences à connaître

- **Un compte Google et un compte téléphone sont deux identités distinctes.**
  Un compte classique a pour e-mail interne `{telephone}@caarco.local`, un compte
  Google garde son vrai e-mail Google. Ils ne peuvent pas être fusionnés depuis
  l'app. Un utilisateur Google se reconnecte donc **toujours** par Google — le
  lien « mot de passe oublié » ne le concerne pas.
- **Si le numéro d'un utilisateur Google appartient déjà à un compte classique,
  il est refusé** avec un message l'invitant à se connecter par mot de passe.
  C'est volontaire : un numéro identifie une seule personne dans toute l'app.
  Si tu veux permettre la fusion des deux comptes, c'est un chantier à part
  (Edge Function avec `service_role`) — dis-le-moi.
