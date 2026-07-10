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

**Sprint 4 — Lancement (en cours, détail dans `SPRINT_4.md`)**
20. ✅ Code écrit (7 juillet 2026), exécution en attente de Cedric — 5–10 tests automatisés sur les flux d'argent uniquement. Indépendant du design, peut avancer sans attendre le Sprint 4bis ci-dessous.
21. Assets store (screenshots FR, icône 512, feature graphic) — **repoussé après le Sprint 4bis** : produire des captures d'un design qui va être refondu serait du travail perdu. L'optimisation APK (52 → <30 Mo) reste post-lancement, pas bloquante.
22. Test fermé avec les transporteurs fondateurs → production — après l'item 21.

🔴 **Corrections backend urgentes, indépendantes du design** (Partie C §C.3.2) : neutraliser le trigger `after_course_terminee` → `verifier_streak_client` qui écrit encore dans `wallets`, et ajouter le contrôle de rôle manquant sur la RPC `admin_crediter_wallet_client`. Migration SQL isolée, sans dépendance avec le Sprint 4bis — à traiter dès que possible, ne pas attendre la fin de la refonte visuelle pour ça.

**Sprint 4bis — Refonte visuelle complète (décision Cedric, 08/07/2026 : avant le lancement) — voir Partie D**
Insérée avant la clôture du Sprint 4 : les items 21 et 22 ci-dessus sont repoussés après ce chantier. Périmètre, méthode et séquencement détaillés en Partie D du présent document.

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

---

# PARTIE C — GOUVERNANCE DES MAQUETTES VISUELLES (AUDIT DU DOSSIER STITCH)

Ajouté le 08/07/2026, suite à la découverte d'un dossier `vehicle_character_sheets/` (export Google Stitch : ~95 écrans en HTML/Tailwind + captures, 5 planches véhicules, 2 variantes de design tokens "Terroir Moderne"). Ce dossier n'est **pas du code** — c'est une bibliothèque de référence visuelle. Elle ne doit pas être confondue avec une spec fonctionnelle, ni être utilisée sans tri.

## C.0 Constat

En croisant le contenu réel des maquettes avec §0.1/§0.2 de ce document et l'état actuel du code (`git status` sur `App/`), un motif net apparaît : **plusieurs maquettes reproduisent, à l'identique ou presque, les 6 écrans du modèle financier aboli** listés en §0.2 et physiquement supprimés au Sprint 2 (`WalletScreen`, `RechargeRapideScreen`, `PaiementScreen`, `PayerTransporteurScreen`, `RetraitScreen`, `EncaissementScreen`). L'hypothèse la plus probable : ce pack Stitch a été généré à partir d'une version du projet antérieure au nettoyage de conformité Play Store, et n'a jamais été mis à jour depuis.

Vérification faite en marge (`git diff` sur `App/RevenusScreen.js`, retrofit en cours non commité) : **le vrai code actuel est déjà conforme** — `RevenusScreen.js` n'affiche que du récapitulatif informatif et renvoie vers "Gérer mes jetons", sans aucune promesse de virement. Le risque n'est donc pas dans le code aujourd'hui ; il est dans l'usage futur de ce dossier de maquettes comme référence de refonte visuelle sans passer par le tri ci-dessous.

## C.1 Classification complète

Légende : ❌ interdit (ne jamais implémenter, correspond à un écran déjà supprimé) · ⚠️ à vérifier avant tout usage (ambigu ou non inspecté en détail) · 🔧 à adapter (fonctionnalité réelle et conservée, maquette à corriger) · ✅ référence valide.

### ❌ Interdit — correspond aux 6 écrans du modèle aboli (§0.2), déjà supprimés du code

| Dossier maquette | Écran aboli correspondant | Preuve |
|---|---|---|
| `portefeuille_caarco_1`, `portefeuille_caarco_2` | WalletScreen | Bouton "Retirer mes gains" juxtaposé au solde TC |
| `recharge_rapide_caarco` | RechargeRapideScreen | Doublon : les paliers rapides existent déjà **dans** MesTokensScreen (§3) — un écran séparé ne doit pas revenir |
| `paiement_caarco` | PaiementScreen | Nom identique à l'écran supprimé |
| `payer_un_transporteur_caarco` | PayerTransporteurScreen | Flux "Identifier + Confirmer un paiement transporteur" via QR |
| `retrait_de_gains`, `retrait_de_gains_caarco` | RetraitScreen | "Vos revenus sont versés automatiquement sur votre compte bancaire chaque semaine" — exactement le séquestre refusé par Google Play |
| `mon_qr_d_encaissement`, `mon_qr_d_encaissement_caarco` | EncaissementScreen | Encaissement via QR — même famille que PayerTransporteur |

**Règle d'acceptation :** si une future session de design reprend un de ces 8 dossiers comme référence, c'est un signal d'alerte immédiat — traiter comme une régression Play Store, pas comme une préférence de design.

### ⚠️ À vérifier avant tout usage — contenu ambigu ou non inspecté

| Dossier maquette | Pourquoi la vigilance |
|---|---|
| `attente_du_r_glement_caarco` | Le nom évoque une attente de règlement — à confirmer qu'il s'agit d'un simple état informatif ("en attente que le client paie en direct") et non d'un écran d'escrow |
| `identification_chauffeur_qr` | Le contenu observé sous `payer_un_transporteur_caarco` mélangeait identification et paiement — un usage isolé de ce concept (vérification anti-fraude pure, sans étape de transaction) est acceptable, mais à confirmer visuellement avant reprise |
| `gestion_des_codes_promo` | Fonctionnalité non explicitement actée dans REV1 — vérifier qu'un service `codePromo` existe déjà dans `App/src/services` avant de la traiter comme une réf valide, sinon la classer comme nouvelle feature (hors scope retrofit) |
| `paiement_instructions_directes` | Probablement légitime (équivalent visuel de `mode_paiement_client` informatif, §3) — confirmer qu'aucun bouton de transaction n'y figure avant de valider |
| `mes_revenus_1`, `mes_revenus_2` | Même famille thématique que `retrait_de_gains` (❌ ci-dessus) — vérifier qu'aucune des deux variantes ne reprend la mention de virement bancaire automatique |

### 🔧 À adapter — fonctionnalité réelle et conservée (§0.1/§3), maquette à corriger avant usage

| Dossier maquette | Écran réel correspondant | Correction nécessaire |
|---|---|---|
| `packs_abonnement_transporteur` | `PacksAbonnementScreen.js` (existe déjà) | La maquette affiche la marque **"TransLogix"** au lieu de CAARCO — reste de template non nettoyé. Vérifier aussi que les paliers payants ne modifient pas le taux de commission sans décision explicite de Cedric (§3, commission fondateurs en attente de décision) |
| `classement_r_gional_caarco` | `LeaderboardScreen.js` (existe déjà) | Même bug de marque "TransLogix" → CAARCO |
| `mes_points_caarco_1`, `mes_points_caarco_2` | `PointsScreen.js` (existe déjà) | Cohérent avec la fidélité conservée (§3). **Rappel d'un bug déjà connu** (mémoire de session) : la bannière streak de `MerciScreen.js` promet "+100 XAF crédités" pour 3 courses/semaine, mais rien ne crédite ce montant côté serveur, et le wallet client n'existe plus depuis le Sprint 1 — corriger le comportement réel avec Cedric avant de retoucher le visuel, sinon on habille un bug plus proprement |
| `calendrier_marketing_admin_1`, `calendrier_marketing_admin_2` | `CalendrierActionsScreen.js` / `MarketingAdminScreen.js` (existent déjà) | Maquette **entièrement en anglais** — le back-office reste français uniquement (§0.3 point 5). Traduire intégralement avant usage |
| `mes_tokens_de_course_caarco`, `mes_tokens_de_course`, `achat_de_tokens_tc` | `MesTokensScreen.js` (existe déjà) | Globalement bien aligné (1 TC = 1 FCFA affiché correctement). Corriger le libellé d'historique "Paiement Transporteur -15 000 XAF" → doit être "Commission course #XXXX" pour ne pas suggérer un paiement de pair à pair |
| `publicit_s_in_app`, `publicit_s_in_app_admin_caarco` | `AdDetailScreen.js` / `PublicitesAdmin.js` (existent déjà) | Fonctionnalité déjà codée, maquette globalement correcte — vérifier juste la cohérence de marque sur les visuels d'exemple utilisés |

### ✅ Référence valide

Tous les écrans restants (~75) : `accueil_caarco`, `aide_support_*`, `configuration_des_tarifs_admin`, `confirmation_de_commande_caarco_1/2`, `connexion_caarco`, `cr_er_un_compte_caarco`, `d_tail_de_la_course_caarco`, `d_tails_de_l_aide_caarco`, `d_tails_de_l_annonce_1/2`, `d_tails_de_la_mission_1/2`, `d_tails_des_revenus_transporteur`, `d_tails_du_colis_caarco_1/2`, `d_tails_du_trajet`, `finances_tokens_tc_admin`, `gestion_des_litiges_admin`, `gestion_des_utilisateurs_admin`, `historique_des_commissions`, `lieux_valider_admin`, `maintenance_en_cours_caarco`, `merci_caarco`, `merci_notation_caarco`, `mes_courses_caarco_1/2`, `messagerie_caarco_1/2`, `messagerie_transporteur_caarco`, `mon_profil_caarco_1/2`, `mot_de_passe_oubli_caarco`, `navigation_livraison_1/2`, `noter_le_client_caarco`, `noter_le_transporteur`, `op_rations_live_admin*`, `param_tres_de_l_application_1/2`, `parrainage_caarco_1/2`, `planifier_un_trajet_caarco_1/2`, `profil_client_caarco`, `profil_transporteur_caarco`, `recherche_de_transporteur_caarco_1/2`, `statistiques_performance*`, `suivi_en_temps_r_el*`, `tableau_de_bord_admin_caarco`, `tableau_de_bord_transporteur`, `templates_notifications_admin`, `transporteur_trouv_caarco`, `v_rification_kyc_*`, `validation_kyc_admin`.

**Nuance :** ce verdict ✅ est établi par correspondance de nom avec les fonctionnalités déjà actées en §0.1/§3, pas par inspection visuelle individuelle de chacun. Avant d'en réutiliser un pour une refonte, un rapide contrôle visuel contre l'écran réel équivalent reste recommandé (5 secondes, pas un audit).

**Planches véhicules** (`character_sheet_for_a_*` × 5 — moto, tricycle, camion, taxi, camionnette) : ✅ assets utilisables directement, aucune logique métier.

**Design tokens** (`terroir_moderne_1/2`) : ✅ déjà exploités (les valeurs collent à `theme.js`/Atelier CAARCO). La v2 est la plus aboutie (rayons plus fins, palette tonale plus nuancée) — à préférer si le design system doit encore évoluer.

## C.2 Plan de correction — entrées 🔧 et ⚠️

Ajouté le 08/07/2026. Méthode : chaque entrée a été vérifiée contre le code réel (`grep`/lecture directe dans `App/src/`, `App/supabase/migrations/`) plutôt que par simple correspondance de nom — plusieurs verdicts de C.1 s'en trouvent affinés, dans un sens comme dans l'autre.

### 🔧 À adapter — vérification effectuée

| # | Dossier maquette | Fichier réel | Constat vérifié | Action précise | Statut |
|---|---|---|---|---|---|
| 1 | `packs_abonnement_transporteur` | `PacksAbonnementScreen.js` | Code déjà propre : aucune trace de "TransLogix", entièrement i18n (`useI18n`), tokens Atelier CAARCO. Seule la maquette HTML porte encore la marque résiduelle, dans `<title>` (ligne 6) et `<h1>` (ligne 144) de `code.html`. | Si ce dossier est un jour repris comme référence visuelle : remplacer les 2 occurrences "TransLogix" → "CAARCO" dans `vehicle_character_sheets/stitch_vehicle_character_sheets/packs_abonnement_transporteur/code.html`. Point distinct et non lié à Stitch : les paliers payants ne doivent pas modifier le taux de commission sans validation explicite (§3). | Code : **déjà fait**. Maquette : **à faire** (cosmétique, non bloquant). Commission paliers : **décision Cedric requise** (déjà en attente avant cet audit). |
| 2 | `classement_r_gional_caarco` | `LeaderboardScreen.js` | Même constat : code déjà i18n et propre. "TransLogix" présent dans `<title>` (ligne 6) et `<h1>` (ligne 136) de `code.html` uniquement. | Même correction cosmétique si la maquette est reprise : 2 occurrences dans `.../classement_r_gional_caarco/code.html`. | Code : **déjà fait**. Maquette : **à faire**. |
| 3 | `mes_points_caarco_1`, `mes_points_caarco_2` | `PointsScreen.js`, `MerciScreen.js`, `services/jalons.js` | **Bug confirmé, pas seulement supposé.** Preuves : (a) `MerciScreen.js:236` affiche en dur `t('merci.jalons.streakMsg', { n: streakCount, montant: '100' })` → "+100 XAF" pour 3 courses/semaine, sans aucun mécanisme serveur qui crédite ce montant ; (b) le type de jalon `credit_wallet` (palier 50 courses = 5000 XAF, `migrations/057_jalons_streak_vip.sql`) a une fonction de crédit qui écrit dans une table `wallets` — or cette fonction n'est appelée **nulle part** dans `App/` ni dans les Edge Functions (code mort) ; (c) plus grave : les tables `wallets`, `transactions_wallet`, `retraits` et les RPC `liberer_sequestre_course` / `admin_crediter_wallet_client` / `traiter_retrait_admin` existent toujours en base (migrations 021, 030, 032, 036, 037, 070, 074) bien que §2 du CLAUDE.md déclare "PORTEFEUILLE CLIENT = SUPPRIMÉ" et "SÉQUESTRE = SUPPRIMÉ" comme décisions finales ; (d) `libelleJalon()` dans `jalons.js:64` retourne encore le texte "+X XAF crédités" pour ce type. | (a) Retirer/neutraliser le texte "+100 XAF" du bandeau streak dans `MerciScreen.js` (et la clé i18n `merci.jalons.streakMsg`) tant qu'aucun mécanisme de crédit réel n'existe pour un client — rappel : un client CAARCO ne détient ni wallet ni TC. (b) Retirer le cas `'credit_wallet'` de `libelleJalon()` (`App/src/services/jalons.js:64`) ou le remplacer par une récompense réellement livrable (réduction %, statut VIP — les deux autres types existent déjà et fonctionnent). (c) Trancher avec Cedric le sort des tables DB orphelines (`wallets`, `transactions_wallet`, `retraits`) et RPC associées — purge en nouvelle migration, ou conservation figée en archive sans usage. Ce point (c) est une décision backend à part entière, hors du périmètre visuel Stitch — à traiter en session dédiée, pas dans une passe de maquettes. | **À faire** — décision Cedric requise sur (b) le remplacement de la récompense et (c) le sort des tables orphelines. |
| 4 | `calendrier_marketing_admin_1`, `calendrier_marketing_admin_2` | `CalendrierActionsScreen.js`, `MarketingAdminScreen.js` | Vérifié : le code réel est déjà 100% français — `MOIS_FR` français en dur, labels "Publicités"/"Campagnes"/"Codes promo", "Nouveau code promo", `formatJourFr()` en `fr-FR`. Seule la maquette Stitch (`code.html`) est entièrement en anglais. | Traduire la maquette HTML seulement si elle est un jour reprise comme référence visuelle. Non prioritaire — le back-office fonctionne déjà en français (§0.3 point 5). | Code : **déjà fait**. Maquette : **à faire**, non urgent. |
| 5 | `mes_tokens_de_course_caarco`, `mes_tokens_de_course`, `achat_de_tokens_tc` | `MesTokensScreen.js` | Vérifié : le libellé d'historique utilise déjà `t('tokens.commissionCourse')` → "Commission course" (`i18n/fr.js:1052`), à la ligne `MesTokensScreen.js:112`. Le libellé "Paiement Transporteur -15 000 XAF" signalé en C.1 **n'existe plus dans le code actuel** (recherche exhaustive dans `App/src` : 0 résultat). | Aucune. Le bug était déjà corrigé avant cet audit. | **Déjà fait.** |
| 6 | `publicit_s_in_app`, `publicit_s_in_app_admin_caarco` | `AdDetailScreen.js`, `PublicitesAdmin.js` | Aucune occurrence de "TransLogix" dans ces 2 dossiers maquette (recherche textuelle exhaustive). Le point de vigilance C.1 portait sur des visuels d'exemple (images), non vérifiables par recherche de texte. | Contrôle visuel rapide des captures des 2 dossiers (5 secondes, même nuance que pour les ✅ de C.1) — aucune correction de code nécessaire à ce stade. | **À faire** — contrôle visuel seulement, non bloquant. |

### ⚠️ Vérification des 5 écrans ambigus — résultat

| # | Dossier maquette | Verdict après vérification | Preuve | Statut |
|---|---|---|---|---|
| 1 | `attente_du_r_glement_caarco` | Pas d'écran réel correspondant dans `App/`. La clé i18n `paiementAttente` ("Paiement en attente", `fr.js:192` / `en.js:183`) existe mais n'est utilisée par **aucun** écran — orpheline. | Recherche exhaustive `App/src` : aucune correspondance de nom d'écran, clé i18n non consommée. | Rien à corriger dans le code aujourd'hui. **Décision Cedric requise** uniquement si cette maquette doit un jour devenir un vrai écran : elle devra rester un état purement informatif ("le client n'a pas encore confirmé avoir payé en direct"), jamais une logique d'escrow. |
| 2 | `identification_chauffeur_qr` | Pas d'écran réel correspondant. Le seul usage de QR code dans `App/` est `SecuriteAdminScreen.js` (activation MFA admin via `QRCodeView.js`) — sans rapport avec une identification chauffeur/anti-fraude. | Recherche `QR`/`qrcode` sur `App/src` : 2 fichiers, tous deux liés au MFA admin. | **Décision Cedric requise avant toute implémentation** — fonctionnalité hors scope actuel (absente de la Section 4 roadmap), héritage direct du concept mêlé identification+paiement de `payer_un_transporteur_caarco` (❌ aboli). Ne pas construire sans validation produit explicite. |
| 3 | `gestion_des_codes_promo` | **Confirmé : fonctionnalité réelle et déjà codée.** La table `codes_promo` existe et est utilisée en CRUD complet directement dans `MarketingAdminScreen.js` (`select` l.191, `insert` l.209, `update` l.220) — pas via un service séparé comme le supposait C.1, mais inline dans l'écran admin, cohérent avec le reste du back-office. | Lecture directe de `MarketingAdminScreen.js` + `ModalCreerCode`. | **Déjà fait.** Reclassement proposé : ⚠️ → ✅ référence valide (à reporter dans C.1 lors d'une prochaine passe de relecture). |
| 4 | `paiement_instructions_directes` | **Confirmé conforme.** Correspond à `ConfirmationScreen.js` — `mode_paiement_client` (`especes`/`mobile_money`) purement informatif, commentaire explicite dans le code : "wallet supprimé — paiement direct client→transporteur" (ligne 18). Aucun bouton de transaction. | Lecture directe `ConfirmationScreen.js` lignes 18, 75, 273, 532-573. | **Déjà fait.** Reclassement proposé : ⚠️ → ✅ référence valide. |
| 5 | `mes_revenus_1`, `mes_revenus_2` | **Confirmé conforme** (déjà établi en C.0, reconfirmé ici) — `RevenusScreen.js` n'affiche qu'un récapitulatif informatif et renvoie vers "Gérer mes jetons", aucune promesse de virement bancaire automatique. | `git diff` sur `RevenusScreen.js` (C.0) + relecture. | **Déjà fait.** Reclassement proposé : ⚠️ → ✅ référence valide. Point de vigilance résiduel : la base conserve encore les tables `wallets`/`retraits` (voir entrée 🔧 #3 ci-dessus) — `RevenusScreen.js` ne les sollicite pas, donc pas de risque actif côté client, mais à couvrir dans le même nettoyage DB à trancher avec Cedric. |

### Synthèse C.2

- **3 des 5 écrans ⚠️** (`gestion_des_codes_promo`, `paiement_instructions_directes`, `mes_revenus_1/2`) se révèlent déjà conformes après vérification — la prudence de C.1 était justifiée mais le résultat est positif.
- **2 des 5 écrans ⚠️** (`attente_du_r_glement_caarco`, `identification_chauffeur_qr`) n'ont **aucun équivalent réel dans le code** — ce ne sont ni des bugs ni des maquettes à corriger, mais des concepts à ne pas construire sans décision produit explicite de Cedric.
- **4 des 6 entrées 🔧** (`packs_abonnement_transporteur`, `classement_r_gional_caarco`, `calendrier_marketing_admin_*`, `mes_tokens_de_course_caarco`) ont un code réel déjà conforme — seule la maquette Stitch porte le défaut, correction cosmétique non bloquante.
- **1 entrée 🔧** (`mes_points_caarco_1/2`) cache un **vrai bug produit + un résidu d'architecture non anticipé** : une promesse de crédit ("+100 XAF") sans mécanisme, et des tables `wallets`/`retraits`/séquestre encore présentes en base malgré leur suppression actée au niveau applicatif. C'est le point le plus important de cette passe — nécessite une décision Cedric avant toute correction de code.
- **1 entrée 🔧** (`publicit_s_in_app*`) reste à confirmer par contrôle visuel uniquement (hors portée d'une recherche textuelle).

## C.3 Vérification croisée — bilinguisme FR/EN et modèle jetons (TC)

Ajouté le 08/07/2026. Méthode : chaque affirmation ci-dessous est vérifiée par grep/lecture directe dans `App/src`, `App/supabase/migrations` et `App/supabase/functions` — aucune ne repose sur la mémoire de session ou sur les documents d'état déjà rédigés. Un script Node jetable (aplatissement récursif des objets `fr`/`en`, non conservé dans le repo) a servi à la comparaison exhaustive des clés i18n.

### C.3.1 Bilinguisme FR/EN — état réel du Chantier B (Sprint 2)

**Parité de clés `fr.js` / `en.js` : confirmée à 100 %.**
Comparaison programmatique des deux objets exportés : **1366 clés de chaque côté, 0 clé manquante dans un sens comme dans l'autre.** La différence de nombre de lignes brutes entre les deux fichiers (`fr.js` : 1596 lignes, `en.js` : 1523 lignes) est purement cosmétique (alignement des `:`, commentaires de section) — elle ne reflète aucune divergence de contenu.

**Persistance du sélecteur de langue : confirmée fonctionnelle de bout en bout.**

| Maillon | Preuve |
|---|---|
| Colonne DB | `migrations/004_messages_profil_statut.sql:48` — `ADD COLUMN IF NOT EXISTS langue TEXT DEFAULT 'fr'` sur `users` |
| Champ autorisé en écriture | `services/auth.js:77-82` — `CHAMPS_PROFIL_AUTORISES` inclut `'langue'` |
| Écriture réelle | `ProfilScreen.js:252` — `langue` fait partie du payload `updates` envoyé à `mettreAJourProfil()` |
| Lecture au démarrage | `i18n/index.js:20-22` — `useI18n()` lit `auth.profil.langue` (fallback : langue système via `detecterLangueSysteme()` avant connexion) |

Le mémo de session ("déjà corrigé") est donc confirmé par le code, pas seulement par ouï-dire.

**⚠️ Bug confirmé : `sexe` et `date_naissance` — perte de données silencieuse, pas juste "colonnes manquantes".**

Le bug est plus grave qu'une simple absence de colonnes :

1. `ProfilScreen.js:124-125` déclare un état local `sexe`/`dateNaissance`, affiché et modifiable dans l'UI d'édition (lignes 560-585, sélecteur de sexe + date picker).
2. À la sauvegarde, `ProfilScreen.js:249-257` inclut bien `sexe` et `date_naissance` dans l'objet `updates` envoyé à `mettreAJourProfil(user.id, updates)`.
3. `services/auth.js:77-90` — `CHAMPS_PROFIL_AUTORISES` ne contient **ni `sexe` ni `date_naissance`** (liste : `nom, ville, telephone, photo_url, expo_push_token, type_vehicule, description, latitude, longitude, derniere_position, pseudo, langue`). La fonction filtre silencieusement ces deux champs avant l'`UPDATE` Supabase — **aucune erreur n'est levée**, la requête part sans eux.
4. Recherche exhaustive dans `App/supabase/migrations` (`sexe`/`date_naissance`) : **zéro résultat.** Ces colonnes n'existent nulle part en base — même si elles avaient franchi le filtre de l'étape 3, l'`UPDATE` aurait échoué avec `column does not exist`.
5. **Le vrai piège** : `ProfilScreen.js:290-291` appelle ensuite `mettreAJourProfilLocal(updates)` — et `AuthContext.js:161-163` fait `setProfil(prev => ({ ...prev, ...updates }))`, qui fusionne l'objet `updates` **complet** (avec `sexe`/`date_naissance` inclus) dans l'état React local. L'écran affiche alors le toast succès `t('profil.sauvegarde')` (ligne 294) et les valeurs saisies restent visibles à l'écran — **l'utilisateur croit que c'est enregistré**. Ce n'est qu'au prochain `rafraichirProfil()` (rechargement depuis `obtenirProfil()`, un `select('*')` sur une table sans ces colonnes) que `sexe`/`date_naissance` redeviennent `null` silencieusement, sans aucun message d'erreur à aucun moment du cycle.

**Action requise (décision Cedric)** : soit (a) ajouter `sexe`/`date_naissance` en migration + les inclure dans `CHAMPS_PROFIL_AUTORISES`, soit (b) si ces champs ne sont plus utiles au produit, les retirer de `ProfilScreen.js` pour ne pas promettre une sauvegarde qui n'arrive jamais.

### C.3.2 Modèle jetons (TC) — pas de dérive côté flux actif, mais le résidu wallet/séquestre (C.2 #3) est plus grave que prévu

**Confirmé : le flux de clôture de course réellement actif aujourd'hui est 100 % TC, sans dérive.**
`NavigationScreen.js:812` et `offlineQueue.js:94` : le seul RPC de clôture de course appelé par l'app est `confirmer_livraison(p_course_id, p_otp)`. Sa version active (`migrations/085_securite_tc_et_courses.sql:105-141`) vérifie l'OTP, passe la course à `terminee`, puis appelle uniquement `debiter_commission_tc()` — **aucun accès aux tables `paiements`/`wallets`/`retraits` dans cette fonction.**

**Confirmé mort — sans risque, à condition de ne pas le redéployer par erreur (voir plus bas) :**

| Élément | Constat | Preuve |
|---|---|---|
| RPC `terminer_livraison()` | Appelle `liberer_sequestre_course` (séquestre wallet TR) — mais n'est appelée **nulle part** dans `App/src` (seul `confirmer_livraison` l'est) | `migrations/fix_terminer_livraison.sql:25-56` ; recherche exhaustive `App/src` : 0 résultat |
| RPC `liberer_sequestre_course` (dernière version active : migration 060) | Écrit dans `wallets`/`transactions_wallet` (crédit TR + bonus parrainage) — mais n'est atteignable que via `terminer_livraison()`, elle-même morte | `migrations/060_commission_20pct.sql:16-105` |
| Edge Function `initier-recharge` | Recharge un `wallets` client via Notchpay ("Recharge portefeuille CAARCO") — jamais appelée depuis `App/src` (0 référence) | `App/supabase/functions/initier-recharge/index.ts` (fichier entier) |
| Edge Function `initier-paiement` | Fait payer le **prix de la course** par le client via Notchpay dans la table `paiements` (modèle séquestre pour le trajet lui-même) — jamais appelée depuis `App/src` | `App/supabase/functions/initier-paiement/index.ts` (fichier entier) |

D'après `ETAT_DU_PROJET_2026-07-05.md:81` (vérification directe sur le Supabase de prod le 5/07), ces deux Edge Functions figurent parmi celles **"modifiées mais jamais publiées"** au 6 juillet — elles n'auraient donc jamais été déployées en prod à ce jour. Information non re-vérifiable en direct dans cette session (pas d'accès Supabase ici) — c'est la meilleure preuve disponible.

**🔴 Le point critique — ce n'est pas que du code mort : une écriture réelle dans `wallets` a lieu aujourd'hui, à chaque course.**

En creusant au-delà de `liberer_sequestre_course` (seule piste explorée en C.2), un **second chemin, totalement indépendant, écrit dans `wallets`/`transactions_wallet` — et lui est bien dans la boucle active** :

1. `confirmer_livraison` fait `UPDATE courses SET statut = 'terminee', ...` (`085_securite_tc_et_courses.sql:130-134`).
2. Cet `UPDATE` déclenche le trigger `after_course_terminee` (`AFTER UPDATE ON courses`, créé par `057_fonctions_motivation.sql:240-244`) — un trigger générique qui se déclenche **quel que soit le code appelant**, TC ou séquestre.
3. Sa fonction `trigger_after_course_terminee()` appelle `PERFORM verifier_streak_client(NEW.client_id)` (`057_fonctions_motivation.sql:233`).
4. `verifier_streak_client` est définie deux fois — doublon de numéro de migration déjà connu (`ETAT_DU_PROJET_2026-07-05.md:85` liste "057×2" parmi les 103 doublons à risque d'ordre non déterministe) : `057_fonctions_motivation.sql:180-217` et `057_jalons_streak_vip.sql:80-112`. Peu importe laquelle gagne la course au `CREATE OR REPLACE` : **les deux versions font strictement la même chose** — à la 3ᵉ course terminée d'un client dans la semaine, `INSERT/UPDATE wallets` (création du wallet si absent, `solde_fcfa += 100`) puis `INSERT INTO transactions_wallet(..., montant_fcfa = 100, statut = 'validee')`.

**Autrement dit : la table `wallets`, censée être définitivement supprimée du modèle client (§2 CLAUDE.md), reçoit une vraie écriture FCFA à chaque fois qu'un client termine sa 3ᵉ course de la semaine — avec le code actuellement actif.** Déclenché par aucune Edge Function ni aucun écran : un trigger DB silencieux, invisible du code React Native, qui échappe donc à toute recherche limitée à `App/src`.

Nuance côté risque utilisateur : recherche exhaustive dans `App/src` de toute lecture de `wallets`/`transactions_wallet`/`retraits` → **0 résultat.** Aucun écran ne lit ni n'affiche ce solde ; le client ne voit jamais ce crédit, ne peut pas le dépenser ni le retirer (contrairement au bug "+100 XAF" de `MerciScreen.js` déjà documenté en C.2, qui lui est visible et trompeur). Ce n'est donc pas un risque *produit* immédiat — c'est un risque **d'architecture et de conformité** : la base contient une activité de crédit-client en fonctionnement, exactement le type d'activité financière qui a motivé le refus initial de Google Play, indépendamment de ce que l'app affiche.

**🔴 Deuxième découverte, distincte — faille d'autorisation sur `admin_crediter_wallet_client`, active en base.**

- `traiter_retrait_admin` (`070_wallet_solde_bonus_non_retirable.sql:96-155`) vérifie bien `IF NOT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN RAISE EXCEPTION` (ligne 111).
- `admin_crediter_wallet_client` (même fichier, version active, lignes 40-91) **ne fait aucune vérification équivalente.** `GRANT EXECUTE ... TO authenticated` (ligne 90) — appelable par **n'importe quel client ou transporteur connecté**, directement via `supabase.rpc('admin_crediter_wallet_client', { p_user_id, p_montant })`, sans passer par l'app. Le commentaire original (`037_admin_crediter_wallet_client.sql:57-58`) l'assume explicitement : *"le contrôle du rôle 'admin' est fait côté app"* — un contrôle client-side ne protège rien pour une fonction appelable directement en HTTP.
- Recherche exhaustive dans `App/src` : **0 référence** à `admin_crediter_wallet_client` — même le back-office admin ne l'utilise pas. Aucun usage légitime aujourd'hui, mais un endpoint exploitable si la migration 070 est déployée (probable : `ETAT_DU_PROJET_2026-07-05.md` confirme les migrations jusqu'à 095 appliquées au 6/07, ce qui inclut structurellement la 070 en application séquentielle standard — non re-vérifié en direct ici).

**Verdict C.3.2 : ni "code mort inoffensif à purger tranquillement", ni un simple résidu esthétique — deux points sont à corriger avant d'envisager toute purge de nettoyage.**

| Élément | Statut réel | Urgence |
|---|---|---|
| `terminer_livraison`, `liberer_sequestre_course` (via ce chemin), Edge Functions `initier-recharge`/`initier-paiement` | Mortes, non atteignables aujourd'hui | 🟡 Nettoyage normal — **mais retirer explicitement `initier-recharge` et `initier-paiement` de toute liste de "fonctions à redéployer"** (elles y figurent actuellement dans `ETAT_DU_PROJET_2026-07-05.md`) avant tout prochain déploiement groupé d'Edge Functions, pour ne pas les republier par inadvertance |
| Trigger `after_course_terminee` → `verifier_streak_client` → écriture `wallets` | **Actif, se déclenche à chaque course aujourd'hui** | 🔴 Urgent — neutraliser l'appel (retirer `verifier_streak_client` du trigger, ou vider son corps) avant tout audit Play Store / OHADA |
| `admin_crediter_wallet_client` sans contrôle serveur | **Faille d'autorisation active si la migration 070 est déployée** | 🔴 Urgent — ajouter le même contrôle `role = 'admin'` que `traiter_retrait_admin`, ou révoquer `EXECUTE` du rôle `authenticated` |

Une fois ces deux points 🔴 traités (probablement en une seule migration correctrice), le reste (tables `wallets`/`transactions_wallet`/`retraits`/`jalons_client`, RPC `liberer_sequestre_course`/`traiter_retrait_admin`/`admin_crediter_wallet_client`, Edge Functions `initier-recharge`/`initier-paiement`) peut être purgé dans une migration de nettoyage classique — décision produit de Cedric sur le calendrier, pas un blocage technique.

### Synthèse C.3

- **Bilinguisme** : Chantier B réellement clos (parité 1366/1366, sélecteur persistant confirmé de bout en bout). Un bug distinct et non lié à l'i18n subsiste sur `sexe`/`date_naissance` : perte de données silencieuse, UX trompeuse (toast de succès affiché alors que rien n'est enregistré).
- **Modèle TC** : aucune dérive côté flux actif — `confirmer_livraison` reste 100 % TC, conforme §3/§12 CLAUDE.md.
- **Résidu wallet/séquestre (C.2 #3)** : plus sérieux que "code mort" — un trigger indépendant de `liberer_sequestre_course` écrit réellement dans `wallets` à chaque semaine active d'un client, et une RPC de crédit wallet est exploitable sans contrôle de rôle serveur. Les deux sont à corriger en priorité, avant toute purge de nettoyage et avant tout futur redéploiement groupé d'Edge Functions.

## C.4 Règle de gouvernance permanente — tri obligatoire de toute maquette IA avant usage

Ajouté le 08/07/2026. Cette règle transforme le travail ponctuel de C.1-C.3 en procédure permanente, pour qu'un futur export de maquettes (Stitch ou tout autre outil de génération IA) ne puisse plus glisser dans le code sans passer par le même tri — et pour que la découverte de C.3.2 (un trigger DB actif + une RPC exploitable, pas du "code mort inoffensif") ne se reproduise pas silencieusement avec un nouveau lot de maquettes.

### C.4.1 Déclencheur — qu'est-ce qui active la procédure

La procédure ci-dessous est obligatoire dès que l'une de ces conditions est vraie :
- un nouveau dossier de maquettes apparaît dans le repo (détectable via `git status` sur du contenu non suivi, comme `vehicle_character_sheets/` l'a été le 08/07/2026) ;
- Cedric mentionne un nouvel export à intégrer (Stitch ou tout autre outil : Figma AI, v0, Galileo, etc.) ;
- une session de refonte visuelle s'apprête à citer un dossier de maquettes — même déjà présent dans le repo — comme référence de design.

Dans les trois cas : **aucune maquette non triée ne doit être ouverte comme référence de design avant que les étapes C.4.3 soient complètes.** "Non trié" = absent de la grille de classification du CDC (actuellement C.1, étendue par toute future passe équivalente).

### C.4.2 Qui fait le tri, et quand

| Rôle | Responsabilité |
|---|---|
| **IA (Claude)** | Exécute le tri complet en autonomie : classification ❌/⚠️/🔧/✅ contre la grille C.1, avec vérification du code réel (pas seulement correspondance de nom — méthode C.2/C.3 : `grep`/lecture directe dans `App/src`, `App/supabase/migrations`, `App/supabase/functions`). Consigne le résultat dans le CDC (nouvelle sous-section, horodatée), avec preuve écrite pour chaque entrée. |
| **Cedric** | Tranche uniquement les entrées ⚠️ et les décisions produit qui en découlent (ex. C.2 #3 : sort des tables `wallets` orphelines — décision encore en attente). Cedric n'exécute pas le tri lui-même. |

**Moment obligatoire :** à l'import (première apparition du dossier dans le repo) — jamais après coup, jamais seulement "à la première utilisation". Si un dossier déjà trié est repris comme référence après une longue pause, un contrôle rapide (5 secondes, comme la nuance déjà actée en C.1 pour les ✅) suffit **sauf si §0.2 a été étendu entre-temps** (voir C.4.4) — dans ce cas, retrier intégralement contre la liste à jour.

**Interdiction explicite :** un dossier de maquettes non trié ne doit apparaître dans aucun prompt de refonte visuelle, aucun commit de code d'écran, ni aucune capture partagée comme référence — qu'il s'agisse d'un export Stitch ou de tout autre outil.

### C.4.3 Procédure de tri (5 étapes, reproductibles)

1. **Lister** les dossiers du nouvel export (`Glob`/`ls` sur le dossier racine de l'export).
2. **Comparer chaque dossier** contre trois références, dans cet ordre :
   - la liste des fonctionnalités abolies (§0.2 — actuellement 6 écrans : `WalletScreen`, `RechargeRapideScreen`, `PaiementScreen`, `PayerTransporteurScreen`, `RetraitScreen`, `EncaissementScreen`, plus tout ajout futur) ;
   - la liste des écrans réels existants dans `App/src` (correspondance de nom **et** de contenu — une maquette au nom neutre peut quand même reproduire une fonctionnalité abolie, voir C.4.4) ;
   - un grep textuel des mots-clés à risque sur le contenu de la maquette (`code.html` ou équivalent) : `solde`, `wallet`, `portefeuille`, `retrait`, `virement`, `séquestre`, `escrow`, `encaissement`, et toute combinaison `QR` + `paiement`.
3. **Classer** chaque dossier selon la grille C.1 (❌/⚠️/🔧/✅), avec la preuve textuelle qui justifie le verdict (citation exacte, ligne si possible) — jamais un verdict sans preuve écrite.
4. **Consigner** le résultat dans une nouvelle sous-section du CDC (horodatée), pas seulement dans la conversation — un tri qui ne survit pas à la session ne compte pas.
5. **Remonter** chaque ⚠️ à Cedric individuellement, avec la question précise à trancher (pas "est-ce que c'est ok ?" générique) — sur le modèle de C.2 (`attente_du_r_glement_caarco`, `identification_chauffeur_qr`).

### C.4.4 Garde-fou anti-réincarnation — un nom différent n'est jamais une preuve de nouveauté

C.1-C.3 ont montré que le risque réel ne se limite pas à "une maquette au nom identique à un écran aboli" (facile à repérer), mais couvre aussi :
- un **résidu cosmétique** dans une maquette dont le code applicatif réel est déjà propre (ex. `packs_abonnement_transporteur`, marque "TransLogix" oubliée) — pas un danger, mais à corriger avant réutilisation ;
- un **concept fonctionnel** hérité d'un écran aboli et recombiné sous un autre nom (ex. `identification_chauffeur_qr`, héritage direct du QR de paiement de `payer_un_transporteur_caarco` ❌) ;
- pire, un **résidu d'architecture bien plus profond que le visuel** : C.3.2 a montré qu'une fonctionnalité peut être supprimée de l'app (aucun écran, aucun bouton) tout en restant active en base (trigger `after_course_terminee` écrivant dans `wallets`, RPC `admin_crediter_wallet_client` exploitable sans contrôle de rôle) — invisible à un tri purement visuel des maquettes.

**Règle : classer par CAPACITÉ, jamais par nom.** Avant d'implémenter un nouvel écran — quel que soit son nom, qu'il vienne d'une maquette triée ✅ ou d'une demande orale de Cedric — répondre explicitement à cette question et consigner la réponse : *« Cet écran donne-t-il au client ou au transporteur un solde consultable, une fonction de retrait, un virement automatique, un paiement de pair à pair passant par l'app, ou une forme de séquestre ? »* Si la réponse est oui à n'importe quel item, l'écran est ❌ interdit au sens de §0.2, indépendamment de son nom de fichier ou d'écran.

**Corollaire base de données :** un tri de maquettes ne couvre que le visuel. Toute réintroduction d'un concept aboli doit aussi être vérifiée côté backend (migrations, RPC, triggers, Edge Functions) avec la même méthode que C.3.2 — grep exhaustif de `App/supabase/migrations` et `App/supabase/functions` pour tout write vers une table de type solde/wallet/retrait, pas seulement une recherche dans `App/src`.

**§0.2 est une liste vivante, pas figée.** Si un futur audit révèle un nouveau pattern aboli à surveiller (comme le trigger wallet ou la RPC non protégée découverts en C.3.2), il doit être ajouté à §0.2 immédiatement, pas seulement documenté dans la Partie C — sinon la prochaine passe de tri (C.4.3 étape 2) travaillera contre une liste obsolète.

### C.4.5 Emplacement de la règle

Cette procédure vit ici, dans le CDC (source de vérité détaillée, avec l'historique des tris déjà faits C.1-C.3). Un rappel court est ajouté à `CLAUDE.md` (section "PROTOCOLE DE DÉMARRAGE OBLIGATOIRE"), pour être chargé automatiquement à chaque démarrage de session par le protocole déjà en vigueur (lecture intégrale de CLAUDE.md avant tout code) — sans dupliquer le détail procédural, seulement le déclencheur et le renvoi vers C.4.

### Synthèse C.4

- Le tri contre la grille C.1 devient une étape obligatoire du workflow, pas une passe ponctuelle : déclenchée à l'import de tout nouvel export de maquettes IA, refaite si §0.2 a évolué depuis le dernier tri.
- Le tri est fait par l'IA (avec preuve écrite et vérification du code réel, pas seulement du nom) ; Cedric ne tranche que les ⚠️ et les décisions produit qui en découlent.
- Un écran n'est jamais jugé légitime par son nom : il est classé par ce qu'il fait (solde, retrait, virement, paiement pair-à-pair, séquestre), et vérifié à la fois côté visuel (maquette) et côté backend (migrations/RPC/triggers), sur le modèle de la découverte C.3.2.

---

## Partie C — état : CLÔTURÉE (08/07/2026)

C.1 (classification), C.2 (plan de correction), C.3 (vérification croisée bilinguisme + jetons) et C.4 (règle de gouvernance permanente) sont terminées. Aucune sous-section restante dans cette partie.

Points encore ouverts, à traiter **en dehors** de la Partie C (décisions produit ou corrections backend, pas des travaux de gouvernance des maquettes) :
- Sort des tables DB orphelines `wallets`/`transactions_wallet`/`retraits`/`jalons_client` (C.2 #3, C.3.2) — décision Cedric requise.
- Neutralisation urgente du trigger `after_course_terminee` → `verifier_streak_client` qui écrit encore dans `wallets` (C.3.2) — 🔴.
- Contrôle de rôle manquant sur la RPC `admin_crediter_wallet_client` (C.3.2) — 🔴.
- Bug de perte silencieuse `sexe`/`date_naissance` dans `ProfilScreen.js` (C.3.1) — décision Cedric requise.
- Reclassements ⚠️→✅ à reporter dans C.1 lors d'une prochaine relecture (`gestion_des_codes_promo`, `paiement_instructions_directes`, `mes_revenus_1/2`).

---

# PARTIE D — REFONTE VISUELLE COMPLÈTE (CHANTIER DESIGN)

## D.0 Décision et cadrage

Décidé avec Cedric le 08/07/2026, en clôture de la Partie C : l'application va vers une **refonte visuelle complète**, en s'appuyant largement sur le dossier de maquettes Stitch (`vehicle_character_sheets/`) comme référence principale — pas seulement des corrections ponctuelles écran par écran. Séquencement choisi explicitement par Cedric : **avant le lancement Play Store**, quitte à repousser les items 21 (assets store) et 22 (test fermé) du Sprint 4 — voir §0.4, "Sprint 4bis" inséré avant la clôture du Sprint 4.

**Coût direct de ce choix, à garder visible à chaque session de ce chantier** : le calendrier de soumission Play Store et celui du recrutement des 50 transporteurs fondateurs (§0.4 point 12, déjà en cours) dépendent désormais de la durée de la refonte, pas seulement des items 20-22. Si le calendrier dérape, la variable d'ajustement est le périmètre d'écrans traités avant de relancer la validation du lancement (voir D.1, priorisation) — pas un abandon silencieux de la décision "avant le lancement" sans en repasser par Cedric.

**Ce qui NE change PAS avec cette décision** : §0.1 du CDC (design system Atelier CAARCO conservé — palette Forêt/Manioc/Néré/Bambou/Latérite, Marcellus/Plus Jakarta Sans/JetBrains Mono, lexique de composants français) reste la référence d'identité. "Refonte complète" porte sur la mise en page, la composition des écrans et l'ergonomie visuelle empruntées à Stitch — pas sur un changement de marque. Si la palette ou la typographie doivent elles aussi bouger (ex. adopter les tokens `terroir_moderne_2`, C.1), c'est une décision distincte à trancher explicitement avec Cedric, à ne pas supposer incluse par défaut dans "refonte complète".

## D.1 Méthode — la grille C.1-C.4 comme porte d'entrée obligatoire

Toute la Partie C existe pour ce moment précis : avant qu'un écran Stitch serve de référence dans ce chantier, il doit avoir franchi le tri C.4. Bonne nouvelle : le tri initial est déjà fait (C.1-C.3) — ce chantier démarre avec un inventaire prêt, pas à zéro.

État d'entrée par catégorie (repris de C.1/C.2 — ne pas retrier ce qui l'est déjà) :

| Catégorie | Contenu | Statut d'entrée dans le chantier D |
|---|---|---|
| ✅ Référence valide | ~75 écrans + 5 planches véhicules + 2 jeux de design tokens | Utilisables tels quels comme référence de mise en page. Contrôle visuel rapide (5 sec, C.1) toujours recommandé avant reprise individuelle. |
| 🔧 À adapter | `packs_abonnement_transporteur`, `classement_r_gional_caarco`, `mes_points_caarco_1/2`, `calendrier_marketing_admin_1/2`, `mes_tokens_de_course_caarco`, `publicit_s_in_app*` | Corriger le défaut identifié en C.2 (marque "TransLogix", traduction EN, libellé de transaction) **avant** de baser un écran dessus. `mes_tokens_de_course_caarco` et `calendrier_marketing_admin_*` : code réel déjà propre (C.2 #4-5), correction cosmétique de la seule maquette. |
| ⚠️ Résolu en ✅ (C.2) | `gestion_des_codes_promo`, `paiement_instructions_directes`, `mes_revenus_1/2` | Reclassés ✅ référence valide — utilisables dès maintenant, à reporter formellement dans C.1 lors d'une prochaine relecture. |
| ⚠️ Toujours en attente | `attente_du_r_glement_caarco`, `identification_chauffeur_qr` | **Hors périmètre du chantier D tant que Cedric n'a pas tranché** (C.2) — ni écran réel correspondant, ni décision produit actée. Ne pas les inclure dans un lot de refonte sans validation explicite préalable. |
| ❌ Interdit | Les 6 dossiers wallet/séquestre (C.1) | Exclusion permanente, aucune exception — un renommage ne les rend pas légitimes (C.4.4). |

Le point 🔧 le plus lourd reste `mes_points_caarco_1/2` (C.2 #3) : avant de retoucher son visuel, la décision Cedric sur le sort des tables `wallets` orphelines et sur le remplacement de la récompense "+100 XAF" doit être prise — sinon la refonte habille un bug plutôt que de le régler.

## D.2 Inventaire écran par écran

Ajouté le 08/07/2026. **Méthode et limite assumée** : cet inventaire mappe chacun des 64 écrans réels (`App/src/screens/`) à sa ou ses maquettes Stitch correspondantes, en s'appuyant sur le tri déjà fait (C.1/C.2) complété par une lecture rapide du code réel (titre affiché, imports) quand le nom seul ne suffisait pas à trancher. Contrairement à C.2 — qui a vérifié le contenu exact de 11 maquettes précises fichier par fichier — cet inventaire ne rouvre pas les ~90 `code.html` un par un : ce niveau de vérification est le travail de D.4, au moment où un lot est réellement pris en charge. Les correspondances restées incertaines sont marquées **« à confirmer »**, pas devinées avec une fausse assurance — conforme à la discipline établie en C.2/C.4 (classer par preuve, pas par ressemblance de nom).

**Composants Atelier CAARCO déjà disponibles** (boîte à outils commune à tous les écrans, non re-listée à chaque ligne) : `Galet` (CTA), `Sillon` (input), `Plaquette` (carte), `Pastille` (badge statut), `Mereau`, `Bascule` (toggle), `Jalons` (étapes), `Echelon` (liste), `Bandeau` (alerte), `Alcove` (section), `Onglets` (tabs), `Cachet` (tampon), `BoutonAnime`, `CarteLeaflet` (carte OSM/WebView), `TutorielPopup`, `CButton`, `CalendrierNaissance`, `CompteARebours`, `ContributionModal`, `LocationPicker`/`PickupLocationPicker`/`DropoffLocationPicker`, `MenuContextuel`, `PanneauDroit`, `QRCodeView`, `SelecteurVille`, `AppelEntrantOverlay`, `BadgeVerifie`, `BannierePublicite`, `BoutonSignalementCarte`. La question « réutiliser vs créer un composant » se tranche écran par écran à l'ouverture du lot (D.4), pas en bloc ici — le lister par écran sans avoir ouvert la maquette produirait une précision de façade.

**Effort — légende directionnelle (pas mesurée)** : **S** = retouche de mise en page sur écran simple (liste/détail statique) · **M** = formulaire, upload, ou logique d'état modérée · **L** = flux complexe (carte/GPS temps réel, overlay multi-état, back-office à sous-vues/filtres).

### D.2.1 Auth (3 écrans)

| Écran réel | Maquette(s) Stitch | Statut | Effort | Note |
|---|---|---|---|---|
| `auth/ConnexionScreen.js` | `connexion_caarco` | ✅ | S | — |
| `auth/InscriptionScreen.js` | `cr_er_un_compte_caarco` | ✅ | S | — |
| `auth/MotDePasseOublieScreen.js` | `mot_de_passe_oubli_caarco` | ✅ | S | — |

### D.2.2 Partagés — racine `screens/` (10 écrans)

| Écran réel | Maquette(s) Stitch | Statut | Effort | Note |
|---|---|---|---|---|
| `ProfilScreen.js` | `mon_profil_caarco_1`, `mon_profil_caarco_2` | ✅ | M | Écran partagé client/TR — vérifier si les 2 variantes correspondent aux 2 rôles. Bug `sexe`/`date_naissance` (C.3.1) à trancher avant retouche. |
| `ProfilPublicScreen.js` | `profil_client_caarco` **et** `profil_transporteur_caarco` | ✅ (résolu) | S | Confirmé via `grep` : écran unique importé à la fois par `ClientNavigator.js` et `TransporteurNavigator.js` (route `ProfilPublic` dans les deux) — les 2 maquettes s'appliquent, une par rôle affiché, ce n'est pas un choix à faire mais un mapping double. Point à vérifier en D.4, pas ici : redondance possible avec `transporteur/ProfilClientScreen.js` (écran TR dédié qui couvre déjà le même cas "TR voit un profil client"). |
| `MerciScreen.js` | `merci_caarco` | ✅ | S | **Bloqué par décision Cedric** : bannière streak "+100 XAF" (C.2 #3) à trancher avant retouche visuelle, sinon on habille le bug. |
| `EcranMaintenance.js` | `maintenance_en_cours_caarco` | ✅ | S | — |
| `ChatScreen.js` | `messagerie_caarco_2` | ✅ (résolu) | M | Confirmé par le contenu réel : `_2` contient le champ "Écrire un message..." + bouton "Envoyer" (fil de discussion) ; `_1` contient "Rechercher une conversation..." (liste, → `MessagesScreen.js`). |
| `OnboardingScreen.js` | Aucune | — | M | Construit hors périmètre Stitch (Sprint 4, `SPRINT_4.md`) — pas de maquette de référence, à concevoir ou laisser tel quel. |
| `SplashAnimeeScreen.js` | Aucune | — | — | Déjà refondu Sprint 3 sur les tokens Atelier — hors périmètre D. |
| `CallScreen.js` | Aucune identifiée | — | S | Pas de maquette "appel" dans l'export Stitch. |
| `ChangerMotDePasseScreen.js` | Aucune dédiée | — | S | Distinct de `mot_de_passe_oubli_caarco` (mdp oublié) — pourrait réutiliser sa mise en page comme base. |
| `ContributionsCarteScreen.js` | Aucune identifiée | — | M | Fonctionnalité absente de l'export Stitch. |

### D.2.3 Client (15 écrans)

| Écran réel | Maquette(s) Stitch | Statut | Effort | Note |
|---|---|---|---|---|
| `AccueilScreen.js` | `accueil_caarco` | ✅ | L | Carte OSM + catégories véhicule + tutoriel first-run. |
| `TrajetScreen.js` | `planifier_un_trajet_caarco_1`, `_2` | ✅ | L | LocationPicker + autocomplétion. |
| `DetailsColisScreen.js` | `d_tails_du_colis_caarco_1`, `_2` | ✅ | S | — |
| `ConfirmationScreen.js` | `confirmation_de_commande_caarco_1`, `_2` + `paiement_instructions_directes` + `d_tails_du_trajet` | ✅ (enrichi) | M | 2e famille de maquettes pour la partie `mode_paiement_client` informatif (reclassée ✅ en C.2). `d_tails_du_trajet` **reclassé ici** (résolu) : contenu réel = "Récapitulatif du trajet" / "Confirmer la commande" / "Total estimé" / "Moyen de paiement" — variante de la même étape de confirmation, pas un écran distinct. |
| `AttenteScreen.js` | `recherche_de_transporteur_caarco_1`, `_2` | ✅ | M | Animation de recherche. |
| `CourseAccepteeScreen.js` | `transporteur_trouv_caarco` | ✅ | S | — |
| `SuiviScreen.js` | `suivi_en_temps_r_el`, `suivi_en_temps_r_el_caarco_1`, `_caarco_2`, `_client` (les 4) | ✅ (résolu) | L | Confirmé par le contenu réel : les 4 variantes partagent un vocabulaire côté passager ("Suivi de votre colis", "Appeler"/"Message", "Arrivée estimée", "En approche") — aucune ne contient d'élément côté conducteur (accepter/naviguer/confirmer livraison). Les 4 sont des itérations du même écran client, pas un partage avec `NavigationScreen.js` (qui a déjà ses 2 maquettes dédiées `navigation_livraison_1/2`). |
| `CoursePlanifieeDetailScreen.js` | Aucune dédiée confirmée | ✅/— | M | `d_tails_du_trajet` réattribué à `ConfirmationScreen.js` (ci-dessus) après lecture du contenu réel — pas de maquette pour cet écran. Cohérent avec l'hypothèse : "courses programmées" (migration 086, Session 8 — 2026-07-03) est probablement postérieure à l'export Stitch. |
| `CourseDetailClientScreen.js` | `d_tail_de_la_course_caarco` | ✅ | S | — |
| `HistoriqueScreen.js` | `mes_courses_caarco_1`, `_2` | ✅ (résolu) | S | Confirmé : les 2 variantes portent le même titre "Historique des Courses" (`_1` = branding "TransLogix" résiduel, `_2` = "CAARCO") — 2 itérations du même écran, pas un partage avec d'autres écrans réels. |
| `MesCoursesPlanifieesScreen.js` | Aucune dédiée confirmée | — | S | Confirmé sans maquette propre (les 2 maquettes "mes courses" sont entièrement prises par `HistoriqueScreen.js`, ci-dessus) — fonctionnalité "courses programmées", postérieure probable à l'export. |
| `MessagesScreen.js` | `messagerie_caarco_1` | ✅ | S | — |
| `NotationScreen.js` | `noter_le_transporteur` | ✅ | S | — |
| `ParrainageScreen.js` | `parrainage_caarco_1`, `_2` | ✅ | S | — |
| `PointsScreen.js` | `mes_points_caarco_1`, `_2` | 🔧 | M | **Bloqué par décision Cedric** (C.2 #3) : sort des tables `wallets` orphelines + remplacement de la récompense `credit_wallet` avant toute retouche visuelle. |

### D.2.4 Transporteur (16 écrans)

| Écran réel | Maquette(s) Stitch | Statut | Effort | Note |
|---|---|---|---|---|
| `TableauBordScreen.js` | `tableau_de_bord_transporteur` | ✅ | L | Toggle dispo + courses dispo + GPS. |
| `CourseScreen.js` | `d_tails_de_la_mission_1`, `_2` | ✅ | M | Accept/refus avec timer 60s. |
| `NavigationScreen.js` | `navigation_livraison_1`, `_2` | ✅ | L | GPS + modal OTP. |
| `MesReservationsScreen.js` | Aucune identifiée | — | S | Fonctionnalité "courses programmées" (Session 8), probablement postérieure à l'export Stitch. |
| `CoursesTransporteurScreen.js` | Aucune dédiée confirmée | — | S | Les 2 maquettes "mes courses" sont entièrement prises par `HistoriqueScreen.js` côté client (D.2.3, résolu) — aucune variante TR distincte identifiée. Pourra réutiliser la même mise en page comme base une fois celle-ci retouchée (même famille fonctionnelle), sans maquette Stitch propre. |
| `AdDetailScreen.js` | `d_tails_de_l_annonce_1`, `_2` | ✅ | S | — |
| `RevenusScreen.js` | `mes_revenus_1`, `_2` | ✅ (reclassé C.2) | M | Vigilance résiduelle : ne sollicite pas les tables `wallets` (C.2 #5 confirmé), garder cet état lors de la retouche. |
| `MesTokensScreen.js` | `mes_tokens_de_course_caarco`, `mes_tokens_de_course`, `achat_de_tokens_tc` | 🔧 (code déjà propre, C.2 #5) | M | Flux d'achat WebView Notchpay — correction cosmétique de la seule maquette si reprise. |
| `PacksAbonnementScreen.js` | `packs_abonnement_transporteur` | 🔧 | M | Corriger "TransLogix"→CAARCO dans la maquette (C.2 #1) avant usage. Paliers payants : ne pas modifier le taux de commission sans décision Cedric explicite. |
| `LeaderboardScreen.js` | `classement_r_gional_caarco` | 🔧 | S | Corriger "TransLogix"→CAARCO dans la maquette (C.2 #2) avant usage. |
| `StatsTransporteurScreen.js` | `statistiques_performance`, `statistiques_performance_caarco` | ✅ | M | Graphiques. |
| `SoumissionKYCScreen.js` | `v_rification_kyc_transporteur_1` | ✅ (résolu) | M | Confirmé par le titre réel de la maquette : "CAARCO - Soumission KYC". Upload CNI/permis/photos véhicule. |
| `StatutKYCScreen.js` | `v_rification_kyc_transporteur_2` | ✅ (résolu) | S | Confirmé par le titre réel de la maquette : "CAARCO - Vérification KYC". |
| `ProfilClientScreen.js` | `profil_client_caarco` | ✅ | S | Vue TR du profil client (distinct de `ProfilPublicScreen.js` générique). |
| `NotationClientScreen.js` | `noter_le_client_caarco` | ✅ | S | — |
| `MessagesTransporteurScreen.js` | `messagerie_transporteur_caarco` | ✅ | S | — |

### D.2.5 Admin (20 écrans)

| Écran réel | Maquette(s) Stitch | Statut | Effort | Note |
|---|---|---|---|---|
| `DashboardScreen.js` | `tableau_de_bord_admin_caarco` | ✅ | L | KPIs temps réel + graphique horaire. |
| `UtilisateursScreen.js` | `gestion_des_utilisateurs_admin` | ✅ (résolu) | S | Confirmé : titre réel de la maquette "Gestion des Utilisateurs" (générique), et écran réel "Utilisateurs" est bien la vue généraliste — mapping direct. |
| `ClientsAdminScreen.js` | Aucune dédiée confirmée | ✅/— | M | `gestion_des_utilisateurs_admin` entièrement attribuée à `UtilisateursScreen.js` (ci-dessus). Vue filtrée par rôle sans maquette propre — adapter la mise en page de `UtilisateursScreen.js` une fois retouchée, ou concevoir sans référence. |
| `TransporteursAdminScreen.js` | Aucune dédiée confirmée | ✅/— | M | Idem `ClientsAdminScreen.js`. Contient aussi le modal "Créditer TC (admin)" — sans rapport avec la faille `admin_crediter_wallet_client` de C.3.2 (RPC différente, déjà protégée par `is_admin()`, migration 085). |
| `CoursesEnCoursAdminScreen.js` | `op_rations_live_admin` | ✅ (résolu) | L | Confirmé par le contenu réel : la maquette contient "Ouvrir le dossier" / "Client" / "Transporteur" / "Statut" (fiche de cas détaillée) — correspond à la feuille de détail course (TRAJET/CLIENT/TRANSPORTEUR/litige/assignation) de l'écran réel, pas à `OperationsAdminScreen.js`. |
| `OperationsAdminScreen.js` | `op_rations_live_admin_caarco` | ✅ (résolu) | L | Confirmé par le contenu réel : la maquette contient "Courses actives" / "En livraison" / "Operations" (vue d'ensemble/dashboard), cohérent avec le titre réel "Opérations" — écran distinct de `CoursesEnCoursAdminScreen.js`, pas une variante partagée. |
| `KYCValidationScreen.js` | `validation_kyc_admin`, `v_rification_kyc_admin` | ✅ | M | — |
| `LitigesScreen.js` | `gestion_des_litiges_admin` | ✅ | M | — |
| `FinancesAdminScreen.js` | `finances_tokens_tc_admin` | ✅ | M | — |
| `RetraitsAdminScreen.js` | Aucune (ne pas utiliser `retrait_de_gains*`) | ✅ (déjà conforme) | S | **Piège de nom vérifié (méthode C.4)** : malgré le nom, l'écran réel affiche les soldes TC des TR ("Renommé en Tokens TC Admin — les retraits n'existent plus dans le système TC", commentaire ligne 13 du fichier) — aucun rapport avec `retrait_de_gains_caarco`/`retrait_de_gains` (❌). Ne jamais rapprocher ces maquettes de cet écran malgré la ressemblance de nom. |
| `ConfigTarifsScreen.js` | `configuration_des_tarifs_admin` | ✅ | M | — |
| `LieuxAdminScreen.js` | `lieux_valider_admin` | ✅ | M | — |
| `MarketingAdminScreen.js` | `gestion_des_codes_promo` (reclassée ✅ C.2) + `publicit_s_in_app_admin_caarco` | ✅ / 🔧 | M | Contrôle visuel des visuels d'exemple recommandé (C.2 #6) avant usage de la 2e maquette. |
| `PublicitesAdmin.js` | `publicit_s_in_app` | 🔧 | S | Contrôle visuel uniquement (C.2 #6), pas de correction de code nécessaire. |
| `CalendrierActionsScreen.js` | `calendrier_marketing_admin_1`, `_2` | 🔧 | M | Maquette entièrement en anglais (C.2 #4) — traduire avant usage ; code réel déjà 100% français. |
| `NotificationsAdminScreen.js` | `templates_notifications_admin` | ✅ | M | Titre "Notifications" confirmé dans le code réel. |
| `CampagnesPushScreen.js` | Aucune identifiée | — | L | "Campagnes Push" avec segments (sexe/ancienneté/ville/note) — fonctionnalité absente de l'export Stitch, distincte de `NotificationsAdminScreen.js`. |
| `SecuriteAdminScreen.js` | Aucune | — | M | 2FA admin (migration 094, Sprint 1) — postérieure à l'export Stitch. |
| `MFAChallengeScreen.js` | Aucune | — | S | Idem, postérieure à l'export. |
| `AdminShell.js` | Aucune | — | — | Shell de navigation admin, pas un écran de contenu — hors périmètre d'une maquette dédiée. |

### D.2.6 Assets réutilisables tels quels

| Élément | Statut | Usage |
|---|---|---|
| 5 planches véhicules (`character_sheet_for_a_*`) | ✅ | Assets illustratifs (moto, tricycle, camion, taxi, camionnette) — utilisables directement, aucune logique métier. |
| `terroir_moderne_1`, `terroir_moderne_2` (design tokens) | ✅ | Déjà exploités dans `theme.js`. Rester sur les tokens actuels sauf décision distincte de faire évoluer la palette vers `terroir_moderne_2` (D.0) — ne pas mélanger silencieusement les deux jeux de valeurs pendant la refonte. |

### Synthèse D.2

- **64 écrans réels** couverts, correspondance établie pour chacun.
- **Les 8 répartitions initialement ambiguës ont été résolues le 08/07/2026**, par lecture du titre et du contenu réel de chaque maquette concernée (pas par déduction de nom) : `mes_courses_caarco_1/2` → `HistoriqueScreen.js` uniquement (2 itérations du même écran, "Historique des Courses") ; `gestion_des_utilisateurs_admin` → `UtilisateursScreen.js` uniquement ; `op_rations_live_admin` → `CoursesEnCoursAdminScreen.js` et `op_rations_live_admin_caarco` → `OperationsAdminScreen.js` (2 écrans distincts, pas une variante partagée) ; `v_rification_kyc_transporteur_1` → `SoumissionKYCScreen.js` et `_2` → `StatutKYCScreen.js` ; les 4 variantes `suivi_en_temps_r_el*` → `SuiviScreen.js` uniquement (vocabulaire passager confirmé, aucune ne correspond à `NavigationScreen.js`) ; `messagerie_caarco_1` (recherche) → `MessagesScreen.js`, `_2` (envoi) → `ChatScreen.js` ; `d_tails_du_trajet` → en réalité une variante de `ConfirmationScreen.js` ("Confirmer la commande"), pas de `CoursePlanifieeDetailScreen.js` ; `profil_client_caarco`/`profil_transporteur_caarco` → les deux s'appliquent à `ProfilPublicScreen.js` (écran unique partagé confirmé par les 2 navigateurs), sans exclusivité à choisir.
- **~12 écrans confirmés sans maquette Stitch** (et non plus "probablement") : `OnboardingScreen`, `CallScreen`, `ChangerMotDePasseScreen`, `ContributionsCarteScreen`, `MesReservationsScreen`, `MesCoursesPlanifieesScreen`, `CoursePlanifieeDetailScreen`, `CoursesTransporteurScreen`, `ClientsAdminScreen`, `TransporteursAdminScreen`, `CampagnesPushScreen`, `SecuriteAdminScreen`, `MFAChallengeScreen`, `AdminShell` — essentiellement des fonctionnalités ajoutées après l'export Stitch (courses programmées, sécurité admin Sprint 1, campagnes push) ou des vues filtrées d'un écran généraliste déjà attribué ailleurs. À concevoir sans référence, ou à dériver d'un écran voisin une fois celui-ci retouché.
- **1 piège de nom vérifié et neutralisé** (`RetraitsAdminScreen.js` vs `retrait_de_gains*` ❌) — bon exemple concret de la discipline C.4 « classer par capacité, pas par nom » appliquée en amont plutôt que découverte en cours de refonte.
- **Redondance potentielle relevée, pas résolue** : `ProfilPublicScreen.js` (générique, partagé client/TR) et `transporteur/ProfilClientScreen.js` (dédié TR) semblent couvrir le même cas d'usage ("TR consulte le profil d'un client") — à clarifier en D.4 avant de dupliquer l'effort de refonte sur les deux.
- **2 écrans bloqués par une décision Cedric en attente**, à ne pas retoucher visuellement avant tranchage produit : `PointsScreen.js`/`MerciScreen.js` (récompense streak, C.2 #3) et `PacksAbonnementScreen.js` (commission des paliers payants, C.2 #1).

## D.2bis Suivi et méthode transverses (adoptés le 08/07/2026)

Quatre améliorations de process, décidées avec Cedric à la clôture de D.2, s'appliquent à partir de D.3 :

1. **Fichier de suivi dédié** — `REFONTE_TRACKING.md` (racine du projet, créé le 08/07/2026) tient l'état de chaque écran (à faire / en cours / fait / bloqué) pour qu'une nouvelle conversation n'ait pas à relire toute la Partie D pour savoir où on en est. Mis à jour à la fin de chaque lot.
2. **Passe composants avant les écrans** — avant le premier lot d'écrans, un lot dédié identifie et construit les patterns UI récurrents dans les maquettes ✅ qui n'ont pas encore d'équivalent dans la boîte à outils Atelier CAARCO (liste en D.2). Principe déjà énoncé en Section 5 de CLAUDE.md, appliqué ici formellement au chantier de refonte.
3. **Captures avant/après par lot** — `scripts/capture-auto.ps1` (déjà existant) est exécuté avant et après chaque lot, captures versées dans un dossier dédié. Seul filet de sécurité disponible contre une régression visuelle, en l'absence de tests UI automatisés sur ce projet.
4. **Definition of done par lot** (non négociable, dérivée des Sprints 2/3 déjà livrés) : tout écran retouché doit repasser i18n complet (parité `fr.js`/`en.js`), zéro hex en dur (mode sombre), contraste WCAG AA, et respect de la grille C.1/C.4 (aucune résurgence wallet/séquestre, y compris dans un texte ou un libellé copié tel quel depuis une maquette ❌ voisine).

## D.3 Priorisation et découpage en lots

Ajouté le 08/07/2026. Objectif : transformer l'inventaire D.2 (64 écrans) en une séquence de lots exploitables un par un, conforme aux 4 règles de process D.2bis.

### D.3.0 Méthode — échantillon représentatif, pas les 87 maquettes une par une

Pour ouvrir le Lot 0 sans rouvrir chaque maquette individuellement (explicitement exclu par consigne), 24 dossiers ✅ ont été lus intégralement (`code.html`), couvrant les 4 familles et les écrans les plus représentatifs de chacune : `accueil_caarco`, `planifier_un_trajet_caarco_1`, `confirmation_de_commande_caarco_1`, `recherche_de_transporteur_caarco_1`, `suivi_en_temps_r_el_client`, `mes_courses_caarco_2`, `noter_le_transporteur`, `parrainage_caarco_1`, `mes_points_caarco_1`, `tableau_de_bord_transporteur`, `d_tails_de_la_mission_1`, `navigation_livraison_1`, `statistiques_performance`, `v_rification_kyc_transporteur_1`, `packs_abonnement_transporteur`, `classement_r_gional_caarco`, `mes_tokens_de_course_caarco`, `tableau_de_bord_admin_caarco`, `gestion_des_utilisateurs_admin`, `gestion_des_litiges_admin`, `finances_tokens_tc_admin`, `configuration_des_tarifs_admin`, `validation_kyc_admin`, `connexion_caarco`.

Deux garde-fous appliqués à chaque candidat pattern : (a) présent dans au moins 2-3 écrans distincts — sinon c'est un besoin ponctuel, pas un composant transverse ; (b) absent de la boîte à outils existante (D.2). Plusieurs candidats plausibles ont été écartés sur le critère (b), preuve à l'appui — voir liste en fin de D.3.1.

### D.3.1 Lot 0 — Composants transverses à construire avant tout écran

12 composants identifiés, chacun avec preuve textuelle (fichier/citation) et justification du non-recouvrement avec Galet, Sillon, Plaquette, Pastille, Mereau, Bascule, Jalons, Echelon, Bandeau, Alcove, Onglets, Cachet et le reste de la boîte à outils listée en D.2. Noms proposés dans le lexique Atelier CAARCO — à valider/ajuster librement à l'ouverture du Lot 0 (D.4), ce ne sont pas des noms de fichiers gravés dans le marbre :

| # | Composant proposé | Rôle | Écrans témoins (preuve) | Pourquoi pas déjà couvert |
|---|---|---|---|---|
| 1 | **Borne** | Tuile KPI compacte : icône + chiffre en police mono + libellé + delta de tendance, assemblée en grille | `parrainage_caarco_1` ("Gains cumulés" 120 pts), `mes_points_caarco_1` ("Solde Actuel" 1 450), `statistiques_performance` (Revenus/Courses/Distance/Note), `tableau_de_bord_admin_caarco` ("+12.5% vs sem. passée"), `finances_tokens_tc_admin` (Volume de Vente) | Plaquette est une carte de contenu générique, sans la structure figée icône+chiffre+delta |
| 2 | **Sentier** | Connecteur vertical d'itinéraire (2+ pastilles reliées par un trait), sans état d'étape nommé | `confirmation_de_commande_caarco_1` (icônes trip_origin/location_on), `mes_courses_caarco_2`, `tableau_de_bord_transporteur`, `d_tails_de_la_mission_1`, `navigation_livraison_1` | Confondu à tort avec Jalons dans le code Stitch lui-même ("Plaquette + Jalons") — Jalons est un stepper à états nommés (complété/actif/à venir), Sentier ne relie que des adresses, sans statut |
| 3 | **Etal** | Groupe de cartes à sélection exclusive (image/icône + libellé + prix), halo au clic (`peer-checked`) | `accueil_caarco` (Moto/Camionnette), `planifier_un_trajet_caarco_1` (scroll véhicules), `confirmation_de_commande_caarco_1` (Cash/Mobile Money) | Ni Mereau (chip), ni Galet (bouton), ni Plaquette (carte statique) ne portent la sémantique "groupe à sélection exclusive avec état actif" |
| 4 | **Pochette** | Tuile média/document : dropzone, galerie défilante, aperçu zoomable | `v_rification_kyc_transporteur_1` (dropzones CNI/permis/plaque), `d_tails_de_la_mission_1` (galerie photos colis), `validation_kyc_admin` (zoom au survol) | Aucun composant d'upload/galerie/zoom dans la boîte à outils existante |
| 5 | **Silo** | Graphique en barres CSS avec axes et infobulle | `statistiques_performance`, `tableau_de_bord_admin_caarco`, `finances_tokens_tc_admin` (double-barre Ventes/Commissions + légende) | Aucun composant de visualisation de données dans la liste existante |
| 6 | **Étoiles** | Notation par étoiles : interactive (saisie) ou lecture seule (moyenne, demi-étoile) | `noter_le_transporteur` (clic + hover JS), `statistiques_performance` (4.8 + demi-étoile), `gestion_des_utilisateurs_admin` (profil 4.8★) | Pastille est un badge de statut, pas un widget de notation graduelle |
| 7 | **Jauge** | Barre de progression linéaire continue (%), sans étapes nommées | `mes_points_caarco_1` (niveau, 72%), `suivi_en_temps_r_el_client` (ETA 85%, annotée à tort "Jalons" dans le code Stitch), `navigation_livraison_1` | Distincte de Jalons (étapes discrètes nommées) malgré la confusion de nommage dans la maquette source elle-même |
| 8 | **Corridor** | Navigation latérale fixe desktop (logo/rôle en en-tête + liens, état actif) | `gestion_des_utilisateurs_admin` (annotée "NavigationDrawer (Web)"), `gestion_des_litiges_admin` (annotée "SideNav (Desktop)"), `finances_tokens_tc_admin` | Distinct de PanneauDroit (panneau de détail à droite) ; aucune nav latérale persistante desktop dans la liste |
| 9 | **Passoire** | Barre recherche + filtres combinés, en tête de liste de données admin | `gestion_des_utilisateurs_admin` (search + selects rôle/statut), `gestion_des_litiges_admin` (Filtrer/Trier), `tableau_de_bord_admin_caarco` (bouton Filtres) | Sillon est un champ de saisie générique seul, pas un bloc recherche+filtres combinés |
| 10 | **Fronton** | En-tête de section avec action "voir tout" | `mes_tokens_de_course_caarco`, `tableau_de_bord_admin_caarco`, `finances_tokens_tc_admin`, `classement_r_gional_caarco` | Motif titre+CTA non nommé dans la liste, distinct d'Alcove (section sans ce couple imposé) |
| 11 | **Echo** | Indicateur de recherche/attente temps réel (anneaux radar, halo pulsé, points rebondissants), sans valeur chiffrée | `recherche_de_transporteur_caarco_1` (`.animate-radar`, 3 anneaux), `tableau_de_bord_transporteur` (bounce + ping), `suivi_en_temps_r_el_client` (`.pulse-ring` "En approche") | CompteARebours affiche une valeur mm:ss ; Echo n'affiche aucune valeur, seulement un signal d'activité |
| 12 | **Cadran** | Sélecteur de période en pilule (mois/date) | `classement_r_gional_caarco` ("Novembre 2023"), `finances_tokens_tc_admin` ("Ce Mois") | Distinct de SelecteurVille (localités) ; aucun composant période/date dans la liste. Évidence plus limitée (2 écrans) — à reconfirmer à l'ouverture du lot avant d'investir dessus. |

**Écartés du Lot 0** (pattern réel mais insuffisamment récurrent ou déjà couvert — à traiter au cas par cas dans l'écran concerné, pas en composant transverse) : avatar à initiales (déjà annoté "Mereau Avatar" dans le code Stitch), bottom sheet flottant sur carte (déjà annoté "Alcôve Modal Style"), FAB de contrôle carte (probable slot de CarteLeaflet), OTP à 4 cases (1 seul écran, `navigation_livraison_1`), carte de plan tarifaire/abonnement (1 seul écran, `packs_abonnement_transporteur` — de toute façon bloqué), input numérique à préfixe/suffixe (variante de Sillon).

**Ordre de construction suggéré à l'intérieur du Lot 0** (indicatif, à trancher en D.4) : Sentier, Etal et Echo en premier — ils conditionnent les Lots 3-4 et 7 (tronc commun client/transporteur, le plus visible) ; Corridor, Passoire, Fronton et Cadran peuvent attendre juste avant le Lot 13 (premier lot admin) sans bloquer le tronc commun.

### D.3.2 Découpage en lots des écrans (après le Lot 0)

**Logique retenue : ordre par rôle et parcours fonctionnel** (tronc commun le plus visible d'abord, admin en dernier — conforme au cadrage de Cedric), plutôt que par pattern UI partagé. Justification du choix, tranchée pour ce chantier : le Lot 0 neutralise déjà la variable "composant visuel manquant" pour tous les écrans en une seule passe amont — regrouper ensuite par pattern n'apporterait qu'un gain marginal. Regrouper par écran-famille (même service, même navigateur, mêmes clés i18n, même contexte métier) réduit davantage le changement de contexte réel à chaque lot, puisque l'implémentation d'un écran demande de relire son service et sa logique environnante, pas seulement son pattern visuel. Chaque lot reste volontairement petit (1 à 6 écrans) pour rester compatible avec le rythme captures avant/après + definition of done par lot (D.2bis).

**Écrans exclus de cette séquence** (5 sur 64) : `SplashAnimeeScreen.js` — déjà refondu Sprint 3, hors périmètre D, aucun lot. Les 4 écrans bloqués par décision Cedric en attente (`ProfilScreen.js`, `MerciScreen.js`, `PointsScreen.js`, `PacksAbonnementScreen.js`) forment un **Lot bloqué**, en fin de séquence, non planifié activement — voir D.3.3.

| Lot | Écrans | Composants Lot 0 mobilisés | Justification |
|---|---|---|---|
| **1 — Auth & entrée** (5) | OnboardingScreen, ConnexionScreen, InscriptionScreen, MotDePasseOublieScreen, ChangerMotDePasseScreen | Sillon, Galet (existants) | Point d'entrée de toute l'app, écrans S/M à faible risque — sert de test de fumée pour valider le Lot 0 sur le design system existant avant les écrans à forte logique métier. `ChangerMotDePasseScreen` regroupé ici car il peut réutiliser la mise en page de `MotDePasseOublieScreen.js` (note déjà actée en D.2.2). |
| **2 — Accueil** (1) | AccueilScreen | Etal, Echo (bannière active), Fronton | Écran le plus visible de toute l'app, volontairement isolé en lot propre vu sa taille (effort L : carte OSM + catégories + carousel + bannières) et son statut de checkpoint explicite (Master Prompt §"un seul CTA principal"). |
| **3 — Commande client : recherche & saisie** (3) | TrajetScreen, DetailsColisScreen, ConfirmationScreen | Sentier, Etal (véhicule + mode paiement), Pochette (photos colis) | Première moitié du tunnel de commande. Point de vigilance à vérifier en D.4 : `ConfirmationScreen` porte le mode paiement direct informatif (§6 règles serveur) — ne rien faire glisser vers un bouton de transaction. |
| **4 — Commande client : matching & suivi** (3) | AttenteScreen, CourseAccepteeScreen, SuiviScreen | Echo (radar recherche), Sentier, Jauge (ETA) | Deuxième moitié du tunnel, enchaînée directement après le Lot 3 pour rester dans le même contexte de service (`courses.js`, Supabase Realtime). |
| **5 — Post-course client** (3) | CourseDetailClientScreen, NotationScreen, HistoriqueScreen | Étoiles, Echelon (existant) | Écrans de clôture/consultation, risque faible ; Étoiles fraîchement construit y est immédiatement exercé. |
| **6 — Fidélité & réservations client** (3) | ParrainageScreen, CoursePlanifieeDetailScreen, MesCoursesPlanifieesScreen | Borne (gains cumulés), Echelon | 2 des 3 écrans sont sans maquette Stitch (à concevoir sans référence) — regroupés avec Parrainage (même famille "engagement client") pour amortir l'effort de conception libre. |
| **7 — Tableau de bord & mission transporteur** (3) | TableauBordScreen, CourseScreen, NavigationScreen | Echo, Sentier, Jauge | Tronc commun transporteur, symétrique du Lot 4 côté client — mêmes composants Lot 0 déjà rodés, effort de prise en main réduit. |
| **8 — Revenus & jetons transporteur** (3) | RevenusScreen, MesTokensScreen, AdDetailScreen | Borne, Silo | Écrans financiers TR (jetons). Vigilance rappelée du tracking (C.2 #5) : ne pas réintroduire de lecture des tables `wallets`. |
| **9 — Réputation & stats transporteur** (3) | StatsTransporteurScreen, LeaderboardScreen 🔧, NotationClientScreen | Silo, Étoiles, Borne | Regroupe les 3 écrans à base de graphiques/notation. `LeaderboardScreen` : corriger "TransLogix"→CAARCO dans la maquette (C.2 #2) à l'ouverture. |
| **10 — KYC transporteur** (2) | SoumissionKYCScreen, StatutKYCScreen | Pochette | Paire déjà couplée dans l'inventaire D.2 (maquettes `_1`/`_2` du même flux) ; Pochette y est directement exercé. |
| **11 — Profil, messagerie & annexes transporteur** (4) | ProfilClientScreen (TR), MessagesTransporteurScreen, MesReservationsScreen, CoursesTransporteurScreen | Echelon, Sentier (résumé course) | Fin du tronc commun TR. `CoursesTransporteurScreen` peut dériver de `HistoriqueScreen.js` — placé après le Lot 5 volontairement. |
| **12 — Écrans partagés restants** (6) | ProfilPublicScreen, ChatScreen, MessagesScreen, CallScreen, EcranMaintenance, ContributionsCarteScreen | Echelon, Sillon | Reste des écrans partagés non bloqués. À vérifier en ouverture : redondance `ProfilPublicScreen`/`ProfilClientScreen` (TR) relevée en D.2 mais non résolue — ne pas dupliquer l'effort sur les deux sans trancher. |
| **13 — Admin : tableau de bord & opérations** (3) | DashboardScreen, OperationsAdminScreen, CoursesEnCoursAdminScreen | Borne, Silo, Corridor, Passoire, Fronton | Premier lot admin, le plus consulté au quotidien (tableau de bord) — première entrée en jeu de Corridor/Passoire/Fronton, jamais utilisés côté app mobile. |
| **14 — Admin : utilisateurs** (3) | UtilisateursScreen, ClientsAdminScreen, TransporteursAdminScreen | Passoire, Corridor, Echelon | 3 vues de la même liste généraliste (2 sans maquette propre, dérivées d'`UtilisateursScreen` une fois retouché) — enchaînées pour capitaliser sur la mise en page commune. |
| **15 — Admin : KYC & litiges** (2) | KYCValidationScreen, LitigesScreen | Pochette (pièces KYC), Corridor | Même famille "dossier à traiter" (upload/preuves + décision admin). |
| **16 — Admin : finances & tarifs** (3) | FinancesAdminScreen, RetraitsAdminScreen, ConfigTarifsScreen | Borne, Silo, Corridor | Écrans financiers admin. `RetraitsAdminScreen` porte un piège de nom déjà neutralisé (D.2.5) — rappeler explicitement à l'ouverture : ne jamais rapprocher de la maquette `retrait_de_gains*` (❌). |
| **17 — Admin : marketing** (4) | MarketingAdminScreen, PublicitesAdmin 🔧, CalendrierActionsScreen 🔧, LieuxAdminScreen | Cadran, Fronton, Corridor | Regroupe les 2 correctifs cosmétiques restants : traduction EN→FR de `CalendrierActionsScreen` (C.2 #4), contrôle visuel de `PublicitesAdmin` (C.2 #6). |
| **18 — Admin : notifications, sécurité & reste** (5) | NotificationsAdminScreen, CampagnesPushScreen, SecuriteAdminScreen, MFAChallengeScreen, AdminShell | Corridor, Echelon | Dernier lot : écrans les plus récents/annexes (sécurité Sprint 1, campagnes push), sans maquette Stitch pour 3 d'entre eux — conçus sur la base du Corridor/Echelon déjà posés dans les lots admin précédents plutôt qu'ex nihilo. |

### D.3.3 Lot bloqué — non planifié, en attente de décision Cedric

| Écran | Blocage | Référence |
|---|---|---|
| `ProfilScreen.js` | Champs `sexe`/`date_naissance` : perte de données silencieuse (C.3.1) — décider (a) migration + autorisation du champ, ou (b) retrait de l'UI, avant toute retouche visuelle | C.3.1 |
| `MerciScreen.js` | Bannière streak "+100 XAF" sans mécanisme de crédit réel côté client (C.2 #3) | C.2 #3, C.3.2 |
| `PointsScreen.js` | Même blocage que `MerciScreen.js` — sort des tables `wallets`/`transactions_wallet` orphelines à trancher avant retouche | C.2 #3, C.3.2 |
| `PacksAbonnementScreen.js` | Commission des paliers payants (C.2 #1) — ne pas modifier le taux de commission sans décision explicite | C.2 #1 |

Ces 4 écrans ne doivent pas être insérés « à proximité » d'un lot voisin (consigne Cedric) : ils resteront en dehors de toute séquence active jusqu'à tranchage, puis seront affectés a posteriori au lot le plus proche de leur famille fonctionnelle (`MerciScreen`/`PointsScreen` → voisinage du Lot 5-6 client, `PacksAbonnementScreen` → voisinage du Lot 9 transporteur, `ProfilScreen` → voisinage du Lot 12).

**Rappel — hors périmètre de ce chantier de design (Partie C), toujours ouverts** : les 2 corrections backend 🔴 (neutraliser le trigger `after_course_terminee`→`verifier_streak_client` qui écrit encore dans `wallets` ; ajouter le contrôle de rôle manquant sur la RPC `admin_crediter_wallet_client`, C.3.2). Aucun lot D.3 n'en dépend techniquement, mais elles conditionnent indirectement le tranchage du Lot bloqué ci-dessus (le sort des tables `wallets` est le même sujet).

### Synthèse D.3

- **Lot 0** : 12 composants transverses identifiés par preuve, aucun redondant avec la boîte à outils existante.
- **59 écrans** répartis sur **18 lots** (1 à 6 écrans chacun), ordonnés tronc commun client → tronc commun transporteur → admin, conformément au cadrage de Cedric.
- **5 écrans hors séquence** : 1 déjà fait (`SplashAnimeeScreen.js`), 4 bloqués par décision produit en attente (D.3.3). Total vérifié : 12 (Lot 0, composants) + 59 (Lots 1-18) + 5 (hors séquence) = 64 écrans + Lot 0, cohérent avec l'inventaire D.2.
- Prochaine étape : D.4, ouverture du Lot 0.

## D.4 Lot 0 — Composants transverses (implémentation, 08/07/2026)

Ouvert et clôturé le 08/07/2026, conformément à D.3.1 et au process D.2bis. Détail écran par écran / composant par composant tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 0 ») — ce qui suit résume les décisions et écarts qui méritent de rester dans le CDC.

### D.4.1 Méthode suivie

Pour chacun des 12 composants proposés en D.3.1, vérification du besoin dans le code réel (`App/src/components/`) avant toute création de fichier — pas seulement relecture de la glose D.2, qui s'est révélée trompeuse sur un point (voir D.4.2). Ordre de construction suivi : Sentier, Etal, Echo d'abord ; Borne, Silo, Étoiles, Pochette ensuite ; Corridor, Passoire, Fronton juste avant ; Cadran reconfirmé puis construit en dernier, comme prévu en D.3.1.

Conventions du code existant respectées à l'identique (vérifiées sur `Plaquette.js`, `Jalons.js`, `Pastille.js`, `Mereau.js`, `Bandeau.js`, `Onglets.js`, `Echelon.js`, `Galet.js`, `Alcove.js`) : composants fonctionnels sans état interne inutile, imports `{ colors, fonts, fontSize, spacing, radius, shadow }` depuis `theme.js` (jamais de hex en dur), `Ionicons` pour les icônes, `StyleSheet.create` en pied de fichier, prop `style` fusionnée en dernier. Palette statique (`colors`), pas `useTheme()` (mode sombre) : 32 des 33 composants existants suivent déjà cette convention, `Sillon.js` étant l'unique exception (input avec état focus) — aligner les 11 nouveaux sur la majorité plutôt que sur l'exception.

i18n : les composants purement présentationnels (Borne, Sentier, Etal, Étoiles, Corridor) ne portent aucun texte interne — tout le texte visible est fourni par l'écran appelant via props, déjà traduit, à l'identique du patron existant (`Plaquette`, `Jalons`, `Pastille`, `Onglets`). Les composants qui portent une micro-copie propre (dropzone de Pochette, placeholder de Passoire, "Voir tout" de Fronton, état vide de Silo, accessibilité de Cadran) l'obtiennent via `useI18n()` avec clés dédiées dans `fr.js`/`en.js`, à l'identique du patron `TutorielPopup`/`CalendrierNaissance`/`SelecteurVille`. Zéro hex en dur, zéro texte en dur : vérifiés fichier par fichier à l'écriture.

### D.4.2 Écart avec D.3.1 — Jauge n'a pas été créé

Avant de créer `Jauge.js`, vérification dans le code réel (pas seulement la glose "Jalons (étapes)" de la boîte à outils D.2) : `App/src/components/Jalons.js` implémente déjà exactement le rôle décrit pour Jauge en D.3.1 #7 — barre de progression linéaire continue (%) avec libellé, sans étapes nommées. Le vrai stepper à états nommés (fait/actif/à venir) est en réalité `Echelon.js`. `grep` confirme qu'aucun des deux fichiers n'est importé par un écran à ce jour — le postulat de D.3.1 ("Jalons = stepper à états nommés, distinct de Jauge") reposait sur la lecture des annotations des maquettes Stitch, pas sur le fichier réel, qui les inversait déjà silencieusement.

Décision : pas de nouveau fichier, un commentaire d'en-tête a été ajouté dans `Jalons.js` référençant l'alias "Jauge" pour qu'une future session le retrouve. Pas de renommage (aucun import à casser, mais renommer un fichier hors du besoin du Lot 0 n'a pas été jugé utile). **Conséquence pour les Lots 4 et 7** (D.3.2) : importer `Jalons.js` directement, aucun composant "Jauge" à chercher ni à créer.

### D.4.3 Composants livrés

11 fichiers créés dans `App/src/components/` : `Borne.js`, `Sentier.js`, `Etal.js`, `Pochette.js`, `Silo.js`, `Etoiles.js`, `Corridor.js`, `Passoire.js`, `Fronton.js`, `Echo.js`, `Cadran.js`. Plus un commentaire ajouté dans `Jalons.js` (D.4.2). Détail de rôle et props de chacun : `REFONTE_TRACKING.md`, tableau Lot 0.

Point d'implémentation notable : **Pochette** (aperçu zoomable) utilise le zoom natif de `ScrollView` (`maximumZoomScale`/`minimumZoomScale`), sans nouvelle dépendance — aucune librairie de zoom d'image n'existait dans le projet, en ajouter une n'a pas été jugé nécessaire pour ce besoin.

### D.4.4 Écran-catalogue (dev-only)

`App/src/screens/dev/CatalogueComposantsScreen.js` affiche les 12 composants (11 nouveaux + Jalons/Jauge) dans leurs états (interactif/lecture seule, vide/rempli), comme surface de revue pour Cedric. Jamais dans la navigation de production : monté uniquement derrière `if (__DEV__ && catalogueOuvert)` dans `RootNavigator.js`, ouvert par un bouton flottant (latérite, coin bas-droit, visible seulement en dev) — aucun `Stack.Screen` enregistré, aucun écran des Lots 1-18 ni des navigateurs (`ClientNavigator`/`TransporteurNavigator`/`AdminNavigator`) modifié pour l'atteindre. `__DEV__` est éliminé statiquement par Metro en build release : le bouton et l'écran n'existent pas dans l'APK/AAB de production.

### D.4.5 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : fait. Composants présentationnels sans texte interne ; composants à micro-copie propre passés par `useI18n()` avec clés dédiées (`silo.*`, `pochette.*`, `passoire.*`, `fronton.*`, `cadran.*`, `composantsCatalogue.*`), ajoutées en miroir dans `fr.js` et `en.js`.
- **Zéro hex en dur** : fait, tous les styles passent par les tokens `theme.js` (`colors`, `fonts`, `fontSize`, `spacing`, `radius`, `shadow`).
- **Contraste WCAG AA** : fait par construction — seules les couleurs de la palette Atelier CAARCO existante sont utilisées (déjà validées AA), aucune nouvelle couleur introduite.
- **Aucune résurgence wallet/séquestre** : fait — aucun des 12 composants ne touche à un solde, un wallet ou une transaction ; Borne/Silo affichent des valeurs déjà calculées et fournies par l'écran appelant (TC, FCFA, %), sans accès direct à une table financière.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté** dans cet environnement — le script nécessite un téléphone Android branché en USB (déboguage activé) et Maestro installés, tous deux absents de cet environnement d'agent (`adb` introuvable, aucun émulateur). À faire par Cedric : lancer le script sur son poste (utile pour confirmer l'absence de régression sur les écrans existants, qui n'ont pas été touchés dans ce Lot — `caarco_tous_ecrans.yaml` ne visite pas l'écran-catalogue, hors navigation normale), ou ouvrir directement le catalogue via le bouton flottant dev et faire une capture manuelle pour la revue des 12 composants. Point ouvert, à lever avant de considérer le Lot 0 définitivement clos.
- **Validation syntaxique** : faite (Babel, `babel-preset-expo`, 16 fichiers vérifiés — 12 composants + Jalons + écran-catalogue + RootNavigator + fr.js/en.js), aucune erreur.

### Synthèse D.4

- **11 composants créés**, **1 composant reconnu comme déjà existant** (Jauge = Jalons.js, non dupliqué) — 12/12 besoins de D.3.1 couverts.
- **1 écran-catalogue dev-only** livré, jamais dans la navigation de production.
- **Aucun écran des Lots 1-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- **Point ouvert avant clôture définitive** : captures avant/après à exécuter par Cedric (D.4.5) — bloquant uniquement pour la preuve visuelle, pas pour l'avancement du chantier.
- Prochaine étape recommandée : **Lot 1 — Auth & entrée** (5 écrans, S/M à faible risque, sert de test de fumée du Lot 0 sur le design system existant avant les écrans à forte logique métier — cf. D.3.2). Alternative : **Lot 2 — Accueil**, l'écran le plus visible de l'app, si Cedric préfère attaquer en premier l'écran à plus fort impact perçu plutôt que le tunnel d'auth.

## D.5 — Lot 1 : Auth & entrée (implémentation, 08/07/2026)

Ouvert et clôturé le 08/07/2026, conformément à D.3.2 et au process D.2bis. Cedric a confirmé l'ouverture du Lot 1 (test de fumée du Lot 0 sur le design system existant, écrans S/M à faible risque, avant les écrans à forte logique métier). Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 1 ») — ce qui suit résume les décisions et écarts qui méritent de rester dans le CDC.

### D.5.1 Méthode suivie

Pour les 3 écrans avec maquette (`ConnexionScreen.js`, `InscriptionScreen.js`, `MotDePasseOublieScreen.js`), les trois `code.html` correspondants ont été lus intégralement (pas seulement les captures `screen.png`) avant toute retouche, pour extraire la structure exacte (hiérarchie, copie, palette locale) plutôt que de deviner depuis l'image. Les deux écrans sans maquette (`OnboardingScreen.js`, `ChangerMotDePasseScreen.js`) ont été traités selon la note déjà actée en D.2.2 : le second reprend la mise en page du premier écran retouché de la paire (`MotDePasseOublieScreen.js`), le premier a été audité contre le Definition of Done (D.2bis point 4) plutôt que redessiné sans référence ni défaut identifié.

Composants mobilisés : uniquement `Sillon` et `Galet`, conformément au périmètre du lot — aucun besoin transverse imprévu n'a nécessité un nouveau composant. La variante `fantome` de `Galet` (déjà existante, fond transparent + bordure/texte foret) a servi de CTA secondaire "Créer un compte", évitant une reconstruction manuelle de bouton.

### D.5.2 Écart avec l'implémentation existante — bug de contraste AA corrigé, pas seulement redesigné

Avant retouche, `ConnexionScreen.js` contenait deux boutons (`btnLogin` de l'étape de choix, `btn` du formulaire) avec fond **Néré + texte blanc** — exactement l'échec AA (~2,7:1) documenté comme corrigé au Sprint 3 (CDC §0.2, ligne « Blanc sur Néré… ✅ Corrigé Sprint 3 »). Le fichier réel n'avait donc pas reçu ce correctif, ou une régression l'avait réintroduit après coup — point non élucidé plus avant, hors périmètre d'investigation de ce lot. En reconstruisant l'écran sur la maquette `connexion_caarco` (qui utilise elle-même un bouton primaire foret foncé), le remplacement par les variantes déjà conformes du composant `Galet` (`primaire` = foret/blanc, `fantome` = transparent/bordure foret) a corrigé ce défaut comme effet de bord de la refonte, sans action dédiée séparée.

### D.5.3 Écart avec la maquette — deux adaptations délibérées, pas des oublis

1. **`MotDePasseOublieScreen.js`** : la maquette invite à "recevoir un code de sécurité temporaire" (formulation qui suggère un envoi externe, SMS). Le flux réel (`reset-mot-de-passe`, Edge Function déjà existante) affiche le mot de passe temporaire directement dans l'app, sans SMS — cohérent avec l'absence de fournisseur SMS externe actée en Section 1 de CLAUDE.md. La copie existante et exacte (`auth.mdpOublie.*`, déjà revue au Sprint 2) a été conservée telle quelle plutôt que de reprendre la formulation de la maquette, pour ne pas promettre un canal de livraison qui n'existe pas.
2. Le lien "Contacter l'assistance" de la même maquette a été **omis** : aucun écran d'assistance/support n'existe aujourd'hui dans `App/src/screens` (les dossiers maquette `aide_support_*` n'ont pas d'écran réel correspondant dans l'inventaire D.2), et un lien sans destination aurait été une fonctionnalité non livrée plutôt qu'un simple manque visuel.

### D.5.4 `InscriptionScreen.js` — changement structurel le plus important du lot

Contrairement à `ConnexionScreen.js` (retouche de mise en page sur une structure conservée), `InscriptionScreen.js` a perdu son fond photo plein écran et sa carte flottante élevée : la maquette `cr_er_un_compte_caarco` est un formulaire plein-écran sur fond manioc uni, sans image ni carte (commentaire explicite dans le `code.html` source : *"TopAppBar and BottomNavBar are intentionally omitted to prioritize the registration task"*). Aucun champ ni logique de validation n'a été modifié (nom, téléphone, mot de passe, genre, date de naissance, ville, parrainage — tous conservés, `inscrire()` appelé à l'identique). Le bouton "Suivant" de la maquette (qui suggère un flux multi-étapes) a été volontairement **remplacé par le libellé existant "Créer mon compte"** : le flux réel crée le compte immédiatement à la soumission, un seul écran, pas un assistant à plusieurs pages — reprendre "Suivant" aurait été une copie malhonnête d'une étape supplémentaire qui n'existe pas.

### D.5.5 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : 1 nouvelle clé ajoutée en miroir strict (`auth.connexion.mdpOublieCourt`, lien court "Oublié ?" à côté du label mot de passe, la clé existante `mdpOublie` étant trop longue pour un lien inline). Parité vérifiée programmatiquement après ajout (flatten + comparaison des deux objets exportés) : **1381 clés de chaque côté, 0 écart**.
- **Zéro hex en dur** : vérifié par grep sur les 4 fichiers modifiés — 0 résultat. Le seul hex hérité du fichier d'origine (dégradé `LinearGradient` de `ConnexionScreen.js`, deux valeurs `#0f1411xx`) a été retokenisé via `alpha(colors.nuit, …)`.
- **Contraste WCAG AA** : le défaut connu (D.5.2) corrigé ; le reste des combinaisons de couleurs reprend des paires déjà en usage ailleurs dans l'app (foret/blanc, charbon/manioc, laterite pour le lien "Oublié ?").
- **Aucune résurgence wallet/séquestre** : non applicable — écrans d'authentification pure, aucun solde ni transaction affichés.
- **Validation syntaxique** : Babel (`babel-preset-expo`) sur les 4 écrans + `fr.js`/`en.js` — OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que le Lot 0 (D.4.5) — pas d'ADB/Maestro dans cet environnement d'agent. À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.5

- **5 écrans traités** : 3 retouchés sur maquette (`ConnexionScreen.js`, `InscriptionScreen.js`, `MotDePasseOublieScreen.js`), 1 sans maquette dérivé d'un écran voisin retouché (`ChangerMotDePasseScreen.js`, rendu adaptatif clair/sombre via `useTheme()` puisqu'atteint après connexion, contrairement aux 3 écrans pré-connexion qui gardent une identité de marque fixe), 1 audité et laissé tel quel car déjà conforme (`OnboardingScreen.js`).
- **1 bug de contraste AA préexistant corrigé** comme effet de bord de la refonte (D.5.2), pas comme correction dédiée séparée.
- **2 écarts délibérés vis-à-vis de la maquette**, documentés et justifiés (D.5.3, D.5.4) plutôt que des oublis silencieux.
- **Aucun nouveau composant créé** — `Sillon`/`Galet` ont suffi, conformément au périmètre annoncé du lot.
- **Aucun écran des Lots 2-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- Prochaine étape recommandée : **Lot 2 — Accueil** (`AccueilScreen.js`, écran le plus visible de l'app, mobilise Etal/Echo/Fronton du Lot 0 pour la première fois en conditions réelles). Alternative : **Lot 3 — Commande client : recherche & saisie**, si Cedric préfère enchaîner directement sur le tunnel de commande.

## D.6 — Lot 2 : Accueil (implémentation, 08/07/2026)

Ouvert et clôturé le 08/07/2026, conformément à D.3.2 et au process D.2bis. 1 écran (`client/AccueilScreen.js`), mobilise pour la première fois en conditions réelles les 3 composants Lot 0 identifiés en D.3.2 : Etal, Echo, Fronton. Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 2 ») — ce qui suit résume les décisions et écarts qui méritent de rester dans le CDC.

### D.6.1 Méthode suivie

Contrôle visuel de la maquette `accueil_caarco` (déjà ✅ en C.1, pas de nouveau tri requis) : structure volontairement simple côté Stitch (recherche d'adresse en overlay + bottom sheet avec grille de sélection véhicule 2 colonnes + un unique bouton "Confirmer CAARCO"). L'écran réel est nettement plus riche (stories transporteurs, bannière publicitaire, bannière récompense, carte de réservation, carte OSM avec transporteurs proches, carrousel "Nos Services", rappels de course active/planifiée, CTA, bannière parrainage) — conformément à la consigne, la maquette a servi de référence de principe (structure adresse + sélection véhicule + CTA unique) plutôt que de plan à reproduire à l'identique, et l'architecture d'ensemble n'a pas été redessinée.

Avant toute modification, vérification par grep de la parité i18n `fr.js`/`en.js` (méthode déjà appliquée au Lot 1) : **1383 clés de chaque côté, 0 écart** — confirmé à nouveau après modification, aucune clé nouvelle n'ayant été nécessaire.

### D.6.2 Fusion du CTA dupliqué (checkpoint explicite du Master Prompt)

Deux boutons distincts de l'écran réel menaient au même écran (`Trajet`) sans logique de différenciation : le bouton "Continuer →" (clé `accueil.continuer`) dans la carte de réservation, et un bouton flottant "Commander maintenant" (clé `accueil.commanderMaintenant`) plus bas dans le flux de scroll, après la carte GPS et le carrousel de services. Fusionnés en un unique CTA, conservé dans la carte de réservation (immédiatement visible, sans scroll — comme dans la maquette de référence) et libellé via la clé `accueil.commander` ("Commander une livraison"), qui existait déjà dans `fr.js`/`en.js` mais n'était consommée par aucun écran avant ce lot. Le bouton flottant du bas est supprimé, avec son import dédié (`BoutonAnime`, plus utilisé ailleurs dans le fichier) et ses styles. Le bloc adresses (`adresseBloc`) reste lui-même tactile et navigue directement vers `Trajet` : ce n'est pas traité comme un second CTA concurrent, au même titre que le bloc de recherche d'adresse de la maquette Stitch n'est pas non plus le bouton d'action — c'est une simple affordance de saisie, pas un bouton stylé comme une action à commettre.

### D.6.3 Etal — découverte d'un besoin déjà codé mais jamais branché

Avant de décider comment exercer `Etal`, vérification dans le code réel (même méthode que D.4.2 pour Jauge) : la fonction `categoriesVehicule()` et l'état `CATEGORIES_VEHICULE` étaient déjà présents dans `AccueilScreen.js`, avec des styles dédiés (`categorieGrille`, `categorieCarte`, etc.), mais **aucun JSX ne les consommait** — confirmé par recherche exhaustive dans le fichier. Preuve supplémentaire et plus parlante : la copie du tutoriel intégré de l'écran (clé `accueil.tutoriel.t1desc`) dit déjà *"Appuyez sur 'Commander' ou choisissez une catégorie de véhicule pour démarrer une course"* — un comportement à deux volets qui n'existait pas dans l'écran avant ce lot (seul le "Commander" existait, sans sélection de catégorie associée). Plutôt que de considérer ce code comme mort et de le supprimer, il a été branché via `Etal` (sélection exclusive, état local `categorieChoisie`, défaut "Moto" comme dans la maquette), positionné sous le bloc adresses et juste au-dessus du CTA fusionné — le CTA "Commander" utilise désormais la catégorie sélectionnée pour préremplir le contexte de course avant de naviguer vers `Trajet`. Ce n'est pas un usage forcé d'Etal : c'est la restauration d'un comportement déjà anticipé par la copie existante mais jamais implémenté.

Écart délibéré avec la maquette : `Etal` est utilisé en mode horizontal (scroll), pas en grille 2 colonnes comme dans `accueil_caarco`. Choix fait pour ne pas ajouter de hauteur verticale à un écran déjà signalé comme surchargé (point de vigilance explicite de ce lot) — cohérent avec le carrousel "Nos Services" existant juste en dessous, qui utilise la même logique horizontale.

### D.6.4 Echo — indicateur de recherche sur la bannière de course active

La bannière de rappel "course en cours" (visible quand le client a une course `en_attente`, `acceptee` ou `en_cours`) affichait un simple point statique quel que soit le statut. Remplacé par l'anneau radar `Echo` uniquement quand `statut === 'en_attente'` (recherche de transporteur réellement en cours, temps réel) ; le point statique est conservé pour `acceptee`/`en_cours` (transporteur déjà affecté, ce n'est plus une situation de recherche). Usage fidèle à la définition D.3.1 d'Echo ("indicateur de recherche/attente temps réel, sans valeur chiffrée") plutôt qu'un usage décoratif forcé.

### D.6.5 Fronton — en-tête de section avec action "voir tout"

Appliqué uniquement à l'en-tête de la section "Nos Services" (titre + lien "Voir les tarifs →"), qui portait déjà le couple titre+CTA visé par Fronton, en remplacement du JSX manuel équivalent. **Non appliqué** à l'en-tête de la section carte GPS ("Transporteurs disponibles") : cette section n'a pas d'action "voir tout", seulement un compteur — utiliser Fronton là aurait été un usage forcé, contraire à la consigne. Écart mineur documenté : Fronton utilise la palette statique (`colors.charbon`), pas la palette adaptative (`tc.charbon` via `useTheme()`) que ce titre utilisait auparavant — conforme à la convention majoritaire du Lot 0 (D.4.1 : 32 composants sur 33 en palette statique), avec une petite régression non bloquante en mode sombre limitée à ce seul en-tête.

### D.6.6 Bannière récompense — non touchée

Conformément à la vigilance explicite de ce lot, la bannière récompense (état `recompense`, clés `accueil.surpriseTitre`/`surpriseSous`, modal de révélation liée au mécanisme streak bloqué en C.2 #3/D.3.3) n'a reçu aucune modification — ni layout, ni texte, ni logique. La maquette `accueil_caarco` ne montre d'ailleurs pas cet élément (absent du Stitch de référence, propre au code réel), donc aucune nécessité visuelle n'imposait d'y toucher.

### D.6.7 Nettoyage DoD trouvé en cours de route — hex en dur préexistants

En vérifiant le critère "zéro hex en dur" sur le fichier retouché, 6 occurrences préexistantes ont été trouvées par grep, sans lien direct avec la fusion du CTA mais dans le même fichier concerné par ce lot :
- `'#e8e0d5'` (fond du placeholder de carte pendant le lazy-load) → `colors.brume`, quasi identique visuellement.
- `'#0f141199'` et `'#0f14118c'` (overlays de modales) → `alpha(colors.nuit, 0.6)` et `alpha(colors.nuit, 0.55)`, reproduisant exactement les mêmes octets d'opacité (0x99 et 0x8c) via la fonction `alpha()` déjà en usage ailleurs dans le code (précédent D.5.2).
- `'#ffffff80'` (placeholder d'adresse) → `alpha(colors.blanc, 0.5)`, reproduction exacte (0x80).
- `'#e8d0a0'` (bordure de la bannière parrainage) → `alpha(colors.nere, 0.45)`, approximation visuelle la plus proche (pas de reproduction pixel-exacte possible depuis un token existant).
- `colors.foret10 ?? '#e8f0ea'` : fallback mort — `colors.foret10` existe bel et bien dans `theme.js`, ce fallback ne s'exécutait donc jamais, mais le littéral hex restait présent dans le texte source. Simplifié en `colors.foret10`.

Corrigé comme effet de bord du passage DoD de ce lot, pas comme correction dédiée séparée — même logique que D.5.2 pour le bug de contraste du Lot 1.

### D.6.8 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé nécessaire (`accueil.commander` existait déjà, orpheline, maintenant consommée). Parité fr/en vérifiée programmatiquement avant et après modification : **1383/1383, 0 écart** dans les deux cas.
- **Zéro hex en dur** : corrigé (D.6.7), confirmé par grep après modification (0 résultat) sur `AccueilScreen.js`.
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs introduite — `Etal`/`Fronton` réutilisent leurs styles internes déjà validés AA au Lot 0 (D.4.5) ; les retokenisations D.6.7 reproduisent des valeurs identiques ou visuellement équivalentes aux hex d'origine.
- **Aucune résurgence wallet/séquestre** : confirmé par grep (0 résultat) ; bannière récompense non touchée (D.6.6).
- **Validation syntaxique** : Babel (`babel-preset-expo`) sur `AccueilScreen.js` — OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-1 (D.4.5/D.5.5) — pas d'ADB/Maestro dans cet environnement d'agent. À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.6

- **1 écran traité** (`AccueilScreen.js`), architecture d'ensemble conservée, retouche ciblée sur le CTA et 3 sections précises.
- **1 CTA dupliqué fusionné** en un seul, conforme au checkpoint explicite "1 action principale par écran" du Master Prompt.
- **Etal, Echo, Fronton exercés pour la première fois en conditions réelles** — les trois sur des besoins réels vérifiés dans le code, aucun usage forcé ; un cas notable (Etal) a révélé du code déjà écrit mais jamais branché, dont la copie du tutoriel anticipait déjà le comportement.
- **6 hex en dur préexistants corrigés** en passant (D.6.7), dont un fallback mort qui ne s'exécutait jamais.
- **3 écarts délibérés documentés** vis-à-vis de la maquette ou de l'implémentation précédente (D.6.2 suppression de l'animation du CTA du bas, D.6.3 Etal horizontal plutôt qu'en grille, D.6.5 Fronton en palette statique).
- **Aucun écran des Lots 1, 3-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- Prochaine étape recommandée : **Lot 3 — Commande client : recherche & saisie** (`TrajetScreen.js`, `DetailsColisScreen.js`, `ConfirmationScreen.js`, 3 écrans — mobilise Sentier, Etal (véhicule + mode paiement, déjà rodé sur ce Lot 2), Pochette (photos colis)). Point de vigilance déjà noté en D.3.2 : `ConfirmationScreen` porte le mode paiement direct informatif (§6 règles serveur) — ne rien faire glisser vers un bouton de transaction.

## D.7 — Lot 3 : Commande client — recherche & saisie (implémentation, 08/07/2026)

Ouvert et clôturé le 08/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`TrajetScreen.js`, `DetailsColisScreen.js`, `ConfirmationScreen.js`), mobilise Sentier, Etal et Pochette du Lot 0. Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 3 ») — ce qui suit résume les décisions et écarts qui méritent de rester dans le CDC.

### D.7.1 Méthode suivie

Les 8 maquettes citées en D.3.2 (`planifier_un_trajet_caarco_1`/`_2`, `d_tails_du_colis_caarco_1`/`_2`, `confirmation_de_commande_caarco_1`/`_2`, `paiement_instructions_directes`, `d_tails_du_trajet`) ont été lues intégralement avant toute retouche. Contrairement aux Lots 1-2 où chaque maquette correspondait proprement à un écran, ce lot a montré des correspondances multiples et partielles : plusieurs maquettes proposent des variantes concurrentes du même écran (ex. `planifier_un_trajet_caarco_1` = carte plein écran + bottom sheet compact ; `_2` = carte 45% + panneau bas plus large avec sélecteur véhicule en pilules). Dans ce cas, la structure déjà en place dans le code réel (qui combine des éléments des deux variantes : carte + panneau bas + sélecteur horizontal) a primé sur le choix d'une seule maquette à suivre à la lettre — cohérent avec la consigne de ne pas redessiner l'architecture existante.

### D.7.2 Découverte maquette — deux nouvelles occurrences de la marque "TransLogix"

`planifier_un_trajet_caarco_2` (`<title>` ligne 6, `<h1>` ligne 170) et `confirmation_de_commande_caarco_2` (`<title>` ligne 6) portent encore la marque "TransLogix" — même défaut cosmétique déjà documenté pour 4 autres dossiers en C.2 (`packs_abonnement_transporteur`, `classement_regional_caarco`, `calendrier_marketing_admin_*`), mais non repéré jusqu'ici pour ces deux-là. Aucune action requise sur le code (le code réel n'a jamais porté cette marque) ; correction cosmétique de la maquette HTML à faire seulement si elle est un jour reprise comme référence visuelle. Reporté dans `REFONTE_TRACKING.md` pour qu'une future session ne le redécouvre pas.

### D.7.3 Découverte maquette — `paiement_instructions_directes` contient une UI de transaction, à ne pas reproduire

C.2 #4 avait vérifié que le **code réel** (`ConfirmationScreen.js`) correspondant à cette maquette était conforme (mode `mode_paiement_client` informatif, aucun bouton de transaction). Cette vérification portait sur le code, pas sur le contenu de la maquette elle-même. En l'ouvrant pour ce lot, la maquette s'est révélée porter une **UI de transaction complète** que le code réel n'a jamais eue : un champ de saisie de numéro de téléphone pour Orange Money (avec préfixe "+237" et clavier `tel`), et un bouton d'action "Confirmer le paiement" accompagné d'une icône cadenas et du texte "Transaction sécurisée • Paiement direct au chauffeur". Reproduire ce visuel tel quel aurait recréé l'apparence d'un encaissement in-app — exactement le risque que la vigilance de D.3.2 anticipait pour ce lot, mais sur la maquette elle-même plutôt que sur le code.

Décision : cette maquette n'a pas servi de référence pour le bloc "Mode de paiement" de `ConfirmationScreen.js`. Seule la structure déjà conforme du code existant (deux options mobile money/espèces, aucune saisie de numéro, aucun bouton de transaction, CTA générique "Confirmer la commande" identique au reste de l'écran) a été conservée, seulement reconstruite avec `Etal` pour la sélection. Point ajouté à `REFONTE_TRACKING.md` pour qu'une future session ne recopie pas le champ téléphone ou le CTA de cette maquette si elle est rouverte.

### D.7.4 Etal — deux usages réels sur des sélecteurs déjà exclusifs mais construits à la main

1. **`TrajetScreen.js`, sélection du véhicule** : le code portait déjà un sélecteur à 4 boutons `flex:1` en rangée fixe (bordure et fond changeant selon l'actif) — exactement la sémantique d'`Etal`, construite à la main faute du composant au moment de son écriture. Remplacé directement, mêmes handlers (`setTypeVehicule`/`setCategorieVehicule`), aucun changement de comportement. Seule adaptation nécessaire : `Etal` n'accepte que des icônes `Ionicons`, alors que le code utilisait `MaterialCommunityIcons` (`motorbike`, `car`, `truck-delivery`, `truck`) — remplacées par les équivalents `Ionicons` déjà choisis pour les mêmes véhicules dans `AccueilScreen` au Lot 2 (`bicycle-outline`, `car-outline`, `car-sport-outline`, `bus-outline`), ce qui aligne au passage l'iconographie véhicule entre les deux écrans.
2. **`ConfirmationScreen.js`, mode de paiement** : même constat, un sélecteur à 2 boutons `flex:1` équivalent à `Etal` en miniature. Remplacé en mode grille (`horizontal={false}`) plutôt qu'en boutons pleine largeur — écart délibéré, voir D.7.5.

**Écart délibéré, `TrajetScreen.js`** : la maquette `planifier_un_trajet_caarco_2` affiche un indicatif de prix sous chaque véhicule ("Dès 2k FCFA"...). Non repris : `TrajetScreen.js` calcule un prix réel dépendant de la distance déjà saisie (`calculerPrixAvecTarifs`), afficher un prix par véhicule aurait exigé de recalculer ce prix pour les 4 véhicules simultanément (changement fonctionnel, pas seulement visuel) et les tarifs statiques disponibles par ailleurs (`vehicules.tarifs` en i18n) ne couvrent pas exactement les 4 types utilisés ici (`camionnette` vs `tricycle` — incohérence de données préexistante, hors périmètre de ce lot). Servir un prix approximatif ou incohérent aurait été pire que ne pas en afficher.

### D.7.5 Sentier et Etal — écarts délibérés vis-à-vis de l'implémentation précédente

1. **`Sentier` (bloc trajet, `ConfirmationScreen.js`)** : l'ancien code affichait un couple "DÉPART"/"ARRIVÉE" (légende mono en majuscules) au-dessus de chaque adresse. `Sentier` ne porte pas cette légende (seulement icône + label + sous-label optionnel) — retirée plutôt que forcée dans un `sousLabel` qui aurait inversé la hiérarchie visuelle (l'adresse doit rester l'information proéminente). Compensée par les icônes par défaut de `Sentier` (anneau pour le premier point, pastille pleine laterite pour le dernier), qui reproduisent exactement `trip_origin`/`location_on` de la maquette `confirmation_de_commande_caarco_1` — la légende textuelle devient redondante avec l'icône et la position (1er point = départ, dernier = arrivée), un principe déjà appliqué implicitement ailleurs dans l'app (mêmes couleurs bambou/nere pour départ/arrivée sur `AccueilScreen` et `TrajetScreen`).
2. **`Etal` en mode grille (`ConfirmationScreen.js`, mode paiement)** : remplace 2 boutons `flex:1` pleine largeur par 2 cartes compactes alignées à gauche (comportement par défaut d'`Etal`, qui ne s'étire pas pour remplir la largeur disponible). Changement visuel assumé, cohérent avec l'usage d'`Etal` déjà fait au Lot 2 (AccueilScreen) et au Lot 3 (TrajetScreen) — pas de variante "pleine largeur" ajoutée au composant partagé pour un seul appelant.
3. **CTA du bas ("Commander maintenant", `BoutonAnime`) du Lot 2** : non concerné par ce lot, mentionné ici seulement pour mémoire — aucun écran de ce Lot 3 ne portait de CTA dupliqué à fusionner (chacun des 3 écrans n'avait déjà qu'un seul CTA principal, conforme à la règle avant même ce lot).

### D.7.6 Pochette — zoom photo ajouté sans perdre le choix caméra/galerie

`DetailsColisScreen.js` gérait déjà l'ajout de photos via deux boutons distincts ("Caméra" / "Galerie", `expo-image-picker`), sans aucun moyen de prévisualiser en plein écran une photo déjà ajoutée. `Pochette` couvre exactement ce manque (zoom au tap, `ScrollView` natif) mais son modèle interne n'offre qu'**un seul** bouton d'ajout générique — l'utiliser pour l'ajout aurait supprimé le choix caméra/galerie sans qu'aucune fonctionnalité de remplacement (sélecteur caméra/galerie natif type action sheet) ne soit demandée par ce lot. Décision : `Pochette` est utilisée uniquement pour l'affichage + zoom des photos déjà présentes (`onAjouter` non fourni, donc sa dropzone interne ne s'affiche jamais) ; les deux boutons "Caméra"/"Galerie" existants restent inchangés, juste repositionnés sous la grille `Pochette` au lieu d'à côté des vignettes.

### D.7.7 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé nécessaire sur les 3 écrans. Parité fr/en vérifiée programmatiquement avant et après modification : **1383/1383, 0 écart** dans les deux cas. Clés `confirmation.departLabel`/`confirmation.arriveeLabel` devenues orphelines par le passage à `Sentier` — conservées, non supprimées (même traitement que les orphelines des Lots 1-2).
- **Zéro hex en dur** : `TrajetScreen.js` portait 2 hex en dur préexistants (`'#e8e0d5'`, `'rgba(15,20,17,0.5)'`) — retokenisés (`colors.brume`, `alpha(colors.nuit, 0.5)`). `DetailsColisScreen.js` et `ConfirmationScreen.js` étaient déjà propres. Confirmé par grep après modification (0 résultat) sur les 3 fichiers.
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs introduite — `Etal`/`Sentier`/`Pochette` réutilisent leurs styles internes déjà validés AA au Lot 0 (D.4.5).
- **Aucune résurgence wallet/séquestre** : confirmé par grep (seule occurrence : le commentaire de suppression déjà présent, `ConfirmationScreen.js:18`) ; vigilance spécifique du lot traitée en D.7.3.
- **Validation syntaxique** : Babel (`babel-preset-expo`) sur les 3 fichiers — OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-2 (D.4.5/D.5.5/D.6.8) — pas d'ADB/Maestro dans cet environnement d'agent. À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.7

- **3 écrans traités**, architecture d'ensemble de chacun conservée, retouche ciblée sur les sélecteurs à choix exclusif déjà présents et sur l'affichage photo.
- **Sentier, Etal (2 fois), Pochette exercés** sur des besoins réels vérifiés dans le code (sélecteurs déjà construits à la main, zoom photo manquant) — aucun usage forcé.
- **2 nouvelles occurrences de "TransLogix"** repérées dans les maquettes (D.7.2), cosmétique, non bloquant.
- **1 découverte importante** : la maquette `paiement_instructions_directes` contient une UI de transaction (numéro de téléphone, CTA "Confirmer le paiement"/"Transaction sécurisée") que le code réel n'a jamais eue — non reproduite, la vigilance de D.3.2 s'est révélée fondée sur la maquette elle-même et pas seulement sur un risque théorique (D.7.3).
- **4 écarts délibérés documentés** vis-à-vis des maquettes ou de l'implémentation précédente (D.7.4 prix par véhicule non affiché, D.7.5 légende départ/arrivée retirée et Etal en grille compacte, D.7.6 Pochette sans son propre bouton d'ajout).
- **Aucun écran des Lots 1-2, 4-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- Prochaine étape recommandée : **Lot 4 — Commande client : matching & suivi** (`AttenteScreen.js`, `CourseAccepteeScreen.js`, `SuiviScreen.js`, 3 écrans — mobilise Echo (déjà rodé au Lot 2), Sentier (déjà rodé à ce Lot 3), et `Jalons.js` pour l'ETA — rappel D.4.2 : ne pas chercher de composant "Jauge" séparé, `Jalons.js` en fait déjà office).

## D.8 — Lot 4 : Commande client — matching & suivi (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`AttenteScreen.js`, `CourseAccepteeScreen.js`, `SuiviScreen.js`), mobilise Sentier et Jalons du Lot 0 ; Echo évalué mais non utilisé (voir D.8.3). Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 4 ») — ce qui suit résume les décisions et écarts qui méritent de rester dans le CDC.

### D.8.1 Méthode suivie

Les 7 maquettes citées en D.3.2 (`recherche_de_transporteur_caarco_1`/`_2`, `transporteur_trouv_caarco`, `suivi_en_temps_r_el`, `suivi_en_temps_r_el_caarco_1`/`_2`, `suivi_en_temps_r_el_client`) ont reçu le contrôle visuel rapide recommandé en C.1/D.1 (déjà triées ✅, pas de nouveau tri) : titres, structure et classes d'animation relevés par lecture ciblée plutôt que relecture intégrale des 7 `code.html`, ce lot étant une continuation directe du Lot 3 sur le même contexte de service (`courses.js`, Supabase Realtime) plutôt qu'une famille de maquettes inédite. Contrairement aux Lots 1-3 où chaque composant Lot 0 mobilisé remplaçait un motif déjà construit à la main, ce lot a montré un cas de figure supplémentaire : un composant assigné par D.3.2 (`Jauge`/`Jalons.js`) correspond à un élément réel de la maquette **absent du code existant** — un ajout, pas un remplacement (voir D.8.2).

### D.8.2 Jalons — ajout réel, pas un remplacement

La maquette `suivi_en_temps_r_el_client` contient, sous le bloc "Arrivée estimée / 5 min", une barre de progression continue explicitement commentée `<!-- Jalons (Progress Bar) -->` dans le HTML Stitch lui-même (remplissage `bambou`, largeur `85%`) — preuve directe, dans le nom donné par la maquette source, que ce composant est bien celui identifié en D.3.1 #7 et implémenté en D.4.2 sous le nom `Jalons.js`. `SuiviScreen.js` ne portait qu'un stepper à 3 points discrets (accepté/en route/livré, sémantique Echelon, non concerné par ce lot) — aucune barre continue. Ajouté sous le sous-titre ETA de l'en-tête (`titrePage`/`sousTitre`), alimenté par un pourcentage calculé localement à l'écran : distance restante vers la cible (dépôt ou livraison selon la phase) rapportée à la distance capturée à l'entrée de cette phase (`distanceInitiale`, réinitialisée à chaque changement de phase collecte→livraison). Aucun nouvel appel serveur, aucune donnée supplémentaire requise — uniquement une dérivation de l'état `distanceKm` déjà calculé par l'écran (Haversine). Décision volontaire : pas de `label` passé à `Jalons` (le sous-titre juste au-dessus joue déjà ce rôle), pour rester à 0 nouvelle clé i18n comme les Lots 2-3.

### D.8.3 Echo — évalué, non utilisé sur `AttenteScreen.js`

`AttenteScreen.js` porte déjà un radar entièrement construit à la main (`Radar`/`AnneauPulsant`/`VehiculeOrbital`) : anneaux concentriques statiques, 3 anneaux pulsés animés (même principe que `Echo`), véhicules émoji en orbite calculés par trigonométrie, et un centre figuré (cercle blanc + icône colis). C'est strictement plus riche que `Echo`, qui ne rend que des anneaux pulsés et un point plein central, sans variante pour anneaux statiques, orbite ou icône personnalisée. Deux options envisagées et écartées : (a) remplacer entièrement le radar par `Echo` — régression visuelle nette (perte des véhicules orbitaux et de l'icône colis) sans aucun gain ; (b) composer `Echo` en superposition sous les autres calques pour ne réutiliser que son animation d'anneaux — techniquement possible mais `Echo` impose un point central plein (0,3× sa taille) qui aurait fini cosmétiquement caché derrière le cercle blanc existant, donc rendu sans aucune utilité réelle, juste un calque mort. Conforme à la consigne de session ("utiliser ces composants seulement s'ils correspondent à un besoin réel… vérifier le code existant avant de forcer un composant") : `Echo` a été jugé non pertinent pour ce lot et n'a été utilisé sur aucun des 3 écrans. Aucune extension d'API tentée sur `Echo` pour ce seul appelant (même discipline qu'au Lot 1 avec `Sillon`, D.5).

### D.8.4 Sentier — même usage réel qu'au Lot 3, deux écrans concernés

`AttenteScreen.js` (bloc "Résumé trajet") et `CourseAccepteeScreen.js` (bloc "Résumé trajet" équivalent) portaient chacun un motif dots + trait construit à la main, identique dans son intention à celui déjà remplacé dans `ConfirmationScreen.js` au Lot 3 (D.7.4-D.7.5) — mêmes handlers de données (`depart_adresse`/`arrivee_adresse`), aucun changement de comportement. Remplacés directement par `Sentier` avec ses icônes et couleurs par défaut (anneau foret pour l'origine, pastille laterite pour la destination), plutôt que les couleurs bambou/nere utilisées jusqu'ici sur ces deux écrans. Écart assumé, pas un oubli : ce choix aligne `AttenteScreen`/`CourseAccepteeScreen` sur la palette déjà adoptée par `ConfirmationScreen` (Lot 3, juste avant dans le même tunnel de commande) plutôt que sur celle d'`AccueilScreen`/`TrajetScreen` (Lot 2-3, étape de sélection en amont) — cohérence renforcée à l'intérieur du sous-parcours "commande confirmée" (Confirmation→Attente→CourseAcceptée→Suivi), sans prétendre unifier la totalité de l'app sur un seul jeu de couleurs trajet (hors périmètre de ce lot).

### D.8.5 CTA dupliqué corrigé sur `AttenteScreen.js`, relevé mais non corrigé sur `CourseAccepteeScreen.js`

1. **`AttenteScreen.js`** : à l'état "timeout" (3 minutes sans transporteur), le bloc informatif portait un bouton "← Retour à l'accueil" (fonction `reessayer()`) strictement redondant avec le bouton persistant du pied de page "Annuler la demande" (fonction `annuler()`) — les deux annulaient la course en cours et ramenaient à l'Accueil dans ce même état, uniquement l'un des deux (`reessayer`) relançait silencieusement le minuteur en cas d'échec de l'annulation plutôt que d'afficher une erreur. Supprimé (fonction + bouton), conformément à la règle "1 action principale par écran" déjà appliquée au Lot 2 (D.6.2) — le pied de page reste l'unique CTA de sortie, avec la gestion d'erreur déjà correcte de `annuler()`.
2. **`CourseAccepteeScreen.js`** : la ligne "Suivre en direct" du menu "Que faire ?" et le bouton principal "Suivre la livraison en direct" en bas d'écran appellent tous deux `allerSuivi()`. Différence avec le cas ci-dessus : ce menu propose 4 options réelles et distinctes (appeler/chat/suivre/annuler), pas seulement une action répétée — plus proche d'un menu à options + un CTA de sortie qu'une duplication accidentelle comme au Lot 2. Laissé tel quel, non corrigé : l'écart est réel mais insuffisamment net pour justifier un changement de comportement hors périmètre strict de ce lot (composants Lot 0 + DoD). Noté pour une éventuelle revue future si Cedric souhaite trancher.

### D.8.6 Découverte maquette — deux nouvelles occurrences de la marque "TransLogix"

`recherche_de_transporteur_caarco_1` (`<title>`) et `suivi_en_temps_r_el_caarco_1` (`<title>`) portent encore "TransLogix" — même défaut cosmétique déjà documenté pour 6 autres dossiers (C.2, D.7.2), non repéré jusqu'ici pour ces deux-là. Aucune action requise sur le code (jamais porté cette marque) ; correction cosmétique de la maquette HTML à faire seulement si elle est un jour reprise comme référence visuelle. Reporté dans `REFONTE_TRACKING.md`.

### D.8.7 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé nécessaire sur les 3 écrans. Parité fr/en vérifiée programmatiquement avant et après modification : **1383/1383, 0 écart** dans les deux cas. Clé `attente.retourAccueil` devenue orpheline par la suppression du CTA dupliqué (D.8.5) — conservée, non supprimée (même traitement que les orphelines des lots précédents). Clés déjà orphelines avant ce lot et non touchées : `attente.trouve`, `attente.dispos`, `attente.voirProfil`, `attente.choisir` (vestiges d'un flux de sélection manuelle de transporteur jamais implémenté tel quel dans le code réel, qui sélectionne automatiquement).
- **Zéro hex en dur** : `CourseAccepteeScreen.js` portait 2 hex en dur préexistants (`'#b2d8b2'` ×2) — retokenisés (`alpha(colors.bambou, 0.3)`). `SuiviScreen.js` en portait 2 (`'#e8d0a0'`, `'#0f1411b8'`) — retokenisés (`alpha(colors.nere, 0.35)`, `alpha(colors.nuit, 0.72)` — cette dernière valeur strictement identique à l'octet près à l'original). `AttenteScreen.js` était déjà propre. Confirmé par grep après modification (0 résultat) sur les 3 fichiers.
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs introduite — `Sentier`/`Jalons` réutilisent leurs styles internes déjà validés AA au Lot 0 (D.4.5) ; les retokenisations reproduisent des valeurs identiques ou visuellement équivalentes aux hex d'origine.
- **Aucune résurgence wallet/séquestre** : confirmé par grep (0 résultat) sur les 3 fichiers. Mode de paiement non concerné par ce lot (sélection faite en amont, `ConfirmationScreen.js`, Lot 3).
- **Validation syntaxique — méthode adaptée** : la commande `npx babel --presets babel-preset-expo` (utilisée aux Lots 0-3) échoue dans cet environnement, y compris sur un fichier déjà validé et non modifié du Lot 3 (`ConfirmationScreen.js`, échec reproductible sur de l'optional chaining pourtant déjà en production) — panne d'outillage de l'environnement, pas une régression introduite par ce lot. Validation faite par `@babel/parser` directement (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : OK. À signaler à Cedric — la commande Babel standard mériterait d'être réparée (dépendances `babel-preset-expo` probablement désynchronisées dans cet environnement) avant de s'y refier aveuglément aux prochains lots.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-3 (D.4.5/D.5.5/D.6.8/D.7.7) — pas d'ADB/Maestro dans cet environnement d'agent. À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.8

- **3 écrans traités** : 2 remplacements de motif trajet déjà construit à la main (`Sentier`, même traitement qu'au Lot 3), 1 ajout réel comblant un manque confirmé par la maquette (`Jalons`, barre ETA).
- **Echo évalué et délibérément non utilisé** (D.8.3) — premier cas de ce chantier où un composant assigné par D.3.2 est jugé non pertinent après vérification du code existant, plutôt qu'utilisé par défaut parce que "prévu pour ce lot".
- **1 CTA dupliqué corrigé** (`AttenteScreen.js`, D.8.5.1, même règle qu'au Lot 2 D.6.2) et **1 cas similaire relevé mais non corrigé** (`CourseAccepteeScreen.js`, D.8.5.2, jugé insuffisamment net).
- **2 nouvelles occurrences de "TransLogix"** repérées dans les maquettes (D.8.6), cosmétique, non bloquant.
- **Panne d'outillage de validation syntaxique** détectée (D.8.7) — la commande Babel standard des Lots 0-3 échoue désormais même sur du code non modifié ; contournée via `@babel/parser`, mais à signaler à Cedric pour réparation avant les prochains lots.
- **Aucun écran des Lots 1-3, 5-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- Prochaine étape recommandée : **Lot 5 — Post-course client** (`CourseDetailClientScreen.js`, `NotationScreen.js`, `HistoriqueScreen.js`, 3 écrans — mobilise Étoiles, jamais encore exercé en conditions réelles, et Echelon existant). Écrans de clôture/consultation, risque faible.

## D.9 — Lot 5 : Post-course client (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`CourseDetailClientScreen.js`, `NotationScreen.js`, `HistoriqueScreen.js`), mobilise Étoiles du Lot 0 — premier usage réel depuis sa création ; Echelon évalué mais non utilisé (voir D.9.3). Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 5 ») — ce qui suit résume les décisions et écarts qui méritent de rester dans le CDC.

### D.9.1 Méthode suivie

Les 4 maquettes citées en D.3.2 (`d_tail_de_la_course_caarco`, `noter_le_transporteur`, `mes_courses_caarco_1`/`_2`) ont reçu le contrôle visuel rapide recommandé en C.1/D.1 (déjà triées ✅, pas de nouveau tri) : captures `screen.png` inspectées directement, `code.html` grepé pour les mots-clés à risque (`wallet`, `solde`, `retrait`, `virement`, `séquestre`, `escrow`, `encaissement`, méthode C.4.3 étape 2) et pour `TransLogix`/`<title>`. Contrairement aux Lots 3-4, la vigilance C.4.4 ("classer par capacité, pas par nom" — vérifier aussi le code réel, pas seulement les maquettes) a porté ses fruits dans le sens inverse cette fois : les maquettes elles-mêmes n'ont révélé aucun défaut caché sur le contenu de premier plan (seulement le bottom nav "Wallet" d'une maquette, D.9.5, jamais repris), alors qu'une recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` sur le code réel des 3 écrans a trouvé une résurgence active et non triviale (D.9.4) — confirmation directe de la méthode C.3.2/C.4.4 : le tri visuel des maquettes ne suffit jamais à couvrir le risque, la vérification du code réel reste obligatoire à chaque lot, pas seulement au moment de l'audit initial de la Partie C.

### D.9.2 Étoiles — premier usage réel, bug de couleur trouvé et corrigé dans le composant partagé lui-même

`CourseDetailClientScreen.js` portait une fonction locale `Etoiles({ note })` (lecture seule, note moyenne du transporteur) strictement identique en comportement à `Etoiles.js` (Lot 0, D.4.3) — mêmes règles plein/demi/vide, même couleur unique néré pour tous les états. Remplacement direct, zéro écart de rendu (`valeur={tr.note_moyenne}`, `taille={14}`).

`NotationScreen.js` portait deux fonctions locales dupliquées, `Etoiles` (note globale, 36px) et `EtoilesMini` (4 critères détaillés, 22px), toutes deux **interactives** — premier cas de ce chantier où `Etoiles.js` est exercé en mode saisie, pas seulement en lecture seule. En comparant le comportement local à celui du composant partagé avant de remplacer (discipline déjà appliquée aux Lots 2-4, réutilisée ici), un écart réel est apparu : la branche interactive de `Etoiles.js` tel que livré au Lot 0 utilisait la même `couleur` (néré) pour les étoiles pleines et vides, ne les distinguant que par la forme de l'icône (`star` vs `star-outline`) — alors que l'implémentation locale d'origine de `NotationScreen.js` utilisait `colors.brume` (gris) pour les étoiles non sélectionnées, donnant une distinction visuelle claire sélectionné/non-sélectionné. Remplacer sans corriger aurait constitué une régression UX réelle (perte de contraste fonctionnel entre l'état sélectionné et non sélectionné d'un sélecteur de note), pas seulement un détail cosmétique.

Corrigé directement dans `Etoiles.js` (Lot 0) plutôt que contourné dans l'écran appelant : ajout d'un prop optionnel `couleurVide` (défaut `colors.brume`), utilisé uniquement dans la branche interactive pour les étoiles non remplies ; la branche lecture seule (utilisée par `CourseDetailClientScreen.js`) n'est pas touchée. Extension jugée sûre et justifiée, contrairement à la prudence exercée au Lot 1 sur `Sillon` (D.5, ~30 appelants existants, extension écartée pour ne pas élargir le rayon d'impact) : `Etoiles.js` n'avait **aucun appelant en production avant ce lot** (seul consommateur préexistant : l'écran-catalogue dev-only du Lot 0, `CatalogueComposantsScreen.js`, lui-même corrigé gratuitement par le fix, sans aucun risque de régression ailleurs). `style={{ gap: spacing.souffle }}` passé à chaque appel pour préserver l'espacement d'origine (12px), le composant partagé utilisant un gap de 2px par défaut pensé pour un contexte compact comme la note en ligne de `CourseDetailClientScreen.js`.

### D.9.3 Echelon — évalué, non utilisé

Aucun des 3 écrans ne présente de besoin réel de stepper à états nommés (fait/actif/à venir). `CourseDetailClientScreen.js` affiche le statut résolu d'une course via `Cachet` (tampon, déjà en place, pas un stepper) ; la maquette `d_tail_de_la_course_caarco` elle-même n'affiche qu'un badge "TERMINÉE" au-dessus du contenu, aucune barre de progression à étapes. Même discipline qu'au Lot 4 avec `Echo` (D.8.3) : composant assigné par D.3.2 sur la base de l'inventaire initial, réévalué à l'ouverture du lot contre le besoin réel des 3 écrans et des 4 maquettes contrôlées, puis délibérément écarté plutôt qu'utilisé par défaut parce que "prévu pour ce lot".

### D.9.4 Découverte — résidu wallet actif dans `HistoriqueScreen.js`, trouvé par recherche de mots-clés sur le code réel, pas par le tri des maquettes

`HistoriqueScreen.js` affichait, dans le pied de chaque carte de course, une vignette de mode de paiement pilotée par `course.methode_paiement` — une colonne DB héritée du modèle de paiement séquestre aboli, avec un CHECK constraint `IN ('online', 'wallet', 'especes')` (migration `039_methode_paiement_especes.sql`, défaut `'online'`), distincte du champ actuellement correct `mode_paiement_client` (`especes`/`mobile_money` uniquement) écrit par `ConfirmationScreen.js` (Lot 3). Concrètement : `course.methode_paiement === 'wallet'` déclenchait une icône `wallet-outline` et le libellé `t('historique.paiementWallet')` → **"Wallet"**, affiché tel quel au client dans son historique de courses. Aucune des 4 maquettes contrôlées ne suggérait ce comportement — la découverte vient exclusivement du grep de mots-clés à risque sur le code réel (méthode C.4.3 étape 2, C.3.2), confirmant que le residu peut survivre indépendamment de toute maquette, exactement le type de risque que C.4.4 a formalisé après la découverte du trigger `after_course_terminee` en C.3.2.

Vérification de la portée avant correction : `coursesClient()`/`SELECT_CLIENT_LISTE` (`services/courses.js`), seule requête alimentant `HistoriqueScreen.js`, est **exclusivement consommée par cet écran** (recherche exhaustive dans `App/src` : aucun autre appelant) — la correction ne pouvait donc pas avoir d'effet de bord sur un écran d'un autre lot. Corrigé : `labelsPaiement()` ne mappe plus que `especes`/`mobile_money` (réutilisant les clés i18n déjà existantes `confirmation.especes`/`confirmation.mobileMoney`, aucune nouvelle clé) ; le rendu de la vignette et la requête `SELECT_CLIENT_LISTE` lisent désormais `mode_paiement_client` au lieu de `methode_paiement`. La clé `historique.paiementWallet` devient orpheline (conservée, non supprimée — même traitement que toutes les orphelines des lots précédents, D.5-D.8).

**Point de vigilance résiduel, explicitement hors périmètre de ce lot** : la colonne `courses.methode_paiement` elle-même (et sa valeur historique `'online'`) reste lue ailleurs dans le code — `TableauBordScreen.js` (Lot 7), `RevenusScreen.js` (Lot 8), `CoursesEnCoursAdminScreen.js` (Lot 13) et `SuiviScreen.js` (Lot 4, déjà clos, non retouché ici puisque hors périmètre de cette session). Ces 4 usages n'ont pas été vérifiés pour un affichage "wallet" équivalent — à faire avec la même méthode (grep de mots-clés sur le code réel, pas seulement sur les maquettes) à l'ouverture de chacun de ces lots respectifs, pas dans cette session.

### D.9.5 Découverte maquette — bottom nav de `mes_courses_caarco_2` contient un onglet "Wallet", non repris

Le bas de la maquette `mes_courses_caarco_2` (confirmé à la fois visuellement sur `screen.png` et textuellement dans `code.html` lignes 241-242) porte une barre de navigation à 4 onglets Home/Orders/**Wallet**/Profile (icône `account_balance_wallet`, libellé "Wallet"). Ce bloc n'a jamais été repris — l'app utilise sa propre navigation bas de page (`BottomNav`, composants réels du projet), jamais celle codée en dur dans une maquette Stitch. Mentionné ici uniquement au titre de la vigilance C.4.4 (aucune action de code nécessaire, aucune régression : ce bloc n'a jamais été construit). `mes_courses_caarco_1` reconfirme par ailleurs le résidu de marque "TransLogix" déjà noté en D.2.3 — rien de nouveau, cohérent avec l'inventaire existant.

### D.9.6 Écart avec la maquette, documenté — bloc "Détail du paiement" de `d_tail_de_la_course_caarco` non repris

La maquette affiche un bloc détaillé (Tarif de base, Distance, Frais de service, Total payé) sous la fiche transporteur. Non reproduit : le modèle de données réel ne stocke, par course, que le prix final (`course.prix_fcfa`) — aucune des composantes intermédiaires du calcul n'est persistée en base. Recalculer cette ventilation côté client aurait exigé soit de dupliquer la formule de tarification (règle serveur non négociable, CLAUDE.md §12 — "Calculé côté serveur (Edge Function) UNIQUEMENT"), avec le risque d'afficher un chiffre qui diverge du montant réellement facturé si la formule évolue côté serveur sans être répliquée ici, soit d'inventer des valeurs pour les besoins de l'affichage — les deux hors de question. Seul le prix total (déjà affiché avant ce lot) reste montré, ce qui est la seule donnée fiable disponible.

### D.9.7 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé nécessaire sur les 3 écrans (les clés `confirmation.especes`/`confirmation.mobileMoney` déjà existantes sont réutilisées pour la correction D.9.4). Parité fr/en vérifiée programmatiquement avant et après modification : **1383/1383, 0 écart** dans les deux cas. Clé `historique.paiementWallet` devenue orpheline (D.9.4) — conservée, non supprimée.
- **Zéro hex en dur** : `CourseDetailClientScreen.js` portait 2 hex en dur préexistants (`'#0f141173'`, `'#e8d0a0'`) — retokenisés (`alpha(colors.nuit, 0.45)`, identique à l'octet près à l'original ; `alpha(colors.nere, 0.35)`, même substitution que celle déjà appliquée au Lot 4 pour ce même hex, D.8.7). `NotationScreen.js` et `HistoriqueScreen.js` étaient déjà propres. Le motif `colors.x + 'hex'` (suffixe alpha en chaîne, ex. `colors.laterite + '60'` dans `CourseDetailClientScreen.js`) n'a pas été retokenisé — conforme à la convention déjà en usage dans les écrans clos des lots précédents (`ConfirmationScreen.js`, `TrajetScreen.js`, `ParrainageScreen.js` portent le même motif, jamais signalé comme un écart en D.5-D.8). Confirmé par grep après modification (0 résultat de hex littéral) sur les 3 écrans.
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs introduite. La correction du prop `couleurVide` sur `Etoiles.js` (D.9.2) restaure exactement le contraste de l'implémentation locale d'origine de `NotationScreen.js` (gris `colors.brume` pour les étoiles non sélectionnées) plutôt que d'en introduire un nouveau.
- **Aucune résurgence wallet/séquestre** : un résidu réel a été trouvé et corrigé dans le périmètre de ce lot (D.9.4) — confirmé par grep (0 résultat) sur les 3 écrans après correction. Point de vigilance résiduel hors périmètre documenté (D.9.4, 4 autres écrans à vérifier à l'ouverture de leurs lots respectifs).
- **Validation syntaxique — méthode adaptée** : `npx babel --presets babel-preset-expo` échoue à nouveau dans cet environnement (même panne d'outillage que le Lot 4, D.8.7, reproduite ici sur du optional chaining non modifié par ce lot) — panne d'outillage de l'environnement, toujours pas réparée depuis le Lot 4. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers modifiés (`CourseDetailClientScreen.js`, `NotationScreen.js`, `HistoriqueScreen.js`, `Etoiles.js`, `services/courses.js`) : OK. À signaler une nouvelle fois à Cedric — la commande Babel standard reste cassée depuis au moins 2 lots.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-4 (D.4.5/D.5.5/D.6.8/D.7.7/D.8.7) — pas d'ADB/Maestro dans cet environnement d'agent. À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.9

- **3 écrans traités** : 2 remplacements de duplication locale de motif étoiles par le composant partagé `Etoiles.js` (1 lecture seule, 1 interactif avec critères multiples), 1 correction de résidu wallet actif (pas cosmétique).
- **1 bug trouvé et corrigé dans le composant partagé lui-même** (`Etoiles.js`, D.9.2) plutôt que contourné dans l'écran appelant — possible sans risque puisque aucun appelant en production n'existait avant ce lot ; extension additive (`couleurVide`), rien de cassant.
- **Echo confirmé non pertinent au Lot 4, Echelon confirmé non pertinent ici** (D.9.3) — deuxième cas de ce chantier où un composant assigné par D.3.2 est délibérément écarté après vérification du besoin réel plutôt qu'utilisé par défaut.
- **1 résidu wallet actif trouvé et corrigé** (`HistoriqueScreen.js`, D.9.4) — trouvé par recherche de mots-clés sur le code réel, pas par le tri visuel des maquettes, confirmant une nouvelle fois la méthode C.3.2/C.4.4 ; portée de la correction vérifiée avant modification (requête à appelant unique, aucun effet de bord sur d'autres lots) ; 4 écrans d'autres lots restent à vérifier avec la même méthode à leur ouverture (Lots 4, 7, 8, 13).
- **1 découverte maquette non reprise** (bottom nav "Wallet" de `mes_courses_caarco_2`, D.9.5) — vigilance C.4.4 appliquée, aucune action de code nécessaire.
- **1 écart maquette documenté** (bloc "Détail du paiement" non reproduit, D.9.6) — donnée non disponible côté client, calcul de prix non recalculable côté client par règle serveur non négociable.
- **Panne d'outillage de validation syntaxique toujours non réparée** (D.9.7, identique au Lot 4) — contournée via `@babel/parser`, à signaler de nouveau à Cedric.
- **Aucun écran des Lots 1-4, 6-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- Prochaine étape recommandée : **Lot 6 — Fidélité & réservations client** (`ParrainageScreen.js`, `CoursePlanifieeDetailScreen.js`, `MesCoursesPlanifieesScreen.js`, 3 écrans — mobilise Borne et Echelon, ce dernier à réévaluer sur ce lot plutôt que présumé pertinent après 2 lots consécutifs où il ne l'était pas). 2 des 3 écrans sont sans maquette Stitch (à concevoir sans référence) ; piste indicative trouvée ce lot-ci pour `MesCoursesPlanifieesScreen` : l'onglet "À venir (0)" de la maquette `mes_courses_caarco_2` (D.9.5), sans être une maquette dédiée triée pour cet écran.

## D.10 — Lot 6 : Fidélité & réservations client (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`ParrainageScreen.js`, `CoursePlanifieeDetailScreen.js`, `MesCoursesPlanifieesScreen.js`), mobilise Borne du Lot 0 — premier usage réel depuis sa création — et Echelon, réévalué après avoir été écarté au Lot 5 et cette fois jugé pertinent. Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 6 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.10.1 Méthode suivie

`parrainage_caarco_1`/`_2` ont reçu le contrôle visuel rapide recommandé en C.1/D.1 (déjà triées ✅, pas de nouveau tri) : `screen.png` inspecté, `code.html` grepé pour les mots-clés à risque (`wallet`, `solde`, `retrait`, `virement`, `séquestre`, `escrow`, méthode C.4.3 étape 2). `CoursePlanifieeDetailScreen.js` et `MesCoursesPlanifieesScreen.js` sont sans maquette Stitch dédiée (confirmé D.2.3) — conçus sans référence visuelle directe, avec `mes_courses_caarco_2` (onglet "À venir (0)") comme piste indicative uniquement pour le second, non traitée comme une maquette triée. Conformément à la vigilance C.3.2/C.4.4 (le tri visuel ne suffit jamais), une recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` a été appliquée non seulement aux 3 écrans mais aussi à leurs services (`services/points.js`, fonctions `courses.js` consommées) — méthode identique à celle qui avait trouvé le résidu wallet du Lot 5 (D.9.4).

### D.10.2 Borne — premier usage réel, exactement sur l'écran qui a servi de preuve à sa création

`ParrainageScreen.js` portait un bloc "gains" fait main (icône + titre + montant total FCFA + liste de filleuls générant une commission), correspondant très précisément à la preuve citée en D.3.1 #1 pour justifier la création de Borne (`parrainage_caarco_1` : "Gains cumulés" 120 pts, en grille 2 colonnes avec "Amis Parrainés"). Remplacé par une grille de 2 `Borne` : "Gains de parrainage" (`stats.total_commissions` en FCFA) et "Amis parrainés" (`filleuls.length`). Écart délibéré avec `stats.nombre_filleuls` (disponible dans le même appel RPC mais dérivé de la même table que le total, voir D.10.5) : le second `Borne` affiche `filleuls.length` (issu de `obtenirFilleuls()`, tous les filleuls inscrits, indépendant du mécanisme de commission) plutôt que `stats.nombre_filleuls` (toujours 0 pour la même raison que le total) — un choix de source de données côté écran, sans toucher au backend, qui rend la seconde tuile réellement informative même si la première reste à 0 pour l'instant. La liste de détail par filleul (montant par personne) et l'état vide sont conservés sous la grille, inchangés fonctionnellement.

### D.10.3 Echelon — enfin exercé, après avoir été écarté au Lot 5

`CoursePlanifieeDetailScreen.js` portait un stepper fait main (`ETAPES`, `indexEtape()`, rendu manuel `puce`/`trait`) ne distinguant que 2 états visuels (fait-ou-actif vs à-venir : `i <= etapeActive` contrôlait le même style plein pour l'étape courante et toutes les étapes passées). C'est exactement le rôle d'`Echelon` (Lot 0, D.3.1 #2 : "stepper à états nommés fait/actif/à venir"), déjà assigné et évalué sans être retenu au Lot 5 (D.9.3) faute de besoin réel constaté sur les 3 écrans traités à l'époque. Ici le besoin est réel et vérifié : remplacé directement (`etapes` = les 4 libellés déjà traduits via les clés existantes `coursesPlanifiees.detailEtape*`, `etapeActive` = `indexEtape(course.statut)`, logique de mapping statut→index non touchée). Gain réel, pas seulement cosmétique : Echelon distingue 3 états (fait = coche + bambou, actif = numéro + foret, à venir = numéro + brume) là où l'implémentation locale n'en distinguait que 2 — un utilisateur voit désormais clairement quelle étape est en cours, pas seulement lesquelles sont dépassées.

### D.10.4 Sentier — besoin transverse imprévu, comblé par un composant déjà du Lot 0

Consigne de la session : si un besoin transverse imprévu apparaît, vérifier d'abord s'il est couvert par un des 12 composants du Lot 0 avant d'en créer un nouveau. Le bloc trajet de `CoursePlanifieeDetailScreen.js` (`trajetLabel`/`trajetTexte` répétés pour départ et arrivée) est structurellement identique au motif déjà résolu par `Sentier` aux Lots 3-4 sur `ConfirmationScreen.js`, `AttenteScreen.js` et `CourseAccepteeScreen.js` (D.7.4, D.8.4) — remplacé (`points={[{label: depart_adresse}, {label: arrivee_adresse}]}`), le prix restant affiché séparément en dessous (hors du rôle de Sentier). Décision documentée de ne **pas** appliquer Sentier à `MesCoursesPlanifieesScreen.js` (écran liste) : le motif compact actuel (une ligne "départ → arrivée" tronquée) reste plus adapté à la densité d'une `FlatList` que le rendu vertical à 2 points de Sentier, cohérent avec `HistoriqueScreen.js` (Lot 5) qui garde lui aussi son propre motif compact en carte de liste plutôt que Sentier.

### D.10.5 Découverte — un résidu wallet cosmétique trouvé et corrigé, et une découverte architecturale plus sérieuse trouvée mais non corrigée (décision Cedric requise)

**Résidu cosmétique, corrigé dans le périmètre de ce lot** : le libellé visible au client sur la tuile de gains était `t('parrainageEcran.gainsTitre')`, dont la valeur littérale était **"Gains wallet"** (`en.js` : "Wallet earnings"), accompagné d'une icône `wallet-outline`. Aucune des 4 maquettes contrôlées ne suggérait ce texte — trouvé par grep sur le code réel (`fr.js`/`en.js`), pas par le tri visuel, même méthode que la découverte D.9.4 du Lot 5. Corrigé : fr "Gains de parrainage", en "Referral earnings", icône `cash-outline`. Vérification de portée : `gainsTitre` n'a qu'un seul point de consommation (`ParrainageScreen.js`), correction sans effet de bord.

**Découverte architecturale, plus sérieuse, non corrigée dans ce lot (hors périmètre visuel)** : le champ `stats.total_commissions` affiché dans la tuile "Gains de parrainage" provient de `get_stats_parrainage()` (RPC), qui lit exclusivement la table `commissions_parrainage`. Recherche exhaustive dans `App/supabase/migrations` : **cette table n'est écrite que par la RPC `liberer_sequestre_course()`** (définie en migration 032, mise à jour en 033) — et `liberer_sequestre_course()` n'est, comme déjà établi en C.3.2, atteignable que via `terminer_livraison()`, elle-même appelée nulle part dans `App/src` (reconfirmé par grep dans cette session). Vérification complémentaire propre à ce lot, absente de C.3.2 : le flux de commission réellement actif aujourd'hui (`confirmer_livraison()` → `debiter_commission_tc()`, migrations 082/085) a été grepé pour `parrain`/`commissions_parrainage` — **zéro occurrence**. Autrement dit, le modèle TC n'a jamais reçu d'équivalent du mécanisme de commission-parrainage de l'ancien modèle séquestre : `commissions_parrainage` est une table structurellement vide sous le flux actuellement actif, et `total_commissions` affichera **0 FCFA pour la totalité des utilisateurs**, indéfiniment, tant que ce mécanisme n'est pas porté sur `debiter_commission_tc()` ou remplacé par autre chose.

Nuance avec le bug déjà connu de `MerciScreen.js` (C.2 #3, "+100 XAF") : ici le chiffre affiché (0) n'est pas mensonger — c'est un total réellement nul, pas une promesse non tenue affichée comme acquise. Le point réellement problématique est ailleurs, dans la copie déjà existante (non modifiée par ce lot) : `parrainageEcran.etape3` ("Vous gagnez 20 pts + 50 % de leurs points de course **+ une commission FCFA sur chaque livraison terminée**") promet un mécanisme qui ne se déclenche structurellement jamais aujourd'hui sous le modèle TC. Ni "solde", "wallet", "retrait", "virement", "séquestre" ni "escrow" n'apparaissent dans ce texte — il ne déclenche donc pas le critère DoD "aucune résurgence wallet/séquestre" au sens strict de la grille C.4.3, mais relève de la même famille de risque que C.2 #3 (promesse non honorée). **N'a pas été corrigé dans ce lot** : modifier cette copie sans trancher au préalable si le mécanisme doit être porté sur le modèle TC (option a) ou si la promesse doit être retirée/ajustée (option b) aurait été une décision produit unilatérale, hors du périmètre "refonte visuelle" de cette session — même logique que celle qui maintient `PointsScreen.js`/`MerciScreen.js` bloqués en D.3.3. **Décision Cedric à prendre**, non urgente (aucune fuite d'argent, aucun chiffre trompeur affiché — contrairement aux 2 points 🔴 de C.3.2), mais à trancher avant que `ParrainageScreen.js` ne soit présenté comme un mécanisme de motivation crédible aux transporteurs/clients fondateurs.

### D.10.6 Découverte maquette — même résidu bottom-nav "Wallet" que D.9.5, rien de nouveau

`parrainage_caarco_1`/`_2` portent, comme `mes_courses_caarco_2` (D.9.5), un onglet de navigation bas de page "Wallet" (`account_balance_wallet`, y compris dans la nav web desktop de `parrainage_caarco_1` ligne 158). Jamais repris (l'app utilise sa propre navigation bas de page) — aucune action de code nécessaire, cohérent avec la vigilance déjà actée.

### D.10.7 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé. 1 nouvelle clé (`parrainageEcran.filleulsTitre`, libellé de la 2ᵉ tuile Borne). Parité fr/en vérifiée programmatiquement avant (1383/1383) et après (**1384/1384, 0 écart**) modification. La clé existante `parrainageEcran.gainsTitre` a été recopiée (valeur corrigée des deux côtés, D.10.5) sans changer le compte de clés.
- **Zéro hex en dur** : `ParrainageScreen.js` portait 2 hex en dur préexistants — `'#e8d0a0'` retokenisé en `alpha(colors.nere, 0.35)` (même substitution qu'aux Lots 4-5 pour ce hex identique) ; `'#25D366'` (vert de marque WhatsApp officiel, déjà présent à l'identique dans `ProfilPublicScreen.js`, hors périmètre) conservé avec un commentaire d'exception documentée, conforme à la règle du Master Prompt ("documented exceptions require a comment"). `CoursePlanifieeDetailScreen.js` et `MesCoursesPlanifieesScreen.js` étaient déjà propres (0 hex avant et après). Confirmé par grep sur les 3 fichiers.
- **Contraste WCAG AA** : aucune nouvelle combinaison hors des tokens déjà validés — `Borne`/`Echelon`/`Sentier` réutilisent leurs styles internes du Lot 0 (déjà validés AA) ; les pilules d'onglets de `MesCoursesPlanifieesScreen.js` (fond `colors.foret` + texte `colors.blanc`) offrent un contraste largement supérieur au seuil AA, sans rapport avec le cas limite blanc/néré déjà documenté (§0.2).
- **Aucune résurgence wallet/séquestre** : 1 résidu cosmétique trouvé et corrigé (libellé "Gains wallet" + icône `wallet-outline`, D.10.5) — confirmé par grep (0 résultat) sur les 3 écrans et leurs services après correction. 1 découverte architecturale trouvée, documentée, **non corrigée** car hors périmètre visuel et nécessitant une décision produit de Cedric (D.10.5) — ne constitue pas un résidu wallet/séquestre au sens strict de la grille C.4.3 (aucun des mots-clés n'apparaît), mais mérite un suivi.
- **Cible tactile ≥52px** : les onglets de `MesCoursesPlanifieesScreen.js`, jusqu'ici implicitement proches de 52px sans garantie, sont désormais explicitement fixés à `minHeight: 52`.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement — reproduit explicitement sur `CoursePlanifieeDetailScreen.js` (`e?.message`, optional chaining), même panne d'outillage que les Lots 4-5 (D.8.7, D.9.7), non réparée. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers modifiés (`ParrainageScreen.js`, `CoursePlanifieeDetailScreen.js`, `MesCoursesPlanifieesScreen.js`, `fr.js`, `en.js`) : OK. À signaler une nouvelle fois à Cedric — la commande Babel standard reste cassée depuis au moins 3 lots.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-5 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.10

- **3 écrans traités** : 1 reconstruction de bloc KPI en `Borne` (`ParrainageScreen.js`, premier usage réel du composant), 1 remplacement de stepper manuel par `Echelon` + remplacement de bloc trajet par `Sentier` (`CoursePlanifieeDetailScreen.js`), 1 restylage de bascule d'onglets sans maquette dédiée (`MesCoursesPlanifieesScreen.js`).
- **Borne exercé pour la première fois**, exactement sur l'écran qui avait servi de preuve à sa création (D.3.1 #1) — confirmation directe que le composant répond au besoin identifié.
- **Echelon enfin jugé pertinent**, après avoir été écarté au Lot 5 faute de besoin réel — même discipline de réévaluation à chaque lot plutôt que d'utilisation par défaut, cette fois avec un résultat positif et un gain UX réel (3 états au lieu de 2).
- **Sentier réutilisé sur un besoin transverse imprévu** (non assigné par D.3.2 à ce lot), conformément à la consigne de vérifier d'abord les 12 composants du Lot 0 avant d'en créer un nouveau — décision documentée de ne pas l'appliquer à l'écran liste du même lot.
- **1 résidu wallet cosmétique trouvé et corrigé** (libellé "Gains wallet" + icône, `ParrainageScreen.js`) — trouvé par grep sur le code réel, pas par le tri des maquettes, confirmant une nouvelle fois la méthode C.3.2/C.4.4.
- **1 découverte architecturale nouvelle, distincte des 2 points 🔴 déjà connus de C.3.2** : le mécanisme de crédit de commission parrainage (`commissions_parrainage`/`liberer_sequestre_course`) n'a jamais été porté sur le modèle TC actif — la tuile "Gains de parrainage" affichera 0 FCFA pour tous les utilisateurs indéfiniment, et la copie `etape3` promet un mécanisme mort. Non corrigé (décision produit hors périmètre visuel), à trancher avec Cedric : porter le mécanisme sur `debiter_commission_tc()`, ou ajuster/retirer la promesse.
- **Aucun écran des Lots 1-5, 7-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché — `PointsScreen.js`/`MerciScreen.js` en particulier non ouverts malgré leur proximité thématique avec la découverte D.10.5, aucune des 2 corrections backend 🔴 de la Partie C touchée — périmètre respecté.
- Prochaine étape recommandée : **Lot 7 — Tableau de bord & mission transporteur** (`TableauBordScreen.js`, `CourseScreen.js`, `NavigationScreen.js`, 3 écrans — mobilise Echo et Sentier, déjà rodés côté client aux Lots 2-4 et 6, plus Jalons pour l'ETA). Point de vigilance à emporter : `TableauBordScreen.js` fait partie des 4 écrans identifiés en D.9.4 comme lisant potentiellement encore `courses.methode_paiement` (résidu analogue à celui corrigé sur `HistoriqueScreen.js` au Lot 5, jamais vérifié sur ce fichier) — à contrôler avec la même méthode de grep exhaustif à l'ouverture de ce lot.

## D.11 — Lot 7 : Tableau de bord & mission transporteur (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`TableauBordScreen.js`, `CourseScreen.js`, `NavigationScreen.js`), mobilise Echo (premier usage réel), Sentier (déjà rodé aux Lots 3/4/6) et Jalons (déjà rodé au Lot 4). Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 7 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.11.1 Méthode suivie

Les 3 maquettes (`tableau_de_bord_transporteur`, `d_tails_de_la_mission_1`/`_2`, `navigation_livraison_1`/`_2`) ont reçu le contrôle visuel rapide recommandé en C.1/D.1 (déjà triées ✅, pas de nouveau tri) : `screen.png` inspecté pour chacune, `code.html` lu intégralement pour `tableau_de_bord_transporteur` et `d_tails_de_la_mission_1` (les deux servant de preuve directe à des décisions de composant). Conformément à la vigilance C.3.2/C.4.4 et à la consigne explicite de cette session, une recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` a porté sur les 3 écrans **et** sur les services qu'ils consomment (`services/courses.js`, `services/candidatures.js`, `services/tokensTC.js`, `services/offlineQueue.js`, `services/offlineCache.js`, `services/gps.js`, `services/itineraire.js`) — pas seulement sur les maquettes.

### D.11.2 `TableauBordScreen.js` — découverte majeure : ~240 lignes de code mort (`CarteCourse`) jamais rendu

Avant toute retouche, vérification du rendu réel de l'écran (même discipline qu'aux Lots 2 et 4 pour Etal/Echo) : l'écran a migré à un moment antérieur à ce lot vers une interface plein écran (`CarteLeaflet` + header flottant + bottom sheet swipeable, `BottomSheetCourse`), mais l'ancien composant `CarteCourse` (carte de course en liste verticale, avec sa propre logique d'acceptation, ~240 lignes) et la fonction `ListeVide()` (état vide plein écran) sont restés dans le fichier sans qu'aucun JSX ne les consomme — confirmé par recherche exhaustive de `<CarteCourse` et `<ListeVide` dans le fichier. Un composant `Etoiles` local (rendu d'étoiles, distinct du composant partagé `Etoiles.js` du Lot 0) n'était lui-même consommé que par `CarteCourse`, donc mort par transitivité. `CarteCourse` et `Etoiles` (local) supprimés ; ~13 styles dupliqués/masqués silencieusement (`statutPoint`, `statutTexte`, `bannierePaiement`, `bannierePaiementTitre`, `bannierePaiementSous` — chacun défini deux fois dans le même objet `StyleSheet.create`, seule la dernière définition l'emportant en JavaScript) et ~15 styles exclusivement consommés par le code mort (`entete`, `statutBarre`, `statutBarreActive`, `statutGauche`, `statutPointActif`, `statutTexteActif`, `listeTitre`, `listeTitreTexte`, `liste`, `chargementCentre`, `chargementTexte`, tout le bloc « Carte course ») supprimés après vérification automatisée (script Node comptant les usages de chaque clé de style, zéro faux positif).

`ListeVide()`, plutôt que supprimée, a été reconstruite en indicateur compact « recherche active » : `Echo` (Lot 0, premier usage réel de ce chantier) en radar bambou 22px, accompagné des clés `tableauBord.aucuneCourse`/`demandesTempsReel` — déjà existantes mais orphelines avant ce lot, leur contenu (« Aucune course disponible » / « Les nouvelles demandes apparaîtront ici en temps réel ») anticipant déjà exactement ce comportement, à l'identique du cas Etal du Lot 2 (D.6.3). Câblée sous condition `enLigne && !chargement && !preActiveCourse && courses.length === 0`, comblant un manque réel : rien n'indiquait au TR que l'app écoutait activement de nouvelles courses quand la liste était vide, alors que la maquette elle-même montre ce signal (« Recherche de nouvelles courses… », points animés).

### D.11.3 Sentier appliqué aux 3 écrans, sur des besoins réels distincts à chaque fois

- **`TableauBordScreen.js`** (`BottomSheetCourse`) : bloc adresses (dots colorés + trait manuel, sans nom de composant) remplacé par `Sentier`, avec `sousLabel` conservé (« Collecte »/« Livraison », clés existantes) pour ne pas perdre d'information opérationnelle pour le TR — écart délibéré avec l'usage habituel de `Sentier` sans `sousLabel` (Lots 3/4/6), justifié par le contexte (décision d'accepter une course sous contrainte de temps, contrairement aux résumés de trajet en lecture passive des autres lots).
- **`CourseScreen.js`** : bloc trajet (icônes 18px + label mono + adresse, séparateur horizontal) remplacé par `Sentier`. Preuve directe dans la maquette elle-même : le `code.html` de `d_tails_de_la_mission_1` commente la section `<!-- Section: Itinerary / Addresses (Plaquette + Jalons) -->` — la même confusion de nommage Jalons/Sentier déjà documentée en D.3.1 #2 pour justifier la création de Sentier, retrouvée une seconde fois indépendamment.
- **`NavigationScreen.js`** : voir D.11.4, ajout et non remplacement.

### D.11.4 Jalons — ajout réel sur `NavigationScreen.js`, même schéma qu'au Lot 4

Les deux maquettes `navigation_livraison_1`/`_2` montrent une barre de progression continue sous le bouton « Ouvrir dans Maps », confirmée visuellement (capture inspectée). Le code réel n'affichait aucune progression ETA persistante — seule `BarreInfoNav` (ETA/min/km + Stop) existait, et uniquement pendant la navigation guidée active (`navActive`). Ajouté : une carte « Itinéraire » (nouveau, D.11.3) surmontée d'une barre `Jalons`, alimentée par le même schéma que `SuiviScreen.js` côté client (Lot 4, D.8.2) — distance de référence capturée une fois par phase (`useEffect` réinitialisé sur `course?.statut`), progression = `1 - distanceRestante/distanceInitiale`. Aucune nouvelle lecture GPS : la distance restante recycle un calcul déjà fait à chaque tick dans le watcher GPS existant (`distDestM`, jusque-là écrit dans un state uniquement pendant `navActive`) — un seul `setState` supplémentaire ajouté au même endroit, pour rendre cette valeur disponible en permanence.

### D.11.5 Extension de `Sentier.js` — `couleurLabel`/`couleurSousLabel`, et un risque de régression détecté avant introduction

Avant d'utiliser `Sentier` dans `BottomSheetCourse` et `CourseScreen.js`, vérification du fond sur lequel il allait être posé (même réflexe que pour le contraste, §0.2/D.5.2) : les deux contextes utilisent `{ backgroundColor: tc.blanc }` (thémé, via `useTheme()`), alors que `Sentier.js` n'utilisait que des couleurs statiques (`colors.charbon`/`colors.cendre`, convention majoritaire du Lot 0, D.4.1). Or `tc.blanc` en mode sombre vaut `#1e2e22` (vert très sombre), quasiment identique à `colors.charbon` (`#1d2420`) — poser `Sentier` tel quel aurait rendu son texte pratiquement illisible en mode sombre sur ces deux écrans. Corrigé **avant** d'introduire le bug (pas après coup) : ajout de 2 props optionnels `couleurLabel`/`couleurSousLabel` à `Sentier.js`, valeur par défaut = les couleurs statiques d'origine — extension strictement additive, zéro changement visuel pour les 4 appelants existants des Lots 3/4/6 (aucun ne passe ces props), même méthode que l'extension `couleurVide` d'`Etoiles.js` au Lot 5 (D.9.2). `TableauBordScreen.js` et `CourseScreen.js` passent désormais `tc.charbon`/`tc.cendre`. `NavigationScreen.js` n'en a pas eu besoin : son panneau utilise exclusivement des couleurs statiques (`colors.blanc` pour `clientBloc`, etc., vérifié par recherche de `tc.` dans le fichier — seulement 2 occurrences, toutes hors du panneau), donc aucun risque de ce type sur cet écran.

**Point de vigilance transversal découvert, non corrigé** : le même risque existe déjà, non détecté jusqu'ici, sur `AttenteScreen.js` (Lot 4, D.8.4) — `Sentier` y est posé dans un conteneur `{ backgroundColor: tc.blanc }` sans les nouveaux props de couleur (qui n'existaient pas encore à ce moment-là). Écran déjà clos, hors périmètre de cette session (consigne : ne toucher aucun écran des Lots 1-6) — à corriger explicitement à l'ouverture d'un futur lot touchant `AttenteScreen.js`, ou dans une passe dédiée si le calendrier le permet avant.

### D.11.6 Echelon évalué, non utilisé sur `NavigationScreen.js`

`NavigationScreen.js` porte déjà un stepper horizontal fait main (`PastillePhase` + `barrePhases`, 3 phases Prise en charge/En route/Livré) structurellement proche d'`Echelon` (Lot 0) mais visuellement plus riche : chaque phase affiche une icône distincte (localisation, navigation, coche) même non atteinte, alors qu'`Echelon` affiche un simple numéro pour les étapes non complétées et ne accepte que des libellés texte (`etapes: string[]`). Remplacer aurait appauvri l'affichage sans gain réel ; étendre `Echelon` pour accepter une icône par étape aurait exigé de changer la forme de ses données d'entrée, un risque plus élevé que l'extension additive faite sur `Sentier` (D.11.5), pour un seul appelant existant (`CoursePlanifieeDetailScreen.js`, Lot 6) qui n'a pas ce besoin. Même discipline qu'Echo/`AttenteScreen.js` au Lot 4 (D.8.3) : composant maison déjà riche et fonctionnel, non remplacé faute de gain démontré — décision documentée, pas un oubli.

### D.11.7 Vigilance `methode_paiement` (héritage D.9.4) — traitée sur `TableauBordScreen.js`, aucun affichage « wallet » trouvé

`TableauBordScreen.js` faisait partie des 4 écrans identifiés au Lot 5 (D.9.4) comme lisant potentiellement encore la colonne héritée `courses.methode_paiement` (`online`/`wallet`/`especes`, migration 039) au lieu du champ correct `mode_paiement_client`. Vérifié : une seule occurrence, dans `BottomSheetCourse` — `const estEspeces = course?.methode_paiement === 'especes' || course?.mode_paiement_client === 'especes';`. Contrairement au résidu trouvé sur `HistoriqueScreen.js` au Lot 5, celui-ci ne comparait jamais à `'wallet'` et n'affichait donc aucun libellé « Wallet » — pas une résurgence au sens strict de la grille C.4.3. Simplifié quand même, par cohérence avec le champ désormais seul autoritaire : `estEspeces = course?.mode_paiement_client === 'especes'`, suppression pure et simple de la lecture du champ hérité. **3 écrans restent à vérifier avec la même méthode**, non ouverts dans cette session : `RevenusScreen.js` (Lot 8, confirmé porter une occurrence à la ligne 258 lors d'une vérification croisée), `CoursesEnCoursAdminScreen.js` (Lot 13), et `SuiviScreen.js` (Lot 4, déjà clos — la vérification de D.9.4 le mentionnait déjà, non rouverte ici).

### D.11.8 Découverte — commentaire de documentation « séquestre » obsolète dans un service consommé

`services/offlineQueue.js` (importé par `NavigationScreen.js` pour la file d'actions hors ligne) portait, dans son commentaire d'en-tête, la phrase « changement de statut, **libération séquestre**, notifications » — vestige du modèle séquestre aboli. Vérification des 4 types d'action réellement gérés par `traiterQueue()` (`MAJ_STATUT_COURSE`, `CONFIRMER_LIVRAISON`, `DEBITER_COMMISSION_TC`, `NOTIFIER_CLIENT`) : aucun ne correspond à une « libération séquestre », le commentaire avait simplement dérivé de l'implémentation réelle sans qu'aucun code actif n'y corresponde. Corrigé (commentaire seul, aucune logique touchée) — trouvé par la recherche exhaustive de mots-clés sur les services consommés (D.11.1), pas par le tri des maquettes, confirmant une nouvelle fois la méthode C.3.2/C.4.4.

### D.11.9 Découverte architecturale, non corrigée — `CourseScreen.js` : la branche d'acceptation immédiate (`en_attente`) semble être du code mort

En reconstruisant le bloc trajet (D.11.3), vérification du contexte d'atteinte de l'écran (même réflexe que D.11.2) : `CourseScreen.js` (route `'Course'`) affiche une branche `course.statut === 'en_attente'` avec boutons Accepter/Refuser, mais recherche exhaustive de `navigation.navigate('Course'` dans `App/src` ne trouve que 3 points d'entrée, tous pour des courses `pre_active` (programmées, imminentes) : la bannière « Démarrer » de `TableauBordScreen.js`, la reprise de session au démarrage de l'app (course `pre_active` trouvée en base), et `MesReservationsScreen.js` (Lot 11). L'acceptation d'une course immédiate (`en_attente`) se fait désormais entièrement via `BottomSheetCourse` sur `TableauBordScreen.js` (interface carte + bottom sheet) sans jamais naviguer vers `'Course'` ; `AdDetailScreen.js` (Lot 8), vérifié par précaution, a lui aussi son propre appel direct à `candidaterCourse` sans passer par cet écran. La branche `en_attente` de `CourseScreen.js` — et les fonctions `accepter()`/`refuser()` qui la servent — semblent donc orphelines. **Non supprimée dans ce lot** : confirmer l'absence de tout autre point d'entrée (notification push avec deep-link direct, par exemple) avant de retirer une branche métier active est une décision d'architecture, hors du périmètre « refonte visuelle » de cette session — même prudence que la découverte D.10.5 du Lot 6. Décision Cedric à prendre : vérifier puis soit retirer la branche morte, soit documenter pourquoi elle doit rester.

### D.11.10 Écart avec la maquette, documenté — OTP à 4 cases non reproduit

`navigation_livraison_2` montre le code de livraison sous forme de 4 cases séparées. Le code réel utilise un unique `TextInput` numérique (`maxLength={4}`, clavier numérique, centré) — choix déjà en place avant ce lot. Non reproduit à l'identique de la maquette : ce motif avait été explicitement écarté du Lot 0 en D.3.1 (« OTP à 4 cases, 1 seul écran ») faute de récurrence justifiant un composant partagé, et le reconstruire à la main ici aurait ajouté un risque de gestion de focus (avance automatique, retour arrière) sur l'écran qui déclenche la RPC serveur `confirmer_livraison` — exactement le chemin que la consigne de cette session demandait de ne pas toucher au-delà du visuel. Seul le hex de `placeholderTextColor` de ce champ a été retokenisé (D.11 résumé DoD) ; le comportement et la structure du champ restent inchangés.

### D.11.11 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé sur les 3 écrans (toutes les chaînes nécessaires existaient déjà, certaines orphelines avant ce lot — `tableauBord.aucuneCourse`/`demandesTempsReel` — désormais consommées). Parité fr/en vérifiée programmatiquement avant et après modification : **1384 clés de chaque côté, 0 écart**.
- **Zéro hex en dur** : 7 hex préexistants retokenisés au total (2 `TableauBordScreen.js`, 2 `CourseScreen.js`, 3 `NavigationScreen.js`, dont le placeholder OTP D.11.10) via `alpha()`, mêmes substitutions que les lots précédents pour les valeurs déjà rencontrées. Confirmé par grep après correction (0 résultat) sur les 3 écrans.
- **Contraste WCAG AA** : un risque de régression réel a été détecté et neutralisé **avant** d'être introduit (D.11.5), pas découvert après coup — cas de figure nouveau dans ce chantier. Point de vigilance résiduel documenté sur un écran d'un lot déjà clos (`AttenteScreen.js`), non corrigé (hors périmètre).
- **Aucune résurgence wallet/séquestre** : 1 résidu de commentaire trouvé et corrigé (D.11.8) ; vigilance `methode_paiement` héritée de D.9.4 traitée sur l'écran concerné de ce lot (D.11.7), aucun affichage « wallet » trouvé nulle part. Recherche exhaustive confirmée par grep (0 résultat) sur les 3 écrans et l'ensemble des services qu'ils consomment.
- **Cible tactile ≥52px** : non applicable aux ajouts de ce lot — aucun nouvel élément tactile introduit (l'indicateur de recherche est `pointerEvents="none"`, `Sentier`/`Jalons` sont purement présentationnels).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `TableauBordScreen.js` (optional chaining) — panne d'outillage identique aux Lots 4-6 (D.8.7, D.9.7, D.10.7), toujours non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers modifiés (`TableauBordScreen.js`, `CourseScreen.js`, `NavigationScreen.js`, `Sentier.js`, `offlineQueue.js`) : OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-6 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci vu l'ampleur du nettoyage de code mort sur `TableauBordScreen.js` (aucune régression visuelle attendue, l'ancienne UI liste n'étant de toute façon plus jamais rendue, mais une confirmation reste prudente).

### Synthèse D.11

- **3 écrans traités** : 1 nettoyage majeur de code mort + reconstruction d'un état vide (`TableauBordScreen.js`), 1 remplacement de bloc trajet fait main (`CourseScreen.js`), 1 ajout réel de fonctionnalité visuelle absente (`NavigationScreen.js`).
- **~240 lignes de composant mort supprimées** (`CarteCourse` + `Etoiles` local), ~28 styles morts ou dupliqués/masqués nettoyés, 4 imports morts préexistants retirés (`RefreshControl`, `Pressable`, `categoriesAutorisees`, `appelerUtilisateur`) — le plus gros nettoyage de dette de code mort de ce chantier à ce jour.
- **`Echo` exercé pour la première fois** (indicateur « recherche active »), **`Sentier` réutilisé sur 2 écrans** avec un écart délibéré (`sousLabel` conservé sur `TableauBordScreen.js`), **`Jalons` ajouté sur un 2ᵉ écran** (même schéma qu'au Lot 4).
- **1 extension de composant partagé** (`Sentier.js`, props `couleurLabel`/`couleurSousLabel`) motivée par un risque de contraste détecté **avant** introduction plutôt qu'après — et qui révèle un point de vigilance résiduel sur un lot déjà clos (`AttenteScreen.js`), non corrigé.
- **`Echelon` évalué, non utilisé** — troisième cas de ce chantier (après Echo/Lot 4, Echelon/Lot 5) où un composant Lot 0 est délibérément écarté après vérification du besoin réel.
- **1 résidu wallet/séquestre trouvé et corrigé** (commentaire, `services/offlineQueue.js`) ; **1 vigilance héritée traitée** (`methode_paiement` sur `TableauBordScreen.js`, aucun affichage trouvé) ; **3 écrans restent à vérifier** avec la même méthode à l'ouverture de leurs lots respectifs (`RevenusScreen.js` Lot 8, `CoursesEnCoursAdminScreen.js` Lot 13, `SuiviScreen.js` déjà clos).
- **1 découverte architecturale non corrigée, décision Cedric à prendre** : la branche d'acceptation immédiate de `CourseScreen.js` semble être du code mort (D.11.9) — à trancher avant suppression.
- **1 écart maquette documenté** (OTP à 4 cases non reproduit, D.11.10) — risque jugé disproportionné au gain sur le chemin critique de confirmation de livraison.
- **Aucun écran des Lots 1-6, 8-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée, aucune logique de prix/solde de jetons/validation OTP modifiée — périmètre respecté.
- Prochaine étape recommandée : **Lot 8 — Revenus & jetons transporteur** (`RevenusScreen.js`, `MesTokensScreen.js`, `AdDetailScreen.js`, 3 écrans — mobilise Borne et Silo). Point de vigilance prioritaire : `RevenusScreen.js` ligne 258 confirmée lire `course.methode_paiement` (D.11.7) — jamais vérifiée pour un affichage "wallet" équivalent, à contrôler dès l'ouverture avec la même méthode de grep exhaustif sur le code réel et les services consommés.

## D.12 — Lot 8 : Revenus & jetons transporteur (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`RevenusScreen.js`, `MesTokensScreen.js`, `AdDetailScreen.js`), mobilise Borne (2ᵉ usage réel) et Sentier/Etoiles (déjà rodés). Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 8 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.12.1 Méthode suivie

Les 5 maquettes assignées (`mes_revenus_1`/`_2`, `mes_tokens_de_course_caarco`, `mes_tokens_de_course`, `achat_de_tokens_tc`, `d_tails_de_l_annonce_1`/`_2`) ont reçu le contrôle visuel rapide recommandé en C.1/D.1 (déjà triées ✅/🔧, pas de nouveau tri) : `code.html` lu intégralement pour les 2 `mes_revenus_*` (preuve directe pour la décision Borne), `achat_de_tokens_tc` (vérification du résidu de `<title>`) et `d_tails_de_l_annonce_1` (preuve directe pour la décision Sentier) ; grep textuel exhaustif (`TransLogix|wallet|solde|retrait|séquestre|escrow|virement`) sur les 5 dossiers. Conformément à la vigilance C.3.2/C.4.4 et à la consigne explicite de cette session, une recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` a porté sur les 3 écrans **et** sur les services qu'ils consomment (`services/courses.js`, `services/tokensTC.js`, `services/candidatures.js`, `services/modeConnexion.js`) — pas seulement sur les maquettes.

### D.12.2 `RevenusScreen.js` — vigilance prioritaire traitée : dernière occurrence active de `course.methode_paiement`

La ligne 258 (confirmée au Lot 7, D.11.7) lisait `course.methode_paiement === 'especes'` — comparaison uniquement à `'especes'`, jamais à `'wallet'`, donc pas d'affichage "Wallet" au sens strict de la résurgence trouvée sur `HistoriqueScreen.js` au Lot 5 (D.9.4). Simplifiée par cohérence avec le champ désormais seul autoritaire, même traitement que `TableauBordScreen.js` au Lot 7 (D.11.7) : `course.mode_paiement_client === 'especes'`. La requête source, `coursesTransporteur()` (`services/courses.js:179`), sélectionnait `methode_paiement` — corrigée pour sélectionner `mode_paiement_client`. **Vérification des appelants avant modification** (même discipline que `SELECT_CLIENT_LISTE` au Lot 5, D.9.3) : `coursesTransporteur()` a 2 appelants, `RevenusScreen.js` (ce lot) et `CoursesTransporteurScreen.js` (Lot 11, non ouvert) — ce dernier ne lit ni `methode_paiement` ni `mode_paiement_client` (confirmé par grep), donc le changement de champ sélectionné est sans risque pour lui.

Il ne reste donc plus que 2 écrans non encore vérifiés avec cette méthode parmi les 4 identifiés en D.9.4 : `TableauBordScreen.js` (Lot 7, déjà traité — simplifié mais pas de résurgence trouvée) et `RevenusScreen.js` (ce lot, traité ci-dessus) sont clos ; `SuiviScreen.js` (Lot 4, déjà clos, non rouvert) et `CoursesEnCoursAdminScreen.js` (Lot 13, à faire) restent à contrôler chacun à l'ouverture de leur lot respectif.

### D.12.3 `RevenusScreen.js` — découverte : 7 styles morts hérités d'un bloc "solde retirable" du modèle wallet aboli

Avant toute retouche, vérification de la consommation réelle des styles du fichier (même discipline qu'au Lot 7, D.11.2) : `soldeBloc`, `soldeLigne`, `soldeMontant`, `soldeBtns`, `btnRetraitIcone`, `btnRechargerBloc`, `btnRechargerBlocTexte` étaient définis dans `StyleSheet.create` mais consommés par **aucun** JSX (confirmé par grep, chaque clé n'apparaissant qu'à sa propre définition) — vestiges directs d'un ancien bloc "solde retirable + bouton recharger/retirer" du modèle wallet, dont le JSX a déjà été retiré à un moment antérieur à ce lot sans que les styles associés le soient. Supprimés. Le commentaire de tête du bloc header (« masquée — même raison que le bloc solde retirable plus bas ») pointait vers ce code déjà mort — corrigé pour ne plus référencer un bloc inexistant, en conservant l'intention (expliquer pourquoi l'icône "Encaissement" reste masquée en V1 Play Store). Les styles activement utilisés `btnRetraitBloc`/`btnRetraitBlocTexte` (bouton réel "Gérer mes jetons", vers `MesTokensScreen`) ont été renommés `btnJetonsBloc`/`btnJetonsBlocTexte` — nettoyage de nommage interne, sans changement de comportement, pour ne plus porter le mot « retrait » sur du code actif qui ne retire rien.

### D.12.4 Borne — 2ᵉ usage réel, `RevenusScreen.js`

Les 3 `StatCard` locales (jour/semaine/mois : icône absente, valeur mono néré, libellé, devise en sous-texte) répliquaient une structure très proche de `Borne` sans être le composant partagé. Preuve directe dans la maquette `mes_revenus_2` (contrairement à `mes_revenus_1`, plus dépouillée) : chacune des 3 cartes stats porte une icône Material Symbols (`today`, `date_range`, `calendar_month`) au-dessus du libellé — exactement la structure icône+valeur+libellé de `Borne`. Remplacées par `Borne` avec les équivalents Ionicons vérifiés dans le glyphmap du projet (`today-outline`, `calendar-outline`, `calendar-number-outline`), valeur formatée `"{n} XAF"` en une seule chaîne mono (au lieu de 2 lignes texte séparées comme l'implémentation locale) — même convention que `ParrainageScreen.js` au Lot 6 (`valeur={`${n} FCFA`}`). `Borne` étant à palette statique (D.4.1), la carte perd l'adaptivité `tc.blanc`/`tc.brume`/`tc.cendre` qu'avait `StatCard` — même compromis mineur déjà documenté pour `Fronton` au Lot 2 (D.6, écart n°3), non bloquant.

### D.12.5 Silo évalué, non utilisé — aucun graphique réel dans les 4 maquettes du lot

`Silo` (graphique en barres CSS) est assigné à ce lot par D.3.2 aux côtés de `Borne`. Vérification des 4 maquettes (`mes_revenus_1`, `mes_revenus_2`, `mes_tokens_de_course_caarco`, `achat_de_tokens_tc`) : aucune ne montre de graphique en barres, de courbe ou d'historique visualisé dans le temps — uniquement des cartes KPI ponctuelles (chiffres seuls) et des listes de transactions/missions. Le code réel des 3 écrans du lot ne contient non plus aucune donnée de série temporelle qui appellerait un graphique (`RevenusScreen.js` calcule des totaux ponctuels jour/semaine/mois, pas une série ; `MesTokensScreen.js` n'a qu'un solde instantané + historique linéaire de transactions). Composant assigné par D.3.2, vérifié, jugé non pertinent — même discipline qu'Echo/`AttenteScreen.js` (Lot 4, D.8.3), Echelon/`CourseDetailClientScreen.js` (Lot 5, D.9.5) et Echelon/`NavigationScreen.js` (Lot 7, D.11.6). `Silo` reste donc à ce jour **jamais exercé en conditions réelles** dans ce chantier ; `StatsTransporteurScreen.js` (maquettes `statistiques_performance*`, preuve d'origine D.3.1 #5) est le candidat le plus probable pour son premier usage, à confirmer sans présumer à l'ouverture du Lot 9.

### D.12.6 `MesTokensScreen.js` — code déjà propre reconfirmé, seuls des hex en dur corrigés

Conforme à C.2 #5 : aucune trace de `wallet` dans le fichier ni dans `services/tokensTC.js` — chaque occurrence de « solde » désigne `solde_tc` (TC, système actif, autorisé par CLAUDE.md §2). Aucune retouche structurelle nécessaire. 4 hex en dur retokenisés : `'#ffffff'` → `colors.blanc` (icône de succès, texte de bouton), `'#0f1411b8'` → `alpha(colors.nuit, 0.72)` (overlay modal succès, même valeur déjà substituée aux Lots 4-7), `'#0f141180'` → `alpha(colors.nuit, 0.5)` (overlay modal bottom-sheet choix/récap, alpha distinct — 0x80 = 0.50 contre 0xb8 = 0.72 pour le premier, les deux overlays n'ayant jamais eu la même opacité dans le code d'origine).

### D.12.7 `AdDetailScreen.js` — Sentier et Etoiles appliqués, confirmation de la découverte du Lot 7

Confirmé (D.11.9) : `AdDetailScreen.js` appelle directement `candidaterCourse` (`services/candidatures.js`) sans jamais passer par `CourseScreen.js`. Son bloc « Trajet + distance » (2 lignes dot+trait construites à la main, labels mono « DÉPART »/« ARRIVÉE » puis adresse en dessous) avait donc bien un besoin réel de `Sentier`, non résolu par un autre écran — preuve directe dans la maquette `d_tails_de_l_annonce_1` (icônes `my_location`/`location_on` reliées par un trait vertical, avec un texte principal (l'adresse) et un texte secondaire (l'heure de collecte/livraison) par point). Remplacé par `Sentier` avec le même schéma `label`=adresse (texte principal) / `sousLabel`=descripteur (« DÉPART »/« ARRIVÉE », clés `adDetail.departLabel`/`arriveeLabel` déjà existantes) que `BottomSheetCourse` au Lot 7 (D.11.3) — écran de la même famille fonctionnelle (aperçu de mission transporteur). Écran entièrement en palette statique (aucun `useTheme()`/`tc.` dans le fichier, `Plaquette` en fond `colors.blanc` fixe) : pas de risque de contraste du type D.11.5, donc pas besoin des props `couleurLabel`/`couleurSousLabel` — vérifié explicitement avant d'écarter le besoin, pas supposé.

La fonction locale `Etoiles({ note })` (rendu plein/demi/vide, seuil demi à 0.5, couleur unique néré) dupliquait fonctionnellement le composant partagé `Etoiles.js` du Lot 0 (déjà remplacé une première fois sur `CourseDetailClientScreen.js` au Lot 5, D.9.2) — même comportement visuel pour les valeurs de note usuelles (les deux composants ne divergent que sur le seuil exact de la demi-étoile, 0.5 strict contre la fenêtre [0.25, 0.75) du composant partagé, un écart invisible en pratique pour des notes à un ou deux décimales). Remplacée par le composant partagé (`valeur`, `taille={11}`).

1 hex en dur retokenisé (`'#0f1411f2'` → `alpha(colors.nuit, 0.95)`, fond de la lightbox photo — même valeur déjà en usage sur `CourseScreen.js` au Lot 7).

### D.12.8 Découverte maquette — résidu "Wallet" distinct de "TransLogix" sur 3 dossiers, et un `<title>` "Recharge Rapide Wallet"

Recherche textuelle exhaustive sur les 5 maquettes assignées à ce lot : `mes_revenus_2` porte une bottom nav à 4 onglets avec un onglet **« Wallet »** actif (icône `account_balance_wallet`) et un item de transaction « Retrait -50 000 FCFA · Traité » dans sa liste — même famille de résidu que la bottom nav « Wallet » déjà repérée sur `mes_courses_caarco_2` au Lot 5 (D.9.4bis). `mes_tokens_de_course_caarco` et `mes_tokens_de_course` portent la même bottom nav avec onglet « Wallet » actif. Dans les 3 cas : purement cosmétique, l'app n'utilise jamais ces barres de navigation Stitch (remplacées par sa propre navigation par rôle) — aucune action de code, mentionné pour mémoire (C.4.4) si ces maquettes sont un jour reprises intégralement (pas seulement pour leur mise en page de contenu).

**Découverte distincte, non anticipée par le tracking** (qui ne signalait qu'un risque « TransLogix » sur ces maquettes) : `achat_de_tokens_tc` porte `<title>CAARCO - Recharge Rapide Wallet</title>` — un résidu de nommage différent, vestige probable du dossier ❌ `recharge_rapide_caarco` (C.1) plutôt que de la marque TransLogix. Le `<title>` n'apparaît dans aucun rendu visuel (`screen.png` ou capture) — c'est un tag HTML `<head>`, jamais affiché à l'écran. Le corps entier de la maquette est conforme au flux TC réel (sélection de tokens, Orange Money/MTN MoMo, bouton « Acheter des Tokens de Course », mention Notchpay) : aucune UI de wallet visible. Correction cosmétique du `<title>` seulement si cette maquette est un jour rouverte intégralement comme référence (y compris son code source HTML, pas seulement sa capture visuelle).

### D.12.9 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé sur les 3 écrans (toutes les chaînes nécessaires existaient déjà). Parité fr/en vérifiée programmatiquement (aplatissement récursif + comparaison, script Node jetable) avant et après modification : **1384 clés de chaque côté, 0 écart**.
- **Zéro hex en dur** : 5 hex préexistants retokenisés au total (4 `MesTokensScreen.js`, 1 `AdDetailScreen.js`) ; `RevenusScreen.js` n'en portait aucun. Confirmé par grep après correction (0 résultat) sur les 3 écrans.
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs hors des tokens déjà validés au Lot 0. Vérification explicite du fond sur lequel `Sentier` est posé dans `AdDetailScreen.js` (même réflexe que D.11.5) : écran entièrement en palette statique, aucun risque de régression de contraste en mode sombre détecté (et donc rien à corriger, contrairement au Lot 7 où l'extension `couleurLabel`/`couleurSousLabel` avait été nécessaire).
- **Aucune résurgence wallet/séquestre** : 1 résidu de code mort trouvé et corrigé (D.12.3, 7 styles orphelins « solde retirable », `RevenusScreen.js`) ; vigilance `methode_paiement` héritée de D.9.4/D.11.7 traitée sur le dernier écran qui la portait encore parmi les lots déjà clos (D.12.2). Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` confirmée par grep (0 résultat actif) sur les 3 écrans et l'ensemble des services qu'ils consomment (`courses.js`, `tokensTC.js`, `candidatures.js`, `modeConnexion.js`) — seul le commentaire documentaire légitime du masquage V1 Play Store subsiste, corrigé pour ne plus référencer le bloc mort supprimé.
- **Cible tactile ≥52px** : non applicable aux changements de ce lot — aucun nouvel élément tactile introduit (`Borne`, `Sentier`, `Etoiles` sont purement présentationnels dans les 3 écrans de ce lot).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `AdDetailScreen.js` (`route.params ?? {}`) — même panne d'outillage que les Lots 4-7 (D.8.7, D.9.7, D.10.7, D.11.11), toujours non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 4 fichiers modifiés (`RevenusScreen.js`, `MesTokensScreen.js`, `AdDetailScreen.js`, `services/courses.js`) : OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-7 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.12

- **3 écrans traités** : 1 remplacement de KPI + correction de vigilance + nettoyage de code mort (`RevenusScreen.js`), 1 correction cosmétique pure (`MesTokensScreen.js`, code déjà propre reconfirmé), 1 remplacement de bloc trajet + composant de notation dupliqué (`AdDetailScreen.js`).
- **`Borne` exercé une 2ᵉ fois** (`RevenusScreen.js`, preuve directe dans `mes_revenus_2`), **`Sentier` et `Etoiles` réutilisés** (`AdDetailScreen.js`, déjà rodés). **`Silo` toujours jamais exercé** — assigné par D.3.2, vérifié, écarté faute de graphique réel dans les 4 maquettes du lot (D.12.5), candidat naturel reporté au Lot 9 (`StatsTransporteurScreen.js`).
- **1 résidu de code mort trouvé et supprimé** (7 styles orphelins d'un bloc « solde retirable » du modèle wallet, `RevenusScreen.js`, D.12.3) — dernier maillon de la vigilance `methode_paiement` héritée de D.9.4/D.11.7 traité (D.12.2).
- **2 imports morts préexistants retirés** (`FlatList`, `MesTokensScreen.js` et `AdDetailScreen.js` — ni l'un ni l'autre ne l'utilisait).
- **2 découvertes de maquettes documentées, aucune action de code requise** : bottom nav « Wallet » sur 3 dossiers (D.12.8, même famille que le Lot 5) ; `<title>` « Recharge Rapide Wallet » sur `achat_de_tokens_tc` (D.12.8, résidu distinct de « TransLogix », jamais visible à l'écran).
- **Aucun écran des Lots 1-7, 9-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée, aucune logique de prix/solde de jetons/OTP modifiée — périmètre respecté.
- Prochaine étape recommandée : **Lot 9 — Réputation & stats transporteur** (`StatsTransporteurScreen.js`, `LeaderboardScreen.js`, `NotationClientScreen.js`, 3 écrans — mobilise Silo, Étoiles, Borne). Point de vigilance : `StatsTransporteurScreen.js` a déjà un composant local `CarteStat` (repéré incidemment à sa ligne 306-316 lors de ce Lot 8, props `icone`/`titre`/`valeur`/`sousTitre`/`badge` — **distinct de `Borne`**, pas une réutilisation du composant partagé) qui joue un rôle très proche d'une tuile KPI — à vérifier à l'ouverture si `CarteStat` doit être remplacé par `Borne` (comme `StatCard` sur `RevenusScreen.js` à ce Lot 8) ou s'il porte une fonctionnalité (badge, sous-titre conditionnel) que `Borne` ne couvre pas encore, avant de présumer.

## D.13 — Lot 9 : Réputation & stats transporteur (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 3 écrans (`StatsTransporteurScreen.js`, `LeaderboardScreen.js`, `NotationClientScreen.js`), mobilise Silo (**1er usage réel**) et Etoiles (3 écrans). Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 9 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.13.1 Méthode suivie

Les 4 maquettes assignées (`statistiques_performance`, `statistiques_performance_caarco`, `classement_r_gional_caarco`, `noter_le_client_caarco`) ont reçu le contrôle visuel rapide recommandé en C.1/D.1 (déjà triées ✅/🔧, pas de nouveau tri) : les 2 `statistiques_performance*` lues intégralement (preuve directe pour la décision Silo/CarteStat, voir D.13.3), `classement_r_gional_caarco` et `noter_le_client_caarco` lues intégralement également (grep exhaustif `TransLogix|wallet|solde|retrait` sur les 4 dossiers, voir D.13.4). Conformément à la vigilance C.3.2/C.4.4 et à la consigne explicite de cette session, une recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` a porté sur les 3 écrans **et** sur les services qu'ils consomment (`services/avis.js`, `services/statutConnexion.js`) — pas seulement sur les maquettes. Recherche `course.methode_paiement`/`mode_paiement_client` également faite sur les 3 écrans (consigne explicite de vérifier même en l'absence de présomption) : aucune occurrence, ces écrans ne touchent pas aux données de paiement de course.

### D.13.2 Silo — 1er usage réel du chantier, `StatsTransporteurScreen.js`

`Silo`, assigné dès le Lot 0 (D.3.1 #5) mais jamais utilisé aux Lots 1-8 faute de graphique réel dans les maquettes traitées jusqu'ici (écarté explicitement au Lot 8, D.12.5), trouve enfin un besoin réel confirmé par la maquette `statistiques_performance_caarco` : sa carte héro "Revenus nets" contient un vrai graphique en barres sur 7 jours (LUN→DIM) avec animation et tooltip au survol — et le code réel avait déjà, indépendamment de toute maquette, une fonction locale `BarresJours` faisant exactement ce même travail (7 barres, une par jour, hauteur proportionnelle au nombre de courses livrées ce jour-là), déjà logée dans la même carte "Revenus nets" que la maquette. Remplacée par `Silo` : `donnees={stats.barresData.map(d => ({ label: d.label, valeurs: [d.nb] }))}`, une seule série (`couleur: colors.bambou`), `hauteur={100}` (approxime la hauteur de tracé d'origine, 64px de barres + espace label). Écart mineur documenté : `Silo` ne supporte qu'une couleur uniforme par série, pas de coloration conditionnelle par barre — `BarresJours` distinguait visuellement les jours à 0 course (`colors.brume`, plus terne) des jours actifs (`colors.bambou`) ; ce contraste jour-actif/jour-inactif est perdu, contre l'apport net d'un axe, d'une infobulle au tap et d'une transition plus propre entre lots. Note distincte, non corrigée (hors périmètre visuel) : la carte "Revenus nets" affiche un gros chiffre de revenu total mais son graphique sous-jacent trace en réalité le **nombre de courses livrées par jour**, pas le revenu quotidien — un écart de sémantique interne au code réel, antérieur à ce lot, non introduit ni aggravé par le remplacement de composant (mêmes données, mêmes calculs, seul le rendu change).

### D.13.3 `CarteStat` vs `Borne` — évalué, conservé, non étendu

Contrairement au geste `StatCard`→`Borne` du Lot 8, le composant local `CarteStat` de `StatsTransporteurScreen.js` (repéré au Lot 8, D.12.9 synthèse, props `icone`/`couleurIcone`/`titre`/`valeur`/`sousTitre`/`badge`/`badgeCouleur`) **n'a pas été remplacé par `Borne`**, après lecture du code réel des 4 usages et des 2 maquettes assignées :

- **Preuve maquette** : `statistiques_performance_caarco` (la plus proche de l'écran réel — mêmes pilules de période Semaine/Mois/Tout que `StatsTransporteurScreen.js`) montre ses 4 tuiles de stats secondaires dans l'ordre **icône → titre (`h3` mono) → valeur → sous-titre optionnel** ("Dist: 450 km" sous "28" pour les livraisons, "Moy. 15 km/course" sous "1,200 km" pour la distance) — un ordre différent de celui de `Borne` (icône+delta en tête, puis valeur, puis un unique libellé après la valeur, sans troisième ligne). `statistiques_performance` (l'autre maquette du lot) confirme par ailleurs le motif delta/badge de `Borne` sur sa carte "Courses" (+12%) — mais celle-ci n'a pas de sous-titre, contrairement à `_caarco`.
- **Besoin réel, pas occasionnel** : les 4 usages réels de `CarteStat` dans le code (durée moyenne, courses livrées, courses/jour, jours actifs) utilisent tous `sousTitre` de façon systématique (jamais vide), et chacun utilise une `couleurIcone` distincte (bambou/néré/forêt/latérite) — un codage visuel des 4 catégories de KPI, pas une variation cosmétique isolée.
- **Coût d'une extension disproportionné au gain** : donner à `Borne` ces deux capacités (réordonnancement titre-avant-valeur + troisième ligne de texte, et une couleur d'icône variable) aurait recréé l'anatomie de `CarteStat` à l'intérieur de `Borne`, pour le bénéfice d'un seul écran consommateur — à la différence de l'extension `couleurLabel`/`couleurSousLabel` de `Sentier` (Lot 7, D.11.4), qui était strictement additive (2 props optionnelles, aucun changement visuel pour les appelants existants) et répondait à un vrai risque de régression de contraste évité en amont, pas à une reconstruction de composant.

Décision : `CarteStat` reste tel quel. Même discipline que `Echo`/`AttenteScreen.js` (Lot 4, D.8.3) et `Echelon`/`NavigationScreen.js` (Lot 7, D.11.6) — un motif local plus riche et déjà aligné sur la maquette réelle est conservé plutôt que forcé dans le composant partagé assigné par D.3.2. `Borne.js` n'a reçu aucune modification ce lot-ci.

### D.13.4 Découvertes maquettes

- **"TransLogix" sur 2 dossiers, dont 1 non prévu par D.3.2/C.2** : `classement_r_gional_caarco` portait "TransLogix" à 2 endroits visibles (`<title>` + `<h1>` affiché à l'écran, pas seulement le tag caché) — conforme à C.2 #2, corrigé. **Découverte non anticipée** : `noter_le_client_caarco`, classé ✅ sans réserve en C.1/D.2.4 (aucune mention de "TransLogix" dans le tri initial), porte pourtant le même défaut aux 2 mêmes emplacements — jamais signalé jusqu'ici. Corrigé par la même méthode (les deux maquettes servant de référence structurelle réelle à ce lot, la correction était requise, pas seulement conditionnelle à un usage futur).
- **`noter_le_client_caarco` — critères modélisés en tags binaires dans la maquette, code réel plus riche** : la maquette présente les 4 critères ("Ponctualité", "Communication", "Colis bien préparé", "Disponibilité") comme des boutons-tags à bascule (JS de la maquette : simple toggle de classes CSS, pas de valeur numérique) — alors que le code réel (`NotationClientScreen.js` + `services/avis.js`) capture déjà une **note graduée 1-5 par critère**, en plus de la note globale. Reproduire le motif "tags" de la maquette aurait fait régresser une fonctionnalité déjà en production. Non repris : seul le remplacement des fonctions locales `Etoiles`/`EtoilesMini` par le composant partagé a été fait ; la maquette n'a servi que de confirmation structurelle générale (bannière paiement reçu, avatar+question, note globale en étoiles, zone commentaire, boutons Envoyer/Passer), pas de référence pour la section critères elle-même.
- **Icône "wallet-outline" sur la carte Revenus, résidu cosmétique** : trouvé par la recherche exhaustive de mots-clés sur le code réel (pas sur une maquette) — `StatsTransporteurScreen.js` utilisait l'icône Ionicons `wallet-outline` pour illustrer sa carte "Revenus nets", sans texte "wallet" associé. Corrigée en `cash-outline`, cohérent avec l'icône déjà utilisée pour l'argent/les jetons ailleurs dans l'app (`TableauBordScreen.js`) et avec le geste identique déjà fait sur `ParrainageScreen.js` au Lot 6. Un commentaire de tête (`// transactions_wallet type=recette`, sans impact fonctionnel — le code interrogeait déjà `transactions_tc`) corrigé au passage.

### D.13.5 Nettoyage hex en dur — `LeaderboardScreen.js`

7 hex en dur retokenisés (les 2 autres écrans du lot étaient déjà propres) :
- `'#3db551'` (×3 : pastille "LIVE" de l'en-tête, texte "LIVE", point "en ligne" sur l'avatar du classement) → `colors.bambou` — aucun autre fichier de l'app n'utilise ce hex précis (vérifié par grep), donc aucune convention transverse à respecter ou casser en le retokenisant.
- `'#e8d0a0'` (bordure du bandeau motivationnel) → `alpha(colors.nere, 0.35)` — même substitution qu'aux Lots 4, 5 et 6 pour ce hex déjà rencontré plusieurs fois.
- `'#f0f5f1'` (fond de la ligne "c'est moi" dans le classement) → `alpha(colors.bambou, 0.08)`, teinte pâle cohérente avec le token `bambou` déjà utilisé pour la bordure de mise en évidence de cette même ligne.
- `'#C9A227'`/`'#8C9099'`/`'#A0522D'` (badges or/argent/bronze) : **conservés avec commentaire d'exception documentée** — convention universelle de médaille, hors palette Atelier CAARCO, même principe que le vert de marque WhatsApp déjà excepté dans `ProfilPublicScreen.js`/`ParrainageScreen.js` (Lot 6, D.10.3).

### D.13.6 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : confirmé, 0 nouvelle clé sur les 3 écrans — les 62 clés utilisées (`stats.*`, `leaderboard.*`, `notationClient.*`, `merci.criteres.*`, `courseAcceptee.nombreCourses`) existaient déjà, vérifiées une par une programmatiquement (présentes côté fr **et** en). Parité vérifiée avant et après modification : **1384 clés de chaque côté, 0 écart**.
- **Zéro hex en dur** : 7 hex préexistants retokenisés (`LeaderboardScreen.js`), 3 couleurs de médaille conservées en exception documentée (D.13.5). `StatsTransporteurScreen.js` et `NotationClientScreen.js` n'en portaient aucun. Confirmé par grep après correction (0 résultat hors exception documentée).
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs hors des tokens déjà validés au Lot 0 — `Silo`/`Etoiles` réutilisent leurs styles internes ; aucun des 3 écrans de ce lot n'utilise `Sentier`, donc aucun risque du type D.11.5 à traiter ici.
- **Aucune résurgence wallet/séquestre** : 1 résidu cosmétique trouvé et corrigé (icône `wallet-outline` + commentaire `transactions_wallet`, D.13.4). Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` confirmée par grep (0 résultat) sur les 3 écrans et les 2 services consommés (`services/avis.js`, `services/statutConnexion.js`). `course.methode_paiement`/`mode_paiement_client` : recherché explicitement par grep sur les 3 écrans (consigne de la session, sans présumer de l'absence) — 0 occurrence.
- **Cible tactile ≥52px** : non applicable aux nouveaux éléments de ce lot — `Silo` est purement présentationnel ; les usages d'`Etoiles` remplacent des implémentations déjà interactives avec le même `hitSlop`, aucune régression ni amélioration de zone tactile.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `StatsTransporteurScreen.js` (`badgeCouleur ?? colors.bambou`, nullish coalescing) — même panne d'outillage que les Lots 4-8 (D.8.7 à D.12.9), toujours non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-8 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

### Synthèse D.13

- **3 écrans traités** : 1 remplacement de graphique + conservation documentée d'un composant local + nettoyage cosmétique (`StatsTransporteurScreen.js`), 1 remplacement de composant de notation + nettoyage hex étendu (`LeaderboardScreen.js`), 1 remplacement de composant de notation (`NotationClientScreen.js`).
- **`Silo` exercé pour la première fois** (`StatsTransporteurScreen.js`, preuve directe dans `statistiques_performance_caarco`) — composant assigné dès le Lot 0, resté sans usage réel jusqu'à ce lot (D.12.5). **`Etoiles` réutilisé sur les 3 écrans** (6e-8e usage réel après Lots 5/8). **`Borne` évalué face à `CarteStat`, non utilisé** — décision documentée (D.13.3), aucune extension de `Borne.js`.
- **1 résidu cosmétique wallet trouvé et corrigé** (icône + commentaire, `StatsTransporteurScreen.js`, D.13.4).
- **2 maquettes corrigées** ("TransLogix"→CAARCO), dont 1 découverte non anticipée par le tri C.2 (`noter_le_client_caarco`).
- **1 découverte de divergence maquette/code documentée, non corrigée** : critères de notation en tags binaires dans la maquette vs notes graduées 1-5 déjà en production (D.13.4) — le code réel, plus riche, est conservé.
- **Aucun écran des Lots 1-8, 10-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée.
- Prochaine étape recommandée : **Lot 10 — KYC transporteur** (`SoumissionKYCScreen.js`, `StatutKYCScreen.js`, 2 écrans — mobilise `Pochette`, jamais encore exercé après les Lots 0-9, assigné par D.3.2 pour l'upload CNI/permis/photos véhicule).

## D.14 — Lot 10 : KYC transporteur (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 2 écrans (`SoumissionKYCScreen.js`, `StatutKYCScreen.js`), mobilise `Pochette` — assigné dès le Lot 0 (D.3.1 #4) mais jamais exercé en conditions réelles avant ce lot (les Lots 1-9 ne l'ont pas mobilisé ; confirmé par grep sur `App/src/screens`, seul `App/src/components/Pochette.js` lui-même en contenait le nom avant ce lot). Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 10 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.14.1 Méthode suivie

Les 2 maquettes assignées (`v_rification_kyc_transporteur_1` = "CAARCO - Soumission KYC", `v_rification_kyc_transporteur_2` = "CAARCO - Vérification KYC") ont été lues intégralement (`code.html`, 252 et 295 lignes) plutôt que soumises au seul contrôle visuel de 5 secondes recommandé en C.1/D.1 — conformément à la consigne explicite de cette session pour les maquettes structurantes d'un lot. Cette lecture complète a produit la découverte principale du lot (D.14.5). Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` menée sur les 2 écrans **et** sur le composant `Pochette.js` (consommé par les deux) : aucune résurgence, à l'exception d'un mot « retrait » dans un commentaire de code déjà présent dans `Pochette.js` depuis le Lot 0 (« affiche un bouton retrait par vignette ») — sans rapport avec un retrait financier (retrait = suppression d'une vignette), classé non pertinent au sens de C.4.4 (capacité, pas mot), non modifié. Recherche `course.methode_paiement`/`mode_paiement_client` sur les 2 écrans : 0 occurrence — attendu, ce sont des écrans KYC hors course, vérifié sans présumer comme demandé.

### D.14.2 Pochette vérifié avant réutilisation — pas encore exercé, un défaut d'implémentation trouvé et corrigé

Contrairement à l'hypothèse de départ de cette session (« Pochette déjà rodé au Lot 3 »), la vérification par grep confirme que **le Lot 3 a bien importé `Pochette` sur `DetailsColisScreen.js`**, donc le composant a déjà un usage réel avant ce lot — l'hypothèse était fondée. Ce lot est son **deuxième** terrain d'exercice, pas le premier, sur 2 écrans supplémentaires (3 usages au total désormais).

En relisant `Pochette.js` avant de l'utiliser (discipline C.4.4, vérifier le code réel plutôt que la seule glose), un écart entre la documentation interne du composant et son implémentation a été trouvé : le commentaire d'en-tête promet `fichiers [{ uri, label? }]`, mais le rendu n'affichait jamais `f.label` — la légende par vignette n'existait pas. Ce défaut devient un besoin réel et non couvert dès que `StatutKYCScreen.js` a besoin d'afficher une galerie de documents hétérogènes (CNI, Permis, Véhicule 1-N) où l'identification de chaque vignette est indispensable (D.14.3). Corrigé en extension additive dans `Pochette.js` : un `<Text>` de légende sous chaque vignette, rendu uniquement si `f.label` est fourni — **aucun changement visuel pour l'appelant existant** (`DetailsColisScreen.js`, Lot 3, qui ne passe pas `label`), même discipline que l'extension `couleurLabel`/`couleurSousLabel` de `Sentier` au Lot 7 (D.11.5). Un hex en dur préexistant dans `Pochette.js` (`'#0f1411f0'`, fond du modal zoom, présent depuis le Lot 0) a été retokenisé en passant (`alpha(colors.nuit, 0.94)`) puisque ce fichier est désormais modifié dans ce lot.

### D.14.3 `StatutKYCScreen.js` — Pochette appliqué en lecture seule, remplace un composant local sans zoom ni légende dynamique

La section "Documents" affichait ses 2-5 photos via un composant local `PhotoDoc` (image statique + légende + repli `image-outline` si l'URL échoue), sans aucune interaction — ni zoom, ni tap. Remplacé par `Pochette` en mode lecture seule (ni `onAjouter` ni `onSupprimer` passés — la vignette est alors purement un affichage zoomable, comportement natif du composant, aucune extension requise pour ce cas) : gain net d'un zoom plein écran par document (utile en particulier quand `statut_kyc` est `rejete`/`infos_manquantes`, pour que le transporteur puisse relire ce qu'il a soumis). Les légendes (CNI / Permis / Véhicule {n}) passent désormais par `f.label` (D.14.2). **Écart documenté, assumé** : `PhotoDoc` gérait un repli visuel (`onError`, icône `image-outline`) si l'URL signée échouait à charger — `Pochette` n'a pas cet équivalent, l'`Image` échouée s'affiche alors vide plutôt qu'un espace réservé explicite. Risque jugé faible et non corrigé dans ce lot (deuxième extension de `Pochette.js` non justifiée par un besoin confirmé) : les URLs signées ont une validité de 10 ans (`uploaderDoc`, `SoumissionKYCScreen.js`), l'échec de chargement resterait un cas rare (fichier supprimé du bucket, coupure réseau — ce dernier cas déjà couvert par le `RefreshControl` existant de l'écran).

### D.14.4 `SoumissionKYCScreen.js` — CNI et Permis : Pochette délibérément **non appliqué**, décision documentée

Pour les 2 documents obligatoires (CNI, Permis), le composant local `BlocPhoto` (ligne image + libellé + sous-libellé + coche, tap unique ouvrant `Alert.alert` Caméra/Galerie/Annuler pour ajouter **ou remplacer**) a été **conservé tel quel**, `Pochette` n'y a pas été branché. Raison, vérifiée avant de trancher plutôt que supposée : en mode `multiple={false}`, la dropzone de `Pochette` ne se réaffiche qu'une fois le fichier existant supprimé (`afficherDropzone = onAjouter && (multiple || fichiers.length === 0)`) — brancher `Pochette` ici aurait transformé le remplacement d'un document en 2 gestes (supprimer, puis rouvrir la dropzone) contre 1 seul aujourd'hui, pour un gain de zoom que D.3.1 attribue explicitement à un **autre** écran (« zoom au survol » cité pour `validation_kyc_admin`, pas pour les 2 maquettes de ce lot, qui ne citent que les « dropzones »). Le zoom sur les documents déjà soumis reste disponible côté transporteur via `StatutKYCScreen.js` (D.14.3) une fois le dossier envoyé. Même discipline que les décisions déjà actées aux Lots 4/7/9 (`Echo`/`AttenteScreen.js`, `Echelon`/`NavigationScreen.js`, `CarteStat`/`StatsTransporteurScreen.js`) : un motif local déjà adapté au besoin réel est conservé plutôt que remplacé par défaut.

### D.14.5 Découverte maquette majeure — `v_rification_kyc_transporteur_2` n'est pas un écran de statut, malgré son titre

La lecture intégrale (D.14.1) contredit l'hypothèse de départ de cette session, qui avait résolu l'association `_2` → `StatutKYCScreen.js` sur la seule foi du titre réel de la maquette (« CAARCO - Vérification KYC »), conformément à D.2.4. **Le contenu de `_2` est en réalité une deuxième variante du même formulaire de soumission que `_1`** (3 dropzones/sections « Identité » → CNI recto + CNI verso, « Permis de Conduire », « Photos du Véhicule », numérotées 1/2/3, avec un tiroir de navigation desktop) — pas une page affichant un statut de dossier (en attente/approuvé/rejeté), une bannière de motif de rejet, ou une revue des documents déjà soumis, qui sont pourtant le cœur fonctionnel réel de `StatutKYCScreen.js`. Aucun des deux éléments distinctifs de `StatutKYCScreen.js` (bannière de statut colorée, motif de rejet, badge vérifié) n'apparaît dans `_2`. Le titre HTML seul (« Vérification » vs « Soumission ») ne suffisait donc pas à garantir une correspondance structurelle — exactement le risque que la discipline C.4.4 (« classer par capacité, jamais par nom ») vise à prévenir, ici sur un cas plus bénin qu'un résidu financier (aucune fonctionnalité abolie en jeu), mais de même nature méthodologique : un nom de maquette qui ressemble à l'écran réel peut recouvrir un contenu totalement différent.

**Conséquence sur ce lot** : `_2` n'a servi à aucune retouche structurelle de `StatutKYCScreen.js` — sa structure réelle (bannière statut, motif de rejet, infos véhicule, documents, badge vérifié, CTA resoumettre) est conservée intégralement, elle répond à un besoin fonctionnel qu'aucune des 2 maquettes de ce lot ne documente. Seul le remplacement `PhotoDoc`→`Pochette` (D.14.3) et le nettoyage DoD (D.14.6) ont été appliqués. `_2` a en revanche confirmé, par recoupement avec `_1`, un vrai écart entre les 2 maquettes et le code réel de `SoumissionKYCScreen.js` (CNI recto/verso séparés, 4 photos véhicule nommées dont une "Plaque d'imm.") — traité en D.14.4bis ci-dessous, dans les limites de ce que le schéma de données actuel permet sans migration.

### D.14.4bis Écarts maquette/code trouvés sur `SoumissionKYCScreen.js` — un corrigé (sans migration), un documenté (hors périmètre)

1. **CNI recto/verso — non repris.** Les 2 maquettes présentent 2 dropzones distinctes pour la CNI (recto/verso). Le code réel et le schéma `transporteurs_kyc` (migration initiale + 048-056) n'ont qu'une seule colonne `cni_url` (texte, pas un tableau) — recto/verso séparés impliquerait soit une migration (nouvelle colonne), soit un détournement de `cni_url` en tableau, les deux hors périmètre d'une passe de retouche visuelle (Master Prompt : *"Never add features. This is a hardening pass, not a building pass"*). Non repris, documenté ici pour une future décision produit si Cedric juge le recto/verso nécessaire — comparable dans son traitement à D.9.6 (bloc détail du paiement non reproduit faute de support du modèle de données).
2. **4ᵉ photo véhicule "Plaque d'immatriculation" — repris, sans migration.** Les 2 maquettes suggèrent 4 angles nommés pour les photos du véhicule (Face avant, Profil, Arrière, Plaque d'imm.), alors que le code plafonnait à 3 photos génériques (`vehicule_url`, `TEXT[]` sans contrainte de nombre en base — vérifié dans les migrations). Comme la colonne est déjà un tableau sans limite fixée côté schéma, le plafond client a été porté de 3 à 4 (`ajouterPhotoVehicule`, bouton d'ajout) — changement purement côté app, aucune migration nécessaire. Les 4 emplacements restent génériques (pas de champ dédié "plaque" séparé, qui aurait exigé une colonne distincte) : un texte d'aide (nouvelle clé i18n `kyc.soumission.photosVehiculeAide`) suggère désormais les 4 angles de la maquette sans imposer de slots figés — compromis proportionné, cohérent avec la discipline « extension additive seulement si besoin réel, jamais par défaut » de cette session.

### D.14.6 Nettoyage hex en dur

1 hex en dur trouvé et corrigé sur `StatutKYCScreen.js` (`'#b0ccb0'`, bordure du bloc "Badge Vérifié" sur fond `colors.bambouSoft`) → `alpha(colors.bambou, 0.3)`, même substitution déjà utilisée pour un bloc de succès équivalent sur `CourseAccepteeScreen.js` (Lot 4). 1 hex en dur préexistant trouvé et corrigé sur `Pochette.js` en marge de son extension (D.14.2, voir ci-dessus). `SoumissionKYCScreen.js` : aucun hex en dur, déjà propre.

### D.14.7 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : 1 nouvelle clé (`kyc.soumission.photosVehiculeAide`, fr/en, D.14.4bis) + 1 valeur corrigée sans changement de compte (`kyc.soumission.maxPhotosVehicule` : "3" → "4" photos, les deux langues). Parité vérifiée programmatiquement avant (1384/1384) et après (**1385/1385, 0 écart**) modification. Clés `kyc.soumission.photoVehiculeTitreAlert`/`changer` devenues orphelines par le passage à `Pochette` sur les photos véhicule (l'ancien menu Alert "Changer/Supprimer/Annuler" par photo n'existe plus, remplacé par le bouton retrait natif de `Pochette` + le bouton d'ajout externe déjà existant) — conservées, non supprimées, même traitement que les orphelines des lots précédents.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 3 fichiers modifiés (`SoumissionKYCScreen.js`, `StatutKYCScreen.js`, `Pochette.js`) — 2 hex préexistants retokenisés au total (1 par fichier, D.14.6).
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs hors des tokens déjà validés au Lot 0 — `Pochette` réutilise ses styles internes ; aucun des 2 écrans n'utilise `Sentier`, donc aucun risque du type D.11.5 à traiter ici. Aucun des 2 écrans KYC n'utilise `useTheme()`/mode sombre adaptatif (tous deux en palette statique `colors.*`, cohérent avec la convention majoritaire du projet, D.4.1) — pas de risque de texte illisible en mode sombre du type hérité du Lot 7 (Sentier sur fond `tc.blanc`), cette vigilance ne s'applique pas ici.
- **Aucune résurgence wallet/séquestre** : confirmé par grep exhaustif (D.14.1) sur les 2 écrans et sur `Pochette.js` — 0 résultat pertinent (1 faux positif "retrait" dans un commentaire de code déjà présent, sans rapport financier, non modifié). `course.methode_paiement`/`mode_paiement_client` : recherché explicitement, 0 occurrence, conforme à l'attente (écrans KYC hors course).
- **Cible tactile ≥52px** : aucun nouvel élément tactile introduit hors de ceux déjà conformes de `Pochette` (dropzone 84×84, bouton supprimer avec `hitSlop`) et du bouton "Ajouter une photo du véhicule" existant (`btnAjouterPhoto`, déjà ≥52px avant ce lot).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `StatutKYCScreen.js` (`user?.id`, optional chaining) — même panne d'outillage que les Lots 4-9 (D.8.7 à D.13.6), toujours non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : OK.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-9 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci pour confirmer visuellement le rendu de `Pochette` en mode lecture seule sur `StatutKYCScreen.js`.

### Synthèse D.14

- **2 écrans traités** : `StatutKYCScreen.js` (remplacement `PhotoDoc`→`Pochette`, lecture seule, gain de zoom) et `SoumissionKYCScreen.js` (photos véhicule `BlocPhoto`→`Pochette`, plafond 3→4, CNI/Permis conservés en `BlocPhoto`, décision documentée).
- **`Pochette` exercé pour la 2ᵉ fois du chantier** (après le Lot 3) — un défaut d'implémentation de son API déjà documentée (`label` jamais rendu) trouvé et corrigé en extension additive, à coût nul pour l'appelant existant.
- **1 découverte maquette majeure** : `v_rification_kyc_transporteur_2`, malgré son titre "Vérification KYC" et son classement ✅ résolu en D.2.4, n'est pas un écran de statut — c'est une 2ᵉ variante du formulaire de soumission (D.14.5). La structure réelle de `StatutKYCScreen.js`, plus riche fonctionnellement, est conservée intégralement.
- **2 écarts maquette/code réels identifiés** : CNI recto/verso non repris (limite du schéma, migration hors périmètre) ; 4ᵉ photo véhicule "plaque" reprise sans migration (plafond client 3→4 + texte d'aide, D.14.4bis).
- **Aucune résurgence wallet/séquestre**, aucune lecture de `course.methode_paiement`/`mode_paiement_client` (attendu, écrans hors course).
- **Aucun écran des Lots 1-9, 11-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 2 écrans ci-dessus + `src/components/Pochette.js` (extension additive + 1 hex retokenisé) + `src/i18n/fr.js`/`en.js` (1 clé + 1 valeur corrigée) + `REFONTE_TRACKING.md` + ce fichier (section D.14).
- Prochaine étape recommandée : **Lot 11 — Profil, messagerie & annexes transporteur** (`ProfilClientScreen.js`, `MessagesTransporteurScreen.js`, `MesReservationsScreen.js`, `CoursesTransporteurScreen.js` — mobilise `Echelon`, `Sentier`). Point de vigilance à emporter : D.2.4/D.3.2 signalent une redondance potentielle non résolue entre `transporteur/ProfilClientScreen.js` (ce lot) et `ProfilPublicScreen.js` (Lot 12) — à vérifier à l'ouverture avant de dupliquer l'effort sur les deux.

## D.15 — Lot 11 : Profil, messagerie & annexes transporteur (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 4 écrans (`transporteur/ProfilClientScreen.js`, `transporteur/MessagesTransporteurScreen.js`, `transporteur/MesReservationsScreen.js`, `transporteur/CoursesTransporteurScreen.js`), mobilise `Echelon`/`Sentier` par assignation D.3.2. Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 11 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.15.1 Méthode suivie

Les 2 maquettes assignées (`profil_client_caarco`, `messagerie_transporteur_caarco`) ont été lues intégralement (`code.html`, 284 et 244 lignes) avant tout code, conformément à la consigne de cette session — pas seulement le contrôle visuel de 5 secondes recommandé en C.1/D.1 pour des maquettes déjà classées ✅. `MesReservationsScreen.js` et `CoursesTransporteurScreen.js` sont « sans maquette » (D.2.4) — traités sans référence Stitch, `CoursesTransporteurScreen.js` vérifié contre `client/HistoriqueScreen.js` (Lot 5) avant réutilisation de sa mise en page, plutôt que dérivé aveuglément. Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` menée sur les 4 écrans **et** sur les services qu'ils consomment (`services/courses.js` — `coursesEnAttente`, `coursesTransporteur`, `obtenirCoursesPlanifieesTR`, `annulerCoursePlanifiee` — `services/messages.js`, `services/tokensTC.js`) : aucune résurgence. Recherche `course.methode_paiement`/`mode_paiement_client` sur les 4 écrans et leurs services : **0 occurrence** — reconfirme explicitement, à la date de ce lot, la note du Lot 8 (D.12) selon laquelle `coursesTransporteur()` ne consommait aucun des deux champs ; le fichier n'a pas changé depuis sur ce point.

### D.15.2 Redondance `ProfilClientScreen.js` / `ProfilPublicScreen.js` — clarifiée, pas de fusion

Point de vigilance prioritaire hérité de D.2.4/D.3.2/D.14 (synthèse D.14). Lecture comparée des deux fichiers réels plus vérification de tous les points de navigation (`grep` exhaustif sur `App/src`) :

- **`ProfilPublicScreen.js`** (racine `screens/`) est un profil public **générique** : reçoit soit un objet `utilisateur` complet soit un `utilisateurId` à charger, affiche hero + note + (bloc véhicule si transporteur) + avis récents (table `avis`) + actions de contact (Message → `Chat`, Appel/Vidéo → `Call`). Seul point d'entrée réel trouvé : `client/AccueilScreen.js` (`navigation.navigate('ProfilPublic', { utilisateur: transporteur })`, ×2) — un client consultant le profil d'un transporteur. Bien qu'enregistré dans les 3 navigateurs (`ClientNavigator.js`, `TransporteurNavigator.js` ×4 occurrences de route), **aucun appel réel côté transporteur** n'a été trouvé (`grep` sur `App/src` : zéro `navigate('ProfilPublic', …)` dans un fichier `transporteur/`) — un TR n'a aujourd'hui aucun chemin vers ce profil pour consulter un client.
- **`transporteur/ProfilClientScreen.js`** ne reçoit jamais un `utilisateur`/`utilisateurId` : il reçoit un `course` complet (`navigation.navigate('ProfilClient', { course })`, unique appelant confirmé `TableauBordScreen.js:983`, bouton « voir le client » du bottom sheet de candidature) et affiche l'identité minimale du client (avatar, nom, note, nombre de courses) **comme contexte** d'un bloc « Détails de la mission » dominant (véhicule requis, distance, prix, trajet, heure de la demande). Aucune liste d'avis, aucune action de contact (Message/Appel/Vidéo) dans le code réel avant ce lot.
- **Conclusion, non une fusion** : les deux écrans ne sont pas redondants, ils répondent à des moments différents — `ProfilClientScreen.js` = « fiche de la candidature reçue » (attachée à un `course`, jamais à un `utilisateur` nu), `ProfilPublicScreen.js` = « profil de confiance générique » (avis + contact, attaché à un `utilisateur`, déjà réutilisé pour les deux rôles). Aucun effort dupliqué à consolider : il n'existe **aujourd'hui aucun chemin** permettant à un TR de consulter le profil de confiance complet (avis, contact) d'un client — ni via `ProfilClientScreen.js` ni via `ProfilPublicScreen.js`. Combler ce manque (par ex. un lien « Voir le profil complet » sur `ProfilClientScreen.js` vers `ProfilPublic` avec `utilisateur: client`) réutiliserait l'écran générique existant sans dupliquer sa logique — mais c'est un ajout de capacité (contact pré-acceptation TR→client), hors périmètre d'une passe de refonte visuelle (Master Prompt : *"Never add features"*) et une décision produit potentiellement sensible (permettre à un TR de contacter un client avant d'accepter la course). **Non implémenté, documenté pour décision future de Cedric si souhaité.**
- Cette clarification confirme aussi, a posteriori, que le mapping D.2.4 (`profil_client_caarco` → `ProfilClientScreen.js`) était le bon : le contenu réel de la maquette (bloc « Détails de la mission » — véhicule requis/distance/prix proposé/itinéraire horodaté) correspond structurellement au bloc course de `ProfilClientScreen.js`, pas au profil générique de `ProfilPublicScreen.js` (voir D.15.4).

### D.15.3 Deux bugs réels trouvés et corrigés (pas seulement des écarts cosmétiques)

1. **`ProfilClientScreen.js` — mauvais nom de champ, le compteur de courses du client affichait toujours 0.** Le code lisait `client?.nombre_courses`, mais la requête réelle qui alimente cet écran (`coursesEnAttente()`, `services/courses.js:149`, seule route vers `ProfilClient`) sélectionne `client:users!client_id(id, nom, note_moyenne, nombre_courses_client)` — le champ existant sur l'objet est `nombre_courses_client`, jamais `nombre_courses` (vérifié aussi sur les 3 autres requêtes de `courses.js` qui joignent un client : lignes 149, 200, 341, 412, toutes `nombre_courses_client`). Conséquence : `nbCourses` valait systématiquement `undefined` → replié sur `?? 0`, donc **tout client s'affichait avec « 0 course » quel que soit son historique réel**, un signal de confiance faussé pour le TR au moment précis où il évalue une candidature. Corrigé : `client?.nombre_courses_client ?? 0`.
2. **`CoursesTransporteurScreen.js` — variable hors-scope, l'écran ne pouvait pas s'afficher (`ReferenceError`).** Une passe d'optimisation antérieure non commitée (déjà présente dans l'arbre de travail avant l'ouverture de ce lot — `React.memo`/`useCallback` sur `ItemCourse`) avait déplacé le calcul `enCours`/`passes` à l'intérieur d'un `useMemo` local à `listeCourses`, sans mettre à jour `ListHeaderComponent` plus bas qui référençait encore la variable `enCours` du top-level du composant — laquelle n'existait plus. Cette expression étant évaluée à chaque rendu (JSX de `FlatList`), l'écran plantait avec un `ReferenceError: enCours is not defined` à chaque ouverture, avant même un premier rendu réussi. Corrigé par un `useMemo` dédié (`enCoursCount`), sans toucher au reste de la structure de la liste.

### D.15.4 Traitement des 4 écrans

| Écran | Traitement |
|---|---|
| `transporteur/ProfilClientScreen.js` | `Etoiles` local (dupliquant `Etoiles.js`) remplacé par le composant partagé (`valeur`, `taille={22}`, `style={{gap:3}}` pour préserver l'espacement d'origine — même discipline que les Lots 5/8/9). Bloc trajet (dots + trait manuels, identique au motif déjà converti aux Lots 3/4/6/7/8) remplacé par `Sentier` (`label`=adresse, `sousLabel`=`course.labelDepart`/`labelArrivee`, même convention que `CourseScreen.js`/`AdDetailScreen.js`) — confirmé pertinent par le contenu réel de la maquette (`profil_client_caarco` : icônes `trip_origin`/`location_on` reliées par un trait dans le bloc « Itinéraire »). Bug `nombre_courses` corrigé (D.15.3 #1). Écran entièrement en palette statique (aucun `useTheme()`), donc `Plaquette` est un fond statique `colors.blanc` — la vigilance héritée du Lot 7 (texte `Sentier` sur fond thémé, D.11.5) ne s'applique pas ici, props `couleurLabel`/`couleurSousLabel` non nécessaires. |
| `transporteur/MessagesTransporteurScreen.js` | Correspondance structurelle avec `messagerie_transporteur_caarco` confirmée par lecture intégrale : recherche + 2 catégories (messages directs / courses) + liste de conversations — le code réel organise ces 2 catégories en sections avec badge de compte (`sectionBadge`) plutôt qu'en onglets à bascule comme la maquette, mais c'est une différence d'implémentation équivalente, pas un écart structurel au sens du Lot 10 (D.14.5) : les deux catégories et le badge de compte existent bel et bien, sous une forme différente. Non retouché structurellement (cohérent avec la consigne « contrôle visuel rapide, pas de nouveau tri complet »). Seul changement : 1 hex en dur retokenisé (`'#edf4ef'` → `alpha(colors.bambou, 0.08)`, même substitution que la ligne « sélectionné » du classement au Lot 9). Barre de recherche visible dans la maquette (« Rechercher une conversation... ») absente du code réel — écart documenté, non ajouté : filtrer une liste déjà chargée n'est pas un simple ajustement visuel, cela demande un nouvel état et une nouvelle logique de filtrage, plus proche d'une fonctionnalité que d'un remplacement de composant (le composant `Passoire` qui couvrirait ce besoin est explicitement assigné aux lots admin, pas à ce lot) — laissé pour une décision produit ultérieure si Cedric le souhaite. |
| `transporteur/MesReservationsScreen.js` | Sans maquette (D.2.4). Déjà conforme au DoD avant ce lot : zéro hex en dur, aucune résurgence wallet, i18n complet. `categorie_vehicule` (clé de lookup de la marge de sécurité) vérifié comme une vraie colonne DB distincte de `type_vehicule` (migrations 012/031/054/095) — pas un bug de nommage comme celui trouvé sur `ProfilClientScreen.js`. `Sentier`/`Echelon` évalués, non utilisés : `CarteReservation` affiche le trajet en une seule ligne de texte tronquée (`depart → arrivee`), pas un motif dots/trait à convertir ; aucun état à étapes nommées. Non modifié. |
| `transporteur/CoursesTransporteurScreen.js` | Confirmé dérivé de `client/HistoriqueScreen.js` (Lot 5) — le bloc trajet (`itemTrajet`/`trajetLigne`/`dot`/`trajetConnecteur`) et le style général sont une reprise quasi identique de son motif de carte compacte. Cohérence maintenue avec la décision déjà actée sur `HistoriqueScreen.js` (D.9, non converti en `Sentier` : carte de liste dense, `Sentier` trop spacieux pour ce contexte) — `Sentier` **non utilisé ici non plus**, pour la même raison, appliquée à l'identique plutôt que réévaluée depuis zéro. Bug `enCours` corrigé (D.15.3 #2). `Echelon` évalué, non utilisé (liste de courses passées/en cours via `Cachet`, pas de stepper). |

### D.15.5 Découvertes maquettes

1. **`profil_client_caarco` : résidu de marque « TransLogix »** dans le `<title>` (« Profil Client - TransLogix », ligne 6) — pas dans le `<h1>` visible (« Profil Client », propre). Corrigé dans la maquette, cette dernière ayant servi de référence structurelle active à ce lot (même discipline que les corrections faites au Lot 9 sur des maquettes activement réutilisées, D.13).
2. **`profil_client_caarco` contient un bloc « Avis Récents » et des actions de contact (Message/Appel/Vidéo)** absents du code réel de `ProfilClientScreen.js` — traité en détail en D.15.2/D.15.4 : non repris, ajout de capacité hors périmètre d'une passe de hardening visuel, documenté pour décision future.
3. **`profil_client_caarco` affiche un tag « Client Premium • Depuis 2021 »** sous le nom — aucune notion de palier client ni de date d'ancienneté n'existe dans le modèle de données réel (`users` ne porte ni `tier`/`palier` ni date d'inscription exposée à cet écran). Non repris — inventer cette donnée aurait affiché une information fausse, même discipline que D.9.6 (bloc « détail du paiement » non reproduit faute de support du modèle de données).
4. **`messagerie_transporteur_caarco` : `<html lang="en">` mais contenu entièrement en français** (« Rechercher une conversation... », « MESSAGES DIRECTS », etc.) — incohérence de métadonnée HTML, pas un résidu de marque ou de modèle financier au sens de C.1/C.4 ; sans impact sur le code réel (l'attribut `lang` d'un fichier maquette n'est jamais consommé par l'app). Non corrigé, mentionné pour mémoire seulement.

### D.15.6 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : **0 nouvelle clé**. Les 49 clés utilisées par les 4 écrans (`profilClient.*`, `course.labelDepart`/`labelArrivee`, `messages.*`, `coursesTR.*`, `coursesPlanifiees.*`, `commun.*`, `tableauBord.clientDefaut`, `courseAcceptee.ouiAnnuler`) existaient déjà et ont été vérifiées une par une comme résolvables (0 clé manquante). Parité fr/en vérifiée par import ESM réel des modules (`node --input-type=module`, plutôt que `require()` qui échoue silencieusement sur la syntaxe `export const` de `fr.js`/`en.js` — écart de méthode noté pour les sessions futures, un `require()` nu sur ces fichiers ne lève pas d'erreur exploitable et peut laisser croire à une vérification faite alors qu'elle a échoué) : **1385 clés de chaque côté, 0 écart**, inchangé par cette passe.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 4 fichiers — 1 hex préexistant retokenisé (`MessagesTransporteurScreen.js`, D.15.4).
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs hors des tokens déjà validés au Lot 0 — `Etoiles`/`Sentier` réutilisent leurs styles internes ; `ProfilClientScreen.js` est en palette statique de bout en bout, aucun risque du type D.11.5 (texte sur fond thémé) à traiter ici.
- **Aucune résurgence wallet/séquestre** : confirmé par grep exhaustif (D.15.1) sur les 4 écrans et les services consommés — 0 résultat. `course.methode_paiement`/`mode_paiement_client` : 0 occurrence, reconfirmé explicitement pour `CoursesTransporteurScreen.js` (D.15.1).
- **Cible tactile ≥52px** : aucun nouvel élément tactile introduit par ce lot (`Etoiles`/`Sentier` sont purement présentationnels ; les corrections de bugs D.15.3 ne touchent à aucun élément tactile). Éléments tactiles préexistants non modifiés, hors périmètre de cette passe.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` non retenté (panne d'outillage confirmée à chaque lot depuis le Lot 4, D.8.7 à D.14.7, toujours non réparée). Validation faite directement via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 4 fichiers modifiés : **OK**, aucune erreur de parsing.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-10 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci pour confirmer visuellement que `CoursesTransporteurScreen.js` s'affiche désormais sans crash (D.15.3 #2).

### Synthèse D.15

- **4 écrans traités** : `ProfilClientScreen.js` (Etoiles + Sentier + bug `nombre_courses` corrigé), `MessagesTransporteurScreen.js` (1 hex corrigé, structure confirmée équivalente à la maquette), `MesReservationsScreen.js` (déjà conforme, non modifié), `CoursesTransporteurScreen.js` (bug `enCours`/`ReferenceError` corrigé, motif trajet conservé par cohérence avec `HistoriqueScreen.js`).
- **Redondance `ProfilClientScreen.js`/`ProfilPublicScreen.js` clarifiée** : pas de fusion, les deux répondent à des besoins distincts (fiche de candidature vs profil de confiance générique) — voir D.15.2. Aucun chemin TR→profil de confiance client n'existe aujourd'hui ; combler ce manque est un ajout de capacité, documenté pour décision future, non fait dans ce lot.
- **2 bugs réels trouvés et corrigés** (pas de simples résidus cosmétiques) : compteur de courses client toujours à 0 sur `ProfilClientScreen.js` (mauvais nom de champ), crash au rendu de `CoursesTransporteurScreen.js` (variable hors-scope après un refactor antérieur non commité) — D.15.3.
- **1 résidu de marque « TransLogix »** corrigé sur la maquette `profil_client_caarco` (activement réutilisée ce lot).
- **`Echelon` évalué sur les 4 écrans, jamais utilisé** (aucun besoin réel d'état à étapes nommées) ; `Sentier` utilisé une fois (`ProfilClientScreen.js`), écarté ailleurs par cohérence avec des décisions déjà actées (`HistoriqueScreen.js`, Lot 5) ou par absence de motif dots/trait à convertir (`MesReservationsScreen.js`).
- **Aucun écran des Lots 1-10, 12-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 4 écrans ci-dessus + `vehicle_character_sheets/.../profil_client_caarco/code.html` (1 correction cosmétique) + `REFONTE_TRACKING.md` + ce fichier (section D.15). Aucun fichier i18n modifié (0 nouvelle clé).
- Prochaine étape recommandée : **Lot 12 — Écrans partagés restants** (`ProfilPublicScreen.js`, `ChatScreen.js`, `MessagesScreen.js`, `CallScreen.js`, `EcranMaintenance.js`, `ContributionsCarteScreen.js` — mobilise `Echelon`, `Sillon`). Point de vigilance à emporter : la redondance `ProfilPublicScreen.js`/`ProfilClientScreen.js` est désormais clarifiée (D.15.2, pas de fusion à faire) — ce lot peut retoucher `ProfilPublicScreen.js` sans dépendance non résolue envers le Lot 11.

## D.16 — Lot 12 : Écrans partagés restants (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 6 écrans (`ProfilPublicScreen.js`, `ChatScreen.js`, `client/MessagesScreen.js`, `CallScreen.js`, `EcranMaintenance.js`, `ContributionsCarteScreen.js`), mobilise `Echelon`/`Sillon` par assignation D.3.2. Détail tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 12 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.16.1 Méthode suivie

Les 4 maquettes assignées (`profil_client_caarco`, `profil_transporteur_caarco`, `messagerie_caarco_1`, `messagerie_caarco_2`) ont été lues intégralement (`code.html`) avant tout code, conformément à la consigne de cette session — pas seulement le contrôle visuel de 5 secondes recommandé en C.1/D.1 pour des maquettes déjà classées ✅. `EcranMaintenance.js` (`maintenance_en_cours_caarco`, déjà ✅) a également été lue intégralement dès lors qu'elle servait de référence structurelle réelle. `CallScreen.js` et `ContributionsCarteScreen.js` sont « sans maquette » (D.2.2) — traités sans référence Stitch. Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` menée sur les 6 écrans **et** sur tous les services qu'ils consomment (`services/messages.js`, `services/contributions.js`, `services/gps.js`, `services/courses.js` pour `obtenirCourse`) : 2 faux positifs trouvés et écartés (commentaires « solde de points carte », voir D.16.5), aucune résurgence réelle. Recherche `course.methode_paiement`/`mode_paiement_client` sur les 6 écrans : **0 occurrence** — aucun de ces écrans ne touche aux données de paiement d'une course, conforme à leur nature (profil, messagerie, appel, maintenance, contributions cartographiques).

### D.16.2 Découverte — `profil_transporteur_caarco` écarté comme référence

L'hypothèse de départ de cette session (D.2.2 : « écran unique partagé, une maquette par rôle affiché ») s'est révélée fausse pour `profil_transporteur_caarco`. La lecture intégrale du `code.html` montre que cette maquette n'est pas une variante-rôle du profil de confiance générique (hero + avis + contact) mais une **fiche d'offre de transport pour une course précise** : bento « Offre Proposée : 35 000 XAF » + « Détails du Véhicule » + « Récapitulatif du Trajet » + CTA final « Choisir ce transporteur ». Aucun bloc avis, aucune action Message/Appel/Vidéo. Ce modèle (le client parcourt et choisit parmi des offres tarifées, une marketplace à enchères) ne correspond à aucun écran de l'inventaire D.2 — le modèle CAARCO réel est un matching automatique côté serveur (`AttenteScreen.js`, Lot 4 : le client ne voit jamais une liste d'offres tarifées à comparer). Cette maquette a donc été écartée pour ce lot ; `ProfilPublicScreen.js` a été retouché uniquement d'après `profil_client_caarco` (bloc hero + « Contact Actions » + « Avis Récents » — son bloc « Détails de la mission » avait déjà été consommé par `transporteur/ProfilClientScreen.js` au Lot 11, D.15.2/D.15.4). Même discipline méthodologique que les découvertes des Lots 10 et 11 (D.14.5, D.15.4) : un nom de maquette cohérent avec un rôle ne garantit pas une correspondance structurelle réelle — la preuve doit venir du contenu, pas du nom.

### D.16.3 Découverte — résidu « WhatsApp » sur `ProfilPublicScreen.js`, précédent invalidé aux Lots 6/9

Le style `btnWhatsApp` (bordure `'#25D366'`, vert de marque WhatsApp) du bouton vidéo de `ProfilPublicScreen.js` a été cité comme précédent documenté par 2 lots antérieurs : le Lot 6 (`client/ParrainageScreen.js`, D.10.4, commentaire « exception documentée, déjà en usage identique dans ProfilPublicScreen.js ») et le Lot 9 (`transporteur/LeaderboardScreen.js`, D.13, commentaire sur les couleurs de médaille citant le même précédent). Vérification faite ce lot-ci (lecture complète de `ProfilPublicScreen.js` et de `CallScreen.js`, qui n'avait encore jamais été ouvert dans ce chantier) : le bouton en question appelle `ouvrirVideo()` → `navigation.navigate('Call', { muteVideo: false })`, qui ouvre `CallScreen.js` — un **appel vidéo in-app via Jitsi Meet** (WebView vers `meet.jit.si`), sans aucun lien avec WhatsApp. Le nom du style et sa couleur étaient donc un résidu trompeur (probable vestige d'une version antérieure où ce bouton ouvrait effectivement WhatsApp), pas une exception de couleur de marque légitime — contrairement à `client/ParrainageScreen.js`, qui a un vrai bouton `logo-whatsapp` + lien `whatsapp://send?text=...` et dont l'exception est fondée sur ses propres mérites, indépendamment de ce qui se passe dans `ProfilPublicScreen.js`. Corrigé ce lot-ci : bouton vidéo repassé en bordure `colors.foret`, bouton d'appel restructuré en pilule labellisée (voir D.16.4). **Les Lots 6 et 9 ne sont pas rouverts** (hors périmètre de cette session) — leurs propres exceptions (WhatsApp réel, couleurs or/argent/bronze) restent valides ; seule la phrase de justification qui pointait vers `ProfilPublicScreen.js` comme précédent était fondée sur un nom de style plausible plutôt que sur une vérification du comportement réel du bouton, un piège de la même famille que les découvertes D.14.5/D.15.3.

### D.16.4 Traitement des 6 écrans

| Écran | Traitement |
|---|---|
| `ProfilPublicScreen.js` | `Etoiles` local (hero) et rangée manuelle d'étoiles (avis) remplacés par le composant partagé `Etoiles.js` — gain réel pour les avis, jusque-là limités aux étoiles pleines (`i <= a.note_globale`) : les demi-étoiles sont désormais rendues pour une `note_globale` comme 4.5. Rangée d'actions du pied de page restructurée en 3 boutons conformes à la section « Contact Actions » de `profil_client_caarco` : Message (flex-1, plein, `colors.foret`, inchangé), **Appel devient un bouton labellisé flex-1** (`colors.brume`/`colors.charbon`, au lieu d'un carré icône seule ambigu), Vidéo (icône seule 52×52, bordure `colors.foret`, teinte WhatsApp supprimée — D.16.3). Import mort préexistant `shadow` retiré. |
| `ChatScreen.js` | Déjà bien aligné sur `messagerie_caarco_2` (en-tête avatar+nom+statut en ligne, bulles brume/bambouSoft avec direction de queue correcte, barre de saisie caméra/galerie/textarea/envoi). 1 hex en dur retokenisé (`'#e3ede5'` → `alpha(colors.bambou, 0.08)`, même substitution qu'aux Lots 9/11 pour une teinte de sélection quasi identique). Bouton « Appeler » présent dans l'en-tête de la maquette **non ajouté** (D.16.6). |
| `client/MessagesScreen.js` | Déjà bien aligné sur `messagerie_caarco_1` (liste de conversations, avatar+nom+heure+aperçu, badge non-lu). 1 hex en dur retokenisé (`'#edf4ef'` → `alpha(colors.bambou, 0.08)`, même substitution que `MessagesTransporteurScreen.js` au Lot 11). Import mort préexistant `shadow` retiré. Barre de recherche de la maquette (littéralement commentée « Search / Filter Sillon » dans le `code.html`) **non ajoutée** (D.16.6). |
| `CallScreen.js` | Sans maquette (D.2.2). Déjà conforme au DoD avant ce lot (0 hex, i18n complet, WebView Jitsi propre) — non modifié. Sa lecture a permis de trancher la découverte D.16.3. |
| `EcranMaintenance.js` | Retint des accents de `colors.laterite` (Alertes/Erreurs/Annulation, §5 CLAUDE.md) vers `colors.nere` (Accent) sur l'icône bouclier, son cercle et la bordure gauche du bloc message (D.16.7). |
| `ContributionsCarteScreen.js` | Cibles tactiles `btnValider`/`btnValideOk` portées de 40px à 52px, `fab` (« Contribuer ») avec `minHeight: 52` ajouté — aucun des trois ne respectait la règle CLAUDE.md §5 (« Taille tactile minimum : 52px height pour les boutons ») avant ce lot. Consomme désormais `contributionTypes(t)` (D.16.8) au lieu de l'objet statique `TYPES_CONTRIBUTION`. |

### D.16.5 `points_carte` — vérifié, mécanisme distinct du wallet bloqué (C.2 #3)

Les commentaires d'en-tête de `ContributionsCarteScreen.js` (« Header : solde de points carte ») et de `services/contributions.js` (« Solde de points carte de l'utilisateur ») sont d'abord apparus comme des candidats à la recherche exhaustive du mot « solde ». Vérifiés jusqu'à la migration `076_contributions_carte.sql` : `points_carte` est une colonne dédiée sur `users`, créditée uniquement par les RPC `soumettre_contribution()`/`valider_contribution()` de ce système de contributions cartographiques communautaires (signaler une route fermée, corriger une adresse, ajouter un lieu manquant, valider un signalement d'un autre utilisateur). Aucun lien avec les tables `wallets`/`transactions_wallet` du modèle séquestre aboli, ni avec le mécanisme de streak bloqué de `PointsScreen.js`/`MerciScreen.js` (C.2 #3, D.3.3, tables `wallets` orphelines) — deux systèmes de « points » homonymes mais entièrement indépendants dans le code, le schéma et les RPC. Confirmé non concerné par le blocage C.2 #3 ; ces 2 faux positifs sont écartés, pas corrigés (rien à corriger, le vocabulaire est juste).

### D.16.6 Barres de recherche des maquettes messagerie — jamais ajoutées, cohérence avec le Lot 11

`messagerie_caarco_1` (référence de `client/MessagesScreen.js`) contient un champ de recherche explicitement commenté « Search / Filter Sillon » dans son `code.html` — un signal fort que ce composant du Lot 0 était originellement pensé pour cet usage précis, et `messagerie_caarco_2` (référence de `ChatScreen.js`) montre un bouton « Appeler » dans l'en-tête, absent du code réel (les appels se déclenchent uniquement depuis `ProfilPublicScreen.js`). Aucun des deux n'a été ajouté : filtrer une liste déjà chargée exige un nouvel état et une nouvelle logique de filtrage (recherche de conversation), et ajouter un second point d'entrée vers l'appel dans l'en-tête du chat est un nouveau chemin de navigation — les deux sont plus proches d'un ajout de fonctionnalité que d'un remplacement de composant visuel, exactement le raisonnement déjà tenu au Lot 11 pour la barre de recherche de `messagerie_transporteur_caarco`/`MessagesTransporteurScreen.js` (D.15.4) et pour le lien profil complet TR→client (D.15.2). Pour rester cohérent avec la discipline « ne jamais ajouter de fonctionnalité dans une passe de refonte visuelle » déjà appliquée sur 11 lots consécutifs, la même décision est reconduite ici plutôt que de céder à l'évidence du nom du composant dans le HTML source. Conséquence : `Sillon` reste **jamais exercé sur un écran de messagerie** dans ce chantier (mais exercé pour la première fois sur `ContributionModal.js`, voir D.16.8) — ces 2 barres de recherche sont de bons candidats pour une décision produit future de Cedric.

### D.16.7 Découverte — teinte alerte sur `EcranMaintenance.js`, non conforme au ton rassurant de la maquette

La maquette `maintenance_en_cours_caarco` (déjà ✅, lue intégralement car servant de référence structurelle) est délibérément apaisante : fond forêt uni, icône bouclier pâle sur un cercle presque noir, aucune touche rouge/orange nulle part, carte « Data Security Verified » au ton rassurant explicite (« vos données restent en sécurité »). Le code réel utilisait `colors.laterite` — la couleur explicitement réservée par CLAUDE.md §5 aux « Alertes / Erreurs / Annulation » — sur l'icône bouclier, son cercle et la bordure gauche du bloc message : un vocabulaire de couleur qui contredit le message produit voulu (« tout va bien, on fait juste de la maintenance »), alors même que le contenu textuel de l'écran (« Toutes vos données sont en sécurité ») porte déjà ce ton rassurant. Retinté en `colors.nere` (Accent), sans casser aucune combinaison de contraste existante (mêmes suffixes d'opacité `+'20'`/`+'40'`, motif exempté de la règle zéro-hex depuis les Lots 5/9/10, seule la teinte de base change).

### D.16.8 `services/contributions.js` et `ContributionModal.js` — retouches hors des 6 écrans nommés, justifiées

La recherche exhaustive des mots-clés interdits sur `ContributionsCarteScreen.js` a mené naturellement à son unique service métier, `services/contributions.js`, où 2 défauts réels ont été trouvés — tous deux consommés exclusivement par `ContributionsCarteScreen.js` et `ContributionModal.js` (composant non listé parmi les 6 écrans nommés par D.3.2, mais rendu uniquement depuis `ContributionsCarteScreen.js` comme son flux de création, donc traité dans le même geste — même principe déjà appliqué aux extensions de composants partagés des Lots 5/7/10 quand un défaut réel touchait directement le périmètre du lot) :
1. **4 hex en dur** dans `TYPES_CONTRIBUTION.*.couleur`, correspondant exactement aux tokens `colors.laterite`/`colors.bambou`/`colors.nere`/`colors.foret` (vérifié valeur par valeur) — retokenisés à l'identique, 0 changement visuel.
2. **`label`/`ptsTxt` des 4 types de contribution codés en dur en français**, jamais passés par `t()`, affichés tels quels dans les 2 fichiers consommateurs (violant la règle « i18n complet » non négociable de D.2bis point 4). `TYPES_CONTRIBUTION` restructuré en fonction `contributionTypes(t)` (même patron que `onglets(t)`, déjà utilisé dans `client/MessagesScreen.js` avant ce lot), 8 nouvelles clés ajoutées en miroir fr/en. Au passage, correction d'une coquille dans le texte source français : « Route fermée / barragée » (mot non standard) → « Route fermée / barrée ».

`CATEGORIES_LIEU` (liste de catégories de lieu affichée dans `ContributionModal.js`, ex. « Marché », « École », « Carrefour ») **volontairement laissée en français non traduite** : ces valeurs sont envoyées telles quelles à la colonne `categorie_lieu` (`TEXT` libre, migration 076, aucune contrainte `CHECK`) et jamais retraduites à l'affichage (`c.categorie_lieu` interpolé brut dans `contributionsCarte.categorieLabel`) — les convertir en clés/slugs traduits changerait le contrat de données réellement stocké (anciennes lignes en français, nouvelles lignes en slugs, avec un risque d'affichage incohérent pour les contributions déjà soumises sans logique de conversion rétroactive). Risque jugé disproportionné pour un champ secondaire, peu visible, d'un sous-type de contribution. Documenté comme écart i18n connu et assumé, non corrigé — même prudence que D.9.6/D.15.5 point 3 (ne pas inventer/déplacer une donnée réellement stockée pour un gain cosmétique).

**Extension additive sur `Sillon.js`** : prop `autoFocus` ajoutée (transmise au `TextInput` interne, défaut `false`) — nécessaire pour préserver le comportement `autoFocus` des 2 champs de `ContributionModal.js` qui l'utilisaient avant la conversion vers `Sillon` (`adresseCorrigee`, `nomLieu`). Zéro impact sur les ~30 écrans déjà consommateurs de `Sillon` qui ne passent pas ce prop (valeur par défaut inchangée).

### D.16.9 Découverte — `MessagesScreen.js` n'est pas à la racine de `screens/`

Contrairement à l'inventaire D.2/D.3.2 (et au tableau `REFONTE_TRACKING.md` avant correction par ce lot), le fichier réel est `App/src/screens/client/MessagesScreen.js` (seul importeur : `ClientNavigator.js`, ligne `import MessagesScreen from '../screens/client/MessagesScreen'`), pas `App/src/screens/MessagesScreen.js` à la racine comme le suggérait le regroupement « Partagés — racine `screens/` ». Aucune action de code nécessaire (l'écran a bien été localisé et traité), mais l'inventaire doit être lu en gardant cette correction en tête pour toute session future qui s'y référerait par son chemin supposé.

### D.16.10 Composants

`Etoiles` (2 usages sur `ProfilPublicScreen.js`, hero + avis — remplace un doublon local et une boucle manuelle, gain net de demi-étoiles pour les avis). `Echelon` évalué sur les 6 écrans, **non utilisé** : aucun besoin réel d'état à étapes nommées, aucun de ces écrans n'a de flux multi-étapes (profil, messagerie, appel, maintenance et contributions cartographiques sont tous des écrans à état unique ou à onglets simples, pas des tunnels séquentiels). `Sillon` évalué, **besoin réel confirmé par le `code.html` de `messagerie_caarco_1` mais délibérément non utilisé sur les écrans de messagerie** (D.16.6, cohérence avec le Lot 11) — utilisé en revanche pour la première fois en conditions réelles sur `ContributionModal.js` (3 champs de saisie construits à la main remplacés), avec l'extension `autoFocus` documentée en D.16.8.

### D.16.11 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : **9 nouvelles clés** (`profilPublic.appeler` + 8 `contributionsCarte.type*`). Parité vérifiée par import ESM réel des modules (`node --input-type=module`, méthode actée au Lot 11 après le piège `require()`, D.15.6) : **1394 clés de chaque côté, 0 écart** (1385 avant ce lot). 1 écart i18n documenté et non corrigé (`CATEGORIES_LIEU`, voir D.16.8).
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat pertinent) — 6 hex préexistants retokenisés au total (1 `ChatScreen.js`, 1 `client/MessagesScreen.js`, 1 `ProfilPublicScreen.js` [résidu WhatsApp, D.16.3], 4 `services/contributions.js`), 2 accents laterite→nere retintés sur `EcranMaintenance.js` (résidu sémantique plutôt qu'un hex en dur au sens strict, D.16.7). `CallScreen.js` confirmé déjà à 0.
- **Contraste WCAG AA** : aucune nouvelle combinaison de couleurs hors des tokens déjà validés — le nouveau bouton « Appel » (`colors.brume`/`colors.charbon`) et le bouton vidéo (`colors.foret` sur `colors.manioc`) reproduisent des contrastes déjà en usage ailleurs dans l'app ; le retint `EcranMaintenance.js` réutilise le même motif d'opacité que l'original, seule la teinte de base change.
- **Aucune résurgence wallet/séquestre** : recherche exhaustive confirmée par grep (0 résultat réel) sur les 6 écrans et tous les services consommés — 2 faux positifs vérifiés et écartés (D.16.5). `course.methode_paiement`/`mode_paiement_client` : recherché explicitement, 0 occurrence (D.16.1).
- **Cible tactile ≥52px** : 3 vrais manquements trouvés et corrigés sur `ContributionsCarteScreen.js` (`btnValider`/`btnValideOk` 40→52px, `fab` `minHeight: 52` ajouté) ; les 3 boutons du pied de page de `ProfilPublicScreen.js` sont tous à 52px.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **non retenté**, panne d'outillage confirmée sans interruption depuis le Lot 4 (D.8.7 à D.15.6). Validation faite directement via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 11 fichiers concernés (9 modifiés + `CallScreen.js` + `fr.js`/`en.js`) : **OK**, aucune erreur de parsing. Toujours signalé à Cedric — la commande standard mériterait d'être réparée avant les prochains lots.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : **non exécuté**, même blocage que les Lots 0-11 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci pour valider visuellement la nouvelle rangée de 3 boutons de `ProfilPublicScreen.js` et le retint de `EcranMaintenance.js`.

### Synthèse D.16

- **6 écrans traités** : `ProfilPublicScreen.js` (Etoiles + rangée contact restructurée + résidu WhatsApp corrigé), `ChatScreen.js` (1 hex corrigé), `client/MessagesScreen.js` (1 hex corrigé), `CallScreen.js` (déjà conforme, non modifié), `EcranMaintenance.js` (retint laterite→nere), `ContributionsCarteScreen.js` (cibles tactiles corrigées + `contributionTypes(t)`).
- **`profil_transporteur_caarco` écarté comme référence** pour `ProfilPublicScreen.js` : c'est une fiche d'offre/enchère de course, pas une variante-rôle du profil de confiance générique — ne correspond à aucun écran de l'inventaire D.2 (D.16.2).
- **1 résidu réel trouvé et corrigé, indépendant de toute maquette** : bouton vidéo à teinte WhatsApp sur `ProfilPublicScreen.js`, qui avait servi de faux précédent à 2 lots antérieurs (D.16.3).
- **2 défauts réels trouvés et corrigés hors des 6 écrans nommés** (`services/contributions.js`) : 4 hex en dur, 8 libellés non traduits — justifiés par consommation exclusive depuis le périmètre de ce lot (D.16.8).
- **2 barres de recherche/points d'entrée montrés par les maquettes, délibérément non ajoutés** (D.16.6), cohérence avec la discipline actée au Lot 11.
- **2 faux positifs wallet/solde vérifiés et écartés** (`points_carte`, mécanisme communautaire distinct, D.16.5).
- **1 découverte d'inventaire** : `MessagesScreen.js` est réellement à `client/MessagesScreen.js`, pas à la racine de `screens/` (D.16.9).
- **Aucun écran des Lots 1-11 ni 13-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 6 écrans du lot + `services/contributions.js` + `components/ContributionModal.js` + `components/Sillon.js` (extension additive) + `src/i18n/fr.js`/`en.js` (9 clés) + `REFONTE_TRACKING.md` + ce fichier (section D.16).
- Prochaine étape recommandée : **Lot 13 — Admin : tableau de bord & opérations** (`DashboardScreen.js`, `OperationsAdminScreen.js`, `CoursesEnCoursAdminScreen.js` — premier lot admin. `Borne`/`Silo`/`Fronton` déjà rodés côté client/transporteur (Lots 2/6/8/9) ; `Corridor`/`Passoire` (nav latérale desktop + recherche/filtres admin), en revanche, jamais exercés hors de l'écran-catalogue dev-only — première mobilisation réelle à ce lot). Point de vigilance hérité du Lot 8 (D.12.2, jamais revérifié depuis) : `CoursesEnCoursAdminScreen.js` fait partie des écrans identifiés comme lisant potentiellement encore `course.methode_paiement` — à vérifier à l'ouverture avec la même méthode de grep exhaustif.

## D.17 — Lot 13 : Admin — tableau de bord & opérations (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. **Premier lot admin du chantier** — les Lots 1-12 portaient tous sur les rôles client/transporteur. 3 écrans (`DashboardScreen.js`, `OperationsAdminScreen.js`, `CoursesEnCoursAdminScreen.js`), composants assignés par D.3.2 : Borne, Silo, Corridor, Passoire, Fronton. Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 13 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.17.1 Méthode suivie

Les 3 maquettes assignées (`tableau_de_bord_admin_caarco`, `op_rations_live_admin_caarco`, `op_rations_live_admin`) ont été lues intégralement (`code.html`) avant tout code, conformément à la consigne de cette session — le Lot 12 venait de montrer une nouvelle fois (`profil_transporteur_caarco`, D.16.2) qu'un nom de maquette cohérent avec un écran ne garantit pas une correspondance structurelle réelle. Les mappings D.2.5 se sont confirmés exacts pour les 3 écrans (aucune réattribution nécessaire, contrairement aux découvertes D.16.2/D.14.5/D.15.4 des lots précédents). Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` menée sur les 3 écrans et tous les fichiers réellement consommés (`services/supabase.js`, `context/MaintenanceContext.js`, `components/PanneauDroit.js`, `components/Mereau.js`) : 0 résultat, aucun faux positif à écarter cette fois. Recherche `course.methode_paiement`/`mode_paiement_client` : 1 vraie résurgence trouvée (voir D.17.2).

### D.17.2 `CoursesEnCoursAdminScreen.js` — vigilance prioritaire confirmée fondée, dernier écran de la liste D.9.4/D.12.2 soldé

Contrairement à `TableauBordScreen.js` (Lot 7, D.11.7) et `RevenusScreen.js` (Lot 8, D.12.2) où la vigilance avait été levée sans résurgence trouvée, `CoursesEnCoursAdminScreen.js` lisait réellement `course.methode_paiement` — à la fois dans la requête source (`.select(...methode_paiement...)`, ligne 438) et dans 2 endroits du rendu (`FeuilleDetail`, icône et libellé « Espèces »/« Mobile Money »). Vérification du schéma réel avant correction : `methode_paiement` (migration 039, valeurs `'online'|'wallet'|'especes'`, littéralement un vestige du modèle wallet aboli) reste une colonne active de `courses`, encore lue par de nombreuses RPC backend (039 à 087) pour de la logique métier réelle (conditions de commission, flux sans OTP) — mais celles-ci sont hors périmètre de ce lot (Partie C, backend). Côté écran, seul le champ informatif autoritaire au sens de CLAUDE.md §12 (« `mode_paiement_client` = 'especes' | 'mobile_money' — informatif seulement ») doit être affiché. Corrigé : requête source + les 2 lectures de rendu basculées vers `mode_paiement_client` — même traitement qu'aux Lots 7/8 (D.11.7, D.12.2). Aucun appelant tiers de cette requête (elle est locale à l'écran, pas un service partagé) : changement sans risque pour un autre écran. La liste des 4 écrans suspects ouverte en D.9.4 (Lot 5) est désormais intégralement soldée.

### D.17.3 Découverte majeure — `Corridor` structurellement redondant avec `AdminShell.js`

Avant d'intégrer `Corridor` (nav latérale fixe desktop, D.3.1 #8) dans l'un des 3 écrans comme suggéré par D.3.2, lecture de la façon dont ces écrans sont réellement montés dans l'app (consigne explicite de cette session, avant de présumer que `capture-auto.ps1` ou toute autre convention s'applique de la même façon qu'aux lots précédents). Les 20 écrans admin ne sont **jamais rendus seuls** : tous montés à l'intérieur d'`App/src/screens/admin/AdminShell.js`, qui possède déjà sa propre sidebar responsive maison — `SidebarContenu` (logo+rôle CAARCO Admin, profil, sections de liens `GESTION`/`UTILISATEURS`/`FINANCES`/`MARKETING`/`CARTE`/`SYSTÈME` avec état actif et badges, drawer coulissant sur mobile `<768px`, colonne fixe 220px sur desktop, bouton déconnexion) — un sur-ensemble fonctionnel de `Corridor` (qui n'a que : en-tête, liste de liens plate avec badge, pied optionnel). Les 3 écrans reçoivent leurs props de navigation (`onMenu`, `onNaviguer`, `onRetour`) directement d'`AdminShell`, sans nav autonome à construire. Utiliser `Corridor` à l'intérieur d'un des 3 écrans créerait une **deuxième** sidebar imbriquée dans la première — aucune des 3 maquettes ne montre ce doublon (chacune n'a qu'une seule sidebar, la leur). `Corridor` est donc un composant sans emploi possible dans ce chantier tel qu'`AdminShell.js` est architecturé aujourd'hui, ce qui vaut pour ce lot et, par construction identique, pour les 5 lots admin restants (14-18) puisqu'`AdminShell.js` enveloppe déjà les 20 écrans admin sans exception. Contrairement aux précédents Echo/Echelon/Silo (D.8.3, D.9.3, D.12.5 — « pas de besoin réel sur cet écran précis »), cette conclusion est **architecturale et définitive pour tout le sous-arbre admin**, pas un jugement écran par écran. `AdminShell.js` (assigné au Lot 18, « shell de navigation, pas un écran de contenu ») a été lu pour cette vérification mais n'a pas été modifié — hors périmètre de ce lot.

### D.17.4 `Passoire` — premier usage réel confirmé sur `CoursesEnCoursAdminScreen.js`, 2 non-usages documentés

`Passoire` (recherche + filtres combinés, D.3.1 #9), comme `Corridor`, n'avait jusqu'ici jamais été exercé hors de l'écran-catalogue dev-only. Vérification de son API réelle (`valeurRecherche`, `onChangerRecherche`, `placeholderRecherche`, `filtres`, `onChangerFiltre`, `onReinitialiser`) avant intégration : `CoursesEnCoursAdminScreen.js` avait un champ de recherche construit à la main (boîte bordée blanche, icône loupe, `TextInput`, bouton clear conditionnel) quasi identique structurellement au rendu par défaut de `Passoire` — remplacé directement, aucune extension d'API nécessaire. La barre d'onglets à compteurs de ce même écran (`ONGLETS`, tabs à sélection exclusive avec badge numérique par statut) n'a **pas** été convertie vers le paramètre `filtres` de `Passoire` : celui-ci ne porte que `{cle, label, actif}`, sans badge numérique — remplacer aurait fait perdre une information réellement affichée (compte par statut) sans bénéfice de cohérence visuelle en retour. `DashboardScreen.js` : aucun champ de recherche n'existe dans le code réel (les pilules période Auj./7 jours/30 jours ne sont pas une recherche) — non pertinent, non ajouté (discipline « ne jamais ajouter de fonctionnalité dans une passe de refonte visuelle », D.16.6/D.9.6). `OperationsAdminScreen.js` : recherche déjà existante et déjà alignée sur la maquette, mais rendue en pilule flottante translucide sur la carte (`bg-blanc/90 backdrop-blur-md rounded-full` dans le `code.html`) — le style par défaut de `Passoire` (boîte opaque bordée, coins `radius.md`) est visuellement incompatible avec ce traitement flottant sans réécriture significative de ses styles internes ; conservé tel quel plutôt que dénaturer l'esthétique déjà conforme à la maquette.

### D.17.5 `Borne` et `Fronton` évalués sur `DashboardScreen.js`, non utilisés

Même discipline qu'aux Lots 4/5/9 (Echo, Echelon, Silo non forcés) appliquée ici à 2 composants pourtant déjà rodés côté client/transporteur : `Borne` (grille KPI) — la grille locale `CarteKPI` porte une capacité réellement supérieure (sous-texte optionnel sur 2/4 cartes, bordure gauche accentuée par couleur, icône teintée par carte) que `Borne` ne supporte pas (icône toujours `bambouSoft`/`foret` fixe, pas de sous-texte, pas d'accent de bordure) — remplacer aurait perdu une information réelle déjà affichée pour un gain de cohérence de composant seul. `Fronton` (en-tête de section + « voir tout ») — le motif existe déjà et est répété à l'identique sur 6 sections de l'écran (`sectionEntete`/`sectionTitre` mono-majuscule compact + `voirTout`) ; `Fronton` impose une typographie de titre nettement plus grande (`fonts.display`/`fontSize.h3`) que ce motif — l'utiliser sur une seule des 6 sections aurait cassé la cohérence entre sections sœurs du même écran. Même discipline que `CarteStat`/Lot 9 (D.13) : motif local plus riche et déjà cohérent conservé plutôt que forcé sur la base de l'assignation D.3.2 seule.

### D.17.6 `Silo` — 2ᵉ usage réel, écran-preuve d'origine du composant

`Silo` (Lot 9, 1er usage réel sur `StatsTransporteurScreen.js`, D.12.5/D.13) remplace ici `GraphiqueHoraire`, le graphique en barres 24h local de `DashboardScreen.js` — `tableau_de_bord_admin_caarco` est littéralement l'écran-preuve d'origine cité en D.3.1 #5 pour ce composant (« Graphique en barres CSS avec axes et infobulle »), jamais revisité depuis le Lot 0. Correspondance structurelle directe : 8 catégories (heures clé) × 1 série (nombre de courses), infobulle au tap déjà supportée nativement par `Silo`. **Compromis documenté** : l'implémentation locale surlignait l'heure courante (±1h) en `colors.nere` contre `colors.foret30` pour les autres — `Silo` n'a pas d'équivalent (sa couleur de barre est indexée par série, pas par catégorie), ce signal visuel est donc perdu. Jugé mineur (information secondaire, pas la donnée principale du graphique) et accepté, même esprit que les compromis documentés du Lot 2 (D.6, écarts n°1-3) plutôt que d'étendre l'API de `Silo` pour un gain marginal.

### D.17.7 Contraste WCAG AA — risque détecté et neutralisé avant introduction, 2ᵉ occurrence après D.11.5

Première passe de retokenisation de `#5cd97d`/`#16a34a` (vert « en ligne » vif, sans précédent ailleurs dans l'app, vérifié par grep) → `colors.bambou` de façon uniforme. Avant validation, calcul de contraste (formule de luminance relative WCAG) sur les 3 usages posés directement sur le hero de `DashboardScreen.js`, **toujours rendu en `colors.nuit`** indépendamment du thème clair/sombre choisi par l'utilisateur (`heroMetricVal` du compteur TR online, `heroLiveDot`, `heroLiveTxt`) : `colors.bambou` (#3d6b4a) sur `colors.nuit` (#0f1411) ne donne que **~3,0:1**, sous le seuil AA texte (4,5:1), contre ~10,3:1 pour le hex d'origine — une régression de contraste réelle qui serait passée inaperçue sans calcul explicite. Corrigé avant d'être introduit vers `colors.bambouSoft`, déjà utilisé sur ce même hero pour la métrique « Livrées » voisine (précédent interne direct, ligne préexistante du fichier) : **~5,4:1**, conforme AA. Les usages de `colors.bambou`/`colors.bambouSoft` **hors** du hero (badge « LIVE » du bandeau filtres période, pastille « TR en ligne » des cartes défilantes) reproduisent le motif déjà en place ailleurs dans ce même fichier (`onlineBadge`/`onlineDot`, préexistant) — fond clair, aucun risque. Même vigilance que D.11.5 (Lot 7, extension `couleurLabel`/`couleurSousLabel` de `Sentier`) : vérifier le fond réel avant de réutiliser un token à l'identique partout, pas seulement retokeniser mécaniquement.

### D.17.8 Décision de portée — i18n admin, tranchée avec Cedric à l'ouverture du lot

Avant de coder, vérification de la parité i18n a révélé que les 20 écrans admin (pas seulement les 3 de ce lot) n'utilisent **aucune** i18n — 0 occurrence de `useI18n`/`t(` sur l'ensemble du dossier `screens/admin/`, 0 clé `admin.*` dans `fr.js`/`en.js` (une seule entrée `admin: 'Admin'`, un libellé de rôle isolé, sans rapport), contrairement aux écrans client/transporteur (1394 clés/côté, parité stricte maintenue sur 12 lots consécutifs). Cohérent avec CLAUDE.md §1 (« Langue : Français uniquement V1 ») mais en tension directe avec la consigne DoD « i18n complet » répétée à l'identique à chaque lot depuis D.2bis point 4. Point tranché avec Cedric avant de coder (question posée en direct, pas de supposition) : **l'admin reste 100% texte français en dur, aucun retrofit d'i18n**, décision qui vaut pour ce lot et les 5 lots admin restants (14-18) — pas seulement pour ce lot-ci. Conséquence pratique : aucune clé nouvelle ajoutée pour le texte propre des 3 écrans ; seules les clés déjà existantes des composants partagés mobilisés (`passoire.rechercherDefaut`, `silo.aucuneDonnee`, posées au Lot 0) sont exercées telles quelles via `Passoire`/`Silo`, sans en ajouter ni en modifier. Parité vérifiée par import ESM réel après le lot : **1394/1394, 0 écart, 0 nouvelle clé** — inchangé depuis le Lot 12.

### D.17.9 `capture-auto.ps1` — 2ᵉ blocage distinct découvert pour les lots admin

Consigne explicite de cette session : vérifier comment les écrans admin sont réellement rendus/testés avant de présumer que `capture-auto.ps1` s'applique comme aux Lots 0-12. Résultat : même app Expo/React Native que le reste du chantier (pas un dashboard web séparé) — `RootNavigator.js` route tout utilisateur `role='admin'` vers `AdminNavigator.js` → `AdminShell.js`, donc en théorie capturable avec un compte de test admin sur le même téléphone Android. Mais **blocage supplémentaire, distinct de « pas d'ADB/Maestro dans cet environnement d'agent »** (blocage des Lots 0-12, toujours valable ici aussi) : le flow Maestro unique exécuté par le script, `scripts/maestro/caarco_tous_ecrans.yaml`, ne contient **aucune** mention d'« admin » (grep confirmé, 0 résultat) — aucune connexion admin, aucune navigation vers `AdminShell` ou l'un de ses 20 écrans. Donc même avec un téléphone Android + ADB + Maestro disponibles sur le poste de Cedric, `capture-auto.ps1` tel quel ne capturerait aucun des 3 écrans de ce lot (ni aucun futur écran admin des Lots 14-18) : un flow Maestro dédié (connexion d'un compte `role='admin'`, puis navigation dans `AdminShell`) serait nécessaire au préalable. Signalé à Cedric comme un 2ᵉ chantier d'outillage, distinct de la réparation de `npx babel --presets babel-preset-expo` (en panne sans interruption depuis le Lot 4, toujours non réparée).

### D.17.10 Definition of done (D.2bis point 4) — vérification

- **i18n complet** : voir D.17.8 — décision de portée actée, 0 nouvelle clé, parité 1394/1394 confirmée inchangée.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 3 écrans — 11 hex retokenisés sur `DashboardScreen.js` (voir D.17.7), 2 sur `CoursesEnCoursAdminScreen.js` (`#e8d0a0` → `colors.nere + '40'`, bordure du bloc prix ; `#0f141173` → `colors.nuit + '73'`, overlay de la modale d'assignation — motif suffixe `colors.x + 'NN'` exempté de la règle zéro-hex depuis les Lots 5/9/10, D.16.7). `OperationsAdminScreen.js` confirmé déjà à 0, aucune retouche.
- **Contraste WCAG AA** : 1 risque réel détecté et neutralisé avant validation, voir D.17.7 — 2ᵉ occurrence de ce type de vigilance proactive dans le chantier après D.11.5 (Lot 7).
- **Aucune résurgence wallet/séquestre** : recherche exhaustive confirmée par grep (0 résultat) sur les 3 écrans et tous les fichiers consommés. `course.methode_paiement`/`mode_paiement_client` : 1 vraie résurgence trouvée et corrigée (D.17.2) — liste D.9.4/D.12.2 désormais intégralement soldée sur les 4 écrans suspects d'origine.
- **Cible tactile ≥52px** : 2 vrais manquements trouvés et corrigés (`btnAssigner`/`btnDesassigner` sur `CoursesEnCoursAdminScreen.js`, ~44px → `minHeight: 52`, boutons d'action contextuelle réels). Icônes utilitaires de header (menu, rafraîchir, fermer modale) laissées sous 52px sur les 3 écrans — convention déjà établie et jamais remise en cause sur l'ensemble des écrans déjà clos du chantier (y compris `AdminShell.js` lui-même, hors périmètre), seuls les boutons d'action primaire/contextuelle sont tenus au seuil, même lecture qu'au Lot 12 (D.16.11).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` non retenté, panne confirmée sans interruption depuis le Lot 4 (D.8.7 à D.16.11) — validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 écrans : **OK**, aucune erreur de parsing. Toujours signalé à Cedric.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté (agent sans ADB/Maestro, comme aux Lots 0-12) — 2ᵉ blocage distinct découvert et documenté, voir D.17.9.

### D.17.11 Premier bilan d'usage réel — Corridor et Passoire

`Corridor` : conclusion négative et **architecturale**, pas un simple jugement écran par écran — redondant avec la sidebar déjà construite dans `AdminShell.js` qui enveloppe les 20 écrans admin sans exception (D.17.3). Contrairement aux précédents Echo/Echelon/Silo (« pas de besoin réel sur cet écran précis », toujours réévalués lot par lot), cette conclusion vaut d'emblée pour les 5 lots admin restants (14-18) sans qu'il soit nécessaire de rouvrir l'analyse à chaque fois — à confirmer en une phrase à l'ouverture de chaque lot admin suivant, pas à re-décortiquer entièrement. `Passoire` : conclusion positive mais mesurée — 1 usage réel confirmé (`CoursesEnCoursAdminScreen.js`), 2 non-usages documentés avec raison propre à chaque écran (pas de recherche sur `DashboardScreen.js` ; recherche existante mais en pilule flottante incompatible avec le style boîte par défaut sur `OperationsAdminScreen.js`). Aucun défaut ni manque dans l'API réelle de `Passoire` pour son unique usage — aucune extension nécessaire, contrairement à `Sentier` (D.11.5) ou `Sillon` (D.16.8) lors de leurs propres premiers usages réels.

### Synthèse D.17

- **3 écrans traités** : `DashboardScreen.js` (11 hex retokenisés + `Silo` pour le graphique horaire), `CoursesEnCoursAdminScreen.js` (`methode_paiement`→`mode_paiement_client` + `Passoire` pour la recherche + 2 hex + 2 cibles tactiles), `OperationsAdminScreen.js` (déjà conforme, non modifié).
- **1 vigilance prioritaire soldée** : `course.methode_paiement` trouvé et corrigé sur `CoursesEnCoursAdminScreen.js` — dernier des 4 écrans suspects de D.9.4 traité (D.17.2).
- **1 découverte architecturale majeure** : `Corridor` redondant avec `AdminShell.js`, sans emploi possible sur l'ensemble des 6 lots admin (D.17.3) — première conclusion de ce type dans le chantier (portée au-delà d'un seul lot).
- **1 décision de portée actée avec Cedric** : admin = français uniquement, aucun retrofit i18n, valable Lots 13-18 (D.17.8).
- **1 risque de contraste détecté et neutralisé avant introduction** (D.17.7), 2ᵉ occurrence après D.11.5.
- **1 blocage d'outillage supplémentaire découvert** : `capture-auto.ps1`/Maestro ne couvre aucun écran admin (D.17.9).
- **Aucun écran des Lots 1-12 ni 14-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. `AdminShell.js` lu, non modifié. Fichiers modifiés : `DashboardScreen.js`, `CoursesEnCoursAdminScreen.js` + `REFONTE_TRACKING.md` + ce fichier (section D.17). Aucune clé i18n ajoutée.
- Prochaine étape recommandée : **Lot 14 — Admin : utilisateurs** (`UtilisateursScreen.js`, `ClientsAdminScreen.js`, `TransporteursAdminScreen.js` — 2 des 3 sans maquette propre, dérivables d'`UtilisateursScreen.js` une fois celui-ci traité, D.2.5). `Passoire` de nouveau assigné par D.3.2 — évaluer son besoin réel sans présumer, comme d'habitude. `Corridor` également réassigné par D.3.2 mais la conclusion architecturale de ce lot (D.17.3) s'applique d'office : à confirmer d'une phrase à l'ouverture, pas à ré-instruire entièrement.

## D.18 — Lot 14 : Admin — utilisateurs (implémentation, 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 14 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.18.1 Méthode suivie

Lecture intégrale du `code.html` de la maquette `gestion_des_utilisateurs_admin` avant de coder les 3 écrans (consigne explicite de la session, même discipline qu'aux lots précédents) : recherche + 2 `<select>` (rôle, statut) en tête, liste d'utilisateurs à gauche (avatar initiales, nom, téléphone, badge rôle, badge statut à puce colorée), volet détail bento à droite (carte profil avec avatar XL + stats Courses/Note en grille 2 colonnes, carte « Documents KYC » avec coche + libellé + lien « Voir » par document, actions « Suspendre le compte » / « Contacter » en pleine largeur). Confirmé structurellement fidèle à l'écran réel `UtilisateursScreen.js` visé (mapping direct D.2.5), mais l'écran réel avant ce lot n'avait **aucun** volet détail — une simple liste plate avec recherche manuelle et un seul filtre (rôle). `ClientsAdminScreen.js`/`TransporteursAdminScreen.js` n'ont pas de maquette propre (D.2.5) mais étaient déjà, avant ce lot, structurellement plus avancés que `UtilisateursScreen.js` (panneau détail `PanneauDroit`, KPIs, actions reset/suppression/crédit TC) — traités par greffe ciblée plutôt que par refonte de mise en page complète, pour ne pas perdre de fonctionnalité réelle déjà supérieure à la maquette.

### D.18.2 `UtilisateursScreen.js` — réécriture complète, premier vrai master-detail de l'écran

L'écran avant ce lot était une simple liste (`Plaquette` + `Mereau` + `Cachet` rôle, recherche `TextInput` manuelle, filtre rôle via `Pastille`) sans aucune consultation détaillée — taper sur un utilisateur ne faisait rien. Réécrit en master-detail conforme à la maquette : liste enrichie d'un badge statut à puce colorée (absent avant ce lot, information pourtant déjà en base via `users.statut`) ; volet détail `PanneauDroit` avec carte profil (avatar XL, statut, grille Courses/Note), section « Documents KYC » (transporteurs uniquement, via `Pochette` en lecture seule sur `cni_url`/`permis_url`), actions Suspendre/Réactiver + Contacter. Délibérément plus léger que les 2 écrans spécialisés voisins (pas de reset/suppression/crédit TC) — écran généraliste de consultation rapide, les actions destructives/financières restant dans les vues spécialisées par rôle, une répartition de responsabilité assumée plutôt qu'un oubli.

### D.18.3 `Passoire` — 3 usages réels confirmés, une limite d'API réelle documentée

Trois usages directs ce lot-ci, chacun en remplacement d'un bloc recherche/filtre déjà construit à la main et quasi identique à la structure par défaut de `Passoire` — aucune extension nécessaire, même constat qu'au Lot 13 (D.17.11). Limite réelle rencontrée sur `UtilisateursScreen.js` : la maquette montre 2 `<select>` indépendants (rôle, statut), mais l'API `filtres` de `Passoire` ne porte qu'un seul tableau plat de chips — une seule dimension. Plutôt que de forcer les 2 dimensions dans un seul tableau de chips (ce qui aurait mélangé « Client »/« Transporteur »/« Actif »/« Suspendu » dans une même rangée, perdant le sens des 2 filtres indépendants de la maquette), le rôle est porté par `Passoire.filtres` et le statut par une rangée de pilules manuelle distincte, réutilisant le style `filtrePilule` déjà en place dans `ClientsAdminScreen.js`/`TransporteursAdminScreen.js` avant ce lot. Pas un défaut de conception de `Passoire` en soi (son unique dimension suffit à ses 2 autres usages de ce lot, chacun réellement mono-dimensionnel), mais une limite réelle à connaître avant de l'assigner tel quel à un futur écran à filtres orthogonaux multiples.

### D.18.4 `TransporteursAdminScreen.js` — deux découvertes réelles, indépendantes de la maquette

**Ajout réel, pas cosmétique** : aucune section « Documents KYC » n'existait dans le panneau détail avant ce lot — un administrateur consultant un transporteur ne pouvait pas voir ses pièces (CNI, permis) sans changer d'écran. Ajoutée via `Pochette` (déjà rodé aux Lots 10 et, dans ce même lot, sur `UtilisateursScreen.js`) en lecture seule, alimentée par `cni_url`/`permis_url` désormais sélectionnés dans la requête liste (absents avant ce lot).

**Bug réel trouvé et corrigé, indépendant de toute maquette** : `ModalDetail` affichait déjà `tr.note_moyenne ? Number(tr.note_moyenne).toFixed(1) : ''` pour la tuile « Note moy. » — mais la requête `charger()` (principale **et** son repli sans jointure KYC) ne sélectionnait jamais `note_moyenne`. Conséquence : cette tuile était vide pour 100 % des transporteurs, sur les deux chemins de la requête, depuis l'introduction de ce bloc stats. Trouvé par lecture croisée requête/rendu (même discipline que D.15.3), pas par comparaison à la maquette. Corrigé en ajoutant `note_moyenne` aux deux `select()`.

### D.18.5 Vigilance wallet/séquestre — recherche exhaustive, aucun résidu trompeur trouvé, une architecture déjà connue reconfirmée

Grep `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 3 écrans : 3 occurrences, aucune corrigée après vérification —

1. `ClientsAdminScreen.js`/`TransporteursAdminScreen.js`, copie « …portefeuille remis à 0 FCFA » dans la confirmation du bouton « Remettre à zéro ». Vérifié jusqu'à la migration (038, `admin_reset_compte`) : le RPC lit/écrit réellement `wallets.solde_fcfa` et insère dans `transactions_wallet`. La copie décrit donc fidèlement un comportement réel — à la différence du badge « Wallet » trouvé et corrigé au Lot 5 (D.9.4), qui affichait un libellé **faux** (un champ hérité jamais réellement alimenté par le flux actif), ici sanitiser le texte sans toucher au RPC aurait maquillé un comportement réel plutôt que de le corriger. Architecture déjà intégralement documentée en C.3.2 (tables `wallets`/`transactions_wallet` orphelines dans l'attente d'une migration de purge, décision Cedric, hors périmètre design) — non retouchée.
2. `TransporteursAdminScreen.js`, `notifierAvecTemplate(id, 'credit_wallet', …)` pour le crédit TC admin. La clé `cle = 'credit_wallet'` en base (`notification_templates`) est un nom résiduel de l'ancien modèle wallet, mais son contenu réel a déjà été assaini par la migration 083 (antérieure à ce chantier de refonte) : *« {salutation} {nom} ! {montant} ont été crédités sur votre compte CAARCO. »* — plus de mention « wallet », `{montant}` reçoit déjà l'unité correcte (« X TC ») depuis l'appelant. Même famille que le piège de nom `RetraitsAdminScreen.js` (D.2.5) : le nom interne trompe, le comportement réel affiché à l'utilisateur est propre. Non renommé (renommer la clé exigerait une migration DB, hors périmètre design).

### D.18.6 Distinction « Créditer TC (admin) » vs `admin_crediter_wallet_client` — reconfirmée, pas présumée acquise

Revérifiée par grep + lecture des migrations plutôt que présumée acquise depuis D.2.5 : le modal « Créditer TC (admin) » de `TransporteursAdminScreen.js` appelle `admin_crediter_tc` (créée migration 082, contrôle `is_admin()` ajouté migration 085 — RPC distincte, déjà correctement protégée). `admin_crediter_wallet_client` (migration 037, faille 🔴 documentée en C.3.2) : **0 référence** dans les 3 écrans de ce lot (grep confirmé) — la distinction actée en D.2.5 tient toujours.

### D.18.7 Découverte hors périmètre visuel, non corrigée — `admin_reset_compte` touche réellement `wallets`/`transactions_wallet`

Non nouvelle (déjà documentée en C.3.2), reconfirmée à l'ouverture de ce lot par lecture directe de la migration 038 plutôt que supposée : la RPC `admin_reset_compte`, appelée par les boutons « Remettre à zéro » de `ClientsAdminScreen.js` et `TransporteursAdminScreen.js`, lit et écrit réellement `wallets.solde_fcfa` et insère dans `transactions_wallet`. Ni l'un des 2 correctifs 🔴 urgents (trigger `after_course_terminee`, RPC `admin_crediter_wallet_client`), ni un défaut caché — une conséquence assumée de tables pas encore purgées (C.3.2 : « peut être purgé dans une migration de nettoyage classique », décision Cedric en attente). Aucune action de code prise (backend hors périmètre de ce lot) ; consignée ici pour que la prochaine session n'ait pas à redécouvrir le lien entre la copie « portefeuille » et le comportement réel de la RPC.

### D.18.8 `Corridor` et `Echelon` — non utilisés, motifs propres à ce lot

`Corridor` : conclusion architecturale du Lot 13 (D.17.3) reconfirmée en une phrase à l'ouverture, non réanalysée en détail — redondant avec la sidebar d'`AdminShell.js`. `Echelon` : évalué sur les 3 écrans, non utilisé — aucun ne présente de séquence linéaire à états nommés (fait/actif/à venir) ; les statuts affichés (compte actif/suspendu, KYC approuvé/en attente/rejeté/infos manquantes) sont catégoriels ou à embranchements, déjà bien servis par des badges (`Cachet`, badges locaux). Même discipline que D.9.3/D.11.6 : composant assigné par D.3.2, vérifié, écarté par manque de besoin réel plutôt qu'imposé par défaut.

### D.18.9 Definition of done (D.2bis point 4) — vérification

- **i18n** : décision de portée du Lot 13 reconduite (D.17.8, admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé. Parité vérifiée par import ESM réel : **1394/1394, 0 écart**, inchangé depuis le Lot 13.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat sur les 3 écrans) — 2 hex retokenisés/supprimés sur `TransporteursAdminScreen.js` (`'#0f141180'` supprimé avec le style mort `modalFond` qui le portait ; `'#0f14118c'` → `alpha(colors.nuit, 0.55)`, équivalence exacte à l'octet près) ; 1 hex supprimé avec le style mort `modalFond` sur `ClientsAdminScreen.js`. `UtilisateursScreen.js` (réécriture complète) : 0 hex introduit.
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 3 écrans (pas de hero sombre comme `DashboardScreen.js` au Lot 13) — calcul de contraste explicite non applicable ; vigilance quand même vérifiée par relecture, badges/pilules réutilisant des combinaisons déjà validées ailleurs (`bambouSoft`/`bambou`, `lateriteSoft`/`laterite`).
- **Aucune résurgence wallet/séquestre trompeuse** : voir D.18.5 — 3 occurrences trouvées, toutes vérifiées saines (copie exacte du comportement réel ou déjà assainie par une migration antérieure), aucune corrigée car aucune n'était fausse.
- **Cible tactile ≥52px** : plusieurs manquements réels trouvés et corrigés — `btnAction` (`ClientsAdminScreen.js`), `dtBtnPrimaire`/`dtBtnSec`/`dtBtnDanger` (`TransporteursAdminScreen.js`) passés de `paddingVertical` seul à `minHeight: 52` ; `creditBtnAnn`/`creditBtnOk` (modal crédit TC) passés de `height: 44` à `height: 52`. `UtilisateursScreen.js` : `btnAction` construit directement à 52px. Icônes utilitaires de header sous 52px non retouchées (convention déjà établie, non remise en cause).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` retenté pour reconfirmer plutôt que supposé toujours cassé — échoue encore, même `Unexpected token` sur du JSX simple non lié à ce lot, panne ininterrompue depuis le Lot 4 (D.8.7), **toujours non réparée**, signalée de nouveau à Cedric. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que le Lot 13 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné par l'agent.

### Synthèse D.18

- **3 écrans traités** : `UtilisateursScreen.js` (réécriture complète, premier master-detail réel de l'écran), `ClientsAdminScreen.js` (greffe `Passoire` + nettoyage de styles morts), `TransporteursAdminScreen.js` (greffe `Passoire` + section Documents KYC ajoutée + bug `note_moyenne` manquante corrigé).
- **1 bug réel trouvé et corrigé, indépendant de toute maquette** : `note_moyenne` jamais sélectionné dans la requête liste de `TransporteursAdminScreen.js` alors que le rendu l'affichait déjà (D.18.4).
- **1 gap fonctionnel réel comblé** : section Documents KYC absente du panneau détail transporteur avant ce lot, ajoutée via `Pochette` (D.18.4).
- **1 limite d'API réelle documentée sur `Passoire`** : une seule dimension de filtre, insuffisante pour les 2 filtres orthogonaux (rôle + statut) de `UtilisateursScreen.js` — contournée par une rangée de pilules manuelle complémentaire, pas un défaut à corriger dans le composant partagé (D.18.3).
- **3 occurrences wallet trouvées par grep, 0 corrigées** : toutes vérifiées jusqu'à la migration/donnée réelle et jugées saines ou déjà assainies antérieurement — aucune sanitisation cosmétique appliquée sur un comportement réel non corrigé (D.18.5).
- **1 découverte architecturale reconfirmée, non corrigée** : `admin_reset_compte` touche réellement `wallets`/`transactions_wallet`, déjà connue en C.3.2, hors périmètre design (D.18.7).
- **Aucun écran des Lots 1-13 ni 15-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. `AdminShell.js` non modifié. Fichiers modifiés : `UtilisateursScreen.js`, `ClientsAdminScreen.js`, `TransporteursAdminScreen.js` + `REFONTE_TRACKING.md` + ce fichier (section D.18). Aucune clé i18n ajoutée.
- Prochaine étape recommandée : **Lot 15 — Admin : KYC & litiges** (`KYCValidationScreen.js`, `LitigesScreen.js` — mobilise `Pochette`, déjà rodé aux Lots 10 et 14, et `Corridor`, dont la conclusion architecturale du Lot 13 (D.17.3) s'applique d'office).

## D.19 — Lot 15 : Admin — KYC & litiges (implémentation, 09/07/2026)

**2 écrans traités, tous marqués fait.** Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 15 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.19.1 Méthode suivie

Lecture intégrale des 2 `code.html` avant de coder (consigne explicite de la session) : `validation_kyc_admin` (page de détail plein écran d'un dossier unique — pas de master-detail, pas de sidebar, en-tête « Retour à la liste » + statut « EN ATTENTE » + 3 sections bento Identité/Permis/Véhicule avec icône `zoom_in` au survol de chaque image + zone de motif de rejet + boutons Rejeter/Approuver) et `v_rification_kyc_admin` (master-detail complet : `NavigationDrawer` desktop propre, liste de 4 dossiers à gauche, volet détail à droite avec documents CNI/Permis/Véhicule également zoomables). Les deux maquettes confirment la même structure de fond (sections labellisées par type de pièce, zoom sur chaque image) malgré des layouts de page différents — cohérent avec l'écran réel déjà en master-detail (liste → `PanneauDetail` plein écran), pas de correspondance structurelle biaisée par le nom trouvée ici (contrairement à d'autres lots, D.16.2/D.18.1).

### D.19.2 `KYCValidationScreen.js` — grille de documents remplacée par 5 sections zoomables via `Pochette`

La grille `DocCard` locale (6 tuiles fixes, image statique + pastille de statut, **aucun zoom**) est remplacée par 5 sections labellisées (CNI, Permis de conduire, Véhicule, Carte grise, Assurance), chacune enveloppant `Pochette` en lecture seule (zoom plein écran réel via son `Modal` + `ScrollView` pinch-zoom déjà existant, absent du code avant ce lot bien que montré explicitement par l'icône `zoom_in` dans les 2 maquettes). La pastille de statut (Présent/À vérifier/Manquant), information réellement décisive pour la décision d'approbation, est conservée mais déplacée à côté du titre de chaque section plutôt que portée par `Pochette` elle-même (voir D.19.3). **Bug latent corrigé, indépendant de la maquette** : la section Véhicule ne lisait que `dossier.vehicule_url[0]`/`[1]` codés en dur, quel que soit le nombre réel de photos soumises par le transporteur (`vehicule_url` est un `TEXT[]` en base) — désormais alimentée par le tableau complet (`vehiculePhotos = (dossier.vehicule_url ?? []).filter(Boolean)`), rendu en galerie `Pochette` (`multiple`). Trouvé par lecture croisée du schéma de la requête et du rendu, même discipline que la découverte `note_moyenne` du Lot 14 (D.18.4).

### D.19.3 `Pochette` — besoin réel vérifié, usage confirmé mais pas par simple substitution 1:1

Conformément à la consigne d'ouverture de session, le besoin de `Pochette` a été vérifié plutôt que présumé acquis malgré la précédente de 3 usages sans écart (Lots 10, 14×2). Deux écarts réels trouvés entre l'API de `Pochette` et le besoin précis de cet écran :
1. **Aucune notion de statut par fichier** dans `Pochette` (elle ne rend qu'image + label + bouton de suppression optionnel) — or `KYCValidationScreen.js` est un écran de **décision** (approuver/rejeter/demander corrections), où savoir precisément quelle pièce est absente ou à vérifier est une information de premier ordre, contrairement au Lot 14 où `Pochette` servait une simple consultation passive (`ClientsAdminScreen.js`/`TransporteursAdminScreen.js`, pas de décision associée à l'affichage des documents).
2. **Galerie horizontale défilante par construction** (`ScrollView horizontal` interne) — la maquette et le code existant montrent une **grille de sections labellisées**, pas un carrousel unique de 6 vignettes qui masquerait les dernières pièces sans geste de swipe, réduisant la lisibilité d'un écran conçu pour un examen exhaustif rapide.

Plutôt que d'étendre l'API de `Pochette` (utilisée telle quelle par 4 autres écrans sans aucune extension nécessaire jusqu'ici — étendre son contrat pour un seul appelant aurait été une extension spéculative, contraire à la discipline du chantier) ou de renoncer à son vrai apport (le zoom), la pastille de statut a été portée par l'écran appelant (une section par type de pièce, chacune affichant sa pastille à côté du titre, puis `Pochette` en dessous pour l'image + zoom, ou un espace réservé « Aucun fichier soumis » si absente). Conclusion : `Pochette` est le bon choix pour la partie image+zoom de cet écran, mais — contrairement à l'attente formulée en ouverture de session (« usage quasi acquis ») — pas par une substitution directe et intégrale de la grille existante ; seule sa capacité de zoom est réutilisée, la structure d'affichage (sections, statuts) reste propre à l'écran.

### D.19.4 `Corridor` — conclusion du Lot 13 reconfirmée en une phrase, non réanalysée

Redondant avec la sidebar d'`AdminShell.js` (D.17.3, reconfirmé D.18.8) — non intégré sur les 2 écrans de ce lot, conformément à la consigne de ne pas rouvrir l'analyse complète.

### D.19.5 `LitigesScreen.js` — déjà conforme, nettoyage de code mort uniquement

Structure déjà alignée sur `gestion_des_litiges_admin` avant ce lot (liste de litiges en cartes + panneau de décision `PanneauDroit` avec récap course/motif/boutons Annuler-Valider). Seul nettoyage DoD réel : import `Modal` mort (jamais rendu en JSX — `ModalDecision` délègue entièrement à `PanneauDroit`, qui gère son propre `Modal` en interne) et styles `modalFond`/`modalContenu` résiduels d'une itération antérieure à l'introduction de `PanneauDroit`, supprimés (ils portaient au passage le seul hex en dur du fichier, `'#0f14118c'`).

### D.19.6 Maquette `gestion_des_litiges_admin` — deux éléments visuels vérifiés puis délibérément non reproduits

1. **Distinction « Urgent »/« En attente »** (bordure et badge colorés par carte) : vérifiée jusqu'au schéma réel avant d'écarter ou de reproduire — recherche exhaustive sur toutes les migrations, `courses` ne porte **aucune** colonne d'urgence/priorité (seul `bonus_urgence_fcfa` existe, migration 078, sans rapport — concerne les missions planifiées). La distinction de la maquette est un artefact des données d'exemple Stitch, pas une capacité réelle du modèle de données — non reproduite pour ne pas inventer une classification que l'app ne peut pas réellement calculer à ce jour.
2. **Carte « Résolu »** (litige historique, opacité réduite, bouton « Voir l'historique ») : les données brutes existent (`courses.statut` = terminee/annulee + `motif_litige` renseigné par ce même écran), mais aucun écran de détail d'historique de litige n'existe dans l'app pour servir de cible réelle à ce bouton. Même catégorie d'omission que le lien « Contacter l'assistance » de `MotDePasseOublieScreen.js` au Lot 1 (D.5) : un lien mort aurait été pire qu'une omission. Non reproduite.

### D.19.7 Vigilance wallet/séquestre — recherche exhaustive sur les 2 écrans et les RPC/services réellement consommés

Grep `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 2 écrans : **0 résultat** — contrairement aux Lots 13/14, aucune occurrence, même saine, à documenter. Vérifié au-delà du texte visible, jusqu'à la source des RPC/migrations réellement appelées par ces 2 écrans :
- `valider_kyc` (définie dans `fix_securite.sql`, hors du dossier `supabase/migrations/` — à noter pour une future session qui chercherait uniquement dans les migrations numérotées) : lue intégralement, `SECURITY DEFINER`, vérifie `role = 'admin'` via `auth.uid()` côté serveur avant toute écriture, ne touche que `transporteurs_kyc` et `users` (statut, kyc_valide, kyc_approuve_le). Aucune table wallet référencée.
- Résolution de litige (`LitigesScreen.js`) : mise à jour directe `courses.update({ statut, motif_litige })`, pas de RPC dédiée — aucun champ financier touché.
- Template de notification `litige_resolu` (migration 072) : contenu vérifié, aucune mention financière ni wallet, cohérent avec les templates déjà assainis notés au Lot 14 (D.18.5).

### D.19.8 Definition of done (D.2bis point 4) — vérification

- **i18n** : décision de portée des Lots 13/14 reconduite (D.17.8/D.18.9, admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé. Parité vérifiée par import ESM réel (`node --input-type=module`) : **1394/1394, 0 écart**, inchangé depuis le Lot 13.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat sur les 2 écrans) — `'#e8780a'` (palier intermédiaire de `JaugeValidite`, `KYCValidationScreen.js`) fusionné dans `colors.laterite` (voir palette ci-dessous) ; `'#0f14118c'` supprimé avec les styles morts `modalFond` qui le portaient (`LitigesScreen.js`).
- **Palette officielle à 3 tons reconfirmée** : `JaugeValidite` (jauge de validité par document, non assignée à ce lot mais déjà présente) utilisait un 4ᵉ ton non tokenisé (`#e8780a`, orange vif) pour son palier « expire sous 30 jours », distinct des 3 tons officiels `laterite`/`nere`/`bambou` — `theme.js` (Section 5 CLAUDE.md, source de vérité unique) ne définit aucun ton « avertissement » dédié. Plutôt que d'inventer une nouvelle couleur de marque de sa propre initiative, le palier « ≤30 jours » a été fusionné avec le palier « expiré » sous `colors.laterite` : même sévérité réelle (un document expirant sous 30 jours empêche bientôt le transporteur d'opérer légalement, au même titre qu'un document déjà expiré). Les 4 messages textuels distincts (jours exacts affichés) sont conservés à l'identique — seule la couleur du palier intermédiaire change, décision documentée plutôt que silencieuse.
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 2 écrans (pas de hero sombre façon `DashboardScreen.js`) — non applicable, vigilance vérifiée par relecture.
- **Aucune résurgence wallet/séquestre** : voir D.19.7 — 0 occurrence, RPC et template de notification vérifiés jusqu'à la source.
- **Cible tactile ≥52px** : 2 manquements réels trouvés et corrigés — `btnCorrections`/`btnRefuser`/`btnValider` (`KYCValidationScreen.js`, 46px→52px) et `btnDecision` (`LitigesScreen.js`, boutons Annuler/Valider la course, 50px→52px). Icônes utilitaires de header (menu, fermer, retour) non retouchées (convention déjà établie, non remise en cause).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **retenté** sur `KYCValidationScreen.js` pour reconfirmer plutôt que supposé toujours cassé — échoue encore, même `Unexpected token` sur du JSX/optional chaining non lié à ce lot, panne ininterrompue depuis le Lot 4 (D.8.7), **toujours non réparée**, signalée de nouveau à Cedric. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 2 fichiers : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13/14 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné par l'agent.

### Synthèse D.19

- **2 écrans traités** : `KYCValidationScreen.js` (grille de documents remplacée par 5 sections `Pochette` zoomables + palette de `JaugeValidite` corrigée), `LitigesScreen.js` (nettoyage de code mort uniquement, déjà conforme).
- **1 bug latent réel corrigé, indépendant de la maquette** : section Véhicule limitée à 2 index codés en dur au lieu du tableau `vehicule_url` complet (D.19.2).
- **1 bilan d'usage réel nuancé sur `Pochette`** : besoin confirmé (zoom, vrai manque vs. les 2 maquettes) mais pas par simple substitution — sa galerie horizontale et l'absence de statut par fichier ont conduit à une intégration en 5 sections propres à l'écran plutôt qu'un remplacement direct de la grille (D.19.3).
- **2 éléments de maquette vérifiés puis délibérément non reproduits** : distinction Urgent/En attente (aucune donnée réelle pour l'étayer) et carte Résolu/historique (aucun écran cible pour son action) — D.19.6.
- **0 résidu wallet/séquestre trouvé** (contrairement aux Lots 13/14) — vérifié jusqu'aux RPC et templates sources, pas seulement le texte visible (D.19.7).
- **1 palette non officielle corrigée par fusion de palier**, pas par invention d'un nouveau ton de marque (D.19.8).
- **Aucun écran des Lots 1-14 ni 16-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. `AdminShell.js` non modifié. Fichiers modifiés : `KYCValidationScreen.js`, `LitigesScreen.js` + `REFONTE_TRACKING.md` + ce fichier (section D.19). Aucune clé i18n ajoutée.
- Prochaine étape recommandée : **Lot 16 — Admin : finances & tarifs** (`FinancesAdminScreen.js`, `RetraitsAdminScreen.js`, `ConfigTarifsScreen.js` — mobilise `Borne`/`Silo` déjà rodés côté transporteur, et `Corridor` de nouveau assigné par D.3.2 dont la conclusion architecturale reste d'office non favorable ; `RetraitsAdminScreen.js` porte un piège de nom déjà neutralisé D.2.5, ne jamais le rapprocher de `retrait_de_gains*`).

## D.20 — Lot 16 : Admin — finances & tarifs (implémentation, 09/07/2026)

**3 écrans traités** : `FinancesAdminScreen.js` (modifié en profondeur), `ConfigTarifsScreen.js` (nettoyage DoD ciblé), `RetraitsAdminScreen.js` (déjà conforme, nettoyage import mort seulement). Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 16 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.20.1 Méthode suivie

Lecture intégrale des 2 `code.html` disposant d'une maquette avant de coder : `finances_tokens_tc_admin` (bento 3 KPIs — Volume de Vente/Commissions Perçues/Transporteurs Actifs — puis graphique en barres "Évolution des Ventes TC" 2 séries sur 4 semaines + panneau "Alertes Solde" à droite) et `configuration_des_tarifs_admin` (bento tarifs/km par véhicule + section "Règles Globales" [frais fixes + majoration nuit] + Enregistrer/Annuler). `RetraitsAdminScreen.js` n'a aucune maquette (piège de nom D.2.5 reconfirmé par lecture directe du fichier : titre réel "Tokens de Course", commentaire ligne 13 "les retraits n'existent plus dans le système TC" — jamais rapproché de `retrait_de_gains*`).

### D.20.2 `FinancesAdminScreen.js` — écart réel confirmé contre la maquette, comblé par `Silo`

Le code réel avait déjà les 4 KPI cards (Commission TC/TC vendues/Volume courses/TR solde bas, plus riches que le bento à 3 tuiles de la maquette) et le bloc "Alertes Solde" (`alertesTR`) — mais **aucun graphique**, alors que la maquette montre explicitement un graphique en barres CSS 2 séries (Ventes/Commissions) sur 4 semaines, avec légende. Comblé par `Silo` (2ᵉ preuve directe de la liste D.3.1 #5, après `DashboardScreen.js` Lot 13 et `StatsTransporteurScreen.js` Lot 9) : nouvelle fonction `donneesGraphiqueHebdoTC()` qui regroupe 28 jours de `transactions_tc` (requête dédiée, indépendante des pilules période jour/semaine/mois qui pilotent uniquement les KPIs et les listes) en 4 barres hebdomadaires achat/commission. Couleurs alignées sur la convention déjà en usage dans ce même fichier (`colors.bambou` = achats, `colors.nere` = commissions) plutôt que sur le foret/nere de la maquette, pour rester cohérent avec `LigneTransaction` et les KPI cards du même écran.

### D.20.3 `Borne` — évalué sur les 2 écrans à KPIs de ce lot, non utilisé sur aucun des deux

- `FinancesAdminScreen.js` : les 4 `Plaquette`-KPI locales codent chaque tuile avec une couleur d'icône/valeur **différente et significative** par catégorie (nere=commission, bambou=ventes, foret=volume, laterite=alerte) — `Borne` impose une icône `colors.foret`/fond `colors.bambouSoft` fixes sur ses 3 usages réels vérifiés avant décision (`RevenusScreen.js` Lot 8, `ParrainageScreen.js` Lot 6, aucun des deux ne passe de couleur variable). Remplacer aurait fait perdre un codage couleur réellement utile (repérage visuel immédiat de la tuile d'alerte). Même discipline que `CarteKPI`/`DashboardScreen.js` (D.17.5) et `CarteStat`/`StatsTransporteurScreen.js` (D.13.3).
- `RetraitsAdminScreen.js` : les 3 `resumeCard` (Vendus/Commissions/En alerte) sont des chips à fond teinté plein (bambouSoft/nereSoft/lateriteSoft), **sans icône** — anatomie inverse de `Borne` (fond blanc fixe + bloc icône obligatoire). Non utilisé, motif différent plutôt que plus pauvre.

### D.20.4 `Silo` — évalué sur `RetraitsAdminScreen.js`, non utilisé faute de besoin réel

Aucune maquette pour ce fichier et aucune dimension temporelle à visualiser dans sa structure à 3 onglets (achats/commissions/soldes) — non utilisé, absence de besoin réel plutôt qu'oubli, même discipline que `Silo` non utilisé sur les écrans du Lot 8 (D.12.3) faute de graphique dans les 4 maquettes de ce lot-là.

### D.20.5 `Corridor` — conclusion des Lots 13-15 reconfirmée en une phrase, non réanalysée

Toujours redondant avec la sidebar d'`AdminShell.js` (D.17.3, reconfirmé D.18.8/D.19.4) — non intégré sur les 3 écrans de ce lot.

### D.20.6 Deux découvertes de configuration morte sur `ConfigTarifsScreen.js`, vérifiées jusqu'à la migration réelle

**Commission parrainage.** La section "Commission parrainage" édite `configurations_systeme.commission_parrainage_pct`. Recherche exhaustive de tous les lecteurs de cette clé (`grep` sur `App/supabase/migrations`) : lue uniquement par `liberer_sequestre_course()`, dans ses 3 versions successives (032, 059, 060). Cette RPC est la même chaîne déjà confirmée **inatteignable** en C.3.2/D.10.5 — accessible seulement via `terminer_livraison()`, jamais appelée dans `App/src` ; le flux réellement actif (`confirmer_livraison()` → `debiter_commission_tc()`, migrations 082/085, relu ici pour confirmer) ne référence ni `parrain` ni `commissions_parrainage`. Conséquence vérifiée : un admin peut modifier ce taux, obtenir le toast de succès, sans effet sur la moindre commission distribuée aujourd'hui — le même défaut structurel que `ParrainageScreen.js` (D.10.5), découvert cette fois depuis l'écran de configuration plutôt que depuis l'écran d'affichage client.

**Charge utile (poids/volume).** La section "Charge utile" édite `parametres_tarifs.poids_max_kg`/`volume_max_m3`. Recherche exhaustive sur `App/supabase/migrations` : ces 2 colonnes ne sont créées par **aucune** migration (`parametres_tarifs` ne porte que `vehicule`/`tarif_km`/`frais_fixes`/`updated_at`, migration 025) — le code défensif de `charger()` ("si les colonnes n'existent pas encore") n'est donc pas une prudence théorique, c'est l'état réel actuel. Plus significatif encore : `calculer_prix()`, relue dans ses 3 versions (025, 026, et 097 — la dernière, active), calcule ses seuils poids/volume via un `CASE p_type_vehicule` **codé en dur** dans la fonction SQL, jamais lu depuis `parametres_tarifs` — donc même si les 2 colonnes existaient et étaient sauvegardées avec succès, le moteur de prix (§12 CLAUDE.md, calcul serveur exclusif) ne les consommerait pas. La section "Charge utile" est donc purement cosmétique aujourd'hui : champs toujours vides au chargement, sauvegarde d'un des deux champs vouée à l'échec (colonne inexistante).

**Traitement des deux découvertes** : ni l'une ni l'autre n'est une résurgence wallet/séquestre au sens strict (aucune écriture dans `wallets`/`transactions_wallet`), et le texte des deux sections n'est pas trompeur en soi (les champs font ce qu'ils annoncent au niveau de l'écran — configurer un taux, configurer des seuils — seul le raccordement en aval est rompu) : pas un cas de "sanitizer un texte qui décrit un comportement réel" (méthode D.18.5/D.19.7), donc aucun texte modifié. Corriger l'une ou l'autre exigerait une migration (rebrancher `debiter_commission_tc()` sur le taux parrainage, ou créer les colonnes et rebrancher `calculer_prix()`) — décision produit/backend hors périmètre visuel de ce lot, non corrigée, versée à la liste des corrections backend en tête de `REFONTE_TRACKING.md`.

### D.20.7 Écart fonctionnel trouvé sur `remise_a_zero_totale()`, non corrigé

La "zone danger" de `ConfigTarifsScreen.js` (dev/staging uniquement, `resetDisponible`) appelle `remise_a_zero_totale()` (migration 066), lue intégralement : contrôle de rôle admin serveur bien présent (contrairement à `admin_crediter_wallet_client`, C.3.2). Mais son tableau de tables à vider (`courses`, `messages`, `commissions_parrainage`, `retraits`, `recompenses_client`, `positions_gps`, `transactions_wallet`, `abonnements_transporteurs`, `avis`, `transactions_points`, `jalons_client`, `classement_mensuel_tr`, `publicites`) **ne contient pas `transactions_tc`**, et la fonction ne remet pas non plus `users.solde_tc` à zéro — alors que le texte de l'écran promet explicitement d'effacer "tokens TC". Écart réel entre la promesse UI et le comportement RPC, sans rapport avec wallet/séquestre (c'est l'inverse : les tables wallet historiques sont bien vidées, seul le système TC actif ne l'est pas). Non corrigé (modification de migration, hors périmètre visuel) — documenté pour que Cedric tranche si ce bouton de reset doit rester fiable pour des tests TC complets.

### D.20.8 Definition of done (D.2bis point 4) — vérification

- **i18n** : décision des Lots 13-15 reconduite (D.17.8/D.18.9/D.19.8, admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé. Parité vérifiée par import ESM réel (`node --input-type=module`) : **1394/1394, 0 écart**, inchangé.
- **Zéro hex en dur** : confirmé par grep avant et après correction (0 résultat) sur les 3 écrans — aucun hex à corriger ce lot-ci, les 3 fichiers étaient déjà propres sur ce point précis. Seul nettoyage : import mort `shadow` (jamais consommé) retiré des 3 fichiers, et fallback tautologique `fontSize.xxs ?? 10` simplifié en `fontSize.xxs` (`ConfigTarifsScreen.js`, le token vaut déjà 10 dans `theme.js`).
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 3 écrans — non applicable, vigilance vérifiée par relecture.
- **Aucune résurgence wallet/séquestre trompeuse** : recherche exhaustive confirmée sur les 3 écrans (0 résultat autre que `solde_tc`, légitime) — voir D.20.6/D.20.7 pour les 2 découvertes de configuration morte et l'écart fonctionnel de reset, aucun des trois n'étant une résurgence wallet au sens strict.
- **Cible tactile ≥52px** : 4 manquements réels trouvés et corrigés sur `ConfigTarifsScreen.js` (`btnSauvegarder`, `comBtnSauv` — partagé par les boutons Enregistrer de la commission parrainage et de la tarification de nuit —, `resetBtn`, `resetBtnAnnuler`/`resetBtnConfirmer` 48→52px). Tabs/pilules (`filtrePilule` de `FinancesAdminScreen.js`, `ongletBtn` de `RetraitsAdminScreen.js`) non retouchées, conformément à la convention déjà établie sur `onglet` de `CoursesEnCoursAdminScreen.js` (Lot 13, jamais remonté à 52px) : les filtres/tabs de navigation ne sont pas tenus au même seuil que les boutons d'action primaire/contextuelle réels.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **non retenté**, panne ininterrompue depuis le Lot 4 (D.8.7), **toujours non réparée** — signalée une nouvelle fois à Cedric. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13-15 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné par l'agent.

### Synthèse D.20

- **3 écrans traités** : `FinancesAdminScreen.js` (graphique `Silo` ajouté, écart réel vs maquette comblé), `ConfigTarifsScreen.js` (nettoyage DoD ciblé, aucune refonte de mise en page nécessaire), `RetraitsAdminScreen.js` (déjà conforme, piège de nom D.2.5 reconfirmé).
- **1 vrai gap maquette/code comblé** : graphique hebdomadaire TC absent du code, présent dans `finances_tokens_tc_admin` (D.20.2).
- **`Borne` non utilisé sur les 2 écrans à KPIs de ce lot** (motifs locaux réellement différents, pas plus pauvres) ; **`Silo` : 1 usage réel, 1 non-usage documenté** (D.20.3/D.20.4).
- **2 découvertes de configuration morte, vérifiées jusqu'à la migration réelle, non corrigées** : commission parrainage sans effet (même chaîne inatteignable que C.2 #3/C.3.2) et charge utile poids/volume sans colonnes ni branchement au moteur de prix (D.20.6).
- **1 écart fonctionnel supplémentaire trouvé** : `remise_a_zero_totale()` ne réinitialise pas le système TC malgré la promesse de l'écran (D.20.7).
- **0 résidu wallet/séquestre trompeur** — toutes les occurrences de "solde" vérifiées se rapportent à `solde_tc` (D.20.6/D.20.7 documentent des découvertes adjacentes mais distinctes d'une résurgence wallet).
- **4 cibles tactiles réelles corrigées** sur `ConfigTarifsScreen.js` (D.20.8).
- **Aucun écran des Lots 1-15 ni 17-18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 déjà connues de la Partie C touchée (les 3 découvertes de ce lot sont nouvelles, documentées, non corrigées, ajoutées à la liste de tête de `REFONTE_TRACKING.md`). `AdminShell.js` non modifié. Fichiers modifiés : `FinancesAdminScreen.js`, `RetraitsAdminScreen.js`, `ConfigTarifsScreen.js` + `REFONTE_TRACKING.md` + ce fichier (section D.20). Aucune clé i18n ajoutée.
- Prochaine étape recommandée : **Lot 17 — Admin : marketing** (`MarketingAdminScreen.js`, `PublicitesAdmin.js`, `CalendrierActionsScreen.js`, `LieuxAdminScreen.js` — mobilise `Cadran`/`Fronton`/`Corridor` ; `CalendrierActionsScreen.js` en anglais dans la maquette, à traduire avant usage ; `PublicitesAdmin.js` ne nécessite qu'un contrôle visuel C.2 #6, pas de correction de code).

## D.21 — Lot 17 : Admin — marketing (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. 4 écrans (`MarketingAdminScreen.js`, `PublicitesAdmin.js`, `CalendrierActionsScreen.js`, `LieuxAdminScreen.js`), composants assignés par D.3.2 : Cadran, Fronton, Corridor. Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 17 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.21.1 Méthode suivie

Les 6 `code.html` assignés (`gestion_des_codes_promo`, `publicit_s_in_app_admin_caarco`, `publicit_s_in_app`, `calendrier_marketing_admin_1`, `calendrier_marketing_admin_2`, `lieux_valider_admin`) lus intégralement avant tout code, conformément à la consigne répétée depuis D.19.1/D.20.1. Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` menée sur les 4 écrans et les 2 services réellement consommés (`services/publicites.js`, `services/lieux.js`) : 0 résultat, aucune résurgence — thème marketing confirmé sans lien avec le modèle financier aboli.

### D.21.2 `MarketingAdminScreen.js` — la 2e maquette assignée ne correspond à aucune section réelle de l'écran

D.2.5 assigne `publicit_s_in_app_admin_caarco` (grille de cartes bannières, toggle actif/inactif, bouton « Ajouter une publicité ») comme référence 🔧 pour `MarketingAdminScreen.js`, en plus de `gestion_des_codes_promo`. Lecture du code réel : `MarketingAdminScreen.js` ne gère que 2 sections (« Packs abonnement », « Codes promotionnels ») — aucune trace de gestion de publicités. La fonctionnalité publicités in-app vit entièrement dans `PublicitesAdmin.js`, fichier distinct correctement apparié à l'autre maquette du lot (`publicit_s_in_app`, liste horizontale de bannières avec vignette + infos, structure quasi identique au rendu réel de `PublicitesAdmin.js`). Traité comme un simple contrôle visuel C.2 #6 sans action de code — ajouter une section publicités à `MarketingAdminScreen.js` pour faire correspondre la maquette aurait constitué une fonctionnalité nouvelle hors périmètre d'une passe de refonte visuelle (même discipline que D.16.6/D.9.6, « ne jamais ajouter de fonctionnalité dans une passe de refonte visuelle »). Un nom de maquette cohérent avec un fichier assigné ne garantit toujours pas une correspondance structurelle réelle — même leçon que D.14.5/D.15.4/D.16.2/D.19.1/D.20.1, cette fois au niveau de l'assignation elle-même plutôt que du contenu d'une seule maquette.

### D.21.3 `LieuxAdminScreen.js` — bug réel trouvé et corrigé : drawer mobile inatteignable depuis cet écran

`LieuxAdminScreen.js` était le seul fichier de `screens/admin/` dont le composant ne déclarait aucun paramètre (`export default function LieuxAdminScreen()`), alors qu'`AdminShell.js` (lu pour vérifier le passage de props, non modifié) transmet systématiquement `onMenu`/`onRetour`/`onNaviguer` à l'écran actif via `{...ecranProps}` (`onMenu` non nul uniquement en layout mobile, `isDesktop ? null : basculer`). Conséquence vérifiée : sur mobile, aucun bouton hamburger n'était rendu dans l'en-tête de cet écran — un utilisateur qui atteint « Lieux à valider » sur téléphone n'a alors aucun moyen de rouvrir la sidebar pour naviguer vers un autre écran admin, une impasse de navigation réelle et non un simple écart cosmétique. Corrigé : `onMenu` accepté en prop et câblé dans l'en-tête, même motif visuel que les autres écrans admin de petite taille (icône `menu-outline`, 22px, conditionnelle à `onMenu` non nul).

### D.21.4 Découverte maquette — `calendrier_marketing_admin_2` n'est pas en anglais, contrairement à ce que laissait supposer la fiche C.2 #4

La fiche C.2 #4 caractérise la paire `calendrier_marketing_admin_1`/`_2` globalement comme « la maquette Stitch entièrement en anglais ». Vérification individuelle des 2 dossiers avant traduction : seule `_1` (`<html lang="en">`, « Marketing Calendar », « Overview of Ads, Push Campaigns, and Promos. », jours « Sun/Mon/Tue/Wed/Thu/Fri/Sat », « Actions for Oct 6, 2023 », nav bas « POIs/Alerts/Settings ») est réellement et intégralement en anglais. `_2` (`<html lang="fr">`, `<title>CAARCO - Calendrier Marketing</title>`, « Octobre 2023 », « Vue d'ensemble des actions marketing programmées. », jours « Lun/Mar/Mer/Jeu/Ven/Sam/Dim », « Aperçu du mois », « Ajouter une action ») est déjà quasi intégralement en français — seule une poignée de libellés bilingues protège encore le legend (« In-App »/« Push »/« Promo » mêlés à du français). Seule `_1` a été traduite intégralement avant usage comme référence (titre de page, bloc profil sidebar « Admin Panel »/« Logistics Controller »/« Douala HQ » → « Panneau Admin »/« Contrôleur Logistique »/« Siège Douala », 4 liens de nav, en-tête de page, légende Publicités/Campagnes/Codes promo, mois, jours de semaine, panneau « Actions du jour » avec ses 2 items d'exemple, nav bas mobile) ; `_2` n'a nécessité aucune correction. Même discipline que D.19.1/D.20.1 : une caractérisation établie au niveau d'une paire de maquettes ne garantit pas qu'elle s'applique identiquement à chacun de ses membres — vérifier individuellement avant de traduire mécaniquement les deux.

### D.21.5 `Cadran` — 1er usage réel du chantier, sur un écran non cité comme preuve d'origine

`Cadran` (assigné dès le Lot 0, D.3.1 #12, écrans-preuve d'origine cités : `classement_r_gional_caarco` et `finances_tokens_tc_admin`) n'avait encore jamais été monté sur un écran de production — vérifié par grep (`Cadran` n'apparaissait que dans `Cadran.js` lui-même et l'écran-catalogue dev-only) avant de présumer un usage acquis aux Lots 9 ou 16, conformément à la consigne explicite de cette session (« vérifier si Cadran y a été utilisé avant de présumer un usage acquis »). Ni `LeaderboardScreen.js` (Lot 9) ni `FinancesAdminScreen.js` (Lot 16) ne l'utilisent au final — confirmé, aucune trace dans leur code ni dans D.13/D.20. Sur ce lot, la navigation mois de `CalendrierActionsScreen.js` (2 `TouchableOpacity` chevron flanquant un `Text` de mois, déjà fonctionnellement isomorphe à l'API `label`/`onPrecedent`/`onSuivant` de `Cadran`) a été remplacée directement par le composant partagé — correspondance structurelle immédiate, aucune extension d'API nécessaire, aucun changement de comportement (mêmes handlers `moisPrec`/`moisSuiv`). Écran non cité par D.3.1 comme preuve pour `Cadran`, mais besoin réel confirmé à la lecture du code plutôt que présumé — même logique que l'usage imprévu de `Sentier` sur `CoursePlanifieeDetailScreen.js` au Lot 6 (D.10.4, besoin transverse comblé par un composant déjà du Lot 0 sans qu'il ait été explicitement assigné à cet écran précis).

### D.21.6 `Fronton` — évalué sur les 4 écrans, non utilisé

Les 2 en-têtes de section de `MarketingAdminScreen.js` (« PACKS ABONNEMENT », « CODES PROMOTIONNELS ») portent une typographie mono compacte tout-capitales (`fonts.mono`/`fontSize.xs`/`letterSpacing:1.2`), incompatible avec la police display large imposée par `Fronton` (`fonts.display`/`fontSize.h3`) — même conflit déjà documenté pour les 6 sections de `DashboardScreen.js` au Lot 13 (D.17.5). De plus, le bouton associé à la section « Codes promotionnels » (« Nouveau », ouverture du panneau de création) est une action de création, pas une navigation « voir tout » au sens strict de `Fronton` (`onVoirTout`) — sémantique différente, pas un simple habillage visuel équivalent. Les 3 autres écrans du lot n'ont qu'un unique en-tête de page (titre + sous-titre), sans sous-section méritant ce motif titre+CTA. Non utilisé sur aucun des 4 écrans, même discipline que `Borne`/`Fronton` sur `DashboardScreen.js` (D.17.5) et `Borne` aux Lots 9/16 (D.13.3/D.20.3) : composant assigné par D.3.2, évalué sur chaque écran, écarté faute de besoin réel plutôt qu'utilisé par défaut.

### D.21.7 `Corridor` — conclusion des Lots 13-16 reconfirmée en une phrase, non réanalysée

Toujours structurellement redondant avec la sidebar déjà construite dans `AdminShell.js`, qui enveloppe les 20 écrans admin sans exception (conclusion architecturale D.17.3, reconfirmée D.18.8/D.19.4/D.20.5) — non intégré sur les 4 écrans de ce lot, conformément à la consigne de confirmer en une phrase plutôt que de rouvrir l'analyse complète à chaque lot admin.

### D.21.8 Vigilance wallet/séquestre — recherche exhaustive, aucun résidu trouvé (thème marketing confirmé sans lien financier)

Grep `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 4 écrans et les 2 services consommés (`services/publicites.js`, `services/lieux.js`) : 0 résultat. Les tables consommées par ce lot (`packs`, `codes_promo`, `publicites`, `lieux`, et en lecture seule `campagnes_push` pour le calendrier) sont toutes des tables marketing/contenu, sans aucun chevauchement avec le modèle séquestre/wallet aboli — hypothèse de départ du prompt de session (« aucun résidu wallet n'est attendu a priori sur ce lot ») confirmée, mais vérifiée avec la même méthode exhaustive que les lots financiers plutôt que présumée sans contrôle.

### D.21.9 Definition of done (D.2bis point 4) — vérification

- **i18n** : décision des Lots 13-16 reconduite (D.17.8/D.18.9/D.19.8/D.20.8, admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé sur les 4 écrans. Parité vérifiée par import ESM réel (`node --input-type=module`) : **1394/1394, 0 écart**, inchangé depuis le Lot 12.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 4 écrans — 1 hex réellement actif retokenisé (`'#0f141159'`, scrim du FAB de `CalendrierActionsScreen.js` → `alpha(colors.nuit, 0.35)`) ; 2 paires de styles (`modalFond`/`modalCarte` sur `MarketingAdminScreen.js`, `modalOverlay`/`modalBox` sur `PublicitesAdmin.js`) portant des hex en dur mais **jamais consommées en JSX** (le modal réel de ces 2 écrans passe par `PanneauDroit`, composant du Lot 0 avec son propre overlay interne) supprimées plutôt que retokenisées — avec elles, l'import `alpha` devenu inutile retiré des deux fichiers.
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 4 écrans — non applicable, vigilance vérifiée par relecture.
- **Aucune résurgence wallet/séquestre** : voir D.21.8, 0 résultat sur les écrans et les 2 services consommés.
- **Cible tactile ≥52px** : 4 manquements réels trouvés et corrigés — `btn` Valider/Rejeter de `LieuxAdminScreen.js` (44→52, boutons d'action de modération réels, même précédent que `btnAssigner`/`btnDesassigner` au Lot 13, D.17.10), `btnNouveauCode` de `MarketingAdminScreen.js` et `btnAjouter` de `PublicitesAdmin.js` (boutons de création nommés, ~30-36px→`minHeight: 52`), `fabSub` de `CalendrierActionsScreen.js` (44→52, 3 actions contextuelles nommées révélées par le FAB, pas de simples icônes utilitaires passives). Pilules de filtre (`pill` de `CalendrierActionsScreen.js`), cellules de calendrier (`cel`) et icônes utilitaires de header non retouchées — convention déjà établie et reconfirmée à chaque lot admin (D.17.10 à D.20.8) : seuls les boutons d'action primaire/contextuelle réels sont tenus au seuil.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` retenté sur `LieuxAdminScreen.js` et **toujours en échec** (même panne ininterrompue depuis le Lot 4, D.8.7 à D.20.8, reproduite ici sur de l'optional chaining non lié à ce lot) — signalée une nouvelle fois à Cedric, la commande standard doit être réparée. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 4 fichiers modifiés : **OK**, aucune erreur de parsing.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13-16 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné par l'agent.

### Synthèse D.21

- **4 écrans traités** : `LieuxAdminScreen.js` (bug réel de navigation mobile corrigé, cibles tactiles), `CalendrierActionsScreen.js` (`Cadran` intégré — 1er usage réel du chantier —, hex corrigé, cible tactile FAB), `MarketingAdminScreen.js` (nettoyage DoD, styles morts retirés), `PublicitesAdmin.js` (nettoyage DoD, styles morts retirés).
- **1 bug réel trouvé et corrigé, indépendant des maquettes** : `LieuxAdminScreen.js` ne recevait/câblait jamais `onMenu`, rendant la sidebar inatteignable sur mobile depuis cet écran (D.21.3).
- **1 découverte d'assignation maquette/écran** : `publicit_s_in_app_admin_caarco` assignée à `MarketingAdminScreen.js` par D.2.5 ne correspond à aucune section réelle de ce fichier — la fonctionnalité vit entièrement dans `PublicitesAdmin.js` (D.21.2).
- **1 découverte maquette** : seule `calendrier_marketing_admin_1` est réellement en anglais ; `_2` était déjà quasi intégralement française malgré la caractérisation groupée de C.2 #4 (D.21.4).
- **`Cadran` : 1er usage réel du chantier**, sur un écran non cité par D.3.1 mais où le besoin s'est révélé exact (D.21.5). **`Fronton` : évalué sur les 4 écrans, non utilisé** (D.21.6). **`Corridor` : conclusion architecturale des Lots 13-16 reconfirmée** (D.21.7).
- **0 résidu wallet/séquestre** — thème marketing confirmé sans lien avec le modèle financier aboli (D.21.8).
- **4 cibles tactiles réelles corrigées**, 1 hex réel retokenisé, 2 paires de styles morts supprimées (D.21.9).
- **Aucun écran des Lots 1-16 ni 18 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 ni des 3 découvertes de configuration morte du Lot 16 touchées. `AdminShell.js` lu (pour vérifier le passage de props), non modifié. Fichiers modifiés : `LieuxAdminScreen.js`, `CalendrierActionsScreen.js`, `MarketingAdminScreen.js`, `PublicitesAdmin.js` + `vehicle_character_sheets/stitch_vehicle_character_sheets/calendrier_marketing_admin_1/code.html` (traduction EN→FR) + `REFONTE_TRACKING.md` + ce fichier (section D.21). Aucune clé i18n ajoutée.
- Prochaine étape recommandée : **Lot 18 — Admin : notifications, sécurité & reste** (`NotificationsAdminScreen.js`, `CampagnesPushScreen.js`, `SecuriteAdminScreen.js`, `MFAChallengeScreen.js`, `AdminShell.js` — mobilise Corridor/Echelon ; 3 des 5 écrans sans maquette Stitch ; `AdminShell.js` est le shell de navigation lui-même, jamais retouché jusqu'ici — dernier lot de tout le chantier D).

## D.22 — Lot 18 : Admin — notifications, sécurité & reste (implémentation, 09/07/2026)

Ouvert et clôturé le 09/07/2026, conformément à D.3.2 et au process D.2bis. **Dernier lot de tout le chantier D.** 5 écrans (`NotificationsAdminScreen.js`, `CampagnesPushScreen.js`, `SecuriteAdminScreen.js`, `MFAChallengeScreen.js`, `AdminShell.js`), composants assignés par D.3.2 : Corridor, Echelon. Détail écran par écran tenu à jour dans `REFONTE_TRACKING.md` (section « Lot 18 ») — ce qui suit résume les décisions et découvertes qui méritent de rester dans le CDC.

### D.22.1 Méthode suivie

Le seul `code.html` assigné avec maquette réelle (`templates_notifications_admin`, ✅ C.1) a été lu intégralement avant tout code, même discipline que D.19.1/D.20.1/D.21.1. Les 3 autres écrans de contenu (`CampagnesPushScreen.js`, `SecuriteAdminScreen.js`, `MFAChallengeScreen.js`) sont sans maquette Stitch (fonctionnalités postérieures à l'export — campagnes push segmentées, 2FA Sprint 1) : lus intégralement et évalués contre les conventions déjà établies aux 17 lots précédents (tokens Atelier, DoD), sans référence visuelle. `AdminShell.js` (shell de navigation, jamais retouché en 17 lots admin) a été lu intégralement pour la première fois dans l'intention explicite d'y appliquer des changements, pas seulement pour vérifier le passage de props comme aux Lots 13/17. Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` menée sur le code réel des 5 écrans : 0 résultat — mais étendue aux services/RPC consommés (`notification_templates`, migrations 072/074/083/098), qui a révélé une découverte réelle, voir D.22.7.

### D.22.2 `NotificationsAdminScreen.js` — déjà largement conforme, nettoyage DoD réel

La maquette `templates_notifications_admin` (« Template Editor ») montre un layout desktop à 2 colonnes fixes : liste des templates groupés par catégorie à gauche, panneau d'édition + aperçu de notification permanent à droite (avec un bouton « New Template »). L'écran réel adopte une architecture différente et délibérée, cohérente avec le reste du chantier admin : liste groupée en colonne unique + modal d'édition via `PanneauDroit` (le même patron que `KYCValidationScreen.js`/`LitigesScreen.js`/`CampagnesPushScreen.js`), avec onglets internes Édition/Aperçu plutôt qu'un panneau toujours visible. Traité comme un écart architectural assumé, pas un défaut — imposer un panneau desktop permanent aurait cassé la cohérence avec tous les autres écrans admin à panneau modal. Le bouton « New Template » de la maquette n'a pas de contrepartie dans le code réel (création de template hors périmètre, aucune RPC d'insertion trouvée) : non ajouté, même discipline que D.16.6/D.9.6/D.21.2 (ne jamais ajouter de fonctionnalité dans une passe de refonte visuelle).

Nettoyage DoD réel trouvé : 2 hex en dur dans la table `GROUPES` (`'#8B6914'` pour `fidelite`, `'#2e7d32'` pour `finance`) — retokenisés vers `colors.nere` (précédent : trophée = néré sur `LeaderboardScreen.js`, Lot 9) et `colors.bambou` (précédent : `finances` = bambou sur `DashboardScreen.js`, Lot 13). Compromis documenté, comme au Lot 2 (D.6, écarts n°1-3) : ces 2 tokens sont déjà utilisés par `kyc` et `course_client` respectivement dans la même table — collision de couleur entre catégories acceptée (le palette Atelier CAARCO n'a que 5 teintes de base pour 7 catégories), chaque carte restant distinguée sans ambiguïté par son icône et son libellé, pas seulement sa couleur. Fallback mort trouvé et supprimé : `colors.foret10 ?? '#edf3ef'` — `colors.foret10` existe bel et bien dans `theme.js` (`'#e6ede7'`, valeur différente du fallback jamais exécuté) — même défaut exact que D.6.7 (Lot 2). 3 styles morts supprimés (`modalScrim`/`modalBoite`/`modalScroll`, jamais consommés en JSX — le modal réel passe entièrement par `PanneauDroit`, comme au Lot 17 D.21.9) — avec eux, le seul hex en dur restant du fichier (`'#0f14118c'`, porté par `modalScrim`). Cibles tactiles : `btnAnnuler`/`btnSauvegarder` de la modale d'édition (46px→52px, boutons d'action réels du flux de sauvegarde).

### D.22.3 `CampagnesPushScreen.js` — écran déjà mature, nettoyage DoD seulement

Sans maquette Stitch, mais déjà une implémentation complète et conforme aux tokens Atelier : segmentation par sexe/ancienneté/ville/note (le besoin exact décrit en D.2.5), récurrence (hebdomadaire/quotidienne/personnalisée par jours), calendrier de programmation en RN pur (`CalendrierModal`, sans dépendance externe). Aucune fonctionnalité manquante identifiée, rien ajouté. Nettoyage DoD réel : 1 style mort supprimé (`styles.overlay`, jamais consommé en JSX — un second style `overlay` existe dans le sous-composant `CalendrierModal`, celui-là bien réel) portant un hex en dur (`'#0f141166'`) ; 1 style mort supplémentaire supprimé (`styles.modal`, bloc de bottom-sheet jamais consommé — le modal réel passe par `PanneauDroit`, même motif qu'en D.22.2) ; 1 hex réellement actif retokenisé (`calS.overlay`, `'#0f141173'` → `colors.nuit + '73'`, exactement la même valeur que l'overlay de modale d'assignation retokenisé au Lot 13, D.17.10 — même motif `colors.x + 'NN'` déjà exempté de la règle zéro-hex) ; import `alpha` retiré (jamais consommé dans ce fichier, indépendamment des styles morts ci-dessus — même geste que D.21.9, appliqué ici à un import déjà mort avant ce lot plutôt que rendu mort par lui). Aucune cible tactile <52px trouvée avec une hauteur fixe explicite (seule trouvaille, `jourChip` à 44px, est une pilule de sélection de jour de la semaine — filtre/sélection, exemptée par la convention établie depuis les Lots 13-17) ; les boutons à hauteur calculée par padding (`btnNouvelle`, `dateBtn`) n'ont pas été retouchés faute de valeur mesurable sans rendu réel — même limite que toutes les vérifications de cible tactile du chantier, qui se sont toujours appuyées sur des hauteurs fixes explicites trouvées par grep, jamais sur une estimation de padding.

### D.22.4 `SecuriteAdminScreen.js` et `MFAChallengeScreen.js` — déjà conformes, non modifiés

Sans maquette Stitch (2FA admin, Sprint 1, migration `mfa`/`services/mfa.js`). Les deux écrans utilisent déjà exclusivement les tokens `theme.js`, le composant `Galet` (hauteur par défaut 52px, non surchargée) pour tous les boutons d'action, et ne portent aucun hex en dur ni aucune référence wallet/solde/séquestre (confirmé par grep). `SecuriteAdminScreen.js` reçoit et câble déjà correctement `onMenu` (contrairement au bug réel trouvé sur `LieuxAdminScreen.js` au Lot 17, D.21.3) — pas de régression de ce type ici. `MFAChallengeScreen.js` est rendu par `RootNavigator.js` **avant** `AdminShell.js` (étape de connexion aal2, hors du shell et de sa sidebar) — confirmé par lecture directe de `RootNavigator.js`, cohérent avec son absence volontaire du `MENU`/`HIDDEN` d'`AdminShell.js`, pas un oubli. Aucun changement : même traitement que `OperationsAdminScreen.js` au Lot 13 (D.17) et `RetraitsAdminScreen.js` au Lot 16 (nettoyage nul faute de défaut réel).

### D.22.5 `AdminShell.js` — décision Corridor tranchée, 1er retouche du chantier

Question posée explicitement par la consigne de cette session, avant conclusion automatique : `AdminShell.js` ne devrait-il pas être refactoré pour consommer `Corridor` en interne, plutôt que la conclusion « Corridor jamais intégré » (D.17.3, reconfirmée D.18.8/D.19.4/D.20.5/D.21.7) ne s'applique tel quel qu'aux 17 écrans de contenu ? Réponse tranchée après lecture complète de `SidebarContenu` (fonction interne d'`AdminShell.js`) : **non, pas de refactor.** `SidebarContenu` est un sur-ensemble strict de `Corridor` — sections groupées avec libellé (`GESTION`/`UTILISATEURS`/`FINANCES`/`MARKETING`/`CARTE`/`SYSTÈME`, absentes de l'API de `Corridor`, qui n'a qu'une liste plate), bloc profil (avatar+initiale, nom, téléphone), mode « rail d'icônes » replié sur mobile fermé (`etendu` bascule l'affichage des libellés, absent de `Corridor`), tiroir mobile animé (`Animated.timing`, `slideX`) et pile d'historique de navigation (`histo`, bouton retour Android) — aucune de ces capacités n'existe dans `Corridor` aujourd'hui. Faire consommer `Corridor` par `AdminShell.js` demanderait donc d'abord d'étendre `Corridor` pour égaler `SidebarContenu` (sections groupées, profil, mode replié, tiroir animé) avant de pouvoir remplacer quoi que ce soit — un chantier de refactor à risque élevé (`AdminShell.js` enveloppe les 20 écrans admin sans exception, la moindre régression serait globale) pour un gain nul : aucun changement visuel, aucune simplification nette, `Corridor` finirait par être une redite de code déjà écrit et déjà fonctionnel dans `SidebarContenu`. Conclusion cohérente avec la discipline du chantier (ne jamais refactorer au-delà du besoin réel, CLAUDE.md) et avec D.17.3 elle-même, qui notait déjà `Corridor` comme « un sur-ensemble fonctionnel » manquant face à `SidebarContenu` — cette session ne fait que vérifier explicitement que cette asymétrie n'a pas changé de sens une fois `AdminShell.js` lui-même dans le lot.

Nettoyage DoD réel, 1ʳᵉ retouche du fichier en 6 lots admin : 2 hex actifs retokenisés (`scrim`, `'#0f141185'` → `colors.nuit + '85'`, overlay du tiroir mobile ; `modalScrim`, `'#0f141199'` → `colors.nuit + '99'`, overlay de la modale déconnexion — aucun des deux n'était mort, les deux sont réellement rendus). Cibles tactiles : `btnAnn`/`btnConf` de la modale déconnexion (46px→52px, boutons d'action réels — même défaut exact que `btnAnnuler`/`btnSauvegarder` de D.22.2, trouvé indépendamment sur 2 fichiers différents du même lot).

### D.22.6 Echelon — évalué sur les 4 écrans de contenu, non utilisé

Écarté aux Lots 5/7/14 (D.9.3/D.11.6/D.18.8) faute de besoin réel constaté, puis retenu au Lot 6 (D.10.3) dans un cas précis : un stepper fait main préexistant (`CoursePlanifieeDetailScreen.js`, `ETAPES`/`puce`/`trait`) qu'`Echelon` remplaçait avec un gain réel (3 états visuels au lieu de 2). C'est cette barre de qualification — remplacer un stepper équivalent déjà construit à la main, pas habiller un écran qui n'en a aucun — qui a été appliquée aux 4 écrans de ce lot, sans le supposer acquis ni écarté d'office comme demandé. `NotificationsAdminScreen.js` : les onglets Édition/Aperçu de la modale sont un aller-retour binaire sans notion de progression (`Onglets`/motif tab déjà en place, pas un stepper) — non concerné. `CampagnesPushScreen.js` : le sous-flux `CalendrierModal` (étape date → étape heure) est un va-et-vient à 2 écrans avec bouton retour explicite, pas une séquence à 3+ états nommés — non concerné. `SecuriteAdminScreen.js` : l'inscription 2FA (inactif → QR affiché → vérifié) est la candidate la plus proche d'un besoin réel — évaluée explicitement plutôt qu'écartée par réflexe — mais l'écran actuel n'a **aucun** stepper préexistant à remplacer, seulement 2 cartes conditionnelles déjà claires par leur titre et leur icône (`shield-outline`/`shield-checkmark`) ; ajouter un `Echelon` ici créerait une section entièrement nouvelle plutôt que d'en améliorer une existante — au-delà du rôle d'une passe de refonte visuelle (CLAUDE.md, ne pas ajouter de fonctionnalité). `MFAChallengeScreen.js` : écran à une seule étape (saisie de code), non concerné. Conclusion : 0/4, mais évalué explicitement sur chacun, pas par défaut — même discipline que Fronton aux Lots 13/17 (D.17.5/D.21.6).

### D.22.7 Découverte majeure — résidus wallet/séquestre dans `notification_templates`, et un 🔴 déjà corrigé en migration mais jamais appliqué en confirmé

La recherche de mots-clés sur le code réel des 5 écrans (D.22.1) ne donne rien, mais `NotificationsAdminScreen.js` édite en direct le contenu de la table `notification_templates` (migration 072) — élargir la recherche à cette table était nécessaire, pas optionnel, puisque c'est exactement le contenu que l'écran de ce lot rend éditable. Résultat, 3 découvertes distinctes :

1. **Textes obsolètes toujours présents et éditables via cet écran** : les templates `retrait_traite_tr`/`retrait_refuse_tr` (groupe `finance`) décrivent un retrait Mobile Money pour TR qui n'existe plus dans le modèle TC (`RetraitsAdminScreen.js`, Lot 16, déjà renommé « les retraits n'existent plus dans le système TC ») — recherche exhaustive dans `App/src` et `App/supabase/functions` : **aucun appelant** de ces 2 clés trouvé nulle part, cohérent avec un résidu mort (même motif que la commission de parrainage morte du Lot 16, D.20.6) plutôt qu'un comportement actif à préserver. Le template `credit_wallet` (groupe `finance`), lui, **est réellement envoyé** aujourd'hui — appelé depuis `TransporteursAdminScreen.js:306` (`notifierAvecTemplate(..., 'credit_wallet', ...)`, écran du Lot 14, hors périmètre de ce lot-ci) : son `corps` a déjà été assaini par la migration 083 (« wallet CAARCO » → « compte CAARCO », « {montant} XAF » → « {montant} ») mais sa `description` (celle que l'admin voit dans la carte de `NotificationsAdminScreen.js`, `tpl.description`) dit encore littéralement « quand l'admin crédite le wallet d'un utilisateur » — texte fidèle au comportement réel de `admin_crediter_wallet_client` (RPC qui écrit toujours dans `wallets`/`transactions_wallet`, confirmée active en D.18.7), donc **non modifié** ici conformément à la consigne « ne jamais sanitizer un texte qui décrit fidèlement un comportement réel » (D.18.5/D.19.7) — corriger la `description` serait une édition de contenu de migration/DB, hors périmètre visuel de ce lot, et masquerait un comportement réel plutôt que de le documenter. `paiement_recu_tr`/`client_paye_sequestre_tr` (groupe `course_tr`) restent liés au modèle séquestre, architecturalement déprécié (CLAUDE.md) mais pas supprimé en base (`liberer_sequestre_course` existe toujours, désormais restreinte admin/service_role par la migration 098, voir point 2).

2. **Découverte la plus significative — vérifiée et close le 09/07/2026** : la migration `098_audit_20260708_corrections_securite.sql`, déjà présente dans `App/supabase/migrations/`, contient un correctif complet pour le 2ᵉ des 2 🔴 de la Partie C listés en tête de `REFONTE_TRACKING.md` — « Contrôle de rôle manquant sur la RPC `admin_crediter_wallet_client` » — plus 7 autres failles/bugs indépendants (policy `wallets` en écriture libre, `liberer_sequestre_course` sans contrôle d'appelant, prix course falsifiable côté client, OTP de livraison sans expiration, `debiter_commission_tc` plafonnant silencieusement à 0, `terminer_livraison` orpheline supprimée, surcharge morte de `calculer_prix`). Signalé initialement comme « application non vérifiable » faute d'accès Supabase depuis cet environnement. **Cedric a ensuite donné une autorisation explicite d'appliquer les migrations en attente** — avant d'exécuter quoi que ce soit, vérification en lecture seule (`supabase db query --linked`, CLI liée au projet réel `dxwkikaniawpfljvteog`) de chacun des 8 points de la migration 098 directement contre la base de production : **tous déjà en place**. Même vérification étendue aux migrations 099/100 (système de permissions super-admin, déjà reflété dans `AdminShell.js`) et aux 5 migrations datées les plus récentes (push tokens, campagnes push, bascule Notchpay, distance réelle, colonnes `transactions_wallet`) : **toutes déjà appliquées**. Explication du faux signal « pending » : la table de suivi CLI (`supabase_migrations.schema_migrations`) n'a jamais été alimentée sur ce projet, les migrations ayant historiquement été appliquées à la main via le SQL Editor (comme l'indiquent plusieurs en-têtes de migration, dont 098 et 099) — `supabase migration list`/`db push --dry-run` listent donc les ~104 migrations locales comme non appliquées alors qu'elles le sont toutes. **Un `supabase db push` réel n'a pas été exécuté** : il aurait tenté de rejouer l'intégralité de l'historique contre un schéma qui l'a déjà, avec un risque réel d'erreurs ou de corruption. **Le 🔴 « admin_crediter_wallet_client » est donc clos, confirmé sans qu'aucune écriture n'ait été nécessaire.** Découverte annexe : `App/supabase/migrations/fix_terminer_livraison.sql` (nom hors convention, ignoré par la CLI) recrée l'ancienne version dangereuse de `terminer_livraison` que 098 a délibérément supprimée — jamais exécuté, à supprimer du dépôt (proposé, pas fait automatiquement).
3. **Le 1er 🔴** (trigger réellement nommé `trigger_streak_client`, appelant `verifier_streak_client`, écrit encore dans `wallets` — confirmé actif en production par la même vérification en lecture seule) est **explicitement non touché** par la migration 098 elle-même, dont l'en-tête l'exclut nommément : « PointsScreen.js et MerciScreen.js sont explicitement marqués bloqué — décision Cedric... Le désactiver silencieusement casserait une fonctionnalité utilisateur active sans validation produit. » Statu quo confirmé.

Aucune modification de migration, de RPC, ni de `TransporteursAdminScreen.js` (Lot 14, hors périmètre) effectuée dans ce lot — uniquement investigation, vérification en lecture seule contre la production, et documentation, conformément à la consigne de ce lot et à la méthode déjà appliquée en D.20.6/D.20.7.

### D.22.8 Definition of done (D.2bis point 4) — vérification

- **i18n** : décision des Lots 13-17 reconduite (admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé sur les 5 écrans. Parité vérifiée par import ESM réel (`node --input-type=module`) : **1394/1394, 0 écart**, inchangé depuis le Lot 12.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 5 écrans — 2 hex retokenisés vers des tokens existants (`NotificationsAdminScreen.js`, catégories fidélité/finance), 1 fallback hex mort supprimé (`NotificationsAdminScreen.js`), 2 hex actifs retokenisés en `colors.x + 'NN'` (`CampagnesPushScreen.js`, `AdminShell.js` ×2), 2 hex morts supprimés avec leurs styles jamais consommés (`NotificationsAdminScreen.js` ×1 bloc, `CampagnesPushScreen.js` ×1). `SecuriteAdminScreen.js`/`MFAChallengeScreen.js` : confirmés déjà à 0, aucune retouche.
- **Contraste WCAG AA** : aucun token neuf introduit, tous les remplacements réutilisent des couleurs déjà validées AA ailleurs dans l'app (mêmes tokens, mêmes fonds) — non applicable, vigilance vérifiée par relecture.
- **Aucune résurgence wallet/séquestre trompeuse dans le code des 5 écrans** : confirmé par grep exhaustif (0 résultat) sur `App/src`. **Résidus réels trouvés côté données** (`notification_templates`) : voir D.22.7 — documentés, non corrigés (hors périmètre visuel, décision Cedric requise sur `credit_wallet`/description, `retrait_traite_tr`/`retrait_refuse_tr` morts).
- **Cible tactile ≥52px** : 4 manquements réels trouvés et corrigés (`btnAnnuler`/`btnSauvegarder` de `NotificationsAdminScreen.js`, `btnAnn`/`btnConf` d'`AdminShell.js`, tous 46→52px, boutons d'action réels de modales de confirmation/sauvegarde). `jourChip` (`CampagnesPushScreen.js`, 44px, pilule de sélection de jour) laissé tel quel — convention filtre/sélection déjà établie depuis les Lots 13-17. Icônes utilitaires de header (`btnMenu`, `btnFermer`, `btnClose`) non retouchées, même convention.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` retenté sur `NotificationsAdminScreen.js` et **toujours en échec** (même panne ininterrompue depuis le Lot 4, D.8.7 à D.21.9, reproduite ici sur un optional chaining/nullish coalescing sans rapport avec ce lot) — signalée une dernière fois à Cedric, la commande standard doit être réparée. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers du lot : **OK**, aucune erreur de parsing.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13-17 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue en 6 lots) — signalé une dernière fois à Cedric, non contourné par l'agent.

### Synthèse D.22

- **5 écrans traités** : `NotificationsAdminScreen.js` (2 hex catégories retokenisés, 1 fallback mort supprimé, 3 styles morts supprimés, 2 cibles tactiles corrigées), `CampagnesPushScreen.js` (2 styles morts supprimés, 1 hex actif retokenisé — écran déjà mature par ailleurs, segmentation complète confirmée), `SecuriteAdminScreen.js` et `MFAChallengeScreen.js` (déjà conformes, non modifiés), `AdminShell.js` (2 hex actifs retokenisés, 2 cibles tactiles corrigées — 1ʳᵉ retouche du fichier en 6 lots admin).
- **1 décision architecturale explicitement tranchée** : `AdminShell.js` ne doit pas être refactoré pour consommer `Corridor` — `SidebarContenu` est un sur-ensemble strict, le refactor inverserait le sens du gain (risque élevé sur les 20 écrans admin, bénéfice nul), voir D.22.5.
- **`Echelon` : évalué explicitement sur les 4 écrans de contenu, écarté sur les 4** — la barre de qualification du Lot 6 (remplacer un stepper fait main préexistant) n'est atteinte nulle part dans ce lot, y compris sur `SecuriteAdminScreen.js`, le candidat le plus proche (D.22.6).
- **1 découverte majeure, vérifiée et close** : la migration 098 (déjà dans le dépôt) corrige le 🔴 `admin_crediter_wallet_client` — confirmée appliquée en production le 09/07/2026 par lecture directe de la base réelle (sur autorisation explicite de Cedric), de même que la totalité des migrations 002-100 et des 5 migrations datées ; aucun `db push` réel exécuté (D.22.7).
- **2 templates de notification morts identifiés** (`retrait_traite_tr`/`retrait_refuse_tr`, aucun appelant trouvé) et **1 description de template non assainie mais fidèle** (`credit_wallet`) — documentés, aucune modification de migration/DB effectuée (D.22.7).
- **Aucun écran des Lots 1-17 touché**, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune migration ni RPC modifiée, `TransporteursAdminScreen.js` (Lot 14) lu en lecture seule pour la traçabilité de `credit_wallet`, non modifié. Fichiers modifiés : `NotificationsAdminScreen.js`, `CampagnesPushScreen.js`, `AdminShell.js` + `REFONTE_TRACKING.md` + ce fichier (section D.22). Aucune clé i18n ajoutée.
- **Ce lot clôt le chantier D** (refonte visuelle des 64 écrans). Bilan global en fin de `REFONTE_TRACKING.md`.
