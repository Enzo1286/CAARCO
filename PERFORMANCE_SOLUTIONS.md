# 🔧 SOLUTIONS CODE — PERFORMANCE CAARCO

Fichier d'implémentation rapide des 10 optimisations prioritaires.

---

## 1️⃣ COURSES.JS — Ajouter Pagination + LIMIT

**Fichier**: `src/services/courses.js`

```javascript
// ═══ ANCIENS ═══ À REMPLACER

// ❌ AVANT
const SELECT_CLIENT = `
  *,
  transporteur:users!transporteur_id(
    id, nom, telephone, note_moyenne, nombre_courses, type_vehicule, photo_url, kyc_valide
  )
`;

export async function coursesClient(clientId) {
  const { data, error } = await supabase
    .from('courses')
    .select(SELECT_CLIENT)
    .eq('client_id', clientId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

// ✅ APRÈS
// Définir des SELECTs granulaires par cas d'usage
const SELECT_COURSES_LIST = `
  id, created_at, statut, prix_fcfa, 
  depart_adresse, arrivee_adresse, distance_km,
  transporteur:users!transporteur_id(id, nom, photo_url)
`;

const SELECT_COURSE_DETAIL = `
  *,
  transporteur:users!transporteur_id(*),
  client:users!client_id(id, nom, telephone, photo_url)
`;

// Liste paginée
export async function coursesClient(clientId, page = 0, pageSize = 20) {
  const offset = page * pageSize;
  const { data, error, count } = await supabase
    .from('courses')
    .select(SELECT_COURSES_LIST, { count: 'exact' })
    .eq('client_id', clientId)
    .order('created_at', { ascending: false })
    .range(offset, offset + pageSize - 1);
  if (error) throw error;
  return { data, total: count, page, pageSize };
}

// Détail complet
export async function obtenirCourse(courseId) {
  const { data, error } = await supabase
    .from('courses')
    .select(SELECT_COURSE_DETAIL)
    .eq('id', courseId)
    .single();
  if (error) throw error;
  return data;
}

// Listeners avec SELECT optimisé
export function abonnerCoursesClient(clientId, callback) {
  const canal = supabase
    .channel(`courses-client-${clientId}`)
    .on('postgres_changes', {
      event: 'UPDATE', schema: 'public', table: 'courses',
      filter: `client_id=eq.${clientId}`,
    }, async (payload) => {
      try {
        const { data } = await supabase
          .from('courses')
          .select(SELECT_COURSES_LIST)
          .eq('id', payload.new.id)
          .single();
        callback(data ?? payload.new);
      } catch {
        callback(payload.new);
      }
    })
    .subscribe();
  return { unsubscribe: () => supabase.removeChannel(canal) };
}
```

---

## 2️⃣ USECOMPTEURMESSAGES.JS — Fixer Memory Leak

**Fichier**: `src/hooks/useCompteurMessages.js`

```javascript
// ❌ AVANT
export function useCompteurMessages() {
  const { user } = useAuth();
  const [compteur, setCompteur] = useState(0);
  const canalRef = useRef(null);

  async function rafraichir(userId) {
    if (!userId) return;
    try {
      const { data, error } = await supabase.rpc('compteur_messages_non_lus', { p_user_id: userId });
      if (!error && typeof data === 'number') setCompteur(data);
    } catch {}
  }

  useEffect(() => {
    if (!user?.id) { setCompteur(0); return; }
    rafraichir(user.id);

    canalRef.current = supabase
      .channel(`compteur-msgs-${user.id}-${Date.now()}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' },
        () => rafraichir(user.id))
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'messages' },
        () => rafraichir(user.id))
      .subscribe();

    return () => {
      if (canalRef.current) supabase.removeChannel(canalRef.current).catch?.(() => {});
    };
  }, [user?.id]);

  return compteur;
}

