# CAARCO — Cahier des charges de reprise & Master Prompt (REV1)

Application de transport de marchandises et déménagement — Cameroun
Numerik World — Bafoussam — Juillet 2026
Basé sur l'état réel du code au 05/07/2026 (scans : ÉTAT_DU_PROJET, ÉCRANS_APPLICATION, FONCTIONNEMENT_COURSES, BACKOFFICE_ADMIN) et l'audit complet (copywriting, couleurs, fonctionnel, admin).

---

# PARTIE 0 — ÉTAT DES LIEUX ET DÉCISIONS DE REPRISE

Ce document n'est pas un cahier des charges de projet neuf : CAARCO est fonctionnellement construit (67 écrans, 31 services, 103 migrations, back-office 18 écrans). C'est un plan de **sécurisation, conformité et finition** avant lancement.

## 0.1 Ce qui existe et qu'on garde tel quel

| Acquis | Verdict |
|---|---|
| Modèle Jetons de Course (ex-TC) : client paie le transporteur en direct, CAARCO débite 20 % en jetons à la livraison | Conservé — c'est la réponse au refus Google Play, et il est réellement actif (migration 085, `confirmer_livraison` atomique) |
| Design system Atelier CAARCO (palette Forêt/Manioc/Néré/Bambou/Latérite, Marcellus + Plus Jakarta Sans + JetBrains Mono, lexique de composants français) | Conservé — identité distinctive face aux bleus/rouges tech de Gozem et Yango |
| Flux client complet (commande → prix → matching auto → suivi GPS → OTP → notation) et flux transporteur complet | Conservés |
| OTP généré par trigger DB, validé par RPC serveur, débit de commission atomique et idempotent | Conservé — bon design |
| Sélection automatique premier-arrivé-premier-servi (le choix manuel par le client est du code mort assumé) | Conservé pour V1 — simple et rapide ; le code mort de sélection manuelle sera supprimé, pas réactivé |
| Back-office admin 18 écrans, RLS actif partout, promotion admin impossible depuis l'app | Conservé |
| Messages d'erreur actionnables (« GPS imprécis (±X m) — sortez à l'extérieur… ») et explication honnête de la commission | Conservés — c'est le standard de copy à généraliser |
| Mode sombre automatique (`darkColors`) | Conservé |

## 0.2 Ce qui existe et qu'on corrige — par gravité

