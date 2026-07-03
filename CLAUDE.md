# CLAUDE.md — CAARCO SUPER AGENT
# Version 4.0 — Application mobile + Site web
# Cedric Timene — Cameroun — Juin 2026
# Stack app : Supabase + React Native Expo + Notchpay (Tokens de Course)
# Stack web : Next.js 16 + Tailwind CSS v4 + framer-motion + Google Sheets CMS

═══════════════════════════════════════════════════════════════════
  PROTOCOLE DE DÉMARRAGE OBLIGATOIRE — LIRE EN PREMIER
═══════════════════════════════════════════════════════════════════

À CHAQUE SESSION, dans cet ordre :

1. Lire ce fichier (CLAUDE.md) en entier
2. Lire /MEMORY.md en entier
3. Scanner le projet (voir Section 3)
4. Annoncer :
   "✅ CAARCO chargé | App: Supabase+Expo | Web: Next.js+Sheets |
    Dernière session: [date] | En cours: [tâche] | 
    Prochaine étape: [étape suivante]"
5. Poser UNE seule question si un point bloquant est détecté

À LA FIN DE CHAQUE SESSION :
- Mettre à jour MEMORY.md
- Annoncer : "💾 Session sauvegardée. Prochaine fois on reprend : [étape]"

Règle absolue : JAMAIS commencer à coder sans avoir complété les étapes 1-4.

═══════════════════════════════════════════════════════════════════


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 1 — STACK TECHNIQUE OFFICIELLE
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```
Frontend Mobile   : React Native 0.81.5 + Expo SDK 54 (bare workflow)
Backend / DB      : Supabase (PostgreSQL + PostGIS + Auth + Storage + Edge Functions)
Authentification  : Supabase Auth + OTP 4 chiffres généré en app
Tokens de Course  : Notchpay (MTN/Orange Money) — achat TC uniquement pour les TR
                    1 TC = 1 FCFA | min 500 TC | boutons rapides 5K/10K/25K/50K/100K
                    TC déduites à la livraison (20% commission) — non retirables
Paiement client   : DIRECT en espèces ou Mobile Money au TR (aucune transaction dans l'app)
Cartographie      : CarteLeaflet (Leaflet 1.9.4 dans WebView) — 100% GRATUIT, sans clé API
Tuiles OSM        : tile.openstreetmap.org — 100% gratuit
Géocodage         : Nominatim (OpenStreetMap) — 100% gratuit, sans clé API
Routage           : OSRM public (router.project-osrm.org) — 100% gratuit, sans clé API
Notifications     : Expo Push Notifications (FCM Android / APNs iOS)
Build & Deploy    : Gradle local (bare workflow) → EAS Build pour production
Stores            : Play Store (Android V1) → App Store (iOS dans 3 mois)
OTP               : Code 4 chiffres généré côté serveur (Edge Function), affiché au client
                    (pas de SMS provider externe)
Monnaie           : XAF exclusivement (entiers, jamais de décimaux)
Langue            : Français uniquement (V1)
Design system     : Atelier CAARCO (voir Section 5)

⚠️  MAPBOX = SUPPRIMÉ (token révoqué, aucune référence dans le code)
⚠️  ORS = SUPPRIMÉ (remplacé par OSRM gratuit)
⚠️  react-native-maps = SUPPRIMÉ (remplacé par CarteLeaflet/WebView)
⚠️  MONEROO = SUPPRIMÉ (remplacé par Notchpay — achat TC uniquement)
⚠️  SÉQUESTRE = SUPPRIMÉ (refusé Play Store — activité financière non agréée)
⚠️  PORTEFEUILLE CLIENT = SUPPRIMÉ (aucune rétention d'argent côté client)
```

### Variables d'environnement (.env) — JAMAIS dans le code
```
EXPO_PUBLIC_SUPABASE_URL=        # URL du projet Supabase
EXPO_PUBLIC_SUPABASE_ANON_KEY=   # Clé publique Supabase
SUPABASE_SERVICE_ROLE_KEY=       # Clé privée (Edge Functions uniquement)
NOTCHPAY_API_KEY=                # Clé API Notchpay (Edge Functions uniquement — JAMAIS côté client)
NOTCHPAY_WEBHOOK_SECRET=         # Secret pour valider les webhooks Notchpay
EXPO_PUBLIC_APP_ENV=             # development | staging | production
# SUPPRIMÉS : EXPO_PUBLIC_MAPBOX_TOKEN, EXPO_PUBLIC_ORS_KEY, MONEROO_API_KEY, MONEROO_WEBHOOK_SECRET
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 1B — SITE WEB CAARCO (D:\CAARCO-WEB)
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```
Dossier     : D:\CAARCO-WEB (SÉPARÉ de D:\CAARCO — ne pas mélanger)
Framework   : Next.js 16.2.6 (App Router, TypeScript)
Style       : Tailwind CSS v4 + tokens Atelier CAARCO (globals.css)
Animation   : framer-motion 12.x
Icônes      : lucide-react 1.17
CMS         : Google Sheets → content.ts → toutes les pages (voir ci-dessous)
```

### CMS Google Sheets — Architecture
```
src/lib/content.ts    → getContent() async, SiteContent type, DEFAULT_CONTENT
.env.local            → SHEET_CSV_URL (URL CSV Google Sheets publiée)
next.config.ts        → remotePatterns (drive.google.com, imgur, cloudinary, unsplash)
```

Google Sheet actif : ID `14kZ8nLZgO7eRqGDrDgVovn28uDm17TINYsBiWO3idXE`
→ 120+ clés : hero, services, stats, comment_ca_marche, avantages_clients,
  avantages_transporteurs, temoignages, cta_download, faq, tarifs, clients,
  transporteurs, contact, footer, images

Cache : `revalidate: 0` dev (changements immédiats) / `300` prod (5 min ISR)

### Pages (11 routes)
```
/                   → Home (toutes sections connectées au Sheet)
/clients            → Pour expéditeurs & entreprises
/transporteurs      → Pour transporteurs
/comment-ca-marche  → Guide complet 4+4 étapes
/tarifs             → 4 véhicules + formule de prix
/faq                → 4 catégories, 11 Q&A
/contact            → Coordonnées + formulaire (données du Sheet)
/telecharger        → Page conversion Play Store (animée)
/a-propos           → Mission + valeurs CAARCO
/cgu                → Conditions générales
/confidentialite    → Politique confidentialité
```

### Contenu — 4 usages officiels CAARCO
```
1. Livraison express     (colis, documents, pharmacie)
2. Déménagement          (particuliers, meubles, électroménager)
3. Logistique entreprises (boutiques, restaurants, PME)
4. Transport ponctuel    (de A à B, sans abonnement)
```
⚠️ Ne pas réduire CAARCO à "livraison de colis" — toujours mentionner les 4 usages.

### Images depuis Google Sheets
Clés `images.*` dans le Sheet → URLs Google Drive / Imgur / Cloudinary
Format Google Drive : `https://drive.google.com/uc?id=FILE_ID`
(fichier partagé "Tout le monde avec le lien" → Lecteur)

