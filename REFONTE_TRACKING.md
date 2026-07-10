# CAARCO — Suivi de la refonte visuelle complète (Partie D)

**Créé le 8 juillet 2026.** Rédigé en français (consigne Cedric). Complète `CAARCO_Cahier_Charges_Reprise_et_Prompt_REV1.md` Partie D (D.0-D.2bis) — ce fichier-ci est l'état d'avancement écran par écran, mis à jour à la fin de chaque lot, pour qu'une nouvelle conversation puisse reprendre sans relire toute la Partie D.

**Ne pas dupliquer le contenu de la Partie D ici** : ce fichier ne contient que le statut. Pour la méthode, les preuves de mapping, les composants disponibles et les règles de gouvernance (C.1-C.4), voir le CDC.

Statuts possibles : `à faire` · `en cours` · `fait` · `bloqué` (décision Cedric en attente) · `sans maquette` (à concevoir sans référence Stitch).

---

## Lot 0 — Composants transverses (D.2bis point 2)

**Statut global : fait (08/07/2026).** 11 nouveaux fichiers créés dans `App/src/components/`, plus un écran-catalogue dev-only. Detail par composant ci-dessous — voir CDC D.4 pour le compte-rendu complet (décisions, écarts avec D.3.1, definition of done).

| Composant proposé | Rôle | Statut | Notes |
|---|---|---|---|
| Borne | Tuile KPI (icône + chiffre mono + libellé + delta) | fait | `Borne.js`. Lots 6, 8, 9, 13, 16 |
| Sentier | Connecteur vertical d'itinéraire (sans état d'étape) | fait | `Sentier.js`. Lots 3, 4, 7, 11 |
| Etal | Groupe de cartes à sélection exclusive | fait | `Etal.js`. Lots 2, 3 |
| Pochette | Tuile média/document (dropzone, galerie, zoom) | fait | `Pochette.js`. Zoom via `ScrollView` natif (`maximumZoomScale`) — pas de nouvelle dépendance. Lots 3, 10, 15 |
| Silo | Graphique en barres CSS (axes + tooltip) | fait | `Silo.js`. État vide i18n (`silo.aucuneDonnee`). Lots 8, 9, 13, 16 |
| Étoiles | Notation par étoiles (interactive/lecture seule) | fait | `Etoiles.js`. Lots 5, 9 |
| Jauge | Barre de progression linéaire continue (%) | **non créé — déjà couvert** | Voir « Écart avec D.3.1 » ci-dessous : `Jalons.js` (existant, jamais utilisé jusqu'ici) fait déjà exactement ce rôle. Lots 4, 7 réutiliseront `Jalons.js` directement. |
| Corridor | Navigation latérale fixe desktop (admin) | fait | `Corridor.js`. Lots 13, 14, 15, 16, 17, 18 |
| Passoire | Barre recherche + filtres combinés (admin) | fait | `Passoire.js`. Lots 13, 14 |
| Fronton | En-tête de section + action "voir tout" | fait | `Fronton.js`. Lots 2, 13, 17 |
| Echo | Indicateur de recherche/attente temps réel (sans valeur chiffrée) | fait | `Echo.js`, animation `Animated` (radar + point pulsé). Lots 2, 4, 7 |
| Cadran | Sélecteur de période en pilule (mois/date) | fait | `Cadran.js`. Preuve toujours limitée à 2 écrans (Lots 13, 17) — reconfirmée à l'ouverture (08/07/2026), construit en dernier comme prévu. |

### Écart avec D.3.1 — Jauge n'a pas été créé

En relisant le code réel (pas seulement la glose de la boîte à outils D.2) avant de créer un nouveau fichier : `App/src/components/Jalons.js` est déjà une barre de progression continue % avec libellé (`progression`, `label`), **sans étapes nommées** — exactement la définition de « Jauge » en D.3.1 #7. Le vrai stepper à états nommés (fait/actif/à venir) est en réalité `Echelon.js`. Les deux fichiers existaient déjà mais n'étaient importés par **aucun** écran (`grep` vérifié) — l'hypothèse de D.3.1 selon laquelle « Jalons = stepper à états nommés » s'appuyait sur l'annotation des maquettes Stitch, pas sur une lecture du fichier réel. Un commentaire a été ajouté en tête de `Jalons.js` pour référencer cet alias. Aucun renommage effectué (zéro import existant à casser, mais renommer un fichier hors périmètre du Lot 0 sans nécessité n'a pas été jugé utile). **Action pour les Lots 4 et 7** : importer `Jalons.js` directement, pas de composant `Jauge` à chercher.

### Écran-catalogue (dev-only)

`App/src/screens/dev/CatalogueComposantsScreen.js` — affiche les 12 composants (11 nouveaux + Jalons/Jauge) dans leurs états (interactif/lecture seule, vide/rempli). **Jamais dans la navigation de prod** : monté uniquement derrière `if (__DEV__ && catalogueOuvert)` dans `RootNavigator.js`, ouvert via un bouton flottant rouge (latérite) visible seulement en dev, jamais un `Stack.Screen` enregistré. Éliminé statiquement par Metro en build release.

### Captures avant/après — bloqué dans cet environnement

`scripts/capture-auto.ps1` nécessite un téléphone Android branché en USB (déboguage activé) + Maestro installé. Aucun des deux n'est disponible dans cet environnement d'agent (`adb`: commande introuvable ; pas d'émulateur). **À faire par Cedric** : soit lancer le script sur son poste avec le téléphone branché (mais `caarco_tous_ecrans.yaml` ne visite pas l'écran-catalogue, qui n'est pas dans la navigation normale — captures utiles surtout pour confirmer l'absence de régression sur les écrans existants, qui n'ont pas été touchés dans ce Lot), soit ouvrir directement le catalogue via le bouton flottant en dev et faire une capture manuelle pour la revue visuelle des 12 composants.

---

## Auth (3 écrans)

| Écran | Maquette Stitch | Statut | Lot |
|---|---|---|---|
| `auth/ConnexionScreen.js` | `connexion_caarco` | fait (08/07/2026) | Lot 1 |
| `auth/InscriptionScreen.js` | `cr_er_un_compte_caarco` | fait (08/07/2026) | Lot 1 |
| `auth/MotDePasseOublieScreen.js` | `mot_de_passe_oubli_caarco` | fait (08/07/2026) | Lot 1 |

## Partagés — racine `screens/` (11 écrans, dont 1 déjà fait)

| Écran | Maquette Stitch | Statut | Lot |
|---|---|---|---|
| `ProfilScreen.js` | `mon_profil_caarco_1`, `_2` | bloqué | Décision Cedric sur `sexe`/`date_naissance` (C.3.1) avant retouche. Lot bloqué (D.3.3), rattachement futur au voisinage du Lot 12. |
| `ProfilPublicScreen.js` | `profil_client_caarco` (bloc avis+contact) | fait (09/07/2026) | Lot 12. Redondance avec `transporteur/ProfilClientScreen.js` clarifiée au Lot 11 (pas de fusion, voir CDC D.15.2). **`profil_transporteur_caarco` écarté comme référence** — ce n'est pas une variante-rôle du profil de confiance générique mais une fiche d'offre/enchère (« Choisir ce transporteur », prix proposé) qui ne correspond à aucun écran de l'inventaire D.2, voir CDC D.16. |
| `MerciScreen.js` | `merci_caarco` | bloqué | Décision Cedric sur la récompense streak (C.2 #3) avant retouche. Lot bloqué (D.3.3), rattachement futur au voisinage des Lots 5-6. |
| `EcranMaintenance.js` | `maintenance_en_cours_caarco` | fait (09/07/2026) | Lot 12 |
| `ChatScreen.js` | `messagerie_caarco_2` | fait (09/07/2026) | Lot 12 |
| `MessagesScreen.js` | `messagerie_caarco_1` | fait (09/07/2026) | Lot 12. **Fichier réel à `client/MessagesScreen.js`**, pas à la racine de `screens/` comme l'inventaire le laissait supposer — voir CDC D.16. |
| `OnboardingScreen.js` | Aucune | fait (08/07/2026) — revu, déjà conforme, non modifié | Lot 1 |
| `SplashAnimeeScreen.js` | Aucune | fait | Déjà refondu Sprint 3 — hors périmètre D, aucun lot. |
| `CallScreen.js` | Aucune | fait (09/07/2026) — déjà conforme, non modifié | Lot 12. Sans maquette (D.2.2) — implémentation WebView Jitsi déjà propre (0 hex, i18n complet), confirme que les actions Appel/Vidéo de `ProfilPublicScreen.js` sont de vrais appels in-app, jamais WhatsApp. |
| `ChangerMotDePasseScreen.js` | Aucune | fait (08/07/2026) | Lot 1. Reprend la mise en page de `MotDePasseOublieScreen.js` retouché, adaptée en version claire/sombre adaptative (`useTheme()`). |
| `ContributionsCarteScreen.js` | Aucune | fait (09/07/2026) | Lot 12. Sans maquette (D.2.2). |

## Client (14 écrans)

| Écran | Maquette Stitch | Statut | Lot |
|---|---|---|---|
| `client/AccueilScreen.js` | `accueil_caarco` | fait (08/07/2026) | Lot 2 |
| `client/TrajetScreen.js` | `planifier_un_trajet_caarco_1`, `_2` | fait (08/07/2026) | Lot 3 |
| `client/DetailsColisScreen.js` | `d_tails_du_colis_caarco_1`, `_2` | fait (08/07/2026) | Lot 3 |
| `client/ConfirmationScreen.js` | `confirmation_de_commande_caarco_1`, `_2`, `paiement_instructions_directes`, `d_tails_du_trajet` | fait (08/07/2026) | Lot 3 |
| `client/AttenteScreen.js` | `recherche_de_transporteur_caarco_1`, `_2` | fait (09/07/2026) | Lot 4 |
| `client/CourseAccepteeScreen.js` | `transporteur_trouv_caarco` | fait (09/07/2026) | Lot 4 |
| `client/SuiviScreen.js` | `suivi_en_temps_r_el*` (4 variantes) | fait (09/07/2026) | Lot 4 |
| `client/CourseDetailClientScreen.js` | `d_tail_de_la_course_caarco` | fait (09/07/2026) | Lot 5 |
| `client/HistoriqueScreen.js` | `mes_courses_caarco_1`, `_2` | fait (09/07/2026) | Lot 5 |
| `client/NotationScreen.js` | `noter_le_transporteur` | fait (09/07/2026) | Lot 5 |
| `client/ParrainageScreen.js` | `parrainage_caarco_1`, `_2` | fait (09/07/2026) | Lot 6 |
| `client/PointsScreen.js` | `mes_points_caarco_1`, `_2` | bloqué | Décision Cedric sur les tables `wallets` orphelines + récompense (C.2 #3). Lot bloqué (D.3.3), rattachement futur au voisinage des Lots 5-6. |
| `client/CoursePlanifieeDetailScreen.js` | Aucune | fait (09/07/2026) | Lot 6 |
| `client/MesCoursesPlanifieesScreen.js` | Aucune | fait (09/07/2026) | Lot 6 |

## Transporteur (16 écrans)

| Écran | Maquette Stitch | Statut | Lot |
|---|---|---|---|
| `transporteur/TableauBordScreen.js` | `tableau_de_bord_transporteur` | fait (09/07/2026) | Lot 7 |
| `transporteur/CourseScreen.js` | `d_tails_de_la_mission_1`, `_2` | fait (09/07/2026) | Lot 7 |
| `transporteur/NavigationScreen.js` | `navigation_livraison_1`, `_2` | fait (09/07/2026) | Lot 7 |
| `transporteur/AdDetailScreen.js` | `d_tails_de_l_annonce_1`, `_2` | fait (09/07/2026) | Lot 8 |
| `transporteur/RevenusScreen.js` | `mes_revenus_1`, `_2` | fait (09/07/2026) | Lot 8. Vigilance résiduelle wallets (C.2 #5) tenue — aucune lecture de `wallets` réintroduite. |
| `transporteur/MesTokensScreen.js` | `mes_tokens_de_course_caarco`, `mes_tokens_de_course`, `achat_de_tokens_tc` | fait (09/07/2026) | Lot 8. Code déjà propre confirmé — seuls 4 hex en dur corrigés. |
| `transporteur/PacksAbonnementScreen.js` | `packs_abonnement_transporteur` | bloqué | Décision Cedric sur la commission des paliers payants (C.2 #1) avant retouche. Lot bloqué (D.3.3), rattachement futur au voisinage du Lot 9. |
| `transporteur/LeaderboardScreen.js` | `classement_r_gional_caarco` | fait (09/07/2026) | Lot 9. "TransLogix"→CAARCO corrigé dans la maquette (2 occurrences : `<title>` + `<h1>` visible). |
| `transporteur/StatsTransporteurScreen.js` | `statistiques_performance`, `statistiques_performance_caarco` | fait (09/07/2026) | Lot 9. `CarteStat` local conservé (non remplacé par `Borne`, voir CDC D.13). `Silo` : 1er usage réel. |
| `transporteur/SoumissionKYCScreen.js` | `v_rification_kyc_transporteur_1` | fait (09/07/2026) | Lot 10 |
| `transporteur/StatutKYCScreen.js` | `v_rification_kyc_transporteur_2` | fait (09/07/2026) | Lot 10 |
| `transporteur/ProfilClientScreen.js` | `profil_client_caarco` | fait (09/07/2026) | Lot 11. Redondance avec `ProfilPublicScreen.js` clarifiée (pas de fusion, voir CDC D.15.2) — 2 bugs réels corrigés (compteur de courses client, voir D.15.3). |
| `transporteur/NotationClientScreen.js` | `noter_le_client_caarco` | fait (09/07/2026) | Lot 9. "TransLogix"→CAARCO corrigé dans la maquette (nouvelle découverte, non listée en C.2). |
| `transporteur/MessagesTransporteurScreen.js` | `messagerie_transporteur_caarco` | fait (09/07/2026) | Lot 11 |
| `transporteur/MesReservationsScreen.js` | Aucune | fait (09/07/2026) | Lot 11. Sans maquette — déjà conforme au DoD, non modifié. |
| `transporteur/CoursesTransporteurScreen.js` | Aucune | fait (09/07/2026) | Lot 11. Sans maquette, dérivé de `HistoriqueScreen.js` (client, Lot 5), confirmé — bug de crash (`ReferenceError`) corrigé, voir CDC D.15.3. |

## Admin (20 écrans)

| Écran | Maquette Stitch | Statut | Lot |
|---|---|---|---|
| `admin/DashboardScreen.js` | `tableau_de_bord_admin_caarco` | fait (09/07/2026) | Lot 13 |
| `admin/UtilisateursScreen.js` | `gestion_des_utilisateurs_admin` | fait (09/07/2026) | Lot 14 |
| `admin/CoursesEnCoursAdminScreen.js` | `op_rations_live_admin` | fait (09/07/2026) | Lot 13 |
| `admin/OperationsAdminScreen.js` | `op_rations_live_admin_caarco` | fait (09/07/2026) — déjà conforme, non modifié | Lot 13 |
| `admin/KYCValidationScreen.js` | `validation_kyc_admin`, `v_rification_kyc_admin` | fait (09/07/2026) | Lot 15 |
| `admin/LitigesScreen.js` | `gestion_des_litiges_admin` | fait (09/07/2026) | Lot 15 |
| `admin/FinancesAdminScreen.js` | `finances_tokens_tc_admin` | fait (09/07/2026) | Lot 16 |
| `admin/RetraitsAdminScreen.js` | Aucune (piège de nom vérifié, ne jamais utiliser `retrait_de_gains*`) | fait (09/07/2026) — déjà conforme, nettoyage import mort seulement | Lot 16. Voir D.2.5 pour la preuve — écran déjà conforme (soldes TC). |
| `admin/ConfigTarifsScreen.js` | `configuration_des_tarifs_admin` | fait (09/07/2026) | Lot 16 |
| `admin/LieuxAdminScreen.js` | `lieux_valider_admin` | fait (09/07/2026) | Lot 17. Bug réel corrigé (`onMenu` jamais reçu ni câblé — drawer mobile inatteignable depuis cet écran), pas seulement cosmétique. |
| `admin/MarketingAdminScreen.js` | `gestion_des_codes_promo`, `publicit_s_in_app_admin_caarco` | fait (09/07/2026) | Lot 17. 2e maquette structurellement sans rapport avec l'écran (voir CDC D.21) — contrôle visuel seulement, aucune section ajoutée. |
| `admin/PublicitesAdmin.js` | `publicit_s_in_app` | fait (09/07/2026) | Lot 17. Contrôle visuel confirmé conforme (C.2 #6), nettoyage DoD seulement (style mort, cible tactile). |
| `admin/CalendrierActionsScreen.js` | `calendrier_marketing_admin_1`, `_2` | fait (09/07/2026) | Lot 17. Maquette `_1` traduite EN→FR (`_2` déjà majoritairement française — découverte, voir CDC D.21). Cadran : 1er usage réel du chantier (nav mois). |
| `admin/NotificationsAdminScreen.js` | `templates_notifications_admin` | fait (09/07/2026) | Lot 18. Architecture déjà divergente de la maquette (liste + `PanneauDroit` modal, pas de panneau desktop permanent) — conforme au patron des autres écrans admin, non forcée vers la maquette. 2 hex catégories retokenisés, 3 styles morts supprimés, 2 cibles tactiles corrigées. |
| `admin/ClientsAdminScreen.js` | Aucune | fait (09/07/2026) | Lot 14. Déjà mature (PanneauDroit, KPIs) avant ce lot — Passoire greffé, pas de refonte de layout complète. |
| `admin/TransporteursAdminScreen.js` | Aucune | fait (09/07/2026) | Lot 14. Idem — Passoire + section Documents KYC ajoutée (gap réel vs maquette comblé par Pochette). |
| `admin/CampagnesPushScreen.js` | Aucune | fait (09/07/2026) — sans maquette, déjà mature | Lot 18. Segmentation sexe/ancienneté/ville/note déjà implémentée en entier. 2 styles morts supprimés, 1 hex actif retokenisé. |
| `admin/SecuriteAdminScreen.js` | Aucune | fait (09/07/2026) — sans maquette, déjà conforme, non modifié | Lot 18. 0 hex, 0 résidu wallet, `onMenu` déjà câblé correctement. |
| `admin/MFAChallengeScreen.js` | Aucune | fait (09/07/2026) — sans maquette, déjà conforme, non modifié | Lot 18. Rendu par `RootNavigator.js` avant `AdminShell.js` (étape aal2), hors sidebar — confirmé, pas un oubli. |
| `admin/AdminShell.js` | Aucune | fait (09/07/2026) — sans maquette | Lot 18. Shell de navigation, pas un écran de contenu. 1ʳᵉ retouche du fichier en 6 lots admin : 2 hex actifs retokenisés, 2 cibles tactiles corrigées. Décision explicite : pas de refactor vers `Corridor` (`SidebarContenu` est un sur-ensemble strict). |

---

## Écrans bloqués — récapitulatif (ne pas retoucher avant décision Cedric)

Détail complet (raison, référence, rattachement futur suggéré) en D.3.3 du CDC.

- `ProfilScreen.js` — champs `sexe`/`date_naissance` (C.3.1)
- `MerciScreen.js` / `PointsScreen.js` — récompense streak "+100 XAF" et tables `wallets` orphelines (C.2 #3)
- `PacksAbonnementScreen.js` — commission des paliers payants (C.2 #1)

## Lots D.3 — vue d'ensemble

Détail complet (composants Lot 0 mobilisés, justification) en D.3.2 du CDC. 59 écrans répartis sur 18 lots après le Lot 0 ; 5 écrans hors séquence (1 fait, 4 bloqués ci-dessus).

| Lot | Thème | Écrans | Statut |
|---|---|---|---|
| 1 | Auth & entrée | 5 | **fait (08/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.5 |
| 2 | Accueil | 1 | **fait (08/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.6 |
| 3 | Commande client : recherche & saisie | 3 | **fait (08/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.7 |
| 4 | Commande client : matching & suivi | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.8 |
| 5 | Post-course client | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.9 |
| 6 | Fidélité & réservations client | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.10 |
| 7 | Tableau de bord & mission transporteur | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.11 |
| 8 | Revenus & jetons transporteur | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.12 |
| 9 | Réputation & stats transporteur | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.13 |
| 10 | KYC transporteur | 2 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.14 |
| 11 | Profil, messagerie & annexes transporteur | 4 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.15 |
| 12 | Écrans partagés restants | 6 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.16 |
| 13 | Admin : tableau de bord & opérations | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.17 |
| 14 | Admin : utilisateurs | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.18 |
| 15 | Admin : KYC & litiges | 2 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.19 |
| 16 | Admin : finances & tarifs | 3 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.20 |
| 17 | Admin : marketing | 4 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.21 |
| 18 | Admin : notifications, sécurité & reste | 5 | **fait (09/07/2026)** — voir compte-rendu détaillé en bas de fichier et CDC D.22. **Dernier lot — chantier D clos.** |

## Corrections backend indépendantes (Partie C, hors refonte visuelle — ne pas laisser traîner)

- 🔴 Neutraliser le trigger `after_course_terminee` → `verifier_streak_client` (écrit encore dans `wallets`) — **toujours ouvert**, explicitement exclu de la migration 098 (voir ci-dessous) tant que `PointsScreen.js`/`MerciScreen.js` restent bloqués (C.2 #3).
- ✅ **RÉSOLU ET CONFIRMÉ EN PRODUCTION (09/07/2026)** — Contrôle de rôle sur `admin_crediter_wallet_client`. Trouvé au Lot 18 (CDC D.22.7) que la migration `098_audit_20260708_corrections_securite.sql` contenait déjà ce correctif mais que son application réelle n'était pas vérifiable depuis l'environnement d'agent. **Vérifié directement contre la base de production le 09/07/2026** (`supabase db query --linked`, lecture seule, projet lié `dxwkikaniawpfljvteog`, CAARCO ACTIVE_HEALTHY) : les 8 correctifs de la migration 098 sont **tous déjà en place en production** — `admin_crediter_wallet_client` a bien son `IF ... NOT is_admin() THEN RAISE EXCEPTION`, `liberer_sequestre_course` idem, policy `wallets_modification` supprimée, `courses.otp_expires_at` existe, `transactions_tc.deficit_tc` existe, `terminer_livraison` supprimée, `trg_verrouiller_prix_creation` existe, surcharge morte `calculer_prix(4 params)` supprimée. **Ce 🔴 est clos, confirmé sans avoir eu besoin d'exécuter quoi que ce soit** — la migration avait déjà été appliquée à la main (SQL Editor) avant ce lot, seule la table de suivi CLI (`supabase_migrations.schema_migrations`) ne le reflétait pas, d'où le faux signal "pending" de `supabase migration list`/`db push --dry-run`. **Ne jamais lancer `supabase db push` sur ce projet en l'état** : la CLI listerait ~104 migrations comme "à pousser" (002 à 100 + les migrations datées), alors qu'elles sont déjà toutes en place — un `db push` réel tenterait de les rejouer contre un schéma qui les a déjà, avec un risque réel d'erreurs ou de corruption (INSERT non idempotents, colonnes déjà existantes). Vérifié aussi : `users.permissions`, `is_super_admin()`, `has_permission()`, `admin_definir_permissions()` (migration 099), `reset_mot_de_passe_log` (migration 100), `campagnes_push`, `notchpay_ref`, `distance_reelle_km`, `transactions_wallet.description`/`course_id` (migrations datées 20260517/20260616/20260617) — **tous déjà en production**. **Exception** : `App/supabase/migrations/fix_terminer_livraison.sql` (nom hors convention, ignoré par la CLI) recrée l'ancienne version dangereuse de `terminer_livraison` (sans OTP) que la migration 098 a délibérément supprimée — fichier obsolète, **ne jamais l'exécuter**, à supprimer du dépôt (proposé à Cedric, pas fait automatiquement).
- 🟡 (trouvé Lot 16) `ConfigTarifsScreen.js` section "Commission parrainage" édite `configurations_systeme.commission_parrainage_pct`, lu **uniquement** par `liberer_sequestre_course()` (migrations 032/059/060) — RPC morte (même chaîne inatteignable que C.2 #3/C.3.2). L'admin peut « sauvegarder » ce taux sans aucun effet sur `debiter_commission_tc()` (flux TC actif). Décision Cedric requise : rebrancher ce taux sur le flux TC, ou retirer la section tant que le mécanisme n'est pas réactivé. Détail CDC D.20.
- 🟡 (trouvé Lot 16) `ConfigTarifsScreen.js` section "Charge utile" (Poids max/Volume max par véhicule) édite `parametres_tarifs.poids_max_kg`/`volume_max_m3` — colonnes absentes de toutes les migrations (`parametres_tarifs` ne les définit nulle part) — et `calculer_prix()` (dernière version active : migration 097) utilise de toute façon des seuils **codés en dur** par véhicule (CASE SQL), jamais lus depuis `parametres_tarifs`. Section 100% cosmétique aujourd'hui, une sauvegarde de ces 2 champs échouerait (colonne inexistante). Décision Cedric requise : migration pour créer les colonnes + brancher `calculer_prix()` dessus, ou retirer la section. Détail CDC D.20.
- 🟡 (trouvé Lot 18) Table `notification_templates` (éditée en direct par `NotificationsAdminScreen.js`) : 2 templates morts (`retrait_traite_tr`/`retrait_refuse_tr`, groupe `finance`) décrivent un retrait Mobile Money TR qui n'existe plus dans le modèle TC — aucun appelant trouvé dans `App/src`/`App/supabase/functions`. Le template `credit_wallet` (groupe `finance`) est lui réellement envoyé (`TransporteursAdminScreen.js:306`) ; son `corps` a déjà été assaini (migration 083, "wallet CAARCO"→"compte CAARCO") mais sa `description` visible dans l'éditeur admin dit encore "quand l'admin crédite le wallet d'un utilisateur" — texte fidèle au comportement réel de `admin_crediter_wallet_client` (non corrigé, voir point 🔴 ci-dessus), donc non modifié dans ce lot (visuel seulement, pas d'édition de contenu DB). Décision Cedric optionnelle : supprimer les 2 templates morts, actualiser la description de `credit_wallet`. Détail CDC D.22.7.

---

## Lot 1 — Auth & entrée (clôturé le 08/07/2026)

**5 écrans traités, tous marqués fait.** Détail complet en CDC D.5. Résumé :

| Écran | Traitement |
|---|---|
| `auth/ConnexionScreen.js` | Refondu sur `connexion_caarco` : suppression de l'étape de choix LOGIN/SIGNUP, formulaire direct (téléphone + mot de passe) sur une carte flottante avec en-tête de marque (CAARCO + `t('splash.tagline')`), lien "Oublié ?" inline à côté du label mot de passe, CTA primaire via `Galet` (variante `primaire`) + CTA secondaire "Créer un compte" (variante `fantome`), rangée décorative de confiance. **Bug de contraste corrigé au passage** : les boutons du fichier précédent utilisaient fond Néré + texte blanc (~2.7:1, échec AA déjà documenté CDC §0.2) — remplacés par les variantes `Galet` conformes (foret/blanc, fantome/foret). |
| `auth/InscriptionScreen.js` | Refondu sur `cr_er_un_compte_caarco` : suppression du fond photo + carte flottante (la maquette est un formulaire plein-écran sur fond manioc uni), nouvel en-tête retour + marque centrée, champs et puces Genre inchangés fonctionnellement. Aucun champ retiré, aucune logique de validation modifiée. |
| `auth/MotDePasseOublieScreen.js` | Refondu sur `mot_de_passe_oubli_caarco` (seule maquette à thème sombre forcé parmi les 3) : fond nuit, avatar circulaire icône clé + badge, carte translucide (`alpha(colors.foret, 0.35)`, pas de blur — aucune dépendance ajoutée), étape 2 (révélation du mot de passe temporaire) alignée sur la même identité visuelle sombre. Copie exacte conservée (pas de reprise du texte de la maquette qui suggère à tort l'envoi d'un code externe — le flux réel affiche le mot de passe directement, sans SMS). Lien "Contacter l'assistance" de la maquette **volontairement omis** : aucun écran d'assistance n'existe encore dans l'app (hors périmètre), un lien mort aurait été pire qu'une omission. |
| `ChangerMotDePasseScreen.js` | Aucune maquette dédiée — reprend la mise en page de `MotDePasseOublieScreen.js` (avatar + badge, carte, CTA) mais en version **adaptative claire/sombre** via `useTheme()` plutôt qu'en thème sombre forcé : écran atteint depuis le profil (post-connexion), donc à l'intérieur du contexte thème habituel de l'app, contrairement aux 3 écrans pré-connexion qui gardent une identité de marque fixe. |
| `OnboardingScreen.js` | Revu, **non modifié**. Aucune maquette Stitch. Contenu déjà conforme au DoD (i18n complet, zéro hex en dur — utilise `useTheme()`, cible tactile 52px, copie des 3 slides déjà alignée sur le positionnement produit réel, y compris "Vous payez, personne ne garde votre argent"). Retoucher sans maquette de référence et sans défaut identifié aurait été un risque de régression sans bénéfice. |

**Composants** : aucun nouveau composant créé (conforme à la consigne — Sillon/Galet suffisaient). Une seule extension mineure envisagée puis écartée : ajouter un prop à `Sillon` pour un accessoire de label inline (le lien "Oublié ?") — finalement fait sans toucher au composant partagé (label géré manuellement dans l'écran appelant), pour ne pas élargir le rayon d'impact à ~30 autres écrans qui utilisent `Sillon`.

**i18n** : 1 nouvelle clé ajoutée en miroir strict — `auth.connexion.mdpOublieCourt` ("Oublié ?" / "Forgot?"). Parité vérifiée programmatiquement après ajout : **1381 clés de chaque côté, 0 écart**. Les clés `auth.connexion.choixLogin`/`choixSignup` deviennent orphelines (l'étape de choix a disparu) — conservées telles quelles, non supprimées (hors périmètre, inoffensif).

**DoD vérifié sur les 4 fichiers modifiés** (`ConnexionScreen.js`, `InscriptionScreen.js`, `MotDePasseOublieScreen.js`, `ChangerMotDePasseScreen.js`) :
- Zéro hex/rgba en dur : confirmé par grep (y compris le dégradé `LinearGradient` de `ConnexionScreen.js`, qui utilisait deux valeurs hex héritées du fichier d'origine — retokenisé via `alpha(colors.nuit, …)`).
- i18n complet : confirmé, parité fr/en 1381/1381.
- Contraste WCAG AA : le seul écart connu (Néré + blanc) a été corrigé en passant par les variantes `Galet` déjà validées AA ; le reste réutilise des combinaisons de tokens déjà en usage ailleurs dans l'app.
- Aucune résurgence wallet/séquestre : aucun des 5 écrans ne touche à un solde, une TC, un wallet — non applicable à ce lot (écrans d'authentification pure).
- Validation syntaxique : Babel (`babel-preset-expo`) sur les 4 fichiers + `fr.js`/`en.js` — OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que le Lot 0 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone branché.

**Périmètre respecté** : aucun écran des Lots 2-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Seuls fichiers modifiés : les 4 écrans ci-dessus + `src/i18n/fr.js`/`en.js` (1 clé) + ce fichier + le CDC (section D.5).

**Prochain lot recommandé : Lot 2 — Accueil** (`AccueilScreen.js`, écran le plus visible de l'app, checkpoint explicite "1 CTA principal" du Master Prompt — mobilise Etal/Echo/Fronton du Lot 0, jamais encore exercés en conditions réelles). Alternative : **Lot 3 — Commande client : recherche & saisie**, si Cedric préfère enchaîner directement sur le tunnel de commande plutôt que sur l'écran d'accueil.

---

## Lot 2 — Accueil (clôturé le 08/07/2026)

**1 écran traité, marqué fait.** Détail complet en CDC D.6. Résumé :

| Écran | Traitement |
|---|---|
| `client/AccueilScreen.js` | Contrôle visuel rapide de la maquette `accueil_caarco` (déjà ✅ en C.1) : structure simple (recherche adresse + bottom sheet catégories véhicule + 1 bouton "Confirmer"), utilisée comme référence de principe plutôt que redessin complet (l'écran réel est bien plus riche : stories, pub, récompense, carte GPS, carrousel services, rappels de course, parrainage — conservés tels quels). **Fusion du CTA dupliqué** : le bouton "Continuer →" (`accueil.continuer`) de la carte de réservation et le bouton flottant "Commander maintenant" (`accueil.commanderMaintenant`) plus bas dans l'écran pointaient tous les deux vers `Trajet` sans distinction. Fusionnés en un seul CTA "Commander" (réutilise la clé existante et jusque-là orpheline `accueil.commander`) positionné directement dans la carte de réservation, immédiatement visible sans scroll — le bouton flottant du bas est supprimé. **Etal exercé pour la première fois en conditions réelles** : la sélection de catégorie de véhicule (`categoriesVehicule()`) était déjà codée dans l'écran mais **jamais rendue** (code mort — aucun JSX ne consommait `CATEGORIES_VEHICULE`, confirmé par grep) ; le texte du tutoriel intégré (`accueil.tutoriel.t1desc` : "Appuyez sur 'Commander' ou choisissez une catégorie de véhicule…") anticipait déjà ce comportement manquant. Reliée via `Etal` (sélection exclusive, état local, défaut "Moto") directement sous le bloc adresses, le CTA "Commander" utilisant la catégorie choisie. **Echo exercé** sur la bannière de rappel "course en cours" : le point statique est remplacé par l'anneau radar `Echo` uniquement quand `statut === 'en_attente'` (recherche transporteur en cours), et reste un point statique pour `acceptee`/`en_cours` (transporteur déjà affecté) — usage fidèle à la sémantique "indicateur de recherche/attente, sans valeur chiffrée". **Fronton exercé** sur l'en-tête de la section "Nos Services" (titre + "Voir les tarifs →"), remplaçant le JSX manuel équivalent — la section "Transporteurs disponibles" n'a pas reçu Fronton (pas d'action "voir tout" sur cette section, usage non forcé). **Bannière récompense** (`recompense`/`accueil.surpriseTitre`/`surpriseSous`, lien vers le mécanisme bloqué C.2 #3) : non touchée, ni layout ni texte ni logique. **Nettoyage DoD en passant** : 6 couleurs hex codées en dur trouvées dans le fichier (dont un fallback mort `colors.foret10 ?? '#e8f0ea'` — le token existe bel et bien dans `theme.js`, le fallback ne s'exécutait jamais) — retokenisées via `alpha()` ou les tokens `theme.js` déjà en usage dans le fichier. Styles devenus inutilisés après la fusion (`categorieGrille/Carte/IconeBloc/Nom/Sous/Tarif`, `voirToutLien`, `btnCommanderPrincipal*`, `btnCommanderFleche`) supprimés ; import `BoutonAnime` retiré (plus consommé). |

**Composants** : `Etal`, `Echo`, `Fronton` du Lot 0, tous les trois exercés pour la première fois sur un écran de production — aucun nouveau composant créé, aucune extension d'API nécessaire sur les trois.

**i18n** : **0 nouvelle clé**. Toutes les chaînes nécessaires existaient déjà (certaines orphelines avant ce lot : `accueil.commander`, jamais consommée jusqu'ici). Parité vérifiée programmatiquement avant et après modification (flatten + comparaison des deux objets exportés) : **1383 clés de chaque côté, 0 écart**, inchangé par cette passe. Clé `accueil.commanderMaintenant` devenue orpheline par la fusion du CTA (conservée telle quelle, non supprimée — même traitement que les clés orphelines du Lot 1).

**DoD vérifié sur le fichier modifié** (`AccueilScreen.js`) :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) — 6 occurrences pré-existantes retokenisées (`alpha(colors.nuit, …)`, `alpha(colors.blanc, …)`, `alpha(colors.nere, …)`, `colors.brume`, et suppression d'un fallback hex mort jamais exécuté).
- i18n complet : confirmé, parité fr/en 1383/1383, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs introduite — `Etal`/`Fronton` réutilisent leurs styles internes déjà validés AA au Lot 0 (D.4.5) ; les hex retokenisés reproduisent des valeurs d'opacité identiques ou visuellement équivalentes aux originales.
- Aucune résurgence wallet/séquestre : confirmé par grep (0 résultat) ; bannière récompense non touchée (mécanisme bloqué C.2 #3 hors périmètre).
- Validation syntaxique : Babel (`babel-preset-expo`) sur `AccueilScreen.js` — OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-1 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone branché.

**Écarts avec l'implémentation existante, documentés (pas des oublis)** :
1. Le bouton CTA du bas ("Commander maintenant", avec l'animation `BoutonAnime`) est supprimé plutôt que conservé — l'écran perd cette micro-animation de pression, au profit d'un unique CTA cohérent avec la règle "1 action principale". Compromis assumé, pas un défaut.
2. `Etal` utilisé en mode horizontal (scroll) plutôt qu'en grille 2 colonnes comme dans la maquette — choix délibéré pour ne pas ajouter de hauteur à un écran déjà signalé comme surchargé (vigilance explicite de ce lot), cohérent avec le carrousel "Nos Services" juste en dessous.
3. `Fronton` utilise la palette statique (`colors.charbon`), pas la palette adaptative (`tc.charbon` via `useTheme()`) que ce titre de section utilisait auparavant — conforme à la convention Lot 0 (32/33 composants transverses en palette statique, D.4.1), mais régression mineure et non bloquante en mode sombre pour ce seul en-tête (le reste de l'écran reste largement adaptatif).

**Périmètre respecté** : aucun écran des Lots 1, 3-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Seul fichier écran modifié : `AccueilScreen.js`. Aucune clé i18n ajoutée (donc `fr.js`/`en.js` non modifiés). Fichiers annexes modifiés : ce fichier + le CDC (section D.6).

**Prochain lot recommandé : Lot 3 — Commande client : recherche & saisie** (`TrajetScreen.js`, `DetailsColisScreen.js`, `ConfirmationScreen.js` — mobilise Sentier, Etal (véhicule + mode paiement), Pochette (photos colis). Point de vigilance déjà noté en D.3.2 : `ConfirmationScreen` porte le mode paiement direct informatif — ne rien faire glisser vers un bouton de transaction).

---

## Lot 3 — Commande client : recherche & saisie (clôturé le 08/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.7. Résumé :

| Écran | Traitement |
|---|---|
| `client/TrajetScreen.js` | Sélecteur de véhicule manuel (4 boutons `flex:1` en rangée fixe, `MaterialCommunityIcons`) remplacé par `Etal` (scroll horizontal, `Ionicons`, mêmes icônes que les catégories équivalentes d'`AccueilScreen` au Lot 2, pour la cohérence visuelle inter-écrans). Aucun changement de comportement (mêmes handlers `setTypeVehicule`/`setCategorieVehicule`). Nettoyage DoD : 2 hex en dur retokenisés (`'#e8e0d5'` → `colors.brume`, `'rgba(15,20,17,0.5)'` → `alpha(colors.nuit, 0.5)`). Styles et import `MaterialCommunityIcons` devenus inutiles supprimés. |
| `client/DetailsColisScreen.js` | Section "Photos du colis" : la grille de vignettes déjà ajoutées est passée par `Pochette` (apporte le zoom plein écran au tap, absent avant ce lot), tout en conservant à l'identique les deux boutons distincts "Caméra"/"Galerie" (Pochette ne gère qu'un seul bouton d'ajout générique — forcer ce modèle aurait fait perdre le choix caméra/galerie). Nettoyage : 2 fallbacks `?? valeur-identique` tautologiques retirés (`colors.lateriteSoft`, `fontSize.xxs`), styles de vignette devenus inutiles supprimés. |
| `client/ConfirmationScreen.js` | **Vigilance appliquée** : la maquette `paiement_instructions_directes` a été écartée du visuel repris — voir découverte ci-dessous. Bloc "Trajet" (départ/arrivée) reconstruit avec `Sentier` (icônes par défaut du composant : anneau foret pour l'origine, pastille laterite pour la destination — fidèle à la maquette `confirmation_de_commande_caarco_1`, qui utilise déjà ces couleurs). Bloc "Mode de paiement" (mobile money / espèces) reconstruit avec `Etal` en mode grille (`horizontal={false}`) plutôt qu'en 2 boutons `flex:1` pleine largeur. Logique de paiement direct (`mode_paiement_client`, commentaire "wallet supprimé" ligne 18, CTA "Confirmer la commande") **non touchée**. |

**Découvertes sur les maquettes** (contrôle visuel avant reprise, C.1/C.4) :
1. **`planifier_un_trajet_caarco_2`** et **`confirmation_de_commande_caarco_2`** portent encore la marque **"TransLogix"** dans leur `<title>` — même défaut cosmétique déjà repéré ailleurs (C.2 #1/#2/#4), non signalé jusqu'ici pour ces deux dossiers précis. Correction cosmétique à faire uniquement si ces maquettes sont un jour rouvertes comme référence visuelle — non bloquant, aucun impact code.
2. **Plus important : `paiement_instructions_directes`** ne se limite pas à un mode de paiement informatif comme le confirmait C.2 #4 pour le *code* — la maquette elle-même contient une **UI de transaction complète** : champ de saisie de numéro de téléphone Orange Money, CTA "Confirmer le paiement" avec icône cadenas et texte "Transaction sécurisée". Reproduire ce visuel aurait réintroduit l'apparence d'un paiement encaissé par l'app, contraire à la règle serveur (§6, mode_paiement_client informatif uniquement). **Non repris** : seule la logique déjà conforme de `ConfirmationScreen.js` (sélection du mode, aucune saisie de numéro, aucun bouton de transaction) a été conservée. À noter pour toute future session : cette maquette ne doit servir que de preuve de la structure "carte de paiement direct au chauffeur", jamais de référence pour son CTA ou son champ téléphone.

**Composants** : `Sentier`, `Etal`, `Pochette` du Lot 0, tous mobilisés sur un besoin réel vérifié dans le code existant (sélecteurs à choix exclusif déjà présents manuellement, ou fonctionnalité manquante — zoom photo). Aucun nouveau composant créé.

**i18n** : **0 nouvelle clé**. Parité vérifiée programmatiquement avant et après modification : **1383 clés de chaque côté, 0 écart**, inchangé par cette passe. Clés `confirmation.departLabel`/`confirmation.arriveeLabel` devenues orphelines par le passage à `Sentier` (conservées, non supprimées — même traitement que les autres orphelines des lots précédents).

**DoD vérifié sur les 3 fichiers modifiés** :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) sur les 3 fichiers.
- i18n complet : confirmé, parité fr/en 1383/1383, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs introduite — `Etal`/`Sentier`/`Pochette` réutilisent leurs styles internes déjà validés AA au Lot 0.
- Aucune résurgence wallet/séquestre : confirmé par grep (0 résultat, hors le commentaire de suppression déjà présent) ; vigilance paiement direct spécifiquement vérifiée (voir découverte ci-dessus).
- Validation syntaxique : Babel (`babel-preset-expo`) sur les 3 fichiers — OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-2 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone branché.

**Périmètre respecté** : aucun écran des Lots 1-2, 4-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Seuls fichiers écran modifiés : les 3 ci-dessus. Aucune clé i18n ajoutée. Fichiers annexes modifiés : ce fichier + le CDC (section D.7).

**Prochain lot recommandé : Lot 4 — Commande client : matching & suivi** (`AttenteScreen.js`, `CourseAccepteeScreen.js`, `SuiviScreen.js` — mobilise Echo (radar recherche, déjà rodé au Lot 2), Sentier (déjà rodé à ce Lot 3), Jalons.js/« Jauge » pour l'ETA (D.4.2 : ne pas chercher de composant « Jauge » séparé, `Jalons.js` fait déjà ce rôle)). Deuxième moitié du tunnel de commande, enchaînée directement après ce lot pour rester dans le même contexte de service (`courses.js`, Supabase Realtime).

---

## Lot 4 — Commande client : matching & suivi (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.8. Résumé :

| Écran | Traitement |
|---|---|
| `client/AttenteScreen.js` | Le radar orbital déjà codé (anneaux concentriques statiques + anneaux pulsés + véhicules en orbite + icône colis au centre) est **conservé tel quel** — `Echo` n'a pas été utilisé ici (voir découverte ci-dessous). Bloc "Résumé trajet" (départ/arrivée, dots + trait construits à la main) reconstruit avec `Sentier`, comme au Lot 3 sur `ConfirmationScreen.js`. **CTA dupliqué corrigé** : à l'état timeout (3 min sans transporteur), un second bouton ("← Retour à l'accueil", fonction `reessayer()`) faisait exactement la même action que le bouton persistant du pied de page ("Annuler la demande") — les deux annulaient la course et revenaient à l'Accueil. Supprimé avec sa fonction, ne laissant qu'un seul CTA visible dans cet état, conforme à la règle "1 action principale par écran". |
| `client/CourseAccepteeScreen.js` | Bloc "Résumé trajet" (même motif dots + trait manuel) reconstruit avec `Sentier`, identique au traitement d'`AttenteScreen.js`. Nettoyage DoD : 2 hex en dur (`'#b2d8b2'`, bordures du bandeau succès) retokenisés en `alpha(colors.bambou, 0.3)`. |
| `client/SuiviScreen.js` | **Ajout réel** : une barre de progression continue (`Jalons`) est insérée sous le sous-titre ETA de l'en-tête, alimentée par un pourcentage calculé côté écran (distance initiale capturée à l'entrée de chaque phase collecte/livraison, puis `1 - distanceRestante/distanceInitiale`) — élément présent dans la maquette `suivi_en_temps_r_el_client` (barre à 85%, littéralement commentée `<!-- Jalons (Progress Bar) -->` dans le HTML Stitch) mais absent du code réel jusqu'ici (seul un stepper à 3 points discrets existait, conservé tel quel — sémantique différente, non concerné par ce lot). Nettoyage DoD : 2 hex en dur retokenisés (`'#e8d0a0'` → `alpha(colors.nere, 0.35)`, `'#0f1411b8'` → `alpha(colors.nuit, 0.72)`, cette dernière valeur strictement identique à l'original). |

**Découverte — Echo non utilisé sur `AttenteScreen.js`, décision documentée** : le radar déjà présent dans le code est strictement plus riche que ce qu'apporterait `Echo` (qui ne rend que des anneaux pulsés + un point plein, sans anneaux statiques ni véhicules orbitaux ni icône centrale personnalisée). Remplacer aurait supprimé des éléments visuels distinctifs sans aucun gain, ou obligé à superposer `Echo` sous les autres calques pour ne garder que son animation d'anneaux — au prix d'un point central `Echo` caché inutilement derrière le cercle blanc existant, sans bénéfice réel. Conforme à la consigne de la session ("utiliser ces composants seulement s'ils correspondent à un besoin réel, vérifier le code existant avant de forcer un composant") : `Echo` a été jugé non pertinent ici et n'a donc pas été utilisé sur les 3 écrans de ce lot.

**Découverte maquettes — deux nouvelles occurrences de la marque "TransLogix"** : `recherche_de_transporteur_caarco_1` (`<title>`) et `suivi_en_temps_r_el_caarco_1` (`<title>`) portent encore "TransLogix", même défaut cosmétique déjà documenté pour 6 autres dossiers (C.2, D.7.2) — aucune action sur le code (jamais porté cette marque), correction cosmétique de la maquette seulement si un jour reprise comme référence.

**CTA dupliqué relevé mais non corrigé, `CourseAccepteeScreen.js`** : la liste d'actions ("Que faire ?") contient une ligne "Suivre en direct" et le bouton principal en bas de l'écran ("Suivre la livraison en direct") appellent tous deux `allerSuivi()`. Contrairement au cas d'`AttenteScreen.js` (2 boutons strictement redondants dans le même état), ici la liste "Que faire ?" est un menu à 4 options réelles et distinctes (appeler, chat, suivre, annuler) et le bouton du bas agit comme un rappel du CTA principal en fin d'écran — plus proche d'un menu + CTA de sortie que d'une vraie duplication accidentelle. Laissé tel quel, non corrigé (écart jugé insuffisamment évident pour justifier un changement de comportement hors périmètre de ce lot).

**Composants** : `Sentier` (2 usages, mêmes conditions que Lot 3 : sélecteurs de trajet déjà construits à la main), `Jalons` (1 usage réel, nouveau — comble un manque confirmé par la maquette). `Echo` non utilisé (voir ci-dessus, décision documentée plutôt qu'un usage forcé).

**i18n** : **0 nouvelle clé**. Parité vérifiée programmatiquement avant et après modification : **1383 clés de chaque côté, 0 écart**. Clé `attente.retourAccueil` devenue orpheline par la suppression du bouton dupliqué (conservée, non supprimée — même traitement que les orphelines des lots précédents). Clés déjà orphelines avant ce lot, non touchées : `attente.trouve`, `attente.dispos`, `attente.voirProfil`, `attente.choisir` (vestiges d'un flux de sélection manuelle de transporteur jamais implémenté tel quel, la sélection étant automatique dans le code réel).

**DoD vérifié sur les 3 fichiers modifiés** :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) sur les 3 fichiers — 4 hex préexistants retokenisés (2 dans `CourseAccepteeScreen.js`, 2 dans `SuiviScreen.js`).
- i18n complet : confirmé, parité fr/en 1383/1383, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs introduite — `Sentier`/`Jalons` réutilisent leurs styles internes déjà validés AA au Lot 0 ; les retokenisations reproduisent des valeurs identiques (`alpha(colors.nuit, 0.72)` = `'#0f1411b8'` à l'octet près) ou visuellement équivalentes aux hex d'origine.
- Aucune résurgence wallet/séquestre : confirmé par grep (0 résultat) sur les 3 fichiers ; mode de paiement non mentionné dans ce lot (hors sujet des 3 écrans, la sélection du mode se fait en amont à `ConfirmationScreen.js`).
- Validation syntaxique : **méthode adaptée** — `npx babel --presets babel-preset-expo` échoue dans cet environnement même sur un fichier déjà validé et non modifié du Lot 3 (`ConfirmationScreen.js`), erreur reproductible sur du optional chaining pourtant déjà en production — panne d'outillage, pas une régression de ce lot. Validation faite via `@babel/parser` directement (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : OK. À signaler à Cedric si la commande Babel standard doit être réparée avant les prochains lots.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-3 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

**Périmètre respecté** : aucun écran des Lots 1-3, 5-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Seuls fichiers écran modifiés : les 3 ci-dessus. Aucune clé i18n ajoutée. Fichiers annexes modifiés : ce fichier + le CDC (section D.8).

**Prochain lot recommandé : Lot 5 — Post-course client** (`CourseDetailClientScreen.js`, `NotationScreen.js`, `HistoriqueScreen.js` — mobilise Étoiles (jamais encore exercé en conditions réelles) et Echelon (existant)). Écrans de clôture/consultation, risque faible.

---

## Lot 5 — Post-course client (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.9. Résumé :

| Écran | Traitement |
|---|---|
| `client/CourseDetailClientScreen.js` | La fonction `Etoiles({ note })` codée en local (lecture seule, note du transporteur) est **strictement identique** en comportement à `Etoiles.js` du Lot 0 (mêmes règles plein/demi/vide, même couleur unique néré) — remplacée par le composant partagé (`valeur`, `taille={14}`), premier usage réel du composant. Nettoyage DoD : 2 hex en dur retokenisés (`'#0f141173'` → `alpha(colors.nuit, 0.45)`, identique à l'octet près ; `'#e8d0a0'` → `alpha(colors.nere, 0.35)`, même substitution qu'au Lot 4 pour le même hex). Style `etoilesRangee` devenu mort supprimé. |
| `client/NotationScreen.js` | Deux fonctions locales dupliquées, `Etoiles` (note globale, 36px) et `EtoilesMini` (4 critères, 22px), toutes deux interactives — remplacées par le composant partagé `Etoiles.js` avec `taille` distincte par appel et `style={{ gap: spacing.souffle }}` pour préserver l'espacement d'origine (le composant partagé utilise un gap de 2px par défaut, pensé pour un contexte compact comme `CourseDetailClientScreen`). **Écart de comportement trouvé et corrigé dans le composant partagé lui-même** : la branche interactive de `Etoiles.js` (Lot 0) colorait les étoiles vides avec la même couleur pleine (néré) que les étoiles sélectionnées — perte de la distinction visuelle sélectionné/non-sélectionné qu'avait l'implémentation locale d'origine (`colors.brume` pour les vides). Corrigé en ajoutant un prop `couleurVide` (défaut `colors.brume`) à `Etoiles.js`, sans risque de régression : aucun autre écran ne consommait ce composant avant ce lot (seul appelant préexistant : l'écran-catalogue dev-only, lui aussi corrigé gratuitement par le fix). Style `etoilesRangee` devenu mort supprimé. |
| `client/HistoriqueScreen.js` | **Résidu wallet trouvé et corrigé** (voir découverte ci-dessous) : la vignette de mode de paiement lisait `course.methode_paiement` (colonne DB héritée de l'ancien modèle séquestre, valeurs `online`/`wallet`/`especes`, migration 039) et pouvait afficher une icône + un libellé **"Wallet"** au client — au lieu du champ actuellement correct `mode_paiement_client` (`especes`/`mobile_money`, écrit par `ConfirmationScreen.js`). Corrigé : `labelsPaiement()` et le rendu de la vignette lisent désormais `course.mode_paiement_client` ; la requête `SELECT_CLIENT_LISTE` (`services/courses.js`, utilisée exclusivement par cet écran — vérifié par recherche exhaustive, aucun autre appelant) sélectionne `mode_paiement_client` à la place de `methode_paiement`. Aucun autre écran affecté (Lots 4/7/8/13 lisent `methode_paiement` via d'autres requêtes, non touchées, hors périmètre de ce lot). |

**Découverte — résidu wallet actif dans `HistoriqueScreen.js`, pas seulement cosmétique** : conformément à la vigilance C.4.4 ("classer par capacité, pas par nom" — vérifier aussi le backend, pas seulement le visuel des maquettes), une recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` sur les 3 écrans du lot a trouvé une résurgence réelle, indépendante de toute maquette : `HistoriqueScreen.js` pouvait afficher le badge de paiement "Wallet" (icône `wallet-outline` + libellé `t('historique.paiementWallet')`) si `course.methode_paiement === 'wallet'` — une valeur du CHECK constraint hérité de la migration `039_methode_paiement_especes.sql` (`online`/`wallet`/`especes`), distincte du champ `mode_paiement_client` (`especes`/`mobile_money`) réellement écrit par le tunnel de commande actuel (`ConfirmationScreen.js`, Lot 3). Aucune des 4 maquettes contrôlées ne suggérait ce défaut — trouvé par la recherche de mots-clés sur le code réel, pas par le tri visuel. Corrigé dans le périmètre strict de ce lot (voir tableau ci-dessus) ; la clé i18n `historique.paiementWallet` devient orpheline (conservée, non supprimée, même traitement que les orphelines des lots précédents) ; les clés `confirmation.mobileMoney`/`confirmation.especes` sont réutilisées à la place. Point de vigilance résiduel, hors périmètre de ce lot : la colonne `courses.methode_paiement` elle-même (et sa valeur `online`) reste lue par `TableauBordScreen.js` (Lot 7), `RevenusScreen.js` (Lot 8), `CoursesEnCoursAdminScreen.js` (Lot 13) et `SuiviScreen.js` (Lot 4, déjà clos, non retouché ici) — à vérifier à l'ouverture de ces lots respectifs, avec la même méthode.

**Découverte maquette — bottom nav de `mes_courses_caarco_2` contient un onglet "Wallet"** : le bas de la maquette (`code.html` lignes 241-242, confirmé par contrôle visuel de `screen.png`) porte une barre de navigation à 4 onglets Home/Orders/Wallet/Profile, avec icône `account_balance_wallet` + libellé "Wallet". Non repris (l'app utilise sa propre navigation bas de page avec ses propres onglets réels, jamais cette barre-là) — mentionné ici uniquement au titre de la vigilance C.4.4, aucune action de code nécessaire. `mes_courses_caarco_1` confirme le résidu de marque "TransLogix" déjà noté en D.2.3 (rien de nouveau).

**Echelon évalué, non utilisé** : aucun des 3 écrans ne présente de besoin réel de stepper à états nommés (fait/actif/à venir). `CourseDetailClientScreen.js` affiche un statut résolu unique via `Cachet` (tampon, déjà en place) ; aucune des 4 maquettes ne montre de stepper de progression (la maquette `d_tail_de_la_course_caarco` n'affiche qu'un badge "TERMINÉE", pas de barre d'étapes). Même discipline qu'au Lot 4 avec `Echo` (D.8.3) : composant assigné par D.3.2, évalué, jugé non pertinent après vérification du besoin réel plutôt qu'utilisé par défaut.

**Écart avec la maquette, documenté** : `d_tail_de_la_course_caarco` affiche un bloc "Détail du paiement" (tarif de base, distance, frais de service, total) — non repris. Le modèle de données réel ne stocke que le prix final (`course.prix_fcfa`), aucune des composantes du calcul n'est persistée par course ; le calcul de prix est une règle serveur non recalculable côté client sans risque d'afficher un chiffre erroné (règle non négociable, CLAUDE.md §12). Reproduire ce bloc aurait nécessité soit d'inventer des chiffres, soit de dupliquer côté client la formule de tarification — les deux étant hors périmètre et risqués. Le prix total seul (déjà affiché) reste la seule donnée fiable.

**Composants** : `Etoiles` (Lot 0) exercé pour la première fois en conditions réelles, sur 2 écrans (lecture seule + interactif) — un écart de comportement du composant partagé lui-même a été trouvé et corrigé sans risque de régression (voir ci-dessus). `Echelon` évalué, non utilisé (voir ci-dessus).

**i18n** : **0 nouvelle clé**. Parité vérifiée programmatiquement avant et après modification : **1383 clés de chaque côté, 0 écart**, inchangé par cette passe. Clé `historique.paiementWallet` devenue orpheline par la correction du résidu wallet (conservée, non supprimée — même traitement que les orphelines des lots précédents).

**DoD vérifié sur les 4 fichiers modifiés** (`CourseDetailClientScreen.js`, `NotationScreen.js`, `HistoriqueScreen.js`, `Etoiles.js`, plus `services/courses.js`) :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) — 2 hex préexistants retokenisés dans `CourseDetailClientScreen.js`. Le motif `colors.x + 'hex'` (suffixe alpha en chaîne, ex. `colors.laterite + '60'`) n'est pas retokenisé, conforme à la convention déjà en usage dans les écrans clos (`ConfirmationScreen.js`, `TrajetScreen.js`, `ParrainageScreen.js`) — un token de couleur avec suffixe n'est pas un hex en dur au sens de ce DoD.
- i18n complet : confirmé, parité fr/en 1383/1383, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs introduite — la restauration de `colors.brume` pour les étoiles non sélectionnées dans `Etoiles.js` reproduit exactement le contraste de l'implémentation locale d'origine de `NotationScreen.js` ; les 2 retokenisations reproduisent des valeurs identiques (`alpha(colors.nuit, 0.45)` = `'#0f141173'` à l'octet près) ou déjà validées par précédent (Lot 4, même hex `'#e8d0a0'` → `alpha(colors.nere, 0.35)`).
- **Aucune résurgence wallet/séquestre : un résidu réel trouvé et corrigé** (badge "Wallet" dans `HistoriqueScreen.js`, voir découverte ci-dessus) — confirmé par grep après correction (0 résultat) sur les 3 écrans.
- Validation syntaxique : `npx babel --presets babel-preset-expo` échoue de nouveau dans cet environnement (même panne d'outillage que le Lot 4, D.8.7, reproduite ici sur du optional chaining non modifié) — contournée via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers modifiés : OK. Panne toujours non réparée, signalée une nouvelle fois à Cedric.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-4 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

**Périmètre respecté** : aucun écran des Lots 1-4, 6-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 3 écrans ci-dessus + `App/src/components/Etoiles.js` (extension additive, un seul prop optionnel ajouté) + `App/src/services/courses.js` (1 champ substitué dans une requête à appelant unique). Aucune clé i18n ajoutée. Fichiers annexes modifiés : ce fichier + le CDC (section D.9).

**Prochain lot recommandé : Lot 6 — Fidélité & réservations client** (`ParrainageScreen.js`, `CoursePlanifieeDetailScreen.js`, `MesCoursesPlanifieesScreen.js` — mobilise Borne (gains cumulés) et Echelon (toujours pas exercé — à réévaluer, pas à forcer). 2 des 3 écrans sont sans maquette Stitch, à concevoir sans référence ; vigilance supplémentaire trouvée ce lot-ci : la maquette `mes_courses_caarco_2` (onglet "À venir (0)") peut servir de piste indicative pour `MesCoursesPlanifieesScreen`, sans être une maquette dédiée triée).

---

## Lot 6 — Fidélité & réservations client (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.10. Résumé :

| Écran | Traitement |
|---|---|
| `client/ParrainageScreen.js` | Contrôle visuel rapide des maquettes `parrainage_caarco_1`/`_2` (déjà ✅ en C.1, pas de nouveau tri). Le bloc "gains" (`total_commissions`) est reconstruit en grille de 2 `Borne` (Lot 0, premier usage réel : "Gains de parrainage" en FCFA + "Amis parrainés" en effectif) — conforme à la preuve D.3.1 qui cite littéralement ce bloc comme origine de Borne. **Résidu wallet cosmétique trouvé et corrigé** : le libellé visible au client était `t('parrainageEcran.gainsTitre')` = **"Gains wallet"** (`en.js` : "Wallet earnings") et l'icône associée `wallet-outline` — renommé "Gains de parrainage" / "Referral earnings", icône `cash-outline`. **Découverte plus importante, non corrigée dans ce lot** : voir ci-dessous. |
| `client/CoursePlanifieeDetailScreen.js` | Le stepper manuel local (`ETAPES`/`indexEtape`/rendu `puce`/`trait`, 2 états seulement : fait-ou-actif vs à-venir) remplacé par `Echelon` (Lot 0, **premier usage réel** après avoir été écarté au Lot 5 — ici le besoin est réel et Echelon apporte un vrai gain : 3 états distincts fait/actif/à venir au lieu de 2). Bloc trajet (`trajetLabel`/`trajetTexte` × 2) remplacé par `Sentier`, **besoin transverse imprévu identifié en cours de lot** (composant non assigné par D.3.2 pour ce lot mais déjà l'un des 12 du Lot 0, réutilisé sur le même motif qu'aux Lots 3-4). Import mort `Cachet` (jamais rendu dans ce fichier) supprimé au passage. |
| `client/MesCoursesPlanifieesScreen.js` | Aucune maquette dédiée — piste `mes_courses_caarco_2` (onglet "À venir (0)") utilisée pour inspirer la bascule d'onglets, convertie en pilules pleine largeur (`radius.full`, actif = fond foret/texte blanc, `minHeight: 52` pour la cible tactile) au lieu du style souligné précédent ; compteur "(N)" désormais affiché sur les deux onglets (avant : uniquement "À venir"). Borne et Echelon évalués, **non utilisés** (aucun KPI global ni état nommé dans cet écran liste) — Sentier également jugé non pertinent ici (carte de liste compacte, cohérent avec `HistoriqueScreen.js` au Lot 5 qui garde aussi son propre motif compact en carte de liste). |

**Découverte majeure — mécanisme de crédit du parrainage mort sous le flux TC actif, indépendamment du résidu cosmétique ci-dessus** : `obtenirStatsParrainage()` (`total_commissions` affiché dans les 2 `Borne`) lit la table `commissions_parrainage`, alimentée **exclusivement** par la RPC `liberer_sequestre_course()` (migrations 032/033, modèle séquestre aboli) — elle-même **non atteignable** dans le code actuel : accessible uniquement via `terminer_livraison()`, qui n'est appelée nulle part dans `App/src` (confirmé par grep, cohérent avec la découverte déjà actée en C.3.2). Le flux de commission réellement actif aujourd'hui (`confirmer_livraison` → `debiter_commission_tc()`, migrations 082/085) ne contient **aucune** référence à `parrain`/`commissions_parrainage` (vérifié par grep sur ces 2 migrations). Conséquence : le total "Gains de parrainage" affichera **0 FCFA pour 100 % des utilisateurs**, indéfiniment, tant que ce mécanisme n'est pas porté sur le modèle TC (ou remplacé). Ce n'est pas un résidu trompeur au sens de `MerciScreen.js` (C.2 #3) — le chiffre affiché (0) est honnête, pas mensonger — mais le texte `parrainageEcran.etape3` ("... + une commission FCFA sur chaque livraison terminée") promet un mécanisme qui ne se déclenche structurellement jamais aujourd'hui. **Décision Cedric à prendre**, hors périmètre visuel de ce lot : porter le crédit de commission parrainage sur `debiter_commission_tc()`, ou ajuster la promesse de `etape3`/retirer la tuile tant que le mécanisme n'est pas rebranché. Détail complet en CDC D.10.5.

**Composants** : `Borne` (Lot 0, premier usage réel, `ParrainageScreen.js`), `Echelon` (Lot 0, premier usage réel après 2 lots où il avait été écarté, `CoursePlanifieeDetailScreen.js`), `Sentier` (Lot 0, déjà rodé aux Lots 3-4, besoin transverse imprévu comblé sur `CoursePlanifieeDetailScreen.js`).

**i18n** : **1 nouvelle clé** (`parrainageEcran.filleulsTitre`, fr "Amis parrainés" / en "Referred friends" — libellé de la 2ᵉ tuile Borne). Parité vérifiée programmatiquement avant (1383/1383) et après (**1384/1384, 0 écart**) modification. Valeur de la clé existante `parrainageEcran.gainsTitre` corrigée des deux côtés (fr "Gains wallet"→"Gains de parrainage", en "Wallet earnings"→"Referral earnings") sans changement de compte de clés.

**DoD vérifié sur les 5 fichiers modifiés** (`ParrainageScreen.js`, `CoursePlanifieeDetailScreen.js`, `MesCoursesPlanifieesScreen.js`, `fr.js`, `en.js`) :
- Zéro hex/rgba en dur : confirmé par grep après correction — 1 hex préexistant retokenisé (`'#e8d0a0'` → `alpha(colors.nere, 0.35)`, même substitution qu'aux Lots 4-5) ; `'#25D366'` (vert de marque WhatsApp, déjà présent tel quel dans `ProfilPublicScreen.js` hors périmètre) conservé avec commentaire d'exception documentée, conforme à la règle du Master Prompt.
- i18n complet : confirmé, parité fr/en 1384/1384, 1 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison hors des tokens déjà validés (Borne/Echelon/Sentier réutilisent leurs styles internes du Lot 0) ; pilules d'onglets foret/blanc (contraste très large, pas un cas limite comme blanc/néré).
- **Aucune résurgence wallet/séquestre : 1 résidu cosmétique trouvé et corrigé** (libellé "Gains wallet" + icône `wallet-outline`, `ParrainageScreen.js`) — confirmé par grep (0 résultat) sur les 3 écrans après correction. **1 découverte architecturale non cosmétique documentée mais non corrigée** (mécanisme de crédit parrainage mort sous le flux TC, voir ci-dessus) — décision Cedric requise, hors périmètre visuel.
- Cible tactile ≥52px : onglets `MesCoursesPlanifieesScreen.js` explicitement fixés à `minHeight: 52` (le style souligné précédent en était proche mais pas garanti).
- Validation syntaxique : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement (même panne reproduite explicitement sur `CoursePlanifieeDetailScreen.js`, optional chaining — panne d'outillage non modifiée par ce lot, connue depuis le Lot 4, D.8.7). Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers modifiés : OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-5 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

**Périmètre respecté** : aucun écran des Lots 1-5, 7-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché — en particulier `PointsScreen.js`/`MerciScreen.js` non ouverts, aucune des 2 corrections backend 🔴 de la Partie C touchée. Seuls fichiers modifiés : les 3 écrans ci-dessus + `src/i18n/fr.js`/`en.js` (1 clé + 1 libellé corrigé) + ce fichier + le CDC (section D.10).

**Prochain lot recommandé : Lot 7 — Tableau de bord & mission transporteur** (`TableauBordScreen.js`, `CourseScreen.js`, `NavigationScreen.js` — mobilise Echo et Sentier, déjà rodés côté client, plus Jalons pour l'ETA). Point de vigilance à emporter : `TableauBordScreen.js` fait partie des 4 écrans identifiés en D.9.4 comme lisant encore `courses.methode_paiement` (résidu potentiel non vérifié) — à contrôler avec la même méthode de grep exhaustif à l'ouverture de ce lot.

---

## Lot 7 — Tableau de bord & mission transporteur (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.11. Résumé :

| Écran | Traitement |
|---|---|
| `transporteur/TableauBordScreen.js` | **Découverte majeure, corrigée** : `CarteCourse` (composant carte-liste complet, ~240 lignes) et `ListeVide` (état vide plein écran) étaient entièrement morts — l'écran a déjà migré vers une UI carte plein écran + bottom sheet (`BottomSheetCourse`) avant ce lot, sans que l'ancien code liste ait été supprimé. `CarteCourse` + le composant `Etoiles` local qu'il consommait seul supprimés, ainsi que ~13 styles dupliqués/masqués (`statutPoint`, `statutTexte`, `bannierePaiement` × 2 chacun — seule la 2ᵉ définition gagnait silencieusement) et ~15 styles orphelins de l'ancienne mise en page (`entete`, `statutBarre`, `listeTitre`, `liste`, `chargementCentre`, tout le bloc "Carte course"). `ListeVide` reconstruite en indicateur compact "recherche active" (`Echo`, radar bambou 22px + `tableauBord.aucuneCourse`/`demandesTempsReel`, clés déjà existantes mais orphelines) et câblée (`enLigne && !chargement && !preActiveCourse && courses.length === 0`) — comble un vrai manque : rien n'indiquait au TR que l'app écoutait activement de nouvelles courses. `BottomSheetCourse` : bloc adresses reconstruit avec `Sentier` (Lot 0). Vigilance méthode-de-paiement (D.9.4) : `estEspeces` lisait encore `course?.methode_paiement` en repli — simplifié pour ne lire que `mode_paiement_client` (aucun affichage "Wallet" trouvé, mais lecture du champ hérité supprimée). 2 hex en dur retokenisés, 3 imports morts préexistants retirés (`RefreshControl`, `Pressable`, `categoriesAutorisees`). |
| `transporteur/CourseScreen.js` | Bloc trajet (icônes + labels mono + adresses, séparateur horizontal) remplacé par `Sentier` — motif confirmé sur la maquette elle-même, commentée `<!-- Plaquette + Jalons -->` dans le `code.html` source (même confusion de nommage déjà documentée en D.3.1 pour Sentier). 2 hex en dur + 2 fallbacks tautologiques (`x ?? x`) nettoyés. **Découverte, non corrigée** : la branche `statut === 'en_attente'` (boutons Accepter/Refuser, minuterie implicite) n'est plus atteignable — `TableauBordScreen.js` gère désormais l'acceptation immédiate entièrement via `BottomSheetCourse`, et `AdDetailScreen.js` (Lot 8) a son propre appel direct à `candidaterCourse`. Aucun `navigation.navigate('Course', …)` du code réel ne passe plus de course `en_attente`. Code mort probable, laissé en l'état (décision produit/architecture hors périmètre visuel de ce lot). |
| `transporteur/NavigationScreen.js` | **Ajout réel** (pas un remplacement) : carte "Itinéraire" (`Sentier`, départ/arrivée) + barre de progression ETA (`Jalons`) insérées dans le panneau, sous le bloc client — élément présent dans les 2 maquettes (`navigation_livraison_1` : barre de progression sous "Ouvrir dans Maps" + carte itinéraire ; confirmé visuellement) mais absent du code réel jusqu'ici (l'écran n'affichait aucune des 2 adresses en permanence, seulement l'adresse de la cible courante via une étiquette flottante sur la carte). Distance de référence capturée par phase et progression calculée par le même schéma que `SuiviScreen.js` côté client (Lot 4, D.8.2) — recyclage d'un calcul de distance déjà fait dans le watcher GPS existant (`distDestM`), aucune nouvelle logique GPS. 3 hex en dur retokenisés (placeholder OTP, bordure "prix", overlay modal OTP). 1 import mort préexistant retiré (`appelerUtilisateur`). **Aucune logique de prix, de solde de jetons ou de validation OTP touchée** — la RPC `confirmer_livraison` et son appel ne sont pas modifiés. |

**Composants** : `Echo` (premier usage réel, `TableauBordScreen.js` — indicateur "recherche active"), `Sentier` (3 écrans, déjà rodé aux Lots 3/4/6), `Jalons` (`NavigationScreen.js`, ajout réel comme au Lot 4). **Extension de composant partagé** : `Sentier.js` reçoit 2 nouveaux props optionnels `couleurLabel`/`couleurSousLabel` (défaut = couleurs statiques d'origine, donc zéro changement visuel pour les 4 appelants existants des Lots 3/4/6 qui ne les passent pas) — nécessaire car `BottomSheetCourse` (`TableauBordScreen.js`) et `CourseScreen.js` placent `Sentier` sur un fond thémé (`tc.blanc`), alors que le composant n'utilisait jusqu'ici que des couleurs statiques (`colors.charbon`/`colors.cendre`) : sans l'extension, le texte aurait pu devenir illisible en mode sombre (`tc.blanc` ≈ vert très sombre, quasi identique à `colors.charbon`). **Point de vigilance transversal découvert, non corrigé** : le même risque existe déjà sur `AttenteScreen.js` (Lot 4, D.8.4) — `Sentier` y est posé sur un conteneur `{ backgroundColor: tc.blanc }` sans les nouveaux props de couleur, donc sans bénéficier de l'extension. Écran déjà clos, hors périmètre de cette session — à corriger à l'ouverture d'un futur lot touchant `AttenteScreen.js`, ou dans une passe dédiée.

**Echelon évalué, non utilisé** : `NavigationScreen.js` a déjà un stepper horizontal fait main (`PastillePhase`/`barrePhases`, 3 phases Prise/Route/Livré) structurellement proche d'`Echelon` mais visuellement plus riche — une icône distincte par phase (position/navigation/checkmark), y compris pour les étapes non atteintes, alors qu'`Echelon` affiche un simple numéro pour les étapes non complétées. Remplacer aurait perdu cette distinction sans gain réel ; étendre `Echelon` pour accepter des icônes par étape aurait été une extension plus risquée que celle faite sur `Sentier` (changement de la forme de données `etapes`, seul appelant existant `CoursePlanifieeDetailScreen.js` du Lot 6). Même discipline que Echo/`AttenteScreen.js` au Lot 4 (D.8.3) : composant riche déjà en place, non remplacé faute de gain démontré.

**Découverte — résidu de documentation wallet/séquestre, corrigé** : `services/offlineQueue.js` (consommé par `NavigationScreen.js`) portait un commentaire d'en-tête obsolète mentionnant encore la "libération séquestre" du modèle aboli — aucune action de code correspondante (les 4 types d'action réels sont `MAJ_STATUT_COURSE`, `CONFIRMER_LIVRAISON`, `DEBITER_COMMISSION_TC`, `NOTIFIER_CLIENT`, tous conformes au modèle TC). Commentaire corrigé ; recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` par ailleurs négative sur les 3 écrans et le reste de leurs services.

**Découverte architecturale, non corrigée (décision Cedric à prendre)** : la branche `en_attente` de `CourseScreen.js` (Accepter/Refuser) semble être du code mort — plus aucun chemin de navigation réel du code n'y mène avec une course `en_attente` depuis que `TableauBordScreen.js` gère l'acceptation immédiate via `BottomSheetCourse`. Non supprimée dans ce lot : c'est une décision d'architecture/produit (confirmer l'absence de tout autre point d'entrée, notamment via deep-link ou notification, avant de retirer une branche métier), hors du périmètre "refonte visuelle" de cette session — même prudence que pour la découverte D.10.5 du Lot 6.

**i18n** : **0 nouvelle clé**. Toutes les chaînes nécessaires existaient déjà (`tableauBord.aucuneCourse`/`demandesTempsReel` pour l'indicateur de recherche, `course.labelDepart`/`labelArrivee` réutilisées pour les 2 nouveaux `Sentier` de `CourseScreen.js`/`NavigationScreen.js`, `navigation.fallbackDepart`/`fallbackArrivee` déjà existantes). Parité fr/en vérifiée programmatiquement avant et après modification : **1384 clés de chaque côté, 0 écart**, inchangé par cette passe.

**DoD vérifié sur les 5 fichiers modifiés** (`TableauBordScreen.js`, `CourseScreen.js`, `NavigationScreen.js`, `Sentier.js`, `offlineQueue.js`) :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) sur les 3 écrans — 7 hex préexistants retokenisés au total (2 `TableauBordScreen.js`, 2 `CourseScreen.js`, 3 `NavigationScreen.js`), tous via `alpha()` avec la même substitution qu'aux lots précédents pour les valeurs déjà rencontrées (`#e8d0a0` → `alpha(colors.nere, 0.35)`, `#0f1411xx` → `alpha(colors.nuit, …)`).
- i18n complet : confirmé, parité fr/en 1384/1384, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison hors des tokens déjà validés. Un vrai risque de régression (texte statique de `Sentier` sur fond thémé `tc.blanc`) a été détecté avant d'introduire le bug, et corrigé par l'extension `couleurLabel`/`couleurSousLabel` plutôt que découvert après coup — voir aussi le point de vigilance résiduel sur `AttenteScreen.js` (Lot 4, préexistant, non corrigé ici).
- Aucune résurgence wallet/séquestre : 1 résidu de commentaire trouvé et corrigé (`offlineQueue.js`, voir ci-dessus). Vigilance `methode_paiement` (D.9.4) traitée sur `TableauBordScreen.js` : aucun affichage "Wallet" trouvé, lecture du champ hérité supprimée par simplification. Recherche exhaustive confirmée par grep (0 résultat) sur les 3 écrans et les services consommés.
- Cible tactile ≥52px : aucun nouvel élément tactile ajouté (l'indicateur "recherche active" est `pointerEvents="none"`, `Sentier`/`Jalons` sont purement présentationnels).
- Validation syntaxique : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `TableauBordScreen.js` (`course?.mode_paiement_client`, optional chaining) — même panne d'outillage que les Lots 4-6, non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 5 fichiers modifiés : OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-6 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci vu l'ampleur du nettoyage de code mort sur `TableauBordScreen.js`.

**Périmètre respecté** : aucun écran des Lots 1-6, 8-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 3 écrans ci-dessus + `src/components/Sentier.js` (extension additive) + `src/services/offlineQueue.js` (commentaire) + ce fichier + le CDC (section D.11). Aucune clé i18n ajoutée (`fr.js`/`en.js` non modifiés).

**Prochain lot recommandé : Lot 8 — Revenus & jetons transporteur** (`RevenusScreen.js`, `MesTokensScreen.js`, `AdDetailScreen.js` — mobilise Borne et Silo). Points de vigilance à emporter : (1) `RevenusScreen.js` fait partie des 4 écrans identifiés en D.9.4 comme lisant potentiellement encore `course.methode_paiement` (ligne 258 confirmée lors de ce Lot 7, jamais vérifiée pour un affichage "wallet" équivalent) — à contrôler avec la même méthode de grep exhaustif ; (2) vigilance déjà actée en D.2.4/C.2 #5 : ne pas réintroduire de lecture des tables `wallets` sur `RevenusScreen.js`/`MesTokensScreen.js`, code déjà propre à préserver ; (3) `AdDetailScreen.js` a son propre appel direct à `candidaterCourse` (confirmé ce Lot 7) — vérifier à l'ouverture s'il a aussi besoin de `Sentier` pour son bloc trajet, par la même méthode de vérification du code réel avant d'imposer un composant.

---

## Lot 8 — Revenus & jetons transporteur (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.12. Résumé :

| Écran | Traitement |
|---|---|
| `transporteur/RevenusScreen.js` | Les 3 `StatCard` locales (jour/semaine/mois, dupliquant exactement la structure icône+valeur mono+libellé) remplacées par `Borne` (Lot 0, icônes `today-outline`/`calendar-outline`/`calendar-number-outline`, confirmées présentes dans la maquette `mes_revenus_2` — `today`/`date_range`/`calendar_month`). **Vigilance prioritaire traitée** : ligne 258 lisait `course.methode_paiement === 'especes'` (champ hérité migration 039) — simplifiée en `course.mode_paiement_client === 'especes'`, et la requête `coursesTransporteur()` (`services/courses.js`, 2 appelants vérifiés : ce fichier et `CoursesTransporteurScreen.js` du Lot 11, qui ne consomme aucun des deux champs) sélectionne désormais `mode_paiement_client` au lieu de `methode_paiement`. **Nettoyage de code mort trouvé et fait** : 7 styles orphelins d'un ancien bloc "solde retirable" (`soldeBloc`, `soldeLigne`, `soldeMontant`, `soldeBtns`, `btnRetraitIcone`, `btnRechargerBloc`, `btnRechargerBlocTexte`) — définis mais jamais consommés par aucun JSX, résidu direct du modèle wallet aboli — supprimés. Styles `btnRetraitBloc`/`btnRetraitBlocTexte` (actifs, servent le bouton "Gérer mes jetons") renommés `btnJetonsBloc`/`btnJetonsBlocTexte` pour ne plus porter le mot "retrait". Commentaire de tête pointant vers ce bloc mort ("le bloc solde retirable plus bas") corrigé. |
| `transporteur/MesTokensScreen.js` | **Code déjà propre confirmé** (C.2 #5) : aucune trace de wallet, `solde` désigne exclusivement `solde_tc`. Seule correction : 4 hex en dur retokenisés (`'#ffffff'` → `colors.blanc` ×2, `'#0f1411b8'` → `alpha(colors.nuit, 0.72)`, `'#0f141180'` → `alpha(colors.nuit, 0.5)`). Import mort préexistant `FlatList` retiré (l'historique de transactions utilise `.map()`, jamais `<FlatList>`). |
| `transporteur/AdDetailScreen.js` | Bloc "Trajet + distance" (dots + trait manuels) remplacé par `Sentier`, sur le même schéma label=adresse/sousLabel=descripteur que `TableauBordScreen.js` au Lot 7 — besoin confirmé par la maquette `d_tails_de_l_annonce_1` elle-même (icônes `my_location`/`location_on` reliées par un trait). Fonction locale `Etoiles({ note })` (dupliquant exactement le composant partagé `Etoiles.js`, même logique plein/demi/vide, même couleur unique néré) remplacée par le composant partagé (`valeur`, `taille={11}`). 1 hex en dur retokenisé (`'#0f1411f2'` → `alpha(colors.nuit, 0.95)`, valeur déjà en usage identique sur `CourseScreen.js` au Lot 7). Import mort préexistant `FlatList` retiré. **Découverte du Lot 7 vérifiée** : `AdDetailScreen.js` appelle bien directement `candidaterCourse` sans passer par `CourseScreen.js` (confirmé) — son bloc trajet avait un besoin réel de `Sentier`, traité ci-dessus. |

**Composants** : `Borne` (Lot 0, 2ᵉ usage réel après Lot 6, `RevenusScreen.js` — maquette `mes_revenus_2` confirme la structure icône+valeur+libellé), `Sentier` (déjà rodé aux Lots 3/4/6/7, `AdDetailScreen.js`), `Etoiles` (déjà rodé au Lot 5, `AdDetailScreen.js`, 3ᵉ écran). **`Silo` évalué, non utilisé** : aucune des 4 maquettes du lot (`mes_revenus_1`, `mes_revenus_2`, `mes_tokens_de_course_caarco`, `achat_de_tokens_tc`) ne montre de graphique en barres ou d'historique visualisé dans le temps — uniquement des cartes KPI ponctuelles et des listes de transactions. Composant assigné par D.3.2, vérifié, jugé non pertinent après inspection du besoin réel (même discipline qu'Echo/Lot 4, Echelon/Lot 5, Echelon/Lot 7).

**Découverte maquette — résidu "Wallet" distinct de "TransLogix", trouvé sur 3 dossiers** : `mes_revenus_2` (bottom nav "Wallet" actif + item de transaction "Retrait -50 000 FCFA"), `mes_tokens_de_course_caarco` et `mes_tokens_de_course` (bottom nav, onglet "Wallet" actif). Purement cosmétique — l'app n'utilise jamais ces barres de navigation Stitch, remplacées par sa propre navigation — aucune action de code nécessaire, mentionné pour mémoire (C.4.4) si ces maquettes sont un jour reprises intégralement. **Découverte distincte** : `achat_de_tokens_tc` porte encore `<title>CAARCO - Recharge Rapide Wallet</title>` — résidu de nommage différent de "TransLogix" mais de même famille (vestige du modèle wallet aboli dans le titre HTML, invisible à l'écran) ; le corps de la maquette est intégralement conforme au flux TC réel (Orange Money/MTN MoMo, "Acheter des Tokens de Course", mention Notchpay) — correction cosmétique du `<title>` seulement si cette maquette est un jour rouverte comme référence.

**i18n** : **0 nouvelle clé** — toutes les clés utilisées (`revenus.aujourdhui`/`cetteSemaine`/`ceMois`, `adDetail.departLabel`/`arriveeLabel`) existaient déjà. Parité fr/en vérifiée programmatiquement (aplatissement récursif + comparaison) avant et après modification : **1384 clés de chaque côté, 0 écart**, inchangé par cette passe.

**DoD vérifié sur les 4 fichiers modifiés** (`RevenusScreen.js`, `MesTokensScreen.js`, `AdDetailScreen.js`, `services/courses.js`) :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) sur les 3 écrans — 5 hex préexistants retokenisés au total (4 `MesTokensScreen.js`, 1 `AdDetailScreen.js`), `RevenusScreen.js` n'en portait aucun.
- i18n complet : confirmé, parité fr/en 1384/1384, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs hors des tokens déjà validés — `Borne`/`Sentier`/`Etoiles` réutilisent leurs styles internes du Lot 0 ; aucun des 3 écrans de ce lot n'est thémé (`useTheme()`/`tc.`) sur les zones où `Sentier` est posé (`AdDetailScreen.js` n'utilise `useTheme()` nulle part, `Plaquette` y est en fond statique `colors.blanc`) — donc pas de risque de régression du type D.11.5, vérifié explicitement avant d'écarter le besoin des props `couleurLabel`/`couleurSousLabel`.
- Aucune résurgence wallet/séquestre : **1 résidu de code mort trouvé et corrigé** (7 styles orphelins "solde retirable", `RevenusScreen.js`, voir ci-dessus) ; vigilance `methode_paiement` (D.9.4/D.11.7) **traitée sur le dernier des 4 écrans qui la portaient encore** (`RevenusScreen.js` ligne 258 + `coursesTransporteur()`) — les 3 autres (`SuiviScreen.js` Lot 4, `TableauBordScreen.js` Lot 7, `CoursesEnCoursAdminScreen.js` Lot 13) suivent leur propre calendrier, celui-ci n'était pas rouvert. Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` confirmée sur les 3 écrans et tous les services consommés (`courses.js`, `tokensTC.js`, `candidatures.js`, `modeConnexion.js`, `supabase.js`) : aucune trace active, seul le commentaire documentaire légitime du masquage V1 Play Store subsiste (corrigé pour ne plus référencer le bloc mort supprimé).
- Cible tactile ≥52px : aucun nouvel élément tactile introduit par ce lot (`Borne`/`Sentier`/`Etoiles` sont purement présentationnels ici).
- Validation syntaxique : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `AdDetailScreen.js` (`route.params ?? {}`, optional/nullish) — même panne d'outillage que les Lots 4-7, toujours non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 4 fichiers modifiés : OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-7 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

**Nettoyage complémentaire (hors DoD strict, trouvé en cours de lot)** : import mort préexistant `FlatList` retiré sur `MesTokensScreen.js` et `AdDetailScreen.js` (ni l'un ni l'autre ne l'utilisaient — historique en `.map()`, pas de liste virtualisée).

**Périmètre respecté** : aucun écran des Lots 1-7, 9-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 3 écrans ci-dessus + `src/services/courses.js` (1 champ substitué dans une requête à 2 appelants vérifiés, le second n'en dépendant pas) + ce fichier + le CDC (section D.12). Aucune clé i18n ajoutée (`fr.js`/`en.js` non modifiés).

**Prochain lot recommandé : Lot 9 — Réputation & stats transporteur** (`StatsTransporteurScreen.js`, `LeaderboardScreen.js`, `NotationClientScreen.js` — mobilise Silo, Étoiles, Borne). Points de vigilance à emporter : (1) `LeaderboardScreen.js` porte le résidu de marque "TransLogix" dans sa maquette `classement_r_gional_caarco` (C.2 #2), code déjà propre — correction cosmétique de la seule maquette si reprise ; (2) `StatsTransporteurScreen.js` a déjà un composant local `CarteStat` (repéré incidemment lors de ce Lot 8, lignes 306-316, props `icone`/`titre`/`valeur`/`sousTitre`/`badge`) qui joue un rôle de tuile KPI proche de `Borne` **sans en être une réutilisation** — vérifier à l'ouverture si `CarteStat` doit être remplacé par `Borne` (même geste que `StatCard`→`Borne` sur `RevenusScreen.js` à ce Lot 8) ou s'il porte une fonctionnalité que `Borne` ne couvre pas (badge, sous-titre conditionnel), avant de présumer l'un ou l'autre ; (3) aucun des 4 écrans restants identifiés en D.9.4/D.11.7 comme lisant potentiellement `course.methode_paiement` n'a été rouvert ici sauf `RevenusScreen.js` (traité) — `SuiviScreen.js` (Lot 4, clos), `TableauBordScreen.js` (Lot 7, traité côté `estEspeces` seulement), `CoursesEnCoursAdminScreen.js` (Lot 13, à faire) restent à vérifier chacun à l'ouverture de leur lot respectif ; (4) `Silo`, assigné à ce Lot 8 par D.3.2 mais jamais utilisé faute de graphique réel dans les maquettes de revenus/tokens, reste donc **encore jamais exercé en conditions réelles** — `StatsTransporteurScreen.js` (maquettes `statistiques_performance*`, D.3.1 preuve #5) est le candidat naturel pour son premier usage réel, à vérifier sans présumer.

---

## Lot 9 — Réputation & stats transporteur (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.13. Résumé :

| Écran | Traitement |
|---|---|
| `transporteur/StatsTransporteurScreen.js` | **`CarteStat` local évalué face à `Borne`, conservé** (voir découverte ci-dessous) — aucun remplacement. `BarresJours` (graphique en barres CSS fait main, 7 jours de courses livrées, déjà logé dans la carte "Revenus nets") remplacé par `Silo` (Lot 0, **1er usage réel** — direct match avec le graphique 7 jours de la maquette `statistiques_performance_caarco`, tooltip au tap inclus). `EtoilesNote` (fonction locale dupliquant `Etoiles.js`, note moyenne arrondie sans demi-étoile) remplacée par le composant partagé (gain net : demi-étoile désormais rendue, comme sur la maquette `statistiques_performance` "4.8" + 4 pleines + 1 demie). Icône `wallet-outline` de la carte "Revenus nets" corrigée en `cash-outline` (résidu cosmétique, voir découverte). Commentaire de tête `// transactions_wallet type=recette` corrigé en `// transactions_tc type=commission` (le code interrogeait déjà `transactions_tc`, seul le commentaire était resté au vocabulaire de l'ancien modèle). Styles morts `barresConteneur`/`barreCol`/`barreHaut`/`barre`/`barreLabel` supprimés (`Silo` porte ses propres styles). |
| `transporteur/LeaderboardScreen.js` | Fonction locale `Etoiles({note})` (dupliquant `Etoiles.js`, arrondi sans demi-étoile) remplacée par le composant partagé (`taille={10}`, `style={{gap:1}}` pour préserver l'espacement d'origine). 7 hex en dur retokenisés : `'#3db551'` (×3 : pastille "LIVE", texte "LIVE", point "en ligne" avatar) → `colors.bambou` (aucun autre usage de ce hex ailleurs dans l'app, aucune convention établie à préserver) ; `'#e8d0a0'` → `alpha(colors.nere, 0.35)` (même substitution qu'aux Lots 4-6) ; `'#f0f5f1'` (fond de la ligne "c'est moi" dans le classement) → `alpha(colors.bambou, 0.08)`. Les 3 couleurs de médaille (`'#C9A227'` or, `'#8C9099'` argent, `'#A0522D'` bronze) **conservées avec commentaire d'exception documentée** — convention universelle or/argent/bronze hors palette Atelier CAARCO, même principe que le vert WhatsApp déjà excepté dans `ProfilPublicScreen.js`/`ParrainageScreen.js`. |
| `transporteur/NotationClientScreen.js` | Deux fonctions locales dupliquées, `Etoiles` (note globale, interactive, taille 32) et `EtoilesMini` (4 critères, interactive, taille 22) — remplacées par le composant partagé unique, `style={styles.etoilesRangee}` réutilisé tel quel pour préserver l'espacement d'origine (`gap: spacing.pause`) sur les deux appels, même traitement que `NotationScreen.js` au Lot 5. Aucun hex en dur trouvé (déjà propre). |

### Découverte principale — `CarteStat` vs `Borne` : conservé, non remplacé, non étendu

Contrairement au geste `StatCard`→`Borne` du Lot 8, **`CarteStat` n'a pas été remplacé** après lecture du code réel et des deux maquettes assignées. Preuve directe dans `statistiques_performance_caarco` (la maquette la plus proche de l'écran réel — mêmes pilules de période Semaine/Mois/Tout que le code) : ses 4 tuiles KPI suivent l'ordre **icône → titre → valeur → sous-titre optionnel** ("Dist: 450 km", "Moy. 15 km/course"), pas l'ordre figé de `Borne` (icône+delta → valeur → libellé unique, sans sous-titre). Les 4 usages réels de `CarteStat` dans le code s'appuient tous sur `sousTitre` (jamais vide, contenu variable) et sur une couleur d'icône différente par tuile (`couleurIcone` : bambou/néré/forêt/latérite, codage visuel des 4 catégories de KPI) — deux fonctionnalités que `Borne` ne couvre pas. Étendre `Borne` pour les deux (réordonnancement titre-avant-valeur + sous-titre + couleur d'icône variable) aurait reconstruit l'anatomie de `CarteStat` à l'intérieur de `Borne` pour le bénéfice d'un seul écran consommateur, contrairement à l'extension `couleurLabel`/`couleurSousLabel` de `Sentier` (Lot 7) qui était purement additive et à coût nul pour les appelants existants. Même discipline que `Echo`/`AttenteScreen.js` (Lot 4, D.8.3) et `Echelon`/`NavigationScreen.js` (Lot 7) : un motif local plus riche, déjà aligné sur la maquette réelle, est conservé plutôt que forcé dans le composant partagé. Détail complet en CDC D.13.3.

### Découverte — icône "wallet-outline" sur la carte Revenus, résidu cosmétique corrigé

`StatsTransporteurScreen.js` affichait l'icône Ionicons `wallet-outline` sur la carte "Revenus nets" — trouvée par la recherche exhaustive de mots-clés (grille C.4.3), bien qu'aucun texte visible ne mentionne "wallet". Par cohérence avec le vocabulaire d'icônes déjà établi ailleurs dans l'app pour l'argent/les jetons (`cash-outline`, confirmé en usage sur `TableauBordScreen.js`), et le même geste qu'au Lot 6 (icône `wallet-outline` corrigée sur `ParrainageScreen.js`), remplacée par `cash-outline`. Un commentaire de tête (`// transactions_wallet type=recette`) portait le même vocabulaire résiduel sans impact fonctionnel (le code interrogeait déjà la bonne table `transactions_tc`) — corrigé également.

### Découverte maquettes — "TransLogix" trouvé sur 2 dossiers, dont 1 non prévu par le tracking

`classement_r_gional_caarco` portait "TransLogix" à 2 endroits (`<title>` + `<h1>` **visible** à l'écran, pas seulement le tag caché) — conforme à C.2 #2, corrigé. **Découverte non prévue** : `noter_le_client_caarco`, classé ✅ (sans réserve) en C.1/D.2.4, porte également "TransLogix" aux 2 mêmes emplacements (`<title>` + `<h1>` visible) — jamais signalé par le tri précédent. Corrigé par la même méthode. Les deux maquettes ont servi de référence structurelle à ce lot, la correction était donc requise (pas seulement "si un jour reprise").

### Découverte maquette — `noter_le_client_caarco` : critères en tags binaires, code réel plus riche (étoiles graduées)

La maquette modélise les "critères" comme des boutons-tags à bascule (Ponctualité/Communication/Colis bien préparé/Disponibilité, sélection simple oui/non) — alors que le code réel (et `services/avis.js` sous-jacent) capture déjà une **note graduée 1-5 par critère** (`ponctualite`, `communication`, `soinColis`, `proprete`), en plus de la note globale. Reproduire le motif "tags" de la maquette aurait fait régresser une fonctionnalité réelle et déjà en production (perte de granularité 1-5 au profit d'un simple oui/non). Non repris — seul le remplacement `Etoiles`/`EtoilesMini` → composant partagé a été fait, la maquette n'ayant servi que de confirmation structurelle générale (bannière paiement, avatar, note globale, commentaire, boutons), pas de référence pour cette section précise.

**Composants** : `Silo` (Lot 0, **1er usage réel du chantier**, `StatsTransporteurScreen.js`), `Etoiles` (3ᵉ/4ᵉ/5ᵉ écrans consommateurs après les Lots 5/8, tous les trois ce lot-ci). `Borne` évalué face à `CarteStat`, **non utilisé** (voir découverte ci-dessus).

**i18n** : **0 nouvelle clé** — les 62 clés utilisées par les 3 écrans (`stats.*`, `leaderboard.*`, `notationClient.*`, `merci.criteres.*`, `courseAcceptee.nombreCourses`) existaient déjà, vérifiées une par une (présentes côté fr **et** en). Parité vérifiée programmatiquement avant et après modification : **1384 clés de chaque côté, 0 écart**, inchangé par cette passe.

**DoD vérifié sur les 3 fichiers modifiés** :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat, hors les 3 couleurs de médaille documentées comme exception) — 7 hex préexistants retokenisés sur `LeaderboardScreen.js`, aucun sur les 2 autres écrans (déjà propres).
- i18n complet : confirmé, parité fr/en 1384/1384, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs hors des tokens déjà validés — `Silo`/`Etoiles` réutilisent leurs styles internes du Lot 0 ; aucun des 3 écrans n'utilise `Sentier` (donc aucun risque du type D.11.5 à traiter ici).
- **Aucune résurgence wallet/séquestre** : 1 résidu cosmétique trouvé et corrigé (icône `wallet-outline` + commentaire `transactions_wallet`, `StatsTransporteurScreen.js`, voir découverte ci-dessus). Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait` confirmée par grep (0 résultat) sur les 3 écrans **et** les services consommés (`services/avis.js`, `services/statutConnexion.js` — tous deux vides de toute trace). `course.methode_paiement`/`mode_paiement_client` : recherché par grep sur les 3 écrans, **aucune occurrence** — ces écrans ne touchent pas aux données de paiement de course, conforme à l'attente.
- Cible tactile ≥52px : aucun nouvel élément tactile introduit par ce lot (`Silo`/`Etoiles` sont les seuls composants ajoutés, usages en lecture ou déjà interactifs avant ce lot avec la même zone de `hitSlop`).
- Validation syntaxique : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement, reproduit explicitement sur `StatsTransporteurScreen.js` (`badgeCouleur ?? colors.bambou`, nullish coalescing) — même panne d'outillage que les Lots 4-8 (D.8.7 à D.12.9), toujours non réparée, signalée une nouvelle fois à Cedric. Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-8 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

**Périmètre respecté** : aucun écran des Lots 1-8, 10-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 3 écrans ci-dessus + 2 maquettes (`classement_r_gional_caarco/code.html`, `noter_le_client_caarco/code.html`, correction cosmétique "TransLogix"→CAARCO) + ce fichier + le CDC (section D.13). Aucune clé i18n ajoutée (`fr.js`/`en.js` non modifiés). `Borne.js`/`Silo.js`/`Etoiles.js` non modifiés (aucune extension nécessaire ce lot-ci).

**Prochain lot recommandé : Lot 10 — KYC transporteur** (`SoumissionKYCScreen.js`, `StatutKYCScreen.js` — mobilise `Pochette`, jamais encore exercé après les Lots 0-9). Voir le prompt de session dédié fourni en fin de session.

---

## Lot 10 — KYC transporteur (clôturé le 09/07/2026)

**2 écrans traités, tous marqués fait.** Détail complet en CDC D.14. Résumé :

| Écran | Traitement |
|---|---|
| `transporteur/SoumissionKYCScreen.js` | Photos véhicule (`BlocPhoto` en boucle + menu `Alert` Changer/Supprimer par photo) remplacées par `Pochette` (galerie + zoom + suppression native), plafond porté de 3 à 4 photos (colonne `vehicule_url` déjà un `TEXT[]` sans limite en base, aucune migration requise) + texte d'aide suggérant les 4 angles de la maquette (face avant/profil/arrière/**plaque d'immatriculation**). CNI et Permis (documents obligatoires uniques) **conservés en `BlocPhoto`**, décision documentée : `Pochette` en mode `multiple={false}` aurait transformé le remplacement d'un document (1 geste aujourd'hui) en 2 gestes (supprimer puis rouvrir la dropzone), pour un gain de zoom que D.3.1 attribue explicitement à un autre écran (`validation_kyc_admin`, Lot 15). |
| `transporteur/StatutKYCScreen.js` | Composant local `PhotoDoc` (image statique + légende + repli d'erreur, aucune interaction) remplacé par `Pochette` en lecture seule (ni `onAjouter` ni `onSupprimer`) sur la galerie de documents déjà soumis (CNI/Permis/Véhicule 1-N) — gain net de zoom plein écran, utile notamment quand le dossier est `rejete`/`infos_manquantes`. Écart assumé : le repli visuel `onError` de `PhotoDoc` (icône si l'image casse) n'a pas d'équivalent dans `Pochette` — risque jugé faible (URLs signées valides 10 ans). |

**Découverte majeure — `v_rification_kyc_transporteur_2` n'est pas un écran de statut, malgré son titre et son classement ✅ résolu en D.2.4** : la lecture intégrale du `code.html` (demandée pour ce lot) révèle que cette maquette est en réalité une **2ᵉ variante du formulaire de soumission** (CNI recto+verso, permis, 3 photos véhicule numérotées, tiroir de nav desktop) — pas une page de statut/vérification (aucune bannière de statut, aucun motif de rejet, aucun badge vérifié). Le titre HTML seul (« Vérification KYC ») ne garantissait donc pas une correspondance structurelle avec l'écran réel du même nom. Conséquence : la structure réelle de `StatutKYCScreen.js` (plus riche fonctionnellement) est conservée intégralement — aucune retouche structurelle depuis cette maquette, qui ne documente pas ce que fait réellement l'écran. Détail complet en CDC D.14.5.

**Écarts maquette/code sur les photos KYC** : (1) CNI recto/verso séparés dans les 2 maquettes — non repris, le schéma `transporteurs_kyc` n'a qu'une colonne `cni_url` unique, ajouter le verso exigerait une migration hors périmètre d'une passe visuelle ; (2) 4ᵉ photo véhicule "Plaque d'imm." suggérée par les 2 maquettes — reprise sans migration (plafond 3→4 + texte d'aide, colonne déjà un tableau sans contrainte de nombre). Détail CDC D.14.4bis.

**Composants** : `Pochette` (Lot 0, **2ᵉ usage réel du chantier** après le Lot 3 — l'hypothèse de départ de cette session, « déjà rodé au Lot 3 », est confirmée par grep). **Extension additive trouvée et corrigée sur `Pochette.js` lui-même** : le composant promettait `fichiers [{ uri, label? }]` dans son propre commentaire d'en-tête depuis le Lot 0, mais ne rendait jamais `label` — corrigé (légende sous chaque vignette, rendu conditionnel, zéro impact visuel pour l'appelant existant `DetailsColisScreen.js` qui ne passe pas ce champ). Même discipline que l'extension `Sentier` du Lot 7.

**i18n** : **1 nouvelle clé** (`kyc.soumission.photosVehiculeAide`, fr "Suggestion : face avant, profil, arrière, plaque d'immatriculation." / en "Suggested: front, side, rear, registration plate.") + **1 valeur corrigée sans nouvelle clé** (`kyc.soumission.maxPhotosVehicule` : "3" → "4" photos, fr et en). Parité vérifiée programmatiquement avant (1384/1384) et après (**1385/1385, 0 écart**) modification. Clés `kyc.soumission.photoVehiculeTitreAlert`/`changer` devenues orphelines (l'ancien menu Alert par photo véhicule n'existe plus) — conservées, non supprimées, même traitement que les orphelines des lots précédents.

**DoD vérifié sur les 3 fichiers modifiés** (`SoumissionKYCScreen.js`, `StatutKYCScreen.js`, `Pochette.js`) :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) — 2 hex préexistants retokenisés (1 par fichier : `'#b0ccb0'` → `alpha(colors.bambou, 0.3)` sur `StatutKYCScreen.js` ; `'#0f1411f0'` → `alpha(colors.nuit, 0.94)` sur `Pochette.js`, trouvé en marge de son extension). `SoumissionKYCScreen.js` était déjà propre.
- i18n complet : confirmé, parité fr/en 1385/1385, 1 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison de couleurs hors des tokens déjà validés au Lot 0. Aucun des 2 écrans n'utilise `useTheme()`/mode sombre adaptatif ni `Sentier` — la vigilance héritée du Lot 7 (texte statique sur fond thémé) ne s'applique pas ici.
- **Aucune résurgence wallet/séquestre** : recherche exhaustive confirmée par grep (0 résultat pertinent) sur les 2 écrans et `Pochette.js` — 1 faux positif ("retrait" dans un commentaire de code de `Pochette.js`, sens "suppression d'une vignette", non financier, non modifié). `course.methode_paiement`/`mode_paiement_client` : recherché explicitement, 0 occurrence (attendu, écrans KYC hors course).
- Cible tactile ≥52px : aucun nouvel élément tactile hors de ceux déjà conformes de `Pochette` (dropzone 84×84 + `hitSlop` sur le bouton supprimer) et du bouton "Ajouter une photo du véhicule" déjà existant.
- Validation syntaxique : `npx babel --presets babel-preset-expo` échoue toujours dans cet environnement (même panne d'outillage que les Lots 4-9, D.8.7 à D.13.6, toujours non réparée, signalée une nouvelle fois à Cedric). Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers modifiés : OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-9 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché.

**Périmètre respecté** : aucun écran des Lots 1-9, 11-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 2 écrans ci-dessus + `App/src/components/Pochette.js` (extension additive + 1 hex retokenisé) + `App/src/i18n/fr.js`/`en.js` (1 clé + 1 valeur corrigée) + ce fichier + le CDC (section D.14).

**Prochain lot recommandé : Lot 11 — Profil, messagerie & annexes transporteur** (`ProfilClientScreen.js`, `MessagesTransporteurScreen.js`, `MesReservationsScreen.js`, `CoursesTransporteurScreen.js` — mobilise `Echelon`, `Sentier`). Point de vigilance à emporter : D.2.4/D.3.2 signalent une redondance potentielle non résolue entre `transporteur/ProfilClientScreen.js` (ce lot) et `ProfilPublicScreen.js` (Lot 12) — à vérifier à l'ouverture avant de dupliquer l'effort sur les deux. Voir le prompt de session dédié fourni en fin de session.

---

## Lot 11 — Profil, messagerie & annexes transporteur (clôturé le 09/07/2026)

**4 écrans traités, tous marqués fait.** Détail complet en CDC D.15. Résumé :

| Écran | Traitement |
|---|---|
| `transporteur/ProfilClientScreen.js` | `Etoiles` local remplacé par le composant partagé (`valeur`, `taille={22}`, `style={{gap:3}}`). Bloc trajet (dots + trait manuels) remplacé par `Sentier` — confirmé pertinent par le bloc « Itinéraire » de la maquette `profil_client_caarco`. **Bug réel corrigé** : le compteur de courses du client lisait `client?.nombre_courses`, un champ jamais sélectionné par la requête réelle (`coursesEnAttente()`, `services/courses.js`, qui sélectionne `nombre_courses_client`) — tout client affichait « 0 course » quel que soit son historique. Corrigé en `client?.nombre_courses_client`. |
| `transporteur/MessagesTransporteurScreen.js` | Structure confirmée équivalente à `messagerie_transporteur_caarco` (2 catégories + recherche + badge de compte, sous forme de sections plutôt que d'onglets — différence d'implémentation, pas un écart structurel). 1 hex en dur retokenisé (`'#edf4ef'` → `alpha(colors.bambou, 0.08)`). Barre de recherche de la maquette non ajoutée (écart documenté, ajout de capacité hors périmètre — voir CDC D.15.4). |
| `transporteur/MesReservationsScreen.js` | Sans maquette. Déjà conforme au DoD avant ce lot (zéro hex, aucune résurgence wallet, i18n complet) — non modifié. `Sentier`/`Echelon` évalués, non pertinents (trajet en une ligne de texte, pas de motif dots/trait ; aucun état à étapes nommées). |
| `transporteur/CoursesTransporteurScreen.js` | Confirmé dérivé de `client/HistoriqueScreen.js` (Lot 5) — motif de trajet compact conservé par cohérence avec la décision déjà actée sur `HistoriqueScreen.js` (non converti en `Sentier`, carte de liste dense). **Bug réel corrigé** : `ListHeaderComponent` référençait une variable `enCours` devenue hors-scope après un refactor antérieur non commité (déplacement du calcul dans un `useMemo`) — l'écran plantait (`ReferenceError`) à chaque ouverture. Corrigé via un `useMemo` dédié (`enCoursCount`). |

**Redondance `ProfilClientScreen.js`/`ProfilPublicScreen.js` — clarifiée, pas de fusion** (CDC D.15.2) : les deux écrans répondent à des besoins distincts. `ProfilClientScreen.js` est attaché à un `course` (fiche de candidature reçue, jamais un `utilisateur` nu — unique appelant confirmé `TableauBordScreen.js:983`). `ProfilPublicScreen.js` est attaché à un `utilisateur` (profil de confiance générique : avis + contact Message/Appel/Vidéo), aujourd'hui uniquement atteint côté client (`AccueilScreen.js`, pour consulter un transporteur) — **aucun chemin TR→profil de confiance client n'existe**, ni via l'un ni via l'autre écran. Combler ce manque serait un ajout de capacité (contact pré-acceptation), documenté pour décision future de Cedric, non fait dans ce lot. Confirme a posteriori que le mapping `profil_client_caarco` → `ProfilClientScreen.js` (D.2.4) était le bon.

**Composants** : `Etoiles` (6ᵉ/7ᵉ écran consommateur, `ProfilClientScreen.js`), `Sentier` (déjà rodé aux Lots 3/4/6/7/8, `ProfilClientScreen.js`, 1 usage ce lot-ci). `Echelon` évalué sur les 4 écrans, **non utilisé** (aucun besoin réel d'état à étapes nommées).

**Découverte maquette** : `profil_client_caarco` portait « TransLogix » dans son `<title>` (pas dans le `<h1>` visible) — corrigé, maquette activement réutilisée ce lot. Bloc « Avis Récents » + actions de contact + tag « Client Premium • Depuis 2021 » de la maquette non repris (D.15.5) : le premier est un ajout de capacité hors périmètre (voir clarification de redondance ci-dessus), le second n'a aucun support dans le modèle de données réel.

**i18n** : **0 nouvelle clé** — les 49 clés utilisées par les 4 écrans existaient déjà, vérifiées une par une comme résolvables. Parité vérifiée par import ESM réel (méthode corrigée ce lot-ci : un `require()` nu sur `fr.js`/`en.js`, en syntaxe `export const` ESM, échoue silencieusement dans cet environnement plutôt que de lever une erreur claire — piège méthodologique noté pour les sessions futures) : **1385 clés de chaque côté, 0 écart**, inchangé par cette passe.

**DoD vérifié sur les 4 fichiers modifiés** :
- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat) — 1 hex préexistant retokenisé (`MessagesTransporteurScreen.js`).
- i18n complet : confirmé, parité fr/en 1385/1385, 0 nouvelle clé.
- Contraste WCAG AA : aucune nouvelle combinaison hors des tokens déjà validés au Lot 0 ; `ProfilClientScreen.js` en palette statique de bout en bout, aucun risque du type D.11.5 ici.
- Aucune résurgence wallet/séquestre : confirmé par grep exhaustif (0 résultat) sur les 4 écrans et les services consommés (`services/courses.js`, `services/messages.js`, `services/tokensTC.js`). `course.methode_paiement`/`mode_paiement_client` : 0 occurrence, reconfirmé pour `CoursesTransporteurScreen.js` (le fichier n'a pas changé sur ce point depuis le Lot 8).
- Cible tactile ≥52px : aucun nouvel élément tactile introduit par ce lot.
- Validation syntaxique : `npx babel --presets babel-preset-expo` non retenté (panne d'outillage confirmée depuis le Lot 4, D.8.7 à D.14.7, toujours non réparée). Validation faite via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 4 fichiers modifiés : OK.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-10 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci pour confirmer que `CoursesTransporteurScreen.js` s'affiche désormais sans crash.

**Périmètre respecté** : aucun écran des Lots 1-10, 12-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 4 écrans ci-dessus + `vehicle_character_sheets/.../profil_client_caarco/code.html` (1 correction cosmétique) + ce fichier + le CDC (section D.15). Aucun fichier i18n modifié (0 nouvelle clé).

**Prochain lot recommandé : Lot 12 — Écrans partagés restants** (`ProfilPublicScreen.js`, `ChatScreen.js`, `MessagesScreen.js`, `CallScreen.js`, `EcranMaintenance.js`, `ContributionsCarteScreen.js` — mobilise `Echelon`, `Sillon`). Redondance `ProfilPublicScreen.js`/`ProfilClientScreen.js` désormais clarifiée (D.15.2) — ce lot peut être ouvert sans dépendance non résolue. Voir le prompt de session dédié fourni en fin de session.

---

## Lot 12 — Écrans partagés restants (clôturé le 09/07/2026)

**6 écrans traités, tous marqués fait** (2 non modifiés car déjà conformes). Détail complet en CDC D.16. Résumé :

| Écran | Traitement |
|---|---|
| `ProfilPublicScreen.js` | `Etoiles` local (hero) et rangée manuelle d'étoiles (avis) remplacés par le composant partagé `Etoiles.js` — gain réel pour les avis : demi-étoiles désormais rendues (`note_globale` peut valoir 4.5). **Résidu trouvé et corrigé, indépendant de toute maquette** : le bouton vidéo portait un style `btnWhatsApp` (bordure `'#25D366'`, vert de marque WhatsApp) alors qu'il déclenche un appel vidéo in-app (`CallScreen.js`/Jitsi), sans aucun rapport avec WhatsApp — voir découverte ci-dessous. Rangée d'actions restructurée en 3 boutons conformes à `profil_client_caarco` (« Contact Actions ») : Message (flex-1, plein, inchangé), **Appel désormais un bouton labellisé flex-1** (au lieu d'un carré icône seule), Vidéo (icône seule, 52×52, bordure `colors.foret` — la teinte WhatsApp supprimée). |
| `ChatScreen.js` | Déjà bien aligné sur `messagerie_caarco_2` (en-tête, bulles brume/bambouSoft, barre de saisie caméra/galerie/envoi). 1 hex en dur retokenisé (`'#e3ede5'` → `alpha(colors.bambou, 0.08)`, même substitution qu'aux Lots 9/11 pour une teinte de sélection quasi identique). |
| `MessagesScreen.js` (client) | Déjà bien aligné sur `messagerie_caarco_1` (liste de conversations, avatar+nom+heure+aperçu). 1 hex en dur retokenisé (`'#edf4ef'` → `alpha(colors.bambou, 0.08)`, même substitution que `MessagesTransporteurScreen.js` au Lot 11). Import mort préexistant `shadow` retiré. Barre de recherche de la maquette (littéralement commentée « Search / Filter Sillon » dans le `code.html`) **non ajoutée** — voir découverte ci-dessous. |
| `CallScreen.js` | Sans maquette (D.2.2). Déjà conforme au DoD avant ce lot (0 hex, i18n complet) — non modifié. |
| `EcranMaintenance.js` | Retint des accents de `colors.laterite` (Alertes/Erreurs) vers `colors.nere` (Accent) sur l'icône bouclier, son cercle et la bordure du bloc message — voir découverte ci-dessous. |
| `ContributionsCarteScreen.js` | Cibles tactiles `btnValider`/`btnValideOk` portées de 40px à 52px, `fab` (« Contribuer ») avec `minHeight: 52` ajouté (aucun des trois ne respectait la règle CLAUDE.md §5 avant ce lot). Consomme désormais `contributionTypes(t)` (voir `services/contributions.js` ci-dessous) au lieu de l'objet statique `TYPES_CONTRIBUTION`. |

### Découverte — `profil_transporteur_caarco` écarté comme référence pour `ProfilPublicScreen.js`

Contrairement à l'hypothèse de départ de cette session (« écran unique partagé, une maquette par rôle affiché », D.2.2), la lecture intégrale du `code.html` révèle que `profil_transporteur_caarco` n'est **pas** une variante-rôle du profil de confiance générique : c'est une fiche d'offre de transport pour une course précise (bento « Offre Proposée : 35 000 XAF » + « Détails du Véhicule » + « Récapitulatif du Trajet » + CTA « Choisir ce transporteur »), sans aucun bloc avis ni action de contact Message/Appel/Vidéo. Ce concept de marketplace à enchères (le client choisit parmi des offres de prix) ne correspond à aucun écran de l'inventaire D.2 — CAARCO fonctionne sur un modèle de matching automatique (`AttenteScreen.js`, Lot 4), pas de sélection manuelle d'offres tarifées. Cette maquette n'a donc servi à rien pour ce lot ; seul `profil_client_caarco` a été une référence structurelle réelle, et seulement pour son bloc hero + « Contact Actions » + « Avis Récents » (son bloc « Détails de la mission » avait déjà été consommé par `transporteur/ProfilClientScreen.js` au Lot 11, D.15.2/D.15.4). Même discipline que les découvertes des Lots 10 et 11 (D.14.5, D.15.4) : un nom de maquette cohérent avec un écran ne garantit pas une correspondance structurelle réelle.

### Découverte — résidu « WhatsApp » sur `ProfilPublicScreen.js`, et son faux précédent aux Lots 6/9

Le style `btnWhatsApp` (bordure `'#25D366'`) du bouton vidéo de `ProfilPublicScreen.js` a servi de précédent documenté au Lot 6 (`ParrainageScreen.js`, D.10) et re-cité au Lot 9 (`LeaderboardScreen.js`, D.13, commentaire sur les couleurs de médaille) comme exemple d'« exception de couleur de marque hors palette Atelier, déjà en usage identique ». Vérification faite ce lot-ci (lecture complète du fichier + de `CallScreen.js`) : ce bouton déclenche `ouvrirVideo()` → `navigation.navigate('Call', { muteVideo: false, ... })`, un appel vidéo **in-app via Jitsi Meet** (`CallScreen.js`, WebView `meet.jit.si`) — aucune ouverture de WhatsApp nulle part dans ce flux. Le nom et la couleur du style étaient donc un résidu trompeur, pas une exception légitime : contrairement à `ParrainageScreen.js` (bouton `logo-whatsapp` + `whatsapp://send?text=...`, un vrai partage WhatsApp, exception réellement fondée sur ses propres mérites), `ProfilPublicScreen.js` n'a jamais eu de fonctionnalité WhatsApp. Corrigé ce lot-ci (retiré, bouton vidéo repassé en bordure `colors.foret`) — **les 2 lots précédents qui ont cité ce cas comme précédent ne sont pas rouverts** (hors périmètre de cette session, D.13/D.10 déjà clos) ; leurs propres exceptions (WhatsApp réel sur `ParrainageScreen.js`, couleurs de médaille or/argent/bronze sur `LeaderboardScreen.js`) restent valides indépendamment de ce résidu, seule la phrase de justification qui pointait vers `ProfilPublicScreen.js` était inexacte.

### Découverte — barre de recherche des maquettes messagerie, jamais ajoutée (cohérence avec le Lot 11)

`messagerie_caarco_1` (`MessagesScreen.js`) contient un champ de recherche explicitement commenté « Search / Filter Sillon » dans son `code.html` — signal fort que ce composant du Lot 0 était originellement pensé pour cet usage. Malgré cela, non ajouté : filtrer une liste déjà chargée exige un nouvel état et une nouvelle logique, plus proche d'un ajout de fonctionnalité que d'un remplacement de composant visuel — exactement le raisonnement déjà tenu au Lot 11 pour `messagerie_transporteur_caarco`/`MessagesTransporteurScreen.js` (D.15.4), une maquette différente mais un même type de besoin. Pour rester cohérent avec la discipline « ne jamais ajouter de fonctionnalité dans une passe de refonte visuelle » déjà appliquée à 11 lots consécutifs, la même décision est reconduite ici plutôt que de céder à l'évidence du nom du composant dans le HTML. `Sillon` reste donc **jamais exercé en conditions réelles** dans ce chantier — candidat naturel pour une décision produit future de Cedric (recherche de conversation, sur les 2 écrans de messagerie à la fois).

### Découverte — teinte alerte sur `EcranMaintenance.js`, non conforme au ton rassurant de la maquette

La maquette `maintenance_en_cours_caarco` (déjà ✅, lue intégralement car servant de référence structurelle) est délibérément apaisante : fond forêt, icône bouclier pâle sur cercle presque noir, aucune touche rouge/orange, carte « Data Security Verified » rassurante. Le code réel utilisait `colors.laterite` (§5 CLAUDE.md : « Alertes / Erreurs / Annulation ») sur l'icône bouclier, son cercle et la bordure du bloc message — un vocabulaire de couleur qui contredit le message produit (« tout va bien, on fait juste de la maintenance »). Retinté en `colors.nere` (Accent), qui ne casse aucune combinaison de contraste existante (mêmes suffixes `+'20'`/`+'40'`, motif exempté de la règle zéro-hex).

### Composants

`Etoiles` (2 usages sur `ProfilPublicScreen.js`, hero + avis — remplace un doublon local et une boucle manuelle, gain net de demi-étoiles pour les avis). `Echelon` évalué sur les 6 écrans, **non utilisé** (aucun besoin réel d'état à étapes nommées — aucun de ces écrans n'a de flux multi-étapes). `Sillon` évalué, **besoin réel confirmé par la maquette de `MessagesScreen.js` mais délibérément non utilisé** (voir découverte ci-dessus, cohérence avec le Lot 11) — sauf sur `ContributionModal.js` (composant exclusivement consommé par `ContributionsCarteScreen.js`, hors des 6 écrans nommés mais indissociable de son flux) où 3 champs de saisie construits à la main (label + `TextInput`) ont été remplacés par `Sillon`, premier usage réel du composant dans ce chantier. **Extension additive sur `Sillon.js`** : prop `autoFocus` ajoutée (transmise au `TextInput` interne, défaut `false`) — nécessaire pour préserver le comportement `autoFocus` des 2 champs qui l'utilisaient, zéro impact sur les ~30 écrans déjà consommateurs de `Sillon` qui ne passent pas ce prop.

### `services/contributions.js` et `ContributionModal.js` — retouches hors des 6 écrans nommés, justifiées

Recherche exhaustive des mots-clés interdits sur `ContributionsCarteScreen.js` a mené à `services/contributions.js`, son unique service métier. Deux défauts réels y ont été trouvés, tous deux consommés exclusivement par `ContributionsCarteScreen.js` et `ContributionModal.js` (composant non listé parmi les 6 écrans mais rendu uniquement depuis `ContributionsCarteScreen.js`, donc traité dans le même geste, même principe que les extensions de composants partagés aux Lots 5/7/10) :
1. **4 hex en dur** (`TYPES_CONTRIBUTION.*.couleur`) correspondant exactement aux tokens `colors.laterite`/`colors.bambou`/`colors.nere`/`colors.foret` — retokenisés à l'identique (0 changement visuel).
2. **Libellés `label`/`ptsTxt` des 4 types de contribution codés en dur en français**, jamais passés par `t()`, affichés tels quels dans les 2 fichiers consommateurs — violent la règle i18n complet. `TYPES_CONTRIBUTION` transformé en fonction `contributionTypes(t)` (même patron que `onglets(t)` déjà utilisé dans `MessagesScreen.js`), 8 nouvelles clés ajoutées en miroir. `CATEGORIES_LIEU` (liste de catégories de lieu, ex. « Marché », « École ») **volontairement laissé en français non traduit** : ces valeurs sont envoyées telles quelles à la colonne `categorie_lieu` (TEXT libre, migration 076, sans contrainte CHECK) — les convertir en clés/slugs changerait le contrat de données stocké (anciennes lignes en français, nouvelles en slugs), un risque disproportionné pour un champ secondaire peu visible. Documenté comme écart i18n connu, non corrigé.

### `points_carte` — vérifié, mécanisme distinct du wallet bloqué (C.2 #3)

Le commentaire d'en-tête de `ContributionsCarteScreen.js » (« solde de points carte ») et celui de `services/contributions.js` (« Solde de points carte ») ont d'abord semblé être des faux positifs à la recherche du mot « solde » — vérifiés jusqu'à la migration 076 : `points_carte` est une colonne dédiée sur `users`, alimentée uniquement par les RPC `soumettre_contribution`/`valider_contribution` de ce même système de contributions cartographiques communautaires (routes fermées, lieux manquants, corrections d'adresse). Aucun lien avec les tables `wallets`/`transactions_wallet` du modèle séquestre aboli, ni avec le mécanisme de streak bloqué de `PointsScreen.js`/`MerciScreen.js` (C.2 #3, D.3.3) — deux systèmes de « points » homonymes mais entièrement indépendants dans le code et le schéma. Confirmé non concerné par le blocage C.2 #3.

### Découverte — `MessagesScreen.js` n'est pas à la racine de `screens/`

Contrairement à l'inventaire D.2/D.3.2 et au tableau ci-dessus (avant correction), le fichier réel est `App/src/screens/client/MessagesScreen.js` (seul importeur : `ClientNavigator.js`), pas `App/src/screens/MessagesScreen.js` à la racine. Aucune action de code nécessaire (l'écran a bien été traité), mais l'inventaire des écrans partagés doit être lu en gardant cette correction en tête pour toute session future qui s'y référerait.

### i18n

**9 nouvelles clés** : `profilPublic.appeler` (fr « Appel » / en « Call », libellé court du nouveau bouton d'appel) + 8 clés `contributionsCarte.type{RouteFermee,CorrectionAdresse,LieuManquant,ValidationLieu}{Label,Pts}` (labels et texte de points des 4 types de contribution, désormais traduits). Parité vérifiée programmatiquement par import ESM réel (`node --input-type=module`, méthode actée au Lot 11 après le piège `require()`) : **1394 clés de chaque côté, 0 écart** (1385 avant ce lot). Au passage, correction d'une coquille dans le texte source français : « Route fermée / barragée » (mot non standard) → « Route fermée / barrée ».

### DoD vérifié sur les 9 fichiers modifiés (`ProfilPublicScreen.js`, `ChatScreen.js`, `client/MessagesScreen.js`, `EcranMaintenance.js`, `ContributionsCarteScreen.js`, `services/contributions.js`, `components/ContributionModal.js`, `components/Sillon.js`, `fr.js`/`en.js`)

- Zéro hex/rgba en dur : confirmé par grep après correction (0 résultat pertinent) sur les 6 écrans et les 2 fichiers annexes — 6 hex préexistants retokenisés au total (1 `ChatScreen.js`, 1 `MessagesScreen.js`, 1 `ProfilPublicScreen.js` [WhatsApp], 4 `services/contributions.js`), 2 accents laterite→nere retintés sur `EcranMaintenance.js` (pas des hex en dur au sens strict, mais un vrai résidu sémantique corrigé). `CallScreen.js` confirmé déjà à 0.
- i18n complet : confirmé, parité fr/en 1394/1394, 9 nouvelles clés. 1 écart i18n documenté et non corrigé (`CATEGORIES_LIEU`, voir ci-dessus, risque de rupture du contrat de données jugé disproportionné).
- Contraste WCAG AA : aucune nouvelle combinaison hors des tokens déjà validés — `btnAppel` (fond `colors.brume`, texte `colors.charbon`) et `btnVideo` (bordure/icône `colors.foret` sur `colors.manioc`) reproduisent des contrastes déjà en usage ailleurs dans l'app ; le retint `EcranMaintenance.js` réutilise le même motif d'opacité (`+'20'`/`+'40'`) que l'original, seule la teinte change.
- Aucune résurgence wallet/séquestre : recherche exhaustive confirmée par grep (0 résultat réel) sur les 6 écrans et tous les services consommés (`services/messages.js`, `services/contributions.js`, `services/gps.js`, `services/courses.js` pour `obtenirCourse`) — 2 faux positifs vérifiés et écartés (commentaires « solde de points carte », mécanisme `points_carte` confirmé indépendant, voir ci-dessus). `course.methode_paiement`/`mode_paiement_client` : recherché explicitement sur les 6 écrans, 0 occurrence (aucun de ces écrans ne touche aux données de paiement d'une course).
- Cible tactile ≥52px : 3 vrais manquements trouvés et corrigés sur `ContributionsCarteScreen.js` (`btnValider`/`btnValideOk` 40→52px, `fab` `minHeight: 52` ajouté) ; les 3 boutons du pied de page de `ProfilPublicScreen.js` sont tous à 52px (2 déjà conformes, 1 nouveau bouton « Appel » construit à 52px d'emblée).
- Validation syntaxique : `npx babel --presets babel-preset-expo` **non retenté**, panne d'outillage confirmée sans interruption depuis le Lot 4 (D.8.7 à D.15.6) — validation faite directement via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 11 fichiers concernés (9 modifiés + `CallScreen.js` + `fr.js`/`en.js` inclus dans le compte) : **OK**, aucune erreur de parsing. Toujours signalé à Cedric.
- Captures avant/après (`scripts/capture-auto.ps1`) : **non exécuté**, même blocage que les Lots 0-11 (pas d'ADB/Maestro dans cet environnement d'agent). À faire par Cedric sur poste avec téléphone Android branché — particulièrement utile ce lot-ci pour valider visuellement la nouvelle rangée de 3 boutons de `ProfilPublicScreen.js` et le retint de `EcranMaintenance.js`.

### Périmètre respecté

Aucun écran des Lots 1-11 ni 13-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. Fichiers modifiés : les 4 écrans retouchés ci-dessus (`ProfilPublicScreen.js`, `ChatScreen.js`, `client/MessagesScreen.js`, `EcranMaintenance.js`) + `ContributionsCarteScreen.js` + `services/contributions.js` + `components/ContributionModal.js` + `components/Sillon.js` (extension additive) + `src/i18n/fr.js`/`en.js` (9 clés) + ce fichier + le CDC (section D.16). `CallScreen.js` non modifié (déjà conforme).

**Prochain lot recommandé : Lot 13 — Admin : tableau de bord & opérations** (`DashboardScreen.js`, `OperationsAdminScreen.js`, `CoursesEnCoursAdminScreen.js` — premier lot admin. `Borne`/`Silo`/`Fronton` sont déjà rodés côté client/transporteur (Lots 2/6/8/9) ; `Corridor` et `Passoire` (nav latérale desktop + recherche/filtres admin), en revanche, n'ont encore jamais été exercés hors de l'écran-catalogue dev-only — première mobilisation réelle à ce lot). Point de vigilance hérité du Lot 8 (D.12.2, jamais revérifié depuis) : `CoursesEnCoursAdminScreen.js` fait partie des écrans identifiés comme lisant potentiellement encore `course.methode_paiement` — à vérifier à l'ouverture avec la même méthode de grep exhaustif. Voir le prompt de session dédié fourni en fin de session.

---

## Lot 13 — Admin : tableau de bord & opérations (clôturé le 09/07/2026)

**Premier lot admin du chantier.** 3 écrans traités : 2 modifiés (`DashboardScreen.js`, `CoursesEnCoursAdminScreen.js`), 1 déjà conforme et non modifié (`OperationsAdminScreen.js`). Détail complet en CDC D.17. Résumé :

| Écran | Traitement |
|---|---|
| `DashboardScreen.js` | Déjà très aligné structurellement sur `tableau_de_bord_admin_caarco` (hero + grille KPI + graphique + alertes), voire plus riche (hero dédié CA/commission/taux/TR-online en plus de la grille 4 KPI). 11 hex en dur retokenisés (voir Contraste ci-dessous — 2 substitutions initiales corrigées après calcul de contraste réel). `Silo` (Lot 0, jamais réutilisé depuis son 1er usage au Lot 9) remplace le graphique horaire `GraphiqueHoraire` local — 2ᵉ usage réel, écran-preuve d'origine du composant (D.3.1 #5). Compromis documenté : perte du surlignage doré de l'heure courante (API `Silo` ne supporte pas de couleur par barre au sein d'une même série). |
| `CoursesEnCoursAdminScreen.js` | **Vigilance prioritaire confirmée fondée** : lisait `course.methode_paiement` (champ hérité migration 039, modèle séquestre aboli, valeurs `online/wallet/especes`) dans la requête source et 2 endroits du rendu — corrigé vers `course.mode_paiement_client` (migration 082, seul champ informatif autoritaire), même traitement qu'aux Lots 7/8 (D.11.7/D.12.2). `Passoire` (Lot 0, jamais exercé hors catalogue) remplace le champ de recherche construit à la main — correspondance structurelle directe (boîte bordée + icône + `TextInput` + bouton clear, quasi identique à l'existant). Barre d'onglets à compteurs (`ONGLETS`) conservée telle quelle — l'API `filtres` de `Passoire` ne porte pas de badge numérique, remplacer aurait fait perdre une information réelle. 2 hex en dur retokenisés. 2 boutons contextuels (`btnAssigner`/`btnDesassigner`, ~44px) portés à `minHeight: 52`. |
| `OperationsAdminScreen.js` | **Déjà conforme, non modifié.** Écran carte temps réel (`CarteLeaflet`) déjà bien aligné sur `op_rations_live_admin_caarco` (bandeau flottant + pilules stats + recherche + mini-cartes courses en scroll bas). 0 hex en dur, 0 résidu wallet/séquestre, 0 occurrence `methode_paiement`. Sa propre barre de recherche flottante (pilule translucide sur carte) correspond déjà à la maquette (recherche seule, sans filtres) — forcer `Passoire` (boîte opaque bordée par défaut) aurait dégradé l'esthétique flottante de la maquette sans gain fonctionnel. |

### Découverte majeure — `Corridor` structurellement redondant avec `AdminShell.js`, jamais utilisable dans ce chantier

`Corridor` (Lot 0, D.3.1 #8 : nav latérale fixe desktop, en-tête+liens+état actif) a été assigné par D.3.2 aux 6 lots admin (13-18). Première vérification réelle de son besoin à ce lot : les 20 écrans admin ne sont **jamais rendus seuls** — ils sont tous montés à l'intérieur de `App/src/screens/admin/AdminShell.js`, qui possède déjà sa **propre** sidebar responsive maison (`SidebarContenu` : logo+rôle, profil admin, sections de liens avec état actif et badges, drawer coulissant sur mobile, colonne fixe 220px sur desktop `width >= 768`, bouton déconnexion) — fonctionnellement un sur-ensemble de `Corridor` (sections groupées, badge, profil, historique de navigation, bouton retour Android). Les 3 écrans de ce lot reçoivent leurs props (`onMenu`, `onNaviguer`, `onRetour`) directement d'`AdminShell`, pas de nav autonome à construire. Utiliser `Corridor` à l'intérieur d'un de ces écrans créerait une **deuxième** barre latérale imbriquée dans la première — aucune des 3 maquettes ne montre ce doublon (chacune n'a qu'une seule sidebar). Conclusion : `Corridor` est un composant sans emploi possible dans ce chantier tel qu'`AdminShell.js` est architecturé aujourd'hui — vrai pour ce lot et, par construction, pour les 5 lots admin restants (14-18), puisque `AdminShell.js` enveloppe déjà les 20 écrans admin sans exception. `AdminShell.js` lui-même est hors périmètre de ce lot (assigné au Lot 18, « shell de navigation, pas un écran de contenu ») — non modifié.

### `Borne` et `Fronton` évalués sur `DashboardScreen.js`, non utilisés (motif réel, pas par défaut)

`Borne` : la grille KPI locale (`CarteKPI`) a une capacité réellement supérieure — sous-texte optionnel (« 20% des courses livrées », 2/4 cartes), bordure gauche accentuée par couleur, icône teintée par carte — que `Borne` ne supporte pas (icône toujours `bambouSoft`/`foret` fixe, pas de sous-texte, pas d'accent de bordure). Remplacer aurait perdu une information réelle déjà affichée. `Fronton` : le motif titre-mono-majuscule + « Voir tout → » existe déjà et est répété à l'identique sur 6 sections de l'écran (`sectionEntete`/`sectionTitre`/`voirTout`) ; `Fronton` impose une typographie de titre bien plus grande (`fonts.display`/`h3`) que ce motif compact — l'utiliser sur une seule des 6 sections aurait cassé la cohérence visuelle entre sections sœurs. Même discipline que `CarteStat`/Lot 9 (D.13) : motif local plus riche et déjà cohérent conservé plutôt que forcé.

### Contraste WCAG AA — risque détecté et corrigé avant introduction (même vigilance que D.11.5)

Première passe de retokenisation de `#5cd97d`/`#16a34a` (vert « en ligne » vif) → `colors.bambou` partout. Recalcul de contraste (formule WCAG relative luminance) sur les 3 usages posés directement sur le hero **toujours sombre** (`colors.nuit`, indépendant du thème clair/sombre de l'app) : `heroMetricVal` (TR online), `heroLiveDot`/`heroLiveTxt` — `colors.bambou` sur `colors.nuit` ne donne que **~3,0:1**, sous le seuil AA texte (4,5:1), alors que le hex d'origine donnait ~10,3:1. Corrigé avant validation vers `colors.bambouSoft` (déjà utilisé pour la métrique « Livrées » voisine sur ce même hero — précédent interne direct) : **~5,4:1**, conforme. Les usages **hors** du hero sombre (badge « LIVE » du bandeau filtres, pastille TR en ligne des cartes) restent `colors.bambou`/`colors.bambouSoft`, identiques au motif déjà en place (`onlineBadge`/`onlineDot`, ligne préexistante du même fichier) — aucun risque de contraste là, fond clair.

### Definition of done (D.2bis point 4) — vérification

- **i18n** : décision de portée actée avec Cedric à l'ouverture de ce lot — les 20 écrans admin n'ont **jamais** utilisé i18n (0 `t()`, 0 clé `admin.*` sur l'ensemble des 20 fichiers, contrairement aux écrans client/transporteur, 1394 clés/côté). Cohérent avec CLAUDE.md §1 (« Langue : Français uniquement V1 »). Décision : admin reste 100% texte français en dur, aucune clé nouvelle ajoutée, aucun retrofit sur le texte propre des écrans — **vaut pour ce lot et les 5 lots admin restants (14-18)**. Seules les clés déjà existantes des composants partagés (`passoire.rechercherDefaut`, `silo.aucuneDonnee`) sont mobilisées telles quelles par l'usage de `Passoire`/`Silo`. Parité vérifiée par import ESM réel : **1394/1394, 0 écart, 0 nouvelle clé** (inchangé depuis le Lot 12).
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 3 écrans — 11 hex retokenisés sur `DashboardScreen.js` (voir Contraste ci-dessus), 2 sur `CoursesEnCoursAdminScreen.js` (`#e8d0a0` → `colors.nere + '40'`, `#0f141173` → `colors.nuit + '73'`, motif suffixe exempté depuis les Lots 5/9/10). `OperationsAdminScreen.js` confirmé déjà à 0.
- **Contraste WCAG AA** : 1 risque réel détecté et neutralisé avant validation (voir ci-dessus) — 2ᵉ occurrence de ce type de vigilance dans le chantier après D.11.5 (Lot 7).
- **Aucune résurgence wallet/séquestre** : recherche exhaustive (`wallet|solde|séquestre|escrow|virement|retrait`) sur les 3 écrans et tous les fichiers consommés (`services/supabase.js`, `context/MaintenanceContext.js`, `components/PanneauDroit.js`) : 0 résultat. `course.methode_paiement`/`mode_paiement_client` : 1 vraie résurgence trouvée et corrigée sur `CoursesEnCoursAdminScreen.js` (voir ci-dessus) — dernier écran de la liste D.9.4/D.12.2 à contrôler, liste désormais soldée.
- **Cible tactile ≥52px** : 2 vrais manquements trouvés et corrigés (`btnAssigner`/`btnDesassigner` sur `CoursesEnCoursAdminScreen.js`, ~44px → `minHeight: 52`). Les icônes utilitaires de header (menu, rafraîchir, fermer) restent sous 52px sur les 3 écrans — convention déjà établie et jamais remise en cause sur les dizaines d'écrans déjà clos du chantier (y compris `AdminShell.js` lui-même, hors périmètre) ; seuls les boutons d'action primaire/contextuelle sont tenus au seuil, même lecture que le Lot 12 (D.16.11).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **non retenté**, panne confirmée sans interruption depuis le Lot 4 — validation via `@babel/parser` (mêmes plugins que d'habitude) sur les 3 écrans : **OK**, aucune erreur.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : vérifié comment les écrans admin sont réellement rendus/testés avant de présumer — même app Expo/React Native que le reste du chantier (pas un dashboard web séparé), routée vers `AdminShell.js` pour tout utilisateur `role='admin'` (`RootNavigator.js`), donc en théorie capturable par `capture-auto.ps1` avec un compte de test admin. **Blocage supplémentaire découvert, distinct de celui des Lots 0-12** : le flow Maestro unique exécuté par le script (`scripts/maestro/caarco_tous_ecrans.yaml`) ne contient **aucune** mention d'« admin » (0 résultat grep) — il ne visite aucun des 20 écrans admin, connexion admin y compris. Donc même avec un téléphone Android + ADB + Maestro disponibles, `capture-auto.ps1` ne capturerait à ce jour aucun des 3 écrans de ce lot tel quel : il faudrait un flow Maestro dédié (connexion admin + navigation `AdminShell`) avant de pouvoir l'utiliser pour les lots admin. Non exécuté (agent sans ADB, comme d'habitude) — signalé à Cedric comme 2ᵉ chantier d'outillage à part entière (en plus de la réparation de `npx babel --presets babel-preset-expo`).

### Premier bilan d'usage réel — `Corridor` et `Passoire`

`Corridor` : évalué en conditions réelles pour la première fois — conclusion négative et définitive pour ce chantier (redondance architecturale avec `AdminShell.js`, voir découverte ci-dessus), pas un simple « pas besoin sur cet écran précis » comme les précédents Echo/Echelon/Silo. `Passoire` : évalué en conditions réelles pour la première fois — 1 usage réel confirmé (`CoursesEnCoursAdminScreen.js`, remplacement direct d'un champ de recherche déjà quasi identique), 2 non-usages documentés avec raison propre (`DashboardScreen.js` : aucune recherche n'existe ; `OperationsAdminScreen.js` : recherche déjà existante mais en pilule flottante sur carte, incompatible avec le style boîte-bordée par défaut de `Passoire` sans dénaturer la maquette). Aucun défaut d'API trouvé sur `Passoire` — sa signature (`valeurRecherche`, `onChangerRecherche`, `placeholderRecherche`, `filtres`, `onChangerFiltre`, `onReinitialiser`) a fonctionné sans extension nécessaire pour son unique usage.

### Périmètre respecté

Aucun écran des Lots 1-12 ni 14-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. `AdminShell.js` (Lot 18) lu mais non modifié. Fichiers modifiés : `DashboardScreen.js`, `CoursesEnCoursAdminScreen.js` + ce fichier + le CDC (section D.17). `OperationsAdminScreen.js` non modifié (déjà conforme). Aucune clé i18n ajoutée (`fr.js`/`en.js` non modifiés).

**Lot suivant traité : Lot 14 — Admin : utilisateurs** (voir compte-rendu ci-dessous et CDC D.18).

---

## Lot 14 — Admin : utilisateurs (clôturé le 09/07/2026)

**3 écrans traités, tous marqués fait.** Détail complet en CDC D.18. Résumé :

| Écran | Traitement |
|---|---|
| `admin/UtilisateursScreen.js` | Réécriture complète sur `gestion_des_utilisateurs_admin` (mapping direct confirmé, D.2.5) : passage d'une simple liste sans détail à un vrai master-detail — `Passoire` (recherche + filtre rôle en chips) + rangée de pilules statut séparée (2 dimensions de filtre, l'API `filtres` de `Passoire` ne portant qu'une seule dimension) + `PanneauDroit` bento (avatar XL, statut, stats Courses/Note, section Documents KYC via `Pochette` pour les transporteurs uniquement, actions Suspendre/Réactiver + Contacter). Items de liste enrichis d'un badge statut (point coloré, absent avant ce lot). |
| `admin/ClientsAdminScreen.js` | Écran déjà mature avant ce lot (PanneauDroit, KPIs, reset/suppression) — pas de refonte de mise en page, greffe ciblée : bloc recherche + 3 pilules statut construits à la main remplacés par un seul `<Passoire>` (recherche + `filtres`). Nettoyage : ~40 lignes de styles morts supprimées (bloc "étape de confirmation" jamais rendu, `modalFond`/`modalCarte` residus d'une implémentation pré-`PanneauDroit`), import `TextInput` devenu inutile retiré. |
| `admin/TransporteursAdminScreen.js` | Même traitement : recherche + 4 pilules KYC remplacées par `<Passoire>`. **Ajout réel** : section "Documents KYC" (via `Pochette`, lecture seule) dans le panneau détail — absente du code avant ce lot alors que la maquette de référence du lot (attribuée à `UtilisateursScreen.js`) la montre explicitement pour un profil transporteur ; comble un vrai manque, pas une simple parité visuelle. **Bug réel trouvé et corrigé** : la requête liste ne sélectionnait jamais `note_moyenne`, alors que `ModalDetail` l'affichait déjà (`tr.note_moyenne ? …toFixed(1) : ''`) — la tuile "Note moy." était donc systématiquement vide pour 100 % des transporteurs, sur les deux variantes de la requête (principale + repli). Corrigé en ajoutant `note_moyenne` (et `cni_url, permis_url` pour les documents) aux deux `select()`. |

### Composants — bilan d'usage réel

`Passoire` : 3/3 usages réels confirmés ce lot-ci (recherche seule sur `UtilisateursScreen.js` combinée à des filtres rôle en chips ; recherche + filtre statut sur `ClientsAdminScreen.js` ; recherche + filtre KYC sur `TransporteursAdminScreen.js`), chaque fois en remplacement direct d'un bloc recherche/filtre déjà quasi identique construit à la main — aucune extension d'API nécessaire. Limite réelle rencontrée et documentée : l'API `filtres` ne porte qu'une seule dimension de filtre (un tableau plat de chips) ; `UtilisateursScreen.js` a besoin de 2 dimensions indépendantes (rôle + statut, conformes à la maquette qui montre 2 `<select>` distincts) — `Passoire` porte le rôle, une rangée de pilules manuelle (même style que celles déjà utilisées dans `ClientsAdminScreen.js`/`TransporteursAdminScreen.js` avant ce lot) porte le statut. Pas un défaut de `Passoire`, une limite de conception à connaître avant de l'assigner à un écran à filtres multi-dimensionnels.

`Corridor` : conclusion du Lot 13 reconfirmée en une phrase à l'ouverture (redondant avec la sidebar d'`AdminShell.js`, qui enveloppe les 20 écrans admin) — non réanalysé en détail, non utilisé.

`Echelon` : évalué sur les 3 écrans, non utilisé. Aucun des 3 ne présente de séquence linéaire à étapes nommées (fait/actif/à venir) — les statuts affichés (compte actif/suspendu, KYC approuvé/en attente/rejeté/infos manquantes) sont catégoriels ou à embranchements, pas une progression, et sont déjà servis correctement par des badges (`Cachet`, badges locaux `dtBadge`/`statutBadge`). Même discipline que D.9.3/D.11.6 : composant assigné par D.3.2, vérifié, écarté par manque de besoin réel plutôt qu'imposé.

### Vigilance wallet/séquestre — recherche exhaustive, aucun résidu trompeur trouvé

Grep `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` (insensible à la casse) sur les 3 écrans : 3 occurrences, toutes vérifiées et jugées saines, aucune corrigée :
- `ClientsAdminScreen.js`/`TransporteursAdminScreen.js` : copie "…portefeuille remis à 0 FCFA" dans la confirmation du bouton "Remettre à zéro". Vérifié jusqu'à la migration : `admin_reset_compte` (migration 038) lit et écrit réellement les tables `wallets`/`transactions_wallet`. La copie est donc **exacte**, pas trompeuse (contrairement au badge "Wallet" du Lot 5, D.9.4, qui affichait un libellé faux) — sanitiser le texte sans toucher au RPC aurait masqué un comportement réel au lieu de le corriger. Architecture déjà entièrement documentée en C.3.2 (tables `wallets`/`transactions_wallet` orphelines, purge à trancher par Cedric, hors périmètre design) — non retouchée, conforme à la consigne de ne pas toucher aux corrections backend.
- `TransporteursAdminScreen.js` : `notifierAvecTemplate(id, 'credit_wallet', …)` pour le crédit TC admin. La clé `cle = 'credit_wallet'` en base est un nom résiduel, mais son contenu réel (`notification_templates`, migration 072 puis corrigé migration 083) est déjà sain : *"{salutation} {nom} ! {montant} ont été crédités sur votre compte CAARCO."* — plus aucune mention de "wallet" ni d'unité FCFA forcée, `{montant}` reçoit déjà l'unité correcte (`"X TC"`) depuis l'appelant. Même famille que le piège de nom `RetraitsAdminScreen.js` (D.2.5) : le nom interne trompe, le comportement réel est propre — non renommé (renommer la clé exigerait une migration DB, hors périmètre design de ce lot).

### Distinction "Créditer TC (admin)" vs `admin_crediter_wallet_client` — reconfirmée

Vérifiée par grep + lecture des migrations, pas présumée acquise : le modal "Créditer TC (admin)" de `TransporteursAdminScreen.js` appelle `admin_crediter_tc` (migration 082, protection `is_admin()` ajoutée migration 085 — RPC distincte, déjà correctement protégée). `admin_crediter_wallet_client` (migration 037, la faille 🔴 documentée en C.3.2) reste **non référencée** dans les 3 écrans de ce lot (grep : 0 résultat) — la distinction actée en D.2.5 tient toujours.

### Definition of done (D.2bis point 4) — vérification

- **i18n** : décision de portée du Lot 13 reconduite (admin 100 % français en dur, aucun retrofit) — **0 nouvelle clé**. Parité vérifiée par import ESM réel (`node --input-type=module`) : **1394/1394, 0 écart**, inchangé depuis le Lot 13.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat sur les 3 écrans) — 2 hex retokenisés sur `TransporteursAdminScreen.js` (`'#0f141180'` → supprimé avec le style mort `modalFond` qui le portait ; `'#0f14118c'` → `alpha(colors.nuit, 0.55)`, équivalence exacte à l'octet près : `Math.round(0.55*255)=140=0x8c`) ; `ClientsAdminScreen.js` : 1 hex supprimé avec le style mort `modalFond`. `UtilisateursScreen.js` (réécriture complète) : 0 hex introduit.
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 3 écrans (pas de hero sombre façon `DashboardScreen.js`) — calcul de contraste non applicable, vigilance quand même vérifiée par relecture (badges/pilules réutilisent des combinaisons déjà validées ailleurs : `bambouSoft`/`bambou`, `lateriteSoft`/`laterite`).
- **Aucune résurgence wallet/séquestre trompeuse** : voir section dédiée ci-dessus — 3 occurrences trouvées, toutes vérifiées saines (copie exacte ou déjà assainie par une migration antérieure), aucune corrigée car aucune n'était fausse.
- **Cible tactile ≥52px** : plusieurs manquements réels trouvés et corrigés — `btnAction` (`ClientsAdminScreen.js`), `dtBtnPrimaire`/`dtBtnSec`/`dtBtnDanger` (`TransporteursAdminScreen.js`) passés de `paddingVertical` seul à `minHeight: 52` ; `creditBtnAnn`/`creditBtnOk` (modal crédit TC) passés de `height: 44` à `height: 52`. `UtilisateursScreen.js` : `btnAction` construit directement à 52px. Icônes utilitaires de header sous 52px non retouchées (convention déjà établie, non remise en cause).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **retenté** (pour re-confirmer, pas juste supposé) — échoue toujours, même erreur `Unexpected token` sur du JSX simple non lié à ce lot, panne d'outillage ininterrompue depuis le Lot 4 (D.8.7), **toujours non réparée** — à signaler de nouveau à Cedric. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 3 fichiers : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que le Lot 13 (pas d'ADB/Maestro dans cet environnement d'agent, et le flow Maestro `caarco_tous_ecrans.yaml` ne visite toujours aucun écran admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné.

### Découverte hors périmètre visuel, non corrigée — `admin_reset_compte` touche réellement `wallets`/`transactions_wallet`

Non nouvelle (déjà en C.3.2), reconfirmée à l'ouverture de ce lot par lecture de la migration 038 : la RPC `admin_reset_compte`, appelée par les boutons "Remettre à zéro" de `ClientsAdminScreen.js` et `TransporteursAdminScreen.js`, lit et écrit réellement `wallets.solde_fcfa` et insère dans `transactions_wallet`. Ce n'est **ni un des 2 correctifs 🔴 urgents** (trigger `after_course_terminee`, RPC `admin_crediter_wallet_client`) **ni un défaut caché** — c'est une conséquence assumée du fait que ces tables ne sont pas encore purgées (décision Cedric en attente, C.3.2 ligne 514 : « peut être purgé dans une migration de nettoyage classique »). Aucune action de code prise (backend hors périmètre de ce lot) ; mentionné ici pour que la prochaine session n'ait pas à redécouvrir le lien entre la copie "portefeuille" et le comportement réel de la RPC.

### Périmètre respecté

Aucun écran des Lots 1-13 ni 15-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée (ni la 3ᵉ trouvée-mais-déjà-connue ci-dessus), `AdminShell.js` (Lot 18) non modifié. Fichiers modifiés : `UtilisateursScreen.js` (réécriture complète), `ClientsAdminScreen.js`, `TransporteursAdminScreen.js` + ce fichier + le CDC (section D.18). Aucune clé i18n ajoutée (`fr.js`/`en.js` non modifiés).

**Prochain lot recommandé : Lot 15 — Admin : KYC & litiges** (`KYCValidationScreen.js`, `LitigesScreen.js` — mobilise `Pochette`, déjà rodé aux Lots 10 et 14, et `Corridor`, dont la conclusion structurelle du Lot 13 s'applique d'office). Voir le prompt de session dédié fourni en fin de session.

---

## Lot 15 — Admin : KYC & litiges (clôturé le 09/07/2026)

**2 écrans traités, tous marqués fait.** Détail complet en CDC D.19. Résumé :

| Écran | Traitement |
|---|---|
| `admin/KYCValidationScreen.js` | La grille `DocCard` locale (6 tuiles : CNI, Permis, Véhicule×2 codés en dur, Carte grise, Assurance — image statique + pastille de statut, **sans zoom**) est remplacée par 5 sections labellisées (Identité/Permis/Véhicule/Carte grise/Assurance, à l'image du bento `validation_kyc_admin`), chacune enveloppant `Pochette` (zoom plein écran réel, absent avant ce lot) tout en conservant la pastille de statut (Présent/À vérifier/Manquant) à côté du titre de section plutôt que dans `Pochette` elle-même. **Bug latent corrigé au passage** : la section Véhicule ne lisait jamais que `vehicule_url[0]`/`[1]` codés en dur, quel que soit le nombre réel de photos soumises (`vehicule_url` est un `TEXT[]`) — désormais alimentée par le tableau complet via la galerie `Pochette`. `JaugeValidite` (jauge de validité par document, non assignée à ce lot) conservée telle quelle, seul son 2ᵉ palier de couleur retokenisé (voir DoD). |
| `admin/LitigesScreen.js` | Déjà structurellement conforme à `gestion_des_litiges_admin` (liste de litiges + panneau de décision via `PanneauDroit`, déjà en place avant ce lot). Nettoyage DoD : import `Modal` mort (jamais rendu, `PanneauDroit` gère son propre `Modal` en interne) et styles `modalFond`/`modalContenu` résiduels (portaient le seul hex en dur du fichier) supprimés. `Corridor` non intégré (voir ci-dessous). |

### Pochette — besoin réel vérifié, usage confirmé mais pas par simple substitution

Conformément à la consigne d'ouverture, le besoin de `Pochette` sur `KYCValidationScreen.js` a été vérifié plutôt que présumé acquis malgré la précédente de 3 usages (Lots 10/14). Deux écarts réels trouvés entre le rôle de `Pochette` et le besoin de cet écran précis :
1. `Pochette` ne porte aucune notion de statut par fichier (Présent/À vérifier/Manquant) — or cette information est ici décisive pour la décision d'approbation, pas un simple affichage secondaire comme au Lot 14 (`ClientsAdminScreen`/`TransporteursAdminScreen`, contexte de consultation, pas de décision).
2. `Pochette` est une galerie **horizontale défilante** — la maquette (et le code existant) montre une **grille** de sections labellisées (Identité/Permis/Véhicule), pas un carrousel unique de 6 vignettes qui masquerait les dernières pièces sans swipe.
Plutôt que d'étendre l'API de `Pochette` (utilisée telle quelle par 4 autres écrans, aucune extension nécessaire jusqu'ici) ou de renoncer à son vrai apport (le zoom, absent du code existant et pourtant montré explicitement dans les 2 maquettes KYC via l'icône `zoom_in`), la pastille de statut a été déplacée **à côté de `Pochette`** (portée par l'écran, pas par le composant partagé) et chaque type de pièce reçoit sa propre section — réutilisation réelle et vérifiée, pas une extension d'API spéculative. Conclusion : `Pochette` confirmé comme le bon choix pour la partie image+zoom, mais la conclusion "quasi acquise" annoncée en ouverture ne valait que pour cette partie-là, pas pour l'écran entier tel quel.

### `Corridor` — conclusion du Lot 13 reconfirmée en une phrase

Redondant avec la sidebar d'`AdminShell.js` (D.17.3, reconfirmé D.18.8) — non réanalysé en détail, non intégré sur les 2 écrans de ce lot.

### Maquette `gestion_des_litiges_admin` — deux éléments visuels non reproduits, vérifiés avant d'écarter

1. **Distinction "Urgent"/"En attente"** (bordure et badge colorés par carte) : vérifiée jusqu'au schéma réel — `courses` ne porte aucune colonne d'urgence/priorité (grep sur toutes les migrations, seul `bonus_urgence_fcfa` existe et concerne les missions planifiées, sans rapport). La distinction de la maquette est un artefact des données d'exemple Stitch, pas une capacité réelle du modèle de données — non reproduite pour ne pas inventer une classification que l'app ne peut pas réellement calculer.
2. **Carte "Résolu"** (litige historique, opacité réduite, bouton "Voir l'historique") : les données existent (`statut` terminee/annulee + `motif_litige`), mais aucun écran de détail d'historique de litige n'existe dans l'app pour servir de cible à ce bouton — même catégorie d'omission que le lien "Contacter l'assistance" du Lot 1 (D.5) : un lien mort aurait été pire qu'une omission. Non reproduite.

### Vigilance wallet/séquestre — recherche exhaustive sur les 2 écrans et les RPC/services consommés, aucun résidu trouvé

Grep `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 2 écrans : **0 résultat** (contrairement aux Lots 13/14, aucune occurrence même saine à documenter). Vérifié également au-delà du texte visible, jusqu'aux RPC/migrations réellement appelées :
- `valider_kyc` (définie dans `fix_securite.sql`, hors dossier `supabase/migrations/`) : lue intégralement — `SECURITY DEFINER`, vérifie `role = 'admin'` côté serveur avant toute écriture, ne touche que `transporteurs_kyc`/`users` (statut, kyc_valide). Aucune table wallet.
- Résolution de litige (`LitigesScreen.js`) : `courses.update({ statut, motif_litige })` en appel direct (pas de RPC dédiée) — aucun champ financier touché.
- Template de notification `litige_resolu` (migration 072) : contenu vérifié, aucune mention financière ni wallet.

### Definition of done (D.2bis point 4) — vérification

- **i18n** : décision de portée des Lots 13/14 reconduite (admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé. Parité vérifiée par import ESM réel : **1394/1394, 0 écart**, inchangé depuis le Lot 13.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat sur les 2 écrans) — `'#e8780a'` (palier intermédiaire de `JaugeValidite`, `KYCValidationScreen.js`) fusionné dans `colors.laterite` (voir ci-dessous) ; `'#0f14118c'` supprimé avec les styles morts `modalFond` qui le portaient (`LitigesScreen.js`).
- **Palette à 3 tons officiels reconfirmée** : `JaugeValidite` utilisait un 4ᵉ ton non tokenisé (`#e8780a`, orange vif) pour le palier "expire sous 30 jours", distinct de `laterite`/`nere`/`bambou`. Aucun ton "avertissement" dédié n'existe dans `theme.js` (Section 5 CLAUDE.md = source de vérité unique) — plutôt que d'inventer une nouvelle couleur de marque, le palier "≤30 jours" a été fusionné avec le palier "expiré" sous `colors.laterite` (même sévérité réelle : un document expirant sous 30 jours empêche bientôt le transporteur d'opérer légalement, au même titre qu'un document déjà expiré). Les 4 messages textuels (jours exacts) sont conservés à l'identique, seule la couleur du palier intermédiaire change.
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 2 écrans (pas de hero sombre) — non applicable, vigilance vérifiée par relecture.
- **Aucune résurgence wallet/séquestre** : voir section dédiée ci-dessus — 0 occurrence, RPC/template vérifiés jusqu'à la source.
- **Cible tactile ≥52px** : 2 manquements réels trouvés et corrigés — `btnCorrections`/`btnRefuser`/`btnValider` (`KYCValidationScreen.js`, 46px→52px) et `btnDecision` (`LitigesScreen.js`, boutons Annuler/Valider la course, 50px→52px). Icônes utilitaires de header (menu, fermer) non retouchées (convention déjà établie).
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **retenté** sur `KYCValidationScreen.js` — échoue encore, même `Unexpected token` sur du JSX/optional chaining non lié à ce lot, panne ininterrompue depuis le Lot 4 (D.8.7), **toujours non réparée**, signalée de nouveau à Cedric. Validation via `@babel/parser` (plugins `jsx`, `optionalChaining`, `nullishCoalescingOperator`, `classProperties`, `objectRestSpread`) sur les 2 fichiers : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13/14 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné.

### Bilan d'usage réel — `Pochette` (4ᵉ usage)

Confirmé utile et réellement nécessaire (comble un vrai manque de zoom vs. les 2 maquettes), mais **premier cas où son usage n'est pas une simple substitution 1:1** : les 3 usages précédents (Lots 10/14) l'appelaient tel quel sans adaptation. Ici, la pastille de statut par pièce (information réellement décisive pour ce flux d'approbation KYC) a dû être portée par l'écran plutôt que par le composant, faute d'un concept de statut dans son API — pas un défaut de `Pochette` (ses 4 autres appelants n'en ont pas besoin), mais une limite réelle à connaître avant de l'assigner à un futur écran de décision similaire. Bonus réel : la section Véhicule expose maintenant tout le tableau `vehicule_url`, pas seulement 2 index codés en dur.

### Périmètre respecté

Aucun écran des Lots 1-14 ni 16-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 de la Partie C touchée. `AdminShell.js` non modifié. Fichiers modifiés : `KYCValidationScreen.js`, `LitigesScreen.js` + ce fichier + le CDC (section D.19). Aucune clé i18n ajoutée.

**Prochain lot recommandé : Lot 16 — Admin : finances & tarifs** (`FinancesAdminScreen.js`, `RetraitsAdminScreen.js`, `ConfigTarifsScreen.js` — mobilise `Borne`/`Silo`, déjà rodés côté transporteur ; `Corridor` de nouveau assigné par D.3.2, conclusion architecturale toujours d'office non favorable ; `RetraitsAdminScreen.js` porte un piège de nom déjà neutralisé D.2.5, ne jamais le rapprocher de `retrait_de_gains*`). Voir le prompt de session dédié fourni en fin de session.

---

## Lot 16 — Admin : finances & tarifs (clôturé le 09/07/2026)

**3 écrans traités : 1 modifié en profondeur (`FinancesAdminScreen.js`), 1 nettoyage mineur seulement (`ConfigTarifsScreen.js`), 1 déjà conforme (`RetraitsAdminScreen.js`).** Détail complet en CDC D.20. Résumé :

| Écran | Traitement |
|---|---|
| `admin/FinancesAdminScreen.js` | Maquette `finances_tokens_tc_admin` lue intégralement : bento 3 KPIs + graphique en barres "Évolution des Ventes TC" (2 séries, 4 semaines) + panneau "Alertes Solde". Le code réel avait déjà 4 KPI cards (Commission TC/TC vendues/Volume courses/TR solde bas) et le bloc alertes — mais **aucun graphique** : écart réel confirmé face à la maquette, comblé par `Silo` (1 nouvelle requête indépendante des pilules période, 28 derniers jours de `transactions_tc`, bucketés en 4 barres hebdomadaires achat/commission). `Borne` évalué sur la grille KPI, **non utilisé** (voir découverte ci-dessous). `Corridor` non intégré (redondant avec `AdminShell.js`, conclusion Lot 13 reconfirmée). Nettoyage : import mort `shadow` retiré. |
| `admin/RetraitsAdminScreen.js` | Piège de nom neutralisé (D.2.5) confirmé en lisant le fichier réel : titré "Tokens de Course", solde TC des transporteurs par onglet (achats/commissions/soldes), commentaire ligne 13 explicite ("les retraits n'existent plus dans le système TC"). Aucune maquette. `Borne` et `Silo` évalués, **non utilisés** (voir ci-dessous). Écran déjà conforme au DoD — seul le même import mort `shadow` retiré. |
| `admin/ConfigTarifsScreen.js` | Maquette `configuration_des_tarifs_admin` lue intégralement : bento tarifs/km par véhicule + section "Règles Globales" (frais fixes + majoration nuit) + Enregistrer/Annuler. Le code réel est structurellement plus riche que la maquette (charge utile poids/volume, commission parrainage, paramètres fixes, zone danger reset dev) — rien retiré. Corrections DoD réelles : fallback tautologique `fontSize.xxs ?? 10` simplifié, import mort `shadow` retiré, 4 boutons d'action sous 52px portés à 52px (`btnSauvegarder`, `comBtnSauv` partagé par les 2 boutons Enregistrer commission/nuit, `resetBtn`, `resetBtnAnnuler`/`resetBtnConfirmer` 48→52). **2 découvertes backend significatives, non corrigées** (voir ci-dessous). |

### Découverte 1 — section "Commission parrainage" de `ConfigTarifsScreen.js` : édite un taux mort

Vérifié jusqu'à la migration réelle (pas seulement le texte de l'écran) : `commission_parrainage_pct` (`configurations_systeme`) n'est lu que par `liberer_sequestre_course()` (migrations 032, 059, 060 — 3 versions successives, toutes lisent la même clé). Cette RPC est la même chaîne déjà confirmée **inatteignable** en C.3.2/D.10.5 (accessible uniquement via `terminer_livraison()`, jamais appelée dans `App/src` — seul `confirmer_livraison()` → `debiter_commission_tc()` est actif, et ne référence ni `parrain` ni `commissions_parrainage`, grep confirmé). Conséquence : un admin peut modifier ce pourcentage, voir le toast "Commission parrainage mise à jour", sans que cela n'affecte jamais un centime de commission réellement distribuée aujourd'hui — même défaut structurel que `ParrainageScreen.js` (Lot 6, D.10.5), découvert cette fois depuis l'écran de configuration plutôt que depuis l'écran d'affichage client. Le texte de l'écran n'est pas trompeur en soi (le champ fait ce qu'il dit — configurer un taux de commission parrainage — juste que rien en aval ne le consomme) : pas un cas de "sanitizer un texte qui décrit un comportement réel" (méthode D.18.5/D.19.7), donc **texte non modifié**. Corriger nécessiterait de rebrancher ce taux sur `debiter_commission_tc()` (backend, décision Cedric) — hors périmètre visuel de ce lot, non corrigé, ajouté à la liste des corrections backend en tête de fichier.

### Découverte 2 — section "Charge utile" de `ConfigTarifsScreen.js` : édite des colonnes qui n'existent pas et que le moteur de prix n'utilise pas

Le code défensif de `charger()` ("Si les colonnes n'existent pas encore, on recharge sans elles") a été vérifié plutôt que pris pour une simple prudence de développeur : recherche exhaustive de `poids_max_kg`/`volume_max_m3` sur tout `App/supabase/migrations` → **0 résultat**, ces colonnes n'existent dans aucune migration de `parametres_tarifs` (seules `vehicule`/`tarif_km`/`frais_fixes`/`updated_at` y sont créées, migration 025). Plus significatif : même si elles existaient, `calculer_prix()` — vérifiée dans ses 3 versions (025, 026, 097, la dernière étant active) — calcule `v_seuil_poids`/`v_seuil_volume` via un `CASE p_type_vehicule` **codé en dur** dans la fonction SQL, jamais lu depuis `parametres_tarifs`. La section "Charge utile" de l'écran est donc purement cosmétique aujourd'hui : les champs se chargent toujours vides, et une tentative de sauvegarde échouerait (colonne inexistante), sans aucun lien avec le moteur de tarification réel (§12 CLAUDE.md, "Calculé côté serveur uniquement"). Non corrigé (créer les colonnes + rebrancher `calculer_prix()` est une migration schéma, décision Cedric) — ajouté à la liste des corrections backend en tête de fichier.

### `Borne` — évalué sur les 2 écrans à KPIs, non utilisé sur aucun des deux

- `FinancesAdminScreen.js` : la grille de 4 `Plaquette`-KPI locales code chaque tuile avec une couleur d'icône/valeur **différente et significative** (nere=commission, bambou=ventes, foret=volume, laterite=alerte) — `Borne` impose une icône `colors.foret`/fond `colors.bambouSoft` fixes sur ses 3 usages réels vérifiés (`RevenusScreen.js`, `ParrainageScreen.js`, aucun ne passe de couleur variable). Remplacer aurait fait perdre le codage couleur par catégorie de KPI, qui est une information réelle sur cet écran (permet de repérer l'alerte rouge d'un coup d'œil). Même discipline que `CarteKPI`/`DashboardScreen.js` (D.17.5) et `CarteStat`/`StatsTransporteurScreen.js` (D.13.3) : motif local plus riche conservé.
- `RetraitsAdminScreen.js` : les 3 `resumeCard` (Vendus/Commissions/En alerte) sont des chips à **fond teinté plein** (bambouSoft/nereSoft/lateriteSoft), **sans icône** — `Borne` impose l'inverse (fond blanc fixe + bloc icône obligatoire). Ni un remplacement direct ni une extension à coût nul n'étaient possibles sans changer le langage visuel de ce résumé compact. Non utilisé, motif différent plutôt que plus pauvre — même conclusion que les précédents.

### `Silo` — 1 usage réel confirmé, 1 non-usage documenté

`FinancesAdminScreen.js` : écart réel confirmé contre la maquette (`finances_tokens_tc_admin` montre explicitement un graphique 2 séries "Ventes/Commissions" sur 4 semaines, absent du code) — 2ᵉ preuve directe de la liste D.3.1 #5 après `DashboardScreen.js` (Lot 13) et `StatsTransporteurScreen.js` (Lot 9). `RetraitsAdminScreen.js` : aucune maquette pour justifier un besoin, et la structure à 3 onglets (transactions + soldes) ne présente aucune dimension temporelle à visualiser en graphique — non utilisé, absence de besoin réel plutôt qu'oubli.

### `Corridor` — conclusion des Lots 13-15 reconfirmée en une phrase, non réanalysée

Toujours redondant avec la sidebar d'`AdminShell.js` (D.17.3, reconfirmé D.18.8/D.19.4) — non intégré sur les 3 écrans de ce lot, conformément à la consigne de ne pas rouvrir l'analyse complète.

### Vigilance wallet/séquestre — recherche exhaustive sur les 3 écrans et les services/RPC consommés

Grep `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 3 écrans : toutes les occurrences trouvées portent sur `solde_tc` (solde de jetons TC des transporteurs, "Solde actuel"/"Solde insuffisant"/"TR solde bas") — **aucune résurgence wallet/séquestre**, y compris le commentaire "les retraits n'existent plus dans le système TC" de `RetraitsAdminScreen.js:13`, qui décrit fidèlement l'architecture actuelle (non modifié, méthode D.18.5). Vérifié au-delà du texte visible jusqu'aux migrations réellement consommées par ce lot : `transactions_tc`/`users.solde_tc` (082/085, déjà confirmées propres aux Lots 8/9), `parametres_tarifs`/`calculer_prix` (025/026/097) et `configurations_systeme` (032) — ces deux derniers ont produit les Découvertes 1 et 2 ci-dessus, ni l'une ni l'autre n'étant une résurgence wallet au sens strict (aucune écriture dans `wallets`/`transactions_wallet` déclenchée par ces 3 écrans), mais des configurations mortes/déconnectées du moteur réel. `remise_a_zero_totale()` (migration 066, appelée par la zone danger de `ConfigTarifsScreen.js`) lue intégralement : contrôle de rôle admin serveur confirmé présent (contrairement à `admin_crediter_wallet_client`), mais **ne réinitialise ni `transactions_tc` ni `users.solde_tc`** alors que le texte de l'écran promet d'effacer "tokens TC" — écart fonctionnel réel, non corrigé ici (modification de migration, hors périmètre visuel), à signaler à Cedric si le bouton de reset doit un jour redevenir fiable pour les tests TC.

### Definition of done (D.2bis point 4) — vérification

- **i18n** : décision des Lots 13-15 reconduite (admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé. Parité vérifiée par import ESM réel : **1394/1394, 0 écart**, inchangé.
- **Zéro hex en dur** : confirmé par grep avant et après (0 résultat) sur les 3 écrans — aucun hex trouvé à corriger ce lot-ci (les 3 fichiers étaient déjà propres sur ce point).
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 3 écrans — non applicable, vigilance vérifiée par relecture.
- **Aucune résurgence wallet/séquestre trompeuse** : voir section dédiée ci-dessus — 0 résidu wallet, 2 découvertes de configuration morte documentées (non wallet), 1 écart fonctionnel sur le reset de test documenté.
- **Cible tactile ≥52px** : 4 manquements réels trouvés et corrigés sur `ConfigTarifsScreen.js` (`btnSauvegarder`, `comBtnSauv`, `resetBtn`, `resetBtnAnnuler`/`resetBtnConfirmer`). Tabs/pilules (`filtrePilule` de `FinancesAdminScreen.js`, `ongletBtn` de `RetraitsAdminScreen.js`) non retouchées — convention déjà établie (précédent direct : `onglet` de `CoursesEnCoursAdminScreen.js`, Lot 13, jamais remonté à 52px) : les filtres/tabs de navigation ne sont pas tenus au même seuil que les boutons d'action primaire/contextuelle réels.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` **non retenté**, panne confirmée sans interruption depuis le Lot 4 (D.8.7), **toujours non réparée** — signalée une nouvelle fois à Cedric. Validation via `@babel/parser` (mêmes plugins que d'habitude) sur les 3 fichiers modifiés : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13-15 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro `caarco_tous_ecrans.yaml` toujours sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné.

### Périmètre respecté

Aucun écran des Lots 1-15 ni 17-18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 déjà connues de la Partie C touchée (les 2 découvertes 🟡 de ce lot sont nouvelles, documentées, non corrigées). `AdminShell.js` non modifié. Fichiers modifiés : `FinancesAdminScreen.js`, `RetraitsAdminScreen.js`, `ConfigTarifsScreen.js` + ce fichier + le CDC (section D.20). Aucune clé i18n ajoutée.

**Prochain lot recommandé : Lot 17 — Admin : marketing** (`MarketingAdminScreen.js`, `PublicitesAdmin.js`, `CalendrierActionsScreen.js`, `LieuxAdminScreen.js` — mobilise `Cadran`/`Fronton`/`Corridor` ; `CalendrierActionsScreen.js` en anglais dans la maquette, à traduire avant usage ; `PublicitesAdmin.js` ne nécessite qu'un contrôle visuel C.2 #6). Voir le prompt de session dédié fourni en fin de session.

---

## Lot 17 — Admin : marketing (clôturé le 09/07/2026)

**4 écrans traités** : `LieuxAdminScreen.js` (bug réel corrigé), `CalendrierActionsScreen.js` (`Cadran` intégré — 1er usage réel du chantier), `MarketingAdminScreen.js` (nettoyage DoD), `PublicitesAdmin.js` (nettoyage DoD). Détail complet en CDC D.21 — ce qui suit résume les décisions et découvertes qui méritent de rester ici.

### Méthode suivie

Les 6 `code.html` assignés (`gestion_des_codes_promo`, `publicit_s_in_app_admin_caarco`, `publicit_s_in_app`, `calendrier_marketing_admin_1`, `_2`, `lieux_valider_admin`) lus intégralement avant tout code. Recherche exhaustive `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 4 écrans et les services consommés (`services/publicites.js`, `services/lieux.js`) : **0 résultat**, aucune résurgence.

### Découverte — la 2e maquette de `MarketingAdminScreen.js` ne correspond à aucune section réelle de l'écran

`publicit_s_in_app_admin_caarco` (grille de cartes bannières avec toggle actif/inactif, "Ajouter une publicité") a été assignée par D.2.5 comme référence 🔧 pour `MarketingAdminScreen.js` — mais le code réel de cet écran ne gère que 2 sections (Packs abonnement, Codes promo), aucune section publicités. La gestion des publicités in-app vit entièrement dans `PublicitesAdmin.js`, un fichier distinct déjà correctement apparié à l'autre maquette (`publicit_s_in_app`, structure en liste horizontale très proche du code réel de `PublicitesAdmin.js`). Traité comme un contrôle visuel C.2 #6 sans action de code — ajouter une section publicités à `MarketingAdminScreen.js` aurait été une fonctionnalité nouvelle hors périmètre d'une passe de refonte visuelle (même discipline que D.16.6/D.9.6).

### Découverte — bug réel sur `LieuxAdminScreen.js` : drawer mobile inatteignable

`LieuxAdminScreen.js` était le seul écran du dossier `admin/` dont la fonction ne déclarait aucun paramètre (`function LieuxAdminScreen()`), alors qu'`AdminShell.js` passe systématiquement `onMenu`/`onRetour`/`onNaviguer` à tous les écrans actifs (`{...ecranProps}`). Conséquence réelle sur mobile (<768px, drawer fermé par défaut) : aucun bouton hamburger n'était rendu, donc aucun moyen de rouvrir la sidebar pour naviguer ailleurs une fois cet écran atteint — une impasse de navigation, pas un simple écart cosmétique. Corrigé : `onMenu` accepté et câblé, même motif que les autres écrans admin de la section (icône `menu-outline`, 22px).

### Découverte maquette — `calendrier_marketing_admin_2` n'est pas en anglais, contrairement à ce que laissait supposer la fiche C.2 #4

La fiche C.2 #4 groupe `calendrier_marketing_admin_1`/`_2` comme "la maquette Stitch entièrement en anglais". Vérifié individuellement : seule `_1` (`lang="en"`, "Marketing Calendar", "Sun/Mon/Tue…") est réellement en anglais. `_2` (`lang="fr"`, "CAARCO - Calendrier Marketing", "Octobre 2023", "Lun/Mar/Mer…", "Aperçu du mois") est déjà presque entièrement en français. Seule `_1` a été traduite (titre, sidebar, en-tête, légende, jours de la semaine, panneau du jour, bottom nav — voir CDC D.21 pour le détail) ; `_2` n'avait besoin d'aucune correction. Même discipline que D.19.1/D.20.1 : une caractérisation faite au niveau de la paire de maquettes ne garantit pas qu'elle s'applique à chaque membre.

### `Cadran` — 1er usage réel du chantier

`Cadran` (assigné dès le Lot 0, D.3.1 #12) n'avait jamais été monté sur un écran de production (seulement l'écran-catalogue dev-only), y compris aux Lots 9 et 16 où ses écrans-preuve d'origine (`classement_r_gional_caarco`, `finances_tokens_tc_admin`) avaient pourtant été traités — vérifié par grep avant de présumer un usage acquis, conformément à la consigne de cette session. Sur ce lot, la navigation mois de `CalendrierActionsScreen.js` (2 `TouchableOpacity` chevron + `Text` du mois, déjà fonctionnellement identique à l'API de `Cadran` : `label`/`onPrecedent`/`onSuivant`) a été remplacée par le composant partagé — correspondance directe, aucune extension d'API nécessaire. Écran non assigné comme preuve pour `Cadran` par D.3.1 (qui citait `classement_r_gional_caarco`/`finances_tokens_tc_admin`), mais besoin réel confirmé à la lecture du code — même logique que Sentier sur `CoursePlanifieeDetailScreen.js` au Lot 6 (D.10.4, besoin transverse imprévu comblé par un composant déjà du Lot 0).

### `Fronton` — évalué sur les 4 écrans, non utilisé

Les 2 en-têtes de section de `MarketingAdminScreen.js` ("PACKS ABONNEMENT", "CODES PROMOTIONNELS") portent une typographie mono compacte tout-caps, incompatible avec la police display large imposée par `Fronton` (même conflit que `DashboardScreen.js` au Lot 13, D.17.5) — et leur bouton associé ("Nouveau") est une action de création, pas une navigation "voir tout" au sens de `Fronton`. Les 3 autres écrans n'ont qu'un en-tête de page unique, sans sous-section méritant ce motif. Non utilisé, même discipline que Corridor/Borne aux lots précédents (composant assigné, évalué, écarté faute de besoin réel).

### `Corridor` — conclusion des Lots 13-16 reconfirmée en une phrase, non réanalysée

Toujours redondant avec la sidebar d'`AdminShell.js` (D.17.3, reconfirmé D.18.8/D.19.4/D.20.5) — non intégré sur les 4 écrans de ce lot.

### Nettoyage DoD complémentaire

- Styles morts supprimés (jamais consommés en JSX, le modal réel passe par `PanneauDroit`) : `modalFond`/`modalCarte` (`MarketingAdminScreen.js`), `modalOverlay`/`modalBox` (`PublicitesAdmin.js`) — avec eux, l'import `alpha` devenu inutile retiré des deux fichiers.
- 1 hex en dur retokenisé : `'#0f141159'` (scrim du FAB, `CalendrierActionsScreen.js`, réellement utilisé contrairement aux styles morts ci-dessus) → `alpha(colors.nuit, 0.35)`.
- Cibles tactiles <52px corrigées : `btn` Valider/Rejeter de `LieuxAdminScreen.js` (44→52), `btnNouveauCode` de `MarketingAdminScreen.js` et `btnAjouter` de `PublicitesAdmin.js` (boutons de création, ~30-36px→`minHeight: 52`), `fabSub` de `CalendrierActionsScreen.js` (44→52, actions contextuelles nommées du FAB, pas de simples icônes utilitaires).

### Definition of done (D.2bis point 4) — vérification

- **i18n** : décision des Lots 13-16 reconduite (admin 100 % français en dur, aucun retrofit) — 0 nouvelle clé. Parité vérifiée par import ESM réel : **1394/1394, 0 écart**, inchangé.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 4 écrans.
- **Contraste WCAG AA** : aucun token posé sur un fond volontairement sombre/thémé différent du reste de l'écran sur ces 4 écrans — non applicable.
- **Aucune résurgence wallet/séquestre** : confirmé par grep exhaustif (0 résultat) sur les 4 écrans et les 2 services consommés.
- **Cible tactile ≥52px** : 4 manquements réels trouvés et corrigés (détail ci-dessus). Pilules de filtre (`pill` de `CalendrierActionsScreen.js`) et cellules de calendrier (`cel`) non retouchées — convention déjà établie, filtres/navigation exemptés du seuil.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` retenté et **toujours en échec** (même panne depuis le Lot 4, reproduite sur `LieuxAdminScreen.js`, optional chaining) — signalée une nouvelle fois à Cedric. Validation via `@babel/parser` (mêmes plugins que d'habitude) sur les 4 fichiers modifiés : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13-16 (pas d'ADB/Maestro dans cet environnement d'agent ; flow Maestro sans couverture admin, D.17.9 non résolue) — signalé de nouveau à Cedric, non contourné.

### Périmètre respecté

Aucun écran des Lots 1-16 ni 18 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune des 2 corrections backend 🔴 ni des 3 découvertes de configuration morte du Lot 16 touchées, `AdminShell.js` non modifié (lu pour comprendre le passage des props, non retouché). Fichiers modifiés : `LieuxAdminScreen.js`, `CalendrierActionsScreen.js`, `MarketingAdminScreen.js`, `PublicitesAdmin.js` + `vehicle_character_sheets/stitch_vehicle_character_sheets/calendrier_marketing_admin_1/code.html` (traduction EN→FR) + ce fichier + le CDC (section D.21). Aucune clé i18n ajoutée.

**Prochain lot recommandé : Lot 18 — Admin : notifications, sécurité & reste** (`NotificationsAdminScreen.js`, `CampagnesPushScreen.js`, `SecuriteAdminScreen.js`, `MFAChallengeScreen.js`, `AdminShell.js` — mobilise Corridor/Echelon ; 3 des 5 écrans sans maquette Stitch ; `AdminShell.js` est le shell de navigation lui-même, jamais retouché jusqu'ici — dernier lot de tout le chantier D). Voir le prompt de session dédié fourni en fin de session.

---

## Lot 18 — Admin : notifications, sécurité & reste (clôturé le 09/07/2026) — DERNIER LOT DU CHANTIER D

**5 écrans traités** : `NotificationsAdminScreen.js` (nettoyage DoD réel), `CampagnesPushScreen.js` (déjà mature, nettoyage DoD), `SecuriteAdminScreen.js` et `MFAChallengeScreen.js` (déjà conformes, non modifiés), `AdminShell.js` (1ʳᵉ retouche du fichier en 6 lots admin). Détail complet en CDC D.22 — ce qui suit résume les décisions et découvertes qui méritent de rester ici.

### Méthode suivie

Le seul `code.html` avec maquette réelle (`templates_notifications_admin`) lu intégralement avant tout code. Les 3 écrans sans maquette évalués contre les conventions des 17 lots précédents. `AdminShell.js` lu intégralement pour la première fois avec l'intention explicite d'y appliquer des changements (pas seulement vérifier le passage de props, comme aux Lots 13/17). Recherche `wallet|solde|séquestre|escrow|virement|retrait|portefeuille` sur les 5 écrans : 0 résultat — étendue à la table `notification_templates` (consommée en direct par `NotificationsAdminScreen.js`), qui a livré la découverte principale du lot (voir plus bas).

### `NotificationsAdminScreen.js` — architecture différente de la maquette, assumée

La maquette montre un panneau d'édition desktop permanent à 2 colonnes ; l'écran réel utilise liste + modale `PanneauDroit` (même patron que les autres écrans admin à panneau). Écart architectural documenté, pas un défaut — imposer un panneau permanent aurait cassé la cohérence avec le reste du chantier admin. Bouton "New Template" de la maquette non repris (pas de RPC de création trouvée, création de template hors périmètre d'une passe visuelle). Nettoyage réel : 2 hex catégories retokenisés (`colors.nere` pour fidélité, `colors.bambou` pour finance — collision de couleur assumée avec `kyc`/`course_client`, palette à 5 teintes pour 7 catégories), 1 fallback hex mort supprimé (`colors.foret10 ?? '#edf3ef'`, même défaut que D.6.7), 3 styles morts supprimés (`modalScrim`/`modalBoite`/`modalScroll`, jamais consommés — le modal réel passe par `PanneauDroit`), 2 cibles tactiles corrigées (`btnAnnuler`/`btnSauvegarder`, 46→52px).

### `CampagnesPushScreen.js` — déjà mature, aucune fonctionnalité manquante

Segmentation sexe/ancienneté/ville/note déjà implémentée en entier (exactement le besoin décrit en D.2.5), récurrence, calendrier RN pur sans dépendance externe. Nettoyage DoD seulement : 2 styles morts supprimés (`styles.overlay` avec son hex, `styles.modal` bottom-sheet jamais consommé), 1 hex actif retokenisé (`calS.overlay`, `'#0f141173'` → `colors.nuit + '73'`, même valeur exacte que l'overlay retokenisé au Lot 13, D.17.10).

### `SecuriteAdminScreen.js` / `MFAChallengeScreen.js` — déjà conformes, non modifiés

0 hex, 0 résidu wallet, boutons via `Galet` (52px par défaut). `SecuriteAdminScreen.js` câble déjà correctement `onMenu` (pas le bug de `LieuxAdminScreen.js`, D.21.3). `MFAChallengeScreen.js` confirmé rendu par `RootNavigator.js` avant `AdminShell.js` (étape aal2 hors sidebar) — absence du `MENU` d'`AdminShell.js` volontaire, pas un oubli.

### `AdminShell.js` — décision Corridor tranchée explicitement

Question posée : `AdminShell.js` devrait-il être refactoré pour consommer `Corridor` en interne ? Réponse : **non**. `SidebarContenu` (fonction interne du fichier) est un sur-ensemble strict de `Corridor` — sections groupées, bloc profil, mode replié mobile, tiroir animé, historique de navigation — aucune de ces capacités n'existe dans `Corridor` aujourd'hui. Refactor à risque élevé (20 écrans admin enveloppés) pour un gain nul. Nettoyage réel (1ʳᵉ retouche du fichier en 6 lots admin) : 2 hex actifs retokenisés (`scrim`, `modalScrim`), 2 cibles tactiles corrigées (`btnAnn`/`btnConf` de la modale déconnexion, 46→52px).

### `Echelon` — évalué explicitement sur les 4 écrans de contenu, écarté sur les 4

Barre de qualification reprise du Lot 6 (D.10.3) : Echelon remplace un stepper *fait main préexistant*, il n'habille pas un écran qui n'en a aucun. Aucun des 4 écrans ne présente de stepper préexistant à remplacer — `SecuriteAdminScreen.js` (inscription 2FA) était le candidat le plus proche, évalué explicitement, mais ses 2 cartes conditionnelles sont déjà claires par titre+icône et ajouter Echelon créerait une section neuve plutôt que d'en améliorer une existante.

### Découverte majeure — migration 098 corrige déjà 1 des 2 🔴 — confirmé appliqué en production le 09/07/2026

En élargissant la recherche wallet/séquestre à `notification_templates` (éditée par l'écran de ce lot) : `App/supabase/migrations/098_audit_20260708_corrections_securite.sql` contenait déjà le correctif attendu pour le 🔴 "Contrôle de rôle manquant sur `admin_crediter_wallet_client`". Initialement signalé comme "application non vérifiable" faute d'accès Supabase — **vérifié dans la foulée le 09/07/2026, une fois l'autorisation explicite de Cedric obtenue**, par requêtes en lecture seule (`supabase db query --linked`) contre la base de production réelle : les 8 correctifs de la migration 098 sont déjà tous en place, de même que les migrations 099, 100 et les 5 migrations datées plus récentes. **Ce 🔴 est clos.** Voir section "Corrections backend indépendantes" en tête de ce fichier pour le détail des vérifications et l'avertissement sur `supabase db push` (à ne jamais lancer tel quel sur ce projet — voir cette même section). Le 1er 🔴 (trigger, réellement nommé `trigger_streak_client` → `verifier_streak_client`, écrit dans `wallets`) reste ouvert sans changement, confirmé toujours actif en production, explicitement exclu par la migration 098 elle-même tant que `PointsScreen.js`/`MerciScreen.js` restent bloqués.

Découverte secondaire : 2 templates de notification morts identifiés (`retrait_traite_tr`/`retrait_refuse_tr`, aucun appelant trouvé) et 1 description de template non assainie mais fidèle au comportement réel (`credit_wallet`, appelé depuis `TransporteursAdminScreen.js`) — documentés en tête de ce fichier, non modifiés (édition de contenu DB hors périmètre visuel).

### Definition of done (D.2bis point 4) — vérification

- **i18n** : décision des Lots 13-17 reconduite (admin 100 % français en dur) — 0 nouvelle clé. Parité vérifiée par import ESM réel : **1394/1394, 0 écart**, inchangé.
- **Zéro hex en dur** : confirmé par grep après correction (0 résultat) sur les 5 écrans.
- **Contraste WCAG AA** : aucun token neuf introduit — non applicable.
- **Aucune résurgence wallet/séquestre dans le code des 5 écrans** : confirmé (0 résultat). Résidus réels trouvés côté données (`notification_templates`) — documentés, non corrigés (voir plus haut).
- **Cible tactile ≥52px** : 4 manquements réels trouvés et corrigés (`btnAnnuler`/`btnSauvegarder` de `NotificationsAdminScreen.js`, `btnAnn`/`btnConf` d'`AdminShell.js`). `jourChip` (44px, pilule de sélection de jour) laissé tel quel — convention filtre/sélection établie.
- **Validation syntaxique** : `npx babel --presets babel-preset-expo` retenté et **toujours en échec** (panne ininterrompue depuis le Lot 4) — signalée une dernière fois à Cedric. Validation via `@babel/parser` sur les 5 fichiers du lot : **OK**.
- **Captures avant/après (`scripts/capture-auto.ps1`)** : non exécuté, même double blocage que les Lots 13-17 — signalé une dernière fois, non contourné.

### Périmètre respecté

Aucun écran des Lots 1-17 touché, aucun des 4 écrans du Lot bloqué (D.3.3) touché, aucune migration ni RPC modifiée, `TransporteursAdminScreen.js` (Lot 14) lu en lecture seule uniquement (traçabilité de `credit_wallet`), non modifié. Fichiers modifiés : `NotificationsAdminScreen.js`, `CampagnesPushScreen.js`, `AdminShell.js` + ce fichier + le CDC (section D.22). Aucune clé i18n ajoutée. Aucun push GitHub, aucun test live lancé — en attente de consigne explicite de Cedric.

**Ce lot clôt le chantier D.** Bilan global ci-dessous.

---

## Bilan global — Chantier D clos (08/07/2026 → 09/07/2026)

**Chantier D (refonte visuelle) clos avec le Lot 18.** 64 écrans + Lot 0 (composants transverses), répartis en 1 lot de composants + 18 lots d'écrans, tous marqués `fait`, sur 2 jours (08 et 09/07/2026).

### Ce qui a été livré

- **64/64 écrans traités** : 59 retouchés en 18 lots séquencés (D.3.2), 1 déjà conforme hors séquence (`SplashAnimeeScreen.js`, refondu Sprint 3), 4 volontairement laissés de côté — voir Lot bloqué ci-dessous.
- **12 composants transverses créés** au Lot 0 (`Borne`, `Sentier`, `Etal`, `Pochette`, `Silo`, `Etoiles`, `Corridor`, `Passoire`, `Fronton`, `Echo`, `Cadran`, + `Jalons.js` existant reconnu comme couvrant déjà le rôle "Jauge" prévu). Bilan d'usage réel très inégal, jamais forcé par défaut :
  - **Usage réel confirmé et répété** : `Sentier` (Lots 3-4, 6-7, 11), `Etal` (Lots 2-3), `Étoiles` (Lots 5, 9), `Silo` (Lots 9, 13), `Pochette` (Lots 3, 10, 15, 19), `Borne` (Lots 6, 8-9, 13, 16 — jamais utilisé en pratique sur les écrans admin à KPI, voir plus bas), `Passoire` (Lots 13-14), `Cadran` (1er usage réel seulement au Lot 17), `Echo` (Lots 2, 4, 7), `Jalons`/Jauge (Lots 4, 7, 11), `Echelon` (1er usage réel au Lot 6 seulement, en remplacement d'un stepper fait main préexistant).
  - **`Corridor` : jamais intégré, sur aucun des 20 écrans admin ni sur `AdminShell.js` lui-même** — découverte architecturale majeure du Lot 13 (D.17.3) : redondant avec `SidebarContenu`, la sidebar déjà construite dans `AdminShell.js`, qui enveloppe les 20 écrans admin sans exception. Reconfirmé en une phrase à chaque lot admin (14-18) sans réanalyse complète. Au Lot 18, la question a été reposée sous un angle différent — `AdminShell.js` devrait-il être refactoré pour *consommer* `Corridor` en interne ? — et tranchée explicitement : non, `SidebarContenu` est un sur-ensemble strict, le refactor inverserait le rapport risque/bénéfice.
  - **`Borne`/`Fronton` : évalués à plusieurs reprises sur des écrans à KPI/sections admin, jamais utilisés en pratique** malgré des écrans-preuve d'origine dédiés — les motifs locaux existants (`CarteKPI`, `CarteStat`, en-têtes mono compacts) se sont révélés systématiquement plus riches ou plus cohérents avec leur écran que les composants partagés.
  - **`Fronton` : 0 usage réel sur tout le chantier**, évalué et écarté sur au moins 3 écrans (Lots 13, 17) — la police display imposée par le composant entre systématiquement en conflit avec les en-têtes mono compacts déjà en place côté admin.
- **Aucune fonctionnalité ajoutée** en dehors du périmètre visuel — discipline tenue sur tout le chantier ("ne jamais ajouter de fonctionnalité dans une passe de refonte visuelle", D.9.6/D.16.6/D.21.2/D.22.2).

### Bugs réels trouvés et corrigés (pas seulement cosmétiques)

- `AccueilScreen.js` (Lot 2) : sélection de catégorie de véhicule codée mais jamais rendue.
- `TableauBordScreen.js` (Lot 7) : ~240 lignes de code mort (`CarteCourse`).
- `HistoriqueScreen.js`/`ProfilClientScreen.js` (Lots 5, 11) : résidus wallet actifs, bugs de compteur de courses.
- `CoursesTransporteurScreen.js` (Lot 11) : crash `ReferenceError`.
- `LieuxAdminScreen.js` (Lot 17) : drawer mobile inatteignable sur mobile (`onMenu` jamais reçu ni câblé), seul écran admin dans ce cas sur 20.
- 2 régressions de contraste WCAG AA détectées et neutralisées **avant** introduction (Lots 7 et 13, D.11.5/D.17.7) — vigilance proactive, pas des bugs livrés puis corrigés.
- `course.methode_paiement` vs `mode_paiement_client` : 4 écrans suspects identifiés au Lot 5 (D.9.4), soldés un par un jusqu'au Lot 13 (D.17.2).

### Découvertes de configuration morte (décision Cedric requise, non corrigées)

- `ConfigTarifsScreen.js` (Lot 16) : section "Commission parrainage" édite un taux lu par une RPC inatteignable (`liberer_sequestre_course`, jamais appelée depuis l'app).
- `ConfigTarifsScreen.js` (Lot 16) : section "Charge utile" édite des colonnes qui n'existent dans aucune migration — sauvegarde vouée à l'échec.
- `notification_templates` (Lot 18) : 2 templates morts (`retrait_traite_tr`/`retrait_refuse_tr`), 1 description non assainie mais fidèle (`credit_wallet`).
- `MarketingAdminScreen.js` (Lot 17) : une 2ᵉ maquette assignée par l'inventaire D.2.5 ne correspond à aucune section réelle de l'écran — la fonctionnalité vit ailleurs (`PublicitesAdmin.js`).

### Découverte la plus importante du chantier : migration 098 — confirmée appliquée en production le 09/07/2026

Le Lot 18 a révélé qu'un correctif déjà écrit dans le dépôt (`098_audit_20260708_corrections_securite.sql`) résout l'un des 2 🔴 de la Partie C (`admin_crediter_wallet_client`) plus 7 autres failles/bugs indépendants. Sur autorisation explicite de Cedric, vérifié le jour même par requêtes en lecture seule contre la production réelle (projet Supabase lié `dxwkikaniawpfljvteog`, CAARCO) : **les 8 correctifs sont déjà en place**, de même que les migrations 099/100 (permissions super-admin) et 5 migrations datées plus récentes — tout le dépôt de migrations est déjà appliqué à la base réelle, malgré le signal "pending" trompeur de `supabase migration list`/`db push --dry-run` (la table de suivi CLI n'a jamais été alimentée, les migrations ayant historiquement été appliquées à la main via le SQL Editor). **Aucune migration n'a donc été exécutée dans ce lot — rien n'était réellement en attente.** Point de vigilance découvert au passage : `fix_terminer_livraison.sql` (fichier hors convention de nommage) recrée une version dangereuse et déjà supprimée de `terminer_livraison` — ne jamais l'exécuter, à supprimer du dépôt.

### Décisions Cedric encore en attente

1. **Lot bloqué (D.3.3), jamais traité** — 4 écrans : `ProfilScreen.js` (champs `sexe`/`date_naissance`), `MerciScreen.js`/`PointsScreen.js` (récompense streak "+100 XAF", tables `wallets` orphelines), `PacksAbonnementScreen.js` (commission des paliers payants).
2. **1 correction backend 🔴 encore ouverte** — trigger `trigger_streak_client`/`verifier_streak_client` (écrit dans `wallets`), volontairement non touché tant que `PointsScreen.js`/`MerciScreen.js` ne sont pas tranchés (point 1 ci-dessus). Le 2ᵉ 🔴 (`admin_crediter_wallet_client`) est **clos**, confirmé appliqué en production le 09/07/2026.
3. **3 découvertes de configuration morte** (Lots 16, 18, ci-dessus) — rebrancher ou retirer chaque section concernée.
4. **Captures avant/après** — `scripts/capture-auto.ps1` jamais exécuté sur 18 lots (pas d'ADB/Maestro dans cet environnement), et le flow Maestro `caarco_tous_ecrans.yaml` ne couvre de toute façon aucun écran admin (D.17.9, non résolu en 6 lots) — un flow Maestro dédié admin serait nécessaire en plus du matériel.
5. **`npx babel --presets babel-preset-expo`** — en panne sans interruption depuis le Lot 4 (15 lots), jamais réparée ; toutes les validations syntaxiques de ce chantier sont passées par `@babel/parser` en remplacement.

### Prochaines étapes suggérées (attente de consigne explicite de Cedric — aucune n'a été lancée)

- Supprimer `App/supabase/migrations/fix_terminer_livraison.sql` du dépôt (fichier obsolète et dangereux, recrée une fonction déjà retirée pour raison de sécurité) — proposé, pas fait automatiquement.
- Trancher les 4 écrans du Lot bloqué et les 3 configurations mortes.
- Réparer `capture-auto.ps1`/Maestro pour obtenir enfin des captures avant/après sur les 18 lots, et un flow Maestro admin.
- Réparer `npx babel --presets babel-preset-expo`.
- Une fois ce qui précède tranché : push GitHub, puis test live guidé par Cedric (non fait dans ce lot, sur consigne explicite de ne rien pousser/tester sans validation).

---

## Session du 10/07/2026 — Traitement des 5 points en attente + 2 demandes nouvelles

Session de suivi post-chantier D, hors refonte visuelle. Autorisation explicite de Cedric obtenue en cours de session pour vérifier/appliquer des migrations en attente. **6 migrations réellement appliquées en production** (`App/supabase/migrations/101` à `106`), toutes vérifiées par requêtes en lecture seule avant et après (projet Supabase lié `dxwkikaniawpfljvteog`). Aucun `supabase db push` exécuté (toujours dangereux sur ce projet — voir avertissement en tête de ce fichier).

### Point 1 — Lot bloqué (D.3.3), 4 décisions tranchées avec Cedric

1. **`ProfilScreen.js`** — sexe/date de naissance activés. Les colonnes existaient déjà en base (ajoutées à la main hors migration, comme souvent sur ce projet) ; seul `CHAMPS_PROFIL_AUTORISES` (`App/src/services/auth.js`) bloquait encore la sauvegarde. Corrigé en 1 ligne, aucune migration nécessaire.
2. **`MerciScreen.js`** — streak hebdomadaire "+100 XAF" remplacé par une réduction % (mécanisme `reduction_pct`, migration 101). Le trigger `trigger_streak_client` (nom réel du 1er 🔴, la description "after_course_terminee" du CDC était une paraphrase, pas le nom de l'objet) ne touche plus `wallets`.
3. **`PointsScreen.js`** — découverte en cours de route : **deux systèmes de jalons parallèles et jamais unifiés** existaient (`jalons_client`, lu par `MerciScreen.js`, vs `recompenses_client`, lu par `PointsScreen.js` ET le popup surprise d'`AccueilScreen.js` — 3 vocabulaires de types différents selon le fichier, 0 ligne dans les deux tables). Tranché avec Cedric : unifié sur `jalons_client` (déjà réparé). `PointsScreen.js` et `AccueilScreen.js` redirigés dessus ; `recompenses_client`/`attribuer_jalon_client(3 arg)`/`reveler_jalon` laissés dormants (non supprimés), `services/motivation.js` allégé de ses exports morts.
4. **`PacksAbonnementScreen.js`** — taux de commission des packs (12/8/5%) réellement branché sur `debiter_commission_tc()` (migration 102), au lieu du taux fixe 20% appliqué à tous les TR. L'infrastructure (`users.pack_actuel`/`pack_expire_at`, table `abonnements_transporteurs`, fonction `expirer_abonnements()`) existait déjà depuis la migration 053 mais n'avait jamais été reliée à rien — RPC `admin_activer_pack_tr()` ajoutée (seul point d'entrée d'activation, admin-only, même patron que `admin_crediter_tc`), cron quotidien d'expiration programmé (jamais fait depuis 053). L'écran lui-même reste honnête tel quel ("Fonctionnalité disponible très prochainement !", pas de paiement in-app réel) — aucun flux Notchpay construit pour les packs dans cette session, scope volontairement limité au backend + activation admin.

### Point 2 — Trigger streak (1er 🔴)

Résolu comme effet de bord du point 1.2 : `trigger_streak_client` ne crédite plus jamais `wallets`.

### Point 3 — 3 configurations mortes

- **Charge utile** (`ConfigTarifsScreen.js`) — `calculer_prix()` lit désormais réellement `parametres_tarifs.poids_max_kg`/`volume_max_m3` (migration 103) au lieu de seuils codés en dur. Écart réel trouvé en vérifiant : moto configuré à 200kg en base, 20kg appliqué par le moteur avant correction — pas juste une section vide, une vraie divergence business déjà en production.
- **Commission parrainage** — laissée en l'état (dormante, non rebranchée, non retirée). N'a pas été retranchée explicitement avec Cedric dans cette session ; `liberer_sequestre_course` (déjà réécrite migration 098) ne la lit plus, la RPC est morte comme documenté au Lot 16.
- **Templates de notification morts** — `retrait_traite_tr`/`retrait_refuse_tr` supprimés de `notification_templates` (migration 106, aucun appelant trouvé). `credit_wallet` non touché (description fidèle à un comportement réel, `admin_crediter_wallet_client` toujours actif).

### Demandes nouvelles de Cedric, traitées dans la foulée

**Gestion des abonnements/commissions transporteur depuis l'admin** — migration 104 : taux de commission personnalisé par TR (`users.commission_taux_pct`/`commission_promo_expire_le`/`commission_promo_motif`), prioritaire sur le pack, pour les promotions type "15% pour les 50 premiers TR, 1 an" citée par Cedric. RPC `admin_definir_commission_personnalisee()` et `admin_modifier_abonnement_tr()` (modifier la date de fin d'un abonnement déjà actif). Nouvel écran **`admin/AbonnementsAdminScreen.js`** (section FINANCES d'`AdminShell.js`, permission `finances`) : liste des TR avec pack actuel, jours restants, commission effective ; panneau de détail pour activer un pack, prolonger/raccourcir la durée, appliquer ou retirer un taux promo. Les 3 RPC testées en direct sur un TR réel puis état restauré (aucune donnée de test laissée en base).

**Suivi de validité des documents transporteur** — migration 105 : `transporteurs_kyc` complétée pour les 7 documents demandés (CNI, Permis, Carte grise, Visite technique, Assurance, Licence de transport, Taxe publicitaire) — seuls CNI/Permis avaient déjà une date d'expiration ; Carte grise/Assurance avaient un fichier sans date ; Visite technique/Licence de transport/Taxe publicitaire n'existaient pas du tout. Nouvel écran **`admin/DocumentsTRAdminScreen.js`** (section UTILISATEURS, permission `utilisateurs`) : liste triée par échéance la plus proche (rouge = expiré, orange = < 30 jours), panneau de détail par TR avec saisie de date par document (format jj/mm/aaaa, validé) et bouton "Notifier le transporteur" pour les documents bientôt expirés — nouveau template `document_expiration_proche` (migration 106) réellement envoyé via `notifierAvecTemplate`, pas seulement affiché.

### Point 4 — Outillage cassé

Aucun changement possible depuis cet environnement : `npx babel --presets babel-preset-expo` retenté, toujours en échec (panne ininterrompue depuis le Lot 4) ; `capture-auto.ps1`/Maestro toujours sans ADB/appareil disponible. Toutes les validations de cette session sont passées par `@babel/parser` (10 fichiers JS revalidés après coup, tous OK) et par des vérifications SQL en lecture seule contre la production (voir détail par point ci-dessus).

### Point 5 — Push GitHub / tests live

**Non fait.** Consigne explicite de ne rien pousser ni tester en live sans confirmation — en attente de Cedric.

### Fichiers modifiés dans cette session

Migrations (appliquées en prod) : `101_jalons_fidelite_sans_wallet.sql`, `102_packs_commission_reelle.sql`, `103_charge_utile_reelle.sql`, `104_commission_personnalisee_admin.sql`, `105_documents_tr_expiration.sql`, `106_templates_notif_documents.sql`.
Code app : `services/auth.js`, `services/jalons.js`, `services/motivation.js`, `screens/MerciScreen.js`, `screens/client/PointsScreen.js`, `screens/client/AccueilScreen.js`, `screens/transporteur/PacksAbonnementScreen.js`, `screens/admin/AdminShell.js`, `i18n/fr.js`, `i18n/en.js` (+3 clés, parité 1397/1397 confirmée).
Nouveaux fichiers : `screens/admin/AbonnementsAdminScreen.js`, `screens/admin/DocumentsTRAdminScreen.js`.

---

*Mettre à jour ce fichier à la fin de chaque lot : statut, lot assigné, et ajouter toute découverte utile aux futures sessions dans la colonne Notes ou en bas de fichier. Chantier D clos au Lot 18 (09/07/2026). Session du 10/07/2026 : 5 points traités + 2 demandes nouvelles (abonnements/commission, documents TR), 6 migrations appliquées en prod. Push GitHub et tests live volontairement NON faits, en attente de consigne explicite de Cedric.*
