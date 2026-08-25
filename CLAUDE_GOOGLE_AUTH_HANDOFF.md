> ✅ **TRAITÉ le 22/08/2026.** Tout le code des points 2 à 5 est écrit et livré.
> Restent 3 actions manuelles (consoles Google Cloud + Supabase, recompilation
> native) : **voir [GOOGLE_SIGNIN_CONFIG.md](GOOGLE_SIGNIN_CONFIG.md)**.
>
> ⚠️ Réserve sur le point 5 : l'envoi d'un OTP **par SMS** n'est pas réalisable —
> CAARCO n'a aucun fournisseur SMS (l'OTP à 4 chiffres existant est le code de
> livraison affiché à l'écran). Le numéro est enregistré tel que déclaré, comme
> à l'inscription classique, avec refus des doublons. Détails dans le guide.

---

# Intégration Google Sign-in : Tâches Backend / Supabase pour Claude

Le frontend et le design (Bouton Google, Écran `CompleterProfilScreen`) ont été gérés et sont en place.
**Ta mission, Claude**, est d'implémenter toute la logique métier, la configuration Supabase, et l'intégration de la librairie native.

Voici les étapes exactes :

## 1. Google Cloud & Supabase (Console / Dashboard)
Tu dois guider Cedric pour configurer ces éléments :
- **Google Cloud Console** : Générer un Client ID Web et un Client ID Android.
- **Supabase Dashboard** : Activer le provider Google et y insérer le Client ID Web.

## 2. Installation de la dépendance native
- L'application est en **Expo Bare Workflow** (SDK 54).
- Il faut installer : `npm install @react-native-google-signin/google-signin`
- *(Important : Il faudra relancer la compilation native `npm run android` puisque c'est une librairie contenant du code natif).*

## 3. Configuration de Google Sign-in dans le Frontend
Dans `src/screens/auth/ConnexionScreen.js` (où se trouve le `BoutonGoogle` déjà créé) :
- Initialiser `GoogleSignin.configure({ webClientId: '...' })`.
- Coder la fonction appelée par le bouton : 
  1. `await GoogleSignin.hasPlayServices()`
  2. `const { data } = await GoogleSignin.signIn()`
  3. `const idToken = data?.idToken`
  4. Appeler la méthode `seConnecterAvecGoogle(idToken)` (à créer dans `auth.js`).

## 4. Logique métier `auth.js`
Dans `src/services/auth.js` :
- Créer la méthode `export async function seConnecterAvecGoogle(idToken)`.
- Elle doit exécuter : `await supabase.auth.signInWithIdToken({ provider: 'google', token: idToken })`.

## 5. Le problème du "Numéro de téléphone obligatoire"
CAARCO exige un numéro de téléphone valide. Google ne le donne pas.
Si un utilisateur se connecte pour la première fois avec Google :
- Son entrée dans la table `users` n'aura pas de numéro de téléphone.
- L'écran `CompleterProfilScreen` (que j'ai créé) est déjà appelé par le `RootNavigator` (il est dans le Stack `auth`).
- **Ta tâche architecturale** : Gérer la redirection. Comment le `RootNavigator.js` ou l'`AuthContext` sait-il qu'il faut afficher `CompleterProfilScreen` plutôt que de le laisser entrer dans `AppNavigator` ? 
- Dans `CompleterProfilScreen.js`, j'ai laissé un commentaire `TODO Claude:` dans la méthode `validerTelephone`. Tu dois y implémenter l'envoi d'OTP pour ce numéro et la mise à jour de la table `users`. 

À toi de jouer !
