import React, { useState } from "react";

/* ============================================================
   CHARTE GRAPHIQUE — CARROUSELS INSTAGRAM CAARCO
   Design system : Atelier CAARCO
   Formats : 1080 x 1080 (1:1)  &  1080 x 1350 (4:5)
   Composant de référence + templates de slides prêts à l'emploi
   ============================================================ */

/* ---------- TOKENS (source de vérité Atelier CAARCO) ---------- */
const C = {
  foret: "#1f3b2a", foret90: "#284a36", foret30: "#b4c4b9",
  bambou: "#3d6b4a", bambouSoft: "#cfdbcf",
  nere: "#c89441", nereSoft: "#f1e3c2",
  laterite: "#b8612e", lateriteSoft: "#f1d6c3",
  manioc: "#fbf9f3", brume: "#ece9e0",
  cendre: "#6b6f68", charbon: "#1d2420", nuit: "#0f1411", blanc: "#FFFFFF",
};
const F = {
  display: "'Marcellus', Georgia, serif",
  body: "'Plus Jakarta Sans', system-ui, sans-serif",
  mono: "'JetBrains Mono', 'Courier New', monospace",
};
const FORMATS = {
  portrait: { w: 1080, h: 1350, label: "4:5", nom: "Portrait" },
  carre: { w: 1080, h: 1080, label: "1:1", nom: "Carré" },
};

/* ---------- PRIMITIVES ---------- */
function Mark({ size = 40, arc = C.manioc, disc = C.nere }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" fill="none">
      <path d="M81.7 54.6 A 33 33 0 1 0 45.5 82.8" stroke={arc} strokeWidth="13" strokeLinecap="round" />
      <circle cx="82" cy="55" r="12" fill={disc} />
    </svg>
  );
}
function Ic({ size = 24, color = C.foret, sw = 2, children }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color}
      strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">{children}</svg>
  );
}
const PATHS = {
  colis: <><path d="M21 8l-9-5-9 5v8l9 5 9-5V8z" /><path d="M3.3 7 12 12l8.7-5" /><path d="M12 22V12" /></>,
  transport: <><path d="M2 4h13v12H2z" /><path d="M15 8h4l3 3v5h-7z" /><circle cx="6" cy="18" r="2" /><circle cx="18" cy="18" r="2" /></>,
  adresse: <><path d="M21 10c0 6-9 12-9 12s-9-6-9-12a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></>,
  delai: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  securite: <path d="M12 2 20 6v6c0 5-3.5 8-8 10-4.5-2-8-5-8-10V6z" />,
  note: <path d="M12 3l2.9 5.9 6.1.9-4.5 4.3 1.1 6.5L12 17.8 6.4 20.6l1.1-6.5L3 9.8l6.1-.9z" />,
  download: <><path d="M12 3v12" /><path d="M7 11l5 5 5-5" /><path d="M4 20h16" /></>,
  check: <path d="M4 12l5 5 11-11" />,
  x: <><path d="M6 6l12 12" /><path d="M18 6 6 18" /></>,
};

function Section({ n, title, children }) {
  return (
    <section style={{ marginTop: 64 }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 16, borderBottom: `1px solid ${C.brume}`, paddingBottom: 14, marginBottom: 28 }}>
        <span style={{ fontFamily: F.mono, fontSize: 13, color: C.nere, letterSpacing: 1 }}>{n}</span>
        <h2 style={{ fontFamily: F.display, fontSize: 30, color: C.charbon, margin: 0, lineHeight: 1.1 }}>{title}</h2>
      </div>
      {children}
    </section>
  );
}
function Eyebrow({ children, color = C.bambou }) {
  return <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 12, letterSpacing: 2, textTransform: "uppercase", color }}>{children}</div>;
}
function Swatch({ name, hex, role }) {
  return (
    <div style={{ borderRadius: 14, overflow: "hidden", border: `1px solid ${C.brume}`, background: C.blanc }}>
      <div style={{ height: 74, background: hex }} />
      <div style={{ padding: "10px 12px" }}>
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 13, color: C.charbon }}>{name}</div>
        <div style={{ fontFamily: F.mono, fontSize: 12, color: C.cendre, marginTop: 2 }}>{hex}</div>
        <div style={{ fontFamily: F.body, fontSize: 11.5, color: C.cendre, marginTop: 5, lineHeight: 1.35 }}>{role}</div>
      </div>
    </div>
  );
}

