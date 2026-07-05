# CAARCO — Fonctionnement des courses (client, transporteur, immédiat, planifié)
**Date du scan : 5 juillet 2026** · Reconstitué directement depuis le code (services, écrans, migrations SQL, Edge Functions) — pas depuis la spec, depuis ce qui est réellement écrit et actif aujourd'hui.

⚠️ **Note de lecture importante** : le code contient plusieurs générations successives du système (modèle wallet/séquestre historique, puis pivot vers les Tokens de Course). Dans ce document, je précise systématiquement **quelle version est active aujourd'hui** (la plus récente, celle réellement appelée par l'app) et je signale explicitement le code mort ou les incohérences trouvées en cours de route — sans les corriger, juste pour que tu voies où sont les zones grises.

---

## 1. Vue d'ensemble

Une course passe par trois grandes phases quel que soit son type :
1. **Création** (client) — trajet, détails colis, prix, mode de paiement informatif
2. **Matching** — trouver un transporteur (TR) qui candidate et se fait sélectionner
3. **Exécution** — collecte → livraison → OTP → commission débitée → notation

Il existe **deux types de course** qui partagent la même table `courses` mais divergent fortement sur le matching :
- **Immédiate** (`type_course = 'immediate'`) : diffusion à tous les TR compatibles, premier arrivé/premier servi.
- **Planifiée** (`type_course = 'programmee'`) : diffusion immédiate aussi, mais le système réserve le **TR le plus proche géographiquement**, avec rappels avant l'heure H et escalade admin si personne ne répond.

## 2. Statuts d'une course

La contrainte SQL la plus récente (migration `087_annulation_tr_et_selection_immediate.sql`) autorise ces valeurs pour `courses.statut` :

```
en_attente, acceptee, en_cours, terminee, annulee, expiree, livree,
programmee, programmee_confirmee, litige,
brouillon, publiee, attribuee, pre_active,
no_show_tr, annulee_tr
```

⚠️ `brouillon`, `publiee`, `attribuee` sont prévus dans la contrainte (migration 078) mais **aucun code applicatif ne les écrit** — statuts fantômes, jamais utilisés en pratique.

### Transitions autorisées (RPC `changer_statut_course`, migration 079)

| Statut de départ | Statuts d'arrivée possibles | Déclenché par |
|---|---|---|
| `en_attente` | `acceptee`, `annulee` | client ou TR |
| `acceptee` | `en_cours`, `annulee` | TR assigné |
| `en_cours` | `terminee`, `litige` | TR assigné |
| `litige` | `terminee`, `annulee` | admin uniquement |
| `programmee` | `attribuee`, `publiee`, `annulee` | système |
| `attribuee` | `programmee_confirmee`, `pre_active`, `en_cours`, `annulee` | système |
| `programmee_confirmee` | `pre_active`, `en_cours`, `annulee` | système/cron |
| `pre_active` | `en_cours`, `annulee` | TR ou admin |
| `no_show_tr` | `annulee` | client ou admin |
| n'importe lequel | n'importe lequel | admin (bypass total) |

**Point d'attention** : cette matrice n'est pas le seul chemin possible. `annulerCourse()` (`services/courses.js`) fait un `UPDATE` direct sur `statut='annulee'`, sans passer par la RPC — la seule protection est la policy RLS (client ou TR propriétaire) et le trigger `trg_courses_protege` qui, lui, ne bloque que la modification du prix, de l'OTP, et le passage forcé à `terminee`. Concrètement : **rien côté serveur n'empêche aujourd'hui un client d'annuler une course déjà `en_cours`** — seul le bouton "Annuler" est masqué côté UI selon le statut (`peutAnnuler` dans `CourseDetailClientScreen.js`).

---

## 3. Course immédiate — cycle détaillé

### 3.1 Création
Le client saisit son trajet (`TrajetScreen.js`), les détails du colis (`DetailsColisScreen.js`), puis confirme (`ConfirmationScreen.js`). Le prix est calculé par la **RPC Postgres `calculer_prix`** (et non une Edge Function comme documenté dans le CLAUDE.md du projet), qui lit ses paramètres dans la table `parametres_tarifs`.

