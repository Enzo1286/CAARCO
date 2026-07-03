// ============================================================
//  CAARCO — Design Tokens React Native
//  Source : Atelier CAARCO Design System v0.1 · Mai 2026
//  Usage  : import { colors, fonts, spacing, radius, shadows, components } from './theme'
// ============================================================

// ─── PIGMENTS (Couleurs) ────────────────────────────────────
export const colors = {

  // Couleurs de marque
  foret:       '#1f3b2a',   // vert profond primaire — fond sombre, titres, CTA principal
  foret90:     '#284a36',   // vert légèrement plus clair (hover)
  foret70:     '#426356',   // vert moyen (icônes secondaires)
  foret30:     '#b4c4b9',   // vert pâle (texte sur fond sombre)
  foret10:     '#e6ede7',   // vert très clair (fond focus, hover léger)

  bambou:      '#3d6b4a',   // vert action — boutons succès, toggles actifs
  bambouSoft:  '#cfdbcf',   // vert doux — fond chips bambou, progress

  nere:        '#c89441',   // or chaud — accent, prix, highlights
  nereSoft:    '#f1e3c2',   // or pâle — fond calicots, pastilles néré

  laterite:    '#b8612e',   // terre cuite — erreurs, alertes rares
  lateriteSoft:'#f1d6c3',  // laterite pâle — fond erreur

  // Neutres
  manioc:      '#fbf9f3',   // crème principal — fond de l'app
  brume:       '#ece9e0',   // fond secondaire — cartes, bordures
  cendre:      '#6b6f68',   // gris moyen — texte secondaire, placeholders
  charbon:     '#1d2420',   // encre — texte principal
  nuit:        '#0f1411',   // fond sombre profond — header sombre, toasts

  // Blanc pur
  blanc:       '#ffffff',
};

// ─── PLUMES (Typographie) ──────────────────────────────────
// Note : Expo — installer avec : npx expo install expo-font @expo-google-fonts/marcellus @expo-google-fonts/plus-jakarta-sans @expo-google-fonts/jetbrains-mono
export const fonts = {
  display: 'Marcellus_400Regular',          // Titres, h1, h2, h3 — serif élégant
  body:    'PlusJakartaSans_400Regular',     // Corps de texte — sans-serif lisible
  bodyMedium: 'PlusJakartaSans_500Medium',  // Corps medium
  bodySemi: 'PlusJakartaSans_600SemiBold',  // Corps semi-bold (boutons)
  bodyBold: 'PlusJakartaSans_700Bold',      // Corps bold
  mono:    'JetBrainsMono_400Regular',      // Labels mono, prix, codes
  monoMedium: 'JetBrainsMono_500Medium',   // Labels mono emphasis
};

// Tailles de texte
export const fontSizes = {
  h1:       48,   // Titres d'écran
  h2:       36,   // Titres de section
  h3:       24,   // Titres de composant (Alcôve, Plaquette)
  lede:     20,   // Texte intro
  body:     16,   // Corps standard
  bodyLg:   18,   // Corps large
  bodySm:   15,   // Corps carte, input
  caption:  14,   // Descriptions
  small:    13,   // Notes, aide
  xs:       11,   // Labels mono, eyebrows
  xxs:      10,   // Grains, labels chips très petits
};

// Line heights
export const lineHeights = {
  tight:    1.02,
  display:  1.05,
  heading:  1.15,
  body:     1.55,
  relaxed:  1.7,
};

// ─── CADENCES (Espacement) ─────────────────────────────────
export const spacing = {
  pas:      4,    // micro
  pause:    8,    // petit
  souffle:  12,   // inter-éléments proches
  arret:    16,   // standard
  couloir:  24,   // confortable
  patio:    32,   // section
  parvis:   48,   // grand écart
  place:    64,   // hero
  horizon:  96,   // très grand
};

// ─── GALETS (Rayons de bordure) ───────────────────────────
export const radius = {
  xs:   4,
  sm:   8,
  md:   14,
  lg:   24,
  full: 999,   // pilule complète
};

// ─── OMBRES (Élévations) ──────────────────────────────────
// Pour React Native, shadowColor/offset/radius/elevation (Android)
export const shadows = {
  voilage: {  // légère — cartes au repos
    shadowColor: '#1f3b2a',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 3,
    elevation: 2,
  },
  canopee: {  // medium — cartes en hover, bandeaux
    shadowColor: '#1f3b2a',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 12,
    elevation: 6,
  },
  futaie: {   // forte — modales, alcôves
    shadowColor: '#1f3b2a',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.14,
    shadowRadius: 24,
    elevation: 12,
  },
};

