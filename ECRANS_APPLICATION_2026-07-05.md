# CAARCO — Détail des 67 écrans de l'application mobile
**Date du scan : 5 juillet 2026** · Extraction faite directement depuis le code source (`App/src/screens/`), fichier par fichier.

## Méthodologie et légende

Pour chaque écran : rôle/accès, objectif, tous les textes affichés (copiés mot pour mot depuis le code), les couleurs utilisées (tokens `colors.xxx` + tout hex en dur détecté), les icônes, les images/visuels, les composants Atelier CAARCO utilisés, et la structure/layout général.

Légende des tokens de couleur (`App/theme.js`) :
- `foret` #1f3b2a (primaire), `foret90` #284a36, `foret70` #426356, `foret30` #b4c4b9, `foret10` #e6ede7
- `bambou` #3d6b4a (succès/action), `bambouSoft` #cfdbcf
- `nere` #c89441 (accent/prix), `nereSoft` #f1e3c2
- `laterite` #b8612e (erreur/alerte), `lateriteSoft` #f1d6c3
- `manioc` #fbf9f3 (fond principal), `brume` #ece9e0 (fond secondaire), `cendre` #6b6f68 (texte secondaire), `charbon` #1d2420 (texte principal), `nuit` #0f1411, `blanc` #ffffff
- Une palette sombre équivalente (`darkColors`) s'active automatiquement selon le thème système.
- Polices : `display` = Marcellus (titres), `body/bodyMed/bodySemi/bodyBold` = Plus Jakarta Sans, `mono` = JetBrains Mono (montants FCFA, codes OTP).

---

# AUTHENTIFICATION (4 écrans)

## 1. SplashScreen.js
`App/src/screens/auth/SplashScreen.js`

**Rôle / accès** : Tout utilisateur non authentifié, premier écran affiché au lancement de l'app (avant Connexion).
**Objectif de l'écran** : Écran d'accueil animé de la marque CAARCO (logo, camions animés, particules), avec redirection automatique ou manuelle vers l'écran de connexion.

**Textes affichés à l'écran** :
- "CAARCO" (nom de l'app)
- "Votre partenaire transport{'\n'}au Cameroun" (tagline)
- "Livraisons rapides et sécurisées{'\n'}partout au Cameroun" (description)
- "Commencer" (bouton CTA)
- "→" (flèche du bouton)
- "CAMEROUN" (label sous le bouton)

**Couleurs** :
- `colors.nuit`, `colors.foret`, `colors.foret90` → dégradé `LinearGradient` de fond, du haut (nuit) vers le bas (foret90), `locations={[0, 0.55, 1]}`
- `colors.nere` → couleur des particules flottantes et du bouton CTA
- `colors.blanc` → texte "CAARCO", tagline, texte du bouton
- `colors.foret30` → description, label "CAMEROUN"
- `colors.foret90` → couleur de la ligne de route
Aucun code hexadécimal en dur.

**Icônes** : Aucune bibliothèque d'icônes importée. Emoji utilisé comme visuel : 🚛 (camion animé traversant l'écran, 3 instances avec délais/vitesses différents).

**Images / visuels** : `require('../../../assets/Logo CAARCO Light PNG.png')` (logo affiché en haut, animé en fondu + zoom). Pas de carte, pas d'avatar.

