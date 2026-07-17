# Assets Play Store — CAARCO

> Préparés en Session 33 (17/07/2026). Le **texte** de la fiche (titre, descriptions
> courte/longue, catégorie) est dans `../PLAY_STORE_FICHE.md`. Ici = les **visuels**.

## ✅ Livrés dans ce dossier

| Fichier | Dimensions | Usage Play Store | Statut |
|---|---|---|---|
| `icon-512.png` | 512×512 | Icône de l'application (obligatoire) | ✅ Prêt (redimensionné depuis `App/assets/icon.png` 1024×1024, bicubique HQ) |
| `feature-graphic-1024x500.png` | 1024×500 | Bandeau « Feature graphic » (obligatoire) | ✅ Draft à valider (voir notes) |

### Notes / points à valider par Cedric
- **Icône** : c'est la marque officielle (arc forêt + disque néré) sur fond clair.
  Vérifier avant upload qu'elle est bien **opaque** (Play Store applique son
  propre masque arrondi ; un fond transparent peut être rendu différemment). Si
  besoin d'un fond, recomposer sur `manioc #fbf9f3` ou `foret #1f3b2a`.
- **Feature graphic** : dégradé forêt→nuit + logo clair + « CAARCO » + tagline +
  les 4 usages officiels. Police du mot « CAARCO » = **Georgia** (serif système),
  approximation de **Marcellus** (police de marque, non installée sur ce poste).
  Pour le rendu exact Marcellus : me le dire, ou refaire dans Canva/Figma avec la
  police embarquée. Couleurs = tokens Atelier CAARCO exacts.

## ⏳ À produire par Cedric (nécessite le téléphone — pas d'émulateur ici)

**Captures d'écran** — obligatoires, min. 2, max. 8.
- **Cible** : 1080×1920 px (ratio 9:16). Les téléphones récents (Tecno/Samsung A)
  capturent souvent plus haut (ex. 1080×2400) — Play Store **accepte** ces ratios ;
  soit uploader tel quel, soit recadrer/redimensionner à 1080×1920.
- **Écrans recommandés** (montrer le parcours + la proposition de valeur) :
  1. **Accueil** (`AccueilScreen`) — carte + CTA « Commander ».
  2. **Commande** (`ConfirmationScreen`/`BookingScreen`) — saisie adresses + prix estimé.
  3. **Suivi temps réel** (`SuiviScreen`) — position GPS du transporteur.
  4. **Mes Tokens** (`MesTokensScreen`) — côté transporteur, solde TC.
  (Optionnel : historique, profil, KYC.)
- **Procédure** :
  1. Lancer l'app sur le téléphone (build de test).
  2. Naviguer sur l'écran, capture native (Power + Volume bas).
  3. Récupérer les PNG (câble/WhatsApp), les déposer ici (ex. `screenshot-1-accueil.png`).
  4. Si recadrage nécessaire à 1080×1920 : n'importe quel éditeur, garder le haut
     (barre de statut) ou la recadrer proprement.

## Récapitulatif exigences Play Store
- Icône : 512×512, PNG 32-bit. ✅
- Feature graphic : 1024×500, PNG ou JPG (pas de transparence utile). ✅
- Captures téléphone : 2 à 8, côté 320–3840 px, ratio entre 16:9 et 9:16. ⏳
- (Facultatif) captures 7"/10" tablette : non requises pour une V1 mobile.