// ─── PIÈCES — Styles de composants ────────────────────────

export const components = {

  // ── GALET (Button) ──────────────────────────────────────
  // Correspondance lexique : Galet = Button
  galet: {
    // Base commune
    base: {
      borderRadius: radius.full,
      paddingVertical: 12,
      paddingHorizontal: 22,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.pause,
    },
    // Variantes
    primaire: {
      backgroundColor: colors.foret,
    },
    primaireText: {
      color: colors.manioc,
      fontFamily: fonts.bodySemi,
      fontSize: fontSizes.bodySm,
    },
    secondaire: {
      backgroundColor: 'transparent',
      borderWidth: 1.5,
      borderColor: colors.foret,
    },
    secondaireText: {
      color: colors.foret,
      fontFamily: fonts.bodySemi,
      fontSize: fontSizes.bodySm,
    },
    fantome: {
      backgroundColor: 'transparent',
    },
    fantomeText: {
      color: colors.foret,
      fontFamily: fonts.bodySemi,
      fontSize: fontSizes.bodySm,
    },
    accent: {
      backgroundColor: colors.nere,
    },
    accentText: {
      color: colors.charbon,
      fontFamily: fonts.bodySemi,
      fontSize: fontSizes.bodySm,
    },
    alerte: {
      backgroundColor: colors.laterite,
    },
    alerteText: {
      color: colors.manioc,
      fontFamily: fonts.bodySemi,
      fontSize: fontSizes.bodySm,
    },
    // Tailles
    xs: {
      paddingVertical: 6,
      paddingHorizontal: 14,
    },
    xsText: {
      fontSize: fontSizes.small,
    },
    lg: {
      paddingVertical: 16,
      paddingHorizontal: 28,
    },
    lgText: {
      fontSize: 17,
    },
  },

  // ── SILLON (TextInput) ───────────────────────────────────
  // Correspondance lexique : Sillon = Input / Text field
  sillon: {
    container: {
      gap: 6,
    },
    label: {
      fontFamily: fonts.mono,
      fontSize: fontSizes.xs,
      letterSpacing: 1.5,
      textTransform: 'uppercase',
      color: colors.cendre,
    },
    field: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.pause,
      backgroundColor: colors.manioc,
      borderWidth: 1.5,
      borderColor: colors.brume,
      borderRadius: radius.md,
      paddingVertical: 12,
      paddingHorizontal: spacing.arret,
    },
    fieldFocused: {
      borderColor: colors.foret,
    },
    fieldError: {
      borderColor: colors.laterite,
    },
    input: {
      flex: 1,
      fontFamily: fonts.body,
      fontSize: fontSizes.bodySm,
      color: colors.charbon,
    },
    placeholder: colors.cendre,
    help: {
      fontSize: fontSizes.small,
      color: colors.cendre,
    },
  },

  // ── PLAQUETTE (Card) ─────────────────────────────────────
  // Correspondance lexique : Plaquette = Card
  plaquette: {
    base: {
      backgroundColor: colors.blanc,
      borderWidth: 1,
      borderColor: colors.brume,
      borderRadius: radius.lg,
      padding: spacing.couloir,
      ...shadows.voilage,
    },
    titre: {
      fontFamily: fonts.display,
      fontSize: fontSizes.h3,
      color: colors.foret,
      marginBottom: spacing.pause,
    },
    body: {
      color: colors.cendre,
      fontSize: fontSizes.caption,
      lineHeight: fontSizes.caption * lineHeights.body,
    },
    // Variante sombre
    foret: {
      backgroundColor: colors.foret,
      borderColor: colors.foret,
    },
    foretTitre: {
      color: colors.manioc,
    },
    foretBody: {
      color: colors.foret30,
    },
  },

  // ── PASTILLE (Chip/Filter) ───────────────────────────────
  // Correspondance lexique : Pastille = Chip / Filter tag
  pastille: {
    base: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 5,
      paddingVertical: 5,
      paddingHorizontal: 12,
      borderRadius: radius.full,
      backgroundColor: colors.brume,
      borderWidth: 1,
      borderColor: 'transparent',
    },
    baseText: {
      fontSize: fontSizes.small,
      fontFamily: fonts.bodyMedium,
      color: colors.charbon,
    },
    active: {
      backgroundColor: colors.foret,
    },
    activeText: {
      color: colors.manioc,
    },
    contour: {
      backgroundColor: 'transparent',
      borderColor: colors.foret,
    },
    contourText: {
      color: colors.foret,
    },
    nere: {
      backgroundColor: colors.nereSoft,
    },
    nereText: {
      color: '#6b4815',
    },
    bambou: {
      backgroundColor: colors.bambouSoft,
    },
    bambouText: {
      color: colors.foret,
    },
  },

  // ── CACHET (Badge/Status) ────────────────────────────────
  // Correspondance lexique : Cachet = Badge / Status pill
  cachet: {
    base: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 5,
      paddingVertical: 4,
      paddingHorizontal: 10,
      borderRadius: radius.sm,
    },
    baseText: {
      fontFamily: fonts.mono,
      fontSize: fontSizes.xs,
      letterSpacing: 0.8,
      textTransform: 'uppercase',
      fontWeight: '500',
    },
    succes: { backgroundColor: colors.bambouSoft },
    succesText: { color: colors.foret },
    info: { backgroundColor: colors.foret10 },
    infoText: { color: colors.foret },
    alerte: { backgroundColor: colors.nereSoft },
    alerteText: { color: '#7a5615' },
    erreur: { backgroundColor: colors.lateriteSoft },
    erreurText: { color: '#7a3b15' },
  },

  // ── MÉREAU (Avatar) ──────────────────────────────────────
  // Correspondance lexique : Méreau = Avatar
  mereau: {
    base: {
      width: 44,
      height: 44,
      borderRadius: 22,
      backgroundColor: colors.foret,
      alignItems: 'center',
      justifyContent: 'center',
      borderWidth: 2,
      borderColor: colors.manioc,
    },
    baseText: {
      color: colors.manioc,
      fontFamily: fonts.display,
      fontSize: 18,
    },
    sm: { width: 28, height: 28, borderRadius: 14, borderWidth: 1.5 },
    smText: { fontSize: 12 },
    lg: { width: 64, height: 64, borderRadius: 32 },
    lgText: { fontSize: 26 },
    nere: { backgroundColor: colors.nere },
    nereText: { color: colors.charbon },
    bambou: { backgroundColor: colors.bambou },
    laterite: { backgroundColor: colors.laterite },
  },

  // ── BASCULE (Toggle/Switch) ──────────────────────────────
  // Correspondance lexique : Bascule = Toggle / Switch
  // Utiliser le composant Switch de React Native avec :
  bascule: {
    trackColorOff: colors.brume,
    trackColorOn: colors.bambou,
    thumbColor: colors.blanc,
    iosBackgroundColor: colors.brume,
  },

  // ── JALONS (Progress bar) ────────────────────────────────
  // Correspondance lexique : Jalons = Progress bar
  jalons: {
    track: {
      width: '100%',
      height: 8,
      backgroundColor: colors.brume,
      borderRadius: radius.full,
      overflow: 'hidden',
    },
    fill: {
      height: '100%',
      backgroundColor: colors.foret,
      borderRadius: radius.full,
    },
  },

  // ── ÉCHELON (Stepper) ────────────────────────────────────
  // Correspondance lexique : Échelon = Stepper / Wizard
  echelon: {
    container: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.pause,
    },
    step: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 6,
    },
    stepText: {
      fontSize: fontSizes.small,
      color: colors.cendre,
    },
    num: {
      width: 24,
      height: 24,
      borderRadius: 12,
      backgroundColor: colors.brume,
      alignItems: 'center',
      justifyContent: 'center',
    },
    numText: {
      fontFamily: fonts.mono,
      fontSize: fontSizes.xs,
      color: colors.cendre,
    },
    numDone: { backgroundColor: colors.bambou },
    numDoneText: { color: colors.manioc },
    numCurrent: { backgroundColor: colors.foret },
    numCurrentText: { color: colors.manioc },
    stepCurrent: { color: colors.foret, fontFamily: fonts.bodySemi },
    bar: {
      width: 20,
      height: 1,
      backgroundColor: colors.brume,
    },
    barDone: { backgroundColor: colors.bambou },
  },

  // ── BANDEAU (Toast/Snackbar) ─────────────────────────────
  // Correspondance lexique : Bandeau = Toast / Snackbar
  bandeau: {
    base: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.souffle,
      backgroundColor: colors.nuit,
      borderRadius: radius.md,
      paddingVertical: 14,
      paddingHorizontal: 18,
      ...shadows.canopee,
      maxWidth: 380,
    },
    baseText: {
      color: colors.manioc,
      fontSize: fontSizes.caption,
      flex: 1,
    },
    succes: { backgroundColor: colors.foret },
    alerte: { backgroundColor: colors.nere },
    alerteText: { color: colors.charbon },
    ico: {
      width: 22,
      height: 22,
      borderRadius: 11,
      backgroundColor: 'rgba(255,255,255,0.18)',
      alignItems: 'center',
      justifyContent: 'center',
    },
    icoText: {
      fontFamily: fonts.mono,
      fontSize: fontSizes.small,
      color: colors.manioc,
    },
  },

  // ── ALCÔVE (Modal) ────────────────────────────────────────
  // Correspondance lexique : Alcôve = Modal / Dialog
  alcove: {
    overlay: {
      flex: 1,
      backgroundColor: 'rgba(15,20,17,0.6)',
      alignItems: 'center',
      justifyContent: 'center',
      padding: spacing.couloir,
    },
    container: {
      backgroundColor: colors.blanc,
      borderRadius: radius.lg,
      padding: spacing.patio,
      borderWidth: 1,
      borderColor: colors.brume,
      ...shadows.futaie,
      width: '100%',
      maxWidth: 420,
    },
    titre: {
      fontFamily: fonts.display,
      fontSize: fontSizes.h3,
      color: colors.foret,
      marginBottom: spacing.pause,
    },
    body: {
      color: colors.cendre,
      fontSize: fontSizes.caption,
      marginBottom: spacing.arret,
    },
    actions: {
      flexDirection: 'row',
      gap: spacing.pause,
      justifyContent: 'flex-end',
    },
  },

  // ── ONGLET (Tab) ─────────────────────────────────────────
  // Correspondance lexique : Onglet = Tab
  onglet: {
    container: {
      flexDirection: 'row',
      borderBottomWidth: 1,
      borderBottomColor: colors.brume,
      gap: spacing.couloir,
    },
    tab: {
      paddingVertical: spacing.souffle,
      paddingBottom: spacing.souffle - 2,
      borderBottomWidth: 2,
      borderBottomColor: 'transparent',
      marginBottom: -1,
    },
    tabText: {
      fontFamily: fonts.bodyMedium,
      fontSize: fontSizes.caption,
      color: colors.cendre,
    },
    tabActif: {
      borderBottomColor: colors.foret,
    },
    tabActifText: {
      color: colors.foret,
    },
  },
};

