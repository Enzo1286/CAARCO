# MÉMOIRE PROJET — CAARCO
Dernière mise à jour : 2026-07-17
Emplacement projet  : D:\Mon projet\CAARCO (déplacé le 2026-07-04, ex-D:\CAARCO)
                      ⚠️ Chemin avec ESPACE → toujours mettre les chemins entre guillemets
Sessions totales    : 28
Propriétaire        : Cedric Timene — Bafoussam, Cameroun

═══════════════════════════════════════════════════════════════

## 🎯 VISION DU PROJET
CAARCO — Application mobile de transport de marchandises
et de déménagement au Cameroun.
"L'Uber du déménagement au Cameroun."
Marché cible : particuliers et commerçants, Cameroun → Afrique.
Monnaie : XAF exclusivement (entiers, jamais de décimaux).
Brand essence : "Warm Authority" — Limpide, Robuste, Camerounais.

---

## 👤 PROFIL DU PROPRIÉTAIRE
- Nom              : Cedric Timene
- Localisation     : Cameroun
- Autres projets   : Numerik World, Bibiche Podcast, Elite TV, CFP AS Com.
- Monnaie          : XAF (Franc CFA) — TOUJOURS
- Langue           : Français
- Outils de dev    : Claude Code + VS Code + Claude Cowork
- Style            : Livrables directs et prêts à l'emploi

---

## 🏗️ STACK TECHNIQUE (RÉELLE — vérifiée au 2026-06-01)

```
Frontend Mobile   : React Native 0.83.6 + Expo SDK 55.0.24 (bare workflow)
Backend / DB      : Supabase (PostgreSQL + PostGIS + Auth + Storage + Edge Functions)
Authentification  : Supabase Auth — téléphone + mot de passe ✅ CONFIRMÉ
                    Email stocké sous forme {telephone}@caarco.local
                    Role forcé côté serveur à la création, jamais côté client
Paiements V1      : Moneroo (Edge Functions initier-paiement + moneroo-webhook)
Paiements V2      : Notchpay + Lygos (fallback planifié)
Cartographie      : CarteLeaflet (Leaflet dans WebView) — OSM gratuit, sans clé API
Routage           : OSRM public (itineraire.js) — gratuit
Notifications     : Expo Push Notifications (FCM V1 — expo_push_token dans users)
État global       : Context React (AuthContext + CourseContext + MaintenanceContext)
Offline           : offlineCache.js + offlineQueue.js (cache et file d'attente)
Design system     : Atelier CAARCO — tokens dans App/theme.js + Design/caarco_theme.js
Build & Deploy    : EAS Build configuré (App/eas.json — 3 profils)
App ID            : com.caarco.app (Android + iOS)
Project EAS ID    : 2be38559-f448-4597-a35e-0b9b306f1e65 (owner: enzo1286)
Version app       : 1.0.0
Stores            : Play Store (Android V1) → App Store (iOS dans 3 mois)
Monnaie           : XAF exclusivement
Langue            : Français V1
React version     : 19.2.0

Site web          : Next.js 16.2.6 + Tailwind CSS v4 + framer-motion + Google Sheets CMS
URL live          : https://caarco-web.vercel.app
CMS               : Google Sheet ID 14kZ8nLZgO7eRqGDrDgVovn28uDm17TINYsBiWO3idXE
```

---

## 🔑 DÉCISIONS STRATÉGIQUES (TOUTES PRISES — FINALES)

```
SÉQUESTRE          ✅ ACTIVÉ — RPC liberer_sequestre_course() côté Supabase
CASH-ON-DELIVERY   ❌ EXCLU de la V1
ASSURANCE COLIS    📋 Plafond interne 50 000 FCFA (sans assureur externe)
COOPTATION         📋 Pas de pénalité pour le parrain en cas de litige filleul
GÉOFENCING         📍 Cameroun uniquement au lancement V1
PRODUITS INTERDITS 📋 Liste statique + validation admin humaine (IA en V2)
PRICING DYNAMIQUE  ❌ PAS de surge pricing en V1
COMMISSION         💰 20% prélevé par CAARCO sur chaque course
TRANSIT CHINE-AFR  ❌ EXCLU définitivement du scope CAARCO
TVA / OHADA        📋 Immatriculation OHADA obligatoire avant lancement
HÉBERGEMENT DATA   ☁️ Supabase EU Frankfurt (RGPD)
USSD FALLBACK      ❌ EXCLU de la V1
PARTENARIATS       🤝 Solliciter MTN + Orange + GIE transporteurs activement
```

---

## 💰 FORMULE DE PRIX (Edge Function UNIQUEMENT)

```javascript
const PRIX_BASE     = 500    // FCFA
const PRIX_KM       = 250    // FCFA/km (variable selon catégorie véhicule)
const FRAIS         = 0.10   // 10% frais de service
const NUIT          = 0.20   // +20% de 22h à 5h
const MINIMUM       = 1000   // FCFA minimum garanti

prix = Math.max(MINIMUM, Math.ceil(
  (PRIX_BASE + distanceKm * PRIX_KM) * (1 + FRAIS) * (isNuit ? 1.20 : 1)
  / 50) * 50)

// Commission : Math.round(prix * 0.20)
// Net transporteur : Math.round(prix * 0.80)
```

Tarifs par catégorie (AccueilScreen) :
- Moto            : 150 XAF/km
- Voiture         : 250 XAF/km
- Tricycle / Van  : 400 XAF/km
- Camion          : à vérifier

⚠️ Vérifier que App/src/services/prix.js appelle l'Edge Function
   et ne calcule PAS le prix localement.

---

## 🎨 DESIGN SYSTEM — ATELIER CAARCO

Fichier de référence : App/theme.js (et Design/caarco_theme.js)

Pigments officiels :
- Forêt    #1f3b2a → Primaire / Marque
- Bambou   #3d6b4a → Action / Boutons
- Néré     #c89441 → Accent / Prix / Logo
- Latérite #b8612e → Alertes / Annulation
- Manioc   #fbf9f3 → Fond principal (jamais blanc pur)
- Brume    #ece9e0 → Fond secondaire / Cartes
- Cendre   #6b6f68 → Texte secondaire
- Charbon  #1d2420 → Texte principal

Typographie : Marcellus (display) · Plus Jakarta Sans (body) · JetBrains Mono (prix FCFA)
Galets (border-radius) : xs:4 sm:8 md:14 lg:24 full:9999
Cadences (spacing) : pas:4 pause:8 souffle:12 arret:16 couloir:24 patio:32

Composants UI créés (nommage Atelier CAARCO) :
- Galet        → Bouton CTA
- Sillon       → Input texte
- Plaquette    → Card/carte
- Pastille     → Badge statut
- Mereau       → Composant UI
- Bascule      → Toggle switch
- Jalons       → Progress steps
- Echelon      → Composant liste
- Bandeau      → Alerte/Banner
- Alcove       → Section/bloc
- Onglets      → Tabs
- Cachet       → Tampon/badge
- BoutonAnime  → Bouton animé
- CarteLeaflet → Carte OSM WebView
- TutorielPopup→ Tutoriel first-run

Fichiers de référence design :
- CAARCO_Brand_Identity.html
- Atelier_CAARCO_-_Design_System.html
- CAARCO_Hi-Fi.html
- CAARCO_Wireframes.html

---

## ✅ TRAVAIL ACCOMPLI (état réel au 2026-05-21)

### Design (terminé)
- [2026] ✅ Charte marque complète (Brand Identity)
- [2026] ✅ Design system Atelier CAARCO (tokens + composants)
- [2026] ✅ Wireframes low-fi complets (20+ écrans)
- [2026] ✅ Hi-Fi mobile (10+ écrans)

### Application React Native — COMPLÈTE (vérifiée au 2026-06-01)
- [2026] ✅ Structure projet complète (App/, supabase/, Design/)
- [2026] ✅ Polices Atelier CAARCO chargées (Marcellus, Plus Jakarta Sans, JetBrains Mono)
- [2026] ✅ Splash animée (SplashAnimeeScreen)
- [2026] ✅ AuthContext + CourseContext + MaintenanceContext (état global)
- [2026] ✅ Navigation complète (Root + Client + Transporteur + Admin)
- [2026] ✅ Mode maintenance (EcranMaintenance.js + MaintenanceContext.js)
- [2026] ✅ Offline support (offlineCache.js + offlineQueue.js)
- [2026] ✅ Système motivation/fidélité avancé (jalons.js + motivation.js)

