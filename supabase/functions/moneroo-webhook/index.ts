import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

async function verifierSignature(corps: string, signature: string, secret: string): Promise<boolean> {
  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );
    if (!/^[0-9a-fA-F]+$/.test(signature) || signature.length % 2 !== 0) {
      return false;
    }
    const bytes = new Uint8Array(signature.length / 2);
    for (let i = 0; i < signature.length; i += 2) {
      bytes[i / 2] = parseInt(signature.slice(i, i + 2), 16);
    }
    return await crypto.subtle.verify('HMAC', key, bytes, encoder.encode(corps));
  } catch {
    return false;
  }
}

serve(async (req) => {
  try {
    const corps = await req.text();
    const signature = req.headers.get('X-Moneroo-Signature') ?? '';
    const secret = Deno.env.get('MONEROO_WEBHOOK_SECRET');
    if (!secret) {
      console.error('[moneroo-webhook] MONEROO_WEBHOOK_SECRET non configuré — webhook rejeté');
      return new Response('Configuration manquante', { status: 500 });
    }

    const valide = await verifierSignature(corps, signature, secret);
    if (!valide) {
      return new Response('Signature invalide', { status: 401 });
    }

    const payload = JSON.parse(corps);
    const { event, data } = payload;

    if (event !== 'payment.success') {
      return new Response('OK', { status: 200 });
    }

    const paymentId: string = data?.id;
    const meta = data?.metadata ?? {};
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // ── Cas 1 : Recharge wallet ───────────────────────────────────────────────
    if (meta.type === 'recharge_wallet') {
      const walletId: string = meta.walletId;
      const montant: number = data?.amount ?? 0;

      if (!walletId || !montant) {
        return new Response('Données recharge manquantes', { status: 400 });
      }

      // Récupérer la transaction pour idempotence + notif
      const { data: txData } = await supabase
        .from('transactions_wallet')
        .select('id, statut, wallet_id, wallets!inner(user_id)')
        .eq('moneroo_payment_id', paymentId)
        .single();

      // Idempotence : déjà traitée, ne pas recréditer
      if (txData?.statut === 'validee') {
        return new Response('OK', { status: 200 });
      }

      // Validation + crédit atomique et idempotent via RPC
      if (txData?.id) {
        await supabase.rpc('valider_recharge_atomique', {
          p_transaction_id: txData.id,
          p_wallet_id:      txData.wallet_id,
          p_montant:        montant,
        });
      }

      // Notifier l'utilisateur que sa recharge est confirmée
      const userId = txData?.wallets?.user_id;
      if (userId) {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        await fetch(`${supabaseUrl}/functions/v1/notify`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            userId,
            titre: '💰 Recharge réussie !',
            corps: `Votre portefeuille a été crédité de ${montant.toLocaleString('fr-FR')} XAF.`,
            data: { type: 'recharge_validee' },
          }),
        });
      }

      return new Response('OK', { status: 200 });
    }

    // ── Cas 2 : Paiement de course ────────────────────────────────────────────
    const courseId: string = meta.courseId;

    if (!paymentId || !courseId) {
      return new Response('Données paiement manquantes', { status: 400 });
    }

    // Idempotence : vérifier si le paiement a déjà été mis en séquestre ou libéré
    const { data: paiementExist } = await supabase
      .from('paiements')
      .select('statut')
      .eq('moneroo_payment_id', paymentId)
      .single();

    if (paiementExist?.statut && ['sequestre', 'libere'].includes(paiementExist.statut)) {
      return new Response('OK', { status: 200 });
    }

    // Mettre en séquestre
    await Promise.all([
      supabase
        .from('paiements')
        .update({ statut: 'sequestre' })
        .eq('moneroo_payment_id', paymentId),
      supabase
        .from('courses')
        .update({ statut_paiement: 'sequestre' })
        .eq('id', courseId),
    ]);

    // Si la course est déjà terminée (paiement post-livraison), libérer immédiatement
    const { data: course } = await supabase
      .from('courses')
      .select('statut, transporteur_id, client_id, prix_fcfa')
      .eq('id', courseId)
      .single();

    if (course?.statut === 'terminee') {
      await supabase.rpc('liberer_sequestre_course', { p_course_id: courseId });
    }

    // Notifier le transporteur que le paiement est sécurisé
    if (course?.transporteur_id) {
      const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
      await fetch(`${supabaseUrl}/functions/v1/notify`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: course.transporteur_id,
          titre: '💳 Paiement sécurisé',
          corps: `Le client a payé ${(course.prix_fcfa ?? 0).toLocaleString('fr-FR')} XAF. Vous recevrez votre part à la livraison.`,
          data: { courseId, type: 'paiement_sequestre' },
        }),
      });
    }

    return new Response('OK', { status: 200 });
  } catch (e) {
    console.error('Webhook error:', e.message);
    return new Response(`Erreur: ${e.message}`, { status: 500 });
  }
});