⚠️ **Anomalie relevée** : le client appelle `calculer_prix` avec un paramètre `p_est_nuit`, mais aucune migration ne définit ce paramètre sur la fonction SQL (signature réelle à 4 paramètres). PostgREST exige une correspondance exacte des noms de paramètres RPC — soit la majoration de nuit ne s'applique jamais réellement en production, soit une version plus récente de la fonction existe hors du dossier `migrations/` que je n'ai pas retrouvée. À vérifier directement sur le Supabase de prod.

La course est insérée avec `statut = 'en_attente'` et `mode_paiement_client = 'especes' | 'mobile_money'` — **ce champ est purement informatif**, aucune transaction n'est créée dessus (voir §3.4).

### 3.2 Diffusion aux transporteurs
L'app appelle l'Edge Function `notifier-transporteurs`, qui sélectionne **tous** les TR en ligne, avec KYC compatible (ou en dessous de leur quota de 2 courses/mois sans KYC), filtrés uniquement par **catégorie de véhicule** — **aucun filtre géographique**.

⚠️ Les paramètres `rayon_matching_immediate_km` (5 km) et `rayon_diffusion_prog_km` (15 km), définis en base (migration 078), **ne sont lus par aucun fichier du code**. En clair : un TR à 40 km reçoit la même notification qu'un TR à 500 mètres pour une course immédiate.

### 3.3 Candidature et sélection automatique
- Le TR candidate via `candidaterCourse()` → RPC `candidater_course` (version active : migration 088). Cette RPC vérifie **avant toute chose** : statut de la course, quota KYC (§5), solde TC suffisant pour la commission (§5) — puis insère la candidature et appelle immédiatement `auto_selectionner_tr`.
- `auto_selectionner_tr` choisit la candidature par `distance_pickup_km ASC, created_at ASC LIMIT 1`. Comme la distance n'est pas encore renseignée au moment de la candidature, **c'est en pratique le premier TR à candidater qui est retenu** — un modèle "premier arrivé, premier servi" assumé (documenté explicitement dans la migration 087 comme le comportement voulu).
- Un cron de secours (`auto_selectionner_courses_en_attente`, toutes les minutes) rattrape les cas non résolus après 15 secondes.
- **Code mort à noter** : l'écran `AttenteScreen.js` contient toute la logique d'affichage d'une liste de candidats avec sélection manuelle par le client (`CarteCandidature`, `ProfilTransporteurScreen.js`, `choisirTransporteur()`), mais la `FlatList` est rendue avec `renderItem={null}` — rien de tout ça n'est visible à l'écran. Le texte affiché au client est explicitement "Sélection automatique en cours…". Autrement dit, **la fonctionnalité "le client choisit son transporteur" existe dans le code mais n'est plus branchée** ; le système actuel est 100% automatique.
- **Timeout** : après 3 minutes sans candidat, le client voit "Aucun transporteur disponible" côté UI (`AttenteScreen.js`) — mais cela déclenche juste `annulerCourse()` (statut → `annulee`). L'expiration serveur réelle (`expirer_courses_inactives` → statut `expiree`) ne se déclenche qu'après **1 heure**, valeur câblée en dur dans un trigger, indépendante du paramètre `delai_expiration_immediate_min` (60 min) défini en base mais jamais lu par le code.

### 3.4 OTP et livraison
Le code OTP (4 chiffres) est généré par un **trigger DB** au moment de l'`INSERT` de la course (`generer_otp_course`), pas par une Edge Function comme documenté dans le CLAUDE.md du projet. Il est affiché au client dans `SuiviScreen.js` une fois la course `en_cours`, et saisi par le TR dans `NavigationScreen.js`, validé par la RPC serveur `confirmer_livraison(p_course_id, p_otp)`.

### 3.5 Paiement du transporteur — quel modèle est réellement actif
La version active de `confirmer_livraison` (migration 085) fait, **dans une seule transaction atomique** :
1. Vérifie l'OTP et que le TR appelant est bien celui assigné
2. Passe la course à `terminee`
3. Débite directement la commission en TC (`debiter_commission_tc`, 20 % du prix stocké en base, idempotent)