AUTH (5 écrans)
- [2026] ✅ SplashScreen + SplashAnimeeScreen
- [2026] ✅ ConnexionScreen (téléphone + mot de passe)
- [2026] ✅ InscriptionScreen
- [2026] ✅ MotDePasseOublieScreen (reset via Edge Function)

CLIENT (18+ écrans — flux complet)
- [2026] ✅ AccueilScreen (carte OSM + catégories véhicule + tutoriel first-run)
- [2026] ✅ TrajetScreen (saisie départ/arrivée avec LocationPicker)
- [2026] ✅ DetailsColisScreen (type + poids + volume)
- [2026] ✅ ConfirmationScreen (résumé + estimation prix)
- [2026] ✅ AttenteScreen (animation recherche transporteur)
- [2026] ✅ CourseAccepteeScreen
- [2026] ✅ SuiviScreen (GPS temps réel + OTP affiché + itinéraire OSRM)
- [2026] ✅ PaiementScreen (Moneroo WebView checkout)
- [2026] ✅ PayerTransporteurScreen
- [2026] ✅ RechargeRapideScreen (recharge wallet Moneroo)
- [2026] ✅ NotationScreen (étoiles + commentaire)
- [2026] ✅ HistoriqueScreen
- [2026] ✅ CourseDetailClientScreen
- [2026] ✅ MessagesScreen + ChatScreen + CallScreen
- [2026] ✅ WalletScreen (solde + historique transactions)
- [2026] ✅ PointsScreen (programme fidélité + paliers)
- [2026] ✅ ParrainageScreen (code unique + gains filleuls)
- [2026] ✅ ProfilTransporteurScreen

TRANSPORTEUR (15+ écrans — flux complet)
- [2026] ✅ TableauBordScreen (toggle en ligne/hors ligne + courses dispo + GPS)
- [2026] ✅ CourseScreen (accept/refus avec timer)
- [2026] ✅ NavigationScreen (GPS vers client)
- [2026] ✅ AttenteReglementScreen (attente OTP + validation paiement)
- [2026] ✅ NotationClientScreen
- [2026] ✅ CoursesTransporteurScreen (historique)
- [2026] ✅ RevenusScreen (dashboard gains)
- [2026] ✅ RetraitScreen (retrait Mobile Money)
- [2026] ✅ EncaissementScreen
- [2026] ✅ PacksAbonnementScreen (abonnements transporteurs)
- [2026] ✅ MessagesTransporteurScreen
- [2026] ✅ ProfilClientScreen + AdDetailScreen
- [2026] ✅ SoumissionKYCScreen (upload CNI + permis + photos véhicule)
- [2026] ✅ StatutKYCScreen

ADMIN (12+ écrans — back-office complet)
- [2026] ✅ DashboardScreen (KPIs temps réel + graphique horaire)
- [2026] ✅ KYCValidationScreen (valider/rejeter transporteurs)
- [2026] ✅ LitigesScreen
- [2026] ✅ TransporteursAdminScreen + ClientsAdminScreen + UtilisateursScreen
- [2026] ✅ FinancesAdminScreen + RetraitsAdminScreen
- [2026] ✅ MarketingAdminScreen + CoursesEnCoursAdminScreen
- [2026] ✅ ConfigTarifsScreen (modifier les tarifs en live depuis la DB)
- [2026] ✅ AdminShell (shell navigation admin)

PARTAGÉS
- [2026] ✅ ProfilScreen, ProfilPublicScreen, MerciScreen
- [2026] ✅ EcranMaintenance (mode maintenance global)
- [2026] ✅ CallScreen, ChatScreen

### Composants UI (18+ composants)
- [2026] ✅ Galet, Sillon, Plaquette, Pastille, Mereau, Bascule
- [2026] ✅ Jalons, Echelon, Bandeau, Alcove, Onglets, Cachet
- [2026] ✅ BoutonAnime, CarteLeaflet, PickupLocationPicker
- [2026] ✅ DropoffLocationPicker, LocationPicker, TutorielPopup

### Services (23 services — réels vérifiés)
- [2026] ✅ supabase.js, auth.js, courses.js, paiement.js
- [2026] ✅ matching.js, candidatures.js, gps.js, itineraire.js (OSRM)
- [2026] ✅ messages.js, notifications.js, wallet.js, points.js
- [2026] ✅ avis.js, recu.js (PDF), statutConnexion.js, prix.js
- [2026] ✅ audio.js (alarme sonore transporteurs)
- [2026] ✅ motivation.js + jalons.js (système fidélité avancé)
- [2026] ✅ offlineCache.js + offlineQueue.js (support offline)
- [2026] ✅ modeConnexion.js, navPreference.js

### Hooks (4)
- [2026] ✅ usePositionGPS.js, useCompteurMessages.js, useNotifsMessages.js, useTutoriel.js

### Backend Supabase
- [2026] ✅ **66 migrations SQL** (⚠️ doublons numéros : 042, 056×3, 057×2, 058×2)
- [2026] ✅ Edge Function : notify (Push Expo ciblé 1 user)
- [2026] ✅ Edge Function : notifier-transporteurs (broadcast push batch 100, filtré par catégorie véhicule)
- [2026] ✅ Edge Function : moneroo-webhook (HMAC-SHA256 obligatoire + séquestre + payout + wallet)
- [2026] ✅ Edge Function : initier-paiement (checkout Moneroo + vérif prix DB + montant max 5M XAF)
- [2026] ✅ Edge Function : initier-recharge (checkout Moneroo wallet, 500–2M XAF)
- [2026] ✅ Edge Function : reset-mot-de-passe (mdp temporaire 8 chars, retour client)
- [2026] ✅ RPC liberer_sequestre_course() — libération automatique après OTP
- [2026] ✅ Trigger code_parrainage_auto — code unique 6 chars à l'inscription
- [2026] ✅ RPC get_stats_parrainage() — gains parrain côté serveur

### 🔐 Sécurité (vérifiée au 2026-06-01)
- [2026] ✅ HMAC-SHA256 sur moneroo-webhook (rejet si secret absent)
- [2026] ✅ Prix vérifié côté serveur (course.prix_fcfa === montant, rejet si mismatch)
- [2026] ✅ Montant max 5M XAF (initier-paiement) et 2M XAF (initier-recharge)
- [2026] ✅ RLS actif sur toutes les tables (policies par role)
- [2026] ✅ JWT stocké dans SecureStore (Keychain iOS / Keystore Android)
- [2026] ✅ URL WebView Moneroo validée par hostname exact (anti-spoofing)
- [2026] ✅ Role forcé côté serveur à l'inscription (jamais côté client)
- [2026] ❌ Tests automatisés absents (zéro fichier .test.js dans App/src)

