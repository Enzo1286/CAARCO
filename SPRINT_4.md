# CAARCO — Sprint 4 : Lancement
**Créé le 7 juillet 2026, à la clôture du Sprint 2/Sprint 3.** Rédigé en français (consigne Cedric). Périmètre : Cahier des Charges REV1 §0.4, items 20-22.

---

## Où on en est

**Item 20 (tests automatisés flux d'argent) : écriture terminée (7 juillet 2026), exécution en prod refusée par Cedric (choix conscient).** 6 fichiers de tests SQL au total dans `App/supabase/tests/` (5 initiaux + 1 issu de l'investigation prix, voir ci-dessous), sur le modèle déjà établi par `095_conflit_horaire_planifie_test.sql` (blocs `DO $$ ... $$` avec `ASSERT`, pas de framework Jest — la logique testée est en PL/pgSQL côté serveur, pas en JS). Cedric a explicitement autorisé d'autres actions en prod ce jour-là (lecture migration 096, déploiement 097) mais pas l'exécution des tests — à faire par lui sur un environnement de test. Détail en fin de document (§ Item 20 — livré).

**Item 21 (assets store) : texte fait (7 juillet 2026), visuels pas commencés.** Descriptions courte/longue + métadonnées rédigées dans `PLAY_STORE_FICHE.md`, prêtes à coller dans Play Console. Icône 512px, feature graphic 1024×500 et screenshots restent à produire — hors du périmètre "fichiers + terminal".

**Item 22 (test fermé transporteurs fondateurs → production) : pas commencé.** Dépend de l'item 21 et d'actions externes (recrutement des TR fondateurs, cf. `ETAT_DU_PROJET_2026-07-05.md`).