| Existant | Problème | Correction | Gravité |
|---|---|---|---|
| Migration `085_securite_tc_et_courses.sql` écrite mais **non exécutée en prod** ; 4 Edge Functions modifiées non redéployées | Crédit de jetons gratuit et commission contournable **exploitables en production aujourd'hui** | Exécuter 085 + redéployer `notifier-transporteurs`, `moneroo-webhook`, `initier-paiement`, `initier-recharge` + migration 086 | 🔴 Immédiat |
| Bouton « Payer » (achat de jetons) inopérant dans `MesTokensScreen` | Le chemin de revenu est cassé | Diagnostiquer (Edge Function `notchpay-init-achat-tc` non déployée ? secrets Notchpay absents ?) dans la même session Supabase que 085 | 🔴 Immédiat |
| `annulerCourse()` fait un UPDATE direct : **rien côté serveur n'empêche un client d'annuler une course `en_cours`** (le bouton est juste masqué en UI) | Un client peut annuler pendant que le transporteur roule avec ses marchandises — litige garanti, transporteur lésé | Router toute annulation par la RPC `changer_statut_course` (matrice de transitions) ; interdire `en_cours → annulee` côté client | ✅ Corrigé le 5/07 (migration 092, non déployée) |
| Paramètre `p_est_nuit` appelé côté client, absent de la signature SQL réelle de `calculer_prix` | La majoration de nuit ne s'applique probablement jamais — perte de revenu silencieuse | Vérifier sur Supabase prod ; aligner la signature ou retirer l'appel | 🔴 Sprint 1 (vérif : 5 min) |
| Minimum d'achat 5 000 jetons | Équivaut à ~16 courses moto d'avance pour la population la plus pauvre en cash de l'écosystème — friction d'entrée majeure | Palier minimum à **1 000 jetons**, boutons rapides 1 000 / 2 500 / 5 000 / 10 000 / 25 000 | ✅ Corrigé le 5/07 (Edge Function non redéployée) |
| Aucun journal d'audit admin : créditer des jetons, supprimer un compte ou remettre la base à zéro ne laisse **aucune trace** | Invérifiable le jour où un partenaire regarde les chiffres ; porte ouverte aux abus internes | Table `audit_admin` en écriture seule (qui, quoi, cible, quand), alimentée par trigger sur les actions critiques | ✅ Corrigé le 5/07 (migration 093, non déployée) |
| Pas de 2FA sur les comptes admin | Un seul mot de passe protège un compte qui peut vider l'app | Activer le MFA TOTP Supabase sur tout compte `role='admin'` | ✅ Corrigé le 5/07 (migration 094, non déployée) |
| « Remise à zéro totale des données » dans ConfigTarifsScreen | **Décision de Cedric : le bouton reste.** Désaccord maintenu et enregistré : un tap ne devrait pas pouvoir détruire une base de production | Compromis d'encadrement : confirmation par saisie du mot « SUPPRIMER », entrée obligatoire dans `audit_admin`, et exclusion du build de production par variable d'environnement au moment du lancement public | ✅ Corrigé le 5/07 (migration 093, non déployée) |
| 6 écrans du modèle financier abandonné (Wallet, Recharge, Paiement, PayerTransporteur, Retrait, Encaissement) + boutons morts vers routes supprimées | Motif de refus Play Store — Google a déjà refusé CAARCO une fois pour activité financière | Suppression physique des fichiers + des styles morts (`btnWhatsapp`…) + du code mort de sélection manuelle (`CarteCandidature`, `renderItem={null}`) | ✅ Sprint 2 (Fait) |
| Deux dossiers `supabase/` concurrents ; migrations à numéros dupliqués (056×3, 057×2…) | Risque de modifier le mauvais dossier ; ordre d'application non déterministe | Archiver l'ancien dossier **hors du repo**, documenter l'ordre réel, renuméroter à partir de maintenant | ✅ Sprint 2 (Fait) |
| « LOGIN » / « SIGN UP » en anglais ; « Tokens » anglicisme partout ; « Tricycle / Van » vs « Camionnette » pour le même palier ; « Vous avez une surprise ! » et « Merci CAARCO ! » | Copy incohérent avec le marché et deux mécaniques limite dark pattern | Fusionné dans le chantier i18n (§0.3) : chaque texte est touché une seule fois | ✅ Sprint 2 (Fait) |
| Blanc sur Néré #c89441 ≈ 2,7:1 — **échec AA** sur le CTA principal (Commencer, Se connecter, prix) | Illisible en plein soleil sur écran d'entrée de gamme — le contexte d'usage réel | Règle : texte **Charbon #1d2420 sur fond Néré** (≈ 5,9:1, conforme). Blanc sur Latérite (≈ 4,4:1) réservé aux gros textes | ✅ Sprint 3 (Fait) |
| Hex en dur éparpillés (`#e8e0d5`, `#e3ede5`, `rgba(...)`…) ; dégradés hors palette dont un **bleu** `#3d5c8a/#1e2e50` sur l'accueil ; `SplashAnimeeScreen` n'importe ni thème ni polices | Bugs garantis en mode sombre ; trahison du design system sur l'écran le plus vu | Tokenisation : grep de `#` et `rgba(` dans `src/screens/` comme test d'acceptation ; dégradés Services recomposés depuis la palette | ✅ Sprint 3 (Fait) |
| Deux splash screens (emoji-camions + camion dessiné) | Doublon, qualité inégale, les emojis varient selon les surcouches Android | Garder `SplashAnimeeScreen` (camion dessiné), supprimer `SplashScreen` emoji | ✅ Sprint 3 (Fait) |
| Aucun filtre géographique sur la diffusion des courses immédiates (rayons 5/15 km en base, jamais lus par le code) | Tolérable à Bafoussam seule ; du bruit destructeur dès la 2ᵉ ville | Lire `rayon_matching_immediate_km` dans `notifier-transporteurs` — **bloquant avant toute expansion multi-villes**, pas avant le lancement Bafoussam | 🟡 Phase 2 |
| Statuts fantômes (`brouillon`, `publiee`, `attribuee`) ; timeout UI 3 min vs expiration serveur 1h en dur | Dette de cohérence | Nettoyer la contrainte ; aligner l'expiration serveur sur le paramètre en base | 🟢 Fil de l'eau |
| Zéro test automatisé sur les flux d'argent | Régression silencieuse possible sur le revenu | 5 à 10 tests ciblés uniquement : débit atomique, idempotence, OTP, quota KYC, transitions de statut — pas une suite complète | 🟡 Sprint 4 |