### Variables d'environnement site web (.env.local)
```
SHEET_CSV_URL=    # URL CSV du Google Sheet publié (Fichier → Publier → CSV)
NEXT_PUBLIC_APP_ENV=development
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 2 — DÉCISIONS STRATÉGIQUES (TOUTES PRISES)
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ces décisions sont FINALES. Ne pas demander de confirmation.
Les appliquer directement dans le code.

```
SÉQUESTRE          = DÉSACTIVÉ (refusé Google Play — activité financière non agréée)
PORTEFEUILLE CL    = DÉSACTIVÉ (aucune rétention d'argent côté client)
TOKENS DE COURSE   = ACTIVÉ — seul système monétaire dans l'app (côté TR uniquement)
                     TR achète TC via Notchpay → TC déduites à la livraison (20%)
                     Client paie TR directement en espèces ou Mobile Money
CASH-ON-DELIVERY   = N/A — paiement direct client→TR sans passer par l'app
ASSURANCE COLIS    = Plafond interne 50 000 FCFA
COOPTATION         = Pas de pénalité pour le parrain
GÉOFENCING         = Cameroun uniquement au lancement V1
PRODUITS INTERDITS = Liste statique + validation admin humaine (IA en V2)
PRICING DYNAMIQUE  = PAS de surge pricing en V1
COMMISSION         = 20% en TC déduites du solde TR à la livraison
                     Math.round(prix_fcfa * 0.20) TC débitées
TRANSIT CHINE-AFR  = EXCLU définitivement du scope CAARCO
TVA / OHADA        = Immatriculation OHADA obligatoire avant lancement
HÉBERGEMENT DATA   = Supabase EU (Frankfurt) — RGPD compliant
USSD FALLBACK      = EXCLU de la V1
PARTENARIATS       = Solliciter MTN + Orange + GIE transporteurs
```

### Formule de prix (côté serveur uniquement — Supabase Edge Function)
```typescript
const PRIX_BASE_FCFA     = 500;
const PRIX_PAR_KM        = 250;
const FRAIS_SERVICE_TAUX = 0.10;
const MAJORATION_NUIT    = 0.20;  // 22h → 5h
const MINIMUM_FCFA       = 1000;

function calculerPrix(distanceKm: number, isNuit: boolean): number {
  const sousTotal = PRIX_BASE_FCFA + (distanceKm * PRIX_PAR_KM);
  const avecService = sousTotal * (1 + FRAIS_SERVICE_TAUX);
  const avecMajoration = isNuit ? avecService * (1 + MAJORATION_NUIT) : avecService;
  return Math.max(MINIMUM_FCFA, Math.ceil(avecMajoration / 50) * 50);
}
// ❌ JAMAIS appeler cette fonction depuis le client
// ✅ UNIQUEMENT depuis une Supabase Edge Function
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 3 — PROTOCOLE DE SCAN DU PROJET
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Au démarrage de chaque session, scanner le projet dans cet ordre :

### ÉTAPE 1 — Cartographie des fichiers
```bash
# Lister la structure du projet
find . -type f -name "*.tsx" -o -name "*.ts" -o -name "*.js" | 
  grep -v node_modules | grep -v .expo | sort

# Vérifier les dépendances installées
cat package.json | grep -E '"dependencies"|"devDependencies"' -A 50
```

### ÉTAPE 2 — Analyse de ce qui est fait
Pour chaque fichier trouvé, déterminer :
- ✅ TERMINÉ : fonctionnel, testé, conforme à la spec
- 🔄 EN COURS : démarré mais incomplet
- ❌ BUGUÉ : erreur détectée
- 📋 MANQUANT : prévu dans le CDC mais pas encore créé

### ÉTAPE 3 — Rapport de scan
Produire ce rapport avant de continuer :

```
═══════════════════════════════════════
SCAN CAARCO — [date et heure]
═══════════════════════════════════════

ÉCRANS MOBILE
├── Onboarding
│   ├── [✅/🔄/❌/📋] SplashScreen
│   ├── [✅/🔄/❌/📋] OnboardingScreen
│   ├── [✅/🔄/❌/📋] RoleSelectionScreen
│   └── [✅/🔄/❌/📋] AuthScreen (OTP)
│
├── Client
│   ├── [✅/🔄/❌/📋] HomeScreen (carte + bouton commander)
│   ├── [✅/🔄/❌/📋] BookingScreen (saisie adresses)
│   ├── [✅/🔄/❌/📋] ColisDetailsScreen (type + poids)
│   ├── [✅/🔄/❌/📋] PrixEstimationScreen
│   ├── [✅/🔄/❌/📋] PaiementScreen (Moneroo)
│   ├── [✅/🔄/❌/📋] MatchingScreen (recherche transporteur)
│   ├── [✅/🔄/❌/📋] TrackingScreen (suivi GPS)
│   ├── [✅/🔄/❌/📋] OTPScreen (code livraison)
│   ├── [✅/🔄/❌/📋] NotationScreen (étoiles)
│   ├── [✅/🔄/❌/📋] HistoriqueScreen
│   └── [✅/🔄/❌/📋] ProfilClientScreen
│
├── Transporteur
│   ├── [✅/🔄/❌/📋] DashboardTransporteurScreen
│   ├── [✅/🔄/❌/📋] CourseIncomingScreen (accept/refus)
│   ├── [✅/🔄/❌/📋] CourseActiveScreen (navigation)
│   ├── [✅/🔄/❌/📋] OTPValidationScreen (saisie code)
│   ├── [✅/🔄/❌/📋] GainsScreen
│   └── [✅/🔄/❌/📋] ProfilTransporteurScreen
│
└── Admin (web)
    ├── [✅/🔄/❌/📋] DashboardAdminScreen
    ├── [✅/🔄/❌/📋] CoursesListScreen
    ├── [✅/🔄/❌/📋] KYCValidationScreen
    ├── [✅/🔄/❌/📋] LitigesScreen
    └── [✅/🔄/❌/📋] ConfigurationScreen

BACKEND (Supabase)
├── [✅/🔄/❌/📋] Tables créées (users, courses, transactions_tc, notations)
├── [✅/🔄/❌/📋] Migration 082 appliquée (solde_tc + transactions_tc + RPCs)
├── [✅/🔄/❌/📋] PostGIS activé (calcul distance GPS)
├── [✅/🔄/❌/📋] RLS (Row Level Security) configuré
├── [✅/🔄/❌/📋] Edge Functions (pricing, OTP, matching)
└── [✅/🔄/❌/📋] Webhooks Notchpay configurés (achat TC)

TOKENS DE COURSE (TC)
├── [✅/🔄/❌/📋] Compte Notchpay créé + API Key
├── [✅/🔄/❌/📋] MesTokensScreen (achat TC 4 étapes + historique)
├── [✅/🔄/❌/📋] Edge Function notchpay-init-achat-tc
├── [✅/🔄/❌/📋] Edge Function notchpay-webhook (crédit TC idempotent)
└── [✅/🔄/❌/📋] Alerte solde < 1 000 TC (TableauBord + MesTokens)

DÉPLOIEMENT
├── [✅/🔄/❌/📋] Compte Expo EAS configuré
├── [✅/🔄/❌/📋] Compte Google Play Console créé
└── [✅/🔄/❌/📋] Build de test généré

BUGS IDENTIFIÉS
└── [liste les bugs trouvés avec fichier:ligne]

PROCHAINE ÉTAPE RECOMMANDÉE
└── [module à développer en priorité]
═══════════════════════════════════════
```

### ÉTAPE 4 — Correction des bugs avant de continuer
Si des bugs sont détectés, les corriger EN PREMIER avant toute nouvelle feature.
Format de correction :
```
🐛 BUG TROUVÉ : [fichier:ligne — description]
🔧 CORRECTION : [explication de la correction]
✅ APRÈS FIX  : [comment vérifier que c'est corrigé]
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 4 — ROADMAP DE DÉVELOPPEMENT
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### PHASE 0 — Fondations (à faire en premier)
```
0.1  Initialiser le projet Expo  →  npx create-expo-app caarco --template
0.2  Configurer Supabase         →  créer projet, activer PostGIS, créer tables
0.3  Configurer EAS Build        →  eas init, eas.json
0.4  Installer les dépendances   →  voir liste Section 7
0.5  Créer la structure dossiers →  voir arborescence ci-dessous
0.6  Configurer les tokens       →  AtlierCaarco.ts (design system)
0.7  Créer les types TypeScript  →  types/index.ts
```

### Structure de dossiers cible
```
/caarco/
├── app/                    # Expo Router (navigation)
│   ├── (auth)/            # Écrans non authentifiés
│   │   ├── index.tsx      # Splash + onboarding
│   │   ├── role.tsx       # Choix de rôle
│   │   └── otp.tsx        # Authentification OTP
│   ├── (client)/          # Écrans client
│   │   ├── index.tsx      # Home (carte)
│   │   ├── booking.tsx    # Saisie course
│   │   ├── colis.tsx      # Détails colis
│   │   ├── prix.tsx       # Estimation prix
│   │   ├── paiement.tsx   # Moneroo checkout
│   │   ├── matching.tsx   # Recherche transporteur
│   │   ├── tracking.tsx   # Suivi GPS
│   │   ├── otp.tsx        # Code livraison
│   │   ├── notation.tsx   # Évaluation
│   │   ├── historique.tsx # Mes courses
│   │   └── profil.tsx     # Mon profil
│   ├── (transporteur)/    # Écrans transporteur
│   │   ├── index.tsx      # Dashboard
│   │   ├── incoming.tsx   # Nouvelle course
│   │   ├── active.tsx     # Course en cours
│   │   ├── otp.tsx        # Saisir code OTP
│   │   ├── gains.tsx      # Mes gains
│   │   └── profil.tsx     # Mon profil
│   └── (admin)/           # Back-office web
│       ├── index.tsx      # Dashboard
│       ├── courses.tsx    # Gestion courses
│       ├── kyc.tsx        # Validation KYC
│       ├── litiges.tsx    # Litiges
│       └── config.tsx     # Configuration
├── components/            # Composants réutilisables
│   ├── ui/               # Boutons, cards, badges...
│   │   ├── CButton.tsx   # Bouton Atelier CAARCO
│   │   ├── CCard.tsx     # Carte avec galet
│   │   ├── StatutBadge.tsx
│   │   ├── PrixDisplay.tsx  # Montant FCFA (JetBrains Mono)
│   │   └── MapView.tsx
│   ├── course/           # Composants métier
│   │   ├── CourseCard.tsx
│   │   ├── TransporteurCard.tsx
│   │   └── OTPDisplay.tsx
│   └── layout/
│       ├── SafeScreen.tsx
│       └── BottomNav.tsx
├── lib/                  # Services et utilitaires
│   ├── supabase.ts      # Client Supabase
│   ├── tokensTC.js      # Service Tokens de Course (achat, solde, débit commission)
│   ├── location.ts      # GPS et géolocalisation
│   ├── notifications.ts # Expo Push Notifications
│   ├── otp.ts           # Génération OTP 4 chiffres
│   └── formatters.ts    # formatFCFA, formatDate...
├── hooks/               # Hooks React personnalisés
│   ├── useAuth.ts       # Authentification Supabase
│   ├── useCourse.ts     # Gestion des courses
│   ├── useLocation.ts   # GPS en temps réel
│   └── useNotifications.ts
├── stores/              # État global (Zustand)
│   ├── authStore.ts     # Utilisateur connecté
│   ├── courseStore.ts   # Course active
│   └── uiStore.ts       # Loading, erreurs...
├── types/               # TypeScript types
│   └── index.ts         # Course, User, Paiement...
├── constants/           # Constantes métier
│   └── caarco.ts        # Prix, statuts, rôles...
├── styles/              # Design system
│   └── AtlierCaarco.ts  # Tokens officiels
├── supabase/            # Config Supabase locale
│   ├── migrations/      # SQL migrations
│   └── functions/       # Edge Functions
│       ├── calculate-price/
│       ├── generate-otp/
│       ├── match-transporter/
│       ├── notchpay-init-achat-tc/
│       └── notchpay-webhook/
├── assets/              # Images, icônes, polices
├── CLAUDE.md            # Ce fichier
├── MEMORY.md            # Mémoire persistante
├── app.json             # Config Expo
├── eas.json             # Config EAS Build
└── .env                 # Variables d'environnement
```

### PHASE 1 — Authentification (Sprint 1, ~3 jours)
```
1.1  Supabase Auth configuré (voir Section 8 — Tutorial Supabase)
1.2  SplashScreen + OnboardingScreen (3 slides)
1.3  RoleSelectionScreen (Client ou Transporteur)
1.4  Génération OTP 4 chiffres dans l'app
1.5  AuthScreen — saisie numéro + OTP
1.6  Navigation conditionnelle selon le rôle
1.7  Persistance de session (AsyncStorage sécurisé)

⚠️ CHECKPOINT 1.x : Avant de coder l'auth, montrer le flux à Cedric
```

### PHASE 2 — Interface Client (Sprint 2-3, ~7 jours)
```
2.1  HomeScreen avec carte OpenStreetMap
2.2  BookingScreen — saisie adresse (autocomplétion Nominatim)
2.3  ColisDetailsScreen — type + poids estimé
2.4  Appel Edge Function → calcul prix GPS + affichage FCFA
2.5  PrixEstimationScreen — confirmation avant commande
2.6  ConfirmationScreen — choix mode paiement (espèces / mobile_money) — informatif uniquement
2.7  MatchingScreen — animation recherche transporteur
2.8  TrackingScreen — position GPS temps réel (Supabase Realtime)
2.9  OTPScreen — affichage code 4 chiffres au client
2.10 NotationScreen — étoiles + commentaire
2.11 HistoriqueScreen — liste des courses passées
2.12 ProfilClientScreen — nom, historique, fidélité

⚠️ CHECKPOINT 2.4 : Montrer la formule de prix à Cedric avant validation
```

### PHASE 3 — Interface Transporteur (Sprint 4, ~5 jours)
```
3.1  KYC Onboarding — upload photos (Supabase Storage)
3.2  DashboardTransporteurScreen — toggle disponible/indispo
3.3  Incoming course — notification + card 60s timer
3.4  Accepter / Refuser avec feedback visuel
3.5  Navigation GPS vers le client
3.6  Confirmation chargement → statut EN_COURS
3.7  OTPValidationScreen — saisir le code OTP du client (modal dans NavigationScreen)
3.8  Confirmation livraison → débit TC commission (Math.round(prix * 0.20))
3.9  GainsScreen / MesTokensScreen — solde TC + historique transactions

⚠️ CHECKPOINT 3.1 : Valider le flow KYC avec Cedric
```

### PHASE 4 — Back-office Admin (Sprint 5, ~4 jours)
```
4.1  DashboardAdmin — KPIs temps réel
4.2  Liste des courses avec filtres
4.3  KYCValidationScreen — valider/rejeter les transporteurs
4.4  Gestion des litiges (décision admin)
4.5  Configuration des tarifs (modifier la formule)
4.6  Rapports et exports CSV

⚠️ CHECKPOINT 4.3 : Valider le processus KYC avec Cedric
```

### PHASE 5 — Tests et déploiement (Sprint 6, ~5 jours)
```
5.1  Tests end-to-end sur Android physique (Tecno/Samsung A)
5.2  Tests achat TC Notchpay (sandbox → production)
5.3  Security review complet (/security --pre-deploy)
5.4  Optimisation performance (bundle < 30MB APK)
5.5  Créer compte Google Play Console (voir Section 9)
5.6  EAS Build → APK de test interne
5.7  EAS Build → Release AAB pour Play Store
5.8  Soumission Play Store (voir Section 9)

⚠️ CHECKPOINT 5.5 : Guider Cedric étape par étape pour le compte Play Store
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 5 — DESIGN SYSTEM ATELIER CAARCO
## (Appliquer sur CHAQUE composant UI sans exception)
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```typescript
// styles/AtlierCaarco.ts — SOURCE DE VÉRITÉ UNIQUE

export const Couleurs = {
  // Pigments officiels
  foret:        '#1f3b2a',  // Primaire / Marque
  foret90:      '#284a36',
  foret30:      '#b4c4b9',
  bambou:       '#3d6b4a',  // Action / Boutons
  bambouSoft:   '#cfdbcf',
  nere:         '#c89441',  // Accent / Prix / Highlights
  nereSoft:     '#f1e3c2',
  laterite:     '#b8612e',  // Alertes / Erreurs / Annulation
  lateriteSoft: '#f1d6c3',
  manioc:       '#fbf9f3',  // Fond principal
  brume:        '#ece9e0',  // Fond secondaire / Cartes
  cendre:       '#6b6f68',  // Texte secondaire
  charbon:      '#1d2420',  // Texte principal
  nuit:         '#0f1411',  // Fond sombre
  blanc:        '#FFFFFF',
  
  // Statuts de course
  statutRecherche:  '#c89441',  // EN_RECHERCHE → Néré (or)
  statutConfirme:   '#3d6b4a',  // CONFIRMÉE → Bambou
  statutEnCours:    '#1f3b2a',  // EN_COURS → Forêt
  statutTermine:    '#cfdbcf',  // TERMINÉE → BambouSoft
  statutAnnule:     '#b8612e',  // ANNULÉE → Latérite
  statutLitige:     '#b8612e',  // LITIGE → Latérite
};

export const Polices = {
  display: 'Marcellus_400Regular',      // H1, H2, titres, montants héros
  body:    'PlusJakartaSans_400Regular', // Tout le reste
  bodyBold:'PlusJakartaSans_700Bold',
  mono:    'JetBrainsMono_400Regular',  // Montants FCFA, codes OTP
};

export const Espacements = {
  pas:     4,   // micro
  pause:   8,   // XS
  souffle: 12,  // SM
  arret:   16,  // MD
  couloir: 24,  // LG
  patio:   32,  // XL
  parvis:  48,  // 2XL
};

export const Galets = {
  xs:   4,
  sm:   8,
  md:   14,
  lg:   24,
  full: 9999,   // Boutons, chips, badges
};

export const Ombres = {
  voilage: {
    shadowColor: '#1f3b2a',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  canopee: {
    shadowColor: '#1f3b2a',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 12,
    elevation: 6,
  },
};
```

### Règles de design CAARCO — OBLIGATOIRES
```
✅ Fond principal toujours : Couleurs.manioc (#fbf9f3) — jamais blanc pur
✅ Boutons CTA : Couleurs.bambou + Galets.full + height 52px minimum
✅ Titres : Police display (Marcellus), uniquement les H1/H2
✅ Montants FCFA : Police mono (JetBrains Mono) + format "2 500 FCFA"
✅ Toujours utiliser les variables, jamais hardcoder les couleurs
✅ 1 action principale par écran (principe "Limpide d'abord")
✅ Contraste minimum WCAG AA (4.5:1) — lisibilité soleil de midi
✅ Taille tactile minimum : 52px height pour les boutons
❌ JAMAIS border-radius: 0 — toujours utiliser les Galets
❌ JAMAIS de décimaux dans les montants FCFA
```

### Composants UI à créer en PREMIER (avant les écrans)
```typescript
// Ordre de création obligatoire :
// 1. CButton.tsx     → bouton primaire (bambou + galet full)
// 2. CCard.tsx       → carte (manioc + voilage + galet md)
// 3. StatutBadge.tsx → badge coloré selon le statut
// 4. PrixDisplay.tsx → montant FCFA (mono + néré)
// 5. OTPDisplay.tsx  → code 4 chiffres (grands caractères)
// 6. MapView.tsx     → carte OSM wrappée
// 7. CInput.tsx      → champ de saisie (galet sm)
// 8. BottomNav.tsx   → navigation bas (3 onglets selon rôle)
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 6 — AGENTS IA INTÉGRÉS
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### AGENT SUPERPOWERS (actif en permanence)
Avant tout code :
PHASE 1 — Reformuler la demande + identifier les fichiers impactés
PHASE 2 — Planifier les sous-tâches + estimer la complexité
PHASE 3 — Coder une sous-tâche à la fois + expliquer
PHASE 4 — Valider : tokens Atelier ✓ | XAF entiers ✓ | RLS Supabase ✓

### AGENT CODE REVIEW (sur demande : /review [fichier])
5 analyses en parallèle :
[A] Bug Hunter CAARCO → prix côté serveur? OTP valide? GPS fallback?
[B] Best Practices → nommage français, constantes, formatFCFA()
[C] Architecture → séparation rôles, Edge Functions, RLS Supabase
[D] Performance → bundle size, lazy loading, cache Supabase
[E] Project Rules → tokens Atelier, XAF entiers, 1 action/écran

### AGENT SECURITY (/security --pre-deploy)
Priorités CAARCO :
- RLS Supabase actif sur toutes les tables
- Prix calculé côté serveur (Edge Function) uniquement
- OTP expirant (15 minutes max)
- Clé Notchpay JAMAIS côté client (Edge Function uniquement)
- Webhook Notchpay validé (HMAC)
- crediter_tc_achat idempotent (vérification notchpay_ref en DB)
- GPS chiffré au repos
- Aucune rétention d'argent client — aucune table wallet/séquestre active

### AGENT MEMORY (automatique)
Début session : lire MEMORY.md
Fin session : mettre à jour MEMORY.md
/mem status → résumé rapide
/mem decisions → voir les décisions prises

### AGENT STACK (activation automatique)
"Quelle lib pour la carte ?"
→ Database Architect + Mobile Specialist
"On est prêts pour le Play Store ?"
→ Release Manager + QA + Security + DevOps


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 7 — DÉPENDANCES À INSTALLER
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```bash
# Initialiser le projet
npx create-expo-app caarco --template expo-template-blank-typescript
cd caarco

# Supabase
npx expo install @supabase/supabase-js
npx expo install @react-native-async-storage/async-storage
npx expo install expo-secure-store

# Navigation (Expo Router)
npx expo install expo-router react-native-safe-area-context
npx expo install react-native-screens

# Cartographie
npx expo install react-native-maps
npx expo install expo-location

# UI & Polices
npx expo install @expo-google-fonts/plus-jakarta-sans
npx expo install expo-font

# Notchpay TC checkout via WebView
npx expo install react-native-webview

# Notifications
npx expo install expo-notifications
npx expo install expo-device

# État global
npm install zustand

# Images / Storage
npx expo install expo-image-picker
npx expo install expo-file-system

# Utilitaires
npx expo install expo-linking
npm install date-fns

# TypeScript (si non inclus)
npm install --save-dev typescript @types/react
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 8 — TUTORIAL SUPABASE (ACTIONS EXTERNES)
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### ÉTAPE A — Créer le projet Supabase
```
1. Aller sur : https://supabase.com
2. Cliquer "Start your project"
3. Créer un compte (ou se connecter avec GitHub)
4. Cliquer "New project"
5. Remplir :
   - Name: caarco-production
   - Database Password: [générer un mot de passe fort]
   - Region: EU West (Ireland) ou EU Central (Frankfurt)
     → CHOISIR Frankfurt pour RGPD + proximité Afrique
6. Cliquer "Create new project"
7. Attendre 2-3 minutes que le projet soit prêt
8. Copier dans .env :
   - Project URL → EXPO_PUBLIC_SUPABASE_URL
   - anon/public key → EXPO_PUBLIC_SUPABASE_ANON_KEY
   - service_role key → SUPABASE_SERVICE_ROLE_KEY
```

### ÉTAPE B — Activer PostGIS (calcul GPS)
```sql
-- Dans Supabase Dashboard → SQL Editor → New Query :
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Vérifier que PostGIS est actif :
SELECT postgis_version();
-- Doit afficher quelque chose comme "3.4 USE_GEOS=1..."
```

### ÉTAPE C — Créer les tables (SQL à coller dans Supabase SQL Editor)
```sql
-- ═══ TABLE : users ═══
CREATE TABLE public.users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         TEXT NOT NULL UNIQUE,
  nom           TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('client', 'transporteur', 'admin')),
  statut        TEXT NOT NULL DEFAULT 'actif' 
                  CHECK (statut IN ('actif', 'suspendu', 'banni', 'kyc_en_attente')),
  score_notation DECIMAL(3,2) DEFAULT 5.00,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ═══ TABLE : courses ═══
CREATE TABLE public.courses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  transporteur_id   UUID REFERENCES users(id),
  statut            TEXT NOT NULL DEFAULT 'DEMANDE'
                      CHECK (statut IN (
                        'DEMANDE','EN_RECHERCHE','CONFIRMEE',
                        'EN_COURS','TERMINEE','ANNULEE','LITIGE'
                      )),
  type_transport    TEXT NOT NULL 
                      CHECK (type_transport IN (
                        'COLIS','DEMENAGEMENT','ELECTROMENAGER',
                        'MATERIAUX','AGRICOLE','AUTRE'
                      )),
  origine_lat       DECIMAL(10,7) NOT NULL,
  origine_lng       DECIMAL(10,7) NOT NULL,
  destination_lat   DECIMAL(10,7) NOT NULL,
  destination_lng   DECIMAL(10,7) NOT NULL,
  origine_adresse   TEXT,
  destination_adresse TEXT,
  distance_km       DECIMAL(8,3) NOT NULL,
  prix_fcfa         INTEGER NOT NULL,
  otp_code          TEXT,
  otp_expires_at    TIMESTAMPTZ,
  paiement_statut   TEXT DEFAULT 'EN_ATTENTE'
                      CHECK (paiement_statut IN (
                        'EN_ATTENTE','SEQUESTRE','LIBERE','REMBOURSE'
                      )),
  moneroo_payment_id TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at      TIMESTAMPTZ,
  completed_at      TIMESTAMPTZ
);

-- ═══ TABLE : notations ═══
CREATE TABLE public.notations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id   UUID REFERENCES courses(id) ON DELETE CASCADE,
  noter_id    UUID REFERENCES users(id),
  note_id     UUID REFERENCES users(id),
  score       INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  commentaire TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, noter_id)
);

-- ═══ TABLE : paiements ═══
CREATE TABLE public.paiements (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id           UUID REFERENCES courses(id) ON DELETE CASCADE,
  montant_fcfa        INTEGER NOT NULL,
  commission_fcfa     INTEGER NOT NULL,
  net_transporteur    INTEGER NOT NULL,
  statut              TEXT NOT NULL DEFAULT 'EN_ATTENTE'
                        CHECK (statut IN (
                          'EN_ATTENTE','INITIE','SEQUESTRE',
                          'LIBERE','REMBOURSE','ECHOUE'
                        )),
  moneroo_payment_id  TEXT UNIQUE,
  moneroo_checkout_url TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  libere_at           TIMESTAMPTZ
);

-- ═══ TABLE : positions_gps ═══
-- (positions temps réel, supprimées après 30 jours)
CREATE TABLE public.positions_gps (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  course_id       UUID REFERENCES courses(id),
  lat             DECIMAL(10,7) NOT NULL,
  lng             DECIMAL(10,7) NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-suppression après 30 jours (RGPD)
SELECT cron.schedule(
  'purge-positions-gps',
  '0 2 * * *',
  $$DELETE FROM positions_gps WHERE created_at < NOW() - INTERVAL '30 days'$$
);

-- ═══ TABLE : transporteurs_kyc ═══
CREATE TABLE public.transporteurs_kyc (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  type_vehicule     TEXT NOT NULL 
                      CHECK (type_vehicule IN (
                        'MOTO_TAXI','TRICYCLE','PICK_UP',
                        'CAMION_LEGER','CAMION_LOURD','CAMIONNETTE'
                      )),
  immatriculation   TEXT,
  cni_url           TEXT,      -- Supabase Storage
  permis_url        TEXT,      -- Supabase Storage
  vehicule_url      TEXT[],    -- Supabase Storage (tableau de photos)
  statut_kyc        TEXT DEFAULT 'EN_ATTENTE'
                      CHECK (statut_kyc IN (
                        'EN_ATTENTE','APPROUVE','REJETE',
                        'INFOS_MANQUANTES'
                      )),
  motif_rejet       TEXT,
  valide_par        UUID REFERENCES users(id),
  valide_at         TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);
```

### ÉTAPE D — Activer Row Level Security (RLS)
```sql
-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notations ENABLE ROW LEVEL SECURITY;
ALTER TABLE paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions_gps ENABLE ROW LEVEL SECURITY;
ALTER TABLE transporteurs_kyc ENABLE ROW LEVEL SECURITY;

-- Politique : chaque utilisateur ne voit que ses propres données
CREATE POLICY "users_own_data" ON users
  FOR ALL USING (auth.uid() = id);

-- Client voit uniquement SES courses
CREATE POLICY "client_own_courses" ON courses
  FOR SELECT USING (auth.uid() = client_id);

-- Transporteur voit SES courses assignées
CREATE POLICY "transporteur_own_courses" ON courses
  FOR SELECT USING (auth.uid() = transporteur_id);

-- Admin voit tout (via service_role key uniquement)
-- Les politiques admin sont gérées par les Edge Functions
-- avec la clé service_role (jamais exposée côté client)
```

### ÉTAPE E — Créer les Edge Functions
```
Dans Supabase Dashboard :
1. Aller dans "Edge Functions"
2. Cliquer "New Function"
3. Créer ces 4 fonctions :

   → calculate-price           (calcul prix GPS)
   → generate-otp              (OTP 4 chiffres)
   → match-transporter         (algorithme de matching)
   → notchpay-init-achat-tc    (initier achat TC via Notchpay)
   → notchpay-webhook          (webhook Notchpay → créditer TC)

Ou via CLI Supabase :
supabase functions new calculate-price
supabase functions new generate-otp
supabase functions new match-transporter
supabase functions new notchpay-init-achat-tc
supabase functions new notchpay-webhook
```

### Code des Edge Functions
```typescript
// supabase/functions/calculate-price/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const PRIX_BASE = 500;
const PRIX_KM   = 250;
const FRAIS     = 0.10;
const NUIT      = 0.20;
const MIN       = 1000;

function haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2)**2 +
    Math.cos(lat1*Math.PI/180) * Math.cos(lat2*Math.PI/180) * Math.sin(dLng/2)**2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

serve(async (req) => {
  const { origineLat, origineLng, destLat, destLng } = await req.json();
  const dist = haversine(origineLat, origineLng, destLat, destLng);
  const heure = new Date().getHours();
  const isNuit = heure >= 22 || heure < 5;
  
  const sousTotal = PRIX_BASE + dist * PRIX_KM;
  const avecService = sousTotal * (1 + FRAIS);
  const prix = isNuit ? avecService * (1 + NUIT) : avecService;
  const final = Math.max(MIN, Math.ceil(prix / 50) * 50);
  
  return new Response(JSON.stringify({
    distanceKm: Math.round(dist * 100) / 100,
    prixFcfa: final,
    isNuit,
    details: { sousTotal, avecService, prix }
  }), { headers: { "Content-Type": "application/json" } });
});

// ─────────────────────────────────────────────
// supabase/functions/generate-otp/index.ts
serve(async (req) => {
  const { courseId } = await req.json();
  const otp = String(Math.floor(1000 + Math.random() * 9000)); // 4 chiffres
  const expires = new Date(Date.now() + 15 * 60 * 1000); // +15 min
  
  // Stocker dans la base (via service_role)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  await supabase.from('courses').update({
    otp_code: otp,
    otp_expires_at: expires.toISOString()
  }).eq('id', courseId);
  
  return new Response(JSON.stringify({ otp, expiresAt: expires }), {
    headers: { "Content-Type": "application/json" }
  });
});
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 9 — TOKENS DE COURSE (TC) + NOTCHPAY
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Pourquoi ce système ?
```
Google Play a refusé l'app V1 car le séquestre de l'argent des clients
constitue une activité financière nécessitant une licence (organisation agréée).

Solution : CAARCO vend des Tokens de Course (TC) aux transporteurs uniquement.
- TC = crédits de service prépayés (1 TC = 1 FCFA)
- TR achète des TC avec son propre argent → MT MoMo ou Orange Money
- TC déduites à chaque livraison (20% commission)
- Aucun argent client ne transite par l'app
```

### ÉTAPE A — Créer un compte Notchpay
```
1. Aller sur : https://notchpay.co
2. Créer un compte Business
3. Remplir : nom, email, pays (Cameroun), téléphone
4. Vérifier l'email
5. Aller dans Dashboard → API Keys
6. Copier la clé publique et privée :
   NOTCHPAY_API_KEY=...       → dans .env (Edge Functions uniquement)
   NOTCHPAY_WEBHOOK_SECRET=...→ dans .env (validation webhooks)
7. Activer le mode Sandbox pour les tests
8. Activer MTN Mobile Money Cameroun (XAF)
9. Activer Orange Money Cameroun (XAF)
```

### ÉTAPE B — Flux achat TC (5 étapes dans MesTokensScreen)
```
ÉTAPE 1 — CHOIX : TR saisit la quantité de TC ou clique un bouton rapide
          Boutons : 5 000 / 10 000 / 25 000 / 50 000 / 100 000 TC
          Minimum : 500 TC

ÉTAPE 2 — RECAP : Résumé (montant FCFA = montant TC, 1:1)

ÉTAPE 3 — PAIEMENT : App appelle Edge Function notchpay-init-achat-tc
          → Edge Function crée une transaction_tc en_attente
          → Appelle Notchpay API → reçoit checkout_url
          → App ouvre checkout_url dans un WebView modal
          → TR paie via MTN MoMo / Orange Money dans le WebView
          → Notchpay redirige vers caarco://tokens-confirmes

ÉTAPE 4 — CONFIRMATION : App détecte l'URL de retour, ferme le WebView
          → Notchpay envoie webhook à notchpay-webhook Edge Function
          → Edge Function appelle RPC crediter_tc_achat (idempotent)
          → users.solde_tc += montantTC
          → App recharge le solde après 2.5s

ALERTE : Si solde_tc < 1 000 TC → bannière rouge dans TableauBord + MesTokens
```

### ÉTAPE C — Code Edge Function notchpay-init-achat-tc
```typescript
// supabase/functions/notchpay-init-achat-tc/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { transporteurId, montantTC } = await req.json();
  
  if (montantTC < 500) {
    return new Response(JSON.stringify({ error: 'Minimum 500 TC' }), { status: 400 });
  }
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  const reference = `caarco_tc_${transporteurId.slice(-8)}_${Date.now()}`;
  
  // Créer la transaction en attente (idempotence)
  await supabase.from('transactions_tc').insert({
    transporteur_id: transporteurId,
    type: 'achat',
    montant_tc: montantTC,
    notchpay_ref: reference,
    statut: 'en_attente',
  });
  
  // Appeler Notchpay
  const resp = await fetch('https://api.notchpay.co/payments/initialize', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('NOTCHPAY_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: montantTC,   // 1 TC = 1 FCFA
      currency: 'XAF',
      description: `Achat ${montantTC} Tokens de Course CAARCO`,
      reference,
      callback: 'caarco://tokens-confirmes',
      webhook: `${Deno.env.get('SUPABASE_URL')}/functions/v1/notchpay-webhook`,
    }),
  });
  
  const data = await resp.json();
  return new Response(JSON.stringify({
    checkout_url: data.authorization_url,
    reference,
  }), { headers: { 'Content-Type': 'application/json' } });
});
```

### ÉTAPE D — Code Edge Function notchpay-webhook
```typescript
// supabase/functions/notchpay-webhook/index.ts
// Appelé par Notchpay après paiement TC confirmé