### Fonctionnalités implémentées (vs spec initiale)
- [2026] ✅ Wallet client avec recharges Moneroo
- [2026] ✅ Programme fidélité avec paliers + streaks + VIP (jalons.js)
- [2026] ✅ Parrainage avec commissions automatiques (codes 6 chars uniques)
- [2026] ✅ Chat temps réel client ↔ transporteur (Supabase Realtime)
- [2026] ✅ Packs abonnement pour transporteurs
- [2026] ✅ Génération de reçus PDF (expo-print)
- [2026] ✅ Tutoriel first-run (useTutoriel + TutorielPopup)
- [2026] ✅ Mode maintenance global (MaintenanceContext + EcranMaintenance)
- [2026] ✅ Support offline (cache + file d'attente)
- [2026] ✅ ConfigTarifsScreen (admin modifie les tarifs en live)
- [2026] ✅ Reset mot de passe (Edge Function reset-mot-de-passe)

### Documents produits
- [2026-05-14] ✅ CLAUDE.md — Super prompt v2 (Sections 1-13)
- [2026-05-14] ✅ MEMORY.md — Ce fichier
- [2026-05-14] ✅ GUIDE_SESSION.md + GUIDE_COWORK.md
- [2026-05-14] ✅ CAARCO_Presentation_Publique.pptx (10 slides)
- [2026-05-14] ✅ CAARCO_Partenaires_Associes.pptx (11 slides, CONFIDENTIEL)
- [2026-05-14] ✅ CAARCO_Business_Plan.pptx (13 slides)
- [2026-05-14] ✅ CAARCO_Modele_Economique.pptx (12 slides)
- [2026-05-14] ✅ CAARCO_Cahier_des_Charges_Fonctionnel.docx (21 pages)
- [2026-05-14] ✅ CAARCO_Contrat_Transporteur.docx (13 pages, OHADA)
- [2026-05-14] ✅ CAARCO_CGU_Politique_Confidentialite.docx (12 pages)
- [2026-05-14] ✅ CAARCO_One_Pager_Executif.docx (1 page)

---

## 🌐 SITE WEB CAARCO — TERMINÉ (session 2026-05-31/06-01)

### Stack
```
Framework  : Next.js 16.2.6 (App Router)
Langage    : TypeScript
Style      : Tailwind CSS v4 + design tokens Atelier CAARCO
Animation  : framer-motion 12.x
Icônes     : lucide-react 1.17
Dossier    : D:\CAARCO-WEB (séparé de l'app D:\Mon projet\CAARCO)
```

### Pages (11 routes)
- `/` — Home (Hero animé + Stats + Services + CommentCaMarche + Avantages + Témoignages + CTA)
- `/clients` — Pour les expéditeurs & entreprises
- `/transporteurs` — Pour les transporteurs
- `/comment-ca-marche` — Guide complet client + transporteur
- `/tarifs` — Tarification transparente (4 véhicules)
- `/faq` — 4 catégories, 11 Q&A
- `/contact` — Coordonnées + formulaire
- `/telecharger` — Page de conversion Play Store
- `/a-propos` — Histoire + mission + valeurs
- `/cgu` + `/confidentialite` — pages légales

### CMS Google Sheets (LIVE)
- Fichier : `D:\CAARCO-WEB\src\lib\content.ts`
- Google Sheet ID : `14kZ8nLZgO7eRqGDrDgVovn28uDm17TINYsBiWO3idXE`
- CSV URL dans : `D:\CAARCO-WEB\.env.local` → `SHEET_CSV_URL`
- 120+ clés de contenu — tout le texte du site modifiable sans code
- Cache : 0 sec (dev) / 5 min (production) — mise à jour quasi-instantanée
- Images : URLs dans le Sheet (Google Drive, Imgur, Cloudinary supportés)
- Domaines autorisés dans next.config.ts : drive.google.com, lh3.googleusercontent.com, imgur, cloudinary, unsplash

### Composants clés
- `PageHero` — hero animé réutilisable (cercles décoratifs, badge pulsant, stagger entrée)
- `AnimatedSection` — scroll-trigger animations (margin: 0px, once: true)
- `VehiculeIcon` — Lucide icons (Bike/Car/Van/Truck) couleur nere
- `Services` — 4 usages (Livraison / Déménagement / Logistique / Ponctuel)
- `Stats`, `CommentCaMarche`, `AvantagesClients`, `AvantagesTransporteurs`, `Temoignages`, `CtaDownload` — tous connectés au Sheet

### Particularités
- Navbar : transparente sur Home (Hero sombre), foret fixe sur pages internes (via usePathname)
- Contenu enrichi : 4 usages vs "livraison seule" → entreprises, déménagement, ponctuel
- Footer + Contact : coordonnées dynamiques depuis le Sheet

---

## 🔄 EN COURS / QUESTIONS OUVERTES

### Questions ouvertes
1. **OnboardingScreen** (3 slides) absent du code. Créer avant Play Store ?
2. **Migrations dupliquées** ⚠️ : 5 numéros en doublon (042, 056×3, 057×2, 058×2) → à consolider avant réinit DB
3. **Edge Functions non redéployées** ⚠️ : 4 fonctions modifiées localement mais pas publiées sur Supabase

### Résolu
- ✅ Auth : mot de passe confirmé (email = téléphone@caarco.local)
- ✅ Site web : déployé sur https://caarco-web.vercel.app
- ✅ CMS Google Sheets : actif en production

---

## 📋 BACKLOG DÉVELOPPEMENT (ce qui reste)

### 🔴 CRITIQUE — Avant lancement Beta
- [x] eas.json présent (3 profils : dev, preview, production)
- [x] APK release buildé et installé sur téléphone physique (2026-05-21)
- [x] Site web déployé : https://caarco-web.vercel.app (2026-06-01)
- [x] CMS Google Sheets actif en production
- [ ] ⚠️ Redéployer 4 Edge Functions sur Supabase (modifiées localement, pas publiées) :
       · notifier-transporteurs · moneroo-webhook · initier-paiement · initier-recharge
       Commande : cd "D:\Mon projet\CAARCO" && npx supabase login
                  npx supabase functions deploy <nom> --project-ref dxwkikaniawpfljvteog
- [ ] ⚠️ Consolider les migrations dupliquées (042, 056, 057, 058) avant réinit DB
- [ ] Tests paiement Moneroo sandbox → production
- [ ] Optimiser APK : 52.4 MB → objectif < 30 MB avant Play Store
- [ ] Connecter domaine caarco.cm au site Vercel

### 🟡 IMPORTANT — Avant Play Store
- [ ] Créer compte Google Play Console (25 USD)
- [ ] Préparer assets Play Store (screenshots 1080×1920, icône 512px, feature graphic)
- [ ] Security review complet (/security --pre-deploy)
- [ ] Optimisation bundle (APK < 30MB)
- [ ] Immatriculation OHADA de CAARCO
- [ ] Recruter 50 transporteurs fondateurs au Cameroun

### 🟡 DOCUMENTS RESTANTS (5-10/10)
- [ ] 5/10 Fiches de poste (CTO, Ops, Commercial)
- [ ] 6/10 Term sheet investisseur
- [ ] 7/10 Kit presse / Media kit
- [ ] 8/10 Plan de communication 90 jours
- [ ] 9/10 Tableau de bord financier Excel
- [ ] 10/10 Contrat de partenariat commercial

### 🟢 NICE TO HAVE — V2
- [ ] Edge Function calculate-price dédiée (actuellement dans initier-paiement)
- [ ] Edge Function generate-otp dédiée (si migration vers OTP auth)
- [ ] Multi-villes (Douala, Yaoundé, Bamenda)
- [ ] Notchpay + Lygos en fallback
- [ ] IA validation produits interdits

---

## 🏗️ ARCHITECTURE TECHNIQUE — SUPABASE (état réel)

### Tables principales (35 migrations)
```
users              → id, phone, nom, role, statut, score_notation,
                     statut_connexion, expo_push_token, type_vehicule,
                     code_parrainage (unique, auto-généré 6 chars),
                     parrain_id
courses            → id, client_id, transporteur_id, statut, type_transport,
                     coordonnées GPS, distance_km, prix_fcfa, otp_code,
                     statut_paiement, moneroo_payment_id, categorie_vehicule
paiements          → id, course_id, client_id, montant_fcfa, methode,
                     numero_mobile, statut, reference, moneroo_payment_id
wallets            → id, user_id, solde_fcfa
transactions_wallet→ id, wallet_id, type, montant_fcfa, methode,
                     statut, moneroo_payment_id, moneroo_checkout_url
messages           → id, course_id, expediteur_id, contenu, lu, created_at
positions_gps      → id, user_id, course_id, lat, lng (supprimées après 30j)
transporteurs_kyc  → id, user_id, type_vehicule, cni_url, permis_url,
                     vehicule_url[], statut_kyc, motif_rejet
commissions_parrainage → id, parrain_id, filleul_id, course_id, montant_fcfa
candidatures       → id, course_id, transporteur_id, statut, expires_at
parametres_tarifs  → table admin pour config tarifs en live
retraits           → id, transporteur_id, montant_fcfa, statut, methode
litiges            → table de gestion des litiges admin
```

### Edge Functions (5 déployées)
```
notify                  → Push Expo ciblé (1 user)
notifier-transporteurs  → Broadcast push TR en ligne (batch 100, par catégorie véhicule)
moneroo-webhook         → HMAC SHA-256 + séquestre course + recharge wallet
initier-paiement        → Checkout Moneroo pour course (XAF, MTN/Orange)
initier-recharge        → Checkout Moneroo pour wallet (min 500 XAF)
```

---

## 📐 CONVENTIONS DU PROJET

Nommage (métier en français) :
- Variables : prixCourse, distanceKm, roleUtilisateur, statutCourse
- Constantes : PRIX_BASE_FCFA, PRIX_PAR_KM, COMMISSION_TAUX
- Fonction : formatFCFA(n) → "2 500 FCFA" (JetBrains Mono)
- Composants : nommage Atelier CAARCO (Galet, Sillon, Plaquette…)

Statuts de course (MAJUSCULES_UNDERSCORE) :
DEMANDE → EN_RECHERCHE → CONFIRMEE → EN_COURS → TERMINEE
                           ↓
                       ANNULEE / LITIGE

Format montants : entiers XAF — "2 500 FCFA"
Format téléphone : +237XXXXXXXXX (E.164)
Format dates : ISO 8601

---

## 🐛 BUGS CONNUS

- ⚠️ **6 numéros de migration dupliqués** (audit 2026-07-03) : 056 (×3), 057 (×2),
  058 (×2), 060 (×2), 061 (×3), 062 (×2)
  → NON renumérotés (risque sur DB déjà déployée). Approche sûre : NE PAS renommer
    les fichiers déjà appliqués ; créer une migration de consolidation datée pour
    tout futur `db reset`, ou basculer sur des noms timestamp (20260703xxxxxx_...).
- ⚠️ **Boutons de paiement morts** : `navigate('Paiement')` dans AccueilScreen (~600)
  et SuiviScreen (payerAvance ~253 + useEffect ~239) pointent vers une route supprimée
  (modèle TC = paiement direct client→TR). À retirer/rediriger avec QA visuelle.
- ⚠️ **6 écrans financiers morts non supprimés** (WalletScreen, RechargeRapideScreen,
  PaiementScreen, PayerTransporteurScreen, RetraitScreen, EncaissementScreen) :
  désormais 0 import, hors bundle. Suppression bloquée dans l'env Cowork — à supprimer
  depuis VS Code.
- Migration 014 hors-séquence (listée entre 015 et 013 dans le fs)
  → Risque faible si Supabase applique par timestamp
- **reset-mot-de-passe** : Edge Function jamais déployée sur Supabase → retourne non-2xx
- **0 tests applicatifs** : aucun fichier .test.js dans App/src → régressions non détectées automatiquement

---

## 💬 CONTEXTE DES SESSIONS

Session 28 (2026-07-17) — Lot B clos (B4) + Lot C bundle prêt + assainissement sécurité :
- **Lot B admin web CLOS** : B4 (test navigateur) validé par Cedric — connexion `679570886` + 2FA +
  23 écrans OK. Audit préalable anti-casse : sur les 23 écrans admin, seuls `PublicitesAdmin`
  (image-picker/file-system, appelés au clic + garde `isWeb`) et `SecuriteAdminScreen` (WebView QR,
  déjà gérée Session 26) touchent au natif ; `MFAChallengeScreen` (chemin critique 2FA) est RN pur.
  Aucun crash au montage.
- **🔴 Découverte sécurité (résolue) — remise à zéro exposée sur le web** : `ConfigTarifsScreen.js:37`
  calcule `resetDisponible = EXPO_PUBLIC_APP_ENV !== 'production'` → une modale de remise à zéro
  destructive est accessible tant que la variable n'est pas `production`. Le `dist-web` servi pour B4
  avait été buildé SANS la variable (absente de `App/.env`) → remise à zéro accessible. **Corrigé** :
  `dist-web` régénéré avec `EXPO_PUBLIC_APP_ENV=production npx expo export --platform web --output-dir
  dist-web` (variable inlinée dans le bundle, PAS persistée dans `.env` pour ne pas toucher les autres
  builds). Vérifié bundle : client/TR exclus (0), aucun secret (0), `EXPO_PUBLIC_APP_ENV` inliné
  (0 accès runtime), clé anon/URL présentes.
- **Lot C — bundle prêt, déploiement à faire par Cedric** : approche retenue = déploiement du bundle
  STATIQUE pré-buildé (`App/dist-web`, avec `vercel.json` SPA copié depuis `scripts/vercel-admin.json`).
  Comme `APP_ENV=production` + URL/clé anon sont déjà inlinées, Vercel n'a qu'à servir des fichiers :
  aucune variable d'env à configurer côté Vercel. Commande : `cd App/dist-web && vercel --prod` (projet
  `caarco-admin`, distinct de `caarco-web`). Non exécutable côté agent (compte Vercel requis ; l'appel
  Management API Supabase et toute action sortante authentifiée sont d'ailleurs bloqués par le
  classifieur du harness en mode auto — constaté cette session).