/* Rend un slide conçu en pleine résolution (w×h) puis mis à l'échelle */
function SlideFrame({ w, h, previewW = 300, children }) {
  const scale = previewW / w;
  return (
    <div style={{ width: previewW, height: Math.round(h * scale), borderRadius: 16, overflow: "hidden", boxShadow: "0 6px 22px rgba(31,59,42,0.16)", flex: "0 0 auto" }}>
      <div style={{ width: w, height: h, transform: `scale(${scale})`, transformOrigin: "top left" }}>{children}</div>
    </div>
  );
}

/* ============================================================
   TEMPLATES DE SLIDES (conçus à 1080px — export direct)
   ============================================================ */
function SlideCouverture({ w, h }) {
  return (
    <div style={{ width: w, height: h, background: C.foret, position: "relative", overflow: "hidden", padding: 96, display: "flex", flexDirection: "column", justifyContent: "space-between", fontFamily: F.body }}>
      <svg viewBox="0 0 100 100" fill="none" style={{ position: "absolute", right: -w * 0.28, bottom: -w * 0.22, opacity: 0.07, width: w, height: w }}>
        <path d="M81.7 54.6 A 33 33 0 1 0 45.5 82.8" stroke={C.manioc} strokeWidth="10" strokeLinecap="round" />
        <circle cx="82" cy="55" r="12" fill={C.manioc} />
      </svg>
      <div style={{ display: "flex", alignItems: "center", gap: 22, position: "relative" }}>
        <Mark size={64} />
        <span style={{ fontFamily: F.display, fontSize: 46, color: C.manioc, letterSpacing: 2 }}>CAARCO</span>
      </div>
      <div style={{ position: "relative" }}>
        <div style={{ fontWeight: 800, fontSize: 30, letterSpacing: 4, textTransform: "uppercase", color: C.nere, marginBottom: 34 }}>Livraison express</div>
        <h1 style={{ fontFamily: F.display, fontSize: 98, lineHeight: 1.03, color: C.manioc, margin: 0 }}>Vos colis livrés partout au Cameroun.</h1>
        <div style={{ width: 170, height: 9, background: C.nere, borderRadius: 9999, marginTop: 46 }} />
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", position: "relative" }}>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.foret30 }}>Glissez →</span>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.manioc }}>01 / 05</span>
      </div>
    </div>
  );
}
function SlideContenu({ w, h }) {
  return (
    <div style={{ width: w, height: h, background: C.manioc, position: "relative", overflow: "hidden", padding: 96, display: "flex", flexDirection: "column", justifyContent: "space-between", fontFamily: F.body }}>
      <div style={{ position: "absolute", left: 40, top: 96, bottom: 96, width: 10, background: C.nere, borderRadius: 9999 }} />
      <div style={{ display: "flex", alignItems: "center", gap: 28 }}>
        <div style={{ width: 108, height: 108, borderRadius: 9999, background: C.bambouSoft, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Ic size={54} color={C.foret}>{PATHS.adresse}</Ic>
        </div>
        <div>
          <div style={{ fontWeight: 800, fontSize: 26, letterSpacing: 3, textTransform: "uppercase", color: C.bambou }}>Comment ça marche</div>
          <div style={{ fontFamily: F.display, fontSize: 40, color: C.cendre }}>Étape 1</div>
        </div>
      </div>
      <div>
        <h2 style={{ fontFamily: F.display, fontSize: 78, lineHeight: 1.05, color: C.charbon, margin: "0 0 30px" }}>Indiquez le point de retrait</h2>
        <p style={{ fontSize: 35, lineHeight: 1.5, color: C.cendre, margin: 0, maxWidth: 800 }}>Saisissez l'adresse de départ et de livraison. CAARCO calcule le prix et trouve un transporteur près de vous.</p>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <Mark size={40} arc={C.foret} /><span style={{ fontFamily: F.display, fontSize: 28, color: C.charbon, letterSpacing: 1 }}>CAARCO</span>
        </div>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.cendre }}>02 / 05</span>
      </div>
    </div>
  );
}
function SlideChiffre({ w, h }) {
  const usages = ["Livraison express", "Déménagement", "Logistique PME", "Transport ponctuel"];
  return (
    <div style={{ width: w, height: h, background: C.brume, position: "relative", overflow: "hidden", padding: 96, display: "flex", flexDirection: "column", justifyContent: "space-between", fontFamily: F.body }}>
      <div style={{ fontWeight: 800, fontSize: 26, letterSpacing: 3, textTransform: "uppercase", color: C.laterite }}>Une seule application</div>
      <div>
        <div style={{ fontFamily: F.mono, fontSize: 240, lineHeight: 0.9, color: C.foret, fontWeight: 700 }}>4</div>
        <div style={{ fontFamily: F.display, fontSize: 66, color: C.charbon, marginTop: 10 }}>usages, une seule app</div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 16, marginTop: 44 }}>
          {usages.map((t) => (
            <span key={t} style={{ fontWeight: 600, fontSize: 29, color: C.foret, background: C.nereSoft, padding: "16px 28px", borderRadius: 9999 }}>{t}</span>
          ))}
        </div>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <Mark size={40} arc={C.foret} /><span style={{ fontFamily: F.display, fontSize: 28, color: C.charbon, letterSpacing: 1 }}>CAARCO</span>
        </div>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.cendre }}>03 / 05</span>
      </div>
    </div>
  );
}
function SlideCTA({ w, h }) {
  return (
    <div style={{ width: w, height: h, background: `linear-gradient(160deg, ${C.foret90} 0%, ${C.nuit} 100%)`, position: "relative", overflow: "hidden", padding: 96, display: "flex", flexDirection: "column", justifyContent: "space-between", fontFamily: F.body }}>
      <div style={{ display: "flex", alignItems: "center", gap: 22 }}>
        <Mark size={64} /><span style={{ fontFamily: F.display, fontSize: 46, color: C.manioc, letterSpacing: 2 }}>CAARCO</span>
      </div>
      <div>
        <div style={{ fontWeight: 800, fontSize: 28, letterSpacing: 3, textTransform: "uppercase", color: C.nere, marginBottom: 30 }}>Prêt à envoyer ?</div>
        <h2 style={{ fontFamily: F.display, fontSize: 92, lineHeight: 1.03, color: C.manioc, margin: "0 0 52px" }}>Téléchargez CAARCO gratuitement</h2>
        <div style={{ display: "inline-flex", alignItems: "center", gap: 22, background: C.bambou, color: C.manioc, padding: "32px 54px", borderRadius: 9999 }}>
          <Ic size={46} color={C.manioc}>{PATHS.download}</Ic>
          <span style={{ fontWeight: 700, fontSize: 40 }}>Installer sur Google Play</span>
        </div>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.nere }}>@caarco.cm</span>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.manioc }}>05 / 05</span>
      </div>
    </div>
  );
}

