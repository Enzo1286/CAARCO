# Charte graphique — Carrousels Instagram CAARCO × Binda

**Version :** 1.0 · **Date :** 12 juillet 2026 · **Langue :** français

Cette charte est la référence obligatoire pour chaque carrousel Instagram CAARCO. Elle complète le design system Atelier CAARCO et ne le remplace pas.

## 1. Objectif et territoire

CAARCO doit paraître **limpide, robuste et camerounais** : une autorité chaleureuse, jamais froide ni bancaire. Les carrousels expliquent, rassurent et orientent vers une action unique. Ils évoquent toujours, lorsque le sujet le permet, les quatre usages officiels : livraison express, déménagement, logistique des entreprises et transport ponctuel.

Le ton est direct, concret, positif et utile. On évite les promesses vagues, les chiffres inventés, le jargon et toute allusion à un portefeuille client, à un séquestre ou à un retrait d’argent.

## 2. Formats Instagram

| Usage | Format | Dimensions | Recommandation |
| --- | --- | --- | --- |
| Feed prioritaire | Portrait 4:5 | 1080 × 1350 px | À privilégier : plus de présence dans le fil. |
| Publication carrée | 1:1 | 1080 × 1080 px | Pour les séries, comparatifs et reprises de contenu. |

- Exporter en PNG ou JPEG sRGB, à 1080 px de large.
- Prévoir une marge de sécurité minimale de **96 px** sur les quatre côtés.
- Garder les 16 % inférieurs dégagés de toute information critique : l’interface Instagram peut les masquer.
- Concevoir à taille réelle puis réduire uniquement pour l’aperçu. Une slide doit rester lisible sur un téléphone de 375 px de large.

## 3. Couleurs Atelier CAARCO

| Pigment | Valeur | Utilisation sociale |
| --- | --- | --- |
| Forêt | `#1f3b2a` | Fond principal sombre, titres, voile photo. |
| Bambou | `#3d6b4a` | CTA, repères positifs, éléments d’action. |
| Néré | `#c89441` | Accent rare : chiffre, mot-clé, point du logo, progression. |
| Latérite | `#b8612e` | Alerte ou erreur uniquement ; jamais décoratif. |
| Manioc | `#fbf9f3` | Fond clair principal ; jamais blanc pur. |
| Brume | `#ece9e0` | Cartes, fond secondaire, séparateurs. |
| Cendre | `#6b6f68` | Texte secondaire. |
| Charbon | `#1d2420` | Texte principal sur fond clair. |
| Nuit | `#0f1411` | Fond profond ou fin de dégradé. |

Règle d’équilibre : environ **60 %** de fond (Manioc ou Forêt), **30 %** de soutien (Brume, Forêt ou Bambou) et **10 %** de Néré. Le texte doit conserver un contraste d’au moins 4,5:1.

## 4. Typographie

- **Marcellus** : accroches et titres seulement. Elle donne le caractère calme et premium de CAARCO.
- **Plus Jakarta Sans** : texte courant, étiquettes, puces et CTA.
- **JetBrains Mono** : prix, tokens TC, codes, pagination et données chiffrées.

À l’échelle 1080 px : titre de couverture 88–98 px ; titre de slide 68–78 px ; corps 32–36 px avec interligne 1,45–1,55 ; étiquette en Plus Jakarta Sans ExtraBold 24–28 px avec capitales et espacement ; pagination 28–30 px en JetBrains Mono.

Les montants sont toujours des entiers : `2 500 FCFA`, `5 000 TC`. Jamais de décimales, jamais de séparateur virgule.

## 5. Logos

Utiliser exclusivement les fichiers officiels :

- Fond clair : `App/assets/Logo CAARCO PNG.png`
- Fond Forêt ou Nuit : `App/assets/Logo CAARCO Light PNG.png`

Le logo reste lisible, non déformé et sans ombre. Laisser autour de lui une zone libre au moins égale au diamètre de son disque Néré. Ne jamais modifier ses couleurs ni le poser directement sur une zone photo chargée sans aplat ou voile suffisant.

## 6. Binda — personnage officiel

Si une slide appelle un personnage, **Binda est le seul personnage de marque à utiliser**. Sa référence visuelle est conservée dans `App/assets/Kako_character_reference.jpeg` (nom de fichier historique).

**Repères immuables :** femme camerounaise noire adulte, peau brune chaude, cheveux courts naturels texturés, petits clous d’oreilles dorés, expression confiante et accueillante ; polo vert Forêt CAARCO, jean bleu brut et baskets blanches. Le style est une illustration 3D soignée, douce et professionnelle — jamais photoréaliste, enfantin ou caricatural.

**Rôles de Binda :**

