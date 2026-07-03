# CORRECTIONS APPLIQUÉES — 3 juillet 2026
Suite au diagnostic (`DIAGNOSTIC_AUDIT_2026-07-03.md`). Voici ce qui a été corrigé, où, et ce qu'il te reste à faire pour activer les correctifs serveur.

---

## ⚠️ ACTION REQUISE DE TA PART (sinon les failles critiques restent ouvertes)

Les correctifs de sécurité sont dans une **migration SQL** que je ne peux pas appliquer à ta place. Tant qu'elle n'est pas exécutée sur Supabase, C1 et C2 restent exploitables en production.

1. Ouvre Supabase → **SQL Editor** → copie-colle le contenu de
   `App/supabase/migrations/085_securite_tc_et_courses.sql` → **Run**.
   (La migration est idempotente : ré-exécutable sans risque.)
2. Vérifie qu'aucune erreur ne remonte (fonctions recréées, trigger créé, policy créée).
3. Rebuild l'app (les modifs client sont déjà dans le code) : `eas build` ou build local.

---

## 🔴 Sécurité — corrigé

### C1 — Crédit TC illimité gratuit
`085_...sql` → `admin_crediter_tc` : ajout du contrôle `is_admin()` + `REVOKE` de PUBLIC.
Avant, n'importe quel compte connecté pouvait s'octroyer des TC à volonté.

### C2 — Commission 20 % contournable
- `085_...sql` → `debiter_commission_tc(p_course_id)` : **1 seul argument**, commission =
  20 % du `prix_fcfa` **stocké en base** (plus jamais fournie par le client), vérif
  appelant = transporteur assigné, **idempotente**.
- `085_...sql` → `confirmer_livraison` : débite la commission **dans la même transaction**
  que la clôture (atomique). Le séquestre wallet (obsolète) en a été retiré.
- Client aligné : `src/services/tokensTC.js`, `src/screens/transporteur/NavigationScreen.js`
  (plus d'appel séparé), `src/services/offlineQueue.js`.

### OTP contournable (online + offline) — corrigé
La policy RLS `courses_update` laissait un TR passer une course en `terminee` en direct,
sans OTP. `085_...sql` ajoute :
- Trigger `trg_courses_protege` : bloque, pour les non-admins, le passage à `terminee`
  hors `confirmer_livraison`, et fige `prix_fcfa` + `otp_livraison`.
- Policy `courses_admin_update` (résolution de litiges par l'admin).

### H2 — Livraison hors ligne sans OTP — corrigé
`NavigationScreen.js` + `offlineQueue.js` : le mode hors ligne exige maintenant l'OTP et
**rejoue `confirmer_livraison`** à la synchro (validation serveur + débit atomique).
Nouvelle action de file `CONFIRMER_LIVRAISON`.

### H1 — RPC exécutables par tous — corrigé
`085_...sql` : `REVOKE`/`GRANT` explicites sur toutes les fonctions TC
(`crediter_tc_achat` réservée au `service_role`, etc.).

---

## 🟡 Design & bugs — corrigé

| Point | Fichier | Changement |
|---|---|---|
| M2 — cibles tactiles | `src/components/Galet.js` | défaut 48→**52px**, petit 40→44px |
| M5 — heure de nuit | `src/services/prix.js` | défaut `HEURE_DEBUT` 20h→**22h** (spec) |
| M3 — couleurs | 8 fichiers | **28** hex doublons de tokens → `colors.*` |
| M4 — séquestre | `085_...sql` | retiré de `confirmer_livraison` |
| M4 — bundle | `src/navigation/ClientNavigator.js` | import orphelin `PaiementScreen` retiré |

M3 : seuls les doublons exacts entre guillemets ont été convertis, hors `#ffffff`
(aucun gain visuel) et hors fichiers carte/WebView (les tokens JS n'y fonctionnent pas).

---

## 🟠 NON corrigé volontairement (à traiter par toi, avec justification)

1. **Migrations dupliquées (H3)** — 056/057/058/060/061/062. Je n'ai **pas** renuméroté :
   renommer des migrations déjà appliquées en prod casse l'historique Supabase.
   Approche sûre : bascule vers des noms timestamp pour les futures, et une migration
   de consolidation datée avant tout `db reset`.

2. **Boutons `navigate('Paiement')` morts** — AccueilScreen (~600) et SuiviScreen
   (`payerAvance` ~253, `useEffect` ~239) pointent vers une route supprimée. Retrait à
   faire **avec QA visuelle** (je ne peux pas tester l'app ici, et ce sont des écrans
   actifs — je n'y touche pas à l'aveugle).

3. **6 fichiers d'écrans financiers morts** — désormais 0 import, hors bundle. La
   suppression de fichiers est bloquée dans cet environnement → à supprimer depuis VS Code :
   `WalletScreen`, `RechargeRapideScreen`, `PaiementScreen`, `PayerTransporteurScreen`,
   `RetraitScreen`, `EncaissementScreen`.

4. **Prix calculé côté client (M1)** — sous le modèle TC c'est secondaire, mais idéalement
   le prix officiel devrait être validé serveur. Non traité (chantier séparé : Edge Function).

---

## À vérifier après déploiement
- Un TR livre une course en ligne → course `terminee` + `solde_tc` diminué de 20 % du prix.
- Le même TR tente `supabase.rpc('admin_crediter_tc', ...)` → **erreur NON_AUTORISE**.
- Un TR tente `supabase.from('courses').update({statut:'terminee'})` → **bloqué par le trigger**.
- Livraison hors ligne puis retour réseau → `confirmer_livraison` rejouée, OTP validé.
- L'admin résout un litige (passe une course en `terminee`/`annulee`) → **OK**.