// ─── RACCOURCIS UTILES ────────────────────────────────────
// Fonctions helpers pour créer des styles combinés rapidement

export const text = {
  h1:        { fontFamily: fonts.display, fontSize: fontSizes.h1, color: colors.foret, lineHeight: fontSizes.h1 * 1.02 },
  h2:        { fontFamily: fonts.display, fontSize: fontSizes.h2, color: colors.foret, lineHeight: fontSizes.h2 * 1.05 },
  h3:        { fontFamily: fonts.display, fontSize: fontSizes.h3, color: colors.foret, lineHeight: fontSizes.h3 * 1.15 },
  lede:      { fontFamily: fonts.display, fontSize: fontSizes.lede, color: colors.charbon, lineHeight: fontSizes.lede * 1.4 },
  body:      { fontFamily: fonts.body,    fontSize: fontSizes.body,   color: colors.charbon, lineHeight: fontSizes.body * 1.55 },
  bodyLg:    { fontFamily: fonts.body,    fontSize: fontSizes.bodyLg, color: colors.charbon },
  bodySm:    { fontFamily: fonts.body,    fontSize: fontSizes.bodySm, color: colors.charbon },
  caption:   { fontFamily: fonts.body,    fontSize: fontSizes.caption, color: colors.cendre },
  eyebrow:   { fontFamily: fonts.mono,    fontSize: fontSizes.xs, letterSpacing: 2, textTransform: 'uppercase', color: colors.cendre },
  prix:      { fontFamily: fonts.mono,    fontSize: fontSizes.h2, color: colors.nere, fontWeight: '500' },     // Affichage du prix en XAF
  prixSm:    { fontFamily: fonts.mono,    fontSize: fontSizes.bodyLg, color: colors.nere, fontWeight: '500' },
};

// Fond d'écran standard
export const screen = {
  flex: 1,
  backgroundColor: colors.manioc,
};

export default {
  colors,
  fonts,
  fontSizes,
  lineHeights,
  spacing,
  radius,
  shadows,
  components,
  text,
  screen,
};