Elle **ne touche plus du tout** les tables `paiements`/`wallets`/séquestre — c'est explicitement commenté dans le code SQL comme un nettoyage du modèle abandonné. Confirmations supplémentaires :
- L'ancienne RPC `terminer_livraison()` (qui libérait un séquestre wallet) n'est appelée nulle part dans le code actuel.
- `PaiementScreen.js` et `AttenteReglementScreen.js` existent toujours comme fichiers mais **ne sont enregistrés dans aucun navigateur** — `TransporteurNavigator.js` porte même le commentaire `// AttenteReglementScreen supprimé — paiement direct client→TR`. Ce sont des écrans orphelins, inaccessibles depuis l'app installée.

**Conclusion : le modèle réellement actif aujourd'hui est 100 % Tokens de Course.** Le client paie le TR directement (espèces ou Mobile Money, hors app), `mode_paiement_client` reste un champ d'affichage sans conséquence financière, et la seule transaction enregistrée par CAARCO est le débit de commission TC à la livraison.

---

## 4. Course planifiée — cycle détaillé

Le principe de base (documenté dans `COURSES_PROGRAMMEES_2026-07-03.md`) : contrairement à ce que l'ancien code laissait penser ("le matching se fait 45 min avant l'heure H"), une course planifiée est **diffusée aux transporteurs dès sa création**, exactement comme une course immédiate — la différence est dans ce qui se passe ensuite.

### 4.1 Cycle de vie complet

```
Création (client) ──► diffusion TR immédiate + horodatage matching_demarre_at
      │
      ├─ TR candidatent ──► auto_selectionner_tr ──► programmee_confirmee
      │                      (le TR le plus proche est réservé, via transporteurs_proches, rayon 30 km)
      │                              │
      │                     rappel J-2h ──► verrou J-45min (statut → pre_active, TR verrouillé)
      │                              │
      │                     Contrôle GPS à l'heure H (SLA 12 km) :
      │                         ├─ TR proche ──► exécution normale (en_cours)
      │                         └─ TR trop loin / GPS coupé ──► libère le TR, pénalité -0,5 note,
      │                                                          repasse en_attente + rebroadcast urgence
      │
      └─ Aucun candidat après 10 min ──► besoin_assignation_admin = TRUE + alerte push à tous les admins
                                          ──► assigner_tr_manuel (RPC réservée admin)
```

### 4.2 Fonctions cron impliquées (pg_cron, SQL)

| Fonction | Fréquence | Rôle |
|---|---|---|
| `preactiver_courses_programmees` | 5 min | Verrouille le TR, passe en `pre_active` à J-45min, notifie TR + client |
| `verifier_proximite_heure_h` | 1 min | Vérifie que le TR est à moins de 12 km à l'heure H, sinon libère + pénalise + repasse `en_attente` |
| `declarer_no_shows_expires` | 5 min | Marque `no_show_tr` après 30 min de grâce, pénalise, suspend le TR après 3 no-shows/30 jours |
| `escalader_courses_programmees` | 1 min | Alerte admin si aucun candidat après 10 min |
| `auto_selectionner_courses_en_attente` | 1 min | Filet de sécurité pour les candidatures non résolues en 15s |

⚠️ **Doublon d'architecture relevé** : il existe en parallèle une Edge Function TypeScript (`courses-programmees-cron`) qui réimplémente indépendamment (avec du Haversine en JS) les mêmes rappels J-24h/J-2h/J-45/J-20. Je n'ai trouvé dans le repo aucune trace de ce qui déclenche cette Edge Function — impossible de dire depuis le code seul si c'est elle ou les fonctions SQL cron ci-dessus qui tournent réellement en production. **À vérifier directement dans le dashboard Supabase** (Cron Jobs SQL vs Scheduled Edge Functions), sinon risque de double traitement (deux rappels envoyés, deux vérifications SLA en concurrence).

### 4.3 Colonnes ajoutées pour gérer ce cycle
Sur `courses` : `type_course`, `planifie_le`, `duree_estimee_min`, `pre_active_at`, `rappel_24h_envoye`, `rappel_2h_envoye`, `bonus_urgence_fcfa`, `coefficient_programme`, `majoration_programme_fcfa`, `matching_demarre_at`, `tentatives_matching`, `besoin_assignation_admin`, `escalade_admin_at`, `no_show_at`.
Sur `users` : `locked_until`, `locked_for_course_id`, `programmes_interdits_jusqu` (suspension temporaire après no-shows répétés).

