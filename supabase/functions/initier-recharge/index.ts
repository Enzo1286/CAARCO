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
    const { walletId, clientId, montant, methode, nom, telephone } = await req.json();

    if (!walletId || !clientId || !montant || !methode) {
      return new Response(
        JSON.stringify({ error: 'Paramètres manquants' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    if (montant < 500) {
      return new Response(
        JSON.stringify({ error: 'Montant minimum 500 XAF' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    if (montant > 2_000_000) {
      return new Response(
        JSON.stringify({ error: 'Montant maximum 2 000 000 XAF par recharge' }),
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

    // Vérifier que le wallet appartient bien au clientId fourni
    const { data: walletCheck, error: walletErr } = await supabase
      .from('wallets')
      .select('id')
      .eq('id', walletId)
      .eq('user_id', clientId)
      .single();

    if (walletErr || !walletCheck) {
      return new Response(
        JSON.stringify({ error: 'Wallet introuvable ou non autorisé' }),
        { status: 403, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    const phoneClean = (telephone ?? '').replace(/[\s+]/g, '').replace(/^237/, '');
    // Fallback email si le numéro est absent : utiliser l'UUID du client (toujours valide)
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
        description: `Recharge portefeuille CAARCO — ${montant.toLocaleString('fr-FR')} XAF`,
        payment_method: monerooMethode,
        customer: {
          email: `${emailLocal}@caarco.cm`,
          first_name: nom ?? 'Client',
          last_name: 'CAARCO',
          phone: phoneClean ? `+237${phoneClean}` : `+237000000000`,
        },
        metadata: { walletId, clientId, type: 'recharge_wallet' },
        return_url: 'https://app.caarco.cm/recharge/retour',
        notify_url: `${supabaseUrl}/functions/v1/moneroo-webhook`,
      }),
    });

    const monerooBody = await monerooRes.json();

    if (!monerooRes.ok) {
      const detail = monerooBody?.message ?? monerooBody?.error ?? JSON.stringify(monerooBody);
      console.error(`[initier-recharge] Moneroo ${monerooRes.status}:`, detail);
      throw new Error(`Moneroo ${monerooRes.status}: ${detail}`);
    }

    const paymentId: string = monerooBody.data.id;
    const checkoutUrl: string = monerooBody.data.checkout_url;

    // Créer la transaction wallet en statut 'initie'
    const { data: tx, error: txErr } = await supabase
      .from('transactions_wallet')
      .insert({
        wallet_id:            walletId,
        type:                 'recharge',
        montant_fcfa:         montant,
        methode,
        statut:               'initie',
        moneroo_payment_id:   paymentId,
        moneroo_checkout_url: checkoutUrl,
      })
      .select()
      .single();

    if (txErr) throw new Error(txErr.message);

    return new Response(
      JSON.stringify({ checkoutUrl, paymentId, transactionId: tx.id }),
      { headers: { ...cors, 'Content-Type': 'application/json' } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } }
    );
  }
});
