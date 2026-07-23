import React, { useState } from "react";

/* ============================================================
   CARROUSEL INSTAGRAM — CAARCO · PARCOURS CLIENT (7 slides)
   Système : Atelier CAARCO · Formats 1080×1080 (1:1) & 1080×1350 (4:5)
   ============================================================ */

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

/* ---------- Logo officiel : anneau ouvert Forêt + disque Néré ---------- */
function Mark({ size = 40, arc = C.foret, disc = C.nere }) {
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
  securite: <><path d="M12 2 20 6v6c0 5-3.5 8-8 10-4.5-2-8-5-8-10V6z" /><path d="M9 12l2 2 4-4" /></>,
  download: <><path d="M12 3v12" /><path d="M7 11l5 5 5-5" /><path d="M4 20h16" /></>,
};

/* Rend un slide 1080px mis à l'échelle pour l'aperçu */
function SlideFrame({ w, h, previewW = 272, children }) {
  const scale = previewW / w;
  return (
    <div style={{ width: previewW, height: Math.round(h * scale), borderRadius: 16, overflow: "hidden", boxShadow: "0 6px 22px rgba(31,59,42,0.16)", flex: "0 0 auto" }}>
      <div style={{ width: w, height: h, transform: `scale(${scale})`, transformOrigin: "top left" }}>{children}</div>
    </div>
  );
}

function Pied({ page, dark }) {
  const col = dark ? C.manioc : C.charbon;
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", position: "relative" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        <Mark size={40} arc={dark ? C.manioc : C.foret} />
        <span style={{ fontFamily: F.display, fontSize: 28, color: col, letterSpacing: 1 }}>CAARCO</span>
      </div>
      <span style={{ fontFamily: F.mono, fontSize: 30, color: dark ? C.manioc : C.cendre }}>{page}</span>
    </div>
  );
}

/* ---------------- SLIDES ---------------- */
const base = (w, h, bg) => ({
  width: w, height: h, background: bg, position: "relative", overflow: "hidden",
  padding: 96, display: "flex", flexDirection: "column", justifyContent: "space-between", fontFamily: F.body,
});

function SlideCover({ w, h }) {
  return (
    <div style={base(w, h, C.foret)}>
      <svg viewBox="0 0 100 100" fill="none" style={{ position: "absolute", right: -w * 0.30, bottom: -w * 0.22, opacity: 0.06, width: w, height: w }}>
        <path d="M81.7 54.6 A 33 33 0 1 0 45.5 82.8" stroke={C.manioc} strokeWidth="10" strokeLinecap="round" />
        <circle cx="82" cy="55" r="12" fill={C.manioc} />
      </svg>
      <div style={{ display: "flex", alignItems: "center", gap: 22, position: "relative" }}>
        <Mark size={66} arc={C.manioc} />
        <span style={{ fontFamily: F.display, fontSize: 46, color: C.manioc, letterSpacing: 2 }}>CAARCO</span>
      </div>
      <div style={{ position: "relative" }}>
        <div style={{ fontWeight: 800, fontSize: 30, letterSpacing: 4, textTransform: "uppercase", color: C.nere, marginBottom: 34 }}>Parcours client</div>
        <h1 style={{ fontFamily: F.display, fontSize: 100, lineHeight: 1.02, color: C.manioc, margin: 0 }}>Envoyez un colis en quelques minutes.</h1>
        <p style={{ fontSize: 36, color: C.foret30, margin: "34px 0 0" }}>5 étapes, de la commande à la livraison.</p>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", position: "relative" }}>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.foret30 }}>Glissez →</span>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.manioc }}>01 / 07</span>
      </div>
    </div>
  );
}