### 4.4 Ce qui reste à câbler côté UI (d'après la doc du 3 juillet)
- Le tableau admin "À assigner" (courses avec `besoin_assignation_admin = TRUE`) n'existe pas encore comme écran — la RPC `assigner_tr_manuel` est prête mais rien dans `CoursesEnCoursAdminScreen.js` ne l'expose pour l'instant.
- L'affichage du "TR le plus proche" côté client (via `transporteursLesPlusProches()`) n'est pas branché sur la carte d'accueil.
- L'élargissement progressif du rayon de recherche (15 → 30 km) avant escalade admin n'est pas implémenté — l'escalade est un tout ou rien après 10 minutes.

---

## 5. Algorithme de matching — comment un TR voit et obtient une course

### 5.1 Comment un TR est notifié
Trois canaux simultanés :
1. **Push Expo** via `notifier-transporteurs` à la création de la course
2. **Realtime Postgres** (`abonnerCoursesEnAttente`, `services/courses.js`) — la course apparaît en direct sur le tableau de bord du TR
3. **Polling de secours** dans `TableauBordScreen.js`

### 5.2 Comment le "plus proche" est calculé
La RPC `transporteurs_proches(lat, lng, rayon_max_km, categorie)` (migration 086) fait du **Haversine en SQL pur** (`6371 * 2 * ASIN(SQRT(...))`) — **pas de PostGIS/`ST_Distance`**, contrairement à ce qu'annonce la stack technique du projet. Elle filtre les TR en ligne, KYC validé, non verrouillés, dans un rayon par défaut de 30 km, triés du plus proche au plus loin, limité à 20 résultats.

Cette RPC sert à deux choses différentes :
- Affichage des TR proches sur la carte client (`TrajetScreen.js`)
- Sélection du TR le plus proche **pour les courses planifiées** (assignation admin / contrôle SLA)

Pour une **course immédiate**, en revanche, le départage entre candidatures ne se fait pas par cette RPC géographique mais par `distance_pickup_km` (une valeur calculée côté client et envoyée avec la candidature) — et comme expliqué en §3.3, dans les faits c'est surtout l'ordre d'arrivée qui tranche.

### 5.3 Refus et non-réponse
- Un TR qui refuse (`refuserCourse()`) fait passer sa candidature à `statut='refuse'`, ce qui exclut la course de sa liste de courses disponibles.
- ⚠️ **Bug historique** : la contrainte SQL sur `candidatures.statut` n'autorisait pas les valeurs `'refuse'`/`'annule_tr'`/`'rejete'` avant la migration 091 — `refuserCourse()` échouait donc silencieusement (l'erreur était avalée par un `.catch()`) jusqu'à cette migration. Si la 091 n'est pas déployée sur ton Supabase de prod, les refus de course ne fonctionnent pas réellement.
- Il n'y a **pas de délai individuel par TR** (pas de "timer 60 secondes" par transporteur) — la course reste disponible pour tous jusqu'à ce qu'un candidat soit retenu, qu'elle expire (1h) ou soit annulée par le client.

---

## 6. Vérification du solde TC et limite KYC — deux vraies barrières serveur

### 6.1 Solde TC insuffisant → candidature bloquée, pas juste l'acceptation
La RPC `candidater_course` (version active, migration 088) calcule la commission (20 % du prix) et compare au solde TC du TR **avant même de créer la ligne de candidature** :
```sql
v_commission := ROUND(prix_fcfa * 0.20);
IF v_solde_tc < v_commission THEN RAISE EXCEPTION 'SOLDE_INSUFFISANT' ...
```
Un TR sans assez de TC ne peut donc **pas du tout candidater** — ni même laisser une trace en base. C'est vrai pour toutes les courses, y compris celles payées en espèces (une version antérieure, migrations 043/055/060, ne vérifiait le solde que pour le paiement `especes` contre l'ancien wallet — corrigé explicitement par la 088).