## 0.3 Décision : application bilingue FR/EN — coût réel et méthode

**Décision de Cedric : CAARCO devient bilingue français/anglais** (cohérent avec le Cameroun — Nord-Ouest et Sud-Ouest anglophones, Bamenda dans les villes V2).

Réalité du code : l'infrastructure i18n existe (`t()`, `fr.js`) mais elle est **partiellement utilisée** — la majorité des textes des 67 écrans sont en dur dans les composants. Le bilinguisme n'est donc pas une traduction, c'est d'abord une **extraction** : plusieurs jours de travail mécanique. Méthode pour ne payer ce coût qu'une fois :

1. **Extraction** : toute chaîne visible passe dans `locales/fr.js` ; règle d'acceptation : grep des chaînes littérales françaises dans `src/screens/` → zéro résultat hors fichiers de langue.
2. **Corrections de copy pendant l'extraction** (on touche chaque texte une seule fois) : « Tokens » → **« Jetons »** partout (« SOLDE DE JETONS », « Acheter des jetons », « Jetons insuffisants — il manque X jetons ») ; « LOGIN »/« SIGN UP » → « Se connecter »/« Créer un compte » ; vocabulaire véhicules unifié (Moto, Voiture, Tricycle/Camionnette, Camion — un seul nom par palier, partout) ; « Vous avez une surprise ! » → annonce directe de la récompense ; « Merci CAARCO ! » → « OK ».
3. **Création de `en.js`** miroir (même nombre de clés, invariant vérifiable) — la traduction peut être assistée par IA puis relue par un locuteur anglophone camerounais (registre local : "Send a package", pas de l'anglais britannique administratif).
4. **Sélecteur de langue** dans le profil + détection de la langue système au premier lancement.
5. Le back-office admin reste **français uniquement** pour l'instant (un seul opérateur).

Séquencement honnête : l'extraction + copy FR est dans le Sprint 2 (elle fusionne avec le nettoyage pré-soumission). La livraison de l'anglais peut suivre le lancement de 2 à 4 semaines sans dommage — le marché V1 (Bafoussam, Ouest) est francophone ; l'anglais devient bloquant au moment de Bamenda.

## 0.4 Feuille de route corrigée

**Sprint 0 — Aujourd'hui (1 session, rien d'autre avant)**
1. Exécuter la migration 085 sur Supabase prod + redéployer les 4 Edge Functions + migration 086
2. Diagnostiquer et réparer le bouton « Payer » (achat de jetons)
3. Vérifier `p_est_nuit` sur la fonction `calculer_prix` de prod
4. Commiter les 5 fichiers en attente — aucun travail ne démarre sur un arbre sale

