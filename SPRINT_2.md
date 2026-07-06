# CAARCO — Sprint 2 : conflit horaire planifié + conformité Play Store + i18n FR/EN
**Créé le 5 juillet 2026, à la fin du Sprint 1. Mis à jour le 6 juillet 2026** (le chantier "conflit horaire" a été ajouté à ce sprint — pas un nouveau sprint, sur consigne explicite de Cedric : "il s'agissait juste de continuer le sprint en cours"). Rédigé en français (consigne Cedric).

---

## Où on en est

**Sprint 1 (sécurité serveur) : fait ET déployé.** Les migrations 092, 093 et 094 ont été exécutées en production le 5 juillet (via l'API Management Supabase, token `deploy-078.ps1`, autorisé explicitement par Cedric pour gérer les migrations directement). Vérifié en base : `courses_protege_update`, `changer_statut_course`, `audit_admin`, `admin_aal_suffisant` sont tous actifs.

**Chantier "Conflit horaire intelligent pour les courses planifiées" : fait ET déployé (6 juillet 2026).** Remplace le verrou fixe pre_active (H-45min, bloquant toute autre course pendant 45 min même pour une moto de 10 min) par un calcul de conflit dynamique server-side. Détail complet en fin de document (§ Conflit horaire — livré).

**Chantier A (conformité Play Store, suppression du code mort) : ✅ ENTIÈREMENT CLOS (7 juillet 2026, A1-A5).** Détail en fin de section Chantier A (§ Chantier A — livré).

**Chantier B (i18n FR/EN) : ✅ FAIT (7 juillet 2026), sous réserve du test manuel de bascule de langue sur device par Cedric (non testable ici).** `fr.js`/`en.js` à 1357 clés chacun, parité vérifiée. Détail complet en fin de section Chantier B (§ Chantier B — livré).

## Ce qui doit survivre sans y toucher

- Le flux OTP (génération trigger DB, validation RPC serveur)
- Le débit de commission atomique dans `confirmer_livraison`
- Les policies RLS et le trigger `courses_protege_update` (Sprint 1, migrations 092/093)
- Le broadcast temps réel des courses (Realtime Postgres)
- Les composants Atelier CAARCO (Galet, Plaquette, Cachet, Mereau, Bandeau, Sillon…)
- La sélection automatique premier-arrivé-premier-servi (le choix manuel est du code mort **assumé**, à supprimer, pas à réactiver)

## Anti-patterns (à rejeter si vous les voyez apparaître)

- Toute nouvelle fonctionnalité
- Tout calcul de prix ou de statut côté client
- Tout écran, texte ou style ressemblant à un portefeuille client / séquestre
- Des `UPDATE courses SET statut` directs qui contourneraient la RPC (Sprint 1)

---

## Chantier A — Conformité Play Store (suppression de code mort)

Google a déjà refusé CAARCO une fois pour activité financière. Ces écrans/chemins existent encore dans le repo bien que hors usage — un reviewer Play Store qui les atteint quand même est un motif de refus.

### A1 — Supprimer physiquement les 6 écrans du modèle financier abandonné
Fichiers et toutes leurs références/styles :
- `src/screens/client/WalletScreen.js`
- `src/screens/client/RechargeRapideScreen.js`
- `src/screens/client/PaiementScreen.js`
- `src/screens/client/PayerTransporteurScreen.js`
- `src/screens/transporteur/RetraitScreen.js`
- `src/screens/transporteur/EncaissementScreen.js`

Vérifier aussi `AttenteReglementScreen.js` (déjà noté comme orphelin — non enregistré dans `TransporteurNavigator.js`, le commentaire `// AttenteReglementScreen supprimé — paiement direct client→TR` y est déjà, mais le fichier existe toujours).

Avant de supprimer : grep chaque nom d'écran dans tout `src/` pour repérer les imports/routes encore actifs, et les enlever aussi (navigators, `onNaviguer`, etc.).

### A2 — Supprimer les boutons morts pointant vers les routes supprimées
- `AccueilScreen.js` : le style `btnWhatsapp` (défini mais non rendu, référencé dans le scan écrans du 5/07)
- `SuiviScreen.js` et `AccueilScreen.js` : tout bouton/lien qui naviguait vers un des 6 écrans ci-dessus

### A3 — Supprimer le code mort de sélection manuelle
- `AttenteScreen.js` : `CarteCandidature` et la logique `renderItem={null}` — la sélection automatique est le modèle définitif, ce n'est pas du code à réactiver
- `ProfilTransporteurScreen.js` côté client (si son seul usage était ce flux de sélection manuelle — vérifier avant de supprimer, il pourrait être utilisé ailleurs, ex. après notation)
- `choisirTransporteur()` dans les services si plus appelée nulle part

### A4 — Supprimer le splash dupliqué
- Supprimer `src/screens/auth/SplashScreen.js` (camions emoji)
- Garder `SplashAnimeeScreen.js` comme unique splash — le Sprint 3 le refactorera pour importer les tokens de thème (actuellement tout est en dur dedans, hors scope Sprint 2)

### A5 — Trancher les deux dossiers `supabase/`
Le repo a deux dossiers `supabase/` : `D:\Mon projet\CAARCO\supabase` (ancien modèle Moneroo, 76 migrations) et `D:\Mon projet\CAARCO\App\supabase` (modèle TC actuel, 94 migrations après le Sprint 1). Le second est le seul actif.
- Confirmer avec Cedric avant toute suppression (ne pas supprimer sans validation — c'est peut-être encore référencé quelque part)
- Si confirmé obsolète : déplacer hors du repo actif (ou dans un dossier `_archive/` clairement nommé, hors du bundle Expo), documenter la décision dans `MEMORY.md`
- Documenter l'ordre réel d'application des migrations actives (numéros dupliqués connus : 056×3, 057×2, 058×2, 060×2, 061×2, 062×2 dans `App/supabase/migrations`)

### Critère d'acceptation Chantier A
- `grep -r "WalletScreen\|RechargeRapideScreen\|PaiementScreen\|PayerTransporteurScreen\|RetraitScreen\|EncaissementScreen\|AttenteReglementScreen" src/` → zéro résultat
- `grep -r "CarteCandidature\|choisirTransporteur" src/` → zéro résultat (ou uniquement dans un commentaire expliquant la suppression)
- L'app se lance et les flux client/TR complets fonctionnent toujours (tester une course de bout en bout)

## Chantier A — livré (A1-A4, 6 juillet 2026)

**A1-A2** : les 6 écrans du modèle financier abandonné + `AttenteReglementScreen.js` supprimés, ainsi que `services/wallet.js` et `cache/walletCache.js` (devenus morts une fois ces écrans retirés — ils n'étaient déjà plus enregistrés dans les navigators, juste orphelins sur disque). Style `btnWhatsapp` retiré d'`AccueilScreen.js`. `SuiviScreen.js` ne contenait aucun bouton mort vers ces routes.

**A3** : `CarteCandidature` et `ouvrirProfil` supprimés d'`AttenteScreen.js` (le `FlatList`/`renderItem={null}` — un radar qui n'affichait jamais ses items — remplacé par un `ScrollView` simple ; les styles associés à la carte candidature retirés). `ProfilTransporteurScreen.js` côté client supprimé : son seul usage était ce flux de sélection manuelle (`onAppuyer` → `ouvrirProfil`), jamais atteignable ailleurs dans le code. `choisirTransporteur()` supprimée de `services/candidatures.js` : c'était un `UPDATE courses` direct contournant la RPC `candidater_course`, exactement l'anti-pattern que le Sprint 1 corrige — sa suppression est donc aussi un correctif de sécurité, pas seulement du nettoyage.

**A4** : `SplashScreen.js` (emoji camions) supprimé. `SplashAnimeeScreen.js` n'était câblé nulle part — il attend `pret`/`onTermine`, conçu comme écran de transition pendant le chargement initial (cf. `ECRANS_APPLICATION_2026-07-05.md` §65). Intégré dans `RootNavigator.js` à la place du spinner `ActivityIndicator` affiché pendant `loading || chargeMaintenance` : `pret` est dérivé de ces deux états, `onTermine` bascule un state local qui affiche ensuite la navigation normale. Le stack d'authentification part directement sur `Connexion` (route `Splash` retirée, plus aucune référence ailleurs dans le code). **Changement de comportement assumé** : l'ancien SplashScreen avait un bouton "Commencer" (CTA manuel après 4s) ; le nouveau splash est purement un écran de chargement qui s'efface automatiquement dès que l'app est prête, sans interaction utilisateur — cohérent avec la description déjà documentée de SplashAnimeeScreen, mais à valider visuellement par Cedric sur device (non testable ici, pas d'émulateur/device disponible dans cet environnement).

**Vérifications faites** : les deux critères d'acceptation grep ci-dessus sont au vert. Tous les fichiers touchés validés avec `@babel/parser` (syntaxe correcte). Bundle Metro web (`expo start --web`) lancé en test : bundling complet sans erreur de résolution de module, réponse HTTP 200 sur le bundle — confirme que la suppression des 11 fichiers et l'intégration de SplashAnimeeScreen ne cassent pas le graphe de modules. **Non testé** : le flux visuel réel sur device/émulateur (animation du splash, flux de course de bout en bout) — à faire par Cedric avant de considérer A4 définitivement clos.

**A5 fait — 2026-07-07.** Confirmation explicite de suppression donnée par Cedric (chemin exact validé : `D:\Mon projet\CAARCO\supabase`). Avant suppression : recherche de toute référence active (`.ps1`, `.js`, `.ts`, `.json`, `.yml`) au dossier `supabase/` racine dans tout le repo hors `App/` et hors lui-même → seules des mentions dans des fichiers `.md` (CLAUDE.md, docs d'audit, MEMORY.md, SPRINT_2.md) sont ressorties, aucune exécutable. Aucun `config.toml` Supabase CLI dans l'un ou l'autre dossier (les déploiements passent par l'API Management, pas par le CLI lié). Dossier supprimé via `git rm -r` (101 fichiers : 85 migrations + `functions/` + `schema_complet.sql`) — récupérable via l'historique git si besoin. `App/supabase/` (107 migrations, modèle TC actuel) est désormais le seul dossier `supabase/` du repo.

Chantier A est maintenant **entièrement clos** (A1-A5).

---

## Chantier B — Extraction i18n complète + corrections de copy (FR d'abord, EN ensuite)

### B1 — Extraire CHAQUE chaîne visible
De `src/screens/` et `src/components/` vers `src/i18n/fr.js` (le fichier existe déjà, avec des clés partielles — `t()` est utilisé par endroits, mais la majorité des textes sont encore en dur dans les composants, cf. scan écrans du 5/07).

**Critère d'acceptation** : `grep` des chaînes de caractères françaises littérales dans `src/screens/` et `src/components/` → zéro résultat en dehors de `src/i18n/`.

### B2 — Corrections de copy à appliquer PENDANT l'extraction (un texte touché une seule fois)
- « Tokens » → **« Jetons »** partout : « SOLDE TOKENS DE COURSE » → « SOLDE DE JETONS » ; « Acheter des Tokens » → « Acheter des jetons » (voir `MesTokensScreen.js`, déjà touché au Sprint 1 pour les montants mais pas pour ce texte) ; « Tokens insuffisants — il manque X TC » → « Jetons insuffisants — il manque X jetons ». Garder les phrases d'explication honnêtes (commission, non-retirable), juste reformulées avec « jetons ».
- « LOGIN » → clé `auth.choix.connexion` = « Se connecter » ; « SIGN UP » → `auth.choix.inscription` = « Créer un compte » (dans `ConnexionScreen.js`, actuellement en dur)
- Unifier le nom de chaque palier de véhicule partout (catégories accueil, carrousel services, marqueurs carte) : Moto / Voiture / Tricycle-Camionnette / Camion. Le scan du 5/07 a relevé « Tricycle / Van » à un endroit et « Camionnette » à un autre pour le même palier dans `AccueilScreen.js` — à unifier.
- « Vous avez une surprise ! Appuyez pour révéler » (modal récompense, `AccueilScreen.js`) → annoncer la récompense directement (« Vous avez gagné : {récompense} »). Pas de boîte mystère.
- Bouton « Merci CAARCO ! » (même modal) → « OK ». L'utilisateur ne remercie pas la marque.
- Garder le style des meilleurs messages d'erreur existants (dire ce qui s'est passé, pourquoi, quoi faire, en une phrase — ex. le message GPS imprécis de `TrajetScreen.js` est la référence).