**Composants Atelier CAARCO utilisés** : Aucun (uniquement composants React Native natifs + `LinearGradient` d'Expo).

**Structure / layout** : `LinearGradient` plein écran ; particules flottantes animées en fond ; zone centrale avec logo + nom + tagline + description (animations d'entrée séquentielles : logo → titre → sous-titre → bouton) ; zone "route" avec ligne pointillée et 3 camions emoji animés en boucle horizontale ; bouton CTA "Commencer" en bas avec redirection automatique après 4 secondes (`navigation.replace('Connexion')`) ou manuelle au tap.

---

## 2. ConnexionScreen.js
`App/src/screens/auth/ConnexionScreen.js`

**Rôle / accès** : Utilisateur non authentifié.
**Objectif de l'écran** : Permettre à l'utilisateur de choisir entre se connecter ou créer un compte, puis saisir ses identifiants (téléphone + mot de passe) pour se connecter.

**Textes affichés à l'écran** (via i18n `t()`, valeurs françaises réelles du fichier `fr.js`) :
- "Bienvenue" (titre, écran de choix, texte en dur)
- "Votre transport, livré en quelques clics." (sous-titre, texte en dur)
- "LOGIN" (bouton, texte en dur)
- "SIGN UP" (bouton, texte en dur)
- "Mot de passe oublié ?" (lien, texte en dur)
- `t('auth.connexion.titre')` → "Connexion" (titre formulaire)
- `t('auth.connexion.telephone')` → "Numéro de téléphone" (label)
- `t('auth.connexion.telPlaceholder')` → "6XX XXX XXX" (placeholder)
- `t('auth.connexion.motDePasse')` → "Mot de passe" (label)
- "••••••••" (placeholder mot de passe, en dur)
- `t('auth.connexion.chargement')` → "Connexion…" (texte bouton en chargement)
- `t('auth.connexion.bouton')` → "Se connecter" (texte bouton)
- `t('auth.connexion.mdpOublie')` → "Mot de passe oublié ?"
- `t('auth.connexion.reinitialiser')` → "Réinitialiser"
- `t('auth.connexion.erreurVide')` → "Remplissez tous les champs." (erreur si champs vides)
- `t('auth.connexion.erreurCredentials')` → "Numéro ou mot de passe incorrect." (erreur de connexion)

**Couleurs** :
- `colors.nuit` → fond de l'écran
- `colors.manioc` → fond de la carte flottante
- `colors.charbon` → titre
- `colors.cendre` → sous-titre, texte des liens, icône retour
- `colors.brume` → fond du bouton retour
- `colors.foret30` → bordure des champs `Sillon`
- `colors.nere` → bouton principal (login/formulaire), `nereSoft` → bouton en chargement
- `colors.blanc` → texte des boutons, fond du cercle flèche
- `colors.foret` → icône flèche dans le bouton
- `colors.bambou` → bouton "SIGN UP", lien accent "Réinitialiser"
- Dégradé `LinearGradient` en dur : `['rgba(15,20,17,0.15)', 'rgba(15,20,17,0.55)']` (ligne ~87), superposé sur l'image de fond (valeurs RGB correspondant à `colors.nuit` #0f1411 avec opacités croissantes du haut vers le bas).

**Icônes** : `Ionicons` (`@expo/vector-icons`) — `arrow-back` (bouton retour du formulaire), `call-outline` (champ téléphone, via `iconeGauche`), `lock-closed-outline` (champ mot de passe), `arrow-forward` (bouton de soumission).

**Images / visuels** : `require('../../../assets/images/fond_connexion.png')` (fond desktop, `IMG_WEB`) et `require('../../../assets/images/tricycle.png')` (fond mobile, `IMG_MOBILE`) — image plein écran en arrière-plan, choisie dynamiquement selon `desktop` (via `useLayoutMode`).

**Composants Atelier CAARCO utilisés** : `Sillon` (champs téléphone/mot de passe), `Bandeau` (message d'erreur).

**Structure / layout** : Image de fond plein écran + overlay dégradé ; layout horizontal avec espace vide à gauche (desktop) et panneau/carte à droite ; deux états visuels : (1) écran de choix (titre + sous-titre + boutons LOGIN/SIGN UP + lien mot de passe oublié), (2) formulaire de connexion (header avec retour, bandeau d'erreur, champs téléphone/mot de passe, bouton de connexion animé au press, lien réinitialisation). Animations d'entrée (translation + fondu) sur la carte et sur le formulaire.

---

## 3. InscriptionScreen.js
`App/src/screens/auth/InscriptionScreen.js`

**Rôle / accès** : Utilisateur non authentifié souhaitant créer un compte.
**Objectif de l'écran** : Collecter les informations d'inscription (nom, téléphone, mot de passe, genre, date de naissance, ville, code de parrainage optionnel) et créer le compte.

**Textes affichés à l'écran** :
- `t('commun.retour')` → "Retour" (lien retour)
- `t('auth.inscription.titre')` → "Créer un compte"
- `t('auth.inscription.sousTitre')` → "Rejoignez CAARCO au Cameroun"
- `t('auth.inscription.nomComplet')` → "Nom complet"
- `t('auth.inscription.nomPlaceholder')` → "Jean Fomekong"
- `t('auth.inscription.telephone')` → "Numéro de téléphone"
- `t('auth.inscription.telPlaceholder')` → "6XX XXX XXX"
- `t('auth.inscription.motDePasse')` → "Mot de passe"
- `t('auth.inscription.mdpPlaceholder')` → "Minimum 6 caractères" (placeholder + texte d'info)
- "Genre " + "*" (astérisque obligatoire, en dur)
- "Homme", "Femme" (labels des chips de genre, en dur)
- "Date de naissance " + "*" + " (min. 15 ans)" (en dur)
- `labelDateNaissance()` → "Sélectionner votre date de naissance" (placeholder) ou template littéral : `` `${dateNaissance.toLocaleDateString('fr-FR', {...})} · ${age} ans` ``
- "Ville " + "*" (en dur)
- "Choisir votre ville…" (placeholder, en dur)
- `t('auth.inscription.parrainage')` → "Code de parrainage (optionnel)"
- `t('auth.inscription.parrainagePlaceholder')` → "Ex : ABC123"
- `t('auth.inscription.parrainageInfo')` → "Laissez vide si vous n'avez pas de code"
- `t('auth.inscription.bouton')` → "Créer mon compte"
- `t('auth.inscription.dejaCompte')` → "Déjà un compte ?"
- `t('auth.inscription.seConnecter')` → "Se connecter"
- Erreurs : `t('auth.inscription.erreurVide')` → "Veuillez remplir tous les champs.", `t('auth.inscription.erreurMdpCourt')` → "Le mot de passe doit contenir au moins 6 caractères.", "Veuillez sélectionner votre genre." (en dur), "Veuillez sélectionner votre ville." (en dur), "Veuillez sélectionner votre date de naissance." (en dur), `t('auth.inscription.erreurCreation')` → "Erreur lors de la création du compte." (fallback si `e.message` absent)

**Couleurs** :
- `colors.nuit` → fond écran
- `colors.manioc` → fond carte flottante
- `colors.charbon` → titre, texte des pickers
- `colors.cendre` → sous-titre, texte retour, labels, placeholders
- `colors.laterite` → astérisque obligatoire
- `colors.foret` → chip actif (genre), icônes actives, lien "Se connecter"
- `colors.blanc` → texte/icônes sur fond actif
- `colors.brume` → bordures des chips/pickers
- Dégradé `LinearGradient` en dur (mêmes valeurs que ConnexionScreen) : `['rgba(15,20,17,0.15)', 'rgba(15,20,17,0.55)']`

**Icônes** : `Ionicons` — `arrow-back` (retour), `person-outline` (nom), `call-outline` (téléphone), `lock-closed-outline` (mot de passe), `male-outline` / `female-outline` (genre), `calendar-outline` (date de naissance), `close-circle` (effacer sélection date/ville), `chevron-down` (indicateur picker fermé), `location-outline` (ville), `gift-outline` (parrainage).

**Images / visuels** : `require('../../../assets/images/fond_connexion.png')` (`IMG_WEB`) / `require('../../../assets/images/tricycle.png')` (`IMG_MOBILE`), image plein écran de fond selon `desktop`.

**Composants Atelier CAARCO utilisés** : `CalendrierNaissance` (modal sélection date), `SelecteurVille` (modal sélection ville), `Galet` (bouton "Créer mon compte"), `Sillon` (champs texte), `Bandeau` (erreur).

**Structure / layout** : Image de fond + overlay dégradé ; layout horizontal (espace vide + carte à droite en desktop) ; `ScrollView` avec carte flottante contenant : lien retour, titre/sous-titre, formulaire (bandeau erreur, champs nom/téléphone/mot de passe, chips genre, picker date de naissance, picker ville, champ parrainage), bouton de soumission `Galet`, lien vers connexion. Deux modals (calendrier, sélecteur de ville) superposés.

---

## 4. MotDePasseOublieScreen.js
`App/src/screens/auth/MotDePasseOublieScreen.js`

**Rôle / accès** : Utilisateur non authentifié ayant oublié son mot de passe.
**Objectif de l'écran** : Générer et afficher un mot de passe temporaire à partir du numéro de téléphone (via Edge Function `reset-mot-de-passe`), sans révéler si le compte existe.

**Textes affichés à l'écran** :
- Étape 1 : "Mot de passe oublié" (titre), "Saisissez votre numéro de téléphone. Un mot de passe temporaire vous sera affiché." (sous-titre), "Numéro de téléphone" (label), "6XX XXX XXX" (placeholder), "Obtenir un mot de passe temporaire" (bouton), "Pour votre sécurité, changez ce mot de passe temporaire dès votre connexion dans Profil → Changer le mot de passe." (avertissement)
- Erreur : "Veuillez saisir votre numéro de téléphone." ; "Impossible de traiter la demande. Réessayez." (catch générique, valeur par défaut si `e.message` absent)
- Étape 2 (succès) : "Mot de passe temporaire" (titre), "Utilisez ce code pour vous connecter, puis changez-le immédiatement dans vos paramètres." (sous-titre), `{tempPassword}` (code affiché, valeur dynamique), "Copié !" / "Maintenir appuyé pour copier" (état du bouton copier), "Retour à la connexion" (bouton)

**Couleurs** :
- `colors.manioc` → fond de l'écran
- `colors.foret10` → fond du bouton retour
- `colors.foret` → icônes (retour, `lock-open-outline`, `key-outline`, `codeValeur` texte)
- `colors.bambou` → icône succès (`key-outline`), état "copié" (icône + texte)
- `colors.bambouSoft` → fond du cercle icône succès
- `colors.charbon` → titres
- `colors.cendre` → sous-titres, texte "Maintenir appuyé pour copier" (état par défaut), avertissement
- `colors.brume` → fond avertissement
- `colors.blanc` → fond du bloc code
Aucun code hexadécimal en dur.

**Icônes** : `Ionicons` — `arrow-back` (retour), `key-outline` (icône succès), `checkmark-circle` / `copy-outline` (état copie, selon `copie`), `lock-open-outline` (icône étape 1), `information-circle-outline` (avertissement).

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Galet` (boutons de soumission et retour), `Sillon` (champ téléphone), `Bandeau` (erreur).

**Structure / layout** : Deux états distincts selon `tempPassword` : (1) formulaire de saisie du téléphone (icône, titre, sous-titre, bandeau erreur, champ téléphone, bouton, bloc d'avertissement) dans un `ScrollView` ; (2) écran de succès centré avec icône, titre, message, bloc code (appui long = copier, avec feedback visuel), bouton retour vers connexion.

---

# CLIENT (18 écrans)

## 5. AccueilScreen.js
`App/src/screens/client/AccueilScreen.js`

**Rôle / accès** : Client connecté (écran d'accueil du parcours client, premier écran après connexion/onboarding).
**Objectif de l'écran** : Point d'entrée principal du client — montre la carte OSM avec les transporteurs proches, permet de démarrer une commande, présente les services/tarifs par catégorie de véhicule, les points fidélité, une bannière de course active, et le programme de parrainage.

**Textes affichés à l'écran** :
- Tutoriel (TutorielPopup) : "Bienvenue sur CAARCO !" / "Vous voyez ici la carte avec les transporteurs disponibles près de vous. Chaque point coloré est un transporteur en ligne." ; "Commander une livraison" / "Appuyez sur 'Commander' ou choisissez une catégorie de véhicule pour démarrer une course." ; "Vos points fidélité" / "Chaque livraison complétée vous rapporte des points échangeables contre des avantages CAARCO."
- Catégories véhicule : "Moto" / "Petits colis légers" / "150 XAF/km" ; "Voiture" / "Bagages, courses" / "300 XAF/km" ; "Tricycle / Van" / "Marchandises, petit déménag." / "500 XAF/km" ; "Camion" / "Grand déménagement" / "1200 XAF/km"
- Statuts course (dead code, `CarteTrajetRecent` non rendu) : "En attente", "Acceptée", "En cours", "Terminée"
- Services (carrousel "Nos Services") : "Moto Express" / "150 XAF/km" / "1-2 places" ; "Voiture" / "300 XAF/km" / "4 places" ; "Camionnette" / "500 XAF/km" / "Charges moyennes" ; "Gros Camion" / "1200 XAF/km" / "Charges lourdes"
- Modal badge vérifié : "Badge Vérifié CAARCO" ; "Ce bouclier indique que le transporteur a complété la vérification d'identité CAARCO et a été approuvé par notre équipe." ; "Conditions pour l'obtenir" ; "Photo de la carte nationale d'identité (CNI) valide" ; "Photo du permis de conduire en cours de validité" ; "Photos du véhicule de transport (avant, arrière, intérieur)" ; "Validation par l'équipe CAARCO sous 48h" ; "Avantages du badge" ; "Confiance accrue des clients, badge visible sur votre profil" ; "Priorité dans la mise en relation avec les demandes" ; "Accès aux courses et clients premium" ; "Meilleure visibilité dans les résultats de recherche" ; bouton "Compris"
- Salutation dynamique : "Bonjour", "Bonsoir", "Bonne nuit" ; `{salutation},` ; `{prenom} 👋`
- "En ligne maintenant" (titre stories)
- Bannière récompense : "Vous avez une surprise !" / "Appuyez pour révéler votre récompense"
- Carte réservation : "Envoyer un colis" ; "Cameroun · Livraison rapide" ; "D'où partez-vous ?" ; "Où livrer ?" ; "Continuer →"
- "Transporteurs disponibles" (titre section carte)
- "Aucun transporteur à proximité" (carte vide)
- Callout transporteur : `★ {note} · {type_vehicule}` ; "Profil" ; "Choisir"
- "Nos Services" ; "Voir les tarifs →"
- Bannière course active : "Course en cours" ; `{depart_adresse} → {arrivee_adresse}`
- "Commander maintenant" (CTA principal)
- Bannière parrainage : "Parrainez vos proches" ; "Gagnez 20 pts à chaque filleul inscrit"
- "Cameroun" (tag ville)
- Modal récompense : titre conditionnel "Statut VIP CAARCO !" / "1 course gratuite !" / `-${pct_reduction}% sur votre prochaine course` ; sous-texte "Félicitations ! Vous avez effectué 100 courses avec CAARCO. Statut VIP activé à vie." / `Votre prochaine course est offerte jusqu'à 5 000 XAF. Valable 30 jours.` / `Réduction appliquée automatiquement sur votre prochaine commande. Valable 30 jours.` ; `🏆 Jalon {course_jalon} courses atteint !` ; bouton "Merci CAARCO !" / "Utiliser lors de ma prochaine course" ; "Plus tard"

**Couleurs** : `colors.foret` (carte réservation, CTA principal), `colors.bambou` (marqueurs moto, points forts), `colors.nere` (accent prix, néré badges), `colors.laterite` (marqueur camion), `colors.manioc` (fond), `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.bambouSoft`, `colors.nereSoft`, `colors.foret10`, `colors.foret30`. Codes hexadécimaux en dur : `#e8e0d5` (fond placeholder de la carte avant chargement) ; dégradés `SERVICES_LISTING` : `['#2a5c3a', colors.foret]`, `['#3d5c8a', '#1e2e50']`, `['#6b2e2e', '#3d1515']` (fonds des cartes services sans photo) ; overlay sombre `['transparent', 'rgba(5,12,8,0.72)', 'rgba(5,12,8,0.93)']` ; `colors.foret10 ?? '#e8f0ea'` (fallback bannière course active) ; `rgba(15,20,17,0.55)` (fond modal badge vérifié) ; `#25D366` (style `btnWhatsapp`, défini mais non rendu). Dégradés `LinearGradient` utilisés pour le fond des cartes "Nos Services" et l'overlay sombre en bas de ces cartes.

**Icônes** : Ionicons. `shield-checkmark` (modal badge), `star` (avantages badge, points badge header), `chevron-forward` (bannière récompense, callout, bannière course active, bannière parrainage), `cube-outline` (header carte réservation), `close` (fermer callout), `person-outline` (voir profil callout), `checkmark-circle-outline` (choisir TR callout), `locate` (recentrer carte), icônes dynamiques par service (`bicycle-outline`, `car-outline`, `car-sport-outline`, `bus-outline`), `gift-outline` (parrainage), `location` (tag ville). Emojis : 👋 (salutation), 🎁 (bannière récompense), 👑 / 🆓 / 🎉 (modal récompense selon type), 🏆 (jalon). `MARQUEUR_VEHICULE` définit aussi 🛵🚗🚐🚛 mais uniquement pour `CarteTrajetRecent`, non monté (code mort).

**Images / visuels** : `require('../../../assets/images/tricycle.png')` (photo de fond carte "Camionnette"). `CarteLeaflet` (carte OSM WebView) affichant marqueurs transporteurs + position client. `Mereau` (avatars stories et header, `photoUrl` distant).

**Composants Atelier CAARCO utilisés** : Mereau, BadgeVerifie, Plaquette (callout carte), BoutonAnime (CTA), TutorielPopup. Hors liste : BannierePublicite, BoutonSignalementCarte.

**Structure / layout** : SafeAreaView + ScrollView unique. Sections : header (salutation, prénom, badge points, avatar), stories horizontales TR en ligne, bannière publicitaire, bannière récompense (conditionnelle), carte de réservation (fond forêt, CTA), section carte GPS (CarteLeaflet, zoom, callout TR, recentrer, signalement, état vide), carrousel "Nos Services" (boucle auto-scroll + dots), bannière course active (conditionnelle), CTA "Commander maintenant", bannière parrainage, tag ville. Overlays : TutorielPopup, Modal récompense, Modal badge vérifié.

---

## 6. TrajetScreen.js
`App/src/screens/client/TrajetScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Saisie du trajet (départ/arrivée via texte, GPS ou carte), sélection du véhicule, bascule immédiat/planifié, calcul du prix estimé, avant de passer à l'écran des détails du colis.

**Textes affichés à l'écran** :
- Tutoriel : "Saisissez vos adresses" / "Entrez l'adresse de collecte puis l'adresse de livraison." ; "Choisissez votre véhicule" / "Sélectionnez le type de véhicule adapté à votre colis." ; "Estimation du prix" / "Le prix est calculé automatiquement selon la distance et le véhicule."
- Véhicules : "Moto", "Voiture", "Camionnette", "Camion"
- Compteur transporteurs flottant : `{n} disponible{s}`
- Fiche TR sélectionné : `★ {note} · {label véhicule}`
- Toggle mode : "Maintenant" / "Planifier"
- Badge date planifiée : date formatée `weekday day month à HHhMM`
- "Choisissez un véhicule pour continuer"
- Champs Sillon : label "Départ" placeholder "Point de collecte…" ; label "Destination" placeholder "Où livrer ?"
- Messages d'erreur GPS : "La localisation automatique est imprécise sur navigateur. Tapez votre adresse de départ dans le champ ci-dessus." ; `GPS imprécis (±{precision} m) — sortez à l'extérieur pour un meilleur signal, ou tapez votre adresse.` ; "Impossible d'obtenir votre position." ; "Adresse non trouvée — utilisez le bouton carte →"
- Bloc prix : "PROGRAMMÉE" / "ESTIMATION" ; `~ {prix}` ; `+{pct}% programmé` (+ " · +10% pointe" si applicable) ; "Calcul prix programmé…" / "Calcul en cours…" ; `{km} km`
- Bouton final : `Planifier · {date} {heure}` ou "Commander maintenant"
- Modal lieu GPS — confirmation : "Votre position GPS" ; nom du lieu existant ; "C'est bien ce lieu ?" ; "Non, corriger" / "Oui, c'est ici"
- État nom : "Quel est ce lieu ?" ; "Ce point n'est pas encore enregistré. Donnez-lui un nom pour enrichir la carte CAARCO." ; placeholder "Ex : Carrefour Gouache, Marché du lundi…" ; "Enregistrer et continuer"
- État correction : "Corriger le nom" ; "Nom actuel : {nom}\nVotre correction sera appliquée si 3 personnes proposent le même nom." ; placeholder "Nom correct de ce lieu…" ; "Retour" / "Soumettre"
- `LocationPicker` : titre "Sélectionner le départ" / "Sélectionner la destination" ; instruction "Glissez la carte pour placer le repère sur le point de collecte" / "...de livraison" ; étiquette "DÉPART" / "DESTINATION"

**Couleurs** : `colors.bambou`, `colors.foret`, `colors.nere`, `colors.laterite` (marqueurs TR), `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.foret10`, `colors.bambouSoft`, `colors.nereSoft`, `colors.foret90`. Hex en dur : `'#e8e0d5'` (fond plein écran, beige derrière la carte). Alpha : `colors.foret + '12'` et `colors.foret + '30'` (fond/bordure badge date). Pas de `LinearGradient`.

**Icônes** : Ionicons + MaterialCommunityIcons. Ionicons : `arrow-back`, `locate`, `map-outline`, `close`, `flash` (mode Maintenant), `calendar-outline`/`calendar` (Planifier), `pencil-outline`, `location-outline`/`navigate-outline`, `navigate`, `sync-outline`, `checkmark-circle`, `location`. MaterialCommunityIcons : `motorbike`, `car`, `truck-delivery`, `truck` (sélection véhicule). Emojis (`MARQUEUR_TR`) : 🛵 🚗 🚐 🚛 (avatar fiche TR sélectionné).

**Images / visuels** : `CarteLeaflet` (carte OSM plein écran, marqueurs client/TR/départ/arrivée, polyline OSRM). `LocationPicker` (×2). `ContributionModal`. `PlanificateurCourse`. Aucune image locale.

**Composants Atelier CAARCO utilisés** : Sillon (champs adresse). LocationPicker, ContributionModal, PlanificateurCourse hors liste Atelier nommée.

**Structure / layout** : Zone carte plein écran en haut (se rétracte si clavier ouvert) avec boutons flottants (retour, compteur TR, contribuer, recentrer). Panneau bas arrondi (max 65% écran) : fiche TR sélectionné (conditionnelle), toggle Maintenant/Planifier, badge date, boutons véhicule, champs Départ/Destination avec GPS/carte + suggestions, bloc prix, bouton Commander/Planifier. Overlays : TutorielPopup, 2× LocationPicker, ContributionModal, Modal lieu GPS (3 sous-états), PlanificateurCourse.

---

## 7. DetailsColisScreen.js
`App/src/screens/client/DetailsColisScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Étape 2/4 de la commande — saisir les détails du colis (mode de tarification, poids/quantité, dimensions, catégorie) et ajouter au moins une photo obligatoire avant de voir le prix.

**Textes affichés à l'écran** :
- Header : "Détails du colis" ; "Étape 2 sur 4"
- Modes de tarification : "Au poids", "Au volume", "Forfait"
- "Poids & quantité" ; champs "Poids (facultatif)" (unité "kg"), "Nb de colis" (unité "pcs", placeholder "1")
- "Dimensions (facultatif)" ; champs "Longueur", "Largeur", "Hauteur" (unité "cm")
- "Catégorie" ; options : "Vêtements", "Électronique", "Alimentaire", "Documents", "Fragile", "Autre"
- `Photos du colis ({n}/3)` ; badge "Obligatoire" ; "Au moins 1 photo est requise pour continuer" ; boutons "Caméra", "Galerie"
- Erreurs : "Autorisez l'accès à la caméra dans les réglages." ; "Autorisez l'accès à la galerie dans les réglages." ; "Impossible d'accéder à la caméra ou à la galerie." ; "Veuillez ajouter au moins une photo du colis avant de continuer."
- CTA : "Voir le prix →"

**Couleurs** : `colors.charbon`, `colors.cendre`, `colors.foret` (pills actifs, icônes boutons photo), `colors.blanc`, `colors.brume`, `colors.manioc`, `colors.laterite` (badge/texte "Obligatoire", alerte), `colors.lateriteSoft`, `colors.foret30`, `colors.foret10`. Aucun hex en dur. Pas de `LinearGradient`.

**Icônes** : Ionicons. `chevron-back`, `barbell-outline`/`cube-outline`/`pricetag-outline` (tarification), `shirt-outline`/`phone-portrait-outline`/`basket-outline`/`document-text-outline`/`warning-outline`/`apps-outline` (catégories), `camera-outline`, `image-outline`, `close-circle`.

**Images / visuels** : Photos via `expo-image-picker`, vignettes `<Image source={{ uri }}>` (URIs locales). Aucune image statique, aucun `CarteLeaflet`.

**Composants Atelier CAARCO utilisés** : Bandeau (erreur). Pas de Galet/Plaquette (styles pill custom).

**Structure / layout** : Header (retour, titre, "Étape 2 sur 4", 4 points de progression). ScrollView : mode tarification (pills), poids & quantité (2 colonnes), dimensions (3 colonnes), catégorie (grille pills), photos (compteur, alerte si vide, vignettes + boutons). Pied fixe : CTA "Voir le prix →" désactivé sans photo. Bandeau d'erreur en haut.

---

## 8. ConfirmationScreen.js
`App/src/screens/client/ConfirmationScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Récapitulatif final avant création de la course — trajet, véhicule, distance (Haversine puis affinée par OSRM), prix calculé côté serveur (RPC `calculer_prix`), choix du mode de paiement du transporteur, puis confirmation (course immédiate ou programmée).

**Textes affichés à l'écran** :
- Majorité des libellés via i18n `t()` : `t('confirmation.titre')`, `t('confirmation.erreurPaiement')`, `t('confirmation.erreurPrixCalc')`, `t('confirmation.erreurDistance', {km})`, `t('confirmation.erreurDistZero')`, `t('confirmation.boutonModifier')`, `t('commun.chargement')`, `t('confirmation.boutonCalc')`, `t('confirmation.boutonConfirmer')`, `t('confirmation.prixErreur')`.
- Littéraux : "TRAJET", "DÉPART", "ARRIVÉE", "VÉHICULE" ; distance dynamique : `${distanceKm} km · Calcul itinéraire réel…` / `${distanceKm} km (route réelle)` / `${distanceKm} km (estimé ×1.5)` / "Calcul de la distance…"
- Alerte réseau : "Connexion faible : distance estimée et majorée. Rapprochez-vous d'un meilleur réseau pour un tarif exact et le suivi GPS de votre course."
- Bloc programmée : "COURSE PROGRAMMÉE" ; date longue formatée ; `Départ à {hh}h{mm}` ; "Prix standard" ; `Majoration programmée (+{pct}%)` (+ " + heure de pointe (+10%)" si applicable)
- Détail prix : "Frais de prise en charge" ; `Distance ({km} km {~} × {tarifKm} XAF/km)` ; `Supplément poids ({poids} kg)` ; `Supplément volume ({volume} m³)` ; "Total à payer" ; " Paiement en espèces à la livraison" / " Paiement Mobile Money au transporteur"
- "COMMENT PAYEREZ-VOUS LE TRANSPORTEUR ? *" ; méthodes "Mobile Money" / "Espèces" ; avertissement "Vous réglez directement en espèces au transporteur à la livraison." / "Vous réglez par Mobile Money directement au transporteur à la livraison."
- Erreur catch : "Impossible de créer la course. Réessayez."

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.blanc`, `colors.charbon`, `colors.brume`, `colors.nere`, `colors.bambou`, `colors.laterite`, `colors.lateriteSoft`, `colors.cendre`, `colors.manioc`, `colors.nereSoft`. Alpha : `colors.foret + '40'` (bordure bloc programmée), `colors.laterite + '55'` (bordure alerte réseau). Aucun hex littéral, pas de `LinearGradient`. `SkeletonLigne` anime l'opacité d'un fond `colors.brume` (shimmer chargement du prix).

**Icônes** : Ionicons + MaterialCommunityIcons. `arrow-back`, icône véhicule dynamique (`motorbike`/`car`/`truck-delivery`/`truck`), `cloud-offline-outline`, `calendar`, `warning-outline`, `phone-portrait-outline`/`cash-outline`, `information-circle-outline`, `checkmark-circle`.

**Images / visuels** : `CarteLeaflet` miniature non-interactive (hauteur 180) — points départ/arrivée + polyline. Aucune image locale.

**Composants Atelier CAARCO utilisés** : Bandeau (erreur).

**Structure / layout** : Header (retour + titre). ScrollView : Bandeau erreur, carte miniature, bloc "Trajet", bloc "Véhicule" (icône + distance en cours), bloc alerte réseau conditionnel, bloc "Course programmée" conditionnel, bloc "Prix" (squelette / erreur / détail), bloc "Mode de paiement" (2 boutons + note). Pied fixe : "Modifier" (outline) et "Confirmer" (plein, spinner + libellés dynamiques).

---

## 9. AttenteScreen.js
`App/src/screens/client/AttenteScreen.js`

**Rôle / accès** : Client connecté, course venant d'être créée.
**Objectif de l'écran** : Écran d'attente pendant la recherche automatique d'un transporteur (radar animé), gestion du timeout de 3 minutes, et possibilité d'annuler la demande.

**Textes affichés à l'écran** :
- Header : "Recherche de transporteurs" ; badge course `#{6 derniers caractères en majuscules}`
- "Diffusion en cours…" / "Sélection automatique en cours…"
- "Les transporteurs proches reçoivent votre demande" / "Nous choisissons le transporteur le plus proche pour vous"
- `{n} transporteur{s} disponible{s} — sélection automatique…`
- `Recherche depuis {temps} · encore {temps}` / "Envoi de la demande en cours…"
- Timeout : "Aucun transporteur disponible" ; "Aucun transporteur n'a répondu après 3 minutes. Réessayez dans quelques instants ou à une autre heure." ; "← Retour à l'accueil"
- Carte candidat (`CarteCandidature`, définie mais **non rendue**, `renderItem={null}`) : nom, note, `{note} · {n} course{s}`, prix, type véhicule, immatriculation, "Voir le profil"
- "Annuler la demande"
- Erreur : "Impossible d'annuler. Réessayez."
- Format temps : `{s}s` ou `{min}min {s}s`

**Couleurs** : `colors.foret30` (anneaux radar), `colors.blanc`, `colors.brume`, `colors.foret`, `colors.bambou`, `colors.bambouSoft`, `colors.nere`, `colors.laterite`, `colors.lateriteSoft`, `colors.charbon`, `colors.cendre`, `colors.manioc`, `colors.foret70`. Aucun hex en dur, pas de `LinearGradient`.

**Icônes** : Ionicons. `cube-outline` (centre radar), `star`/`star-half`/`star-outline`, `chevron-forward`, `chatbubbles-outline`, `time-outline`, `close-circle-outline`. `ICONES_VEHICULE` (non affichées) : `bicycle-outline`, `car-outline`, `car-sport-outline`, `bus-outline`. Emojis : 🏍️ 🚗 🚐 (véhicules en orbite autour du radar).

**Images / visuels** : Aucune image ni carte — animation graphique pure (anneaux + véhicules orbitaux). Pas de `CarteLeaflet`.

**Composants Atelier CAARCO utilisés** : Mereau, Plaquette, Bandeau, BadgeVerifie (dans `CarteCandidature`, non affiché actuellement).

**Structure / layout** : Header (titre, bouton chat conditionnel, badge n° course). Bandeau erreur. `FlatList` avec `renderItem={null}` — tout le visible vient du `ListHeaderComponent` : radar animé, textes d'état, résumé trajet, bloc "sélection en cours" si candidats > 0, timer/spinner sinon, bloc timeout après 3 min. Bouton fixe "Annuler la demande".

---

## 10. CourseAccepteeScreen.js
`App/src/screens/client/CourseAccepteeScreen.js`

**Rôle / accès** : Client connecté, une fois qu'un transporteur a accepté la course.
**Objectif de l'écran** : Confirmer qu'un transporteur a été trouvé, présenter ses informations, proposer des actions rapides (appeler, chat, suivre, annuler) avant de rejoindre le suivi en direct.

**Textes affichés à l'écran** :
- Bannière succès : "Transporteur trouvé !" ; `${nom} est en route vers vous` / "Le transporteur est en route vers vous"
- Fiche transporteur : note, type véhicule, `{n} course{s}` (si > 0), téléphone, prix
- "QUE SOUHAITEZ-VOUS FAIRE ?"
- Actions : "Appeler le transporteur" / "Appel téléphonique direct" ; "Chat in-app" / "Envoyer des messages ou des photos" ; "Suivre en direct" / "Carte + progression en temps réel" ; "Annuler la course" / "Des frais peuvent s'appliquer" (danger)
- "Suivre la livraison en direct" (CTA principal)
- Modal annulation : "Annuler la course" ; "Le transporteur a accepté votre course et est peut-être déjà en route.\n\nÊtes-vous sûr de vouloir annuler ?" ; "Non, continuer" / "Oui, annuler"
- Alert erreur : "Erreur" / "Impossible d'annuler. Réessayez."

**Couleurs** : `colors.bambou`, `colors.bambouSoft`, `colors.foret`, `colors.foret10`, `colors.laterite`, `colors.lateriteSoft`, `colors.nere`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`. Hex en dur : `'#b2d8b2'` (bordure bannière succès et cercle icône, vert clair hors palette). Pas de `LinearGradient`.

**Icônes** : Ionicons. `checkmark-circle`, `star`, `call-outline`, `call`, `chatbubble-outline`, `navigate`, `close-circle-outline`, `chevron-forward`.

**Images / visuels** : Mereau (avatar transporteur, "lg"), BadgeVerifie. Aucune carte, aucune image locale.

**Composants Atelier CAARCO utilisés** : Mereau, Alcove (modal confirmation d'annulation), BadgeVerifie.

**Structure / layout** : Bannière succès en haut. ScrollView : carte transporteur (avatar, nom, badge, note, véhicule, nb courses, téléphone, prix), carte résumé trajet, carte "Actions" (4 lignes : Appeler / Chat / Suivre / Annuler), CTA "Suivre la livraison en direct". Modal `Alcove` de confirmation d'annulation.

---

## 11. SuiviScreen.js
`App/src/screens/client/SuiviScreen.js`

**Rôle / accès** : Client connecté, course en phase "acceptée" (collecte) ou "en_cours" (livraison).
**Objectif de l'écran** : Suivi GPS en temps réel de la position du transporteur sur carte, affichage de l'ETA/distance, du code OTP de livraison, et gestion des cas de no-show ou d'annulation par le transporteur.

**Textes affichés à l'écran** :
- Titre : "Colis en route" (livraison) / "Votre chauffeur arrive" (collecte)
- Sous-titre livraison : `Livraison dans {etaMin} min · {distanceKm} km` / "En cours de livraison…" ; collecte : `Votre chauffeur arrive dans {etaMin} min.` / `Votre chauffeur est à {distanceKm} km` / "Localisation en cours…"
- Badge : "EN ROUTE · LIVRAISON" / "EN ROUTE · COLLECTE"
- Fiche chauffeur : nom, véhicule formaté + immatriculation optionnelle, fallback "Véhicule" ; note
- OTP : "Votre code de livraison" ; code affiché ; "Donnez-le au\ntransporteur"
- "Contacter" ; "Annuler le trajet"
- Modal no-show : "Transporteur introuvable" ; "Votre transporteur ne s'est pas présenté à l'heure prévue.\nQue souhaitez-vous faire ?" ; "Annuler et être remboursé" / "Patienter encore"
- Modal annulation TR : "Transporteur indisponible" ; "Votre transporteur a annulé cette course.\nQue souhaitez-vous faire ?" ; "Relancer la même course" / "Modifier la course" / "Annuler la course"
- Erreurs : "Impossible d'annuler pour le moment. Réessayez." ; "Impossible d'annuler. Réessayez." ; "Impossible de relancer la course. Réessayez."

**Couleurs** : `colors.bambou`, `colors.bambouSoft`, `colors.nere`, `colors.nereSoft`, `colors.foret`, `colors.laterite`, `colors.lateriteSoft`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`. Code en dur : `rgba(15, 20, 17, 0.72)` (fond des modals no-show/annulation). Pas de `LinearGradient`.

**Icônes** : Ionicons. `star`, `keypad-outline` (bandeau OTP), `call-outline`, `locate` (FAB), `time-outline`, `close-circle-outline`, `refresh-outline`, `hourglass-outline`, `create-outline`. Emojis (`EMOJI_VEHICULE`) 🏍 🚗 🚐 🚛 🛺 (marqueur transporteur sur la carte).

**Images / visuels** : `CarteLeaflet` plein écran (marqueurs départ/arrivée/transporteur + polyline), avatar Mereau (chauffeur).

**Composants Atelier CAARCO utilisés** : Mereau, Bandeau.

**Structure / layout** : En-tête (progression d'étapes, badge statut, titre, sous-titre, mini-carte chauffeur). Zone carte flex avec FAB recentrage. Pied de page : bandeau OTP conditionnel (phase livraison), boutons "Contacter"/"Annuler le trajet". Deux Modals plein écran non-dismissables : no-show et annulation TR. Navigation auto vers "Merci" quand statut → "terminee".

---

## 12. PaiementScreen.js
`App/src/screens/client/PaiementScreen.js`

**Rôle / accès** : Client connecté, après une course terminée ou en cours de suivi.
**Objectif de l'écran** : Régler le transporteur. Le code contient un commentaire explicite indiquant que "especes" et "wallet" sont **désactivés temporairement pour la V1 Play Store** (Google exige une déclaration "fonctionnalités financières"), la liste `METHODES` affichée ne propose donc que Orange Money et MTN Mobile Money, bien que la logique wallet/espèces reste présente dans le code.

**Textes affichés à l'écran** :
- Méthodes visibles : "Orange Money", "MTN Mobile Money"
- Header : "Paiement" ; bannière post-livraison "Livraison confirmée ! Réglez votre transporteur pour continuer." ; sinon "Course terminée avec succès ✓"
- Bannière reprise : "Vous avez un paiement Mobile Money en cours pour cette course." ; "Reprendre"
- Carte montant : "Montant à régler" ; valeur ; "XAF" ; `À {nom}`
- "Mode de paiement" (titre section)
- Wallet : "Vérification du solde…" ; `Solde disponible : {montant} XAF` ; "Solde insuffisant" ; `Solde : {solde} XAF · Il manque {manquant} XAF` ; "Recharger le portefeuille" ; "Le paiement sera débité immédiatement de votre portefeuille."
- Espèces : "Vous payez directement en espèces au transporteur à la livraison. La commission CAARCO (20%) sera prélevée automatiquement sur le wallet du transporteur."
- Numéro : `Numéro {label}` ; préfixe "+237" ; placeholder "6XXXXXXXX"/"67XXXXXXX" ; "Un SMS de confirmation sera envoyé à ce numéro"
- Bouton payer : "Traitement en cours…" / "Confirmer, payer en espèces" / `Payer {montant} XAF`
- "🔒 Paiement sécurisé · Notchpay"
- Erreurs : "Numéro Mobile Money invalide. Vérifiez et réessayez." ; "Portefeuille non chargé. Réessayez." ; "Solde insuffisant. Rechargez votre portefeuille." ; "Erreur lors de l'enregistrement du mode de paiement." ; "Impossible d'initier le paiement" ; "Paiement annulé ou échoué. Réessayez ou choisissez une autre méthode." ; "Paiement refusé par l'opérateur Mobile Money. Réessayez." ; "Confirmation en attente. Vérifiez votre messagerie Mobile Money puis revenez sur cette page." ; "Erreur réseau lors de la vérification. Réessayez dans quelques instants." ; "Paiement échoué. Réessayez."
- Écran attente TR (espèces) : "En attente du transporteur" ; "Votre choix de paiement en espèces\na été transmis à {nom}." ; "Le transporteur confirme avoir reçu le paiement.\nVous serez redirigé automatiquement." ; "Montant à remettre en espèces" ; "Changer de méthode"
- WebView : "Paiement · Notchpay"

**Couleurs** : `colors.foret`, `colors.bambouSoft`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.nere`, `colors.nereSoft`, `colors.bambou`, `colors.laterite`, `colors.lateriteSoft`, `colors.foret10`, `colors.foret30`. Hex en dur : Orange Money `'#FF6600'`/`'#FFF3EB'`, MTN Mobile Money `'#FFCC00'`/`'#FFFBE6'`. Pas de `LinearGradient`.

**Icônes** : Ionicons. `phone-portrait-outline`, `cash-outline`, `checkmark-circle`, `time-outline`, `person-circle-outline`, `wallet-outline`, `warning-outline`, `add-circle-outline`, `checkmark-circle-outline`, `close`.

**Images / visuels** : `WebView` plein écran pour le checkout Notchpay. Aucune carte, aucun avatar/photo.

**Composants Atelier CAARCO utilisés** : Bandeau.

**Structure / layout** : Deux états. (1) Formulaire : header, bannières conditionnelles, carte montant (fond vert), liste de méthodes (radio), bloc wallet ou info espèces, champ numéro, pied fixe "Payer" + note sécurité. (2) État plein écran "attente confirmation TR" remplaçant tout le contenu si paiement espèces. Modal glissant plein écran avec `WebView` Notchpay pour Mobile Money.

---

## 13. PayerTransporteurScreen.js
`App/src/screens/client/PayerTransporteurScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Transférer de l'argent depuis le wallet du client vers un transporteur (via scan QR, saisie manuelle d'ID, ou historique récent), puis saisir et confirmer un montant.

**Textes affichés à l'écran** :
- Modes : "Scanner", "Saisie", "Récents"
- Header : "Payer un transporteur"
- Solde : `Solde disponible : {solde} XAF`
- "Scanner le QR du transporteur" ; "Le transporteur affiche son QR dans l'onglet \"Encaissement\""
- "IDENTIFIANT DU TRANSPORTEUR" ; placeholder "Collez ou saisissez l'ID…"
- Erreur recherche : "Transporteur introuvable pour cet identifiant."
- Récents vide : "Aucun transporteur récent"
- "MONTANT À PAYER" ; placeholder "0" ; `Solde insuffisant, manque {x} XAF` / `Solde après : {x} XAF`
- Bouton : `Payer {montant} XAF`
- Alertes : "Module absent" / "Installez expo-camera :\nnpx expo install expo-camera" ; "Permission refusée" / "Autorisez la caméra dans les réglages." ; "QR invalide" / "Ce transporteur est introuvable." ; "QR non reconnu" / "Scannez un QR CAARCO valide." ; "Montant invalide" / "Le minimum est de 100 XAF." ; "Solde insuffisant" / `Votre solde est de {solde} XAF.` ; "Paiement échoué" / message ou "Réessayez."
- Succès : "Paiement effectué" ; montant ; `versés à {nom}` ; "Fermer"

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.bambou`, `colors.bambouSoft`, `colors.nere`. Aucun hex littéral, pas de `LinearGradient`.

**Icônes** : Ionicons. `qr-code-outline`/`keypad-outline`/`time-outline` (onglets), `arrow-back`, `wallet-outline`, `close`, `qr-code`, `search`, `chevron-forward`, `send`, `checkmark-circle`.

**Images / visuels** : `CameraView` (expo-camera, chargement dynamique) pour scan QR. Mereau (avatar destinataire/récents).

**Composants Atelier CAARCO utilisés** : Mereau. `Plaquette` importé mais non utilisé (carte custom `CarteTransporteur`).

**Structure / layout** : Header + barre de solde. Sans destinataire : onglets Scanner/Saisie/Récents. Avec destinataire : carte résumé + champ montant + info solde + bouton "Payer". Écran de succès plein écran après paiement.

---

## 14. RechargeRapideScreen.js
`App/src/screens/client/RechargeRapideScreen.js`

**Rôle / accès** : Client connecté, généralement atteint depuis PaiementScreen ou WalletScreen quand le solde wallet est insuffisant.
**Objectif de l'écran** : Recharger rapidement le portefeuille wallet via Mobile Money (Orange/MTN), montant suggéré ou personnalisé, paiement via WebView Notchpay.

**Textes affichés à l'écran** :
- Header : "Recharger le portefeuille"
- Alerte : "Solde insuffisant" ; `Il vous manque {montant} XAF pour payer cette course.`
- Résumé : "Solde actuel" ; "Montant de la course" ; "Minimum à recharger"
- "Choisissez un montant" ; badge "Recommandé" ; "Saisir un autre montant" ; `Minimum : {montant} XAF` ; placeholder `Ex. {montant}`
- "Via Mobile Money" ; méthodes "Orange Money", "MTN MoMo"
- Bouton : `Recharger {montant} XAF` / "Choisir un montant"
- "🔒 Paiement sécurisé · Notchpay"
- WebView : "Recharge Mobile Money" ; bouton "J'ai confirmé ✓"
- Erreurs : "Saisissez un montant valide (minimum 500 XAF)." ; `Minimum requis : {montant} XAF pour couvrir cette course.` ; "Impossible d'initier la recharge." ; "Paiement annulé ou échoué. Réessayez."

**Couleurs** : `colors.foret`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.nere`, `colors.laterite`, `colors.lateriteSoft`, `colors.bambou`, `colors.foret90`. Hex en dur : Orange Money `'#FF6600'`/`'#FFF3EB'`, MTN MoMo `'#FFCC00'`/`'#FFFBE6'`. Pas de `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `warning`, `close-circle`, `create-outline`, `phone-portrait-outline`, `wallet-outline`, `close`.

**Images / visuels** : `WebView` plein écran pour le checkout Notchpay. Aucune carte, aucune image.

**Composants Atelier CAARCO utilisés** : Bandeau.

**Structure / layout** : Header + ScrollView : carte alerte solde insuffisant (conditionnelle), carte résumé solde, section "Choisissez un montant" (grille 2×2 + bascule montant personnalisé), section méthode Mobile Money. Pied fixe : bouton recharger + note sécurité. Modal glissant plein écran `WebView` Notchpay avec bouton manuel "J'ai confirmé ✓".

---

## 15. NotationScreen.js
`App/src/screens/client/NotationScreen.js`

**Rôle / accès** : Client connecté, après livraison.
**Objectif de l'écran** : Noter le transporteur (note globale + 4 critères détaillés) et laisser un commentaire facultatif.

**Textes affichés à l'écran** :
- Critères : "Ponctualité", "Soin du colis", "Communication", "Propreté véhicule"
- Header : "Notez votre expérience" ; "Votre avis aide la communauté CAARCO"
- Label de note dynamique : "Excellent !" (5) / "Très bien" (4) / "Correct" (3) / "Décevant" (2) / "Mauvais" (1)
- "Commentaire (optionnel)" ; placeholder "Décrivez votre expérience…" ; compteur `{n}/500`
- "Envoyer mon avis" ; "Passer"
- Erreur : "Impossible d'envoyer l'avis. Réessayez."

**Couleurs** : `colors.nere` (étoiles pleines), `colors.brume` (étoiles vides), `colors.foret`, `colors.foret10`, `colors.blanc`, `colors.charbon`, `colors.cendre`. Aucun hex, pas de `LinearGradient`.

**Icônes** : Ionicons. `star`/`star-outline`, `time-outline` (Ponctualité), `cube-outline` (Soin du colis), `chatbubble-outline` (Communication), `sparkles-outline` (Propreté véhicule), `checkmark-circle-outline`.

**Images / visuels** : Mereau (avatar transporteur, "lg"), BadgeVerifie.

**Composants Atelier CAARCO utilisés** : Mereau, BadgeVerifie, Bandeau.

**Structure / layout** : Header, carte transporteur (avatar, nom+badge, sélecteur 5 étoiles + label dynamique), carte des 4 critères (icône+label+mini-étoiles), champ commentaire avec compteur. Pied fixe : "Envoyer mon avis" + lien "Passer".

---

## 16. HistoriqueScreen.js
`App/src/screens/client/HistoriqueScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Afficher l'historique des courses ("Mes courses"), séparé en onglets "À venir" (programmées) / "Passées", avec pagination et mise à jour en temps réel (Realtime).

**Textes affichés à l'écran** :
- Tutoriel : "Vos livraisons passées" / "Retrouvez ici toutes vos courses avec statuts, distances et montants. Appuyez sur une course pour voir les détails."
- Header : "Mes courses"
- Onglets : "À venir" (badge compteur), "Passées"
- Flash bannière : "Course programmée confirmée !" + date formatée
- Badge type : "Planifiée" / "Immédiate"
- Heures ligne : `Prévu {heure}`, `Commandé {heure}`, `Départ {heure}`, `Livré {heure}`
- Véhicules : "Moto", "Voiture", "Camionnette", "Tricycle", "Tricycle / Van", "Camion"
- Paiement : "Mobile Money" (online), "Wallet", "Espèces"
- `{distance} km · {vehicule}` ; `{prix} XAF`
- États vides : "Aucune course planifiée" / "Aucune course pour l'instant" ; "Vos courses programmées apparaîtront ici" / "Vos livraisons apparaîtront ici"
- " Fin de l'historique "
- Alert acceptation : "Course acceptée !" ; `${nomTransp} a accepté votre course. Vous pouvez maintenant le contacter.` ; "Plus tard" / "Voir le détail"

**Couleurs** : `colors.nere`, `colors.bambou`, `colors.foret`, `colors.foret10`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`. Aucun hex en dur, pas de `LinearGradient`. (Statuts colorés délégués au composant `Cachet`.)

**Icônes** : Ionicons. `calendar-outline`/`flash-outline` (badge Planifiée/Immédiate), `time-outline`, `create-outline`, `play-outline`, `checkmark-outline`, `refresh-outline`, `cube-outline`/`calendar-outline` (états vides), `checkmark-circle`/`close` (bannière flash).

**Images / visuels** : Aucune (pas de carte, pas d'avatar/photo).

**Composants Atelier CAARCO utilisés** : Plaquette, Cachet, TutorielPopup.

**Structure / layout** : SafeAreaView ; bannière flash conditionnelle (auto-masquée après 6s) ; en-tête (titre + actualiser) ; onglets "À venir"/"Passées" avec badge compteur ; `FlatList` de cartes `ItemCourse` (badge type, Cachet statut, dates, trajet pointillé, distance/véhicule/paiement + prix, chevron), pull-to-refresh, pagination infinie (20/page) sur "Passées", pied "Fin de l'historique". TutorielPopup en overlay.

---

## 17. CourseDetailClientScreen.js
`App/src/screens/client/CourseDetailClientScreen.js`

**Rôle / accès** : Client connecté, accédé depuis HistoriqueScreen.
**Objectif de l'écran** : Détail complet d'une course spécifique (trajet, prix, transporteur, statut) et actions contextuelles (annuler, relancer, signaler un litige, reprendre la recherche).

**Textes affichés à l'écran** :
- Header : "Détail de la course"
- Trajet : "DÉPART", "ARRIVÉE" ; meta `{distance} km`, type véhicule
- Bloc programmée : "Course planifiée" ; date/heure formatée ; "✓ Transporteur assigné" / "En attente d'un transporteur"
- Bloc transporteur : "TRANSPORTEUR" ; actions "Appeler", "Chat", "Suivre" (si applicable)
- Bloc attente : `{n} transporteur{s} disponible{s}` / "En attente d'un transporteur…" ; bouton "Choisir un transporteur" / "Continuer la recherche"
- Boutons bas : "Annuler la course" ; "Relancer cette course" ; "Signaler un problème"
- Alert annulation : "Annuler la course ?" ; "Vous annulez une course avec un transporteur déjà assigné. L'annulation reste gratuite avant le départ." / "Cette course sera annulée définitivement." ; "Non, garder" / "Oui, annuler" ; erreur "Erreur" / "Impossible d'annuler. Réessayez."
- Modal litige : "Signaler un problème" ; "Décrivez le problème avec cette course. Un admin examinera votre signalement sous 24–48h." ; placeholder "Ex : Colis endommagé, manquant, mauvaise livraison…" ; "Annuler" / "Envoyer" ; succès "Litige signalé" / "Un admin va examiner votre litige sous 24–48h et vous recontactera." ; erreur "Erreur" / "Impossible de signaler le litige. Réessayez."

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.blanc`, `colors.charbon`, `colors.brume`, `colors.manioc`, `colors.nere`, `colors.bambou`, `colors.laterite`, `colors.lateriteSoft`, `colors.cendre`, `colors.nereSoft`. Aucun hex en dur, pas de `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `star`/`star-half`/`star-outline`, `navigate-outline`, `car-outline`, `calendar`, `call`, `chatbubble-outline`, `navigate`, `play-circle-outline`, `close-circle-outline`, `refresh-circle-outline`, `alert-circle-outline`.

**Images / visuels** : Mereau (avatar transporteur), BadgeVerifie. Aucune carte, aucune image.

**Composants Atelier CAARCO utilisés** : Mereau, Plaquette, Cachet, BadgeVerifie.

**Structure / layout** : Header + ScrollView de cartes `Plaquette` : (1) statut + date + prix + trajet en pointillés ; (2) bloc "course planifiée" conditionnel ; (3) bloc transporteur (avatar/nom/note/téléphone + 3 actions) OU bloc "attente" (spinner + reprendre). Boutons de pied conditionnels selon le statut. Modal glissant pour le formulaire de litige.

---

## 18. MessagesScreen.js
`App/src/screens/client/MessagesScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Centraliser les conversations liées aux courses (chat client↔transporteur) et les messages système (partages de position), avec archivage/suppression/partage en sélection multiple.

**Textes affichés à l'écran** :
- Onglets : "Conversations", "Système"
- Header : "Messages" ; mode sélection `{n} sélectionné(s)` ; bouton "Tout"
- Fallback conversation : "Transporteur en attente"
- Fallback message système : "Notification système" ; contenu "Position partagée par le transporteur" / "Message automatique"
- États vides : "Aucune conversation archivée" / "Aucune conversation" + "Vos échanges avec les transporteurs\napparaîtront ici" ; "Aucun message système" + "Les positions partagées par les\ntransporteurs apparaîtront ici"
- Menu contextuel : "Sélectionner", "Archiver"/"Désarchiver", "Partager", "Supprimer la conversation"
- Alertes : `Supprimer {n} conversation(s) ?` / "Les messages seront définitivement supprimés." ; erreur "Erreur"/"Impossible de supprimer."
- Message de partage : `${nom}, ${depart} → ${arrivee}` avec titre "Conversations CAARCO" / "Conversation CAARCO"
- Barre d'actions multi-sélection : "Archiver", "Partager", "Supprimer"

**Couleurs** : `colors.bambou`, `colors.bambouSoft`, `colors.foret`, `colors.laterite`, `colors.cendre`, `colors.blanc`, `colors.brume`, `colors.manioc`, `colors.charbon`. Hex en dur : `'#edf4ef'` (fond ligne sélectionnée). Pas de `LinearGradient`.

**Icônes** : Ionicons. `checkmark-circle-outline`/`navigate-outline`/`flag-outline`/`close-circle-outline` (statut course), `chatbubbles-outline`, `radio-outline`, `person-outline`, `chevron-forward`, `location-outline`/`information-circle-outline`, `close`, `archive-outline`/`arrow-up-circle-outline`, `share-outline`, `trash-outline`.

**Images / visuels** : Mereau (avatar par conversation), BadgeVerifie. Aucune carte, aucune image locale.

**Composants Atelier CAARCO utilisés** : Mereau, BadgeVerifie. `MenuContextuel` hors liste Atelier nommée.

**Structure / layout** : SafeAreaView ; en-tête (titre ou compteur sélection + "Tout") ; onglets segmentés Conversations/Système avec badges non-lus ; `FlatList` d'`ItemConversation` ou `ItemSysteme` ; barre d'actions multi-sélection en bas ; `MenuContextuel` en bottom-sheet.

---

## 19. WalletScreen.js
`App/src/screens/client/WalletScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Afficher le solde du portefeuille (wallet), l'historique des transactions, permettre une recharge Mobile Money (Notchpay) et un paiement par scan de QR code.

**Textes affichés à l'écran** :
- Header : "Portefeuille"
- Bannière interrompue : `Recharge de {montant} XAF interrompue` ; "Reprenez ou annulez ce paiement" ; "Reprendre"
- Carte solde : "SOLDE DISPONIBLE" ; montant ; "XAF" ; "Prêt à payer" / "Rechargez pour payer"
- Actions : "Recharger", "Scanner QR"
- "HISTORIQUE"
- Types de transaction : "Recharge", "Paiement course", "Remboursement", "Gain transporteur"
- Statuts : "En attente", "Validée", "Échouée", "Annulée"
- Vide : "Aucune transaction" ; "Rechargez votre portefeuille\npour commencer"
- Modal recharge — succès : `+{montant} XAF` ; "Crédité sur votre portefeuille" ; "Fermer" ; sinon : "Recharger le portefeuille" ; "MÉTHODE" ; "Orange Money"/"MTN MoMo"/"Carte" ; "MONTANT" ; placeholder "5 000" ; "Minimum : 500 XAF" ; "Recharger" / "Validation en cours…"
- Modal scanner : "Pointez vers le QR code de paiement CAARCO" ; résultat : montant, `Réf. {ref}`, `Solde après paiement : {solde} XAF` ; "Confirmer le paiement" / "Scanner à nouveau"
- WebView : "Recharge Mobile Money"
- Alertes : "Module caméra absent" ; "Permission refusée" ; "QR invalide" / "Ce QR n'est pas un code CAARCO." ; "Solde insuffisant" / `Votre solde ({solde} XAF) est insuffisant.` ; "Paiement effectué" / `{montant} XAF débités.` ; "Montant invalide" / "Le minimum est de 500 XAF." ; "Recharge annulée" ; "Recharge en cours" / "Paiement reçu. Votre solde sera mis à jour dans quelques instants."

**Couleurs** : `colors.foret`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.nere`, `colors.bambou`, `colors.laterite`, `colors.bambouSoft`, `colors.nuit` (fond scanner), `colors.foret10`. Hex en dur : Orange Money `'#FF6600'`/`'#FFF3EB'`, MTN MoMo `'#FFCC00'`/`'#FFFBE6'` ; cercles décoratifs translucides `rgba(255,255,255,0.05)`/`rgba(255,255,255,0.04)` sur la carte solde (fond forêt). Pas de `LinearGradient`.

**Icônes** : Ionicons. `time-outline`, `arrow-down-circle-outline` (recharge/gain), `arrow-up-circle-outline` (paiement), `return-down-back-outline` (remboursement), `add-circle-outline`, `qr-code-outline`, `receipt-outline` (vide), `qr-code` (résultat scan), `close`.

**Images / visuels** : `CameraView` dans un Modal plein écran (scan QR) ; `WebView` dans un Modal plein écran (checkout Notchpay). Aucune carte, aucun avatar.

**Composants Atelier CAARCO utilisés** : Aucun composant nommé de la liste Atelier (styles custom + sous-composant `ItemTransaction`).

**Structure / layout** : SafeAreaView ; header "Portefeuille" ; `FlatList` des transactions avec `ListHeaderComponent` (bannière recharge interrompue conditionnelle, grande carte solde avec cercles décoratifs, boutons Recharger/Scanner QR, label "HISTORIQUE") ; ligne de transaction (icône par type, libellé, statut+date, montant signé) ; état vide. Modal bottom-sheet pour la recharge. Modal plein écran pour le scanner QR. Modal plein écran glissant pour le `WebView` Notchpay.

---

## 20. PointsScreen.js
`App/src/screens/client/PointsScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Afficher le solde de points fidélité, la progression vers les paliers, les jalons/surprises à débloquer, le catalogue d'échange de points contre récompenses et l'historique des transactions de points.

**Textes affichés à l'écran** :
- Header : "Mes Points" ; bouton "Parrainer"
- Carte solde : "MES POINTS" ; solde ; "pts" ; nom du palier
- Barre de palier : `{n} pts pour atteindre {nom du palier suivant}`
- Commissions parrainage : "Commissions parrainage" ; `{n} transporteur{s} recruté{s}` ; `+{montant} XAF`
- "Streak de la semaine" ; message : "🎉 Streak atteint ! +100 XAF crédités" / `{n} course{s} de plus ce semaine → +100 XAF`
- "Mes surprises" ; `🎯 Encore {n} course{s} pour débloquer votre prochaine surprise (jalon {next})` ; `Jalon {n} courses` ; "Appuyez pour révéler votre surprise !" ; "Révéler" ; "Effectuez vos 10 premières courses pour débloquer votre 1ère surprise."
- Alert révélation : "🎁 Surprise révélée !" ; message = `labelRecompense(...)` ; "Super !" ; erreur "Impossible de révéler la surprise. Réessayez."
- "Catalogue récompenses" ; carte item : titre + `{points} pts`
- Alert échange : "Confirmer l'échange" ; `Échanger {points} points contre "{titre}" ?` ; "Annuler"/"Confirmer" ; erreur fallback "Échange impossible"
- "Historique" ; motifs : "Course effectuée", "Parrainage", "Échange récompense" ; montant `±{n} pts`
- "Erreur de chargement"

**Couleurs** : `colors.nere`, `colors.bambou`, `colors.brume`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.foret`, `colors.foret10`, `colors.nereSoft`. Codes en dur (rgba sur fond forêt) : `rgba(255,255,255,0.06)`/`0.04` (cercles décoratifs), `rgba(255,255,255,0.15)`/`0.2`/`0.3`/`0.6`/`0.55` (pastilles/barre de progression des paliers). Pas de `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `gift-outline`, `medal`/`medal-outline`, `checkmark-circle`/`ellipse-outline`, `star`, `add-circle-outline`/`remove-circle-outline`. Emojis : 🎉 (streak), 🎯 (prochain jalon), 🎁 (jalon + alerte).

**Images / visuels** : Aucune (pas de carte, pas de photo).

**Composants Atelier CAARCO utilisés** : Bandeau.

**Structure / layout** : Header (retour, titre, pill "Parrainer") ; spinner ou ScrollView : carte solde verte (cercles décoratifs, badge palier, `BarrePalier`), carte commissions parrainage conditionnelle, carte "Streak de la semaine" (3 cases + message), section "Mes surprises" conditionnelle, grille 2 colonnes "Catalogue récompenses", liste "Historique" conditionnelle.

---

## 21. ParrainageScreen.js
`App/src/screens/client/ParrainageScreen.js`

**Rôle / accès** : Client connecté.
**Objectif de l'écran** : Partager son code de parrainage, suivre ses filleuls et gains associés, et saisir le code d'un parrain si le client n'en a pas encore.

**Textes affichés à l'écran** :
- Header : "Parrainage" ; pill "20 pts / filleul inscrit"
- Carte code : "Votre code" ; valeur du code ; "Partagez votre code unique et gagnez 20 points pour chaque ami inscrit, plus 50 % de leurs points de course."
- Boutons : "Partager sur WhatsApp" ; "Copié !" / "Copier" ; "Autres options"
- Message WhatsApp : `Rejoins CAARCO, l'app de transport colis au Cameroun ! 🚚\nUtilise mon code de parrainage *{code}* lors de ton inscription et on gagne tous les deux des points.\n\nTélécharge l'appli ici : https://caarco.app`
- Carte "Gains wallet" : "Gains wallet" ; "Commissions reçues sur les courses de vos filleuls" ; `{montant} FCFA` + "total perçu" ; par filleul `{nom_anonymise}` + `{gains} FCFA` ; vide "Vos gains apparaîtront ici dès qu'un filleul aura terminé une course."
- "Vous avez un code parrain ?" (si pas de parrain) ; placeholder "Ex: ABC123" ; "Appliquer" ; succès "Code appliqué ! Votre parrain a été crédité." ; erreur fallback "Code invalide ou déjà utilisé."
- "Mes filleuls" + compteur ; statut "Actif" (≥5 courses) ou `{n}/5 courses` ; vide "Aucun filleul pour l'instant" + "Partagez votre code pour commencer" ; `Inscrit le {date}`
- "Comment ça marche" : "1" "Partagez votre code unique à vos proches" ; "2" "Ils s'inscrivent avec votre code CAARCO" ; "3" "Vous gagnez 20 pts + 50 % de leurs points de course + une commission FCFA sur chaque livraison terminée"

**Couleurs** : `colors.foret`, `colors.bambouSoft`, `colors.nere`, `colors.nereSoft`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.foret10`, `colors.foret30`. Hex en dur : `'#e8d0a0'` (bordures pills nère), `'#25D366'` (bouton WhatsApp). `colors.nere + '40'` (bordure carte gains). Pas de `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `star`, `gift`, `logo-whatsapp`, `checkmark-outline`/`copy-outline`, `share-social-outline`, `wallet-outline`, `people-outline`. Emoji : 🚚 (message WhatsApp).

**Images / visuels** : Mereau (avatar par filleul, "sm"). Aucune carte, aucune autre image.

**Composants Atelier CAARCO utilisés** : Mereau, Bandeau.

**Structure / layout** : Header (retour, titre, pill points). ScrollView : hero "carte code" verte, carte "Gains wallet", section saisie code parrain conditionnelle, section "Mes filleuls" (liste ou état vide), carte "Comment ça marche" (3 étapes).

---

## 22. ProfilTransporteurScreen.js
`App/src/screens/client/ProfilTransporteurScreen.js`

**Rôle / accès** : Client connecté, atteint depuis AttenteScreen ("Voir le profil" d'un candidat).
**Objectif de l'écran** : Afficher le profil complet d'un transporteur candidat à une course (note, véhicule, prix proposé, trajet) et permettre au client de le choisir explicitement.

**Textes affichés à l'écran** :
- Header : "Profil transporteur"
- Hero : nom ; `{note.toFixed(1)} sur 5` ; `{n} course{s} effectuée{s}`
- "VÉHICULE" ; nom du véhicule capitalisé ; immatriculation (si présente)
- "PRIX PROPOSÉ" ; `{prix} XAF` ; `{km} km · {vehicule}`
- "TRAJET" ; "DÉPART" / "ARRIVÉE" ; adresses
- Bouton : "Choisir ce transporteur"
- Erreur : "Impossible de sélectionner ce transporteur. Réessayez."

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.blanc`, `colors.charbon`, `colors.brume`, `colors.manioc`, `colors.nere`, `colors.cendre`. Aucun hex en dur, pas de `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `star`/`star-half`/`star-outline`, `bicycle-outline`/`car-outline`/`car-sport-outline`/`bus-outline`, `checkmark-circle`.

**Images / visuels** : Mereau (avatar, "xl"), BadgeVerifie. Aucune carte, aucune image locale.

**Composants Atelier CAARCO utilisés** : Mereau, BadgeVerifie, Plaquette, Bandeau.

**Structure / layout** : Header + ScrollView : Bandeau erreur ; bloc hero (grand avatar, nom+badge, étoiles, note, nb courses) ; carte `Plaquette` "VÉHICULE" ; carte `Plaquette` "PRIX PROPOSÉ" ; carte `Plaquette` "TRAJET". Pied fixe : bouton "Choisir ce transporteur" (spinner de chargement).

---

# TRANSPORTEUR (18 écrans)

## 23. TableauBordScreen.js
`App/src/screens/transporteur/TableauBordScreen.js`

**Rôle / accès** : Transporteur (TR) connecté.
**Objectif de l'écran** : Écran d'accueil principal du TR — carte plein écran avec sa position, toggle en ligne/hors ligne, réception en temps réel des courses disponibles (bottom sheet swipeable), gestion des courses planifiées et des blocages (impayé, limite KYC).

**Textes affichés à l'écran** :
- "Activez votre disponibilité" / "Basculez sur 'En ligne' pour apparaître sur la carte et commencer à recevoir des demandes de course." (tutoriel étape 1)
- "Courses disponibles" / "Les nouvelles demandes apparaissent ici en temps réel. Acceptez ou refusez rapidement pour rester prioritaire." (tutoriel étape 2)
- "Votre position est partagée" / "Quand vous êtes en ligne, votre position GPS est visible par les clients à proximité (rayon 15 km)." (tutoriel étape 3)
- "Client" (fallback nom client) ; "Profil" (voir profil client)
- "Tokens insuffisants — il manque {montant} TC pour postuler à cette course." ; "Acheter des Tokens"
- "Mobile Money" / "Espèces" (badge mode de paiement)
- "Vous avez atteint la limite de 2 courses/mois sans KYC vérifié." ; "Soumettre mon dossier KYC"
- "En attente du client" ; "Chat"
- "Approuvé pour {véhicule KYC} · Course {véhicule requis}" ; "Refuser" ; "Proposer mes services"
- "Solde insuffisant" ; "À percevoir du client · commission déduite de votre solde TC"
- "{distance} km" / "Livrer avant {heure}" ; "Collecte" / "Livraison"
- "Tokens insuffisants — manque {n} TC · Appuyer pour acheter" ; "Soumettre mon KYC pour continuer"
- "Proposition envoyée, en attente du client" ; "Non compatible" ; "Accepter" ; "Voir les détails complets"
- "Bonjour" / "Bonsoir" / "Bonne nuit" (salutation selon l'heure) ; "{Prénom}" ou "Transporteur" (fallback)
- "🥇 #{rang} ce mois" / "🥈 #{rang} ce mois" / "🥉 #{rang} ce mois" / "🏆 #{rang} ce mois"
- "Impayé CAARCO, {dette} XAF" ; "Vous ne recevez plus de courses tant que cette dette n'est pas réglée." ; "Régler" / "Acheter des Tokens"
- "Vous êtes hors ligne" ; "Activez le toggle en haut à droite pour recevoir des courses"
- "Course terminée — noter le client" ; "{prix} XAF · {prénom client}"
- "Prochaines courses · {n}" ; "{jour} {date} à {heure}h{minute}" ; "Course planifiée — démarrage imminent" ; "{prix} XAF · {heure}" ; "Démarrer"
- "Courses à venir disponibles · {n}" ; "{nom client} · {note} ★" ; "Réservation..." / "Réserver cette course"
- "{indexVisible+1} / {courses.length} courses"
- "Aucune course disponible" / "Vous êtes hors ligne" (état vide) ; "Les nouvelles demandes apparaîtront ici en temps réel" / "Passez en ligne pour recevoir des courses"
- Toasts : "Impossible de charger les courses", "Proposition envoyée — sélection automatique en cours.", "Tokens insuffisants pour cette course. Achetez des TC dans l'onglet Revenus.", "Cette course n'est plus disponible.", "Limite de 2 courses/mois atteinte. Soumettez votre dossier KYC.", "Course planifiée imminente — vous ne pouvez pas accepter de nouvelles courses pour l'instant.", "Connexion lente. Réessayez dans quelques secondes.", "Impossible d'envoyer la proposition. Réessayez.", "Course planifiée réservée ! Rendez-vous à l'heure prévue.", "Cette course vient d'être prise par un autre transporteur.", "Vous avez déjà une mission planifiée à ce créneau horaire.", "Vous avez une course imminente. Impossible de prendre une autre mission.", "Impossible de réserver cette course. Réessayez.", "Le client vous a choisi ! Rendez-vous au point de collecte.", "Réglez votre impayé pour recevoir des courses", "Dette réglée, vous pouvez à nouveau recevoir des courses", "Erreur de remboursement", "Erreur de connexion"
- Notifications locales : "🚛 Nouvelle course disponible !" / "{départ} → {arrivée}" ; "⏰ Course planifiée — démarrage dans 45 min" ; "✅ Course confirmée !" / "Le client vous a choisi. Rendez-vous au point de collecte."

**Couleurs** : `colors.foret`, `colors.foret70`, `colors.foret10`, `colors.foret30`, `colors.bambou`, `colors.bambouSoft`, `colors.nere`, `colors.nereSoft`, `colors.laterite`, `colors.lateriteSoft`, `colors.brume`, `colors.charbon`, `colors.cendre`, `colors.blanc`, `colors.manioc`, `colors.nuit` (fond racine). Hex en dur : `'rgba(251,249,243,0.96)'` (header flottant, bouton refuser, compteur), `'rgba(251,249,243,0.95)'` (chargement flottant), `'#ffd4c4'` (sous-titre bannière impayé), `'rgba(255,255,255,0.25)'` (bouton "Régler"), `'#e8d0a0'` (bordures bannière paiement/pré-active/limite KYC). Aucun `LinearGradient`.

**Icônes** : Ionicons. `star`/`star-half`/`star-outline`, `location`, `navigate`, `chevron-forward`, `ticket-outline`, `add-circle-outline`, `checkmark-circle`, `close`, `id-card-outline`, `lock-closed-outline`, `chatbubbles-outline`, `cash-outline`/`phone-portrait-outline`, `warning`, `toggle-outline`, `checkmark-circle-outline`, `calendar-outline`, `alarm-outline`, `albums-outline`, `navigate-circle-outline`, `lock-closed`, `checkmark`, `bicycle-outline`/`car-outline`/`car-sport-outline`/`bus-outline`. Emojis : 🚛 ⏰ ✅ (notifications), 🥇 🥈 🥉 🏆 (rang mensuel), 🏍 🚗 🚐 🛺 🚛 (marqueurs véhicule carte), 📦 🏠 (marqueurs pickup/dropoff).

**Images / visuels** : `CarteLeaflet` (carte OSM plein écran), `Mereau` (avatar TR et clients), `BadgeVerifie`. Aucun `require()` d'asset local.

**Composants Atelier CAARCO utilisés** : `CarteLeaflet`, `BoutonSignalementCarte`, `Mereau`, `Bascule` (toggle en ligne), `Bandeau`, `BadgeVerifie`, `Galet` (bouton "Démarrer"/"Réserver"), `TutorielPopup`.

**Structure / layout** : Carte plein écran en fond avec overlays flottants : bandeau toast, header (salutation, nom, badge, rang, puce véhicule, toggle, avatar), bannière impayé persistante, bannière hors-ligne, bannière paiement en attente, section courses programmées, bannière course pré-active verrouillée, section marketplace planning, indicateur de chargement. En bas : bottom sheet animé (`FlatList` horizontal paginé, une carte par course, swipe gauche/droite), compteur/dots, bouton "Refuser" flottant. États : hors ligne, en ligne sans course, en ligne avec courses, verrouillé sur course pré-active, bloqué impayé.

---

## 24. CourseScreen.js
`App/src/screens/transporteur/CourseScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Afficher le détail d'une course spécifique (client, trajet, prix, photos colis, commission TC) et permettre d'accepter/refuser ou de démarrer une course déjà planifiée.

**Textes affichés à l'écran** :
- "← Retour" ; "Détail de la course"
- "{nom client}" ou "Client" (fallback) ; "{téléphone}"
- "DÉPART" / "ARRIVÉE" ; "Distance" / "Véhicule" / "XAF"
- "Photos du colis · appuyer pour agrandir"
- "Mode de paiement client : " + "Mobile Money" ou "Espèces"
- "Tokens insuffisants — il manque " + "{montant} TC" + " pour postuler à cette course." ; "Acheter des Tokens"
- "Commission CAARCO : " + "{n} TC" + " déduites de votre solde à la livraison."
- "Refuser" ; "Accepter la course" ; "Voir l'itinéraire dans l'application"
- "Prévu le {jour} {date} à {heure}" ; "Démarrer la course"
- Messages de statut (Bandeau) : "Course acceptée ! En route vers le client." ; "Impossible d'accepter cette course." ; "Erreur lors du refus." ; "Impossible de démarrer la course. Réessayez."

**Couleurs** : `colors.foret`, `colors.bambou`, `colors.nere`, `colors.laterite`, `colors.blanc`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.manioc`, `colors.lateriteSoft`, `colors.nereSoft`. Hex en dur : `'rgba(0,0,0,0.95)'` (fond lightbox plein écran). Aucun `LinearGradient`.

**Icônes** : Ionicons. `location` (départ), `navigate` (arrivée), `ticket-outline` (mode paiement), `warning-outline`, `add-circle-outline`, `close-circle` (fermer lightbox), `alarm-outline` (course planifiée). Aucun emoji.

**Images / visuels** : `<Image source={{ uri }}>` par photo de `course.photos_colis` (vignettes + lightbox modal). `Mereau` (avatar client).

**Composants Atelier CAARCO utilisés** : `Galet`, `Plaquette`, `Cachet` (badge statut), `Mereau`, `Bandeau`.

**Structure / layout** : Header (retour, titre, `Cachet` statut). ScrollView : bloc client, bloc trajet, bloc stats (distance/véhicule/prix), photos horizontal + lightbox, bloc commission TC (alerte si solde insuffisant). Boutons variables selon statut : `en_attente` → Refuser/Accepter ; `acceptee` → "Voir l'itinéraire" ; `pre_active` → info horaire + "Démarrer la course".

---

## 25. NavigationScreen.js
`App/src/screens/transporteur/NavigationScreen.js`

**Rôle / accès** : Transporteur (TR) avec une course active (acceptée ou en cours).
**Objectif de l'écran** : Guider le TR vers le point de collecte puis de livraison (navigation intégrée CAARCO ou externe Waze/Google Maps), gérer la prise en charge, la confirmation OTP de livraison et l'annulation avant collecte.

**Textes affichés à l'écran** :
- "Rendez-vous au client" / "Naviguez jusqu'à l'adresse de collecte indiquée sur la carte. Le client vous attend." (tutoriel)
- "Code OTP de livraison" / "À la remise du colis, le client vous dicte son code à 4 chiffres. Saisissez-le pour confirmer la livraison et recevoir votre paiement." (tutoriel)
- "Aller chercher" / "En route" / "Livré" (phases) ; "arrivée" / "min" / "restant" + "Stop"
- "Hors ligne · Validation locale activée · Sync automatique au retour réseau"
- "Pas encore à destination" / `Vous êtes encore à ${distance} du point de livraison. Assurez-vous d'être à destination avant de confirmer.` / "Annuler" / "Confirmer quand même"
- "Confirmer la livraison" / "Avez-vous bien remis le colis au client à destination ?" / "Pas encore" / "Oui, livraison effectuée"
- "📍 Le transporteur est arrivé à destination." (message envoyé au client)
- "Code de livraison" (modal) ; "Demandez au client son code à 4 chiffres et saisissez-le ici." ; placeholder "0000" ; "Code incorrect. Demandez au client son code à 4 chiffres." ; "Confirmer la livraison" ; "Annuler"
- "Code de livraison requis pour confirmer." ; "Code OTP incorrect. Vérifiez avec le client." ; "Impossible de confirmer la livraison. Réessayez."
- "🚗 Votre colis est en route !" / "✅ Livraison confirmée !" (notifs offline)
- "Annuler cette course" (modal) / "Le client sera notifié et pourra relancer la même demande, la modifier, ou annuler.\n\nConfirmez-vous l'annulation ?" / "Non, continuer" / "Oui, annuler"
- "Impossible d'annuler cette course. Réessayez." ; "Impossible de mettre à jour le statut." ; "Destination introuvable." ; "Impossible d'obtenir votre position GPS." ; "Erreur lors du calcul de l'itinéraire."
- "{adresse départ}" ou "Aller chercher le colis" / "{adresse arrivée}" ou "Livrer à destination" (étiquette flottante)
- "Navigation" (bouton nav CAARCO/externe) ; "Récupéré" / "J'ai récupéré le colis" ; "Livrer" / "Je suis arrivé, Livrer"
- "Navigation en cours, voir la carte" ; "Livraison confirmée !" ; "Retour au tableau de bord" ; "Voir les détails de la course" ; "Annuler cette course"
- "Vous êtes arrivé au point de collecte" / "Appuyez pour voir les coordonnées du client"
- Alert "Coordonnées du client" / `Nom : ${nom}\nTéléphone : ${tel}`
- "À encaisser" ; "Navigation via {navAppLabel}" / "CAARCO reprendra automatiquement à votre retour" ; "Recentrer" / "Réduire"

**Couleurs** : `colors.nuit` (bandeau navigation), `colors.blanc`, `colors.bambou`, `colors.bambouSoft`, `colors.nere`, `colors.laterite`, `colors.lateriteSoft`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.foret`, `colors.manioc`. Hex en dur : `'rgba(255,255,255,0.12)'` (flèche manœuvre), `'rgba(255,255,255,0.55)'` (nom de rue), `'rgba(0,0,0,0.55)'` (overlay modal OTP), `'rgba(251,249,243,0.95)'` (étiquette flottante, boutons recentrer/réduire), `'#aaa'` (placeholder OTP). Aucun `LinearGradient`.

**Icônes** : Ionicons. Icône de manœuvre dynamique (`{etape.icone}-outline`), `close`, `location-outline`, `navigate-outline`, `checkmark-circle-outline`, `checkmark`, `navigate`, `cube`, `checkmark-circle`, `navigate-circle`, `chatbubbles-outline`, `call`, `information-circle-outline`, `close-circle-outline`, `person-circle`, `chevron-forward`, `cloud-offline-outline`, `locate`, `chevron-down`.

**Images / visuels** : `CarteLeaflet` (mode navigation orientée/perspective), `Mereau` (avatar client).

**Composants Atelier CAARCO utilisés** : `CarteLeaflet`, `Mereau`, `Alcove` (modal annulation), `Bandeau`, `TutorielPopup`, `BoutonSignalementCarte`.

**Structure / layout** : Bandeau d'erreur, barre hors-ligne conditionnelle, barre de progression 3 pastilles. Zone carte (hauteur variable) avec étiquette destination flottante, bandeau navigation guidée, barre infos bas (ETA/min/km/Stop), boutons recentrer/réduire. Panneau scrollable sous la carte (masqué en plein écran/navigation) : carte client, liens détails/annulation, coordonnées client si proche, bande prix, banner navigation externe, boutons contextuels selon phase. Modal `Alcove` annulation, modal plein écran OTP, `TutorielPopup`.

---

## 26. AttenteReglementScreen.js
`App/src/screens/transporteur/AttenteReglementScreen.js`

**Rôle / accès** : Transporteur (TR) venant de terminer une livraison.
**Objectif de l'écran** : Faire patienter/confirmer le règlement du client avant de rediriger vers l'écran de notation — deux flux distincts : paiement en espèces (confirmation manuelle) ou paiement en ligne (polling automatique du webhook).

**Textes affichés à l'écran** :
- Mode espèces : "Paiement en espèces" ; "Le client a choisi de vous payer en espèces.\nAvez-vous reçu le montant ?" ; "Montant à encaisser" ; `Commission CAARCO (${commissionFcfa} XAF) sera débitée de votre wallet si vous confirmez.` ; "Pas encore reçu" ; "Oui, j'ai reçu" / "Traitement…" ; Alert : "⚠️ Impayé CAARCO" / `Votre solde était insuffisant. Une dette de ${dette} XAF a été enregistrée.\n\nVous ne pouvez plus recevoir de courses tant que cette dette n'est pas réglée.` / "Compris"
- Mode Mobile Money/Notchpay : "Attente du règlement" ; "Votre livraison est confirmée.\nLe paiement est en cours de traitement…" ; "Montant à encaisser" ; "Livraison confirmée" / "Traitement du paiement" / "Paiement reçu" (étapes) ; Alert : "Continuer sans confirmation ?" / "Le client a peut-être déjà payé mais la confirmation tarde à arriver. Vous pouvez continuer, le paiement sera vérifié côté serveur." / "Attendre encore" / "Continuer quand même" ; "Le client a payé → Continuer"

**Couleurs** : `colors.manioc`, `colors.nere`, `colors.foret`, `colors.charbon`, `colors.cendre`, `colors.blanc`, `colors.brume`, `colors.bambou`, `colors.nereSoft`. Hex en dur : `'#e8d0a0'` (bordure du cercle animé). Aucun `LinearGradient`.

**Icônes** : Ionicons. `sync-outline` (spinner rotatif), `cash-outline`, `information-circle-outline`, `close-circle-outline`, `checkmark-circle-outline`, `wallet-outline`, `checkmark-circle`, `arrow-forward-circle-outline`.

**Images / visuels** : Aucune image ni carte ; uniquement une icône animée dans un cercle.

**Composants Atelier CAARCO utilisés** : Aucun (uniquement tokens du thème).

**Structure / layout** : Icône circulaire animée, titre, sous-titre, bloc montant à encaisser. Puis selon `methodeEspeces` : deux boutons "Pas encore reçu"/"Oui, j'ai reçu" + info commission, ou liste de 3 étapes de progression avec spinner + bouton de déblocage manuel après 90 secondes.

---

## 27. NotationClientScreen.js
`App/src/screens/transporteur/NotationClientScreen.js`

**Rôle / accès** : Transporteur (TR) venant de terminer et d'être payé pour une course.
**Objectif de l'écran** : Permettre au TR de noter le client (note globale + critères détaillés + commentaire) avant de retourner au tableau de bord.

**Textes affichés à l'écran** :
- "Ponctualité" / "Communication" / "Colis bien préparé" / "Disponibilité" (critères)
- "Paiement reçu" ; "{montant} XAF"
- "Notez ce client" ; "{nom client}" ; "Note globale"
- "Commentaire (optionnel)" ; placeholder "Décrivez votre expérience avec ce client…"
- "Envoyer la note" ; "Passer sans noter"
- Erreur : `e?.message ?? 'Impossible de soumettre la note.'`

**Couleurs** : `colors.nere`, `colors.brume`, `colors.bambouSoft`, `colors.bambou`, `colors.blanc`, `colors.charbon`, `colors.cendre`, `colors.foret`, `colors.manioc`. Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `star`/`star-outline`, `checkmark-circle` (bannière paiement), `time-outline`, `chatbubble-outline`, `cube-outline`, `person-circle-outline` (4 critères).

**Images / visuels** : `Mereau` (avatar client).

**Composants Atelier CAARCO utilisés** : `Mereau`, `Bandeau`.

**Structure / layout** : ScrollView : bannière "Paiement reçu", carte titre client, carte note globale (5 étoiles), carte critères détaillés (4 lignes mini-étoiles), zone commentaire, bouton "Envoyer la note", lien "Passer sans noter".

---

## 28. CoursesTransporteurScreen.js
`App/src/screens/transporteur/CoursesTransporteurScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Lister toutes les courses du TR (en cours en tête, puis historique passé), avec accès rapide pour reprendre la navigation d'une course active.

**Textes affichés à l'écran** :
- "Mes courses" ; "Aucune course acceptée" ; "Les courses que vous acceptez\napparaîtront ici"
- "EN COURS · {n}" ; "Reprendre la navigation"
- "{distance} km · {véhicule}" ; "{prix} XAF" ; "{nom client}" ; date formatée

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.bambou`, `colors.nere`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.manioc` (+ équivalents `tc.*` via `useTheme`). Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `refresh-outline`, `car-outline` (état vide), `navigate-outline` (badge "Reprendre la navigation").

**Images / visuels** : `Mereau` (avatar client, "xs").

**Composants Atelier CAARCO utilisés** : `Plaquette`, `Cachet`, `Mereau`.

**Structure / layout** : Header + actualiser. `FlatList` de cartes course (date, statut, client, trajet, distance/véhicule/prix, bandeau "Reprendre la navigation" si active). Section "EN COURS" en tête. État vide dédié.

---

## 29. RevenusScreen.js
`App/src/screens/transporteur/RevenusScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Tableau de bord des revenus (gains jour/semaine/mois, chiffre d'affaires global, classement mensuel, bonus volume) avec historique des courses filtrable par onglets.

**Textes affichés à l'écran** :
- "Vos gains et commissions" / "CAARCO prélève 20 % de commission en Tokens de Course sur chaque livraison. Gérez vos TC dans l'onglet Tokens." (tutoriel)
- "Toutes" / "Livrées" / "Annulées" (onglets) ; "Revenus"
- "Aujourd'hui" / "Cette semaine" / "Ce mois" (StatCard)
- "CHIFFRE D'AFFAIRES" ; "{n} course{s} · Montant brut payé par les clients"
- "CLASSEMENT CE MOIS" / "#{rang} à Bafoussam"
- "BONUS VOLUME (MOIS PRÉCÉDENT)" / "+{n} XAF crédités"
- "Gérer mes Tokens de Course" ; "Aucune course dans cette catégorie"
- "Perçu en cash" (badge) ; "{prix} brut" ; "+{montant} XAF" ; "{distance} km"

**Couleurs** : `colors.foret`, `colors.bambou`, `colors.bambouSoft`, `colors.nere`, `colors.nereSoft`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc`. Pas de hex brut (concaténations d'opacité sur tokens). Aucun `LinearGradient`.

**Icônes** : Ionicons. `stats-chart-outline`, `diamond-outline` (packs abonnement), `trophy-outline` (classement), `flash-outline` (bonus), `ticket-outline` (gérer tokens).

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Plaquette`, `Cachet`, `Onglets`, `TutorielPopup`.

**Structure / layout** : Header (titre + icônes stats/packs — icône "encaissement" masquée pour la V1 Play Store). Rangée 3 `StatCard` (jour/semaine/mois). Carte CA global. Bloc motivation (rang + bonus). Bouton vers "Mes Tokens". Onglets de filtre. `FlatList` de courses avec badge "Perçu en cash". `TutorielPopup`.

---

## 30. StatsTransporteurScreen.js
`App/src/screens/transporteur/StatsTransporteurScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Statistiques détaillées de performance (durée moyenne, nombre de courses, revenus nets avec graphique 7 jours, efficacité, note clients, distance totale) filtrables par période.

**Textes affichés à l'écran** :
- "Semaine" / "Mois" / "Tout" (filtre période) ; "Statistiques"
- "Durée moy. course" / "De la prise en charge à la livraison"
- "Courses livrées" / "{n} km au total" ou "Aucune pour cette période"
- "Revenus nets" / "{montant} XAF" / "Commission CAARCO déjà déduite"
- "Courses / jour actif" / "Excellent" / "Bon" / "Aucune donnée"
- "Jours actifs" / "{actifs}/{total}" ; "Note clients" / "{note}" / "Moyenne sur toutes vos courses"
- "Distance totale" / "{km} km" / "Moy. {x} km / course"
- "Dim","Lun","Mar","Mer","Jeu","Ven","Sam" (labels graphique)

**Couleurs** : `colors.foret`, `colors.bambou`, `colors.nere`, `colors.laterite`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc`. Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `time-outline`, `cube-outline`, `wallet-outline`, `flash-outline`, `calendar-outline`, `star`/`star-outline`, `location-outline`, `trophy`.

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : Aucun (composants locaux `CarteStat`, `BarresJours`, `EtoilesNote`).

**Structure / layout** : Header + filtre période en pilules. ScrollView pull-to-refresh : 2 cartes (durée moyenne, nb courses), carte revenus nets avec mini-graphique 7 jours, 2 cartes (efficacité, jours actifs), carte note clients, carte distance totale.

---

## 31. RetraitScreen.js
`App/src/screens/transporteur/RetraitScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Demander un retrait Mobile Money du solde du wallet TR (Orange Money / MTN MoMo).

**Textes affichés à l'écran** :
- "Retrait" ; "SOLDE DISPONIBLE"
- "Montant à retirer" / placeholder "0" / "XAF" ; "Min {min} XAF · Max {max} XAF"
- "Méthode de paiement" ; "Orange Money" (hint "6XXXXXXXX") / "MTN Mobile Money" (hint "67XXXXXXX")
- "Numéro {label méthode}" / préfixe "+237"
- "Les fonds sont versés sous 24h ouvrées. En cas de problème, contactez le support CAARCO."
- "Demander le retrait"
- Erreurs : `Montant minimum : ${min} XAF`, `Montant maximum : ${max} XAF`, `Solde insuffisant (${solde} XAF disponible)`, "Numéro Mobile Money invalide.", "Impossible d'envoyer la demande. Réessayez."
- Succès : "Demande envoyée !" / `Votre retrait de ${montant} XAF est en cours de traitement.\nVous recevrez les fonds sur votre numéro ${méthode} sous 24h.` / "Retour aux revenus"

**Couleurs** : `colors.manioc`, `colors.foret`, `colors.foret10`, `colors.foret30`, `colors.brume`, `colors.charbon`, `colors.cendre`, `colors.blanc`, `colors.bambou`, `colors.nereSoft`, `colors.laterite`. Hex en dur : Orange Money `'#FF6600'`/`'#FFF3EB'` ; MTN MoMo `'#FFCC00'`/`'#FFFBE6'`. Aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `phone-portrait-outline`, `information-circle-outline`, `checkmark-circle`, `arrow-up-circle-outline`.

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Bandeau`.

**Structure / layout** : Header + ScrollView/KeyboardAvoidingView : carte solde (fond forêt), carte montant, méthodes sélectionnables, champ numéro, info délai. Pied fixe "Demander le retrait" (désactivé si invalide). Écran de succès plein écran après envoi.

---

## 32. EncaissementScreen.js
`App/src/screens/transporteur/EncaissementScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Générer un QR code et un identifiant partageable permettant à un client de payer le TR directement (fonctionnalité liée au wallet).

**Textes affichés à l'écran** :
- "Encaissement" ; "MON SOLDE WALLET" ; "{solde} XAF"
- `QR pour ${montant} XAF` ou "Mon QR de paiement" ; "Le client scanne ce QR dans l'onglet \"Payer\""
- "MONTANT À DEMANDER (optionnel)" / placeholder "Laissez vide pour montant libre" / "XAF"
- "MON IDENTIFIANT CAARCO" ; "Le client peut entrer cet ID manuellement dans l'onglet \"Saisie\""
- "Copier" / "Copié !" ; `Demander ${montant} XAF` ou "Partager mon ID"
- Message de partage : `Payez-moi ${montant} XAF sur CAARCO.\nMon ID : ${id}` ou `Payez-moi sur CAARCO.\nMon ID : ${id}`

**Couleurs** : `colors.foret`, `colors.blanc`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.manioc`, `colors.nere`. Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `close-circle`, `copy-outline`/`checkmark`, `share-social-outline`.

**Images / visuels** : `QRCodeView` (composant custom générant un QR depuis `caarco://receive?userId=...&amount=...`).

**Composants Atelier CAARCO utilisés** : Aucun composant standard ; `QRCodeView` custom.

**Structure / layout** : Header (retour conditionnel + titre). ScrollView : carte solde wallet, section QR (titre dynamique, QR code, champ montant optionnel), section identifiant (ID tronqué + copier), bouton "Partager".

---

## 33. PacksAbonnementScreen.js
`App/src/screens/transporteur/PacksAbonnementScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Présenter 3 formules d'abonnement (Standard/Pro/Elite) avec avantages et tableau comparatif ; l'activation réelle n'est pas encore fonctionnelle (affiche une alerte "bientôt disponible").

**Textes affichés à l'écran** :
- "STANDARD" / "Développez votre activité" ; avantages : "Courses illimitées", "Commission CAARCO réduite à 12%", "Badge transporteur vérifié", "Priorité dans le matching clients", "Accès aux livraisons express", "Support prioritaire CAARCO"
- "PRO" / "Maximisez vos revenus" ; avantages : "Tout ce que Standard inclut", "Commission CAARCO réduite à 8%", "Badge Pro CAARCO", "Profil mis en avant pour les clients", "Tableau de bord analytique avancé", "Longues distances débloquées", "Support dédié 7j/7"
- "ELITE" / "L'expérience CAARCO ultime" ; avantages : "Tout ce que Pro inclut", "Commission CAARCO réduite à 5%", "Badge Elite doré", "Placement N°1 dans les résultats", "Contrats entreprises en priorité", "Gestionnaire de compte dédié", "Formations gratuites CAARCO"
- "Commission actuelle : 20% TC par course · Taux réduit disponible prochainement"
- "⭐ LE PLUS POPULAIRE" ; `Seulement ${commission}% de commission par course`
- "Abonnement Annuel" / "Meilleur prix" / "XAF / MOIS" ; "Abonnement Mensuel" / "XAF / MOIS" ; `Économie : ${n} XAF`
- `Plan actif, ${nom}` ou `Activer le plan ${nom}`
- Alert : `Activer ${nom}` / `${prix} XAF / ${an|mois}\n\nPaiement via Notchpay (MTN MoMo / Orange Money).\n\nFonctionnalité disponible très prochainement !` / "Annuler" / "Me prévenir"
- Alert : "Déjà actif" / `Vous êtes déjà sur le plan ${nom}.`
- "Plan actuel : {NOM}" ; `Pack ${nom}` ; "Comparer tous les plans"
- "Commission CAARCO" / "Mensuel" / "Annuel" (tableau comparatif)

**Couleurs** : `colors.bambou`, `colors.bambouSoft`, `colors.nere`, `colors.nereSoft`, `colors.foret`, `colors.blanc`, `colors.brume`, `colors.charbon`, `colors.cendre`, `colors.manioc`. Hex en dur : `'#2d5238'` (fin gradient Standard), `'#a67535'` (fin gradient Pro), `'#0f2118'` (fin gradient Elite), `'rgba(255,255,255,0.2)'` (badge populaire), `'rgba(255,255,255,0.15)'`/`'0.12'`/`'0.8'` (icône hero, bloc commission, tagline). `LinearGradient` diagonal utilisé pour le bloc hero : `[colors.bambou, '#2d5238']` (Standard), `[colors.nere, '#a67535']` (Pro), `[colors.foret, '#0f2118']` (Elite).

**Icônes** : Ionicons. `information-circle-outline`, `close`, `checkmark`, `trending-down`, `checkmark-circle`/`rocket-outline`. Icônes des avantages : `infinite-outline`, `trending-down-outline`, `shield-checkmark`, `flash-outline`, `bicycle-outline`, `headset-outline`, `checkmark-done-outline`, `ribbon-outline`, `person-circle-outline`, `bar-chart-outline`, `map-outline`, `call-outline`, `trophy-outline`, `podium-outline`, `briefcase-outline`, `person-outline`, `school-outline`. Emojis : ⚡ (Standard), ⭐ (Pro), 💎 (Elite), ✅ (alerte).

**Images / visuels** : Aucune image statique ; hero décoratif via `LinearGradient`.

**Composants Atelier CAARCO utilisés** : Aucun composant standard — interface entièrement custom.

**Structure / layout** : Bannière fine d'info commission. Header à 3 onglets (Standard/Pro/Elite) + fermer. ScrollView : carte hero dégradée (badge populaire, emoji, nom, tagline, highlight commission), sélecteur Annuel/Mensuel, résumé prix, CTA "Activer", plan actuel, liste des avantages, tableau comparatif des 3 plans.

---

## 34. MessagesTransporteurScreen.js
`App/src/screens/transporteur/MessagesTransporteurScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Lister les conversations du TR (messages directs hors course + discussions liées à des courses), avec sélection multiple, archivage, partage et suppression.

**Textes affichés à l'écran** :
- "Messages" ; "{n} sélectionné(s)" ; "Tout"
- "Aucun message" / "Les clients qui vous contactent\napparaîtront ici"
- "MESSAGES DIRECTS" / "COURSES" (sections + badge de compte)
- "📷 Photo" (aperçu message image) ou contenu du message
- "Sélectionner" / "Archiver" / "Désarchiver" / "Partager" / "Supprimer la conversation"
- Alert : `Supprimer ${n} conversation(s) ?` / "Les messages seront définitivement supprimés."
- Partage : `Message de ${nom}` ; `${client}, ${départ} → ${arrivée}` ; titre "Conversations CAARCO"

**Couleurs** : `colors.foret`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc`, `colors.laterite`, `colors.bambou`. Hex en dur : `'#edf4ef'` (fond items sélectionnés). Aucun `LinearGradient`.

**Icônes** : Ionicons. `close`, `refresh-outline`, `chatbubbles-outline`, `chevron-forward`, `checkmark-circle-outline`, `archive-outline`/`arrow-up-circle-outline`, `share-outline`, `trash-outline`, `checkmark`.

**Images / visuels** : `Mereau` (avatar client/expéditeur) avec pastille "non lu" ou case à cocher.

**Composants Atelier CAARCO utilisés** : `MenuContextuel`, `Mereau`.

**Structure / layout** : Header à deux états (normal / sélection). `FlatList` mêlant en-têtes de section et items, appui long ouvrant `MenuContextuel`. Barre d'actions flottante en mode sélection. État vide dédié.

---

## 35. ProfilClientScreen.js
`App/src/screens/transporteur/ProfilClientScreen.js`

**Rôle / accès** : Transporteur (TR), accédé depuis le lien "Profil" d'une carte course.
**Objectif de l'écran** : Afficher le profil public du client associé à une course (note moyenne, nombre de courses) ainsi que le détail de la course demandée.

**Textes affichés à l'écran** :
- "Profil client" ; "{nom client}" ; "{note} sur 5" ; "{n} course{s} passée{s}"
- "COURSE DEMANDÉE" ; "{Type de véhicule}" ; "{distance} km · {prix} XAF"
- "DÉPART" / "ARRIVÉE" ; "DEMANDE REÇUE" ; date/heure formatée

**Couleurs** : `colors.nere`, `colors.foret10`, `colors.bambou`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `star`/`star-half`/`star-outline`, `bicycle-outline`/`car-outline`/`car-sport-outline`/`bus-outline`, `time-outline`.

**Images / visuels** : `Mereau` (avatar client, "xl").

**Composants Atelier CAARCO utilisés** : `Mereau`, `Plaquette`.

**Structure / layout** : Header + ScrollView : bloc hero (avatar, nom, étoiles, note, nb courses), carte "COURSE DEMANDÉE" (véhicule, distance/prix, trajet), carte "DEMANDE REÇUE" (date/heure).

---

## 36. AdDetailScreen.js
`App/src/screens/transporteur/AdDetailScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Afficher le détail complet d'une "annonce" de course (marketplace de candidatures) et permettre au TR de proposer ses services si son KYC l'y autorise, ou de consulter en lecture seule une course déjà assignée.

**Textes affichés à l'écran** :
- "Détails" / "Détails de l'annonce" ; "#{id}"
- "CLIENT" ; "{note}" / "·" / "{n} course{s}"
- "TRAJET" ; "DÉPART" / "ARRIVÉE" ; "{distance} km" / "{véhicule}"
- "COLIS" ; "Poids" ("{n} kg"), "Colis" ("{n}"), "Dimensions" ("{L}×{H} cm"), "Catégorie"
- "PHOTOS DES COLIS ({n}) · Appuyer pour agrandir"
- "À percevoir" / "{prix} XAF" ; "Distance" / "{km} km"
- "Annonce introuvable" ; "Impossible de charger les détails." ; "Cette course n'est plus disponible."
- "Vous êtes hors ligne. Passez en ligne pour proposer vos services."
- "Proposition envoyée, en attente du client"
- "Vous ne pouvez pas accepter cette course" / `Approuvé pour ${véhiculeLabel} · Cette course requiert ${véhiculeLabel}`
- "Proposer mes services"

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.foret30`, `colors.foret70`, `colors.nere`, `colors.bambou`, `colors.bambouSoft`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc`, `colors.laterite`, `colors.lateriteSoft`. Hex en dur : `'rgba(0,0,0,0.95)'` (fond lightbox). Aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `star`/`star-half`/`star-outline`, `navigate-circle-outline` (badge distance), `bicycle-outline`/`car-outline`/`car-sport-outline`/`bus-outline`, `scale-outline` (poids), `cube-outline` (nb colis), `resize-outline` (dimensions), `pricetag-outline` (catégorie), `checkmark-circle`, `lock-closed` (non éligible), `alert-circle-outline`, `close-circle`.

**Images / visuels** : `Mereau` (avatar client). `<Image source={{ uri }}>` par photo de colis (vignettes + lightbox).

**Composants Atelier CAARCO utilisés** : `Mereau`, `Plaquette`.

**Structure / layout** : Header retour + titre + badge ID. ScrollView : carte client, carte trajet + badge distance/véhicule, carte colis, photos + lightbox, bandeau prix (fond forêt), erreur inline. Pied fixe variable : proposition déjà envoyée / bloc "non éligible" (cadenas) / bouton "Proposer mes services".

---

## 37. SoumissionKYCScreen.js
`App/src/screens/transporteur/SoumissionKYCScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Formulaire de soumission du dossier KYC (type de véhicule, immatriculation, CNI, permis avec dates, photos du véhicule) pour validation par l'équipe CAARCO.

**Textes affichés à l'écran** :
- "Dossier KYC" ; "Votre dossier sera vérifié par l'équipe CAARCO sous 24-48h. Tous les documents doivent être lisibles et valides."
- "TYPE DE VÉHICULE *" / "Choisir un véhicule…" / "Moto", "Voiture", "Tricycle / Van", "Camion"
- "IMMATRICULATION (optionnel)" / placeholder "ex : LT 1234 A"
- "DOCUMENTS IDENTITÉ" ; "Carte Nationale d'Identité" / "Photo recto de votre CNI" ; "Permis de conduire" / "Photo de votre permis valide"
- "Appuyer pour changer" ; "Date de délivrance" / "Date d'expiration" / placeholder "JJ/MM/AAAA"
- "PHOTOS DU VÉHICULE" ; "Photo véhicule {n}" ; "Ajouter une photo du véhicule"
- Alert choix source : "Caméra" / "Galerie" / "Annuler" ; Alert photo véhicule : "Changer" / "Supprimer" / "Annuler"
- Alert permission : "Autorisez l'accès à la caméra." / "Autorisez l'accès à la galerie."
- Alert : "Maximum 3 photos de véhicule" ; "* Champs obligatoires" ; "Soumettre le dossier"
- Étapes d'upload : "CNI…", "Permis…", "Photos véhicule…", "Enregistrement…"

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.foret30`, `colors.blanc`, `colors.brume`, `colors.charbon`, `colors.cendre`, `colors.manioc`, `colors.bambou`, `colors.laterite` (astérisque). Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `shield-checkmark-outline`, `car-outline`/`bicycle-outline`/`cube-outline`/`bus-outline`, `chevron-up`/`chevron-down`, `checkmark`, `card-outline`, `camera-outline`, `checkmark-circle`, `calendar-outline`, `add-circle-outline`, `send-outline`.

**Images / visuels** : `<Image source={{ uri }}>` pour CNI/permis/jusqu'à 3 photos véhicule, uploadées vers Supabase Storage bucket `kyc-documents`.

**Composants Atelier CAARCO utilisés** : Aucun (formulaire entièrement custom).

**Structure / layout** : Header + ScrollView formulaire : bandeau info, dropdown véhicule, immatriculation, section documents (CNI + dates, permis + dates), section photos véhicule (jusqu'à 3), note obligatoire. Pied fixe "Soumettre le dossier" avec étape d'upload en cours.

---

## 38. StatutKYCScreen.js
`App/src/screens/transporteur/StatutKYCScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Afficher le statut du dossier KYC soumis (en attente / approuvé / rejeté / infos manquantes) avec le détail du véhicule, les documents et le motif de rejet éventuel.

**Textes affichés à l'écran** :
- "En cours d'examen" / "Votre dossier est en cours de vérification par l'équipe CAARCO."
- "Dossier approuvé" / "Félicitations ! Vous pouvez maintenant accepter des courses."
- "Dossier rejeté" / "Votre dossier a été refusé. Consultez le motif ci-dessous."
- "Informations manquantes" / "Des documents supplémentaires sont requis."
- "Mon dossier KYC" ; "Aucun dossier soumis" ; "Soumettez votre dossier pour commencer à\naccepter des courses sur CAARCO." ; "Soumettre mon dossier"
- "Ce badge est visible par les clients dans l'application. Il indique que votre identité et votre véhicule ont été vérifiés par l'équipe CAARCO."
- "MOTIF" + motif de rejet
- "VÉHICULE" / "Type" / "Immatriculation" / "Soumis le {date}"
- "DOCUMENTS SOUMIS" / "CNI" / "Permis" / "Véhicule {n}" / "Aucun document visible"
- "Validé le {date}" ; "Resoumettre le dossier"
- "Pour toute question sur votre dossier, contactez le support CAARCO."

**Couleurs** : `colors.nere`, `colors.nereSoft`, `colors.bambou`, `colors.bambouSoft`, `colors.laterite`, `colors.lateriteSoft`, `colors.foret`, `colors.foret10`, `colors.foret30`, `colors.foret70`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc`. Aucun hex en dur, aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back` ou `log-out-outline`, `document-text-outline`, `send-outline`, `time-outline`/`checkmark-circle-outline`/`close-circle-outline`/`alert-circle-outline` (statut), `car-outline`, `card-outline`, `calendar-outline`, `warning-outline`, `shield-checkmark-outline`, `refresh-outline`, `information-circle-outline`, `image-outline` (fallback).

**Images / visuels** : `<Image source={{ uri }}>` pour CNI/permis/véhicules, avec état d'erreur. `BadgeVerifie` si approuvé.

**Composants Atelier CAARCO utilisés** : `BadgeVerifie`.

**Structure / layout** : Header retour/déconnexion + titre. Si aucun dossier : état vide + CTA. Sinon ScrollView pull-to-refresh : bannière de statut colorée, badge vérifié conditionnel, motif de rejet conditionnel, carte infos véhicule, photos de documents, date de validation, bouton "Resoumettre" si rejeté, bloc d'aide.

---

## 39. MesTokensScreen.js
`App/src/screens/transporteur/MesTokensScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Gérer le solde de Tokens de Course (TC) — achat via Notchpay (WebView Mobile Money) et consultation de l'historique des transactions.

**Textes affichés à l'écran** :
- "Acheter des Tokens" ; "Quantité (min. {min} TC)" ; placeholder "ex : 5 000" ; `Minimum ${min} TC (${min} FCFA)` ; "= {montant} FCFA"
- Boutons rapides : 5 000 / 10 000 / 25 000 / 50 000 / 100 000 TC ; "Continuer"
- "Achat TC" / "Commission course" (transactions)
- "Paiement confirmé !" ; "Tokens ajoutés" / "+{n} TC" ; "Nouveau solde" / "{n} TC" ; "Super !"
- "Mes Tokens" ; "SOLDE TOKENS DE COURSE" ; "= {solde} FCFA"
- "Solde bas — rechargez pour continuer à accepter des courses"
- "Chaque course déduit 20 % du prix en TC de votre solde à la livraison."
- "ACHATS RAPIDES" ; "HISTORIQUE" / "Aucune transaction pour le moment."
- "Paiement Notchpay" ; "Chargement Notchpay…" ; "J'ai payé — Vérifier mon paiement" ; "Vérification du paiement en cours…"
- "Récapitulatif" ; "Tokens achetés" / "{n} TC" ; "Montant à payer" / "{n} FCFA" ; "Paiement via" / "Notchpay (MTN / Orange)"
- "Les TC ne sont ni retirables, ni transférables. Ils diminuent à chaque livraison pour payer la commission CAARCO."
- `Payer ${montant} FCFA`

**Couleurs** : `colors.foret` (fond carte solde), `colors.bambou`, `colors.nere`, `colors.laterite`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc` (majoritairement dynamique `tc.*`). Hex en dur : `'rgba(15,20,17,0.72)'` (overlay modal succès). Aucun `LinearGradient`.

**Icônes** : Ionicons. `arrow-back`, `refresh`, `close`, `warning-outline`, `information-circle-outline`, `add-circle-outline`, `arrow-down`/`arrow-up` (transaction), `checkmark` (succès), `checkmark-circle-outline` ("j'ai payé").

**Images / visuels** : `WebView` chargeant la page Notchpay. Pas d'avatar/photo.

**Composants Atelier CAARCO utilisés** : Aucun composant standard — `EtapeChoix`, `LigneTransaction`, `SuccesModal` locaux.

**Structure / layout** : Header + refresh. ScrollView : carte solde (fond forêt), bandeau info commission, CTA "Acheter des Tokens", grille de 5 boutons rapides, historique. Flux modaux : WebView Notchpay avec secours "J'ai payé", bannière de vérification, modal 2 étapes (Choix quantité → Récapitulatif), `SuccesModal` animé.

---

## 40. LeaderboardScreen.js
`App/src/screens/transporteur/LeaderboardScreen.js`

**Rôle / accès** : Transporteur (TR).
**Objectif de l'écran** : Afficher le classement mensuel des transporteurs (nombre de courses, note) avec mise en avant de la position du TR connecté et messages de motivation.

**Textes affichés à l'écran** :
- "{Mois} {Année}" ; "Classement" ; "{titreDate} · Bafoussam" ; "LIVE"
- "Votre position" ; "{n} course{s}" ; `${needed} course${s} pour atteindre le rang #${rang-1}`
- "🚀 {motivMsg}" (bloc position propre) ; "{motivMsg}" (bannière compacte)
- "Le classement sera disponible\ndès que les premières courses seront complétées." (état vide)
- "{nom} (moi)" ; "courses" ; "TOP {rang}" ou "#{rang}"

**Couleurs** : `colors.foret`, `colors.nere`, `colors.bambou`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.manioc`, `colors.nereSoft`. Hex en dur : `'#3db551'` (point en ligne), `'#f0f5f1'` (fond ligne "moi"), `'#C9A227'` (or), `'#8C9099'` (argent), `'#A0522D'` (bronze). Aucun `LinearGradient`.

**Icônes** : Ionicons. `trophy`, `shield-checkmark` (vérifié), `flash` (motivation), `trophy-outline` (vide). Emojis : 🥇🥈🥉 (médailles), 🚀 (motivation).

**Images / visuels** : `Mereau` (avatar TR) avec pastille verte "en ligne".

**Composants Atelier CAARCO utilisés** : `Mereau`.

**Structure / layout** : Header (titre, sous-titre mois/ville, trophée, "LIVE" pulsant). Bloc "Votre position" mis en avant si hors top affiché. Bannière de motivation compacte sinon. `FlatList` du classement (médaille/rang, avatar, nom+badge+étoiles+note, nb courses, badge or/argent/bronze ou "TOP n"), pull-to-refresh, état vide.

---

# ADMIN (18 écrans)

## 41. AdminShell.js
`App/src/screens/admin/AdminShell.js`

**Rôle / accès** : Administrateur (unique point d'entrée du back-office admin ; conteneur qui héberge tous les autres écrans admin).
**Objectif de l'écran** : Fournit la coquille de navigation de l'admin (sidebar rétractable, historique de navigation, bascule desktop/mobile, déconnexion) et affiche l'écran actif parmi les 17 autres écrans admin.

**Textes affichés à l'écran** :
- "CAARCO" ; "Administration"
- Sections sidebar : "GESTION", "UTILISATEURS", "FINANCES", "MARKETING", "CARTE", "SYSTÈME"
- Items de menu : "Vue d'ensemble", "Opérations live", "Courses", "Transporteurs", "Clients", "Utilisateurs", "Vérif. KYC", "Litiges", "Finances", "Tokens TC", "Calendrier", "Notifications", "Lieux à valider", "Paramètres"
- "Déconnexion" ; nom par défaut "Administrateur" ; initiale par défaut "A"
- Modal déconnexion : "Déconnexion", "Quitter le panneau administrateur ?", "Annuler", "Déconnecter"

**Couleurs** : `colors.manioc` (fond général), `colors.foret` (fond sidebar), `colors.foret90` (séparateurs), `colors.foret30` (icônes/texte secondaire), `colors.nere` (icône/label actif), `colors.blanc` (logo, label actif), `colors.bambou` (avatar profil), `colors.laterite` (déconnexion), `colors.brume` (bordure bouton annuler), `colors.charbon`, `colors.cendre`. Hex en dur : `'rgba(200, 148, 65, 0.12)'` (item de menu actif), `'rgba(15,20,17,0.52)'` (voile sidebar mobile), `'rgba(15,20,17,0.6)'` (voile modal déconnexion). Aucun `LinearGradient`.

**Icônes** : Ionicons. `close-outline`, `log-out-outline`. Icônes dynamiques par item de menu (suffixées `-outline` si inactif) : `stats-chart`, `map`, `navigate-circle`, `car`, `people`, `person`, `id-card`, `warning`, `cash`, `ticket`, `calendar`, `notifications`, `map-outline`, `settings`.

**Images / visuels** : `require('../../../assets/Logo Blanc.png')` (logo CAARCO blanc en haut de sidebar).

**Composants Atelier CAARCO utilisés** : Aucun (construit avec `View`/`TouchableOpacity`/`Animated` bruts).

**Structure / layout** : Desktop (≥768px) : sidebar fixe 220px + zone de contenu. Mobile : écran actif plein écran + sidebar overlay coulissant avec voile et bouton fermeture ; pile d'historique de navigation + gestion du bouton retour Android. Modal centré de confirmation de déconnexion.

---

## 42. DashboardScreen.js
`App/src/screens/admin/DashboardScreen.js`

**Rôle / accès** : Administrateur — écran "Vue d'ensemble" (accueil du back-office).
**Objectif de l'écran** : Donner une vue synthétique en temps réel de l'activité (CA, commissions, taux de livraison, transporteurs en ligne, courses récentes, litiges) et permettre d'activer/désactiver le mode maintenance global de l'application.

**Textes affichés à l'écran** :
- Filtres période : "Auj.", "7 jours", "30 jours"
- Raccourcis : "Live", "Transporteurs", "Clients", "KYC", "Finances", "Litiges"
- Hero : "CAARCO", "LIVE", "XAF · CA", "XAF · Comm.", "Livrées", "TR online"
- Bannière maintenance : "MAINTENANCE ACTIVE, App inaccessible", bouton "Désactiver"
- "Dashboard", sous-titre `` `${heureMAJ} · Cameroun` ``
- Modal maintenance : titre `'Désactiver la maintenance ?'` / `'⚠️ Activer la maintenance ?'` ; description `"L'application redeviendra accessible pour tous les utilisateurs immédiatement."` / `"Tous les clients et transporteurs seront bloqués instantanément sur tous les appareils."` ; placeholder "Message affiché aux utilisateurs (optionnel)" ; boutons "Annuler", "Réactiver"/"Activer"
- "ACCÈS RAPIDE" ; KPI : "Courses" (sous "{n} livrées"), "Chiffre d'aff.", "Commission CAARCO" (sous "20% des courses livrées"), "Nouveaux clients"
- "Courses programmées en attente", "Des courses sont planifiées, transporteurs à assigner"
- "TRANSPORTEURS EN LIGNE" ; "DERNIÈRES COURSES", "Voir tout →" ; "ACTIVITÉ · 24H" ; "TOP VÉHICULES"
- "LITIGES EN ATTENTE" ; `` `#A-${2090+i}` `` ; "Litige en cours" ; "Urgent" / "Médiation"
- Véhicules : "Moto", "Voiture", "Tricycle/Van", "Camion"
- Statuts : "En attente", "Acceptée", "En cours", "Livrée" (×2), "Annulée", "Litige", "Programmée"

**Couleurs** : `colors.foret` (hero, icône courses), `colors.nere` (commission, statut en_attente/programmee), `colors.bambou`/`bambouSoft` (acceptee/livree/terminee, badge TR online), `colors.laterite`/`lateriteSoft` (annulee/litige, bannière maintenance), `colors.nereSoft` (tag "Médiation"), `colors.manioc`, `colors.brume`, `colors.cendre`, `colors.charbon`, `colors.blanc`, `colors.nuit` (fond carte hero). Hex en dur : `'#5cd97d'` (point LIVE), `'#16a34a'` (point en ligne), `'rgba(22,163,74,0.2)'` (fond badge LIVE), `'#e6f9f0'` (fond badge LIVE header), `'#1e7e34'`/`'#c0392b'` (tendance +/-), `'#e6f4ea'`/`'#fce8e6'` (fond tendance). Pas de `LinearGradient` (le hero utilise une simple `View` opacity 0.08).

**Icônes** : Ionicons. `menu-outline`, `refresh-outline`, `shield-checkmark`/`shield-outline`, `warning`, `trending-up`/`trending-down`, icônes raccourcis (`map`, `car-sport-outline`, `people-outline`, `id-card-outline`, `cash-outline`, `warning-outline`), `navigate-circle-outline`, `trending-up-outline`, `person-add-outline`, `calendar-outline`. Emojis : `EMOJI_VEH` (🏍🚗🚐🛺🚛) sur cartes TR + répartition véhicules ; ★ (note TR).

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Plaquette` (derniers courses, activité 24h, top véhicules, litiges).

**Structure / layout** : ScrollView pull-to-refresh. Bannière maintenance conditionnelle, en-tête (menu, titre/sous-titre, rafraîchir, bascule maintenance), pilules de période + badge LIVE, hero sombre (4 métriques + mini-histogramme horaire), grille de 6 raccourcis, grille KPI 2×2, bandeau "courses programmées" conditionnel, scroll horizontal TR en ligne, `Plaquette` dernières courses, `Plaquette` graphique horaire, `Plaquette` barres véhicules, `Plaquette` litiges en attente. Modal maintenance. Spinner de chargement.

---

## 43. KYCValidationScreen.js
`App/src/screens/admin/KYCValidationScreen.js`

**Rôle / accès** : Administrateur — file d'attente de vérification KYC des transporteurs.
**Objectif de l'écran** : Examiner les dossiers KYC en attente (documents, dates de validité) et approuver, rejeter ou demander des corrections.

**Textes affichés à l'écran** :
- Véhicules : "Moto", "Voiture", "Camionnette", "Tricycle", "Tricycle / Van", "Camion"
- Temps d'attente : "< 1h", `` `${h}h` ``, `` `${j}j` ``
- Jauge validité : "Date non renseignée" ; `` `Expiré il y a ${n}j` ``, `` `Expire dans ${n}j` ``, `` `Valide · ${n}j restants` `` ; "Expiration : " + date
- Statuts document : "Présent", "À vérifier", "Manquant"
- Documents : "CNI", "Permis", "Véhicule (1)", "Véhicule (2)", "Carte grise", "Assurance"
- "Dossier KYC" ; "Inscrit le " + date
- Boutons : "Corrections", "Refuser", "Valider"
- "MOTIF", placeholder "Ex : CNI illisible, permis expiré, photo floue…"
- "DOCUMENTS", "VALIDITÉ DES DOCUMENTS" ; "CNI", "Permis de conduire"
- "Vérifications KYC" ; `` `${n} dossier${s} en attente` `` ou "Aucun dossier en attente"
- Recherche : placeholder "Rechercher un transporteur…" ; "Chargement des dossiers…"
- Vide : "Aucun dossier en attente", "Tous les transporteurs ont été traités" ; `` `Aucun résultat pour « ${recherche} »` ``

**Couleurs** : `colors.laterite` (expiré, manquant, refuser), `colors.nere` (attente, seuil ≤90j), `colors.bambou` (ok/valider), `colors.foret`/`foret10` (tag véhicule, bordure corrections), `colors.foret30`, `colors.cendre`, `colors.charbon`, `colors.brume`, `colors.manioc`, `colors.blanc`, `colors.nereSoft`, `colors.lateriteSoft`, `colors.bambouSoft`. Hex en dur : `'#e8780a'` (seuil "expire ≤30j", orange hors palette). Aucun dégradé.

**Icônes** : Ionicons. `time-outline`, `checkmark-circle`, `alert-circle`, `close-circle`, `image-outline`/`document-outline`, `chevron-forward`, `arrow-back`, `pencil-outline`, `close-outline`, `checkmark-outline`, `menu-outline`, `search-outline`, `checkmark-done-circle-outline`, `car-outline`.

**Images / visuels** : `<Image source={{ uri }}>` pour chaque document (CNI, permis, photos véhicule, carte grise, assurance) — URLs Supabase Storage dynamiques.

**Composants Atelier CAARCO utilisés** : `Plaquette` (identité), `Mereau` (avatar, "sm"/"md").

**Structure / layout** : Vue liste (en-tête + badge, recherche, `ScrollView` d'`ItemKYC`) et vue détail `PanneauDetail` (retour + temps d'attente, `Plaquette` identité, 3 boutons d'action, zone de motif conditionnelle, grille 2 colonnes `DocCard`, jauges de validité CNI/Permis).

---

## 44. LitigesScreen.js
`App/src/screens/admin/LitigesScreen.js`

**Rôle / accès** : Administrateur — résolution des litiges.
**Objectif de l'écran** : Lister les courses au statut "litige" et permettre à l'admin de trancher (valider la course ou l'annuler) avec un motif optionnel, en notifiant les deux parties.

**Textes affichés à l'écran** :
- "Litiges", "Décisions administratives" ; Cachet "LITIGE" ; "Traiter ce litige"
- Modal : "Décision du litige" ; "Client", "Transporteur" ; "Montant" ; "SIGNALEMENT DU CLIENT"
- "Motif de décision (optionnel)", placeholder "Ex : Le colis a été livré avec retard mais livré. Remboursement partiel refusé."
- "Annuler la course", "Valider la course"
- Vide : "Aucun litige en cours", "Toutes les courses sont résolues"

**Couleurs** : `colors.laterite`/`lateriteSoft` (Cachet danger, annuler, badge, signalement), `colors.bambou` (valider), `colors.foret` (chevron), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`, `colors.nere` (prix), `colors.bambouSoft` (icône vide). Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `swap-horizontal-outline` (entre avatars), `chevron-forward`, `close`, `close-circle-outline`, `checkmark-circle-outline`, `shield-checkmark-outline` (vide).

**Images / visuels** : Aucune image statique ; avatars via `Mereau` (initiales).

**Composants Atelier CAARCO utilisés** : `Plaquette` (`ItemLitige`), `Cachet` ("LITIGE", danger), `Mereau` ("xs"), `PanneauDroit`.

**Structure / layout** : En-tête (menu, titre/sous-titre, badge). Spinner / état vide / `ScrollView` de `Plaquette`. `ModalDecision` via `PanneauDroit` : récap course, deux parties, montant, signalement client, champ motif, deux boutons de décision.

---

## 45. TransporteursAdminScreen.js
`App/src/screens/admin/TransporteursAdminScreen.js`

**Rôle / accès** : Administrateur — gestion des transporteurs.
**Objectif de l'écran** : Lister tous les transporteurs, filtrer par statut KYC, rechercher, consulter un panneau détail avec statistiques et actions (créditer TC, suspendre/réactiver, remettre à zéro, supprimer le compte).

**Textes affichés à l'écran** :
- Filtres : "Tous", "Vérifiés", "En attente", "Non vérifiés"
- KYC : "Approuvé", "En attente", "Rejeté", "Incomplet"
- Détail : badge "Actif"/"Suspendu", "KYC vérifié" ; Stats : "Courses", "Note moy.", "Véhicule" ; "Inscrit le " + date
- Boutons : "Créditer TC (admin)", "Suspendre", "Réactiver", "Remettre à zéro", "Supprimer le compte"
- "Transporteurs", `` `${n} inscrits · ${m} vérifiés` `` ; recherche "Nom ou téléphone…" ; vide "Aucun transporteur trouvé"
- Alert reset : "Remettre à zéro", `` `Toutes les courses actives de ${nom} seront annulées.\n\nCette action est irréversible.` `` ; succès `` `${n} course(s) annulée(s) · portefeuille à 0 FCFA` ``
- Alert suppression : "Supprimer le compte", `` `Le compte de ${nom} (${tel}) sera définitivement supprimé.` `` ; succès "Compte supprimé"
- Modal crédit TC : "Créditer TC (admin)", placeholder "Montant TC", note "1 TC = 1 FCFA · crédité via RPC idempotent"

**Couleurs** : `KYC_COULEUR` (approuve→bambou, en_attente→nere, rejete→laterite, infos_manquantes→cendre), `colors.bambou`/`bambouSoft` (actif/vérifié), `colors.laterite`/`lateriteSoft` (suspendre/supprimer), `colors.foret` (avatar, confirmer crédit), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Pas de hex brut hors overlay modal `'rgba(0,0,0,0.55)'`. Aucun dégradé.

**Icônes** : Ionicons. `close`, `shield-checkmark`, `ticket-outline`, `ban-outline`, `checkmark-circle-outline`, `refresh-circle-outline`, `trash-outline`, `chevron-forward`, `menu-outline`, `search-outline`, `close-circle`.

**Images / visuels** : Aucune ; avatars via `Mereau`.

**Composants Atelier CAARCO utilisés** : `Plaquette` (`ItemTR`), `Mereau`, `PanneauDroit`.

**Structure / layout** : En-tête + recherche + pilules de filtre, `ScrollView` de `Plaquette` (avatar + point en ligne, nom + tag suspendu, téléphone, tag KYC + nb courses). `ModalDetail` via `PanneauDroit` : hero, stats, date, colonne d'actions. Modal séparé pour crédit TC.

---

## 46. ClientsAdminScreen.js
`App/src/screens/admin/ClientsAdminScreen.js`

**Rôle / accès** : Administrateur — gestion des clients.
**Objectif de l'écran** : Lister tous les clients (y compris anciens clients ayant changé de rôle), rechercher/filtrer par statut, consulter un détail avec statistiques, suspendre/réactiver/remettre à zéro/supprimer le compte.

**Textes affichés à l'écran** :
- Détail : "Inscrit le " + date ; Stats : "Courses", "Points", "XAF estimé"
- Boutons : "Suspendre", "Réactiver", "Remettre à zéro", "Supprimer le compte"
- "Clients", `` `${n} inscrits · +${m} aujourd'hui` `` ; KPI mini : "Total", "Actifs", "Suspendus", "Auj."
- Recherche "Rechercher un client…" ; Filtres "Tous", "Actifs", "Suspendus" ; vide "Aucun client trouvé"
- Alert reset / suppression : mêmes formulations que TransporteursAdminScreen adaptées au client

**Couleurs** : `colors.laterite`/`lateriteSoft` (suspendre/supprimer), `colors.bambou`/`bambouSoft` (réactiver), `colors.nere` (points, KPI "Auj."), `colors.foret` (spinner/refresh), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Le `StyleSheet` définit des styles non utilisés dans le rendu actuel (vestiges d'un ancien modal). Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `close`, `ban-outline`, `checkmark-circle-outline`, `refresh-circle-outline`, `trash-outline`, `chevron-forward`, `search-outline`, `close-circle`.

**Images / visuels** : Aucune ; avatars via `Mereau` (initiales).

**Composants Atelier CAARCO utilisés** : `Plaquette` (`ItemClient`), `Mereau`, `PanneauDroit`.

**Structure / layout** : En-tête + 4 KPI mini + recherche + pilules de filtre + `ScrollView` de `Plaquette`. `ModalDetail` via `PanneauDroit` avec statistiques et colonne d'actions.

---

## 47. UtilisateursScreen.js
`App/src/screens/admin/UtilisateursScreen.js`

**Rôle / accès** : Administrateur — liste plate de tous les utilisateurs (tous rôles confondus).
**Objectif de l'écran** : Fournir une vue simple, recherchable et filtrable par rôle de l'ensemble des comptes (clients + transporteurs), écran plus basique que les écrans dédiés Clients/Transporteurs.

**Textes affichés à l'écran** :
- Filtres : "Tous", "Clients", "Transporteurs"
- "Utilisateurs", `` `${n} au total` `` ; recherche "Rechercher par nom ou téléphone…"
- Item : "Inscrit le " + date ; vide "Aucun utilisateur trouvé"
- Badge rôle : "CLIENT", "TRANSPORTEUR", "ADMIN" (`role.toUpperCase()`)

**Couleurs** : `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : `Ionicons` importé mais **aucune icône n'est réellement rendue** dans ce fichier.

**Images / visuels** : Aucune ; avatar via `Mereau` (`photoUrl`).

**Composants Atelier CAARCO utilisés** : `Plaquette` (`ItemUtilisateur`), `Cachet` (badge rôle), `Mereau`, `Pastille` (pilules de filtre).

**Structure / layout** : En-tête (menu, titre, total), recherche, filtres `Pastille`, `ScrollView` de `Plaquette` (avatar + nom + badge rôle + téléphone + date). État vide et spinner.

---

## 48. FinancesAdminScreen.js
`App/src/screens/admin/FinancesAdminScreen.js`

**Rôle / accès** : Administrateur — synthèse financière du système de Tokens de Course.
**Objectif de l'écran** : Afficher les KPI financiers (commission TC, TC vendues via Notchpay, volume des courses, alertes de solde bas) et l'historique récent des achats/commissions.

**Textes affichés à l'écran** :
- Filtres période : "Auj.", "7 jours", "30 jours"
- "Finances", "Tokens de Course · Commissions"
- KPI : "Commission TC (20%)", "TC vendues (Notchpay)", "Volume courses", "TR solde bas (<1 000 TC)"
- "TR SOLDE INSUFFISANT" ; "Solde actuel"
- "ACHATS TC (NOTCHPAY)", "COMMISSIONS DÉDUITES"
- Vide : "Aucun achat sur cette période", "Aucune commission sur cette période"
- Labels : "Achat TC", "Commission"

**Couleurs** : `colors.bambou`/`bambouSoft` (achats), `colors.nere`/`nereSoft` (commission), `colors.foret` (volume), `colors.laterite`/`lateriteSoft` (alerte solde bas), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `refresh-outline`, `ticket-outline`, `arrow-down-circle-outline`, `trending-up-outline`, `warning-outline`/`warning`, `arrow-up-circle-outline`.

**Images / visuels** : Aucune ; `Mereau` pour l'avatar des TR en alerte.

**Composants Atelier CAARCO utilisés** : `Plaquette` (KPI, alerte, listes), `Mereau`.

**Structure / layout** : ScrollView pull-to-refresh. En-tête (menu/rafraîchir), pilules de période, grille KPI 2×2, bloc d'alerte TR solde bas conditionnel, liste des achats TC récents, liste des commissions déduites récentes.

---

## 49. RetraitsAdminScreen.js
`App/src/screens/admin/RetraitsAdminScreen.js`

**Rôle / accès** : Administrateur — administration des Tokens de Course (renommé depuis un ancien écran "retraits", devenu obsolète car il n'existe pas de retrait dans le système TC).
**Objectif de l'écran** : Consulter l'historique des transactions TC (achats, commissions) et les soldes TC des transporteurs, via des onglets.

**Textes affichés à l'écran** :
- Onglets : "Achats TC", "Commissions", "Soldes TR"
- "Tokens de Course", "1 TC = 1 FCFA · Notchpay"
- Résumé : "Vendus", "Commissions", "En alerte"
- Statuts : "Confirmé", "En attente", "Échoué" ; "Solde insuffisant"
- Vide : "Aucune transaction", "Aucun transporteur KYC validé"
- `` `${n} TR avec solde < 1 000 TC` ``

**Couleurs** : `colors.bambou`/`bambouSoft` (achats/confirmé), `colors.nere`/`nereSoft` (commissions/en attente), `colors.laterite`/`lateriteSoft` (échoué/alerte), `colors.brume` (badge par défaut), `colors.cendre`, `colors.foret` (onglet actif), `colors.charbon`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `refresh-outline`, `arrow-down-circle-outline`, `arrow-up-circle-outline`, `ticket-outline`, `people-outline`, `warning`.

**Images / visuels** : Aucune ; `Mereau` pour les avatars TR (soldes).

**Composants Atelier CAARCO utilisés** : `Mereau`, `Plaquette`.

**Structure / layout** : En-tête (menu, titre/sous-titre, rafraîchir), rangée de résumé (3 cartes), onglets (3, badge sur "Soldes TR"), `ScrollView` pull-to-refresh de transactions ou soldes selon l'onglet, bandeau d'alerte conditionnel.

---

## 50. MarketingAdminScreen.js
`App/src/screens/admin/MarketingAdminScreen.js`

**Rôle / accès** : Administrateur — configuration marketing (packs d'abonnement et codes promo).
**Objectif de l'écran** : Activer/désactiver des packs d'abonnement et créer/désactiver des codes de réduction promotionnels.

**Textes affichés à l'écran** :
- Modal création : "Nouveau code promo" ; "Code" (placeholder "EX: CAARCO50"), "Réduction (XAF)" (placeholder "500"), "Utilisations max (laisser vide = illimité)" (placeholder "100"), "Durée de validité"
- Durées : "30 jours", "90 jours", "6 mois", "1 an" ; bouton "Création…"/"Créer le code"
- Pack : "Actif"/"Inactif", `` `${n} jours` ``
- Code : "Expiré"/"Actif"/"Inactif" ; `` `-${n} XAF` `` ; `` `${n} utilisation(s)${max ? ' / ' + max : ''}` ``
- "Marketing", "Packs et codes promotionnels" ; sections "PACKS ABONNEMENT", "CODES PROMOTIONNELS" ; "Nouveau"
- Vide : "Aucun pack configuré", "Aucun code créé"

**Couleurs** : `colors.bambou`/`brume` (switch actif/inactif), `colors.cendre` (inactif), `colors.nere` (montant réduction), `colors.foret` (boutons "Nouveau"/créer), `colors.laterite` (désactiver), `colors.charbon`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `close`, `add`, `close-circle-outline`.

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Plaquette` (`CartePack`, liste des codes), `PanneauDroit` (formulaire).

**Structure / layout** : ScrollView pull-to-refresh. Section "PACKS ABONNEMENT" (cartes `Plaquette` : nom, description, prix, durée, switch). Section "CODES PROMOTIONNELS" (bouton "Nouveau" → formulaire `PanneauDroit`, liste `Plaquette` de codes avec stats d'utilisation et bouton désactiver).

---

## 51. CoursesEnCoursAdminScreen.js
`App/src/screens/admin/CoursesEnCoursAdminScreen.js`

**Rôle / accès** : Administrateur — gestion complète des courses (temps réel).
**Objectif de l'écran** : Parcourir/rechercher/filtrer toutes les courses tous statuts confondus (y compris planifiées), consulter le détail avec timeline, assigner/désassigner un transporteur pour les courses planifiées.

**Textes affichés à l'écran** :
- Onglets : "Tout", "En attente", "Acceptée", "En cours", "Livrée", "Litige", "Annulée", "Planifiées"
- Statuts : "En attente", "Acceptée", "En cours", "Livrée" (×2), "Litige", "Annulée", "Programmée", "TR Assigné"
- Timeline : "Créée", "Acceptée", "En cours", "Livrée" ; durée "à l'instant", "{n} min", "{h}h{mm}", "{n}j"
- Carte : `` `#${id8}` ``, `` `${km} km est.` ``, `` `${km} km réel` ``, `` `${prix} XAF` ``
- Date planifiée : `` `${date} à ${heure}` `` ; annulée : `` `Course annulée · ${date}` ``
- Sections détail : "TRAJET", "CLIENT", "TRANSPORTEUR", "DATE PLANIFIÉE", "ATTRIBUTION"
- Adresses : "Collecte", "Livraison", "Non renseigné"
- Pastilles : distance estimée/réelle, type de véhicule, "Espèces"/"Mobile Money"
- "Montant total", "Commission CAARCO"
- Boutons : "Assigner un transporteur", "Désassigner le transporteur" ; "Raison du litige"
- "Courses", `` `${n} au total · temps réel` ``, "LIVE" ; recherche "ID, adresse, client, transporteur…"
- Vide : "Aucun résultat pour cette recherche" / "Aucune course dans cette catégorie"
- Modal assignation : "Assigner un transporteur", placeholder "Nom du transporteur…", vide "Aucun transporteur disponible" ; item TR `` `${véhicule} · ★ ${note}` ``
- Alert assigner/désassigner : "Assigner ce transporteur ?" / "Désassigner le transporteur ?" avec messages associés
- Notification push (contenu serveur) : "📅 Course planifiée assignée", "Une course planifiée vous a été assignée. Préparez-vous !"

**Couleurs** : `COULEUR_STATUT` (nere/bambou/foret/bambou/bambou/laterite/cendre/nere/bambou), `colors.foret` (timeline actif), `colors.bambou` (timeline fait, assigner), `colors.laterite`/`lateriteSoft` (litige, désassigner, annulée), `colors.nere`/`nereSoft` (prix, badge planifié), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `search-outline`, `close-circle`, `calendar-outline`, `person-outline`, `close`, `checkmark`, `close-circle-outline`, `footsteps-outline` (distance réelle), `navigate-circle-outline` (distance estimée), `cash-outline`/`card-outline`, `star`, `warning-outline`, `calendar`, `person-add-outline`, `person-remove-outline`. Emojis : `EMOJI_VEHICULE` (🏍🚗🚐🛺🚛).

**Images / visuels** : Aucune image statique ; `Mereau` pour client/transporteur.

**Composants Atelier CAARCO utilisés** : `Mereau`, `PanneauDroit` (`FeuilleDetail`).

**Structure / layout** : En-tête avec recherche + 8 onglets scrollables (compteurs). `FlatList` de `CarteCourse` (bordure gauche colorée par statut, adresses, date planifiée optionnelle, pied client/TR + prix/distance). `FeuilleDetail` via `PanneauDroit` : timeline 4 étapes ou bandeau annulée, trajet, prix, sections client/transporteur, litige conditionnel, attribution (assigner/désassigner). Modal bottom-sheet de recherche/assignation TR.

---

## 52. ConfigTarifsScreen.js
`App/src/screens/admin/ConfigTarifsScreen.js`

**Rôle / accès** : Administrateur — configuration des tarifs (écran "Paramètres").
**Objectif de l'écran** : Configurer les tarifs par type de véhicule (prix/km, frais fixes, poids/volume max), le taux de commission de parrainage, la majoration nocturne, consulter les paramètres fixes non modifiables, et exécuter une remise à zéro complète des données de test (zone danger) confirmée par mot de passe.

**Textes affichés à l'écran** :
- "Paramètres", bouton "Enregistrer"
- Véhicules : "Moto", "Voiture", "Tricycle / Camionnette", "Camion"
- Paramètres fixes : "Commission CAARCO" → "20 %" ; "Part nette transporteur" → "80 %" ; "Supplément poids" → "50 XAF / kg" ; "Supplément volume" → "500 XAF / m³" ; "Arrondi final" → "Centaine supérieure (100 FCFA)"
- Sections : "TARIFS PAR TYPE DE VÉHICULE", "COMMISSION PARRAINAGE", "TARIFICATION DE NUIT", "PARAMÈTRES FIXES (NON MODIFIABLES EN V1)"
- Champs véhicule : "Tarif / km", "Prise en charge (fixe)", "CHARGE UTILE", "Poids max", "Volume max" ; badge "Modifié"
- Commission : "Part reversée au parrain", "Pourcentage de la commission CAARCO (20 %) versé au parrain à chaque course terminée.", "Taux de commission" (placeholder "10")
- Nuit : "Majoration horaire", "Début (h)" (placeholder "20"), "Fin (h)" (placeholder "5"), "Majoration" (placeholder "20")
- Note bas de page : "La formule appliquée est : (Frais fixes + Distance × Tarif km + Suppléments) arrondi à la centaine supérieure."
- Zone danger : "ZONE DANGER", "Remise à zéro totale", "Efface courses, tokens TC, messages, commissions et historiques de tous les comptes.\nLes comptes sont conservés.", "Réinitialiser"
- Modal reset : "⚠️ Remise à zéro totale", texte détaillé, "Entrez votre mot de passe admin pour confirmer", "Annuler", "Tout effacer"
- Divers messages d'erreur/succès de validation par champ

**Couleurs** : `colors.foret`/`foret10` (icônes véhicule, bouton enregistrer), `colors.nere`/`nereSoft` (badge "Modifié", icône commission), `colors.bambou` (enregistrer commission/nuit), `colors.laterite`/`lateriteSoft` (zone danger), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `bicycle-outline`/`car-outline`/`cube-outline`/`bus-outline`, `people-outline`, `moon-outline`, `warning`, `nuclear-outline`.

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Plaquette` (cartes véhicule, commission, nuit, paramètres fixes), `Bandeau`.

**Structure / layout** : En-tête + bouton enregistrer, `Bandeau`, ScrollView : cartes par véhicule, carte commission, carte nuit, carte paramètres fixes (lecture seule), note explicative, carte "zone danger". Modal centré de confirmation par mot de passe pour la remise à zéro.

---

## 53. CampagnesPushScreen.js
`App/src/screens/admin/CampagnesPushScreen.js`

**Rôle / accès** : Administrateur — gestion des campagnes de notifications push.
**Objectif de l'écran** : Créer, éditer, envoyer ou planifier (y compris en récurrence) des campagnes push avec ciblage/segmentation d'audience, consulter la liste des campagnes et leur statut, les arrêter/renvoyer/supprimer.

**Textes affichés à l'écran** :
- Cibles : "Tous", "Clients", "Transporteurs", "Inactifs 7+ j"
- Types : "Alerte", "Marketing", "Saisonnier", "Annonce", "Rappel"
- Récurrences : "Une seule fois", "Chaque lundi", "Chaque vendredi", "Chaque jour", "Personnalisé…"
- Villes (VILLES_CM) : Yaoundé, Douala, Bafoussam, Garoua, Bamenda, Ngaoundéré, Bertoua, Ebolowa, Kribi, Limbé
- Segmentation : "Sexe", "Ancienneté", "Ville", "Note moyenne" ; ancienneté "< 30 jours", "1 à 6 mois", "> 6 mois" ; score "★ Excellent (≥ 4.5)", "★ Bon (3–4.5)", "★ Faible (< 3)"
- Filtres avancés : "Score notation", "Nom", "Ville", "Sexe", "Statut", "Date inscription" ; opérateurs "=", "!=", ">", ">=", "<", "<=", "contient"
- Statuts : "Brouillon", "Planifié", "Envoyé", "Échec", "Arrêté"
- Formulaire : "Titre interne (optionnel)", "Message *" (compteur, max 120), "Cible *", "🎯 Segmentation activée"/"Affiner la cible", "Type *", bascule "Maintenant"/"Programmer", "Récurrence", "Heure d'envoi", "Date et heure", "Aperçu"
- Toasts et alertes de confirmation d'arrêt/suppression

**Couleurs** : `TYPES` (laterite/bambou/nere/foret/cendre), `STATUT_COULEUR` (cendre/nere/bambou/laterite/laterite), `colors.foret` (segmentation active, chip actif), `colors.bambou` ("Programmer" actif, renvoyer), `colors.nere` (chip opérateur actif), `colors.laterite` (arrêter, astérisque, suppression filtre), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Rgba : `'rgba(0,0,0,0.45)'` (voile calendrier custom). Aucun dégradé.

**Icônes** : Ionicons. Icônes de cible (`people`, `person`, `car`, `time`), de type (`warning`, `megaphone`, `gift`, `newspaper`, `notifications`), de récurrence (`send-outline`, `calendar-outline`, `repeat-outline`, `options-outline`), navigation calendrier (`chevron-back`/`chevron-forward`/`chevron-up`/`chevron-down`), `arrow-forward`/`checkmark`, `close`, `create-outline`, `stop-circle-outline`, `refresh`/`send`, `trash-outline`, `add`, `options`/`options-outline`, `close-circle`, `phone-portrait-outline`. Emojis : 🌅 (lundi matin), 🎉 (vendredi soir), 📅, ⚙️, 🎯.

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Bandeau` (toasts), `PanneauDroit` (formulaire de campagne).

**Structure / layout** : En-tête (retour/menu, titre, "Nouvelle"). `FlatList` de cartes campagne. Formulaire via `PanneauDroit` : titre, message avec compteur, cible en chips, panneau de segmentation dépliable, sélecteur de type, bascule Maintenant/Programmer, récurrence ou calendrier personnalisé interne, aperçu en direct, boutons annuler/envoyer.

---

## 54. NotificationsAdminScreen.js
`App/src/screens/admin/NotificationsAdminScreen.js`

**Rôle / accès** : Administrateur — éditeur de templates de notifications.
**Objectif de l'écran** : Parcourir et modifier les modèles de messages de notification groupés par catégorie, avec prévisualisation par substitution de variables d'exemple avant sauvegarde.

**Textes affichés à l'écran** :
- Groupes : "Courses, Client", "Courses, Transporteur", "Vérification KYC", "Fidélité & Classement", "Finance & TC", "Litiges", "Général"
- "Notifications", `` `${n} templates · personnalisables` ``
- Carte : clé, description, badge "OFF" si inactif, titre, corps, chips de variables
- Onglets modal : "Édition", "Aperçu"
- "Variables disponibles", "Titre de la notification" (compteur /100), "Corps du message" (compteur /300)
- "Prévisualisation avec valeurs d'exemple" ; "Annuler", "Sauvegarder"

**Couleurs** : Groupes (`colors.bambou`, `colors.foret`, `colors.nere`, `'#8B6914'`, `'#2e7d32'`, `colors.laterite`, `colors.cendre`), `colors.foret` (accents, onglet actif), `colors.laterite`/`lateriteSoft` (badge OFF), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Hex en dur : `'#8B6914'` (groupe Fidélité), `'#2e7d32'` (groupe Finance), `'#edf3ef'` (fallback fond chips). Aucun dégradé.

**Icônes** : Ionicons. Icônes de groupe dynamiques (`person`, `car`, `id-card`, `trophy`, `cash`, `warning`, `notifications`), `menu`, `pencil-outline`, `close`, `notifications` (aperçu).

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Bandeau`, `PanneauDroit`.

**Structure / layout** : En-tête (menu, titre/sous-titre). ScrollView pull-to-refresh, sections groupées par catégorie, cartes template. Modal d'édition via `PanneauDroit` : onglets Édition/Aperçu (variables + champs + compteurs / bulle de notification simulée), boutons annuler/sauvegarder.

---

## 55. OperationsAdminScreen.js
`App/src/screens/admin/OperationsAdminScreen.js`

**Rôle / accès** : Administrateur — carte des opérations en temps réel (supervision de la flotte).
**Objectif de l'écran** : Visualiser en temps réel sur une carte les transporteurs en ligne et les courses actives (en attente/acceptée/en cours/litige), avec recherche, pastilles de statistiques, et panneaux d'information sur sélection.

**Textes affichés à l'écran** :
- Statuts : "En attente", "Acceptée", "En cours", "Litige"
- "Opérations", badge "LIVE" ; pastilles : "TR en ligne", "Courses actives", "En livraison", "En attente"
- Recherche : placeholder "Rechercher TR, adresse…" ; "Recentrer"
- Panneau TR : label véhicule dynamique, "Disponible, aucune course active"
- Légende : "TR en ligne", "Collecte", "Livraison" ; "Chargement des opérations…"
- Titre liste : `` `COURSES (${filtrées}/${total})` `` ou `` `ACTIVES (${total})` `` ; "Tout afficher"
- Vide : "Aucun transporteur en ligne", "Les opérations apparaîtront ici en temps réel"

**Couleurs** : `COULEUR_STATUT` (nere/bambou/foret/laterite), `colors.bambou` (collecte, pastille TR), `colors.nere` (livraison, note), `colors.foret` (marqueur TR par défaut), `colors.laterite` (pastille "en attente"), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Hex en dur (rgba translucides sur manioc) : `'rgba(251,249,243,0.96)'`/`0.92`/`0.97` (en-tête, légende, panneaux flottants). Aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `refresh-outline`, `car-outline`, `cube-outline`, `navigate-outline`, `time-outline`, `search-outline`/`close-circle`, `locate`, `star`, `navigate-circle-outline`. Emojis : `EMOJI_VEH` (🏍🚗🚐🛺🚛), 📦 (collecte), 🏠 (livraison).

**Images / visuels** : `CarteLeaflet` (carte OSM WebView plein écran, marqueurs et polylignes dynamiques).

**Composants Atelier CAARCO utilisés** : `CarteLeaflet`.

**Structure / layout** : Carte plein écran en fond avec overlays : en-tête (menu, titre, LIVE, rafraîchir), pastilles de stats en scroll horizontal, recherche, "Recentrer" conditionnel, panneau TR flottant sur sélection, légende, liste horizontale de `MiniCourse`, overlays de chargement/vide. Polling positions 5s + realtime + nettoyage TR fantômes toutes les 5 min.

---

## 56. PublicitesAdmin.js
`App/src/screens/admin/PublicitesAdmin.js`

**Rôle / accès** : Administrateur — gestion des publicités in-app.
**Objectif de l'écran** : Gérer les bannières publicitaires affichées en carrousel dans l'application (upload d'image, lien, date d'expiration, ordre, activation, suppression).

**Textes affichés à l'écran** :
- "Publicités in-app", "Ajouter" ; vide "Aucune publicité, appuyez sur Ajouter"
- Méta carte : `` `Ordre ${n}` `` + `` ` · Expire ${date}` `` ou "Permanent"
- Alert suppression : "Supprimer la publicité", `` `Supprimer "${titre}" définitivement ?` ``
- Modal ajout : "Nouvelle publicité" ; placeholder image "Appuyer pour choisir une image", "Format recommandé : 1024 × 500 px"
- Champs : "Titre (usage interne) *", "Lien au clic (optionnel)", "Date de fin (laisser vide = permanent)", "Ordre dans le carousel (0 = premier)"
- "Publier la bannière"

**Couleurs** : `colors.foret`/`foret10` (bouton principal), `colors.laterite` (supprimer, erreur), `colors.bambou` (switch actif), `colors.brume` (bordures, miniature, switch inactif), `colors.cendre`, `colors.charbon`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. `menu-outline`/`arrow-back`, `add`, `image-outline`, `trash-outline`, `close`.

**Images / visuels** : `<Image source={{ uri: pub.image_url }}>` (miniatures), `<Image source={{ uri: imageUri }}>` (aperçu formulaire). Upload via `expo-image-picker` vers Supabase Storage (natif via `expo-file-system`, web via Edge Function `upload-publicite`).

**Composants Atelier CAARCO utilisés** : `PanneauDroit` (formulaire).

**Structure / layout** : En-tête (retour/menu, titre, "Ajouter"). ScrollView de cartes bannière (miniature, titre, méta, switch, supprimer) ou état vide. Formulaire `PanneauDroit` : zone d'image, champs titre/lien/date/ordre, bouton de soumission.

---

## 57. LieuxAdminScreen.js
`App/src/screens/admin/LieuxAdminScreen.js`

**Rôle / accès** : Administrateur — validation des lieux proposés par les utilisateurs.
**Objectif de l'écran** : Examiner et approuver/rejeter les points d'intérêt (lieux) proposés par les clients/transporteurs pour le système de carte/géocodage.

**Textes affichés à l'écran** :
- "Lieux en attente", `` `${n} lieu(x) à valider` ``
- Méta : `` `${categorie} · ${ville}` `` ; coordonnées (5 décimales) ; `` `Proposé par ${nom} (${role})` ``
- Boutons : "Rejeter", "Valider" ; vide "Aucun lieu en attente"

**Couleurs** : `colors.bambou`/`bambouSoft` (valider), `colors.laterite` (rejeter), `colors.cendre`, `colors.charbon`, `colors.brume`, `colors.manioc`, `colors.blanc`. Aucun hex en dur, aucun dégradé.

**Icônes** : Ionicons. Icônes par catégorie (`CATEGORIES_ICONE`) : `storefront-outline` (Marché), `school-outline` (École), `medical-outline` (Hôpital), `home-outline` (Mosquée/Église), `map-outline` (Quartier), `git-merge-outline` (Carrefour), `flame-outline` (Station essence), `bed-outline` (Hôtel), `bandage-outline` (Pharmacie), `construct-outline` (Atelier/Garage), `location-outline` (Autre) ; `close-circle-outline`, `checkmark-circle-outline`, `checkmark-done-circle-outline` (vide).

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : Aucun (cartes brutes `View`/`Text`/`TouchableOpacity`).

**Structure / layout** : En-tête. `FlatList` de cartes de lieu (icône catégorie, nom, méta, coordonnées, proposant, boutons rejeter/valider). État de chargement et état vide.

---

## 58. CalendrierActionsScreen.js
`App/src/screens/admin/CalendrierActionsScreen.js`

**Rôle / accès** : Administrateur — calendrier marketing agrégé.
**Objectif de l'écran** : Visualiser sur un calendrier mensuel les événements marketing (publicités, campagnes push, codes promo) par jour, avec filtres, panneau de détail du jour sélectionné, et raccourcis FAB pour créer de nouveaux éléments.

**Textes affichés à l'écran** :
- Types : "Publicités", "Campagnes", "Codes promo" ; options FAB : "Nouvelle pub", "Nouvelle campagne", "Nouveau code promo"
- "Calendrier marketing" ; titre navigation (mois + année) ; titre panneau jour (date complète)
- Vide jour : "Aucune action ce jour"
- Items : titre publicité fallback "Publicité" (sous-texte expiration/"Permanent") ; campagne fallback "Campagne" ; code promo fallback "Code promo" (`` `−${n} FCFA` ``) ; `` `Expiration : ${code}` ``

**Couleurs** : `TYPES` (nere/nereSoft publicités, bambou/bambouSoft campagnes, laterite/lateriteSoft codes promo), `colors.foret` (navigation, jour sélectionné), `colors.nereSoft`/`colors.nere` (jour "aujourd'hui"), `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.manioc`, `colors.blanc`. Hex en dur : `'rgba(15,20,17,0.35)'` (voile du FAB). Aucun dégradé.

**Icônes** : Ionicons. `menu-outline`, `chevron-back`/`chevron-forward`, icônes de type (`images-outline`, `megaphone-outline`, `pricetag-outline`), `calendar-outline` (jour vide), `close`/`add` (FAB).

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : Aucun (calendrier construit avec des `View` brutes).

**Structure / layout** : En-tête, ScrollView : navigation de mois, pilules de filtre (3 types), grille de calendrier (points colorés par type d'événement), résumé mensuel par type, panneau de détail du jour sélectionné. FAB en bas à droite se déployant en 3 sous-boutons vers Publicités/Campagnes/Marketing.

---

# ÉCRANS PARTAGÉS (9 écrans)

## 59. ProfilScreen.js
`App/src/screens/ProfilScreen.js`

**Rôle / accès** : Utilisateur authentifié (client ou transporteur) ; certaines sections varient selon le rôle (véhicule/KYC/stats pour transporteur, bannière fidélité pour client).
**Objectif de l'écran** : Écran central de gestion du compte — consultation/édition des informations personnelles, préférences (langue, notifications, thème, navigation, sonnerie), changement de rôle, sécurité (mot de passe, déconnexion, suppression de compte), assistance et programme de fidélité.

**Textes affichés à l'écran** (dont plusieurs via i18n) :
- "Mon profil" ; "Modifier"/"Annuler" ; "Informations personnelles" ; "Historique des courses"/"Trajets récents et passés"
- "Code de parrainage" ; "Nom complet"/"Votre nom", "Pseudo (optionnel)"/"@votre_pseudo", "Numéro de téléphone"/"6XXXXXXXX"
- "Modifier le numéro changera votre identifiant de connexion."
- "GENRE", "Homme", "Femme" ; "DATE DE NAISSANCE" ; "VILLE"
- "TYPE DE VÉHICULE" (édition TR), "Mon véhicule"/"Non renseigné" (lecture)
- "Dossier KYC" ; "Statistiques"/"Performances, notes et distances"
- "Enregistrer les modifications"
- "PRÉFÉRENCES" : "Langue", "Notifications", "Mode sombre", "Application de navigation" (TR), "Sonnerie d'alarme" (TR)
- "MODE" : "Passer en mode Client", "Passer en mode Transporteur", "Mode actuel : {roleLabel}"
- "SÉCURITÉ" : "Modifier le mot de passe", "Se déconnecter", "Supprimer mon compte"
- "ASSISTANCE" : "Discuter sur WhatsApp"
- "CAARCO · v1.0.0 · Cameroun" ; "Conditions d'utilisation" / "Confidentialité"
- Modal suppression : "Supprimer mon compte" ; "Cette action est irréversible. Toutes vos données (courses, historique) seront supprimées.\n\nÊtes-vous sûr de vouloir continuer ?" ; "Oui, supprimer"
- Modal fidélité : "Programme de fidélité" ; niveaux "Explorateur", "Habitué", "Ambassadeur", "Légende" avec plages de courses ; avantages listés par niveau (accès complet, support standard/prioritaire, badge visible, priorité matching, offres partenaires, conciergerie, accès bêta)
- Bannière fidélité (client) : `{niveau.label}`, `` `${nbCourses} course${s} · Voir mes avantages` ``
- Toasts : erreurs nom/téléphone vides, "Numéro mis à jour. Reconnectez-vous avec le nouveau numéro.", "Profil mis à jour avec succès ✓", "Ce numéro est déjà utilisé par un autre compte.", "Impossible de sauvegarder. Vérifiez votre connexion.", erreurs de déconnexion/suppression
- `Alert.alert` : "Photo de profil"/"Choisir la source" ("Caméra"/"Galerie"/"Annuler") ; permissions caméra/galerie refusées

**Couleurs** : `colors.foret` (fond `safe`, icônes actives, MODE), `colors.blanc`, `colors.manioc`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.foret30` (icônes inactives), `colors.foret70`, `colors.foret90` (fond bannière fidélité), `colors.nere` (niveau fidélité, bouton sauvegarder), `colors.nereSoft` (ligne niveau actif modal), `colors.bambou`/`bambouSoft` (chips véhicule), `colors.laterite` (déconnexion, suppression). Rgba en dur : `'rgba(31,59,42,0.08)'` (bulles d'icône menu), `'rgba(200,148,65,0.18)'` (icône MODE), `'rgba(184,97,46,0.18)'`/`'0.1'` (icônes déconnexion/suppression), `'rgba(37,211,102,0.12)'` + `'#25D166'` (icône WhatsApp), `'rgba(255,255,255,0.1)'`/`'0.2'` (bouton modifier, bordure avatar), `'rgba(0,0,0,0.45)'` (overlay avatar édition), `'rgba(200,148,65,0.3)'`/`'0.15'` (bordure/fond bannière fidélité). Ombre `sectionBloc` construite manuellement plutôt qu'un token `shadow.*`.

**Icônes** : Ionicons. `moon`/`sunny-outline` (thème), `pencil-outline`, `person-outline`, `at-outline`, `call-outline`, `male-outline`/`female-outline`, `calendar-outline`, `close-circle`, `location-outline`, `gift-outline`, `eye-outline`/`eye-off-outline` (code parrainage), `bicycle-outline`/`car-outline`/`cube-outline`/`bus-outline`, `chevron-up`/`chevron-down`/`chevron-forward`, `id-card-outline`, `bar-chart-outline`, `language-outline`, `notifications-outline`, `navigate-outline`, `musical-notes-outline`, `checkmark`, `lock-closed-outline`, `log-out-outline`, `trash-outline`, `logo-whatsapp`, `camera`, `checkmark-circle`, `ellipse-outline`. Emojis (niveaux fidélité) : 🌱 (Explorateur), 🌿 (Habitué), 🌳 (Ambassadeur), 🦁 (Légende).

**Images / visuels** : `<Image source={{ uri: photoAffichee }}>` (photo de profil via `ImagePicker` local ou `profil.photo_url`), sinon `Mereau` (avatar généré). Upload vers Supabase Storage bucket `avatars`.

**Composants Atelier CAARCO utilisés** : `Mereau`, `BadgeVerifie`, `Sillon`, `Cachet` (badge de rôle), `Bascule`, `Bandeau`, `Alcove` (modals suppression + fidélité), `TutorielPopup`, `CalendrierNaissance`, `SelecteurVille`.

**Structure / layout** : Header (titre, toggle thème, modifier/annuler). `Bandeau` toast. ScrollView : hero avatar + nom + pseudo + badge rôle, bannière fidélité (clients), section "MON COMPTE" (formulaire d'édition inline ou liste de menu, incluant véhicule/KYC/stats pour TR), bouton "Enregistrer" (mode édition), section "PRÉFÉRENCES", section "MODE", section "SÉCURITÉ", section "ASSISTANCE", footer (version + liens légaux). Deux modals `Alcove` (suppression, détail fidélité avec barre de progression) et un `TutorielPopup`.

---

## 60. ProfilPublicScreen.js
`App/src/screens/ProfilPublicScreen.js`

**Rôle / accès** : Utilisateur authentifié consultant le profil public d'un autre utilisateur (client consultant son transporteur ou inversement).
**Objectif de l'écran** : Afficher les informations publiques d'un contact (note, nombre de courses, véhicule si transporteur, avis reçus) et permettre de le contacter (chat, appel, visio).

**Textes affichés à l'écran** :
- "Profil" (chargement/erreur) ; "Profil transporteur"/"Profil client" ; "Profil introuvable"
- "VÉHICULE" ; `` `${note} sur 5` `` ; `` `${n} course${s} effectuée${s}/passée${s}` `` ; `@${pseudo}`
- "AVIS RÉCENTS" (si présents) ; "Utilisateur" (fallback auteur) ; "Contacter"
- Nom du véhicule capitalisé dynamiquement

**Couleurs** : `colors.manioc`, `colors.foret` (icônes, bouton Contacter, bordures), `colors.foret10`, `colors.charbon`, `colors.cendre`, `colors.brume` (statut hors ligne), `colors.bambou` (statut en ligne), `colors.nere` (étoiles), `colors.blanc`. Hex en dur : `'#25D366'` (bordure bouton visio, vert WhatsApp).

**Icônes** : Ionicons. `arrow-back`, `star`/`star-half`/`star-outline`, `bicycle-outline`/`car-outline`/`car-sport-outline`/`bus-outline`, `chatbubble-outline`, `call-outline`, `videocam-outline`.

**Images / visuels** : `Mereau` (photo ou initiales générées).

**Composants Atelier CAARCO utilisés** : `Mereau`, `Plaquette`, `BadgeVerifie`.

**Structure / layout** : Header fixe (retour + titre dynamique). Chargement / profil introuvable / contenu complet (hero avatar + statut + nom + pseudo + badge + étoiles + nb courses, bloc véhicule si TR, avis récents). Pied fixe : bouton "Contacter" pleine largeur + boutons ronds appel/visio (si téléphone renseigné).

---

## 61. MerciScreen.js
`App/src/screens/MerciScreen.js`

**Rôle / accès** : Client (après paiement confirmé) ou transporteur (après livraison), écran de fin de course.
**Objectif de l'écran** : Remercier l'utilisateur, afficher le montant gagné (transporteur), permettre la notation de l'autre partie (étoiles globales + critères détaillés pour le client), proposer le téléchargement du reçu PDF (client) et célébrer les jalons de fidélité/streaks.

**Textes affichés à l'écran** :
- Critères (client) : "Ponctualité", "Soin du colis", "Communication", "Propreté véhicule"
- Modal jalon : "Surprise !", `` `Vous atteignez ${n} courses` ``, "Super, merci !"
- Bannière streak : "Streak de la semaine !", "3 courses cette semaine, +100 XAF crédités sur votre wallet"
- "Merci pour votre confiance !" (client) / "Course livrée avec succès !" (TR)
- "Votre colis a bien été livré. Notez votre expérience ci-dessous." / "Bravo ! Votre client a reçu son colis."
- "MONTANT GAGNÉ" (TR) ; `` `${montant} XAF` ``
- "Votre transporteur" / "Votre client" ; note texte : "Excellent !"/"Très bien"/"Correct"/"Décevant"/"Mauvais"
- "Commentaire (optionnel)" ; placeholder "Décrivez votre expérience…" ; compteur `{n}/500`
- "Envoyer mon avis" ; "Télécharger le reçu PDF"/"Génération…" (client) ; "Continuer à conduire" (TR)/"Passer" (client)

**Couleurs** : `colors.bambou` (icône succès), `colors.nereSoft` (fond cercle icône), `colors.charbon`, `colors.cendre`, `colors.foret` (fond bloc montant, bouton envoyer), `colors.bambouSoft` (label montant, fond bouton reçu), `colors.blanc`, `colors.nere` (note, reçu), `colors.brume`, `colors.foret10`, `colors.manioc`. Ombres `shadow.futaie`/`shadow.voilage`, aucun hex en dur.

**Icônes** : Ionicons. `checkmark-circle` (client) / `trophy-outline` (TR), `star`/`star-outline`, `time-outline` (ponctualité), `cube-outline` (soin colis), `chatbubble-outline` (communication), `sparkles-outline` (propreté), `download-outline` (reçu), `arrow-forward` (continuer), `gift-outline` (jalon). Emojis : 🎁 (jalon), 🔥 (streak).

**Images / visuels** : Avatar de la cible via `Mereau` (nom uniquement).

**Composants Atelier CAARCO utilisés** : `Mereau`, `Bandeau`.

**Structure / layout** : `Bandeau` d'erreur ; `Modal` transparent animé pour le jalon surprise. ScrollView : bannière streak conditionnelle, illustration succès, bloc montant (TR), bloc "cible" (avatar+nom+rôle+étoiles+note texte), critères détaillés (client), champ commentaire. Pied fixe : "Envoyer mon avis", bouton reçu PDF conditionnel (client), "Passer"/"Continuer à conduire".

---

## 62. EcranMaintenance.js
`App/src/screens/EcranMaintenance.js`

**Rôle / accès** : Tous les utilisateurs (clients et transporteurs), écran bloquant plein écran affiché dès que l'administrateur active le mode maintenance ; l'admin conserve son accès normal.
**Objectif de l'écran** : Bloquer totalement l'application pendant la maintenance, sans aucune navigation possible, en rassurant l'utilisateur sur la sécurité de ses données.

**Textes affichés à l'écran** :
- Message par défaut : "L'application est temporairement indisponible.\nNous revenons très vite." (si prop `message` non fournie)
- "Application indisponible"
- "Toutes vos données sont en sécurité.\nL'accès sera rétabli sans délai dès que possible."
- "CAARCO" (logo texte) ; "Transport sécurisé au Cameroun"
- `message` (prop dynamique optionnelle passée par l'admin)

**Couleurs** : `colors.nuit` (fond), `colors.laterite` (icône bouclier, bordure gauche du bloc message), `colors.blanc`, `colors.cendre`, `colors.foret30` (logo footer). Concaténations token+alpha : `colors.lateriteSoft + '20'`, `colors.laterite + '40'`, `colors.foret + '30'`, `colors.cendre + '40'`, `colors.cendre + '80'`.

**Icônes** : Ionicons. `shield-outline` (pulsation en boucle), `time-outline` (séparateur décoratif).

**Images / visuels** : Aucune (le composant `Image` est importé mais jamais utilisé dans le rendu).

**Composants Atelier CAARCO utilisés** : Aucun.

**Structure / layout** : Colonne centrée unique : icône bouclier pulsante, titre, bloc message (bordure gauche accentuée), séparateur décoratif avec icône horloge, sous-texte rassurant, pied de page en position absolue (logo + sous-titre). Aucun bouton, aucune navigation — écran totalement bloquant.

---

## 63. CallScreen.js
`App/src/screens/CallScreen.js`

**Rôle / accès** : Tout utilisateur authentifié initiant ou recevant un appel (audio ou vidéo) avec une autre partie.
**Objectif de l'écran** : Afficher une session d'appel Jitsi Meet intégrée dans une `WebView`, avec en-tête personnalisé et gestion des états de chargement/erreur.

**Textes affichés à l'écran** :
- "Appel vidéo"/"Appel audio" (selon type) ; "Appel CAARCO" (titre par défaut)
- "Connexion en cours…" ; "Appel vidéo sécurisé"/"Appel audio sécurisé"
- "Connexion impossible" ; "Vérifiez votre connexion internet et réessayez." ; "Réessayer"

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.charbon`, `colors.cendre`, `colors.blanc`, `colors.brume`, `colors.manioc`, `colors.lateriteSoft`, `colors.laterite`. Aucun hex en dur.

**Icônes** : Ionicons. `arrow-back`, `videocam`/`call` (indicateur type), `videocam-outline`/`call-outline` (chargement), `wifi-outline` (erreur), `refresh-outline` (réessayer).

**Images / visuels** : `WebView` chargeant `` `https://meet.jit.si/${room}?embedded=true#${fragment}` `` (Jitsi Meet, config via fragment d'URL : pré-jointure désactivée, deep linking désactivé, mute initial selon params, simulcast désactivé, watermarks masqués).

**Composants Atelier CAARCO utilisés** : Aucun.

**Structure / layout** : Header (retour, chip type d'appel + titre). Corps : `WebView` plein écran avec overlay de chargement (icône, spinner, titre, sous-texte), remplacé par un bloc d'erreur (icône, titre, message, réessayer) en cas d'échec.

---

## 64. ChatScreen.js
`App/src/screens/ChatScreen.js`

**Rôle / accès** : Tout utilisateur authentifié, dans une conversation liée à une course ou en messagerie directe.
**Objectif de l'écran** : Messagerie temps réel (texte + images), avec réponse/citation, sélection multiple (suppression/partage), filtrage anti-partage de coordonnées de contact, et visualisation de positions partagées sur une carte.

**Textes affichés à l'écran** :
- "En ligne"/"Hors ligne" ; "Voir la position sur la carte"
- `` `${n} sélectionné(s)` `` ; "Tout" ; "Chat" (fallback) ; "Aucun message"
- "Discutez avant de confirmer votre course" / "Partagez des photos de vos bagages\nou posez vos questions ici"
- "⚠️ Le partage de contacts est interdit dans CAARCO." (blocage regex) ; "Seul le client peut initier une conversation."
- "Échec d'envoi, " + message d'erreur ; "Attendez que le client vous contacte en premier"
- "Votre réponse…"/"Votre message…" ; "Position du transporteur" (modal carte)
- Menu contextuel : "Copier", "Répondre", "Transférer", "Sélectionner", "Supprimer", "Signaler"
- Alertes : permissions caméra/galerie, "Seul le client peut initier une conversation.", confirmation suppression, "Signalement envoyé"

**Couleurs** : `colors.foret`, `colors.foret10`, `colors.brume` (bulle "autre", bordures), `colors.bambouSoft` (bulle "moi"), `colors.charbon`, `colors.cendre`, `colors.bambou` (en ligne, case cochée), `colors.lateriteSoft`/`colors.laterite` (erreur d'envoi), `colors.foret30`, `colors.blanc`, `colors.manioc`. Couleurs de thème dynamiques `tc.*`. Hex en dur : `'#e3ede5'` (bulle sélectionnée), `'rgba(31,59,42,0.06)'` (bloc citation), `colors.laterite + '40'` (bordure bandeau erreur).

**Icônes** : Ionicons. `arrow-back`, `close`, `send`, `camera-outline`, `image-outline`, `map-outline`, `checkmark` (sélection), `copy-outline`, `return-down-back-outline`, `arrow-redo-outline`, `checkmark-circle-outline`, `trash-outline`, `flag-outline`, `alert-circle-outline`, `chatbubbles-outline` (vide), `share-outline`, `lock-closed-outline` (blocage TR).

**Images / visuels** : `<Image source={{ uri: item.image_url }}>` (messages image) ; avatar via `Mereau` ; `CarteLeaflet` dans un `Modal` plein écran pour visualiser la position du transporteur (marqueur type `'user'`).

**Composants Atelier CAARCO utilisés** : `Mereau`, `BadgeVerifie`, `CarteLeaflet`, `MenuContextuel`.

**Structure / layout** : Header à deux variantes (normal / sélection). `FlatList` de bulles (droite/vert pour soi, gauche/gris pour l'autre, avec avatar, citation, images, ou lien carte). Bandeau d'erreur conditionnel. Pied à trois variantes : barre de sélection multiple, bandeau de blocage TR, ou zone de saisie (réponse + caméra/galerie + texte + envoyer). Appui long → `MenuContextuel`. `Modal` plein écran pour la carte de position.

---

## 65. SplashAnimeeScreen.js
`App/src/screens/SplashAnimeeScreen.js`

**Rôle / accès** : Affiché en interne comme écran de transition/chargement (piloté par les props `pret` et `onTermine`), typiquement pendant le chargement initial des données de l'app.
**Objectif de l'écran** : Divertir l'utilisateur pendant le chargement avec une animation de logo et une métaphore de trajet (un camion stylisé roulant d'un point A à un point B), jusqu'à ce que l'app soit prête, puis disparaît en fondu.

**Textes affichés à l'écran** :
- "CAARCO" (nom de la marque)
- "Transport de confiance au Cameroun" (tagline)
Aucun texte dynamique, aucune erreur, aucun `Alert`, pas d'i18n.

**Couleurs** : Ce fichier n'importe **pas** le thème `colors` — toutes les couleurs sont des hex en dur définis localement : `COULEUR_FOND = '#1f3b2a'` (fond, ≈ foret), `COULEUR_ROUTE = '#2e5040'` (route, propre au fichier), `COULEUR_MARQUAGE = '#c89441'` (marquage, ≈ nere). Autres : `'#ffffff'` (texte "CAARCO", icônes marqueurs), `'#3d6b4a'` (marqueur A, ≈ bambou), `'#c89441'` (marqueur B, points de chargement), `'#ffffff60'` (tagline). Illustration du camion (`CamionCaarco`, dessinée en `View`, pas une image) : `'#3d6b4a'` (caisse), `'#c89441'` (bande), `'#1f3b2a'` (cabine), `'#cfdbcf'` (pare-brise), `'#c89441'` (phare), `'#1d2420'` (roues), `'#6b6f68'` (enjoliveurs).

**Icônes** : Ionicons. `home-outline` (marqueur départ A), `flag` (marqueur arrivée B).

**Images / visuels** : `require('../../assets/Logo CAARCO Light PNG.png')` (logo en haut). Le camion n'est pas une image mais une illustration de `<View>` stylisées, animée horizontalement.

**Composants Atelier CAARCO utilisés** : Aucun (ni composants Atelier ni tokens du thème central — polices en dur `'Marcellus_400Regular'`/`'PlusJakartaSans_400Regular'`).

**Structure / layout** : Overlay plein écran (`zIndex: 9999`) : bloc logo en haut ; scène de route (marqueur A → route pointillée animée avec camion en mouvement → marqueur B) ; bloc bas avec tagline et 3 points de chargement animés. Animation en deux phases : le camion avance jusqu'à 82 % du trajet puis attend que `pret` devienne vrai avant de terminer sa course, puis fondu et `onTermine()`.

---

## 66. ChangerMotDePasseScreen.js
`App/src/screens/ChangerMotDePasseScreen.js`

**Rôle / accès** : Utilisateur authentifié, accédant depuis le menu Profil.
**Objectif de l'écran** : Changer le mot de passe du compte en vérifiant d'abord l'ancien mot de passe par ré-authentification, puis en le mettant à jour via Supabase Auth.

**Textes affichés à l'écran** :
- "Changer le mot de passe" ; "Saisissez votre mot de passe actuel, puis le nouveau mot de passe souhaité."
- "Mot de passe actuel"/"Votre mot de passe actuel", "Nouveau mot de passe"/"Au moins 6 caractères", "Confirmer le nouveau mot de passe"/"Répéter le nouveau mot de passe"
- "Confirmer le changement" ; "Choisissez un mot de passe d'au moins 6 caractères. Ne le partagez jamais."
- Erreurs : champs vides, longueur minimale, mots de passe différents, "Session expirée. Reconnectez-vous.", "Ancien mot de passe incorrect.", erreur générique
- Succès : "Mot de passe modifié !" ; "Votre nouveau mot de passe est actif. Utilisez-le lors de votre prochaine connexion." ; "Retour au profil"

**Couleurs** : `colors.manioc`, `colors.foret`, `colors.foret10`, `colors.charbon`, `colors.cendre`, `colors.brume`, `colors.bambou`, `colors.bambouSoft`. Aucun hex en dur.

**Icônes** : Ionicons. `arrow-back`, `lock-closed-outline`, `key-outline`, `shield-checkmark-outline`, `checkmark-circle`.

**Images / visuels** : Aucune.

**Composants Atelier CAARCO utilisés** : `Galet`, `Sillon` (3 champs), `Bandeau`.

**Structure / layout** : Deux états : (1) écran de succès centré (icône, titre, message, bouton retour) ; (2) formulaire (header, icône+titre+sous-titre, `Bandeau` erreur, 3 champs sécurisés, bouton de confirmation, bloc conseil sécurité).

---

## 67. ContributionsCarteScreen.js
`App/src/screens/ContributionsCarteScreen.js`

**Rôle / accès** : Utilisateur authentifié participant à l'enrichissement collaboratif de la carte (signalements de lieux, corrections).
**Objectif de l'écran** : Écran à deux onglets — valider les contributions proches de sa position (gain de points) et consulter son propre historique de contributions ; header affichant le solde de points ; bouton flottant pour soumettre une nouvelle contribution.

**Textes affichés à l'écran** :
- "Valider"/"Mes contributions" (onglets avec compteur) ; "Carte communautaire" ; `` `${points} pts` ``
- "Aidez CAARCO à avoir la carte la plus précise du Cameroun. Gagnez des points pour chaque contribution validée."
- `` `${validations}/3` `` ; `` `Catégorie : ${c}` `` ; `` `Signalé par ${nom}` ``
- "Validé (+2 pts)"/"Valider (+2 pts)" ; statuts "✓ Confirmé", "✗ Rejeté", `` `En attente · ${n}/3` `` ; `` `+${points} pts` ``
- "Chargement…" ; "Aucune contribution proche"/"Pas encore de contribution" ; "Contribuer" (FAB)

**Couleurs** : `colors.foret` (icônes, banner, valider, FAB), `colors.brume`, `colors.charbon`, `colors.nere` (points), `colors.nereSoft` (badge points), `colors.bambouSoft` (bannière info), `colors.cendre`, `colors.manioc`, `colors.blanc`, `colors.bambou` (état confirmé), `colors.laterite` (statut rejeté). Couleur dynamique externe `cfg.couleur` (service `contributions`) avec suffixe d'opacité `+ '15'`.

**Icônes** : Ionicons. `arrow-back`, `map-outline`, `star` (solde points), `people-outline` (votes), `thumbs-up-outline`, `checkmark-circle`, `add` (FAB), `location-outline`/`add-circle-outline` (états vides). Icônes additionnelles dynamiques via `cfg.icone`.

**Images / visuels** : Aucune image ni carte visuelle (liste textuelle malgré le nom) ; géolocalisation pour filtrer les contributions à 5 km.

**Composants Atelier CAARCO utilisés** : `ContributionModal` (hors liste Atelier nommée).

**Structure / layout** : Header (retour, titre, badge points). Bannière info. Onglets avec compteurs. Chargement / état vide / `FlatList` avec `RefreshControl` (cartes différentes selon onglet : validation avec bouton d'action, ou historique avec statut coloré). FAB "Contribuer" ouvrant `ContributionModal`.