### 6.2 Limite de 2 courses/mois sans KYC — vraie contrainte serveur
Contrairement à ce qu'on pourrait croire d'un simple message d'interface, c'est bien la RPC serveur qui bloque :
```sql
IF v_kyc_statut NOT IN ('APPROUVE','approuve') THEN
  -- compte les courses terminées ce mois-ci
  IF v_mois_nb >= 2 THEN RAISE EXCEPTION 'LIMITE_KYC_ATTEINTE' ...
```
Côté UI, `TableauBordScreen.js` fait un double contrôle : un compteur local grise déjà le bouton "Candidater" avant même d'appeler le serveur, et intercepte aussi l'exception `LIMITE_KYC_ATTEINTE` si elle survient quand même. Double barrière (UI + serveur), le serveur restant la source de vérité.

---

## 7. Annulations et no-show

### 7.1 Annulation côté client
Le bouton "Annuler" n'est affiché (`peutAnnuler`, `CourseDetailClientScreen.js`) que pour les statuts `en_attente`, `programmee`, `programmee_confirmee` — c'est-à-dire **avant qu'un TR soit en route**. Comme noté en §2, rien côté serveur n'interdit techniquement d'annuler à un autre statut via `annulerCourse()`, c'est une protection purement UI.

Aucune pénalité financière n'est réellement appliquée à l'annulation client : le paramètre `annulation_gratuite_avant_h` (2h, défini en base) n'est référencé par aucun code.

### 7.2 Annulation côté transporteur, avant collecte (statut `acceptee`)
RPC `transporteur_annuler_course_acceptee` (migration 087) :
- Détache le TR de la course (`transporteur_id = NULL`)
- Statut → `annulee_tr`
- Neutralise sa candidature
- **Anti-fraude explicite** : le client ne reçoit jamais l'identité du TR qui a annulé — la notification utilise un template générique sans variable nominative.
Le client peut ensuite relancer la même course (`relancerCourse()`), la modifier, ou annuler définitivement (géré dans `SuiviScreen.js`).

### 7.3 Annulation côté transporteur, après collecte (statut `en_cours`)
Aucune RPC d'annulation trouvée à ce stade — la matrice de transition n'autorise que `en_cours → terminee | litige`. Une fois le colis récupéré, le TR ne peut plus "annuler" ; en cas de problème, la voie est le litige.

### 7.4 No-show du transporteur (courses planifiées uniquement)
`declarer_no_shows_expires` marque la course `no_show_tr` après 30 minutes de grâce passée l'heure prévue, applique une pénalité de -0,5 sur la note du TR, et suspend son accès aux courses planifiées pendant 7 jours après 3 no-shows en 30 jours.

Le client peut alors annuler via une RPC dédiée qui tente un remboursement **si `paiement_statut IN ('sequestre','initie')`**.

⚠️ Cette branche de remboursement est **vestigiale** : comme établi en §3.1 et §3.5, `paiement_statut` n'est jamais écrit par le flux de création actuel (`ConfirmationScreen.js`) — le modèle TC ne passe plus par un séquestre. Concrètement, cette RPC de remboursement ne trouvera jamais les conditions pour s'exécuter sur une course créée aujourd'hui. Ce n'est pas un bug actif (rien ne casse), mais une portion de logique héritée de l'ancien modèle qui ne sert plus à rien dans le flux actuel.

---

## 8. Notation, points de fidélité, litiges

### 8.1 Points de fidélité
Un **trigger DB indépendant** (`crediter_points_course`, déclenché quand `courses.statut` passe à `terminee`) attribue automatiquement 1 point par 100 FCFA (minimum 1 point), plus 50 % pour le parrain le cas échéant. Ce trigger reste actif quel que soit le flux de paiement.

### 8.2 Notation
`soumettreAvis()` insère dans la table `avis`, ce qui déclenche un trigger de recalcul de la note moyenne et du nombre de courses de la cible (client ou TR). La notation elle-même ne génère pas de points — c'est un mécanisme séparé du §8.1.

