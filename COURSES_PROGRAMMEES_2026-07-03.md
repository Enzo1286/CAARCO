# SYSTÈME DE COURSES PROGRAMMÉES — 3 juillet 2026

Réponse aux 4 exigences. Basé sur l'existant (cron programmées, modèle d'enchère, auto-sélection) — je n'ai pas reconstruit, j'ai comblé les trous.

## Le problème de départ (constaté dans le code)

Aujourd'hui, quand un client crée une course programmée (`ConfirmationScreen.js`), **les transporteurs ne sont jamais notifiés** — le code disait « le matching se fait à J-45min via le cron », mais le cron J-45 ne traite QUE les courses qui ont *déjà* un TR. Résultat : une course programmée sans TR restait orpheline pour toujours. C'est exactement ce que ta demande corrige.

## Ce qui a été implémenté

### 1. Pré-réservation dès la création (exigence 1 + point 2)
`ConfirmationScreen.js` — à la création d'une course programmée, on diffuse maintenant immédiatement aux TR (`notifier-transporteurs`) et on horodate `matching_demarre_at`. Les TR reçoivent la notification, candidatent, et le moteur réserve **le plus proche**.

`migration 086` — `auto_selectionner_tr` gère désormais les deux types : immédiate → `acceptee`, programmée → `programmee_confirmee`. Le sweep pg_cron (chaque minute) traite aussi les programmées. Le TR le plus proche est pré-réservé, puis le cron existant prend le relais (rappel J-2h, verrouillage J-45, contrôle GPS J-20).

### 2. Escalade admin si aucun TR (exigence 3)
`migration 086` — `escalader_courses_programmees()` (pg_cron chaque minute) : si une course programmée reste sans candidature au bout de `escalade_admin_apres_min` (défaut 10 min), elle est marquée `besoin_assignation_admin = TRUE` et **tous les admins reçoivent une alerte push**. La course apparaît alors dans le tableau « À assigner ».

`assigner_tr_manuel(course_id, tr_id)` — RPC réservée admin (`is_admin()`) pour attribuer manuellement un TR depuis ce tableau.

### 3. Le TR le plus proche, borné (exigence 4)
`migration 086` — `transporteurs_proches(lat, lng, rayon_max_km, categorie)` retourne les TR en ligne + KYC dans le rayon (défaut **30 km**), du plus proche au plus loin.
`matching.js` — `transporteursLesPlusProches()` l'appelle et renvoie `{ lePlusProche, aucunDansRayon }`.

**Rappel de mon avertissement** : tu as choisi le bornage à 30 km plutôt que « aucune limite ». C'est le bon choix — au-delà de 30 km, le service renvoie `aucunDansRayon = true` pour afficher un message honnête (« aucun transporteur disponible pour l'instant ») au lieu d'un TR fantôme qui ne viendra jamais.

## Cycle de vie complet d'une course programmée

```
Création (client) ─► diffusion TR immédiate + matching_demarre_at
      │
      ├─ TR candidatent ─► auto_selectionner_tr ─► programmee_confirmee (TR le plus proche réservé)
      │                                                   │
      │                                          rappel J-2h ─► verrou J-45 (pre_active)
      │                                                   │
      │                                          SLA J-20 : TR trop loin / GPS off ?
      │                                              ├─ non ─► exécution
      │                                              └─ oui ─► libère TR, re-broadcast urgence + bonus
      │
      └─ aucun TR après 10 min ─► besoin_assignation_admin=TRUE + alerte admin ─► assigner_tr_manuel
```

## ⚠️ À faire pour activer (je ne peux pas déployer sur ton Supabase)

1. **Migration 086** : Supabase → SQL Editor → coller `App/supabase/migrations/086_moteur_courses_programmees.sql` → Run. (Applique aussi la 085 si pas encore fait.)
2. **Vérifier les settings pg** utilisés par les crons : `app.supabase_url` et `app.service_role_key` (déjà requis par la migration 080 existante).
3. **Edge Function `notifier-transporteurs`** doit être déployée (c'est elle qui diffuse). D'après ta mémoire projet, les Edge Functions n'ont jamais été redéployées — à vérifier.
4. **Rebuild l'app** (les modifs `ConfirmationScreen.js` et `matching.js` sont déjà dans le code).

## Ce qui reste (côté UI, je peux le faire ensuite)

- **Tableau admin « À assigner »** : lister `courses WHERE besoin_assignation_admin = TRUE` + bouton appelant `assigner_tr_manuel`. La RPC est prête ; il manque l'écran (à ajouter dans `CoursesEnCoursAdminScreen` ou un nouvel onglet).
- **Affichage client du TR le plus proche** : brancher `transporteursLesPlusProches()` sur la carte d'accueil / l'écran de réservation pour montrer le plus proche + le message si `aucunDansRayon`.
- **Élargissement progressif du rayon avant escalade** (15→30 km + bonus) : aujourd'hui l'escalade passe direct à l'admin après 10 min ; le ré-élargissement automatique vit dans le cron Edge `courses-programmees-cron` et demanderait un redéploiement.

Dis-moi si j'enchaîne sur le tableau admin « À assigner » et l'affichage carte, ou si tu veux d'abord déployer et tester ce socle.