// ✅ APRÈS
export function useCompteurMessages() {
  const { user } = useAuth();
  const [compteur, setCompteur] = useState(0);
  const canalRef = useRef(null);
  const userIdRef = useRef(null);

  async function rafraichir(userId) {
    if (!userId) return;
    try {
      const { data, error } = await supabase.rpc('compteur_messages_non_lus', { p_user_id: userId });
      if (!error && typeof data === 'number') setCompteur(data);
    } catch {}
  }

  useEffect(() => {
    const userId = user?.id;

    if (!userId) {
      setCompteur(0);
      if (canalRef.current) {
        supabase.removeChannel(canalRef.current).catch(() => {});
        canalRef.current = null;
      }
      userIdRef.current = null;
      return;
    }

    // Cleanup ancien canal avant d'en créer un nouveau
    if (userIdRef.current !== userId && canalRef.current) {
      supabase.removeChannel(canalRef.current).catch(() => {});
      canalRef.current = null;
    }

    rafraichir(userId);

    // ID déterministe (pas de Date.now())
    const canalId = `compteur-msgs-${userId}`;
    canalRef.current = supabase
      .channel(canalId)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `destinataire_id=eq.${userId}`,  // ← Filtrer côté serveur
      }, () => rafraichir(userId))
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'messages',
        filter: `destinataire_id=eq.${userId}`,
      }, () => rafraichir(userId))
      .subscribe();

    userIdRef.current = userId;

    return () => {
      if (canalRef.current) {
        supabase.removeChannel(canalRef.current).catch(() => {});
        canalRef.current = null;
      }
    };
  }, [user?.id]);

  return compteur;
}
```

---

## 3️⃣ MESSAGES.JS — Ajouter Pagination

**Fichier**: `src/services/messages.js`

```javascript
// ❌ AVANT
const SELECT_MSG = '*, expediteur:users!messages_expediteur_id_fkey(id, nom, photo_url)';

export async function obtenirMessages(courseId) {
  const { data, error } = await supabase
    .from('messages')
    .select(SELECT_MSG)
    .eq('course_id', courseId)
    .order('created_at', { ascending: true });
  if (error) {
    console.error('[messages] obtenirMessages error:', JSON.stringify(error));
    throw error;
  }
  return data ?? [];
}

// ✅ APRÈS
const SELECT_MSG = '*, expediteur:users!messages_expediteur_id_fkey(id, nom, photo_url)';

export async function obtenirMessages(courseId, page = 0, pageSize = 50) {
  const offset = page * pageSize;
  const { data, error, count } = await supabase
    .from('messages')
    .select(SELECT_MSG, { count: 'exact' })
    .eq('course_id', courseId)
    .order('created_at', { ascending: true })
    .range(offset, offset + pageSize - 1);
  if (error) {
    console.error('[messages] obtenirMessages error:', JSON.stringify(error));
    throw error;
  }
  return { data: data ?? [], total: count, page, pageSize };
}

// DM paginé aussi
export async function obtenirMessagesDM(monId, autreId, page = 0, pageSize = 50) {
  const offset = page * pageSize;
  const { data, error, count } = await supabase
    .from('messages')
    .select(SELECT_MSG, { count: 'exact' })
    .is('course_id', null)
    .or(
      `and(expediteur_id.eq.${monId},destinataire_id.eq.${autreId}),` +
      `and(expediteur_id.eq.${autreId},destinataire_id.eq.${monId})`
    )
    .order('created_at', { ascending: true })
    .range(offset, offset + pageSize - 1);
  if (error) {
    console.error('[messages] obtenirMessagesDM error:', JSON.stringify(error));
    throw error;
  }
  return { data: data ?? [], total: count, page, pageSize };
}
```

---

## 4️⃣ USEPOSITIONGPS.JS — Optimiser pour Batterie

**Fichier**: `src/hooks/usePositionGPS.js`

```javascript
// ❌ AVANT
const INTERVALLE_MS  = 30_000;
const DISTANCE_M     = 30;

export function usePositionGPS(userId) {
  // ...
}

// ✅ APRÈS
function getGPSConfig() {
  const h = new Date().getHours();
  const isNuit = h >= 20 || h < 6;
  const isWeekend = [0, 6].includes(new Date().getDay());

  if (isNuit) {
    return isWeekend
      ? { time: 600_000, distance: 100 }   // 10 min / 100m
      : { time: 300_000, distance: 50 };   // 5 min / 50m
  }
  return { time: 30_000, distance: 30 };   // 30s / 30m (jour actif)
}

