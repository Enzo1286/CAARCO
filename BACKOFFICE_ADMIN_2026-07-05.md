# CAARCO — Back-office administrateur : fonctionnement actuel et accès sélectifs
**Date du scan : 5 juillet 2026** · Reconstitué depuis le code (`AdminShell.js`, les 18 écrans `App/src/screens/admin/`, et les migrations SQL de sécurité).

---

## 1. Comment fonctionne le back-office aujourd'hui

### 1.1 Un rôle unique, binaire
Toute la sécurité admin repose sur une seule fonction SQL, `is_admin()` (migration 029) :
```sql
CREATE FUNCTION is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin');
$$;
```
La colonne `users.role` n'accepte que trois valeurs : `client`, `transporteur`, `admin`. **Il n'existe aucune notion de sous-rôle, de niveau, ou de permission granulaire nulle part dans le code actuel** — ni table de permissions, ni colonne `niveau_admin`, ni système RBAC. J'ai vérifié spécifiquement (recherche de `permissions`, `niveau_acces`, `rbac`, `access_level` dans tout le code) : rien de tel n'existe.

**Conséquence concrète : un compte admin a accès à 100 % du back-office, ou 0 %. Il n'y a pas d'entre-deux.** Quelqu'un qui a le rôle `admin` peut :
- Voir toutes les finances et les soldes TC de tous les transporteurs
- Créditer des TC à n'importe quel compte
- Supprimer ou remettre à zéro n'importe quel compte client/transporteur
- Activer le mode maintenance qui bloque toute l'application
- Résoudre les litiges, valider les KYC, configurer les tarifs
- Lancer une remise à zéro totale des données de test (zone danger)

Il n'y a **aucun moyen aujourd'hui** de créer un compte admin "restreint" — par exemple un accès lecture seule aux statistiques, comme tu le décris pour un actionnaire.

Le passage au rôle admin se fait uniquement via la RPC `changer_role_utilisateur` (migration 084), qui **interdit explicitement** de basculer vers `admin` depuis l'app (`IF p_nouveau_role NOT IN ('client', 'transporteur')`) — un compte admin ne peut donc être créé/promu que directement en base (SQL Editor Supabase), jamais depuis l'interface. C'est une bonne pratique de sécurité, mais ça confirme qu'il n'y a aujourd'hui aucune UI de gestion des admins eux-mêmes.