**Sprint 1 — Sécurité serveur et revenu (2–4 jours) — ✅ FAIT côté code le 5 juillet 2026 (soir), PAS ENCORE déployé en prod**
5. ✅ Annulation routée par la RPC de transitions ; `en_cours → annulee` interdit côté client (l'admin garde son bypass) — migration 092
6. ✅ Minimum d'achat à 1 000 jetons + nouveaux paliers rapides — client + Edge Function `notchpay-init-achat-tc`
7. ✅ Table `audit_admin` (écriture seule, trigger sur crédit jetons, suppression de compte, reset, changement de tarifs, résolution de litige) — migration 093
8. ✅ 2FA TOTP sur les comptes admin — migration 094 + écran Sécurité admin
9. ✅ Encadrement du reset : saisie « SUPPRIMER » + entrée d'audit (le bouton reste, décision Cedric) + exclusion des builds de production

⚠️ **Action requise avant que ces correctifs soient actifs** : exécuter `092_verrouiller_transitions_courses.sql`, `093_audit_admin.sql`, `094_mfa_admin.sql` sur le Supabase de production (SQL Editor, dans l'ordre), puis redéployer `notchpay-init-achat-tc`. Même situation que la migration 085 : écrite, pas encore appliquée.

Découvertes en cours de route (corrigées dans le même Sprint 1, hors liste initiale) :
- La suppression de compte (Transporteurs/Clients admin) ne fonctionnait pas du tout : le code faisait un `DELETE` direct qu'aucune policy RLS n'autorisait. Remplacé par une RPC `admin_supprimer_compte` (auditée).
- La remise à zéro par compte (`admin_reset_compte`) n'était accordée qu'au `service_role` — jamais appelable depuis l'app admin. Corrigé (vérification `is_admin()` + `authenticated`).
- Nettoyage git préalable nécessaire : `node_modules`/`.expo` étaient suivis par git dans `App/` malgré un `.gitignore` correct jamais commité ; trois secrets réels (clé `service_role` de prod, clé `service_role` démo, token d'accès Supabase) traînaient en clair dans des fichiers jamais commités — aucun dans l'historique git, pas de rotation nécessaire, désormais proprement ignorés.

**En parallèle dès cette semaine (délais incompressibles, indépendants du code)**
10. Créer le compte Google Play Console (25 USD) — anticiper l'exigence de test fermé des comptes personnels récents (~12 testeurs / 14 jours continus, vérifier les chiffres exacts à la création)
11. Lancer l'immatriculation OHADA
12. Démarrer le recrutement terrain des 50 transporteurs fondateurs (gares routières, syndicats moto — ils seront les testeurs du test fermé : une pierre deux coups)

**Sprint 2 — Conformité stores et i18n (1 semaine) — ✅ FAIT (7 juillet 2026)**
13. ✅ Suppression physique des 6 écrans financiers morts + boutons morts + code mort de sélection manuelle
14. ✅ Tranchage des dossiers `supabase/` + documentation de l'ordre des migrations
15. ✅ Extraction i18n complète + corrections de copy FR (§0.3, points 1–2)
16. ✅ `en.js` + sélecteur de langue (livrable en fast-follow si le calendrier serre)

**Sprint 3 — Design et lisibilité (2–3 jours) — ✅ FAIT (6 juillet 2026)**
17. ✅ Contraste : Charbon sur Néré pour tous les CTA et prix
18. ✅ Tokenisation des hex en dur + dégradés Services recomposés depuis la palette + suppression du splash emoji
19. ✅ Vérification mode sombre écran par écran (les hex en dur corrigés au point 18 sont la cause principale des bugs)

**Sprint 4 — Lancement**
20. 5–10 tests automatisés sur les flux d'argent uniquement
21. Assets store (screenshots FR, icône 512, feature graphic) ; l'optimisation APK (52 → <30 Mo) est **post-lancement**, pas bloquante
22. Test fermé avec les transporteurs fondateurs → production

**Phase 2 (après traction à Bafoussam)**
- Filtre géographique de diffusion (bloquant avant multi-villes)
- Multi-villes (Douala, Yaoundé, Bamenda — l'anglais devient obligatoire ici)
- Permissions admin granulaires (`admin_acces`, `a_acces()`, écran de gestion) — **seulement quand le premier partenaire externe existe** ; en attendant, un écran statistiques lecture seule suffit
- iOS ; Lygos en fallback paiement ; IA de validation des produits interdits

---

# PARTIE A — CAHIER DES CHARGES

## 1. Vision et positionnement

**Une phrase :** CAARCO permet à n'importe qui au Cameroun de faire transporter n'importe quoi — colis, marchandises, déménagement — par un transporteur vérifié, suivi en temps réel, sans que CAARCO ne touche jamais l'argent du client.

**Le différenciateur :** face à Gozem (super-app, moto-colis) et Yango (VTC Douala/Yaoundé), CAARCO gagne par trois choses qu'ils ne font pas : les **villes secondaires** (Bafoussam d'abord — les géants l'ignorent), le **gros volume** (déménagement, camion — leur moto-colis ne le couvre pas), et le **B2B récurrent** (commerçants, PME) qui veut traçabilité et reçus.

**La menace structurelle assumée — désintermédiation :** le client paie le transporteur en direct ; après la première course, ils peuvent traiter hors app pour éviter les 20 %. La défense n'est pas technique, elle est de valeur : flux constant de nouveaux clients pour le transporteur, protection OTP + reçu PDF en cas de litige, notation qui construit sa réputation, courses programmées, et clause du contrat transporteur. Ce risque est piloté par un KPI dédié (§7 : taux de courses répétées client↔transporteur passant par l'app).

## 2. Cibles

| Persona | Besoin | Ce que CAARCO lui vend |
|---|---|---|
| **Commerçante du marché, Bafoussam** | 2–4 livraisons/semaine, fiabilité, preuve | Transporteur vérifié, suivi, reçu PDF, historique — **cœur de cible, volume récurrent** |
| **Particulier qui déménage** | Camion + confiance, 1 fois tous les 2–3 ans | Prix transparent au km, photos du colis, OTP |
| **PME / boutique en ligne locale** | Livraisons clients externalisées | Courses programmées, facturation propre (Phase 2 : compte entreprise) |
| **Transporteur (moto → camion)** | Plus de courses, paiement immédiat | Il encaisse en direct (espèces/MoMo), CAARCO ne retient rien — argument de recrutement n°1 |

## 3. Modèle économique

- **Le client ne paie jamais CAARCO.** Paiement direct client → transporteur (espèces ou Mobile Money, hors app). `mode_paiement_client` reste informatif.
- **CAARCO vend des Jetons de Course aux transporteurs** (1 jeton = 1 FCFA) via Notchpay (MTN MoMo / Orange Money). Commission de 20 % du prix, débitée en jetons à la livraison, atomique et idempotente (migration 085).
- **Minimum d'achat : 1 000 jetons** (corrigé depuis 5 000). Paliers rapides : 1 000 / 2 500 / 5 000 / 10 000 / 25 000.
- Jetons ni retirables ni transférables — formulation existante conservée, elle est honnête et claire.
- **Recommandation en attente de décision : commission fondateurs.** 10–15 % pendant 6 mois pour les 50 premiers transporteurs — la densité vaut plus que la marge au démarrage. À trancher avant le recrutement terrain.
- Packs d'abonnement transporteur, parrainage, fidélité : conservés tels quels (déjà codés).

## 4. Langues

FR + EN (décision §0.3). Français au lancement Bafoussam ; anglais livré au plus tard avec l'ouverture de Bamenda. Registre : français simple et direct (vouvoiement, verbes d'action), anglais camerounais courant. Tout texte passe par i18n — plus aucune chaîne en dur, c'est un invariant du projet vérifié par grep.

## 5. Administration et modération

- Rôle admin binaire conservé pour V1 (un seul opérateur) — le système granulaire (`admin_acces` / `a_acces()` / rôle `admin_limite` / écran de gestion, plan validé du scan back-office) se construit **au premier partenaire externe**, pas avant. Première réponse à un actionnaire : écran statistiques lecture seule dédié.
- **Journal d'audit obligatoire dès le Sprint 1** (§0.2) — c'est le prérequis de toute transparence future, et il protège Cedric lui-même.
- 2FA TOTP sur tout compte admin.
- Reset total : conservé sur décision de Cedric, encadré (saisie « SUPPRIMER » + audit), à exclure du build de prod par variable d'environnement au lancement public.
- KYC transporteur : dispositif existant conservé (CNI + permis + photos véhicule, validation < 48h, quota 2 courses/mois sans KYC).

## 6. Sécurité serveur — règles non négociables

- Toute transition de statut de course passe par la RPC à matrice (`changer_statut_course`) ; aucun UPDATE direct de `statut` depuis le client.
- Toute valeur d'argent ou de quota (solde jetons, commission, prix, quota KYC) est décidée côté serveur ; le client affiche, il ne calcule jamais.
- Le débit de commission reste dans la transaction atomique de `confirmer_livraison` — ne jamais le déplacer.
- Webhook Notchpay : HMAC-SHA256 obligatoire (existant, conservé).
- Les actions admin critiques déclenchent une écriture `audit_admin` par trigger — pas par appel applicatif contournable.

## 7. KPIs de pilotage

| Métrique | Pourquoi |
|---|---|
| Transporteurs actifs à Bafoussam (en ligne ≥ 3 j/semaine) | La densité est la stratégie |
| Délai moyen de matching d'une course immédiate | Le produit tient ou meurt là-dessus |
| Taux de courses répétées client↔même transporteur **via l'app** | Le thermomètre de la désintermédiation |
| Ventes de jetons / semaine + solde moyen | Le revenu et la friction d'entrée |
| Part de clients commerçants (≥ 4 courses/mois) | Le cœur de cible B2B |
| Taux de litiges et no-shows | La confiance |

## 8. Stack (existante, conservée)

React Native 0.81.5 / Expo SDK 54 / Supabase (Auth téléphone + Postgres + RLS + Edge Functions + pg_cron) / Notchpay (MoMo, OM) / OSM-Leaflet / SecureStore. Un seul dossier `supabase/` actif après le Sprint 2.

---

# PARTIE B — MASTER PROMPT (RETROFIT CAARCO)

Prompt en anglais (convention Numerik World), textes d'interface via i18n FR/EN. Conçu pour **Claude Code sur le repo existant** (`D:\Mon projet\CAARCO\App`) : il transforme, il ne scaffolde pas.

---

```
# CAARCO — Retrofit & Design Master Prompt

## Context
You are working INSIDE an existing, largely complete React Native / Expo
SDK 54 codebase (67 screens, 31 services, Supabase backend with RLS and
Edge Functions, 103 SQL migrations). The active payment model is
"Jetons de Course" (prepaid credits; client pays the transporter directly,
outside the app; CAARCO debits a 20% commission in jetons at delivery,
atomically, in `confirmer_livraison`, migration 085). You are NOT
scaffolding anything new. Read before writing. Preserve working logic:
the OTP flow, the atomic commission debit, RLS policies, the realtime
course broadcast, the Atelier CAARCO components.

## Role
You are the technical lead finishing this app for launch in Bafoussam,
Cameroon. Priorities in strict order: (1) server-side safety of money and
course-state, (2) Play Store compliance (Google already rejected a
previous financial model — nothing resembling client wallets may remain),
(3) i18n FR/EN with copy fixes, (4) visual consistency and contrast.
Never add features. This is a hardening pass, not a building pass.

## Non-negotiable server rules
- Every course status change goes through the transition-matrix RPC
  `changer_statut_course`. Remove any direct `UPDATE courses SET statut`
  from client-callable paths (e.g. `annulerCourse()` in services/courses.js).
  A client must NOT be able to cancel a course that is `en_cours`.
- Money and quotas (jeton balance, commission, price, KYC quota) are
  decided server-side only. The client renders; it never computes value.
- The commission debit stays inside the `confirmer_livraison` transaction.
- Critical admin actions (credit jetons, delete account, data reset,
  tariff change, dispute resolution) write to an append-only `audit_admin`
  table via DB trigger: who, what, target, when. No update/delete policy.
- Admin accounts require TOTP MFA (Supabase native).
- The "total data reset" button stays (owner's decision) but must require
  typing the word "SUPPRIMER" to confirm, must write an audit entry, and
  must be excludable from production builds via an env flag.

## Play Store compliance pass
- Physically DELETE these orphan screens and all references/styles:
  WalletScreen, RechargeRapideScreen, PaiementScreen,
  PayerTransporteurScreen, RetraitScreen, EncaissementScreen.
- Delete dead buttons pointing to removed payment routes (AccueilScreen,
  SuiviScreen) and dead styles (btnWhatsapp).
- Delete the dead manual-selection code path (CarteCandidature,
  renderItem={null} logic in AttenteScreen) — auto-selection is the model.
- Delete SplashScreen.js (emoji trucks). Keep SplashAnimeeScreen.js as the
  single splash, refactored to import theme tokens and fonts (it currently
  hardcodes everything).

## i18n pass (merge all copy fixes here — touch each string once)
- Extract EVERY user-visible string from src/screens/ and src/components/
  into locales/fr.js. Acceptance: grep for French string literals in
  src/screens/ returns zero outside locale files.
- While extracting, apply these copy corrections:
  * "Tokens" → "Jetons" everywhere. "SOLDE TOKENS DE COURSE" →
    "SOLDE DE JETONS"; "Acheter des Tokens" → "Acheter des jetons";
    "Tokens insuffisants — il manque X TC" → "Jetons insuffisants — il
    manque X jetons". Keep the honest explainer sentences (commission,
    non-withdrawable) — reworded with "jetons".
  * "LOGIN" → key auth.choix.connexion = "Se connecter";
    "SIGN UP" → auth.choix.inscription = "Créer un compte".
  * Unify vehicle names to ONE name per tier everywhere (categories,
    services carousel, markers): Moto / Voiture / Tricycle–Camionnette /
    Camion. No more "Tricycle / Van" vs "Camionnette" mismatch.
  * "Vous avez une surprise ! Appuyez pour révéler" → state the reward
    directly ("Vous avez gagné : {récompense}"). No mystery boxes.
  * "Merci CAARCO !" button → "OK". The user never thanks the brand.
  * Keep the error-message style of the best existing strings: say what
    happened, why, and what to do, in one sentence.
- Create locales/en.js mirroring fr.js key-for-key (equal key count is a
  project invariant). Cameroonian everyday English register ("Send a
  package", "Top up your jetons"), not administrative British English.
- Language selector in profile + system-language detection on first run.
- Admin back-office screens stay French-only for now.

## Design tokens — Atelier CAARCO (existing, now enforced)
Palette: foret #1f3b2a (+90/70/30/10), bambou #3d6b4a (+soft),
nere #c89441 (+soft), laterite #b8612e (+soft), manioc #fbf9f3,
brume #ece9e0, cendre #6b6f68, charbon #1d2420, nuit #0f1411, blanc.
Fonts: Marcellus (display), Plus Jakarta Sans (body), JetBrains Mono
(FCFA amounts, OTP codes — keep this, it's a good choice).

Contrast rules (enforced, AA minimum):
- Text on nere backgrounds is CHARBON, never white (white on #c89441 is
  2.7:1 — a hard AA failure on the app's primary CTAs). Update Splash CTA,
  Connexion primary button, price accents.
- White on laterite (4.4:1) only for large text; body text on laterite
  surfaces uses charbon or switches to lateriteSoft background.
- cendre on manioc stays (4.9:1, passes).

Hardcoded-color purge:
- Replace every raw hex/rgba in src/screens/ with theme tokens (or
  documented alpha suffixes on tokens). The off-palette Services gradients
  (['#3d5c8a','#1e2e50'] blue, ['#6b2e2e','#3d1515']) are recomposed from
  palette colors — a BLUE gradient has no place in this brand.
- Acceptance: grep for '#' and 'rgba(' in src/screens/ returns zero
  matches outside theme.js (documented exceptions require a comment).
- Then verify dark mode screen-by-screen: the hardcoded hexes were the
  main cause of dark-mode bugs.

## Functional fixes (small, high-impact)
- Minimum jeton purchase: 1000 (was 5000). Quick buttons:
  1000 / 2500 / 5000 / 10000 / 25000.
- Verify/align the `p_est_nuit` parameter between the client call and the
  real SQL signature of `calculer_prix` — the night surcharge likely never
  applies in production.
- Align server-side course expiry with the DB parameter
  (delai_expiration_immediate_min) instead of the hardcoded 1h trigger.
- Remove phantom statuses (brouillon, publiee, attribuee) from the CHECK
  constraint if truly unwritten, or document why they stay.
- AccueilScreen is overloaded (stories + ad banner + reward banner +
  booking card + map + services carousel + active-course banner + CTA +
  referral banner). Do not redesign it now, but: one primary CTA
  ("Commander") — demote or merge the duplicate "Continuer →" path.

## Money-flow tests (the only tests for now)
Write 5–10 targeted tests, nothing more: commission debit is atomic and
idempotent; OTP validation rejects wrong/replayed codes; insufficient
jeton balance blocks candidature; KYC quota (2 courses/month) enforced
server-side; client cannot transition en_cours → annulee; audit_admin
receives entries on credit/delete/reset.

## Anti-patterns (reject on sight)
- Any new feature. Any client-side computation of money or status.
- Any screen, string, or style resembling client wallets/escrow.
- Raw hex values, hardcoded strings, English UI text outside en.js.
- White text on nere. Off-palette gradients. Mystery-box copy.
- Direct status UPDATEs bypassing the transition RPC.

## Process per task
State in two sentences what you are hardening and which existing logic
must survive untouched. Make the change. Run the acceptance greps
(strings, hexes) and the money-flow tests. Report what you deleted —
in this pass, deleted code is progress.
```

---

## Comment utiliser ce document

1. **Sprint 0 se fait à la main sur le Dashboard Supabase** (migration 085, Edge Functions, `p_est_nuit`) — pas avec Claude Code. C'est toi, aujourd'hui.
2. **Claude Code ensuite** : colle la Partie B en tête de session (ou en `HARDENING.md` dans le repo) et avance sprint par sprint selon §0.4. Les greps d'acceptation (chaînes en dur, hex en dur) se relancent à la fin de chaque session.
3. **Les démarches parallèles** (Play Console, OHADA, recrutement fondateurs) ne dépendent d'aucun code — elles démarrent cette semaine, sinon chaque jour de retard repousse le lancement d'un jour.

## Décisions actées dans cette révision

1. « Tokens » → « Jetons » partout (décision Cedric, appliquée au chantier i18n).
2. Application bilingue FR/EN (décision Cedric) ; extraction i18n en Sprint 2, anglais livrable en fast-follow, bloquant seulement à l'ouverture de Bamenda.
3. Reset total conservé (décision Cedric, contre recommandation — désaccord enregistré) ; encadré par saisie « SUPPRIMER » + audit + exclusion du build prod par variable d'environnement au lancement.
4. Minimum d'achat de jetons abaissé à 1 000.
5. Annulation de course verrouillée côté serveur ; matrice de transitions seule voie de changement de statut.
6. Journal d'audit admin + 2FA dès le Sprint 1.
7. Module permissions granulaires reporté au premier partenaire externe ; les 6 écrans financiers morts supprimés physiquement avant soumission.
8. Contraste : Charbon sur Néré pour tous les CTA (échec AA corrigé).
9. En attente de décision Cedric : commission fondateurs réduite (10–15 % / 6 mois) pour les 50 premiers transporteurs.
