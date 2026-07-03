# 📊 MÉTRIQUES & BENCHMARKS — CAARCO Performance

Document pour mesurer avant/après implémentation des optimisations.

---

## 🎯 OBJECTIFS DE PERFORMANCE

| Métrique | Cible | Seuil | Notes |
|----------|-------|-------|-------|
| **Bundle APK** | < 30 MB | 45 MB | Actuellement ~45 MB |
| **Démarrage app** | < 3s | 5s | Actuellement ~4-5s |
| **Navigation** | < 300ms | 500ms | Actuellement 500ms-1s |
| **FlatList (100 items)** | < 500ms render | 1s | Actuellement 800ms+ |
| **Memory (idle)** | < 150 MB | 250 MB | Actuellement 180-200 MB |
| **Memory (100 courses)** | < 200 MB | 350 MB | Actuellement 250-350 MB |
| **Battery (1h usage)** | < 30% drain | 50% | Actuellement 35-50% |
| **Frame rate** | 60 FPS (stable) | > 40 FPS | Actuellement 30-50 FPS |

---

## 📏 COMMENT MESURER

### A. Bundle Size
```bash
# Build APK de test
eas build --platform android --profile preview

# Analyser la composition
npx metro-visualizer dist/main.jsbundle

# Ou via Android Studio:
# Build → Analyze APK → ~/caarco.apk
```

**Attendu AVANT**: ~45 MB  
**Attendu APRÈS Phase 1**: ~40 MB (-5 MB)  
**Attendu APRÈS Phase 3**: ~35 MB (-10 MB)

---

### B. Memory Profiling (Flipper)

```bash
# 1. Installer Flipper
npm install -g flipper-server

# 2. Lancer l'app en debug
npm run android

# 3. Dans Flipper:
# → Device → Hermes Debugger
# → Memory Tab
# → Prendre un snapshot
# → Faire une action (charger 100 courses)
# → Prendre snapshot #2
# → Comparer différence
```

**Avant** (HomeScreen + 100 courses):
```
Heap size: 185 MB
Image cache: ~15 MB
Component tree: ~8 MB
Listeners: 6+ canaux = ~2 MB
TOTAL: ~210 MB
```

**Après Phase 1** (HomeScreen + 100 courses paginées):
```
Heap size: 140 MB (-45 MB)
Image cache: ~10 MB (-5 MB)
Component tree: ~5 MB (-3 MB)
Listeners: 1 canal = ~0.2 MB (-1.8 MB)
TOTAL: ~155 MB (-55 MB)
```

---

### C. Render Time Profiling (React DevTools)

```bash
# 1. Installer React DevTools
npm install --save-dev @react-native-community/hooks
# (ou utiliser Flipper React DevTools plugin)

# 2. En app: Profiler → Start recording

# 3. Navigation 5x entre écrans

# 4. Vérifier:
#    - Total render time < 300ms
#    - Per-component time < 50ms
#    - Re-renders < 5 per action
```

**Avant**:
```
AccueilScreen render: 1200ms (!)
  ├── CarteLeaflet: 400ms
  ├── FlatList (publicités): 300ms
  ├── BannierePublicite: 250ms
  └── Autres: 250ms

ChatScreen (50 messages): 800ms
```

**Après Phase 2**:
```
AccueilScreen render: 450ms (-62%)
  ├── CarteLeaflet: 150ms
  ├── FlatList: 100ms
  ├── BannierePublicite: 80ms
  └── Autres: 120ms

ChatScreen (50 messages paginés): 300ms (-62%)
```

---

### D. Battery Drain (Android Settings)

```
Settings → Battery → Battery usage

AVANT:
- App CAARCO: 45% drain / 1h usage
- GPS: 25% of app
- Network: 15% of app
- Display: 5% of app

APRÈS Phase 2:
- App CAARCO: 28% drain / 1h usage (-38%)
- GPS: 12% of app (night mode)
- Network: 10% of app
- Display: 6% of app
```

---

### E. Frame Rate (Android Profiler)

```bash
# Dans Android Studio:
# Build → Profile → Run 'app'
# → Profiler window → CPU tab
# → Selector: All Processes
# → Look at "Frames" visualization

# Red = dropped frame (< 60 FPS)
# Green = smooth (60 FPS)
```