serve(async (req) => {
  const payload = await req.text();
  const sig = req.headers.get('x-notchpay-signature') || '';
  
  // Valider la signature HMAC
  const secret = Deno.env.get('NOTCHPAY_WEBHOOK_SECRET')!;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey('raw', encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const mac = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
  const expected = Array.from(new Uint8Array(mac)).map(b => b.toString(16).padStart(2,'0')).join('');
  if (expected !== sig) return new Response('Unauthorized', { status: 401 });
  
  const event = JSON.parse(payload);
  if (event.event !== 'payment.complete') return new Response('OK');
  
  const reference = event.data?.reference;
  if (!reference?.startsWith('caarco_tc_')) return new Response('OK');
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  // RPC idempotente — vérifie si notchpay_ref déjà traité
  await supabase.rpc('crediter_tc_achat', { p_notchpay_ref: reference });
  
  return new Response('OK');
});
```

### ÉTAPE E — RPC Supabase (migration 082)
```sql
-- Dans App/supabase/migrations/082_systeme_tokens_tc.sql
-- (déjà créé — à appliquer dans Supabase Dashboard → SQL Editor)

-- users.solde_tc
ALTER TABLE users ADD COLUMN IF NOT EXISTS solde_tc INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD CONSTRAINT chk_solde_tc_positif CHECK (solde_tc >= 0);

-- courses.mode_paiement_client
ALTER TABLE courses ADD COLUMN IF NOT EXISTS mode_paiement_client TEXT
  CHECK (mode_paiement_client IN ('especes', 'mobile_money'));

-- Table transactions_tc
CREATE TABLE IF NOT EXISTS transactions_tc (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transporteur_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type            TEXT NOT NULL CHECK (type IN ('achat', 'commission')),
  montant_tc      INTEGER NOT NULL CHECK (montant_tc > 0),
  course_id       UUID REFERENCES courses(id) ON DELETE SET NULL,
  notchpay_ref    TEXT,
  statut          TEXT NOT NULL DEFAULT 'confirme'
                    CHECK (statut IN ('en_attente', 'confirme', 'echoue')),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- RPC : crediter_tc_achat (idempotent)
CREATE OR REPLACE FUNCTION crediter_tc_achat(p_notchpay_ref TEXT)
RETURNS void AS $$
DECLARE v_tx transactions_tc%ROWTYPE;
BEGIN
  SELECT * INTO v_tx FROM transactions_tc
  WHERE notchpay_ref = p_notchpay_ref AND statut = 'en_attente' FOR UPDATE;
  IF NOT FOUND THEN RETURN; END IF; -- déjà traité ou inexistant
  UPDATE transactions_tc SET statut = 'confirme' WHERE id = v_tx.id;
  UPDATE users SET solde_tc = solde_tc + v_tx.montant_tc WHERE id = v_tx.transporteur_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC : debiter_commission_tc
CREATE OR REPLACE FUNCTION debiter_commission_tc(
  p_course_id UUID, p_transporteur_id UUID, p_commission_tc INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE users SET solde_tc = solde_tc - p_commission_tc
  WHERE id = p_transporteur_id AND solde_tc >= p_commission_tc;
  IF NOT FOUND THEN RAISE EXCEPTION 'Solde TC insuffisant'; END IF;
  INSERT INTO transactions_tc (transporteur_id, type, montant_tc, course_id, statut)
  VALUES (p_transporteur_id, 'commission', p_commission_tc, p_course_id, 'confirme');
END; $$ LANGUAGE plpgsql SECURITY DEFINER;
```

### ÉTAPE F — Tester en sandbox
```
1. Dans Notchpay Dashboard → activer "Sandbox Mode"
2. Utiliser les credentials de test fournis par Notchpay
3. Simuler un achat de 5 000 TC (MTN MoMo test)
4. Vérifier que le webhook est reçu par l'Edge Function
5. Vérifier que users.solde_tc += 5000
6. Accepter une course, livrer, saisir OTP
7. Vérifier que TC débitées = Math.round(prix * 0.20)
8. Quand tout fonctionne en sandbox → passer en production
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 10 — TUTORIAL EXPO EAS + PLAY STORE
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### ÉTAPE A — Créer le compte Expo (gratuit)
```
1. Aller sur : https://expo.dev
2. Cliquer "Sign Up"
3. Créer un compte avec ton email
4. Dans le terminal VS Code :
   npm install -g eas-cli
   eas login
   eas init          ← dans le dossier /caarco
5. Choisir "Create a new Expo project"
6. Copier le project ID dans app.json
```

### ÉTAPE B — Configurer EAS Build (eas.json)
```json
{
  "cli": { "version": ">= 8.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "android": { "buildType": "apk" }
    },
    "preview": {
      "distribution": "internal",
      "android": { "buildType": "apk" }
    },
    "production": {
      "android": { "buildType": "aab" },
      "ios": { "autoIncrement": true }
    }
  },
  "submit": {
    "production": {
      "android": {
        "serviceAccountKeyPath": "./google-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

### ÉTAPE C — Premier build Android (APK de test)
```bash
# Build APK pour test sur appareil physique
eas build --platform android --profile preview

# → EAS génère l'APK dans le cloud (5-10 minutes)
# → Un lien de téléchargement apparaît
# → Envoyer le lien sur WhatsApp à des testeurs au Cameroun
# → Installer et tester sur Tecno/Samsung A
```

### ÉTAPE D — Créer le compte Google Play Console
```
1. Aller sur : https://play.google.com/console
2. Cliquer "Créer un compte développeur"
3. Payer les frais d'inscription : 25 USD (unique, une seule fois)
4. Remplir les informations du développeur :
   - Nom : CAARCO ou Cedric Timene
   - Email : contact@caarco.cm
   - Téléphone : ton numéro Cameroun
5. Accepter les conditions d'utilisation
6. Attendre la vérification (24-48h)
7. Créer une nouvelle application :
   - Nom de l'app : CAARCO
   - Langue par défaut : Français
   - Type : Application
   - Gratuit ou Payant : Gratuit (les courses sont payées dans l'app)
```

### ÉTAPE E — Préparer la fiche Play Store
```
Éléments à préparer AVANT la soumission :

Screenshots Android (obligatoires) :
→ Minimum 2 screenshots de 1080×1920px
→ Prendre des screenshots des écrans : Accueil, Booking, Tracking

Icône de l'app :
→ 512×512px PNG
→ Fond Forêt (#1f3b2a) avec logo CAARCO (Arc + Disque Néré)

Feature Graphic (bandeau) :
→ 1024×500px
→ "CAARCO — Transport de marchandises au Cameroun"

Description courte (max 80 caractères) :
→ "Transport de marchandises rapide et sûr au Cameroun"

Description longue (max 4000 caractères) :
→ Décrire l'application, les fonctionnalités, la sécurité

Politique de confidentialité (URL) :
→ Héberger la politique sur : caarco.cm/confidentialite
→ Le document est déjà créé (Doc 3/10)

Catégorie : Transport
Tags : livraison, transport, cameroun, bafoussam
```

### ÉTAPE F — Soumettre le build AAB en production
```bash
# Build AAB (Android App Bundle) pour le Play Store
eas build --platform android --profile production

# Soumettre automatiquement au Play Store
eas submit --platform android

# Ou manuellement :
# 1. Télécharger le .aab depuis expo.dev
# 2. Dans Play Console → Production → Créer une version
# 3. Uploader le .aab
# 4. Remplir les notes de mise à jour
# 5. Lancer la revue (3-7 jours)
```

### ÉTAPE G — iOS App Store (dans 3 mois)
```
1. Créer compte Apple Developer : https://developer.apple.com
   → Frais : 99 USD/an
2. EAS Build iOS :
   eas build --platform ios --profile production
3. Soumettre via EAS Submit :
   eas submit --platform ios
4. Remplir la fiche App Store Connect
5. Revue Apple : 1-7 jours (plus stricte que Google)
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 11 — TUTORIAL NOTIFICATIONS PUSH (EXPO)
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```typescript
// lib/notifications.ts

import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { supabase } from './supabase';

// 1. Configurer le comportement des notifications
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

// 2. Demander la permission et enregistrer le token
export async function enregistrerNotifications(userId: string): Promise<void> {
  if (!Device.isDevice) return; // Pas de notifications sur simulateur
  
  const { status } = await Notifications.requestPermissionsAsync();
  if (status !== 'granted') return;
  
  const token = (await Notifications.getExpoPushTokenAsync()).data;
  
  // Sauvegarder le token dans Supabase
  await supabase.from('users').update({ 
    expo_push_token: token 
  }).eq('id', userId);
}

// 3. Envoyer une notification depuis l'Edge Function
// (dans supabase/functions/notify/index.ts)
async function envoyerNotification(expoPushToken: string, titre: string, corps: string) {
  await fetch('https://exp.host/--/api/v2/push/send', {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: expoPushToken,
      sound: 'default',
      title: titre,
      body: corps,
      data: { type: 'course_update' },
    }),
  });
}

// Notifications CAARCO à implémenter :
// - "Transporteur trouvé !" (client)
// - "Nouvelle course disponible" (transporteur)  
// - "Votre transporteur est arrivé" (client)
// - "Livraison confirmée — X TC débités" (transporteur)
// - "Achat TC confirmé — X TC créditées" (transporteur, depuis notchpay-webhook)
// - "Solde TC faible — rechargez vos tokens" (transporteur si < 1000 TC)
// - "Votre KYC a été approuvé" (transporteur)
// - "Litige ouvert — L'admin va trancher" (les deux)
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 12 — RÈGLES MÉTIER CRITIQUES
## (Ne jamais dévier de ces règles)
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```
PRIX          : Calculé côté serveur (Edge Function) UNIQUEMENT
               Jamais depuis le client React Native

OTP           : 4 chiffres générés aléatoirement dans l'Edge Function
               Affiché au client dans l'app, communiqué verbalement au transporteur
               Expire après 15 minutes
               Validé côté serveur uniquement (modal dans NavigationScreen)

TOKENS DE COURSE (TC) :
               1 TC = 1 FCFA — non retirables, non transférables, non revendables
               TR PEUT voir les courses mais NE PEUT PAS postuler si TC < commission
               TC vérifiées à l'acceptation (CourseScreen), débitées à la LIVRAISON
               Commission = Math.round(prix_fcfa * 0.20) TC
               Achat TC = Notchpay WebView → webhook → crediter_tc_achat (idempotent)
               Alerte automatique si solde_tc < 1 000 TC
               ❌ JAMAIS de retrait TC — TC = crédits de service uniquement

PAIEMENT CLIENT → TR :
               Le client paie le transporteur DIRECTEMENT (espèces ou Mobile Money)
               Aucune transaction client ne passe par l'app CAARCO
               mode_paiement_client = 'especes' | 'mobile_money' — informatif seulement

RÔLES         : Client, Transporteur, Admin — mutuellement exclusifs
               Vérifié sur chaque requête Supabase via RLS
               Admin = uniquement via service_role (jamais côté client)

MONTANTS      : TOUJOURS des entiers en FCFA ou TC (jamais de décimaux)
               Format d'affichage FCFA : "2 500 FCFA" (espace + Mono font)
               Format TC : "2 500 TC" (même règle)

GPS           : Jamais stocker en clair
               Suppression automatique après 30 jours
               Partagé seulement entre les parties d'une course active

STATUTS       : DEMANDE → EN_RECHERCHE → CONFIRMEE → EN_COURS → TERMINEE
               Transitions unidirectionnelles uniquement
               ANNULEE possible avant CONFIRMEE (gratuit) ou EN_COURS (pénalité)
```


## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 13 — COMMANDES DISPONIBLES
## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/scan           → Scanner tout le projet et produire le rapport
/scan [dossier] → Scanner un dossier spécifique
/review [fichier] → Code review complet (5 agents)
/security --full → Security review complet
/security --pre-deploy → Checklist avant Play Store
/mem status     → Résumé rapide de l'avancement
/mem update     → Ajouter une information à la mémoire
/supabase setup → Guide étape par étape Supabase
/notchpay setup → Guide étape par étape Notchpay TC (Section 9)
/build android  → Commandes EAS Build Android
/build ios      → Commandes EAS Build iOS
/deploy         → Guide complet Play Store / App Store
/next           → Quelle est la prochaine étape à faire ?
/checkpoint     → Poser une question à Cedric avant de continuer
```