const TEMPLATES = [
  { comp: SlideCouverture, titre: "Couverture — Accroche", role: "Slide 1 : logo + promesse forte + indice de swipe. Fond Forêt.", fond: "Forêt" },
  { comp: SlideContenu, titre: "Contenu — Étape / Idée", role: "Slides 2 à N : une seule idée, icône, titre + paragraphe court. Fond Manioc.", fond: "Manioc" },
  { comp: SlideChiffre, titre: "Chiffre clé — Preuve", role: "Slide de preuve : un grand chiffre en JetBrains Mono. Fond Brume.", fond: "Brume" },
  { comp: SlideCTA, titre: "CTA — Conversion", role: "Dernière slide : appel à l'action unique (télécharger l'app). Dégradé Forêt.", fond: "Forêt→Nuit" },
];

/* ============================================================
   PAGE CHARTE
   ============================================================ */
export default function CharteCarrouselsCAARCO() {
  const [fmt, setFmt] = useState("portrait");
  const dims = FORMATS[fmt];

  const swItem = { display: "flex", alignItems: "flex-start", gap: 12, marginBottom: 14 };
  const grid = (min) => ({ display: "grid", gap: 16, gridTemplateColumns: `repeat(auto-fill, minmax(${min}px, 1fr))` });

  return (
    <div style={{ background: C.manioc, minHeight: "100vh", color: C.charbon, fontFamily: F.body }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Marcellus&family=JetBrains+Mono:wght@400;500;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box}
      `}</style>

      {/* HERO */}
      <header style={{ background: C.foret, color: C.manioc, padding: "56px 40px", position: "relative", overflow: "hidden" }}>
        <div style={{ maxWidth: 1060, margin: "0 auto", position: "relative" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 18, marginBottom: 30 }}>
            <Mark size={52} />
            <span style={{ fontFamily: F.display, fontSize: 34, letterSpacing: 2 }}>CAARCO</span>
          </div>
          <Eyebrow color={C.nere}>Charte graphique</Eyebrow>
          <h1 style={{ fontFamily: F.display, fontSize: 58, lineHeight: 1.05, margin: "12px 0 16px" }}>Carrousels Instagram</h1>
          <p style={{ fontSize: 18, color: C.foret30, maxWidth: 620, lineHeight: 1.55, margin: 0 }}>
            Système visuel pour concevoir des carrousels cohérents, lisibles et orientés conversion — fondé sur le design system Atelier CAARCO.
          </p>
          <div style={{ fontFamily: F.mono, fontSize: 13, color: C.nere, marginTop: 26, letterSpacing: 1 }}>
            1080×1080 (1:1) · 1080×1350 (4:5) · Français · v1.0 — Juillet 2026
          </div>
        </div>
      </header>

      <main style={{ maxWidth: 1060, margin: "0 auto", padding: "0 40px 90px" }}>

        {/* 01 — TERRITOIRE */}
        <Section n="01" title="Territoire de marque">
          <p style={{ fontSize: 16, lineHeight: 1.7, color: C.charbon, maxWidth: 780, marginTop: 0 }}>
            CAARCO connecte expéditeurs et transporteurs pour le transport de marchandises au Cameroun. Le ton est <b>clair, concret et rassurant</b>, avec une fierté locale assumée. Chaque carrousel sert un objectif : expliquer, prouver, convertir. On ne réduit jamais CAARCO à « livraison de colis » — quatre usages coexistent :
          </p>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginTop: 18 }}>
            {["Livraison express", "Déménagement", "Logistique entreprises", "Transport ponctuel"].map((t) => (
              <span key={t} style={{ fontWeight: 600, fontSize: 14, color: C.foret, background: C.nereSoft, padding: "9px 18px", borderRadius: 9999 }}>{t}</span>
            ))}
          </div>
        </Section>

        {/* 02 — LOGO */}
        <Section n="02" title="Signature — Arc + Disque Néré">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 18 }}>
            <div style={{ flex: "1 1 200px", background: C.manioc, border: `1px solid ${C.brume}`, borderRadius: 16, padding: 28, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
              <Mark size={72} arc={C.foret} />
              <span style={{ fontFamily: F.mono, fontSize: 12, color: C.cendre }}>sur fond clair (Manioc)</span>
            </div>
            <div style={{ flex: "1 1 200px", background: C.foret, borderRadius: 16, padding: 28, display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
              <Mark size={72} arc={C.manioc} />
              <span style={{ fontFamily: F.mono, fontSize: 12, color: C.foret30 }}>sur fond foncé (Forêt)</span>
            </div>
            <div style={{ flex: "2 1 300px", background: C.blanc, border: `1px solid ${C.brume}`, borderRadius: 16, padding: 28, display: "flex", flexDirection: "column", justifyContent: "center", gap: 16 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                <Mark size={44} arc={C.foret} />
                <span style={{ fontFamily: F.display, fontSize: 30, color: C.charbon, letterSpacing: 2 }}>CAARCO</span>
              </div>
              <p style={{ fontSize: 13.5, lineHeight: 1.6, color: C.cendre, margin: 0 }}>
                Verrou logo + mot : anneau ouvert Forêt avec disque Néré à l'extrémité, mot en Marcellus. Zone de protection = hauteur du disque tout autour. Ne jamais déformer, recolorer hors palette, ni ajouter d'ombre au logo.
              </p>
            </div>
          </div>
        </Section>

        {/* 03 — COULEURS */}
        <Section n="03" title="Palette">
          <Eyebrow>Pigments principaux</Eyebrow>
          <div style={{ ...grid(150), marginTop: 12 }}>
            <Swatch name="Forêt" hex="#1f3b2a" role="Marque / fonds sombres / titres" />
            <Swatch name="Bambou" hex="#3d6b4a" role="Action / boutons / accent secondaire" />
            <Swatch name="Néré" hex="#c89441" role="Accent / chiffres / surlignage" />
            <Swatch name="Latérite" hex="#b8612e" role="Alerte / annulation (usage rare)" />
          </div>
          <div style={{ height: 22 }} />
          <Eyebrow>Neutres</Eyebrow>
          <div style={{ ...grid(150), marginTop: 12 }}>
            <Swatch name="Manioc" hex="#fbf9f3" role="Fond principal — jamais blanc pur" />
            <Swatch name="Brume" hex="#ece9e0" role="Fonds secondaires / cartes" />
            <Swatch name="Cendre" hex="#6b6f68" role="Texte secondaire" />
            <Swatch name="Charbon" hex="#1d2420" role="Texte principal" />
            <Swatch name="Nuit" hex="#0f1411" role="Fond très sombre / dégradés" />
          </div>
          <div style={{ marginTop: 20, background: C.nereSoft, borderRadius: 12, padding: "14px 18px", fontSize: 13.5, color: C.charbon, lineHeight: 1.6 }}>
            <b>Règle 60 / 30 / 10.</b> ~60 % fond (Manioc ou Forêt) · ~30 % couleur de soutien (Brume, Forêt, Bambou) · ~10 % accent Néré réservé à ce qui doit capter l'œil (chiffre, mot-clé, CTA). Contraste minimum WCAG AA (4,5:1) — lisible en plein soleil.
          </div>
        </Section>

        {/* 04 — TYPOGRAPHIE */}
        <Section n="04" title="Typographie">
          <div style={{ display: "grid", gap: 16, gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))" }}>
            <div style={{ border: `1px solid ${C.brume}`, borderRadius: 16, padding: 22, background: C.blanc }}>
              <div style={{ fontFamily: F.display, fontSize: 60, color: C.foret, lineHeight: 1 }}>Aa</div>
              <div style={{ fontFamily: F.display, fontSize: 22, color: C.charbon, marginTop: 8 }}>Marcellus</div>
              <div style={{ fontSize: 12.5, color: C.cendre, marginTop: 4 }}>Titres H1/H2, accroches, montants héros</div>
            </div>
            <div style={{ border: `1px solid ${C.brume}`, borderRadius: 16, padding: 22, background: C.blanc }}>
              <div style={{ fontFamily: F.body, fontWeight: 800, fontSize: 60, color: C.foret, lineHeight: 1 }}>Aa</div>
              <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 22, color: C.charbon, marginTop: 8 }}>Plus Jakarta Sans</div>
              <div style={{ fontSize: 12.5, color: C.cendre, marginTop: 4 }}>Corps, sous-titres, étiquettes, boutons</div>
            </div>
            <div style={{ border: `1px solid ${C.brume}`, borderRadius: 16, padding: 22, background: C.blanc }}>
              <div style={{ fontFamily: F.mono, fontSize: 56, color: C.nere, lineHeight: 1 }}>2 500</div>
              <div style={{ fontFamily: F.mono, fontSize: 20, color: C.charbon, marginTop: 8 }}>JetBrains Mono</div>
              <div style={{ fontSize: 12.5, color: C.cendre, marginTop: 4 }}>Montants FCFA / TC, codes OTP, pagination</div>
            </div>
          </div>

          <div style={{ marginTop: 22, border: `1px solid ${C.brume}`, borderRadius: 16, overflow: "hidden" }}>
            {[
              ["Titre héro (couverture)", "Marcellus", "92–98 px", "1.03"],
              ["Titre de slide", "Marcellus", "72–78 px", "1.05"],
              ["Sous-titre / étape", "Marcellus", "40 px", "1.1"],
              ["Corps", "Plus Jakarta Sans", "34–35 px", "1.5"],
              ["Étiquette / eyebrow", "PJS 800 · maj · +3", "26 px", "1.2"],
              ["Chiffre clé", "JetBrains Mono", "180–240 px", "0.9"],
              ["Pagination / swipe", "JetBrains Mono", "30 px", "1"],
            ].map((r, i) => (
              <div key={r[0]} style={{ display: "grid", gridTemplateColumns: "1.4fr 1.4fr 0.9fr 0.6fr", gap: 8, padding: "12px 18px", background: i % 2 ? C.blanc : C.manioc, fontSize: 13.5 }}>
                <span style={{ fontWeight: 600, color: C.charbon }}>{r[0]}</span>
                <span style={{ color: C.cendre }}>{r[1]}</span>
                <span style={{ fontFamily: F.mono, color: C.foret }}>{r[2]}</span>
                <span style={{ fontFamily: F.mono, color: C.cendre }}>{r[3]}</span>
              </div>
            ))}
          </div>
          <p style={{ fontSize: 12.5, color: C.cendre, marginTop: 10 }}>Tailles exprimées à l'échelle réelle 1080 px. Diviser par ~2,8 pour un aperçu 4:5 à 300 px.</p>
        </Section>

        {/* 05 — FORMATS & GRILLE */}
        <Section n="05" title="Formats & zone de sécurité">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 24, alignItems: "flex-start" }}>
            {[["portrait", true], ["carre", false]].map(([k, reco]) => {
              const d = FORMATS[k]; const bw = 150; const bh = bw * (d.h / d.w);
              return (
                <div key={k} style={{ textAlign: "center" }}>
                  <div style={{ position: "relative", width: bw, height: bh, background: C.foret, borderRadius: 12, margin: "0 auto" }}>
                    <div style={{ position: "absolute", inset: 13, border: `1.5px dashed ${C.foret30}`, borderRadius: 6 }} />
                    <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: bh * 0.16, background: "rgba(200,148,65,0.28)", borderTop: `1px solid ${C.nere}`, borderRadius: "0 0 12px 12px" }} />
                  </div>
                  <div style={{ fontFamily: F.display, fontSize: 20, color: C.charbon, marginTop: 12 }}>{d.label} — {d.nom}</div>
                  <div style={{ fontFamily: F.mono, fontSize: 12, color: C.cendre }}>{d.w} × {d.h} px</div>
                  {reco && <div style={{ fontSize: 11, fontWeight: 700, color: C.bambou, marginTop: 4 }}>◆ Recommandé (occupe + de feed)</div>}
                </div>
              );
            })}
            <div style={{ flex: "1 1 300px", minWidth: 260 }}>
              <ul style={{ margin: 0, paddingLeft: 18, fontSize: 14, lineHeight: 1.8, color: C.charbon }}>
                <li><b>Marge de sécurité :</b> 96 px sur les 4 côtés. Aucun texte au-delà.</li>
                <li><b>Zone basse (~16 %) :</b> réservée — l'UI Instagram (points, légende) s'y superpose. Pas d'info critique.</li>
                <li><b>Une idée par slide.</b> Un seul message dominant, une seule action.</li>
                <li><b>Alignement à gauche</b> par défaut ; centrage réservé aux couvertures et CTA.</li>
              </ul>
            </div>
          </div>
        </Section>

        {/* 06 — GALETS & OMBRES */}
        <Section n="06" title="Galets & ombres">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 24, alignItems: "flex-end" }}>
            {[["xs", 4], ["sm", 8], ["md", 14], ["lg", 24], ["full", 40]].map(([n, r]) => (
              <div key={n} style={{ textAlign: "center" }}>
                <div style={{ width: 72, height: 72, background: C.bambouSoft, border: `2px solid ${C.bambou}`, borderRadius: n === "full" ? 9999 : r }} />
                <div style={{ fontFamily: F.mono, fontSize: 12, color: C.charbon, marginTop: 8 }}>{n}</div>
                <div style={{ fontFamily: F.mono, fontSize: 11, color: C.cendre }}>{n === "full" ? "9999" : r} px</div>
              </div>
            ))}
            <div style={{ display: "flex", gap: 20, marginLeft: 10 }}>
              <div style={{ width: 120, height: 72, background: C.blanc, borderRadius: 14, boxShadow: "0 1px 4px rgba(31,59,42,0.06)", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: F.mono, fontSize: 12, color: C.cendre }}>voilage</div>
              <div style={{ width: 120, height: 72, background: C.blanc, borderRadius: 14, boxShadow: "0 4px 12px rgba(31,59,42,0.10)", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: F.mono, fontSize: 12, color: C.cendre }}>canopée</div>
            </div>
          </div>
          <p style={{ fontSize: 13, color: C.cendre, marginTop: 16 }}>Boutons, chips et badges : galet <b>full</b>. Cartes : galet <b>md</b>. <b>Jamais</b> d'angle vif (border-radius 0).</p>
        </Section>

        {/* 07 — ICONOGRAPHIE & PHOTO */}
        <Section n="07" title="Iconographie & photo">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 14 }}>
            {[["colis", "Colis"], ["transport", "Transport"], ["adresse", "Adresse"], ["delai", "Délai"], ["securite", "Sécurité"], ["note", "Note"], ["download", "App"]].map(([k, label]) => (
              <div key={k} style={{ width: 96, textAlign: "center", padding: "16px 8px", background: C.blanc, border: `1px solid ${C.brume}`, borderRadius: 14 }}>
                <div style={{ display: "flex", justifyContent: "center" }}><Ic size={30} color={C.foret}>{PATHS[k]}</Ic></div>
                <div style={{ fontSize: 11.5, color: C.cendre, marginTop: 8 }}>{label}</div>
              </div>
            ))}
          </div>
          <p style={{ fontSize: 14, lineHeight: 1.7, color: C.charbon, marginTop: 16, maxWidth: 800 }}>
            <b>Icônes :</b> trait de 2 px, extrémités et angles arrondis, style linéaire monochrome (Forêt ou Manioc). <b>Photo :</b> contextes réels camerounais (routes, marchés, motos, PME), jamais de stock cliché. Superposer un voile Forêt (dégradé vers le bas, opacité 55–75 %) pour garantir la lisibilité du texte blanc.
          </p>
        </Section>

        {/* 08 — ANATOMIE */}
        <Section n="08" title="Anatomie d'un carrousel">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 10, alignItems: "center" }}>
            {[["01", "Accroche", C.foret, C.manioc], ["02", "Idée / preuve", C.brume, C.charbon], ["03", "Idée / preuve", C.brume, C.charbon], ["04", "Idée / preuve", C.brume, C.charbon], ["05", "CTA", C.bambou, C.manioc]].map((s, i) => (
              <React.Fragment key={i}>
                <div style={{ background: s[2], color: s[3], borderRadius: 12, padding: "16px 14px", minWidth: 92, textAlign: "center" }}>
                  <div style={{ fontFamily: F.mono, fontSize: 12, opacity: 0.7 }}>{s[0]}</div>
                  <div style={{ fontWeight: 700, fontSize: 13, marginTop: 4 }}>{s[1]}</div>
                </div>
                {i < 4 && <Ic size={20} color={C.nere}><path d="M4 12h16" /><path d="M14 6l6 6-6 6" /></Ic>}
              </React.Fragment>
            ))}
          </div>
          <p style={{ fontSize: 14, lineHeight: 1.7, color: C.charbon, marginTop: 16, maxWidth: 800 }}>
            <b>3 à 6 slides</b> idéalement. La slide 1 porte 80 % du travail : accroche + bénéfice clair + indice de swipe. Les slides intermédiaires développent une idée chacune. La dernière slide contient <b>un seul</b> appel à l'action (télécharger l'app).
          </p>
        </Section>

        {/* 09 — TEMPLATES */}
        <Section n="09" title="Templates prêts à l'emploi">
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 22, flexWrap: "wrap" }}>
            <span style={{ fontSize: 13, color: C.cendre }}>Format d'aperçu :</span>
            {Object.keys(FORMATS).map((k) => (
              <button key={k} onClick={() => setFmt(k)} style={{
                cursor: "pointer", fontFamily: F.body, fontWeight: 700, fontSize: 13,
                padding: "8px 18px", borderRadius: 9999,
                border: `1.5px solid ${fmt === k ? C.foret : C.brume}`,
                background: fmt === k ? C.foret : C.blanc,
                color: fmt === k ? C.manioc : C.cendre,
              }}>{FORMATS[k].label} · {FORMATS[k].nom}</button>
            ))}
            <span style={{ fontFamily: F.mono, fontSize: 12, color: C.cendre, marginLeft: 4 }}>{dims.w} × {dims.h} px</span>
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 26 }}>
            {TEMPLATES.map((t) => {
              const Comp = t.comp;
              return (
                <div key={t.titre} style={{ width: 300 }}>
                  <SlideFrame w={dims.w} h={dims.h} previewW={300}><Comp w={dims.w} h={dims.h} /></SlideFrame>
                  <div style={{ fontFamily: F.display, fontSize: 18, color: C.charbon, marginTop: 14 }}>{t.titre}</div>
                  <div style={{ fontSize: 12.5, color: C.cendre, lineHeight: 1.5, marginTop: 4 }}>{t.role}</div>
                  <div style={{ fontFamily: F.mono, fontSize: 11, color: C.nere, marginTop: 6 }}>Fond : {t.fond}</div>
                </div>
              );
            })}
          </div>
          <p style={{ fontSize: 12.5, color: C.cendre, marginTop: 18 }}>Textes d'exemple — à remplacer par votre message. Les chiffres doivent refléter des données réelles CAARCO (ne pas inventer de statistiques).</p>
        </Section>

        {/* 10 — MONTANTS */}
        <Section n="10" title="Règles des montants">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 20 }}>
            <div style={{ flex: "1 1 240px", background: C.blanc, border: `1px solid ${C.brume}`, borderRadius: 16, padding: 24 }}>
              <div style={{ display: "flex", gap: 22, alignItems: "baseline", flexWrap: "wrap" }}>
                <span style={{ fontFamily: F.mono, fontSize: 32, color: C.nere }}>2 500 FCFA</span>
                <span style={{ fontFamily: F.mono, fontSize: 32, color: C.foret }}>5 000 TC</span>
                <span style={{ fontFamily: F.mono, fontSize: 32, color: C.charbon, letterSpacing: 6 }}>4271</span>
              </div>
              <div style={{ fontSize: 12, color: C.cendre, marginTop: 8 }}>Montant · Tokens · OTP</div>
            </div>
            <ul style={{ flex: "1 1 280px", margin: 0, paddingLeft: 18, fontSize: 14, lineHeight: 1.8, color: C.charbon }}>
              <li>Toujours des <b>entiers</b> — jamais de décimaux.</li>
              <li>Séparateur de milliers = <b>espace</b> (« 2 500 »), jamais de virgule.</li>
              <li>Unité <b>après</b> le nombre : « FCFA » ou « TC ».</li>
              <li>Police <b>JetBrains Mono</b>, couleur Néré pour la mise en avant.</li>
            </ul>
          </div>
        </Section>

        {/* 11 — DO / DON'T */}
        <Section n="11" title="À faire / À éviter">
          <div style={{ display: "grid", gap: 18, gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))" }}>
            <div style={{ background: C.bambouSoft, borderRadius: 16, padding: 22 }}>
              <div style={{ fontWeight: 800, color: C.foret, marginBottom: 14, fontSize: 15 }}>À FAIRE</div>
              {["Fond Manioc ou Forêt — jamais blanc pur", "Une idée + une action par slide", "Accent Néré sur le mot ou chiffre clé", "Titres en Marcellus, montants en Mono", "Marge 96 px et zone basse dégagée"].map((t) => (
                <div key={t} style={swItem}><Ic size={18} color={C.bambou}>{PATHS.check}</Ic><span style={{ fontSize: 13.5, color: C.charbon, lineHeight: 1.4 }}>{t}</span></div>
              ))}
            </div>
            <div style={{ background: C.lateriteSoft, borderRadius: 16, padding: 22 }}>
              <div style={{ fontWeight: 800, color: C.laterite, marginBottom: 14, fontSize: 15 }}>À ÉVITER</div>
              {["Angles vifs (border-radius 0)", "Couleurs hors palette Atelier CAARCO", "Texte dans la zone basse (UI Instagram)", "Plusieurs CTA ou messages par slide", "Chiffres décimaux ou statistiques inventées"].map((t) => (
                <div key={t} style={swItem}><Ic size={18} color={C.laterite}>{PATHS.x}</Ic><span style={{ fontSize: 13.5, color: C.charbon, lineHeight: 1.4 }}>{t}</span></div>
              ))}
            </div>
          </div>
        </Section>

        {/* TOKENS */}
        <Section n="12" title="Tokens (à copier)">
          <pre style={{ background: C.nuit, color: C.manioc, borderRadius: 16, padding: 22, fontFamily: F.mono, fontSize: 12.5, lineHeight: 1.65, overflowX: "auto" }}>{`const Couleurs = {
  foret:'#1f3b2a', foret90:'#284a36', foret30:'#b4c4b9',
  bambou:'#3d6b4a', bambouSoft:'#cfdbcf',
  nere:'#c89441', nereSoft:'#f1e3c2',
  laterite:'#b8612e', lateriteSoft:'#f1d6c3',
  manioc:'#fbf9f3', brume:'#ece9e0',
  cendre:'#6b6f68', charbon:'#1d2420', nuit:'#0f1411',
};
const Polices = {
  display:'Marcellus',          // titres, accroches
  body:'Plus Jakarta Sans',     // corps, boutons
  mono:'JetBrains Mono',        // FCFA / TC / OTP
};
const Formats = { carre:[1080,1080], portrait:[1080,1350] };`}</pre>
        </Section>

        <div style={{ marginTop: 60, paddingTop: 22, borderTop: `1px solid ${C.brume}`, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <Mark size={30} arc={C.foret} />
            <span style={{ fontFamily: F.display, fontSize: 18, color: C.charbon, letterSpacing: 1 }}>CAARCO</span>
          </div>
          <span style={{ fontFamily: F.mono, fontSize: 12, color: C.cendre }}>Charte carrousels IG · Atelier CAARCO · v1.0</span>
        </div>
      </main>
    </div>
  );
}