⚠️ **Système de fidélité avancé probablement cassé pour le flux actuel** : les jalons (paliers 10/20/30/50/100 courses, statut VIP à 100 courses) et le bonus streak hebdomadaire (crédit wallet) ne sont déclenchés que depuis l'ancienne RPC `liberer_sequestre_course` — qui n'est plus appelée par `confirmer_livraison` (la RPC réellement active aujourd'hui, voir §3.5). Autrement dit, **les récompenses de fidélité "jalons" ne se déclenchent probablement plus** pour les courses terminées via le système TC actuel ; seul l'affichage du compteur de streak (un simple comptage, sans écriture) continue de fonctionner visuellement dans `MerciScreen.js`. À vérifier en conditions réelles avant de communiquer sur ce programme auprès des clients.

Notez aussi la coexistence de deux implémentations de fidélité parallèles (`motivation.js`/`jalons.js` lisant des tables différentes, `recompenses_client` vs `jalons_client`) — signe de deux générations de système non totalement unifiées.

### 8.3 Litiges
- **Initiation (client)** : `signalerLitige()` → RPC `signaler_litige`, qui passe la course en `litige` et enregistre le motif, uniquement si la course est déjà `livree`/`terminee`/`en_cours`/`en_route` et appartient bien au client.
- **Résolution (admin)** : il n'existe **pas de RPC dédiée** `resoudre_litige` — `LitigesScreen.js` fait un `UPDATE` direct (`statut = 'terminee' | 'annulee'`, motif), autorisé par une policy réservée aux admins. **Aucune logique de remboursement ou d'ajustement TC n'est déclenchée** à la résolution d'un litige : la commission ayant déjà été débitée à la livraison, trancher un litige en "annulée" ne rembourse pas le client et ne recrédite pas le transporteur. Si un ajustement financier est censé accompagner certaines décisions de litige, il faudrait le faire manuellement aujourd'hui.

---

## 9. Résumé des points d'attention à vérifier avant le lancement

Cette section rassemble, en un coup d'œil, tout ce qui mérite une vérification manuelle sur le Supabase de production avant de considérer le système de courses comme fiable :

| # | Sujet | Risque | Où vérifier |
|---|---|---|---|
| 1 | `calculer_prix` appelée avec un paramètre `p_est_nuit` qui n'existe pas dans sa signature SQL | La majoration de nuit ne s'applique peut-être jamais | Tester un appel RPC direct dans Supabase SQL Editor à une heure de nuit |
| 2 | Aucun filtre géographique sur la diffusion des courses immédiates | Un TR à 40 km reçoit une notification pour une course à 500m d'un autre TR | Vérifier `notifier-transporteurs` en prod, décider si c'est voulu ou à corriger |
| 3 | Deux implémentations parallèles du cron des courses planifiées (SQL pg_cron vs Edge Function `courses-programmees-cron`) | Risque de doubles rappels/doubles vérifications SLA si les deux tournent | Vérifier dans le dashboard Supabase quels jobs sont réellement actifs |
| 4 | Migration 091 (fix statuts `candidatures`) pas forcément déployée | Le bouton "Refuser" d'un TR échoue silencieusement | Vérifier la présence de la migration 091 en prod, tester un refus |
| 5 | Programme de fidélité "jalons" découplé du flux de paiement actif | Les paliers/VIP/bonus streak ne se déclenchent plus | Faire un test de bout en bout : terminer une course au jalon 10, vérifier si la récompense apparaît |
| 6 | Résolution de litige sans ajustement financier automatique | Un litige tranché "annulée" ne rembourse ni ne recrédite personne | Décider si un geste commercial manuel est nécessaire en cas de litige |
| 7 | Aucune restriction serveur réelle sur l'annulation à un statut avancé | Un client pourrait en théorie annuler une course déjà en cours via un appel direct | Décider si la protection UI seule est suffisante pour le lancement |
| 8 | Tableau admin "À assigner" pas encore construit | L'escalade admin sur courses planifiées orphelines n'a pas d'écran pour agir dessus | Prioriser cet écran avant d'activer les courses planifiées en prod |

Ce sont des observations factuelles issues du code, pas des bugs que j'ai "trouvés en testant" — certaines de ces zones grises sont peut-être déjà connues et acceptées comme dette technique temporaire. Je te les liste pour que la décision de les traiter (ou pas) avant le lancement soit consciente plutôt que découverte en production.
