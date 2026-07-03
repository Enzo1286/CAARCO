import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const MONEROO_BASE = 'https://api.moneroo.io/v1';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors });
  }

  try {
    const { courseId, clientId, montant, methode, numero, nom, telephone } = await req.json();

    if (!courseId || !clientId || !montant || !methode) {
      return new Response(
        JSON.stringify({ error: 'Paramètres manquants' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    if (typeof montant !== 'number' || montant <= 0 || !Number.isInteger(montant)) {
      return new Response(
        JSON.stringify({ error: 'Le montant doit être un entier positif en XAF' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    if (montant > 5_000_000) {
      return new Response(
        JSON.stringify({ error: 'Montant maximum 5 000 000 XAF' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    const monerooMethode = methode === 'orange_money' ? 'orange_cm' : 'mtn_cm';
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const apiKey = Deno.env.get('MONEROO_API_KEY')!;

    const supabase = createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Vérifier que le montant correspond au prix réel de la course (anti-falsification)
    const { data: course, error: courseErr } = await supabase
      .from('courses')
      .select('prix_fcfa, client_id, statut')
      .eq('id', courseId)
      .single();

    if (courseErr || !course) {
      return new Response(
        JSON.stringify({ error: 'Course introuvable' }),
        { status: 404, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    if (course.client_id !== clientId) {
      return new Response(
        JSON.stringify({ error: 'Non autorisé' }),
        { status: 403, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    if (course.prix_fcfa !== montant) {
      return new Response(
        JSON.stringify({ error: 'Montant invalide — ne correspond pas au prix de la course' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    const phoneClean = (telephone ?? '').replace(/[\s+]/g, '').replace(/^237/, '');
    const emailLocal = phoneClean || clientId.replace(/-/g, '').slice(0, 20);

    const monerooRes = await fetch(`${MONEROO_BASE}/payments/initialize`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        amount: montant,
        currency: 'XAF',
        description: `Course CAARCO #${courseId.slice(-8).toUpperCase()}`,
        payment_method: monerooMethode,
        customer: {
          email: `${emailLocal}@caarco.cm`,
          first_name: nom ?? 'Client',
          last_name: 'CAARCO',
          phone: phoneClean ? `+237${phoneClean}` : `+237000000000`,
        },
        metadata: { courseId, clientId },
        return_url: 'https://app.caarco.cm/paiement/retour',
        notify_url: `${supabaseUrl}/functions/v1/moneroo-webhook`,
      }),
    });

    const monerooBody = await monerooRes.json();

    if (!monerooRes.ok) {
      throw new Error(monerooBody?.message ?? `Moneroo ${monerooRes.status}`);
    }

    const paymentId: string = monerooBody.data.id;
    const checkoutUrl: string = monerooBody.data.checkout_url;
    const reference = `CAARCO-${Date.now().toString(36).toUpperCase()}`;

    await supabase.from('paiements').insert({
      course_id: courseId,
      client_id: clientId,
      montant_fcfa: montant,
      methode,
      numero_mobile: numero ? numero.replace(/\s/g, '') : null,
      statut: 'initie',
      reference,
      moneroo_payment_id: paymentId,
    });

    return new Response(
      JSON.stringify({ checkoutUrl, paymentId, reference }),
      { headers: { ...cors, 'Content-Type': 'application/json' } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } }
    );
  }
});