### 1.2 Navigation : AdminShell.js
Le back-office est un shell de navigation unique (`AdminShell.js`) qui héberge les 18 écrans admin en interne (pas de vraie navigation par route — un état React qui bascule l'écran affiché). Il propose :
- Une sidebar fixe en desktop (220px), un overlay coulissant en mobile
- 6 sections de menu : **GESTION** (vue d'ensemble, opérations live, courses, KYC, litiges), **UTILISATEURS** (transporteurs, clients, utilisateurs), **FINANCES** (finances, tokens TC), **MARKETING** (campagnes, notifications, calendrier, publicités), **CARTE** (lieux à valider), **SYSTÈME** (configuration/paramètres)
- Un bouton de déconnexion avec confirmation

Comme la sidebar est construite en dur dans `AdminShell.js` (une liste statique d'items de menu), **tout compte avec `role='admin'` voit exactement le même menu, sans aucune variation possible** — le code ne contient aucune logique de type "afficher cet item seulement si...".

### 1.3 Les 18 écrans du back-office et ce qu'ils permettent

| Écran | Ce qu'il permet | Sensibilité |
|---|---|---|
| DashboardScreen | Vue d'ensemble CA/commissions/TR en ligne, **activer/désactiver la maintenance globale** | 🔴 Critique (bloque toute l'app) |
| OperationsAdminScreen | Carte temps réel de la flotte et des courses actives | 🟡 Lecture |
| CoursesEnCoursAdminScreen | Voir/filtrer toutes les courses, assigner/désassigner un TR sur une course planifiée | 🟠 Opérationnel |
| TransporteursAdminScreen | **Créditer des TC gratuitement**, suspendre/réactiver/supprimer un compte TR | 🔴 Critique (impact financier direct) |
| ClientsAdminScreen | Suspendre/réactiver/supprimer un compte client | 🟠 Sensible (données personnelles) |
| UtilisateursScreen | Liste en lecture de tous les comptes | 🟡 Lecture |
| KYCValidationScreen | Approuver/rejeter les dossiers d'identité des TR | 🟠 Sensible |
| LitigesScreen | Trancher un litige (valider/annuler une course) | 🟠 Sensible |
| FinancesAdminScreen | Voir tous les KPI financiers (commissions, ventes TC, alertes soldes) | 🔴 Confidentiel |
| RetraitsAdminScreen | Historique complet des transactions TC + soldes de tous les TR | 🔴 Confidentiel |
| MarketingAdminScreen | Activer des packs, créer des codes promo | 🟡 Opérationnel |
| ConfigTarifsScreen | Modifier les tarifs en live, **remise à zéro totale des données** | 🔴 Critique |
| CampagnesPushScreen | Envoyer des notifications push segmentées à tous les utilisateurs | 🟠 Sensible |
| NotificationsAdminScreen | Modifier les textes de toutes les notifications système | 🟡 Opérationnel |
| PublicitesAdmin | Gérer les bannières publicitaires in-app | 🟢 Faible |
| LieuxAdminScreen | Valider les lieux proposés par les utilisateurs | 🟢 Faible |
| CalendrierActionsScreen | Vue agrégée des actions marketing planifiées | 🟡 Lecture |
| AdminShell | Le conteneur lui-même | — |

La colonne "Sensibilité" est ma propre lecture, pas quelque chose codé dans l'app — elle sert à montrer que **des écrans à fort impact (crédit TC, suppression de comptes, reset total, maintenance globale) sont aujourd'hui protégés exactement de la même façon qu'un simple écran de lecture de statistiques** : par la seule appartenance au rôle `admin`.

---

## 2. Ta demande : un accès sélectif pour un actionnaire ("voir uniquement les statistiques des courses")

**Verdict : ce n'est pas possible aujourd'hui, il faut le construire.** Ce n'est ni une case à cocher cachée, ni une fonctionnalité désactivée — la notion même de "rôle partiel" n'existe pas dans le schéma de données. Voici comment je le construirais.

### 2.1 Principe général : un système de permissions par module
Ajouter une table de permissions, indépendante du `role` binaire actuel, qui accorde des accès **par module** (calqués sur les sections de la sidebar) et **par niveau** (lecture seule vs lecture/écriture) :

```sql
CREATE TABLE admin_acces (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  module      TEXT NOT NULL CHECK (module IN (
                'dashboard', 'operations', 'courses', 'transporteurs',
                'clients', 'utilisateurs', 'kyc', 'litiges', 'finances',
                'tokens_tc', 'marketing', 'config', 'carte'
              )),
  peut_voir      BOOLEAN NOT NULL DEFAULT TRUE,
  peut_modifier  BOOLEAN NOT NULL DEFAULT FALSE,
  accorde_par    UUID REFERENCES users(id),
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, module)
);
```

Avec ça, ton exemple ("un actionnaire qui voit uniquement les statistiques des courses") devient une seule ligne :
```sql
INSERT INTO admin_acces (user_id, module, peut_voir, peut_modifier)
VALUES ('<id-actionnaire>', 'courses', TRUE, FALSE);
```

### 2.2 Ce qu'il faut changer pour que ça fonctionne réellement

1. **Créer un nouveau rôle intermédiaire**, par exemple `admin_limite`, distinct de `admin` — pour continuer à distinguer "super-admin fondateur" (toi) de "admin à accès restreint" (actionnaire, futur employé). Le `admin` plein reste ton rôle, `admin_limite` devient le rôle des comptes à accès partiel.
2. **Remplacer `is_admin()` par une fonction plus fine**, par exemple `a_acces(p_module TEXT, p_ecriture BOOLEAN DEFAULT FALSE)` :
   ```sql
   CREATE FUNCTION a_acces(p_module TEXT, p_ecriture BOOLEAN DEFAULT FALSE)
   RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
     SELECT EXISTS (
       SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
       UNION
       SELECT 1 FROM admin_acces a
         WHERE a.user_id = auth.uid()
           AND a.module = p_module
           AND (NOT p_ecriture OR a.peut_modifier)
     );
   $$;
   ```
   Un `admin` plein garde un accès total (première branche du `UNION`) ; un `admin_limite` n'a que ce qui lui est explicitement accordé.
3. **Reprendre chaque policy RLS admin** (`courses_admin_update`, `retraits_admin_select`, etc.) pour appeler `a_acces('module', ...)` au lieu de `is_admin()` — c'est le travail le plus long, car il faut le faire table par table, mais c'est la seule façon que la restriction soit **réellement appliquée côté serveur** et pas seulement cachée dans l'interface (sinon un actionnaire un peu curieux pourrait interroger l'API Supabase directement et voir des données qu'il ne devrait pas voir).
4. **Adapter `AdminShell.js`** pour ne construire la sidebar qu'à partir des modules auxquels l'utilisateur connecté a accès (`peut_voir`), et griser/masquer les boutons d'action (crédit TC, suppression, etc.) selon `peut_modifier`.
5. **Construire un nouvel écran "Gestion des accès"**, réservé au `admin` plein, listant les comptes `admin_limite` et permettant de cocher/décocher leurs modules — c'est l'écran depuis lequel tu ferais concrètement "je donne à cet actionnaire l'accès aux statistiques de courses uniquement".
6. **Créer un écran de statistiques dédié et épuré** pour ce cas d'usage précis : plutôt que de donner accès à `CoursesEnCoursAdminScreen` (qui permet aussi d'assigner/désassigner des transporteurs), il vaut mieux prévoir une vue purement analytique (comme les blocs déjà présents dans `DashboardScreen` : CA, nombre de courses, taux de livraison, activité 24h) sans aucun bouton d'action. C'est plus sûr et correspond mieux à ce qu'un actionnaire attend réellement (des chiffres, pas des leviers opérationnels).

### 2.3 Ordre de priorité recommandé
Si tu veux avancer sur ce point, je recommande cet ordre :
1. D'abord un écran statistiques en lecture seule dédié (§2.2 point 6) — livrable rapidement, valeur immédiate même sans le système de permissions complet.
2. Ensuite la table `admin_acces` + la fonction `a_acces()` + le nouveau rôle `admin_limite` — la fondation technique.
3. Enfin l'écran "Gestion des accès" pour que tu puisses accorder/retirer des droits toi-même sans repasser par SQL à chaque fois.

Fait dans cet ordre, tu peux donner un accès fonctionnel à ton premier actionnaire dès l'étape 1 (en créant son compte `admin_limite` et en pointant manuellement, via SQL, vers l'écran statistiques), sans attendre que tout le système de permissions soit terminé.

## Ce que j'en pense

Le choix actuel (rôle admin binaire, tout ou rien) est défendable pour une V1 avec une seule personne aux commandes — c'est simple et il n'y a pas de surface d'attaque supplémentaire. Mais dès que tu impliques un actionnaire ou une deuxième personne dans l'équipe (ce qui semble être ton besoin immédiat), le "tout ou rien" devient un vrai risque : soit tu ne donnes accès à personne d'autre (ce qui limite la transparence avec tes parties prenantes), soit tu donnes un accès admin complet à quelqu'un qui n'a besoin que de voir des chiffres — ce qui l'expose par erreur à des boutons comme "Remise à zéro totale" ou "Créditer TC (admin)". Je ne le construirais pas avant d'en avoir vraiment besoin, mais je le mettrais en haut de la liste dès que le premier partenaire externe doit avoir un œil sur les chiffres.