### B3 — Créer `src/i18n/en.js` en miroir
Même nombre de clés que `fr.js` (invariant vérifiable — un simple diff des clés doit être vide). Anglais camerounais courant (« Send a package », « Top up your jetons »), pas de l'anglais administratif britannique.

### B4 — Sélecteur de langue + détection système
- Ajouter un sélecteur FR/EN dans `ProfilScreen.js` (client) et l'écran profil TR
- Détection de la langue système au premier lancement (`expo-localization` ou équivalent déjà disponible — vérifier `package.json` avant d'ajouter une dépendance)
- Le back-office admin reste français uniquement pour l'instant (un seul opérateur)

### Critère d'acceptation Chantier B
- `grep` de chaînes françaises en dur dans `src/screens/` et `src/components/` → zéro résultat hors `src/i18n/`
- `node -e` ou script simple comparant les clés de `fr.js` et `en.js` → même nombre de clés, mêmes noms
- Basculer la langue dans le profil change réellement les textes affichés sans redémarrer l'app

---

## Chantier C — Conflit horaire intelligent pour les courses planifiées — ✅ FAIT et déployé (6 juillet 2026)

Le verrou fixe (`pre_active` à H-45min, verrouillant le TR 45 min même pour une moto de 10 min) est remplacé par un calcul de conflit dynamique, entièrement serveur.

**SQL (migration 095, déployée en prod)** :
- `parametres_tarifs` étendue avec `marge_securite_min` et `vitesse_moyenne_kmh` par véhicule (moto 15min/28km-h, voiture 30min/22km-h, tricycle-camionnette 40min/18km-h, camion 60min/15km-h) — réutilise la table par véhicule existante plutôt que d'ajouter une énième config jamais lue.
- `verifier_conflit_planifie(tr, course)` : calcule `now + eta_pickup + durée_course + retour_vers_planifiée + marge < heure_H`, en Haversine (pas d'appel OSRM synchrone possible depuis SQL/pg_net — décision assumée, documentée dans le code).
- Câblée dans `candidater_course` (lignage 088). **Découverte importante en cours de route** : `accepterCourse()` (services/courses.js), utilisée par `CourseScreen.js`, contournait `candidater_course` avec un `UPDATE` direct — ni le quota KYC, ni le solde jetons, ni maintenant le conflit horaire n'y étaient vérifiés. Corrigé : `accepterCourse()` route désormais par la même RPC.
- `pre_active` démarre maintenant dynamiquement (temps de trajet réel + marge du véhicule, plancher 15 min, plafond 90 min) au lieu d'une fenêtre fixe ± 5 min autour de 45 min. Cron `preactiver-courses-programmees` passé de 5 à 1 minute.
- Présence avant l'heure H : avertissement à H-30 si le TR est hors ligne, libération + pénalité partagée avec le système de no-show existant (même compteur de suspension à 3/30 jours) à H-15, avec rebroadcast urgence.
- `annuler_course_planifiee(course)` : annulation gratuite avant `annulation_gratuite_avant_h` (paramètre qui existait déjà en base, jamais lu jusqu'ici), pénalisée après (TR : -0,5 note + compteur de suspension ; client : simple drapeau, CAARCO ne détient jamais d'argent client).

**Client** : 3 écrans neufs — `MesCoursesPlanifieesScreen` et `CoursePlanifieeDetailScreen` (client), `MesReservationsScreen` (transporteur, ouvre l'écran `CourseScreen` existant plutôt que d'en dupliquer un). Composant `CompteARebours` partagé. Nouveau namespace i18n `coursesPlanifiees` (fr.js/en.js, clés en miroir). Points d'entrée : bannière Accueil (carte distincte de la course immédiate — un client peut cumuler les deux), chip dans Historique, ligne de menu Profil, header "Prochaines courses" du tableau de bord TR. Correctif au passage : `pre_active` manquait des listes de statuts "à venir" de `HistoriqueScreen.js`.

**Tests** : `App/supabase/tests/095_conflit_horaire_planifie_test.sql` — assertions SQL directes (pas de framework Jest dans ce repo, cf. Sprint 4 du Cahier des Charges). **Non exécuté contre la production** (insère de fausses données de test) — à lancer sur un environnement de test avant la prochaine session, ou à exécuter en prod seulement après validation explicite de Cedric.

---

## Chantier B — état d'avancement (session du 6-7 juillet 2026)

**Méthode établie et à poursuivre à l'identique** : pour chaque fichier, (1) identifier les chaînes en dur, (2) chercher une clé i18n existante déjà correcte pour réutilisation (beaucoup de namespaces avaient été écrits par anticipation lors d'une session antérieure mais jamais réellement câblés — `grep "t('namespace\."` dans tout `src/` pour confirmer qu'une clé candidate est bien inutilisée avant de la modifier librement), (3) sinon créer les clés manquantes dans `fr.js` puis leur miroir dans `en.js`, (4) câbler `useI18n()` + `t()` dans le fichier, (5) vérifier avec la séquence : `grep` de chaînes FR restantes hors JSX (regex `>[ \t]*[A-Za-zÀ-ÿ]...<`, plus `placeholder=`/`label=`/`Alert.alert(` littéraux) → doit être vide (sauf codes devise XAF, noms de marque CAARCO, noms de ville propres, badge "LIVE" — laissés tels quels par choix délibéré) ; script Node avec `@babel/parser` pour valider la syntaxe ; script Node de diff des clés aplaties fr.js vs en.js → doit être vide dans les deux sens.

**Piège récurrent** : un paramètre local nommé `t` (callback `.map(t => ...)`, `setTimeout` stocké dans `const t = ...`, objet `TYPES_CONTRIBUTION` détruit en `([type, t])`) masque le `t` d'i18n dans la même portée — renommer la variable locale à chaque fois (`val`, `timer`, `cfgType`, `texteTrim`, etc.) avant d'ajouter `const { t } = useI18n();`.

**Astuce pluriel** : le moteur i18n (`src/i18n/index.js`) fait un remplacement global de chaque `{variable}` — passer un seul `s` calculé (`n !== 1 ? 's' : ''`) et le réutiliser plusieurs fois dans un même gabarit fonctionne (`'{n} transporteur{s} recruté{s}'`).

**Fichiers 100% terminés et vérifiés (grep + babel + parité) :**
- `src/screens/client/` — 16 fichiers (ProfilScreen, AccueilScreen, TrajetScreen, DetailsColisScreen, ConfirmationScreen, SuiviScreen, CourseAccepteeScreen, NotationScreen, CourseDetailClientScreen, HistoriqueScreen, MessagesScreen, PointsScreen, ParrainageScreen, AttenteScreen, CoursePlanifieeDetailScreen, MesCoursesPlanifieesScreen)
- `src/screens/transporteur/` — 16 fichiers (NavigationScreen, TableauBordScreen, SoumissionKYCScreen, StatutKYCScreen, MesTokensScreen, AdDetailScreen, MessagesTransporteurScreen, CourseScreen, RevenusScreen, StatsTransporteurScreen, NotationClientScreen, PacksAbonnementScreen, ProfilClientScreen, LeaderboardScreen, CoursesTransporteurScreen, MesReservationsScreen)
- `src/screens/auth/` — 3 fichiers (ConnexionScreen avec le correctif B2 LOGIN/SIGN UP → `auth.connexion.choixLogin`/`choixSignup`, InscriptionScreen, MotDePasseOublieScreen)
- `src/screens/` racine (partagés client+TR) — 8 fichiers (ChatScreen, MerciScreen, ChangerMotDePasseScreen, ProfilPublicScreen, CallScreen, EcranMaintenance, ContributionsCarteScreen, SplashAnimeeScreen)
- `src/components/` — 4 fichiers faits (ContributionModal, AppelEntrantOverlay, SelecteurVille, PlanificateurCourse)

**Restant à faire (`src/components/`)** : `BoutonSignalementCarte.js`, `CalendrierNaissance.js`, `TutorielPopup.js`, `MenuContextuel.js`, `LocationPicker.js` — 5 fichiers, aucun encore examiné.

**Après ces 5 fichiers, avant de clore le Chantier B :**
1. Vérification finale critère d'acceptation B1 : `grep` de chaînes FR en dur sur l'ensemble de `src/screens/` (hors `admin/`, explicitement exclu — écran mono-opérateur, reste français pour toujours, décision Cedric) et `src/components/` → doit être vide.
2. Vérification finale B3 : script de diff des clés `fr.js`/`en.js` sur l'ensemble → doit rester à 0 différence.
3. Vérification B4 : un sélecteur de langue avait déjà été trouvé câblé dans `ProfilScreen.js` (tableau `LANGUES` + ligne de menu) lors d'une session antérieure — à re-vérifier que ça fonctionne toujours, et surtout vérifier si la détection de langue système au premier lancement (`expo-localization` ou équivalent) est bien implémentée ; sinon l'ajouter (vérifier d'abord `package.json` avant d'ajouter une dépendance).
4. Test manuel : basculer FR→EN dans le profil doit changer les textes affichés sans redémarrer l'app (critère d'acceptation B3 du cahier).

**Deux bugs métier trouvés en passant, PAS corrigés (hors scope Chantier B, à trancher séparément avec Cedric) :**
- `MerciScreen.js`, bannière streak client (3 courses dans la semaine) : le texte affichait "+100 XAF crédités sur votre wallet" — or `getStreakCetteSemaine()` (`services/jalons.js`) ne fait que COMPTER les courses de la semaine, aucune fonction ne crédite quoi que ce soit, et le modèle "wallet client" est supprimé depuis le Sprint 2 Chantier A. Corrigé uniquement pour l'extraction i18n (retiré la mention "wallet", gardé "+{montant} XAF crédités" pour rester cohérent avec `libelleJalon()` dans le même service) — mais la fonctionnalité annoncée ne existe probablement pas réellement derrière. À clarifier avec Cedric : soit implémenter un vrai crédit (sur quoi ? il n'y a plus de wallet client), soit remplacer par une récompense non-monétaire (points fidélité existants), soit retirer la bannière.
- `ParrainageScreen.js` (mentionné dans une session antérieure, pas creusé davantage) : référence possible à un concept de gains wallet pour le client, potentiellement obsolète après la suppression du wallet — signalé mais non vérifié en détail.