- **🔐 Assainissement — la fuite n'était pas où le journal le disait** : `scripts/reset_mdp_admin.sql`
  ne contenait QUE des placeholders (pas de vrai mdp comme l'affirmait le journal 26bis). La vraie fuite
  était dans **`MEMORY.md`** (lignes 521/523 : `Brnd.25%E-c`, `Admin@Caarco2026!` en clair). **Retirés.**
  Vérifié : jamais entrés dans l'historique git (`git log -S` vide, absents de HEAD) — exposition locale
  uniquement. `reset_mdp_admin.sql` aussi corrigé (ciblait les emails périmés `697028122@`/`admin@` →
  réécrit pour l'unique compte `679570886@caarco.local`). Rotation du mdp : Cedric a choisi la voie SQL,
  à exécuter par lui (SQL Editor) car l'API Management est bloquée ici. 2FA inchangé = pas de verrouillage.
- **Nettoyage** : 13 fichiers parasites racine (débris de collage terminal, tous vides sauf `_wtest_5`)
  supprimés après confirmation. Plus aucun fantôme racine ni dans `App/`.

Session 26 (2026-07-17) — Comptes admin assainis + cadrage admin web :
- **Objectif Cedric** : accéder au back-office admin depuis n'importe où (navigateur), sans
  cette machine ni l'app, et y brancher un nom de domaine plus tard.
- **CDC_ADMIN_WEB.md créé** (racine) : c'est LE document de référence pour la suite de ce
  chantier — décisions, état des lieux prouvé, architecture, lots A à D, risques. Lire ce
  fichier avant toute nouvelle session sur l'admin web, pas ce journal.
- **Découverte majeure : la base de prod est ENTIÈREMENT à jour.** Les migrations 085 → 108
  sont TOUTES appliquées (dont 092/093/094/099 que ce MEMORY listait à tort comme « écrites
  mais pas déployées » — info périmée depuis, corrigée ici). `calculer_prix()` en version 103.
  Vérifié par `scripts/diagnostic_supabase.sql` (une seule requête, lecture seule, marqueurs
  par migration — l'historique CLI ne fait pas foi, les migrations ayant été passées à la main).
- **Comptes admin assainis** (`scripts/migrer_compte_admin.sql`, transaction + garde-fous) :
  · Il existait 2 super-admins : `697028122` (numéro n'appartenant PAS à Cedric) et `admin`
    (« Admin CAARCO », identifiant devinable `admin@caarco.local`, jamais connectable car
    `REGEX_TEL = /^[0-9]{8,15}$/` dans services/auth.js:7 rejette « admin » côté client).
  · Résultat : **un seul compte admin, `679570886` (le vrai numéro de Cedric), 2FA TOTP
    `verified` confirmé en base.** Le compte a été migré (même id → mot de passe, historique
    et facteur 2FA conservés), pas recréé. `admin` supprimé ; compte transporteur de test
    « Enzo » qui occupait 679570886 supprimé aussi (il était vide : 0 course/TC/KYC/message).
- **Piège rencontré (à retenir pour toute suppression de compte)** : ~14 clés étrangères vers
  `users` sont sans ON DELETE CASCADE (dont `wallets`, résidu du modèle abandonné) → un DELETE
  direct échoue. Le script nettoie les résidus techniques avant suppression. La transaction a
  protégé : 2 échecs successifs, 0 modification partielle.
- **Bug corrigé — QR code 2FA invisible sur web** : `SecuriteAdminScreen.js` rendait le QR dans
  une `WebView` (react-native-webview), inexistante en navigateur → « does not support this
  platform ». `QRCodeLocal` gère désormais les 2 plateformes (SVG injecté dans le DOM sur web,
  WebView inchangée sur mobile) + les 2 formats possibles de Supabase (SVG brut ou data-URI).
  Bon exemple du type d'incompatibilité que le Lot B devra débusquer écran par écran.
- **Capacité redécouverte** : `SUPABASE_ACCESS_TOKEN` (App/.env) permet d'exécuter du SQL sur la
  prod via l'API Management (`POST /v1/projects/dxwkikaniawpfljvteog/database/query`). Ne plus
  affirmer que c'est impossible sans avoir testé.
- **Prochaine étape** : Lot B du CDC_ADMIN_WEB.md (point d'entrée web admin uniquement), puis
  Lot C (Vercel). Lot A clos.

Session 26 bis (2026-07-17, reprise) — Commit correctif annulation + Lot B admin web B1-B3 :
- **Étape 1 close** : le travail non suivi dans `App/` (correctif « annulation automatique des
  courses planifiées en retard + affichage du motif ») commité en 2 commits séparés —
  `c646e6df` (migrations 107/108 déjà en prod, `courses-programmees-cron`, 9 écrans client/TR,
  fr.js/en.js 3 clés) et `aaf2fa68` (bump `app.json` 1.1.0 / versionCode 26, séparé du
  correctif). `SecuriteAdminScreen.js` (prépa Lot B) laissé non commité à ce stade.
- **⚠️ Sécurité à traiter** : `scripts/reset_mdp_admin.sql` (racine) contient de VRAIS mots de
  passe en clair (compte 697028122/679570886 et compte admin supprimé), PAS des emplacements
  comme l'affirme `CDC_ADMIN_WEB.md` §5.5. Non commité. À assainir avant tout `git add` racine
  + changer le mdp du compte principal s'il est encore actif.
  [MDP RÉELS RETIRÉS DE CE JOURNAL LE 2026-07-17 (Session 28) — jamais entrés dans l'historique
  git ; le fichier `scripts/reset_mdp_admin.sql` s'est avéré ne contenir QUE des placeholders,
  la vraie fuite était ici même dans MEMORY.md.]
- **Lot B admin web — B1-B3 faits** (commit `d99d53f0`) : `src/navigation/RootNavigator.web.js`
  (admin-only, Metro le résout sur web à la place de `RootNavigator.js`) + garde web sur
  `gpsBackground.js` (`TaskManager.defineTask` derrière `Platform.OS !== 'web'`). Export web OK,
  navigateurs client/TR exclus du bundle (vérifié par grep de chaînes exclusives). B2 : le repli
  localStorage de `supabase.js` existait déjà. Détail : mémoire auto `admin-web-entree-dediee`.
- **B4 (test navigateur) laissé à Cedric** : build servi sur http://localhost:3100 — connexion
  admin `679570886` + 2FA + navigation 23 écrans ; non-admin → « Espace réservé ».
- **Lot C (Vercel)** : `EXPO_PUBLIC_APP_ENV` absent de `App/.env` → le fixer à `production` sur
  Vercel (exclut la remise à zéro totale du build). Projet Vercel distinct de `caarco-web`.

Session 25 (2026-07-12) — Infographie promo Binda :
- Infographie Instagram 4:5 créée pour la promotion « première course » donnant la possibilité
  de gagner un écran plat 55 pouces neuf, avec Binda et la mention de conditions.
- PNG final déposé sur le Bureau : `Infographie-Promo-Binda-55pouces`.
- Décision de marque : le personnage officiel CAARCO s'appelle désormais **Binda**. Le fichier
  de référence conserve son nom historique `Kako_character_reference.jpeg`.

Session 24 (2026-07-12) — Carrousel Instagram Kako :
- Carrousel 4:5 de quatre slides centré sur Kako créé à partir de la planche officielle,
  avec quatre poses/cadrages, les logos CAARCO et les tokens Atelier CAARCO.
- PNG finaux déposés sur le Bureau : `Carrousel-Kako-CAARCO`.

Session 23 (2026-07-12) — Carrousel de présentation CAARCO :
- Carrousel Instagram 4:5 de quatre slides produit : promesse, quatre usages, parcours,
  appel à l'action. Source React/Tailwind et exporteur conservés dans
  `Carrousel-Presentation-CAARCO/`.
- PNG finalisés copiés sur le Bureau dans `Carrousel-Presentation-CAARCO`.

Session 22 (2026-07-12) — Charte Instagram CAARCO × Kako :
- Charte pérenne créée dans `CHARTE_CARROUSELS_INSTAGRAM_KAKO.md` : formats 1:1 et 4:5,
  palette Atelier CAARCO, typographies, logos, règles d'écriture et spécification React/Tailwind.
- Kako devient le personnage officiel obligatoire lorsqu'un carrousel a besoin d'un personnage.
  Référence copiée dans `App/assets/Kako_character_reference.jpeg`; logos officiels :
  `App/assets/Logo CAARCO PNG.png` (fond clair) et `App/assets/Logo CAARCO Light PNG.png`
  (fond sombre).
- Convention future : toute demande « Create a carousel on [Sujet] » crée par défaut quatre
  slides; l'export d'images fournit une image distincte par slide.

Sessions 16-21 (2026-07-08/09) — Refonte visuelle Lots 0-6 (en cours) :
- Suite directe de la Session 15 ci-dessous. Détail exhaustif (méthode, composants, i18n,
  DoD, découvertes) volontairement **pas** dupliqué ici — c'est le rôle assumé de
  `REFONTE_TRACKING.md` (racine du projet) et de la Partie D du CDC
  (`CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md`, sections D.4 à D.10), pensés dès le
  départ pour qu'une nouvelle conversation reprenne sans relire tout l'historique (D.2bis).
  Lire ces deux fichiers avant toute nouvelle session de refonte plutôt que ce journal.
- Statut au 09/07/2026 : Lot 0 (composants transverses, 11 fichiers) et Lots 1-6 clos
  (Auth, Accueil, Commande client ×2, Post-course client, Fidélité & réservations client —
  16 écrans au total). Prochain : Lot 7 (tableau de bord & mission transporteur).
- Seul point à retenir hors détail technique : **découverte au Lot 6** (CDC D.10.5) —
  le mécanisme de crédit de commission parrainage (`commissions_parrainage`) est mort sous
  le flux Jetons de Course actif (jamais porté depuis l'ancien modèle séquestre) ; la tuile
  "Gains de parrainage" de `ParrainageScreen.js` affichera 0 FCFA pour tous les utilisateurs
  tant que Cedric n'a pas tranché (porter le mécanisme sur le modèle TC, ou ajuster la
  promesse du texte `parrainageEcran.etape3`). Non corrigé (décision produit hors périmètre
  visuel), à ajouter à la liste des décisions Cedric en attente aux côtés de C.2 #3 (déjà
  dans le CDC C.2/D.3.3).
- Panne d'outillage toujours ouverte, signalée à chaque lot depuis le Lot 4 : `npx babel
  --presets babel-preset-expo` échoue systématiquement dans l'environnement agent (même sur
  du code non modifié) — validation syntaxique contournée via `@babel/parser` à chaque lot.
  À réparer sur poste (Cedric) si la commande standard redevient nécessaire.

Session 15 (2026-07-08) — Décision refonte visuelle complète, avant le lancement :
- Cedric a tranché : refonte visuelle **complète** de l'app, en s'appuyant largement sur le
  dossier de maquettes Stitch, et **avant** le lancement Play Store — pas après, pas en
  parallèle discret. Conséquence directe : les items 21 (assets store) et 22 (test fermé) du
  Sprint 4 sont repoussés après ce nouveau chantier (item 20, tests SQL, reste indépendant et
  peut avancer sans attendre). Les 2 corrections backend 🔴 de C.3.2 (trigger `wallets`, RPC
  `admin_crediter_wallet_client`) restent elles aussi indépendantes — à ne pas laisser traîner
  en attendant la refonte, ce sont de simples migrations SQL sans lien avec le design.
- Roadmap §0.4 mise à jour : "Sprint 4bis — Refonte visuelle complète" inséré avant la clôture
  du Sprint 4 (numérotation des items 20-22 conservée pour ne pas casser les références déjà
  écrites dans SPRINT_4.md et project_sprint_status.md).
- Nouvelle **Partie D** créée dans CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md : D.0
  (décision + cadrage, coût calendrier explicite) et D.1 (méthode — la grille C.1-C.4 sert de
  porte d'entrée : ~75 écrans ✅ utilisables tels quels, 6 🔧 à corriger avant usage, 2 ⚠️
  toujours hors périmètre tant que Cedric n'a pas tranché, 6 ❌ définitivement exclus).
  Précision actée : la refonte porte sur la mise en page/ergonomie, PAS sur un changement de
  design system (palette/typo Atelier CAARCO conservées, sauf décision distincte future sur
  `terroir_moderne_2`).
- **D.2 fait dans la foulée (même session, Cedric a dit "maintenant")** : inventaire complet
  des 64 écrans réels mappés à leurs maquettes Stitch. ~10 écrans sans maquette identifiée
  (fonctionnalités postérieures à l'export : courses programmées, sécurité admin Sprint 1,
  campagnes push). ~8 répartitions ambiguës entre plusieurs écrans réels et une maquette
  partagée (mes_courses_caarco, gestion_des_utilisateurs_admin, op_rations_live_admin*,
  suivi_en_temps_r_el*, v_rification_kyc_transporteur*) — volontairement pas tranchées ici,
  à trancher à l'ouverture de chaque lot (D.4) plutôt que devinées. **1 piège de nom vérifié
  et neutralisé** : `RetraitsAdminScreen.js` affiche en réalité les soldes TC des TR (déjà
  renommé dans le code, commentaire explicite ligne 13) — sans rapport avec `retrait_de_gains*`
  (❌) malgré la ressemblance de nom, bon exemple concret de la méthode C.4 appliquée. Rappel
  des 2 écrans bloqués par décision Cedric en attente : `PointsScreen`/`MerciScreen` (récompense
  streak) et `PacksAbonnementScreen` (commission paliers) — ne pas les retoucher visuellement
  avant tranchage produit.
- **Process pour la suite (Cedric, même session)** : avancer étape par étape, proposer des
  idées d'amélioration à chaque étape, et fournir à chaque fois un prompt prêt à coller dans
  une nouvelle conversation pour démarrer la phase suivante (au lieu de tout enchaîner dans une
  seule conversation qui grossit). 4 améliorations adoptées : fichier de suivi dédié, passe
  composants avant les écrans, captures avant/après par lot, lever les ambiguïtés en amont
  plutôt que lot par lot — détail en Partie D.2bis du CDC.
- **8 ambiguïtés de D.2 levées dans la foulée**, par lecture réelle du titre/contenu de chaque
  maquette concernée (pas par déduction) : `mes_courses_caarco_1/2` = 2 itérations du même écran
  (`HistoriqueScreen.js` client uniquement, pas partagé avec le TR ni les courses planifiées) ;
  `gestion_des_utilisateurs_admin` = `UtilisateursScreen.js` seul ; `op_rations_live_admin` =
  `CoursesEnCoursAdminScreen.js` et `op_rations_live_admin_caarco` = `OperationsAdminScreen.js`
  (2 écrans distincts, pas une variante) ; KYC transporteur `_1`=soumission/`_2`=statut ; les 4
  maquettes "suivi" = toutes `SuiviScreen.js` (vocabulaire passager confirmé, aucune ne va à
  `NavigationScreen.js`) ; `d_tails_du_trajet` en réalité une variante de `ConfirmationScreen.js`
  ("Confirmer la commande"), pas de la fiche course planifiée ; `profil_client_caarco`/
  `profil_transporteur_caarco` mappent tous les deux à `ProfilPublicScreen.js` (écran unique,
  confirmé partagé entre `ClientNavigator.js` et `TransporteurNavigator.js`). Ceci a aussi
  confirmé que ~12 écrans (pas 10) n'ont aucune maquette Stitch — la plupart liés aux courses
  programmées (Session 8, postérieures probables à l'export) ou vues filtrées d'un écran
  généraliste déjà attribué ailleurs.
- **`REFONTE_TRACKING.md` créé** à la racine du projet : suivi écran par écran (à faire/en
  cours/fait/bloqué/sans maquette) + rappel des 2 écrans bloqués et des 2 corrections backend
  🔴 indépendantes. À mettre à jour à la fin de chaque lot — c'est la source de vérité d'avancement
  pour la suite, pas la Partie D du CDC (qui garde la méthode et les preuves, pas le statut).
- Reste à faire, en nouvelles sessions (un chantier = une conversation, avec prompt de
  démarrage fourni à chaque fois) : D.3 (priorisation/lots, en commençant par le Lot 0 —
  passe composants transverses), puis D.4+ (lots d'implémentation). Rien codé sur les écrans
  à ce stade — uniquement le cadrage, l'inventaire et le suivi documentés.

Session 14 (2026-07-08) — Partie C (gouvernance maquettes Stitch) clôturée :
- C.1-C.3 (classification des ~95 maquettes du dossier `vehicle_character_sheets/`, plan de
  correction, vérification croisée bilinguisme FR/EN + modèle jetons) déjà faites en amont de
  cette session — détail complet dans CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md.
- C.3.2 a révélé que le résidu wallet/séquestre n'est pas du code mort inoffensif : le trigger
  `after_course_terminee` → `verifier_streak_client` écrit réellement dans `wallets` à chaque
  3ᵉ course/semaine d'un client (🔴 actif aujourd'hui), et la RPC `admin_crediter_wallet_client`
  est exploitable sans contrôle de rôle serveur si la migration 070 est déployée (🔴).
- C.4 rédigée : procédure permanente de tri de toute future maquette IA (Stitch ou autre) contre
  la grille C.1 (❌/⚠️/🔧/✅) avant qu'elle serve de référence de design. Tri fait par l'IA
  (preuve écrite + vérification du code réel) ; Cedric ne tranche que les ⚠️ et les décisions
  produit. Règle centrale : « classer par CAPACITÉ, jamais par nom » — pour empêcher qu'un écran
  déjà aboli (§0.2) revienne sous un nom différent, y compris côté backend (migrations/RPC/
  triggers, pas seulement le visuel). Rappel court ajouté dans CLAUDE.md (protocole de démarrage
  obligatoire) pointant vers la procédure C.4 du CDC.
- Partie C entièrement close (C.1 à C.4). Points ouverts transférés hors Partie C — ce sont des
  décisions produit/backend, pas de la gouvernance de maquettes : sort des tables orphelines
  `wallets`/`transactions_wallet`/`retraits`/`jalons_client`, neutralisation du trigger
  `after_course_terminee`, contrôle de rôle manquant sur `admin_crediter_wallet_client`, bug de
  perte silencieuse `sexe`/`date_naissance` dans `ProfilScreen.js` — tous en attente de décision
  Cedric, à traiter en dehors de tout travail sur les maquettes Stitch.

Session 13 (2026-07-08) — Audit complet et préparation production :
- Réalisation de l'audit de qualité complet (score 9/10).
- Déploiement réussi des 5 Edge Functions critiques (Notchpay et matching/dispatch push) sur le Supabase de production.
- Résolution du bug d'achat TC : alignement du minimum à 1000 TC dans `tokensTC.js` (client) pour matcher la validation de l'Edge Function.
- Résolution du bug PowerShell du script `build-debug.ps1` (réécriture 100% ASCII propre résolvant le parse error PowerShell lié à l'encodage et aux guillemets imbriqués).
- Vérification du build debug local Gradle de 11 minutes (succès, APK généré à 88,2 Mo).
- Rédaction du diagnostic qualitatif et du changelog de production final.

Session 12 (2026-07-07) — Sprint 2 Chantier B clos :
- 5 derniers composants i18n traités (BoutonSignalementCarte, CalendrierNaissance, TutorielPopup,
  MenuContextuel, LocationPicker) + 2 wrappers découverts en cours de route (DropoffLocationPicker,
  PickupLocationPicker, texte en dur passé en props à LocationPicker). fr.js/en.js : 1357 clés
  chacun, parité vérifiée. Vérification finale B1 (grep global hors admin/) et B3 (parité) au vert.
- Bug corrigé : le sélecteur de langue FR/EN dans ProfilScreen.js ne persistait jamais réellement
  (`langue` et `pseudo` absents de la liste blanche `CHAMPS_PROFIL_AUTORISES` dans services/auth.js
  → UPDATE Supabase silencieusement filtré malgré le toast de succès affiché ; la valeur revenait
  au français par défaut au redémarrage suivant). Ajoutés à la liste blanche (colonnes déjà
  présentes en base, migration 004).
- Détection de la langue système ajoutée sans nouvelle dépendance native (bare workflow, pas de
  device/émulateur ici pour valider un rebuild) : src/i18n/detecterLangueSysteme.js via
  NativeModules RN natif. Câblée à l'inscription (langue initiale du profil) et en repli dans
  useI18n() avant connexion (écrans d'auth).
- Bug trouvé, PAS corrigé (nécessite une migration SQL, décision Cedric) : ProfilScreen.js permet
  de modifier sexe et date_naissance (via CalendrierNaissance) mais ces colonnes n'existent dans
  AUCUNE migration de App/supabase/migrations — la liste blanche les filtre aussi, donc l'UI dit
  "sauvegardé" mais rien n'est jamais écrit pour ces deux champs.
- Nettoyage : ~35 fichiers fantômes vides à la racine du repo et dans App/ (résidus d'un collage
  de code JS dans un terminal lors d'une session antérieure, ex. `!selectionnes.has(c.id)))`,
  `handleAccepterCourseProgrammee(c.id)},`) — même symptôme que les fichiers fantômes nettoyés en
  Session 10, jamais entièrement éradiqué depuis. Supprimés.
- Vérifié : `npx expo export --platform web` compile sans erreur sur l'ensemble du bundle après
  tous ces changements.
- Reste avant de clore le sprint entier : Chantier A5 (trancher les 2 dossiers supabase/, toujours
  en attente de confirmation explicite Cedric) ; test manuel sur device de la bascule de langue et
  de sa persistance après redémarrage ; décision sur sexe/date_naissance (migration ou suppression
  des champs) ; ~65 fichiers modifiés/supprimés du Sprint 2 (Chantier A + B) encore non commités
  dans App/ — à committer une fois validés par Cedric.

Session 11 (2026-07-06/07) — Sprint 2 Chantier A (fini) + Chantier B i18n (très avancé) :
- Chantier A (conformité Play Store) terminé : A1-A4 livrés (6 écrans financiers morts +
  SplashScreen dupliqué + code mort de sélection manuelle supprimés, SplashAnimeeScreen
  intégré dans RootNavigator). A5 (trancher les 2 dossiers supabase/) toujours en attente
  de confirmation explicite Cedric — voir SPRINT_2.md.
- Chantier B (extraction i18n FR/EN complète) : fr.js/en.js passés de ~505 à 1322 clés,
  parité vérifiée après CHAQUE fichier (script Node de diff des clés aplaties). Tous les
  écrans client (16), transporteur (16), auth (3), écrans partagés racine (8) et 4/9
  composants partagés faits et vérifiés (grep + @babel/parser + parité). Détail complet,
  méthode établie, pièges connus (variable locale `t` qui masque le `t` i18n) et liste
  exacte des 5 fichiers composants restants (BoutonSignalementCarte, CalendrierNaissance,
  TutorielPopup, MenuContextuel, LocationPicker) dans SPRINT_2.md § Chantier B — état
  d'avancement. admin/ explicitement exclu du scope (reste français, décision Cedric).
- Correctif B2 appliqué : boutons "LOGIN"/"SIGN UP" (ConnexionScreen.js, en dur en anglais
  même en interface française) → clés `auth.connexion.choixLogin`/`choixSignup`
  ('CONNEXION'/'INSCRIPTION' en FR, 'LOGIN'/'SIGN UP' en EN).
- Bug métier trouvé en marge (PAS corrigé, hors scope i18n) : la bannière streak client
  dans MerciScreen.js promet "+100 XAF crédités sur votre wallet" pour 3 courses/semaine,
  mais `getStreakCetteSemaine()` (services/jalons.js) ne fait que compter les courses —
  aucune fonction ne crédite réellement quoi que ce soit, et le wallet client n'existe
  plus depuis la Session 10. Texte extrait en i18n (mention "wallet" retirée) mais la
  fonctionnalité annoncée reste probablement fantôme. À trancher avec Cedric : vrai
  crédit (sur quoi ?), récompense non-monétaire via les points fidélité existants, ou
  suppression de la bannière.
- Prochaine étape : finir les 5 composants restants, puis vérification finale B1/B3
  (grep global + diff clés), puis B4 (sélecteur de langue déjà vu câblé dans
  ProfilScreen.js lors d'une session antérieure — revérifier + détection langue système
  au premier lancement), puis clore le sprint (mise à jour ETAT_DU_PROJET_2026-07-05.md
  et CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md, SPRINT_2.md, commit — pas de
  SPRINT_3.md avant que A+B soient réellement clos, consigne Cedric).

Session 8 (2026-07-03) — Audit complet + corrections sécurité :
- Rapport : DIAGNOSTIC_AUDIT_2026-07-03.md + CORRECTIONS_2026-07-03.md
- 🔴 C1 corrigé : `admin_crediter_tc` était appelable par n'importe qui (crédit TC
  illimité gratuit). Migration 085 : contrôle is_admin() + REVOKE PUBLIC.
- 🔴 C2 corrigé : commission 20% contournable (montant fourni par le client,
  débit best-effort). Migration 085 : `debiter_commission_tc(p_course_id)` dérive
  la commission du prix STOCKÉ, idempotent, intégré atomiquement dans
  `confirmer_livraison`. Client (tokensTC.js, NavigationScreen, offlineQueue) aligné.
- 🟠 OTP contournable corrigé : la policy `courses_update` autorisait un TR à passer
  une course en 'terminee' en direct (sans OTP), online et offline. Migration 085 :
  trigger `trg_courses_protege` (bloque terminee hors confirmer_livraison + fige
  prix_fcfa et otp_livraison pour les non-admins) + policy `courses_admin_update`.
- 🟠 H2 : livraison hors ligne rejoue désormais `confirmer_livraison` avec OTP
  (plus de MAJ_STATUT_COURSE→terminee sans code).
- 🟡 M4 : séquestre retiré de confirmer_livraison ; import orphelin PaiementScreen
  retiré ; 6 écrans financiers = code mort hors bundle (suppression fichiers à faire).
- 🟡 M2 : Galet CTA 48→52px (petit 40→44). M5 : heure nuit défaut 20h→22h (prix.js).
- 🟡 M3 : 28 hex doublons de tokens → colors.* (hors #ffffff et cartes/WebView).
- ⚠️ Migration 085 + Edge Functions restent À DÉPLOYER sur Supabase (SQL Editor).
- ⚠️ Vérif syntaxe via bash faussée par lag du mount (lecture tronquée) ; fichiers
  validés via l'outil Read (authoritatif) — édits intacts.
- 🐛 CRASH corrigé (post-M3) : le nettoyage couleurs avait inséré `colors.laterite`
  dans `Sillon.js` qui importe la palette aliasée (`colors as staticColors`) →
  `ReferenceError: Property 'colors' doesn't exist` au démarrage (Sillon = champ de
  saisie monté partout). Fix : `staticColors.laterite`. Leçon : vérifier le BINDING,
  pas juste la syntaxe. Seul fichier à import aliasé du repo.