export function usePositionGPS(userId) {
  const watchRef = useRef(null);
  const activeRef = useRef(false);
  const configRef = useRef(getGPSConfig());
  const lastUpdateRef = useRef(0);

  // Recalculer config toutes les heures
  useEffect(() => {
    const interval = setInterval(() => {
      configRef.current = getGPSConfig();
    }, 3_600_000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (!userId) return;

    activeRef.current = true;

    async function demarrer() {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();
        if (status !== 'granted' || !activeRef.current) return;

        const config = configRef.current;
        watchRef.current = await Location.watchPositionAsync(
          {
            accuracy: Location.Accuracy.Balanced,
            timeInterval: config.time,
            distanceInterval: config.distance,
          },
          async (location) => {
            if (!activeRef.current) return;

            // Throttle uploads: max 1 par 30s même si GPS envoie plus
            const now = Date.now();
            if (now - lastUpdateRef.current < 30_000) return;
            lastUpdateRef.current = now;

            const { latitude, longitude } = location.coords;
            await mettreAJourPosition(userId, latitude, longitude).catch(() => {});
          }
        );
      } catch {
        // Permissions refusées ou pas de GPS
      }
    }

    demarrer();

    return () => {
      activeRef.current = false;
      try { watchRef.current?.remove(); } catch {}
      watchRef.current = null;
    };
  }, [userId]);
}
```

---

## 5️⃣ THEMECONTEXT.JS — Memoiser Valeur

**Fichier**: `src/context/ThemeContext.js`

```javascript
// ❌ AVANT
return (
  <ThemeContext.Provider
    value={{
      isDark,
      colors,
      fonts,
      fontSize,
      spacing,
      radius,
      shadow,
      capteurActif: false,
      modeManuel: manuel,
      basculerMode,
      resetAuto,
      pret,
    }}
  >
    {children}
  </ThemeContext.Provider>
);

// ✅ APRÈS
import { useMemo } from 'react';

const contextValue = useMemo(() => ({
  isDark,
  colors: isDark ? darkColors : lightColors,
  fonts,
  fontSize,
  spacing,
  radius,
  shadow,
  capteurActif: false,
  modeManuel: manuel,
  basculerMode,
  resetAuto,
  pret,
}), [isDark, manuel, pret]);  // ← Dépendances clés

return (
  <ThemeContext.Provider value={contextValue}>
    {children}
  </ThemeContext.Provider>
);
```

---

## 6️⃣ BANNIÉREPUBLICITE.JS — Fixer FlatList Keys

**Fichier**: `src/components/BannierePublicite.js`

```javascript
// ❌ AVANT
<FlatList
  ref={flatRef}
  data={pubsLoop}
  keyExtractor={(_, i) => String(i)}  // ← ANTI-PATTERN!
  horizontal
  // ...
/>

// ✅ APRÈS
<FlatList
  ref={flatRef}
  data={pubsLoop}
  keyExtractor={(item, i) => `pub-${item.id || i}`}  // ← Item ID ou fallback
  horizontal
  maxToRenderPerBatch={5}  // ← Limiter renders
  updateCellsBatchingPeriod={50}  // ← Batch updates
  // ...
/>
```

---

## 7️⃣ SELECTEURVILE.JS — FlatList Keys

**Fichier**: `src/components/SelecteurVille.js`

```javascript
// ❌ AVANT
<FlatList
  data={villesFiltrees}
  keyExtractor={v => v}  // ← OK si strings uniques
  // ...
/>

// ✅ APRÈS (ajouter index comme fallback)
<FlatList
  data={villesFiltrees}
  keyExtractor={(v, i) => `${v}-${i}`}  // ← Unique même si doublons
  maxToRenderPerBatch={10}
  updateCellsBatchingPeriod={50}
  // ...
