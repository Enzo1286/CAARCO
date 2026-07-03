# DIAGNOSTIC CAARCO — Application mobile
Audit design + sécurité + bugs · 3 juillet 2026
Périmètre : `D:\CAARCO` (app React Native + Supabase). Le site web `D:\CAARCO-WEB` n'était **pas** accessible dans cette session — non audité ici.

---

## Verdict en une phrase

L'app est fonctionnellement très complète (54+ écrans, 96 migrations, 13 Edge Functions), mais le **pivot vers les Tokens de Course (TC) a introduit deux failles critiques** qui, en l'état, permettent à un transporteur de se créditer des TC gratuitement et d'échapper à la commission de 20 %. Ce sont des bugs de logique serveur, pas de design. À corriger **avant** toute mise en production.

Sévérités : 🔴 Critique · 🟠 Élevé · 🟡 Moyen · 🔵 Mineur

---

## 1. SÉCURITÉ

### 🔴 C1 — N'importe quel utilisateur peut se créditer des TC à l'infini
`supabase/migrations/082_systeme_tokens_tc.sql` (RPC `admin_crediter_tc`, ligne ~89)

La fonction est `SECURITY DEFINER`, **sans aucune vérification que l'appelant est admin**, et **aucun `REVOKE EXECUTE`** n'est posé. Par défaut PostgreSQL/Supabase accorde l'exécution à `PUBLIC` → elle est appelable par tout compte connecté via PostgREST :

```js
// N'importe quel transporteur, depuis un client modifié :
await supabase.rpc('admin_crediter_tc', { p_transporteur_id: monId, p_montant_tc: 100000000 });
```

Résultat : solde TC illimité, gratuit. Comme les TC sont la seule barrière économique du modèle, ceci vide entièrement le business model. **C'est le point le plus grave de l'audit.**

