import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function categoriesCompatibles(categorieVehicule: string): string[] {
  switch (categorieVehicule) {
    case 'moto':                return ['moto'];
    case 'voiture':             return ['voiture'];
    case 'tricycle_camionnette':
    case 'tricycle':
    case 'camionnette':
    case 'van':
    case 'camion':
      return ['tricycle', 'camionnette', 'tricycle_camionnette', 'van', 'camion'];
    default:
      return [];
  }
}

function interpoler(template: string, vars: Record<string, string>): string {
  return Object.entries(vars).reduce(
    (acc, [k, v]) => acc.replaceAll(`{${k}}`, v ?? ''),
    template,
  );
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors });
  }

  try {
    const { courseId, categorieVehicule, departAdresse, arriveeAdresse, prixFcfa, methodePaiement } = await req.json();

    if (!courseId || !categorieVehicule) {
      return new Response(
        JSON.stringify({ error: 'courseId et categorieVehicule requis' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const typesCompatibles = categoriesCompatibles(categorieVehicule);
    if (!typesCompatibles.length) {
      return new Response(
        JSON.stringify({ skip: true, reason: 'categorie_inconnue' }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const { data: transporteurs, error } = await supabase
      .from('users')
      .select('id, expo_push_token')
      .eq('role', 'transporteur')
      .eq('statut_connexion', 'en_ligne')
      .in('type_vehicule', typesCompatibles)
      .not('expo_push_token', 'is', null);

    if (error || !transporteurs?.length) {
      return new Response(
        JSON.stringify({ skip: true, reason: 'no_transporteurs', error: error?.message }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const tokens = transporteurs.map((t) => t.expo_push_token).filter(Boolean);

    if (!tokens.length) {
      return new Response(
        JSON.stringify({ skip: true, reason: 'no_tokens' }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    // ── Résoudre le template personnalisé ────────────────────────────────────
    const prixFormate = prixFcfa
      ? new Intl.NumberFormat('fr-FR').format(prixFcfa) + ' XAF'
      : '';

    const variables = {
      depart:  departAdresse ?? '',
      arrivee: arriveeAdresse ?? '',
      // Séparateur inclus dans la variable pour que le template reste propre quand montant = ''
      montant: prixFormate ? ' · ' + prixFormate : '',
    };

    let titreNotif = '📦 Nouvelle course disponible !';
    let corpsNotif = `${departAdresse ?? ''} → ${arriveeAdresse ?? ''}${prixFormate ? ' · ' + prixFormate : ''}`;

    const { data: tpl } = await supabase
      .from('notification_templates')
      .select('titre, corps')
      .eq('cle', 'nouvelle_course_tr')
      .eq('actif', true)
      .maybeSingle();

    if (tpl) {
      titreNotif = interpoler(tpl.titre, variables);
      corpsNotif = interpoler(tpl.corps, variables);
    }
    // ─────────────────────────────────────────────────────────────────────────

    const messages = tokens.map((token) => ({
      to: token,
      sound: 'default',
      title: titreNotif,
      body: corpsNotif,
      data: { courseId, type: 'nouvelle_course' },
      channelId: 'caarco-alarme-v2',
      priority: 'high',
      ttl: 30,
    }));

    // Expo limite à 100 messages par batch
    const batches: typeof messages[] = [];
    for (let i = 0; i < messages.length; i += 100) {
      batches.push(messages.slice(i, i + 100));
    }

    const results = await Promise.allSettled(
      batches.map((batch) =>
        fetch(EXPO_PUSH_URL, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(batch),
        }).then((r) => r.json()),
      ),
    );

    return new Response(
      JSON.stringify({
        success: true,
        notifies: tokens.length,
        batches: results.length,
      }),
      { headers: { ...cors, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } },
    );
  }
});
