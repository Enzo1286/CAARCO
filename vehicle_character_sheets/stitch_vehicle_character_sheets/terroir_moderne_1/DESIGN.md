---
name: Terroir Moderne
colors:
  surface: '#fbf9f3'
  surface-dim: '#dcdad4'
  surface-bright: '#fbf9f3'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3ee'
  surface-container: '#f0eee8'
  surface-container-high: '#eae8e2'
  surface-container-highest: '#e4e2dd'
  on-surface: '#1b1c19'
  on-surface-variant: '#424843'
  inverse-surface: '#30312d'
  inverse-on-surface: '#f2f1eb'
  outline: '#727972'
  outline-variant: '#c2c8c1'
  surface-tint: '#486551'
  primary: '#082516'
  on-primary: '#ffffff'
  primary-container: '#1f3b2a'
  on-primary-container: '#86a58f'
  inverse-primary: '#aeceb7'
  secondary: '#3a6847'
  on-secondary: '#ffffff'
  secondary-container: '#bcefc5'
  on-secondary-container: '#406e4d'
  tertiary: '#2e1c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#4a3000'
  on-tertiary-container: '#c99441'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#caebd2'
  primary-fixed-dim: '#aeceb7'
  on-primary-fixed: '#042011'
  on-primary-fixed-variant: '#304d3b'
  secondary-fixed: '#bcefc5'
  secondary-fixed-dim: '#a0d2aa'
  on-secondary-fixed: '#00210d'
  on-secondary-fixed-variant: '#225031'
  tertiary-fixed: '#ffddb0'
  tertiary-fixed-dim: '#f6bd65'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#614000'
  background: '#fbf9f3'
  on-background: '#1b1c19'
  surface-variant: '#e4e2dd'
  foret: '#1f3b2a'
  foret-90: '#284a36'
  foret-30: '#b4c4b9'
  bambou: '#3d6b4a'
  nere: '#c89441'
  laterite: '#b8612e'
  manioc: '#fbf9f3'
  brume: '#ece9e0'
  cendre: '#6b6f68'
  charbon: '#1d2420'
  nuit: '#0f1411'
typography:
  h1:
    fontFamily: Marcellus
    fontSize: 48px
    fontWeight: '400'
    lineHeight: 56px
  h2:
    fontFamily: Marcellus
    fontSize: 36px
    fontWeight: '400'
    lineHeight: 44px
  h3:
    fontFamily: Marcellus
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
  lede:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '400'
    lineHeight: 28px
  body:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-medium:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-semibold:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.05em
  price-display:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  pas: 4px
  pause: 8px
  souffle: 12px
  arret: 16px
  couloir: 24px
  patio: 32px
  parvis: 48px
  place: 64px
---

## Brand & Style

The design system embodies "Terroir Moderne"—a synthesis of deep-rooted Cameroonian organic textures and the precision of high-end functional utility. It is designed to feel robust for logistics while maintaining a premium, "quiet luxury" aesthetic that distinguishes it from generic delivery apps.

The style is **Corporate / Modern** with **Tactile** undertones. It prioritizes clarity and high-performance utility (inspired by Uber) but wraps it in an earth-toned, sophisticated palette. Every interaction should feel intentional and grounded, evoking trust in a professional moving and freight service.

**Key Principles:**
- **Limpide d'abord:** One primary action or question per screen to ensure usability on the go.
- **Robustness:** High legibility under direct sunlight and high-contrast elements for low-bandwidth environments.
- **Non-Folkloric Identity:** Cultural grounding is achieved through material-inspired naming and a specific natural color palette rather than clichés.

## Colors