- 🚀 Système COURSES PROGRAMMÉES (migration 086 + doc COURSES_PROGRAMMEES_2026-07-03.md) :
  · Constat : une course programmée sans TR n'était JAMAIS matchée (diffusion TR
    désactivée à la création ; cron J-45 ne gère que les courses déjà attribuées).
  · Décisions Cedric : pré-réservation dès la création · escalade admin si aucun TR ·
    matching client borné 30 km · diffusion TR à la création.
  · Implémenté : `auto_selectionner_tr` gère programmée→'programmee_confirmee' ;
    sweep pg_cron étendu ; `escalader_courses_programmees()` (flag besoin_assignation_admin
    + alerte admin après 10 min) ; `assigner_tr_manuel()` (admin) ; `transporteurs_proches()`
    borné 30 km ; ConfirmationScreen diffuse + matching_demarre_at ; matching.js
    `transporteursLesPlusProches()`.
  · RESTE : UI admin « À assigner », affichage carte du TR le plus proche, élargissement
    progressif du rayon (cron Edge). Migration 086 + Edge functions À DÉPLOYER.
- ⚠️ Bug ouvert : bouton « Payer » (achat TC, MesTokensScreen) ne fait rien — hypothèse
  Edge Function notchpay-init-achat-tc non déployée / secrets Notchpay absents côté
  Supabase. En attente du log Metro de Cedric.