/>
```

---

## 8️⃣ CHATSCREEN.JS — React.memo sur Composants

**Fichier**: `src/screens/ChatScreen.js`

```javascript
// ❌ AVANT
function BulleMessage({ item, estMoi, onLongPress, onPress, onOuvrirCarte, selectionne, selectionMode }) {
  // ...
}

// ✅ APRÈS
const BulleMessage = React.memo(
  function BulleMessage({ item, estMoi, onLongPress, onPress, onOuvrirCarte, selectionne, selectionMode }) {
    // ...
  },
  (prevProps, nextProps) => {
    // Comparaison personnalisée: true = props identiques (ne pas re-render)
    return (
      prevProps.item.id === nextProps.item.id &&
      prevProps.item.created_at === nextProps.item.created_at &&
      prevProps.estMoi === nextProps.estMoi &&
      prevProps.selectionne === nextProps.selectionne
    );
  }
);

// Idem pour StatutEnLigne et CarteLeafletPos
const StatutEnLigne = React.memo(StatutEnLigneImpl);
const CarteLeafletPos = React.memo(CarteLeafletPosImpl);
```

---

## 9️⃣ ACCUEILSCREEN.JS — React.memo sur Cartes

**Fichier**: `src/screens/client/AccueilScreen.js`

```javascript
// ✅ DÉJÀ BON
const CarteTrajetRecent = React.memo(function CarteTrajetRecent({ course, onPress }) {
  // ...
});

// Vérifier que CarteService aussi est mémorisé
const CarteService = React.memo(function CarteService({ service, cardW, onPress }) {
  // ...
});
```

---

## 🔟 PROFILSCREEN.JS — Consolider State

**Fichier**: `src/screens/ProfilScreen.js`

```javascript
// ❌ AVANT (30+ useState)
const [nom, setNom] = useState('');
const [pseudo, setPseudo] = useState('');
const [telephone, setTelephone] = useState('');
const [langue, setLangue] = useState('fr');
const [photoUri, setPhotoUri] = useState(null);
// ... etc

// ✅ APRÈS
const [profileData, setProfileData] = useState({
  nom: '',
  pseudo: '',
  telephone: '',
  langue: 'fr',
  photoUri: null,
  sexe: null,
  dateNaissance: null,
  ville: null,
  typeVehicule: '',
  // ...
});

const handleUpdateProfile = useCallback((updates) => {
  setProfileData(prev => ({ ...prev, ...updates }));
}, []);

// Usage:
handleUpdateProfile({ nom: 'Alice', langue: 'en' });
```

---

## 📋 FICHIERS À MODIFIER (Checklist)

- [ ] `src/services/courses.js` (Problem 1)
- [ ] `src/hooks/useCompteurMessages.js` (Problem 2)
- [ ] `src/services/messages.js` (Problem 4)
- [ ] `src/hooks/usePositionGPS.js` (Problem 7)
- [ ] `src/context/ThemeContext.js` (Problem 8)
- [ ] `src/components/BannierePublicite.js` (Problem 5)
- [ ] `src/components/SelecteurVille.js` (Problem 5)
- [ ] `src/screens/ChatScreen.js` (Problem 9 + 10)
- [ ] `src/hooks/useNotifsMessages.js` (Problem 2 similaire)
- [ ] `src/screens/ProfilScreen.js` (Problem 6)

---

## 🧪 VALIDATION APRÈS CHANGEMENTS

```bash
# 1. Tester que rien ne crash
npm run android

# 2. Profiler la mémoire (avant/après)
# → Ouvrir Flipper → Hermes Debugger → Memory
# → Consommer une ressource (charger 100 courses)
# → Checker que la mémoire augmente puis **diminue** en déscroll

# 3. Profiler renders
# → React DevTools → Profiler → Start recording
# → Navigate entre écrans 5-10x
# → Vérifier que temps < 100ms per navigation

# 4. Checker les listeners
# → React DevTools → Components
# → Chercher "canal" ou "channel"
# → Vérifier que nombre = 1 par hook (pas 10+)
```

---

**Réalisé par**: Performance Specialist (Claude Haiku 4.5)  
**Date**: 2026-06-18