**Hors périmètre initial, fait le 7 juillet 2026 : `OnboardingScreen` (3 slides).** Écran prévu au Cahier des Charges (Phase 1.2) mais absent du code — construit et câblé dans `RootNavigator.js` (affiché une seule fois avant la première connexion, jamais à un utilisateur déjà authentifié, persistance via le même mécanisme AsyncStorage que les tutoriels in-app existants). i18n FR/EN complet. Non testé sur device (pas d'émulateur disponible ici) — à valider par Cedric.

## Ce qui doit survivre sans y toucher

- Tout ce qui est verrouillé dans `SPRINT_2.md` § Ce qui doit survivre sans y toucher (flux OTP, débit commission atomique, RLS, `courses_protege_update`, modèle TC, absence de séquestre/wallet client)

---

## Item 20 — livré

**Constat de départ** (`ETAT_DU_PROJET_2026-07-05.md`) : zéro test automatisé sur les flux d'argent. Risque identifié : régression silencieuse sur le revenu (crédit TC gratuit, commission contournable). Le Cahier des Charges limite volontairement le périmètre à "5 à 10 tests ciblés uniquement : débit atomique, idempotence, OTP, quota KYC, transitions de statut — pas une suite complète".

**Choix technique** : pas de Jest. La quasi-totalité de la logique à risque (débit TC, vérification OTP, quota KYC, transitions de statut) vit dans des RPC PL/pgSQL (`debiter_commission_tc`, `crediter_tc_achat`, `confirmer_livraison`, `candidater_course`, `changer_statut_course`), pas dans du JS testable unitairement — un test Jest qui mockerait Supabase ne testerait que la coquille d'appel, pas la logique elle-même. Écrire des tests SQL directs (`ASSERT` en PL/pgSQL, exécutés à la main dans le SQL Editor) teste la vraie logique, sans dépendance à un environnement de test Postgres local ou à pgTAP (non installé sur ce projet).

**5 fichiers créés** dans `App/supabase/tests/` (10 scénarios au total, README ajouté pour l'exécution) :
- `082_crediter_tc_achat_test.sql` — crédit + idempotence webhook Notchpay rejoué
- `085_debiter_commission_tc_test.sql` — débit atomique (20 % du prix stocké) + idempotence + plancher à zéro
- `085_confirmer_livraison_otp_test.sql` — OTP incorrect = aucune mutation ; OTP correct = transition + débit atomiques
- `088_candidater_course_kyc_test.sql` — quota 2 courses/mois sans KYC, KYC approuvé non limité
- `092_changer_statut_course_test.sql` — transition hors matrice refusée ; UPDATE direct sur course `en_cours` bloqué par le trigger
- `097_calculer_prix_test.sql` — majoration nuit correctement appliquée + rétrocompatibilité de l'appel à 4 arguments (voir § Divergence prix.js ci-dessous pour le contexte)

**Non fait** : l'exécution réelle. Cet environnement n'a pas d'accès Supabase (pas de MCP configuré, cf. `[[project_sprint_status]]`) — ces scripts n'ont donc **pas été vérifiés contre une vraie base**. Ils ont été écrits à partir d'une lecture attentive des migrations qui définissent chaque fonction (dernière version de chacune : 085 pour `debiter_commission_tc`/`confirmer_livraison`, 082 pour `crediter_tc_achat`, 095 pour `candidater_course`, 092 pour `changer_statut_course`/le trigger), mais une erreur de colonne ou une hypothèse fausse sur `auth.uid()` (voir § Hypothèse dans le README) ne serait détectée qu'à l'exécution. **À faire par Cedric avant de considérer l'item 20 clos** : exécuter les 6 fichiers dans le SQL Editor sur un environnement de test, corriger si un `ASSERT` échoue pour une raison qui n'est pas un vrai bug applicatif (ex. colonne renommée depuis).

**Divergence `prix.js` — creusée jusqu'au bout (7 juillet 2026), deux constats.**

1. **Pas de faille de sécurité.** Hypothèse initiale infirmée : `App/src/services/prix.js` (`calculerPrixAvecTarifs`, marqué "ESTIMATION AFFICHAGE UNIQUEMENT") n'est utilisé que pour l'aperçu de prix affiché pendant la saisie (`TrajetScreen.js`, état `prixEstime`). Le prix réellement stocké dans `courses.prix_fcfa` vient bien du serveur dans les deux cas : RPC `calculer_prix` pour les courses immédiates, Edge Function `tarifer-course-programmee` pour les courses planifiées (`ConfirmationScreen.js` lignes 145-175 et 258 — le commentaire en tête de ce bloc dit explicitement "Prix autoritatif depuis le serveur, jamais calculé côté client"). CLAUDE.md Section 2 documente une formule uniforme (`PRIX_BASE_FCFA`/`PRIX_PAR_KM` fixes) qui est simplement obsolète : le modèle réel, actif depuis la migration 026, est par véhicule (tarif_km + frais_fixes + suppléments poids/volume depuis `parametres_tarifs`). Pas d'action requise sur ce point, CLAUDE.md pourrait être mis à jour un jour mais ce n'est que de la documentation.

2. **Bug suspecté, puis vérifié comme déjà corrigé en prod (mais jamais commité).** `ConfirmationScreen.js` appelle `calculer_prix` avec un paramètre `p_est_nuit` — mais aucune migration commitée (025 ou 026, les deux seules à définir cette fonction) ne déclarait ce paramètre : la signature commitée était à 4 arguments. Vérification directe en production (API Management, lecture seule, 7 juillet 2026) : la fonction existe en **deux versions surchargées** — la 4-arguments de la 026, et une 5-arguments avec `p_est_nuit` qui **applique déjà correctement** la majoration nuit (lue depuis `configurations_systeme.majoration_nuit_pct`, défaut 0.20). Quelqu'un a donc appliqué ce correctif à la main via le SQL Editor à un moment donné, sans jamais le reverser dans une migration — même schéma de drift que 085/092 avant leur propre commit. **Rien n'était cassé, aucune correction n'était nécessaire.**

`097_calculer_prix_majoration_nuit.sql` documente maintenant cette version exacte (copie fidèle via `pg_get_functiondef`, pas une réécriture — une première version de ce fichier, écrite avant la vérification en prod, aurait régressé les tarifs de repli du camion : 700 FCFA/km + 500 frais fixes au lieu des 1000/10 000 réellement actifs). Droits d'exécution (`anon`, `authenticated`) déjà corrects en prod, vérifiés. **Migration non exécutée** — inutile, `CREATE OR REPLACE` avec un corps identique à l'existant est un no-op, ça n'aurait fait qu'écrire pour rien sur la prod. Elle sert uniquement à ce que le dépôt git reflète enfin la réalité de la base. Test ajouté quand même : `App/supabase/tests/097_calculer_prix_test.sql` (majoration appliquée + rétrocompatibilité 4 arguments) — utile pour détecter une régression future.

**Trouvé en marge, pas traité (mineur)** : les tarifs de repli de camion diffèrent entre trois endroits — `calculer_prix` en prod (1000 FCFA/km, 10 000 frais fixes), `prix.js` côté client (700 FCFA/km, 5 000 frais fixes) et l'Edge Function `tarifer-course-programmee` (700 FCFA/km, 5 000 frais fixes, pas de repli camionnette/tricycle distinct). Ces valeurs de repli ne s'activent que si `parametres_tarifs` ne contient pas la ligne du véhicule concerné — normalement toujours peuplée, donc impact réel probablement nul, mais à examiner si un jour `parametres_tarifs` est vidée par erreur.

---