function SlideStep({ w, h, data }) {
  return (
    <div style={base(w, h, C.manioc)}>
      <div style={{ position: "absolute", left: 40, top: 96, bottom: 96, width: 10, background: C.nere, borderRadius: 9999 }} />
      <div style={{ display: "flex", alignItems: "center", gap: 30 }}>
        <div style={{ width: 112, height: 112, borderRadius: 9999, background: C.bambouSoft, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Ic size={56} color={C.foret}>{PATHS[data.icon]}</Ic>
        </div>
        <div>
          <div style={{ fontWeight: 800, fontSize: 26, letterSpacing: 3, textTransform: "uppercase", color: C.bambou }}>Étape {data.n} / 5</div>
          <div style={{ fontFamily: F.display, fontSize: 44, color: C.charbon }}>{data.kicker}</div>
        </div>
      </div>
      <div>
        <h2 style={{ fontFamily: F.display, fontSize: 78, lineHeight: 1.05, color: C.charbon, margin: "0 0 30px" }}>{data.titre}</h2>
        <p style={{ fontSize: 35, lineHeight: 1.5, color: C.cendre, margin: 0, maxWidth: 830 }}>{data.corps}</p>
        {data.otp && (
          <div style={{ display: "flex", gap: 18, marginTop: 44 }}>
            {["4", "2", "7", "1"].map((d, i) => (
              <div key={i} style={{ width: 100, height: 116, borderRadius: 18, background: C.foret, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <span style={{ fontFamily: F.mono, fontSize: 66, color: C.nere }}>{d}</span>
              </div>
            ))}
          </div>
        )}
      </div>
      <Pied page={data.page} dark={false} />
    </div>
  );
}

function SlidePrix({ w, h }) {
  return (
    <div style={base(w, h, C.foret)}>
      <div style={{ display: "flex", alignItems: "center", gap: 30 }}>
        <div style={{ width: 112, height: 112, borderRadius: 9999, background: "rgba(200,148,65,0.18)", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Ic size={56} color={C.nere}>{PATHS.delai}</Ic>
        </div>
        <div>
          <div style={{ fontWeight: 800, fontSize: 26, letterSpacing: 3, textTransform: "uppercase", color: C.nere }}>Étape 3 / 5</div>
          <div style={{ fontFamily: F.display, fontSize: 44, color: C.foret30 }}>Tarif</div>
        </div>
      </div>
      <div>
        <h2 style={{ fontFamily: F.display, fontSize: 74, lineHeight: 1.05, color: C.manioc, margin: "0 0 26px" }}>Le prix, affiché aussitôt</h2>
        <div style={{ fontFamily: F.mono, fontSize: 128, color: C.nere, lineHeight: 1, fontWeight: 700 }}>2 750 FCFA</div>
        <div style={{ fontFamily: F.mono, fontSize: 28, color: C.foret30, marginTop: 12 }}>Exemple : 8 km, en journée</div>
        <p style={{ fontSize: 33, lineHeight: 1.5, color: C.manioc, margin: "36px 0 0", maxWidth: 850 }}>Tarif transparent calculé à la distance. Vous réglez le transporteur directement, en espèces ou Mobile Money.</p>
      </div>
      <Pied page="04 / 07" dark={true} />
    </div>
  );
}

function SlideCTA({ w, h }) {
  return (
    <div style={base(w, h, `linear-gradient(160deg, ${C.foret90} 0%, ${C.nuit} 100%)`)}>
      <div style={{ display: "flex", alignItems: "center", gap: 22 }}>
        <Mark size={66} arc={C.manioc} />
        <span style={{ fontFamily: F.display, fontSize: 46, color: C.manioc, letterSpacing: 2 }}>CAARCO</span>
      </div>
      <div>
        <div style={{ fontWeight: 800, fontSize: 28, letterSpacing: 3, textTransform: "uppercase", color: C.nere, marginBottom: 30 }}>C'est parti</div>
        <h2 style={{ fontFamily: F.display, fontSize: 96, lineHeight: 1.03, color: C.manioc, margin: "0 0 20px" }}>Téléchargez CAARCO</h2>
        <p style={{ fontSize: 38, color: C.foret30, margin: "0 0 52px" }}>Gratuit sur Google Play — Cameroun</p>
        <div style={{ display: "inline-flex", alignItems: "center", gap: 22, background: C.bambou, color: C.manioc, padding: "32px 54px", borderRadius: 9999 }}>
          <Ic size={46} color={C.manioc}>{PATHS.download}</Ic>
          <span style={{ fontWeight: 700, fontSize: 40 }}>Installer l'application</span>
        </div>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.nere }}>@caarco.cm</span>
        <span style={{ fontFamily: F.mono, fontSize: 30, color: C.manioc }}>07 / 07</span>
      </div>
    </div>
  );
}

const STEPS = {
  s1: { n: 1, kicker: "Adresses", icon: "adresse", titre: "Indiquez le retrait et la livraison", corps: "Saisissez l'adresse de départ et de destination. L'autocomplétion sur carte vous fait gagner du temps.", page: "02 / 07" },
  s2: { n: 2, kicker: "Colis", icon: "colis", titre: "Décrivez votre colis", corps: "Type d'envoi (colis, déménagement, matériaux…) et poids estimé : CAARCO s'adapte à tous vos besoins.", page: "03 / 07" },
  s4: { n: 4, kicker: "Suivi", icon: "transport", titre: "Un transporteur arrive", corps: "Un transporteur proche accepte votre course. Suivez sa position en temps réel jusqu'à destination.", page: "05 / 07" },
  s5: { n: 5, kicker: "Livraison", icon: "securite", titre: "Livraison confirmée", corps: "Donnez votre code à 4 chiffres à la remise du colis, puis notez le transporteur.", page: "06 / 07", otp: true },
};

const SLIDES = [
  { cap: "01 · Couverture", render: (w, h) => <SlideCover w={w} h={h} /> },
  { cap: "02 · Étape 1 — Adresses", render: (w, h) => <SlideStep w={w} h={h} data={STEPS.s1} /> },
  { cap: "03 · Étape 2 — Colis", render: (w, h) => <SlideStep w={w} h={h} data={STEPS.s2} /> },
  { cap: "04 · Étape 3 — Prix", render: (w, h) => <SlidePrix w={w} h={h} /> },
  { cap: "05 · Étape 4 — Transporteur & suivi", render: (w, h) => <SlideStep w={w} h={h} data={STEPS.s4} /> },
  { cap: "06 · Étape 5 — Livraison (code OTP)", render: (w, h) => <SlideStep w={w} h={h} data={STEPS.s5} /> },
  { cap: "07 · Appel à l'action", render: (w, h) => <SlideCTA w={w} h={h} /> },
];

/* ---------------- PAGE ---------------- */
export default function CarrouselParcoursClient() {
  const [fmt, setFmt] = useState("portrait");
  const d = FORMATS[fmt];
  return (
    <div style={{ background: C.manioc, minHeight: "100vh", color: C.charbon, fontFamily: F.body, padding: "40px 32px 80px" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Marcellus&family=JetBrains+Mono:wght@400;500;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box}
      `}</style>

      <div style={{ maxWidth: 1180, margin: "0 auto" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 10 }}>
          <Mark size={40} arc={C.foret} />
          <span style={{ fontFamily: F.display, fontSize: 24, letterSpacing: 1, color: C.charbon }}>CAARCO</span>
        </div>
        <h1 style={{ fontFamily: F.display, fontSize: 38, color: C.charbon, margin: "0 0 6px" }}>Carrousel — Parcours client</h1>
        <p style={{ fontSize: 15, color: C.cendre, margin: 0, maxWidth: 640, lineHeight: 1.55 }}>
          7 slides pour présenter l'application CAARCO, du premier écran à la livraison. Textes d'exemple à ajuster ; le prix affiché illustre la formule (base + distance).
        </p>

        <div style={{ display: "flex", alignItems: "center", gap: 10, margin: "22px 0 28px", flexWrap: "wrap" }}>
          <span style={{ fontSize: 13, color: C.cendre }}>Format :</span>
          {Object.keys(FORMATS).map((k) => (
            <button key={k} onClick={() => setFmt(k)} style={{
              cursor: "pointer", fontFamily: F.body, fontWeight: 700, fontSize: 13, padding: "8px 18px", borderRadius: 9999,
              border: `1.5px solid ${fmt === k ? C.foret : C.brume}`, background: fmt === k ? C.foret : C.blanc, color: fmt === k ? C.manioc : C.cendre,
            }}>{FORMATS[k].label} · {FORMATS[k].nom}</button>
          ))}
          <span style={{ fontFamily: F.mono, fontSize: 12, color: C.cendre, marginLeft: 4 }}>{d.w} × {d.h} px</span>
        </div>

        <div style={{ display: "flex", flexWrap: "wrap", gap: 24 }}>
          {SLIDES.map((s) => (
            <div key={s.cap} style={{ width: 272 }}>
              <SlideFrame w={d.w} h={d.h} previewW={272}>{s.render(d.w, d.h)}</SlideFrame>
              <div style={{ fontSize: 12.5, color: C.cendre, marginTop: 10, lineHeight: 1.4 }}>{s.cap}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
