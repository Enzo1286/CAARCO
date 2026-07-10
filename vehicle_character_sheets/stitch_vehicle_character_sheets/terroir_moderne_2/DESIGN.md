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
  foret-90: '#284a36'
  foret-70: '#426356'
  foret-30: '#b4c4b9'
  foret-10: '#e6ede7'
  bambou-soft: '#cfdbcf'
  nere-soft: '#f1e3c2'
  laterite: '#b8612e'
  laterite-soft: '#f1d6c3'
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
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.05em
  price-display:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
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
  horizon: 96px
---

## Brand & Style

The design system for the product is built on three pillars: **Limpide (Clear)**, **Chaleureux (Warm)**, and **Robuste (Robust)**. It targets a Cameroonian audience, providing a logistics and transport solution that feels deeply rooted in the local environment without resorting to clichés.

The chosen style is **Corporate / Modern with a Tactile twist**. It prioritizes high legibility and functional simplicity to ensure reliability even on older devices or under direct sunlight (high contrast). The "warmth" is achieved through a cream-based neutral palette and serif typography, while "robustness" is conveyed through solid blocks of deep forest green and a strict geometric grid. The aesthetic is professional, grounded, and intentionally avoids gradients or unnecessary decorative elements to maintain a lightweight technical footprint.

## Colors

The palette is inspired by natural Cameroonian elements. 
- **Primary (Foret):** Used for main actions, titles, and active states. It provides the "Robust" foundation.
- **Secondary (Bambou):** Used for success states and active toggles.
- **Tertiary (Nere):** A warm gold reserved strictly for pricing (XAF), highlights, and critical accents.
- **Neutral (Manioc):** The primary background for all views. Pure white is never used for backgrounds, only for cards and modal surfaces to create subtle "elevated" contrast.
- **Status Colors:** Laterite is used for errors and alerts.
- **Text:** Charbon is the primary text color, with Cendre used for secondary information and placeholders.

## Typography

This design system uses a strategic mix of three typefaces:
- **Marcellus:** An elegant serif used for headlines (H1-H3). It brings the "Chaleureux" (warm) and human touch.
- **Plus Jakarta Sans:** A highly legible sans-serif for body text, ensuring clarity across all screen sizes.
- **JetBrains Mono:** A technical monospaced font used for "hard data"—prices in XAF, uppercase labels, and tracking codes. This reinforces the "Robuste" (robust) and reliable nature of the logistics service.

All uppercase labels in JetBrains Mono should have a slight letter spacing (+5%) for better readability at small sizes.

## Layout & Spacing

The layout follows a **Fluid Grid** model optimized for mobile-first interaction. 

- **Margins:** Standard side margins are set to `couloir` (24px) for desktop/tablet and `arret` (16px) for small mobile devices.
- **Gutter:** A consistent gutter of `arret` (16px) is used between elements.
- **Rhythm:** All vertical spacing must adhere to the defined spacing tokens (e.g., `souffle` for internal card padding, `patio` for section breaks).
- **Philosophy:** "Un écran = une question." Each screen should focus on a single primary action, utilizing generous white space (`horizon` or `place`) to separate logical groups.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Low-Contrast Outlines** rather than aggressive shadows.

1.  **Level 0 (Base):** The `manioc` background.
2.  **Level 1 (Cards/Plaquettes):** Pure white surfaces with a 1px `brume` border. A very soft, diffused shadow ("voilage") is used to lift these elements slightly.
3.  **Level 2 (Modals/Alcôve):** Pure white surfaces with a more pronounced, darker shadow ("futaie") to indicate higher priority and interaction focus.
4.  **Overlays:** A semi-transparent `nuit` overlay is used behind modals to focus the user's attention.

Avoid using shadows on buttons; use color fills (`foret` or `nere`) to indicate interactability.

## Shapes

The shape language is "Softly Geometric."
- **Standard (md):** Used for cards (`Plaquette`) and input fields (`Sillon`), set at 14px.
- **Small (sm):** Used for smaller UI elements like checkboxes or mini-cards, set at 8px.
- **Pill (full):** Used for buttons (`Galet`) and status indicators (`Cachet`) to make them feel inviting and distinct from structural containers.
- **Sharp:** Never used; every corner has at least a 4px (xs) radius to maintain the "Chaleureux" principle.

## Components

- **Galet (Button):** Always pill-shaped (`borderRadius: full`). 
    - *Primary:* `foret` background, white text.
    - *Accent:* `nere` background (used for payment or final confirmation).
    - *Ghost:* `brume` border, `charbon` text.
- **Sillon (Input):** Label in `JetBrains Mono` (uppercase), field with `brume` border and 14px radius. Focus state uses a `bambou` border or `foret-10` background.
- **Plaquette (Card):** White background, 1px `brume` border, 14px radius.
- **Pastille (Chip):** Used for filtering. `brume` background for inactive, `bambou-soft` for active.
- **Cachet (Badge):** `JetBrains Mono` font, uppercase. Background matches the status (e.g., `nere-soft` for pending, `bambou-soft` for delivered).
- **Méreau (Avatar):** Circular container with initials rendered in `Marcellus`.
- **Calicot (Banner):** Notification area with a `nere-soft` background and a thick left border in `nere`.
- **Jalons (Progress Bar):** A `brume` track with a `foret` fill.