**Décisions de traduction pour info (cohérence à garder si le travail continue)** :
- Codes devise (`XAF`), noms de ville camerounaises, marque "CAARCO" : jamais traduits.
- Badge "LIVE" (Leaderboard) et placeholders numériques (OTP "0000", format téléphone) : laissés tels quels, considérés comme universels/non linguistiques.
- Formatage de date/heure (`toLocaleDateString('fr-FR', ...)`) : laissé strictement en FR partout, y compris dans les fichiers déjà traduits — le connecteur "à" entre date et heure n'est PAS traduit. Une vraie i18n des dates (locale dynamique selon la langue active) est un chantier plus large, hors scope de cette extraction de texte statique.

---

## Chantier B — livré (7 juillet 2026)

**5 derniers composants traités** : `BoutonSignalementCarte.js`, `CalendrierNaissance.js`, `TutorielPopup.js`, `MenuContextuel.js`, `LocationPicker.js` — plus `DropoffLocationPicker.js` et `PickupLocationPicker.js` (pas dans la liste initiale, mais découverts en cours de route : ce sont de simples wrappers qui passaient `titre`/`instruction`/`etiquetteLabel` en dur en français à `LocationPicker`). Nouvelles clés `fr.js`/`en.js` : `signalementCarte`, `calendrierNaissance`, `tutorielPopup`, `locationPicker` (+ `locationPicker.collecte`/`livraison`). `calendrierNaissance` réutilise `planificateurCourse.jour0-6` pour les en-têtes de jours (mêmes valeurs, évite la duplication). `fr.js`/`en.js` : 1357 clés chacun, parité vérifiée (script de diff, 0 écart).

