# SPRINT 3 — Design, Contraste et Lisibilité
**Statut : Terminé (Validé le 6 juillet 2026)**

Ce sprint s'est concentré sur la rigueur du design system, la correction des problèmes d'accessibilité (contraste) et l'assainissement de la base de code UI.

## 1. Contraste et Accessibilité (Norme AA)
- Remplacement systématique du texte blanc sur fond `Néré` (`#c89441`) par du texte `Charbon` (`#1d2420`) pour garantir la lisibilité (échec AA corrigé).
- Mise à jour globale du bouton `CButton` (variante nere).
- Corrections de contraste sur les bannières de l'écran d'accueil (`Parrainage`, `Récompense`) pour éviter les conflits de mode sombre avec des fonds clairs codés en dur.

## 2. Tokenisation Intégrale
- Suppression de l'intégralité des couleurs codées "en dur" (codes hexadécimaux et rgba isolés) dans l'ensemble des fichiers `src/screens/` et `src/components/`.
- Intégration de la fonction `alpha(hex, opacity)` au `theme.js` pour gérer proprement les opacités des tokens du design system (`colors.bambou`, `colors.foret`, etc.).
- Recomposition des anciens dégradés hors-charte (ex: bleu sur l'accueil) avec la palette officielle Atelier CAARCO.

## 3. Nettoyage de l'UI
- Suppression physique du fichier doublon `SplashScreen.js` (emoji).
- Refonte de `SplashAnimeeScreen.js` pour utiliser nativement les tokens et les polices du `theme.js` au lieu des valeurs "en dur".
- Correction d'un bug logique mineur sur l'écran d'accueil où les "courses programmées" s'affichaient par erreur comme des "courses en cours" (requête Supabase affinée).

**Prochaine étape du Cahier des Charges : SPRINT 4 — Lancement.**
