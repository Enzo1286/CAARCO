import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Interpolation côté Edge Function (même logique que notif_interpoler SQL)
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
    // Nouvelle API : { userId, template_cle, variables, data }
    // Ancienne API : { userId, titre, corps, data }          ← rétrocompatible
    const {
      userId,
      titre: titreParam,
      corps: corpsParam,
      template_cle,
      variables,
      data,
    } = await req.json();

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'userId requis' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // ── Résolution du titre et du corps ────────────────────────────────────
    let titre = titreParam as string | undefined;
    let corps = corpsParam as string | undefined;

    if (template_cle) {
      const { data: tpl } = await supabase
        .from('notification_templates')
        .select('titre, corps')
        .eq('cle', template_cle)
        .eq('actif', true)
        .maybeSingle();

      if (tpl) {
        const vars = variables ?? {};
        titre = interpoler(tpl.titre, vars);
        corps = interpoler(tpl.corps, vars);
      }
      // Si le template n'existe pas, on utilise les valeurs titreParam/corpsParam passées en fallback
    }

    if (!titre || !corps) {
      return new Response(
        JSON.stringify({ error: 'titre et corps requis (ou template_cle valide)' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    // ── Récupération du token push + nom (pour auto-injection dans {nom}) ──
    const { data: user, error } = await supabase
      .from('users')
      .select('expo_push_token, nom')
      .eq('id', userId)
      .single();

    if (error || !user?.expo_push_token) {
      return new Response(
        JSON.stringify({ skip: true, reason: 'no_token' }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    // Auto-injection : {nom} = prénom du destinataire (sauf si déjà fourni par le caller)
    // Fonctionne même si user.nom est vide (remplace {nom} par '') — évite l'affichage littéral de {nom}
    if (template_cle) {
      const vars = variables ?? {};
      if (!('nom' in vars)) vars['nom'] = user.nom ?? '';
      // Re-interpoler avec {nom} désormais disponible
      titre = interpoler(titre, vars);
      corps  = interpoler(corps,  vars);
    }

    // Canal Android : alarme pour nouvelle_course (bypass DnD), normal sinon
    const channelId = data?.type === 'nouvelle_course' ? 'caarco-alarme-v2' : 'caarco-v2';

    const pushRes = await fetch(EXPO_PUSH_URL, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: user.expo_push_token,
        sound: 'default',
        title: titre,
        body: corps,
        data: data ?? {},
        channelId,
      }),
    });

    const pushBody = await pushRes.json();

    return new Response(
      JSON.stringify({ success: true, expo: pushBody }),
      { headers: { ...cors, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } },
    );
  }
});