Session 1 (2026-05-14 — Matin) :
- Création des 7 agents IA (CLAUDE.md v1)
- Création des 4 présentations PowerPoint
- Design system Atelier CAARCO intégré
- 13 décisions stratégiques identifiées (non tranchées)

Session 2 (2026-05-14 — Après-midi) :
- Stack technique arrêtée : Supabase + Expo + Moneroo
- 13 décisions stratégiques TOUTES TRANCHÉES
- Super prompt CLAUDE.md v2 créé (Sections 1-13)
- GUIDE_SESSION.md + GUIDE_COWORK.md créés
- Documents 1-4 produits (CDC, Contrat, CGU, One-pager)

Session 3 (2026-05-21) :
- Scan complet du projet — réalité bien plus avancée que MEMORY.md
- ~80-85% de l'application codée (54 écrans, 18 composants, 16 services,
  5 Edge Functions, 35 migrations SQL)
- Fonctionnalités bonus découvertes : Wallet, Parrainage, Points/Fidélité,
  Chat temps réel, Packs abonnement, Reçus PDF, Tutoriels first-run
- MEMORY.md mis à jour avec l'état réel
- Questions ouvertes identifiées : auth (mot de passe vs OTP), prix.js,
  onboarding, eas.json

Session 4 (2026-05-22) :
- 3 bugs corrigés :
  1. AccueilScreen — reprise de course après reconnexion client (hasRecoveredRef + useFocusEffect)
  2. TableauBordScreen — GPS watchPositionAsync (remplace setInterval) + toggle retry
  3. notifier-transporteurs — filtre TR inactifs (gte derniere_position 10 min)
