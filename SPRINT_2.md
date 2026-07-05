# CAARCO — Sprint 2 : conflit horaire planifié + conformité Play Store + i18n FR/EN
**Créé le 5 juillet 2026, à la fin du Sprint 1. Mis à jour le 6 juillet 2026** (le chantier "conflit horaire" a été ajouté à ce sprint — pas un nouveau sprint, sur consigne explicite de Cedric : "il s'agissait juste de continuer le sprint en cours"). Rédigé en français (consigne Cedric).

---

## Où on en est

**Sprint 1 (sécurité serveur) : fait ET déployé.** Les migrations 092, 093 et 094 ont été exécutées en production le 5 juillet (via l'API Management Supabase, token `deploy-078.ps1`, autorisé explicitement par Cedric pour gérer les migrations directement). Vérifié en base : `courses_protege_update`, `changer_statut_course`, `audit_admin`, `admin_aal_suffisant` sont tous actifs.

**Chantier "Conflit horaire intelligent pour les courses planifiées" : fait ET déployé (6 juillet 2026).** Remplace le verrou fixe pre_active (H-45min, bloquant toute autre course pendant 45 min même pour une moto de 10 min) par un calcul de conflit dynamique server-side. Détail complet en fin de document (§ Conflit horaire — livré).

Chantiers **restants** de ce Sprint 2 (pas encore commencés) :
1. Conformité Play Store (suppression du code mort lié à l'ancien modèle financier)
2. Extraction i18n complète FR/EN + corrections de copy

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

## Ordre suggéré pour les chantiers restants (A et B)

1. Chantier A d'abord (suppression), plus rapide et plus urgent pour la conformité store
2. Chantier B ensuite (extraction i18n) — plus long, mécanique, bénéficie d'un arbre déjà nettoyé (moins d'écrans à traiter si A est fait avant)

## En fin de sprint

Comme convenu : mettre à jour `ETAT_DU_PROJET_2026-07-05.md` et `CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md` (cocher les items faits), committer, puis **mettre à jour ce même `SPRINT_2.md`** tant que les chantiers A et B ne sont pas terminés — pas de `SPRINT_3.md` avant que ce sprint soit réellement clos (consigne Cedric, 6 juillet 2026).