**Correctif :**
- Ajouter en tête de fonction un contrôle de rôle : `IF (SELECT role FROM users WHERE id = auth.uid()) <> 'admin' THEN RAISE EXCEPTION 'Non autorisé'; END IF;`
- Et poser explicitement : `REVOKE EXECUTE ON FUNCTION admin_crediter_tc(UUID, INTEGER) FROM public, authenticated;` puis `GRANT ... TO service_role;` (l'écran admin doit passer par une Edge Function en service_role, pas par un appel RPC direct côté client).

### 🔴 C2 — La commission de 20 % est contournable
`src/services/tokensTC.js` (l.67) + `082_...sql` (`debiter_commission_tc`, l.53) + `NavigationScreen.js` (l.793)

Trois problèmes cumulés :

1. **Montant fourni par le client.** Le débit passe par `debiter_commission_tc(p_course_id, p_transporteur_id, p_commission_tc)` où `p_commission_tc` est calculé **en JS côté client** (`Math.round(prix * 0.20)`). La RPC ne recalcule rien, ne vérifie pas `auth.uid()`, ne vérifie pas que la course est bien livrée. Un TR peut appeler la RPC avec `p_commission_tc = 0`.
2. **Découplé de la livraison.** Côté serveur, `confirmer_livraison` (bien écrite, valide l'OTP) **ne débite pas** la commission — elle appelle encore l'ancien `liberer_sequestre_course`. Le débit TC est un appel **séparé** et **`.catch()` non bloquant** (`NavigationScreen.js` l.793) : s'il échoue ou n'est jamais émis, la course se termine quand même. Aucune réconciliation.
3. **Le plancher masque le solde insuffisant.** `UPDATE ... SET solde_tc = GREATEST(0, solde_tc - p_commission_tc)` : même sans TC, le débit « réussit » en tombant à 0. La règle « TR ne peut pas travailler sans TC » n'est donc pas réellement appliquée au débit.

**Correctif :** faire du débit une opération **serveur atomique, dérivée du prix stocké**. Idéalement, intégrer le débit *dans* `confirmer_livraison` : lire `v_course.prix_fcfa`, calculer `round(prix*0.20)`, débiter dans la même transaction, échouer si solde insuffisant (sauf politique de solde négatif assumée). Supprimer le `p_commission_tc` client. Ajouter `REVOKE EXECUTE` + `auth.uid()` check sur `debiter_commission_tc`.

### 🟠 H1 — Aucune protection d'exécution sur les RPC TC
`082_systeme_tokens_tc.sql`

Aucune des fonctions de la migration (`debiter_commission_tc`, `admin_crediter_tc`, `crediter_tc_achat`, `verifier_solde_tc`) n'a de `REVOKE`/`GRANT`. Toutes exécutables par `PUBLIC`. `crediter_tc_achat` est heureusement idempotente et ne crédite que si une transaction `en_attente` existe déjà (créée côté serveur), donc moins exposée — mais elle devrait quand même être réservée à `service_role`. Politique à généraliser : **toute RPC `SECURITY DEFINER` doit avoir un `REVOKE FROM public` + un `GRANT` ciblé.**

### 🟠 H2 — Contournement de l'OTP en mode hors ligne
`NavigationScreen.js` l.746-753

En mode hors ligne, la livraison est confirmée sans validation OTP : la file d'attente pousse `MAJ_STATUT_COURSE → 'terminee'` directement, court-circuitant `confirmer_livraison` (qui est la seule à valider le code du client). Un TR en « faux hors ligne » peut donc clôturer une course **sans le code du client**, et le débit TC associé est lui aussi « best-effort ». À réconcilier côté serveur au moment de la synchro (rejeter une clôture offline sans OTP, ou re-valider).

### 🟡 M1 — Le prix est calculé côté client puis inséré en DB
`src/services/courses.js` (`creerCourse`, l.20) — `prix_fcfa` provient de `courseData` (client). Aucune Edge Function `calculate-price` n'existe (contrairement à la Section 12 du CLAUDE.md qui l'exige). Sous le modèle TC c'est moins grave (le client paie le TR directement), **mais** la commission dérive de `prix_fcfa` : sous-évaluer le prix = sous-évaluer la commission. Vecteur d'évasion supplémentaire tant que C2 n'est pas corrigé. À terme : prix officiel calculé/validé serveur.

### ✅ Points sécurité corrects (à conserver)
- `notchpay-webhook` : HMAC-SHA256 **obligatoire**, rejet si `NOTCHPAY_HASH_KEY` absent (fail-secure). Bien.
- `confirmer_livraison` : validation OTP serveur, `transporteur_id = auth.uid()`, `FOR UPDATE`. Bien conçue — il faut juste y rattacher le débit TC.
- `supabase.js` : uniquement l'`anon key`, JWT en `SecureStore` (Keychain/Keystore). Correct.
- `notchpay-verifier-paiement` : idempotent, revérifie le statut auprès de Notchpay. Correct.

### 🔵 À vérifier
- `notchpay-init-achat-tc` utilise `NOTCHPAY_PUBLIC_KEY` dans l'en-tête `Authorization`. Vérifier que Notchpay n'attend pas la clé privée (Grant) pour `initialize` — sinon les paiements échoueront en prod.

---

## 2. DESIGN

Le design system (`theme.js`) est propre, complet et bien nommé (palette Atelier CAARCO, polices, galets, ombres). Les problèmes sont dans **l'application** des tokens, pas dans le système.

### 🟡 M2 — Cibles tactiles sous le minimum
`src/components/Galet.js` l.47 : hauteur par défaut **48px**, taille « petit » **40px**. La Section 5 du CLAUDE.md impose **52px minimum** (lisibilité + tactile, usage terrain au soleil, Android mid-range). Le bouton CTA principal est donc sous la spec par défaut. → passer le défaut à 52, « petit » à 44 min.

### 🟡 M3 — 128 couleurs codées en dur dans les écrans
`grep` trouve 128 hex littéraux hors `theme.js`. Deux catégories :
- **Légitimes** : dégradés des cartes véhicules (`AccueilScreen.js` l.126-129) — pas dans la palette, acceptable.
- **À corriger** : neutres/accents qui **doublonnent déjà des tokens** (ex. `#b4c4b9` = `foret30`, `#e8e0d5` ≈ `brume`). Risque d'incohérence visuelle et de dérive à la maintenance. Violent la règle « jamais hardcoder ». → remplacer par `colors.*`.

Fichiers les plus concernés : `AccueilScreen`, `SuiviScreen`, `PaiementScreen`, `PointsScreen`, `ParrainageScreen`, `DashboardScreen` (admin), `ChatScreen`.

### 🔵 Cohérent
Structure des composants Atelier (Galet, Sillon, Plaquette, Pastille…), typographie (Marcellus display / Plus Jakarta body / JetBrains Mono prix), fond `manioc` généralisé. Rien à redire sur les fondations.

---

## 3. BUGS & DETTE TECHNIQUE

### 🟠 H3 — 6 numéros de migration en doublon
Pire que ce que note MEMORY.md. Numéros dupliqués : **056 (×3), 057 (×2), 058 (×2), 060 (×2), 061 (×3), 062 (×2)**. En cas de réinitialisation DB, l'ordre d'application n'est pas déterministe → risque de schéma incohérent (une fonction créée avant sa table, un fix appliqué avant le bug). À **consolider/renuméroter** avant tout `db reset` en production.

### 🟡 M4 — Code mort du modèle financier abandonné (risque Play Store)
Le pivot TC visait justement à retirer toute « activité financière » refusée par Google Play. Or il reste en base et dans le code :
- `confirmer_livraison` appelle toujours `liberer_sequestre_course` (séquestre wallet).
- Écrans encore présents : `WalletScreen`, `RechargeRapideScreen`, `PayerTransporteurScreen`, `RetraitScreen`, `EncaissementScreen`. Le tab `Revenus` (TR) est toujours monté.

Ils semblent déliés de la navigation principale, mais **tant qu'ils sont dans le bundle et référencés**, un reviewer Play Store peut les atteindre → motif de refus identique à la V1. → supprimer (ou isoler derrière un flag mort) le séquestre, le wallet et les retraits.

### 🟡 M5 — Heure de nuit incohérente
`src/services/prix.js` l.35 : `HEURE_DEBUT_DEFAUT = 20` (20h), alors que CLAUDE.md/MEMORY spécifient **22h→5h**. La config DB peut surcharger, mais le fallback par défaut applique la majoration nuit 2h trop tôt. → aligner sur 22, ou trancher et mettre à jour la spec.

### 🔵 Divers
- Racine `D:\CAARCO` polluée par des fichiers parasites (fragments de commandes PowerShell transformés en noms de fichiers : `Math.max(prev`, `charger()`, etc.). À nettoyer, cosmétique mais salissant.
- Toujours **zéro test** (`.test.js` absents). Pour un flux paiement/commission, au moins des tests sur les RPC critiques seraient prudents.

---

## 4. PRIORITÉS (ordre d'action recommandé)

1. 🔴 **C1** — sécuriser `admin_crediter_tc` (contrôle admin + REVOKE). *Quelques lignes SQL, impact maximal.*
2. 🔴 **C2** — débit commission atomique côté serveur, dérivé du prix stocké, intégré à `confirmer_livraison`.
3. 🟠 **H1** — `REVOKE`/`GRANT` sur toutes les RPC TC.
4. 🟠 **H2** — réconcilier la livraison hors ligne (pas de clôture sans OTP).
5. 🟠 **H3** — consolider les migrations dupliquées.
6. 🟡 **M4** — purger le code financier (séquestre/wallet/retrait) avant soumission Play Store.
7. 🟡 M1, M2, M3, M5 — prix serveur, cibles 52px, tokens couleur, heure de nuit.

Les points 1 à 3 sont, à mon avis, bloquants pour une mise en production : en l'état, le modèle économique de CAARCO n'est pas protégé côté serveur.