- Build APK release LOCAL réussi (Gradle 8.13 + AGP 8.12.0)
  · Root cause build : autolinking.json avait chemins C:\CAARCO (ancien emplacement)
    → supprimé, Gradle régénère avec D:\CAARCO correctement
- APK 52.4 MB installé directement sur téléphone via ADB
- ⚠️ notifier-transporteurs NON REDÉPLOYÉE sur Supabase (fix local uniquement)
- ⚠️ APK trop lourd : 52.4 MB (cible < 30 MB pour Play Store)

Session 6 (2026-05-31 → 2026-06-01) — Site web CAARCO :
- Design : icônes véhicules Lucide (nere), PageHero animé, AnimatedSection fix, Navbar adaptive
- Contenu enrichi : 4 usages (livraison / déménagement / logistique / ponctuel)
- CMS Google Sheets : 120+ clés, cache 5 min prod / 0 sec dev, parser CSV robuste
- Composants : Services, Stats, AvantagesClients, AvantagesTransporteurs, Temoignages, CtaDownload → tous liés au Sheet
- Images : URLs dynamiques depuis Sheet (Google Drive, Imgur, Cloudinary)
- Contact + Footer : coordonnées dynamiques depuis Sheet
- Mockup téléphone Hero : restauré en version JSX animée (cards course/GPS/OTP)

