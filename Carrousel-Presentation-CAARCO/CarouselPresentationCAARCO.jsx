import React from 'react';

/**
 * Carrousel de présentation CAARCO — 1080 × 1350 (4:5)
 * Requiert Tailwind CSS et les polices Marcellus, Plus Jakarta Sans et JetBrains Mono.
 */
const slides = [
  {
    number: '01',
    eyebrow: 'L’application CAARCO',
    title: 'Le transport qui avance avec vous.',
    body: 'Pour déplacer un colis, des meubles ou les livraisons de votre activité, simplement.',
    tone: 'dark',
  },
  {
    number: '02',
    eyebrow: 'Une app, quatre usages',
    title: 'Tout ce que vous transportez.',
    uses: ['Livraison express', 'Déménagement', 'Logistique entreprises', 'Transport ponctuel'],
    tone: 'light',
  },
  {
    number: '03',
    eyebrow: 'Simple de bout en bout',
    title: 'Votre course en quatre temps.',
    steps: ['Indiquez le trajet', 'Recevez une estimation', 'Un transporteur accepte', 'Suivez la livraison'],
    tone: 'light',
  },
  {
    number: '04',
    eyebrow: 'Prêt à partir ?',
    title: 'Transportez mieux. Dès aujourd’hui.',
    body: 'CAARCO rapproche les personnes, les commerces et les transporteurs au Cameroun.',
    tone: 'dark',
  },
];

const cn = (...classes) => classes.filter(Boolean).join(' ');

function Mark({ light = false }) {
  return (
    <img
      className="h-16 w-16 object-contain"
      src={light ? '/assets/Logo CAARCO Light PNG.png' : '/assets/Logo CAARCO PNG.png'}
      alt="Logo CAARCO"
    />
  );
}

export default function CarouselPresentationCAARCO() {
  return (
    <main className="mx-auto flex max-w-[1080px] flex-col gap-8 bg-[#fbf9f3] p-4 text-[#1d2420]">
      {slides.map((slide) => (
        <article
          key={slide.number}
          aria-label={`Slide ${slide.number}`}
          className={cn(
            'relative aspect-[4/5] overflow-hidden rounded-[24px] p-16 sm:p-24',
            slide.tone === 'dark' ? 'bg-[#1f3b2a] text-[#fbf9f3]' : 'bg-[#fbf9f3] text-[#1d2420]'
          )}
        >
          <header className="relative z-10 flex items-center justify-between">
            <Mark light={slide.tone === 'dark'} />
            <span className={cn('font-mono text-xl', slide.tone === 'dark' ? 'text-[#b4c4b9]' : 'text-[#6b6f68]')}>
              {slide.number} / 04
            </span>
          </header>

          <section className="relative z-10 mt-24 max-w-3xl">
            <p className="font-sans text-sm font-extrabold uppercase tracking-[0.24em] text-[#c89441]">{slide.eyebrow}</p>
            <h1 className="mt-5 font-[Marcellus] text-6xl leading-[1.04] sm:text-8xl">{slide.title}</h1>
            {slide.body && <p className={cn('mt-8 max-w-2xl font-sans text-xl leading-relaxed sm:text-3xl', slide.tone === 'dark' ? 'text-[#b4c4b9]' : 'text-[#6b6f68]')}>{slide.body}</p>}
          </section>

          {slide.uses && (
            <div className="relative z-10 mt-16 grid grid-cols-2 gap-4 font-sans text-lg font-bold sm:gap-6 sm:text-2xl">
              {slide.uses.map((use) => <div key={use} className="rounded-[24px] bg-[#ece9e0] p-6 text-[#1f3b2a] shadow-[0_4px_12px_rgba(31,59,42,0.08)]">{use}</div>)}
            </div>
          )}

          {slide.steps && (
            <ol className="relative z-10 mt-14 space-y-4 font-sans">
              {slide.steps.map((step, index) => (
                <li key={step} className="flex items-center gap-5 rounded-[14px] bg-white p-5 text-xl shadow-[0_2px_8px_rgba(31,59,42,0.06)] sm:text-2xl">
                  <span className="font-mono text-[#c89441]">0{index + 1}</span><span className="font-bold">{step}</span>
                </li>
              ))}
            </ol>
          )}

          {slide.number === '04' && (
            <div className="relative z-10 mt-16 inline-flex rounded-full bg-[#3d6b4a] px-8 py-5 font-sans text-xl font-bold text-white sm:text-2xl">Téléchargez CAARCO</div>
          )}

          <div aria-hidden="true" className={cn('absolute -bottom-24 -right-20 h-96 w-96 rounded-full border-[40px]', slide.tone === 'dark' ? 'border-[#b4c4b9]/10' : 'border-[#cfdbcf]')} />
        </article>
      ))}
    </main>
  );
}