**Avant** (HomeScreen + scroll):
```
Frame times: avg 25ms (40 FPS)
Dropped: 15-20% of frames
Jank: noticeable in lists > 50 items
```

**Après Phase 1**:
```
Frame times: avg 12ms (60 FPS stable)
Dropped: 2-5% of frames
Jank: smooth even with 200+ items
```

---

## 📋 CHECKLIST AVANT/APRÈS

### AVANT Implémentation

**Collecte de métriques baseline**:

```bash
# 1. Bundle
eas build --platform android --profile preview
# → Télécharger APK → Vérifier taille avec: `ls -lh ~/caarco.apk`
# Attendu: 45 MB

# 2. Memory
# → Ouvrir app → HomeScreen
# → Flipper → Memory → Snapshot
# Attendu: 180-200 MB

# 3. Navigation
# → Faire 10 navigations HomeScreen → Chat → HomeScreen
# → Mesurer temps moyen avec console.time()
# Attendu: 700ms-1s

# 4. Battery
# → Charger phone à 100%
# → Utiliser app 1h (scroll, chat, commandes)
# → Vérifier %  batterie restante
# Attendu: 50-65% restant (35-50% drain)

# 5. Frame rate
# → Android Studio Profiler
# → HomeScreen → Scroll 10x
# Attendu: avg 25-30ms (30-40 FPS)
```

### APRÈS Phase 1 (Jours 1-2)

```bash
# Répéter les 5 mesures ci-dessus
# ATTENDU:
# 1. Bundle: 40-42 MB (-3-5 MB)
# 2. Memory: 140-160 MB (-40-50 MB)
# 3. Navigation: 350-500ms (-50%)
# 4. Battery: 75-85% restant (+25% mieux)
# 5. Frame rate: 15-20ms (50-60 FPS)
```

### APRÈS Phase 2 (Jours 3-4)

```bash
# ATTENDU:
# 1. Bundle: 38-40 MB (-5-7 MB total)
# 2. Memory: 120-140 MB (-60-80 MB total)
# 3. Navigation: 250-350ms (-65%)
# 4. Battery: 85-90% restant (+35-40% mieux)
# 5. Frame rate: 10-15ms (60 FPS stable)
```

### APRÈS Phase 3 (Semaine 2)

```bash
# ATTENDU:
# 1. Bundle: 32-35 MB (-10-13 MB total)
# 2. Memory: 110-130 MB (-70-90 MB total)
# 3. Navigation: 200-300ms (-70%)
# 4. Battery: 88-92% restant (+40-45% mieux)
# 5. Frame rate: 10-12ms (60 FPS stable)
```

---

## 📊 TABLEAU DE SUIVI

Copier ce template et remplir après chaque phase:

```
╔════════════════════════════════════════════════════════════════════╗
║ PHASE 1 — CRITIQUES (Jour 1-2)                                    ║
╠════════════════════════════════════════════════════════════════════╣
║ Metric              │ Avant    │ Cible    │ Après    │ Gain    ║
║─────────────────────┼──────────┼──────────┼──────────┼─────────║
║ Bundle APK          │ 45 MB    │ 42 MB    │ ?        │ ?       ║
║ Memory (idle)       │ 190 MB   │ 160 MB   │ ?        │ ?       ║
║ Memory (100 items)  │ 280 MB   │ 200 MB   │ ?        │ ?       ║
║ Navigation time     │ 850ms    │ 500ms    │ ?        │ ?       ║
║ Frame rate (avg)    │ 28ms     │ 20ms     │ ?        │ ?       ║
║ Battery (1h)        │ 45%      │ 25%      │ ?        │ ?       ║
╚════════════════════════════════════════════════════════════════════╝

╔════════════════════════════════════════════════════════════════════╗
║ PHASE 2 — IMPORTANTS (Jours 3-4)                                  ║
╠════════════════════════════════════════════════════════════════════╣
║ Metric              │ Phase1   │ Cible    │ Après    │ Gain    ║
║─────────────────────┼──────────┼──────────┼──────────┼─────────║
║ Bundle APK          │ 42 MB    │ 40 MB    │ ?        │ ?       ║
║ Memory (100 items)  │ 200 MB   │ 170 MB   │ ?        │ ?       ║
║ Navigation time     │ 500ms    │ 350ms    │ ?        │ ?       ║
║ Frame rate (avg)    │ 20ms     │ 15ms     │ ?        │ ?       ║
║ Battery (1h)        │ 25%      │ 18%      │ ?        │ ?       ║
╚════════════════════════════════════════════════════════════════════╝

╔════════════════════════════════════════════════════════════════════╗
║ PHASE 3 — NICE-TO-HAVE (Semaine 2)                               ║
╠════════════════════════════════════════════════════════════════════╣
║ Metric              │ Phase2   │ Cible    │ Après    │ Gain    ║
║─────────────────────┼──────────┼──────────┼──────────┼─────────║
║ Bundle APK          │ 40 MB    │ 35 MB    │ ?        │ ?       ║
║ Memory (100 items)  │ 170 MB   │ 130 MB   │ ?        │ ?       ║
║ Navigation time     │ 350ms    │ 250ms    │ ?        │ ?       ║
║ Frame rate (avg)    │ 15ms     │ 12ms     │ ?        │ ?       ║
║ Battery (1h)        │ 18%      │ 12%      │ ?        │ ?       ║
╚════════════════════════════════════════════════════════════════════╝
```