Session 5 (2026-05-25) — Suite audit sécurité :
- Migration 039 : colonne methode_paiement sur courses + contrainte transactions_wallet corrigée (ajout 'recette')
- Alarme sonore implémentée (expo-av, assets/sounds/alarme_course.mp3, audio.js)
  · Bug corrigé : jouerAlarme() doit être appelée HORS du setCourses() updater (React 19 — pure updater)
  · coursesVuesRef (useRef Set) pour dédupliquer les INSERTs Realtime
- Vérification wallet insuffisant pour courses en espèces (20% commission) dans TableauBordScreen
- Optimisations performance : Metro inlineRequires, Gradle parallel+caching, abiFilters sans x86_64, babel remove-console
- Audit sécurité complet réalisé — 5 failles corrigées :
  1. ✅ supabase.js : AsyncStorage → SecureStore (JWT chiffré dans Keychain/Keystore)
  2. ✅ moneroo-webhook : HMAC maintenant obligatoire (fail-secure si secret absent)
  3. ✅ PaiementScreen + RechargeRapideScreen : URL WebView validée par hostname exact (anti-spoofing)
  4. ✅ initier-recharge : montant max 2 000 000 XAF ajouté
  5. ✅ initier-paiement : montant max 5 000 000 XAF + vérification prix côté DB (anti-falsification)
- ⚠️ Edge Functions modifiées localement mais NON REDÉPLOYÉES (npx supabase login requis)

Session 10 (2026-07-05, soir) — Nettoyage git + Sprint 1 (sécurité serveur) :
- Audit complet du 5/07 (matin) : ETAT_DU_PROJET, ECRANS_APPLICATION, FONCTIONNEMENT_COURSES,
  BACKOFFICE_ADMIN, CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md (contient le Master Prompt
  de retrofit en Partie B — c'est le document de référence pour les sprints suivants)
- Nettoyage git préalable (arbre trouvé très désynchronisé) :
  · node_modules/ et .expo/ étaient suivis par git dans App/ malgré un .gitignore correct
    jamais commité → untrack (git rm --cached), fichiers gardés sur disque
  · 3 secrets réels trouvés en clair, jamais commités (donc pas de rotation nécessaire) :
    .env.production.backup (service_role + token d'accès Supabase), .env.demo (service_role
    démo), deploy-078.ps1 (token d'accès Supabase en dur) → tous ajoutés au .gitignore
  · ~12 fichiers fantômes vides supprimés (NOW(), dateMax, {, npx, supabase.removeChannel(canal)…)
    — résidus d'un collage de code JS/SQL dans un terminal, sans rapport avec le travail réel
  · Migrations 077-091 + une bonne partie de src/ (écrans admin, composants, i18n) n'avaient
    JAMAIS été commitées → tout resynchronisé en un commit propre
- Sprint 1 (voir CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md §0.4) fait côté code :
  · annulerCourse() route par changer_statut_course (plus d'UPDATE direct) ; trigger
    courses_protege_update étendu : une course en_cours ne peut plus changer de statut hors
    RPC de confiance (migration 092)
  · Minimum jetons 100→1000, paliers 1000/2500/5000/10000/25000 (client + Edge Function)
  · Table audit_admin (écriture seule) + câblage sur crédit jetons, suppression de compte,
    reset (par compte + total), changement de tarifs, résolution de litige (migration 093)
    → a aussi corrigé 2 boutons admin cassés découverts en cours de route : suppression de
    compte (aucune policy RLS n'autorisait le DELETE direct) et reset par compte (RPC
    accordée au service_role seulement, jamais appelable depuis l'app)
  · Reset total encadré : saisie "SUPPRIMER" (vérifiée aussi côté serveur) + exclusion du
    build de production via EXPO_PUBLIC_APP_ENV
  · 2FA TOTP admin natif Supabase (migration 094) : écran SecuriteAdminScreen (QR rendu
    localement via WebView — jamais envoyé à un service tiers comme QRCodeView le fait pour
    d'autres usages), défi à la connexion (MFAChallengeScreen), admin_aal_suffisant() dans
    les 4 fonctions critiques. Zéro risque de verrouillage : un compte sans facteur activé
    n'est jamais bloqué.
- ⚠️ Comme la 085 (Session précédente), les migrations 092/093/094 sont écrites mais PAS
  déployées sur le Supabase de production. Prochaine session : les exécuter (SQL Editor,
  dans l'ordre) + redéployer notchpay-init-achat-tc.
- SPRINT_2.md créé (conformité Play Store : suppression des 6 écrans financiers morts +
  code mort de sélection manuelle + tranchage des dossiers supabase/ ; puis extraction i18n
  FR/EN complète). Prochaine étape après le déploiement Supabase ci-dessus.
- Consigne Cedric : tous les briefs/résumés/rapports doivent être en français désormais.
- Consigne Cedric : raccourcis de build cdd/ct/crd/crt/prod (voir mémoire Claude Code).

Session 9 (2026-07-04) — Déménagement du projet :
- Projet déplacé (copié) : D:\CAARCO → D:\Mon projet\CAARCO
  · ⚠️ L'ancien dossier D:\CAARCO existe ENCORE (copie 4 Go) — à supprimer après vérification
- Scripts corrigés (chemins en dur → $PSScriptRoot, insensible aux futurs déplacements) :
  · build-release-usb.ps1, build-debug.ps1 (pointait encore sur C:\CAARCO !),
    CLEANUP-SCRIPT.ps1, scripts/capture-auto.ps1, scripts/capture-ecrans.ps1
- Caches purgés au nouvel emplacement (contenaient les chemins D:\CAARCO) :
  · App/android/build (incl. autolinking.json — même root cause que Session 4),
    App/android/app/build, App/android/.gradle, App/.expo
  → Gradle régénère tout au prochain build
- newArchEnabled=false → pas de CMake/ninja, l'espace dans "Mon projet" ne gêne pas Gradle

---

## ⚠️ PIÈGES À ÉVITER

❌ Calculer le prix côté client → faille de sécurité critique
❌ Décimaux dans les montants FCFA → arrondir au 50 supérieur
❌ Clé API Moneroo côté client React Native → Edge Function uniquement
❌ Clé SUPABASE_SERVICE_ROLE_KEY côté client → Edge Function uniquement
❌ GPS en clair en base → suppression automatique 30 jours
❌ Routes Supabase sans RLS → accès non autorisé
❌ Présupposer connexion stable → réseau variable au Cameroun (MTN/Orange)
❌ Hardcoder les couleurs → utiliser les tokens de App/theme.js
❌ Angles vifs (border-radius:0) → principe "galet"
❌ Marcellus sur le body → uniquement les titres display
❌ Modifier le statut connexion des transporteurs depuis AuthContext
   → TRs contrôlent eux-mêmes via le toggle TableauBordScreen

---

## 📌 NOTES IMPORTANTES

- App/theme.js = source de vérité design (PAS styles/AtlierCaarco.ts)
- Design/caarco_theme.js = version complète du design system
- CarteLeaflet = carte OSM dans WebView (OSRM pour le routage)
- Tutoriel first-run implémenté sur AccueilScreen, TableauBordScreen, SuiviScreen
- Expo SDK 55 (pas 54 comme dans CLAUDE.md)
- React 19.2.0 (nouvelle version)
- Les utilisateurs cibles ont des Android mid-range (Tecno, Itel, Samsung A)
- Cameroun : réseau MTN + Orange dominant
- Moneroo : methode 'orange_money' → 'orange_cm', 'mtn_mobile_money' → 'mtn_cm'
- EAS Build : eas.json à créer avant de pouvoir générer un APK