- guide : elle explique une étape ou montre l’application ;
- preuve humaine : elle rassure à côté d’un bénéfice ou d’un chiffre réel ;
- appel à l’action : elle invite à télécharger ou à commencer une course.

**Mise en scène :** placer Binda dans le tiers droit ou gauche, pas au centre du bloc de lecture ; réserver l’autre partie à l’accroche. Sur une slide chargée, préférer un buste ou une pose trois-quarts. Ne pas couper son visage, le logo de son polo ou ses mains de façon involontaire. Le personnage ne doit pas apparaître par défaut : seulement lorsqu’il renforce le message.

Prompt de référence pour une nouvelle illustration :

> Binda, mascotte officielle CAARCO, femme camerounaise noire adulte aux cheveux courts naturels texturés, sourire professionnel et chaleureux, polo vert Forêt CAARCO avec le logo officiel, jean bleu brut, baskets blanches, illustration 3D premium et douce, lumière studio chaleureuse, pose [ACTION], cadrage [CADRAGE], fond [COULEUR/DÉCOR], composition laissant une grande zone vide pour un titre à gauche, sans texte ni logo généré.

Toujours joindre la référence personnage et le logo officiel à la génération. Après génération, vérifier le polo, l’âge adulte, la coiffure, les proportions des mains et l’espace réservé au texte avant intégration.

## 7. Structure d’un carrousel

Un carrousel standard compte **4 slides**. Il peut passer à 5 ou 6 uniquement si chaque slide apporte une idée distincte.

1. **Couverture** — accroche forte, bénéfice clair, logo, indication discrète de glissement.
2. **Problème ou étape 1** — une seule idée, visuel ou Binda si utile.
3. **Solution / preuve** — bénéfice concret, détail ou donnée vérifiée.
4. **CTA** — une seule action : télécharger, écrire, demander une course, partager ou enregistrer.

Chaque slide porte un titre court, du contenu structuré et une image ou un emplacement visuel descriptif. Ne pas empiler plusieurs messages ou plusieurs CTA dans une même slide.

## 8. Composition

- Alignement à gauche par défaut ; centrage seulement pour couverture, chiffre manifeste ou CTA.
- Utiliser une grille simple à une colonne : titre, preuve/explication, visuel, repère bas.
- Les cartes sont en Brume ou blanc, rayon 14 ou 24 px ; les boutons et pastilles sont totalement arrondis.
- Icônes : style linéaire arrondi cohérent, 2 px, Forêt ou Manioc. Pas d’émojis comme icônes.
- Photos : scènes crédibles du Cameroun. Poser un voile Forêt de 55–75 % derrière un texte clair.
- Les animations d’aperçu sont discrètes (opacité/translation, 150–300 ms) et désactivables avec `prefers-reduced-motion`.

## 9. Règles éditoriales

- Français uniquement, phrases courtes, une promesse précise.
- Privilégier les verbes d’action : « Planifiez », « Suivez », « Transportez », « Téléchargez ».
- Ne jamais réduire CAARCO à la livraison de colis.
- Prix et informations produit : ne publier que les règles validées et les données vérifiables.
- Rappeler, lorsque pertinent : le client règle directement le transporteur en espèces ou Mobile Money ; les TC servent aux transporteurs et ne sont ni retirables ni transférables.

## 10. Exigences de production React / Tailwind

Chaque nouvelle demande « Create a carousel on [Sujet] » produit par défaut un carrousel de quatre slides en React avec Tailwind CSS.

- Une donnée `slides[]` contient titre, contenu, type visuel, image/placeholder, repère et CTA éventuel.
- Le composant accepte `format="portrait" | "square"` et conserve les ratios 4:5 ou 1:1.
- Les images utilisent une URL fournie ou un espace réservé descriptif ; Binda utilise sa référence ci-dessus lorsqu’un personnage est requis.
- Prévoir `alt` descriptif, contraste AA, absence de défilement horizontal et aperçu adapté mobile/desktop.
- À la demande « Make slide X more engaging », modifier uniquement la slide concernée, sans casser la cohérence de la série.
- À la demande « Export each slide as an image », générer une image distincte par slide, nommée `sujet-01-4x5.png`, etc.

## 11. Contrôle avant publication

- [ ] Format 1080 × 1350 ou 1080 × 1080 confirmé.
- [ ] Une idée principale et une seule action par slide.
- [ ] Palette, typos et logo CAARCO officiels appliqués.
- [ ] Binda conforme à la référence, si un personnage est présent.
- [ ] Textes lisibles, contraste AA et marges sûres respectés.
- [ ] Chiffres, montants et promesses vérifiés.
- [ ] CTA final unique et clair.