The palette is derived from the natural materials of the Cameroonian landscape. **Manioc (#fbf9f3)** is the mandatory background for all screens, providing a warm, sophisticated alternative to harsh white. 

**Foret (#1f3b2a)** serves as the primary anchor for structural elements and major actions, while **Bambou (#3d6b4a)** signifies success and progression. **Nere Gold (#c89441)** is reserved strictly for financial value—prices in XAF and highlights—to ensure they pop against the deep greens. **Laterite (#b8612e)** provides a distinctive, earth-toned error state that remains visible without feeling alarming.

## Typography

This system utilizes a tripartite typographic strategy:
1. **Marcellus (Serif):** Used for headlines and branding (h1-h3). It adds an authoritative, literary elegance that suggests tradition and reliability.
2. **Plus Jakarta Sans (Sans-Serif):** The primary workhorse for UI text, instructions, and navigation. Chosen for its modern, friendly, and highly legible geometric forms.
3. **JetBrains Mono (Monospaced):** Specifically for technical data. Use this for price displays (XAF), tracking codes, and uppercase labels. It evokes a sense of "receipt-like" precision and logistical accuracy.

Large headers (h1, h2) should reflow or scale down on small-format 4-inch mobile devices to ensure UI integrity.

## Layout & Spacing

The layout follows a fluid-first approach optimized for mobile devices. It utilizes a **Base-8 rhythm** with Cameroonian-inspired naming for internal units.

- **Margins:** Standard screen margins are set to `couloir (24px)` to give the content room to breathe, emphasizing the "premium" feel.
- **Gutters:** Standard element spacing is `arret (16px)`.
- **Vertical Rhythm:** Content sections are separated by `patio (32px)` or `parvis (48px)` to maintain high visual clarity.

The interface should avoid clutter. Use `place (64px)` for significant vertical breaks between logical groups (e.g., between a map view and the action sheet).

## Elevation & Depth

Depth is conveyed through **Tonal Layers** rather than heavy drop shadows, keeping the UI "limpide" (clear).

- **Surface Container:** Cards (Plaquette) use a pure `blanc` surface against the `manioc` background.
- **Voilage Shadow:** Use an extremely subtle, diffused shadow for elevated cards: `0px 4px 12px rgba(29, 36, 32, 0.05)`.
- **Futaie Shadow:** Used for modals (Alcôve) to create deep immersion: `0px 10px 25px rgba(15, 20, 17, 0.15)`.
- **Outlines:** Most containers use a 1px solid border in `brume (#ece9e0)` to define edges without adding visual weight.

## Shapes

The shape language is defined by the **Galet (Pebble)** philosophy. While the app is professional and robust, the use of large corner radii makes the interface feel approachable and modern.

- **Standard Buttons (Galet):** Always use `full` (pill-shaped) roundedness.
- **Cards (Plaquette):** Use `lg` (24px) for a soft, premium feel.
- **Input Fields (Sillon):** Use `md` (14px) to balance the softness of buttons with the structure needed for forms.
- **Badges (Cachet):** Use `sm` (8px) for a sharp, utilitarian look.

## Components

### Galet (Buttons)
The primary action button is a full-width pill. 
- **Primary:** `foret` background with `foret-30` text.
- **Secondary:** `brume` background with `charbon` text.
- **Accent:** `nere` background (used for payment/final confirmation).

### Sillon (Inputs)
Inputs feature a `label-mono` title in all-caps `cendre` color positioned above the field. The field itself has a `brume` border and `manioc` background, changing to a `foret` border on focus.

### Plaquette (Cards)
Cards are the primary content container. They must be `blanc` with a 1px `brume` border. They do not use heavy shadows unless they are interactive or floating.

### Cachet (Status Badges)
Small rectangular containers using `JetBrains Mono` in uppercase. Backgrounds should be light tints (`bambouSoft`, `nereSoft`, `lateriteSoft`) with high-contrast text.

### Mereau (Avatars)
Circular containers displaying user initials using the `Marcellus` font to maintain brand consistency even in small elements.

### Jalons (Progress Bar)
A `brume` track with a `foret` fill. Used during the driver's journey or freight tracking to show linear progress.