---

## 🧪 SCRIPTS UTILES

### `benchmark.js` — Mesurer Performance Globale

Créer `scripts/benchmark.js`:

```javascript
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const results = {
  timestamp: new Date().toISOString(),
  bundleSize: null,
  metrics: {},
};

console.log('🔍 Benchmark CAARCO Performance…\n');

// 1. Bundle size
exec('eas build --platform android --profile preview', (err) => {
  if (err) {
    console.warn('⚠️  EAS Build failed, skipping bundle size');
    return;
  }
  
  exec('ls -lh dist/caarco.apk | awk \'{print $5}\'', (err, stdout) => {
    if (!err) {
      results.bundleSize = stdout.trim();
      console.log(`✅ Bundle: ${results.bundleSize}`);
    }
  });
});

// Sauvegarder résultats
setTimeout(() => {
  fs.writeFileSync(
    path.join(__dirname, `../benchmarks/result-${Date.now()}.json`),
    JSON.stringify(results, null, 2)
  );
  console.log('\n✅ Résultats sauvegardés en benchmarks/');
}, 30000);
```

Run: `node scripts/benchmark.js`

---

## 🔔 ALERTS & SEUILS

**Si après Phase 1:**
- Bundle > 44 MB → ⚠️ Recheck leafletBundle.js compression
- Memory > 200 MB → ⚠️ Listeners non cleanup, recheck useCompteurMessages
- Navigation > 600ms → ⚠️ Recheck ProfilScreen consolidation

**Si après Phase 2:**
- Bundle > 40 MB → 🔴 CRITICAL
- Memory > 180 MB → 🔴 CRITICAL
- Battery drain > 25% → ⚠️ GPS not throttled properly

---

## 📸 AVANT/APRÈS Screenshots

### Avant Phase 1 (Memory Profiler)

```
Timeline: 0:00 - 0:30
─────────────────────────────────
Heap size:  ████████████ 185 MB
JSObjects:  ███ 45 MB
Strings:    ██ 28 MB
Images:     ████ 60 MB
Other:      ████ 52 MB
```

### Après Phase 3 (Memory Profiler)

```
Timeline: 0:00 - 0:30
─────────────────────────────────
Heap size:  ████ 125 MB (-68% ✅)
JSObjects:  █ 25 MB
Strings:    █ 15 MB
Images:     ███ 45 MB
Other:      ██ 40 MB
```

---

## 🎯 SUCCESS CRITERIA

✅ **Succès** si après Phase 1:
- Memory -50 MB en situation normale
- Navigation -40% plus rapide
- Frame rate stable > 50 FPS
- Pas de regressions (tests pass)

✅ **Succès** si après Phase 3:
- Memory -80 MB en situation normale
- Navigation -70% plus rapide
- Frame rate 60 FPS stable
- Bundle < 35 MB
- Battery drain < 20% / 1h

---

**Document créé**: 2026-06-18  
**Maintenu par**: Performance Team  
**Prochaine révision**: Après Phase 2