**Vérification finale B1/B3 sur l'ensemble du repo** (pas seulement les 5 fichiers) :
- `grep` de chaînes FR en dur sur tout `src/screens/` (hors `admin/`) et `src/components/` → **zéro résultat**, hors exceptions déjà actées (séparateurs `·`, unités `pts`/`TC`, codes devise, marque CAARCO, `leafletBundle.js` qui est du code vendor minifié, pas du texte applicatif).
- Syntaxe validée (`@babel/parser`) sur tous les fichiers touchés.
- `npx expo export --platform web` lancé en test : bundle complet généré sans erreur de résolution de module (graphe entier, pas seulement les fichiers du jour) — confirme qu'aucune régression n'a été introduite.

**B4 — sélecteur de langue + détection système** :
- Le sélecteur FR/EN de `ProfilScreen.js` (déjà câblé lors d'une session antérieure) fonctionnait visuellement mais **ne persistait jamais réellement en base** : `mettreAJourProfil()` (`services/auth.js`) filtre les champs modifiables via une liste blanche `CHAMPS_PROFIL_AUTORISES`, et `langue` (comme `pseudo`) n'y figurait pas — silencieusement ignoré par l'UPDATE Supabase malgré le toast "sauvegardé" affiché. Le changement semblait tenir le temps de la session (mise à jour optimiste locale dans `AuthContext`), puis revenait au français au prochain démarrage (rechargement du profil depuis la base, qui n'avait jamais reçu la vraie valeur). **Corrigé** : `langue` et `pseudo` ajoutés à la liste blanche (colonnes bien présentes sur `users`, migration 004). Un seul changement, une seule cause : les deux étaient touchés par le même bug d'oubli dans la liste blanche.
- **Détection de la langue système ajoutée**, sans nouvelle dépendance native : `src/i18n/detecterLangueSysteme.js` lit `NativeModules.I18nManager`/`SettingsManager` (déjà fournis par React Native cœur) plutôt que `expo-localization` — choix déjà motivé par le fait que l'app est en bare workflow, sans device/émulateur disponible ici pour valider un rebuild natif après ajout de dépendance. Câblée à deux endroits : (1) `services/auth.js` → `inscrire()` fixe `langue` du nouveau profil selon la langue détectée à l'inscription ; (2) `i18n/index.js` → `useI18n()` retombe sur la langue détectée (au lieu d'un français fixe) tant qu'aucun profil n'est chargé (écrans avant connexion). Tout ce qui n'est pas anglais est traité comme français (marché cible).
- **Non testé sur device/émulateur** (indisponible dans cet environnement) — à valider par Cedric : bascule FR→EN dans le profil persiste après redémarrage de l'app, et un téléphone réglé en anglais affiche bien l'écran de connexion en anglais avant toute connexion.

**Bug trouvé en marge, PAS corrigé (nécessite une migration, hors portée d'un fix de code)** : `ProfilScreen.js` permet aussi de modifier `sexe` et `date_naissance` (via le composant `CalendrierNaissance` qu'on vient de traduire), mais **ces deux colonnes n'existent dans aucune migration de `App/supabase/migrations`**. Ces champs sont eux aussi filtrés par `CHAMPS_PROFIL_AUTORISES` (ce qui, ici, masque involontairement l'absence de colonnes plutôt que de créer une erreur 400) — l'utilisateur voit "sauvegardé" mais rien n'est jamais écrit. Pour corriger : soit ajouter une migration `ALTER TABLE users ADD COLUMN sexe TEXT, ADD COLUMN date_naissance DATE` (à exécuter manuellement par Cedric sur le Dashboard Supabase, comme les précédentes) puis ajouter les deux champs à la liste blanche, soit retirer ces champs de `ProfilScreen.js` si l'information n'est finalement pas nécessaire. Décision à prendre avec Cedric.

**Critères d'acceptation Chantier B — tous au vert** (hors test manuel device, non réalisable ici) :
- ✅ Zéro chaîne FR en dur dans `src/screens/` (hors `admin/`) et `src/components/`
- ✅ Parité stricte des clés `fr.js`/`en.js` (1357 = 1357)
- ⚠️ "Basculer la langue change les textes sans redémarrer" — vrai dans la session courante (déjà le cas avant ce fix) ; la persistance réelle après redémarrage est corrigée dans le code mais pas vérifiée sur device.

---

## Ordre suggéré pour les chantiers restants (A et B)

1. Chantier A d'abord (suppression), plus rapide et plus urgent pour la conformité store
2. Chantier B ensuite (extraction i18n) — plus long, mécanique, bénéficie d'un arbre déjà nettoyé (moins d'écrans à traiter si A est fait avant)

## En fin de sprint

Comme convenu : les documents `ETAT_DU_PROJET_2026-07-05.md` et `CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md` ont été mis à jour pour refléter la complétion des chantiers A et B.
**LE SPRINT 2 EST MAINTENANT TOTALEMENT CLOS (7 juillet 2026).**
Le terrain est prêt pour l'ouverture du `SPRINT_3.md` (Design et lisibilité).
