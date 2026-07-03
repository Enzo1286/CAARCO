import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function genererMotDePasse(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let pwd = '';
  for (let i = 0; i < 8; i++) pwd += chars[Math.floor(Math.random() * chars.length)];
  return pwd;
}

// Mêmes variantes que peut stocker auth.js (sans le +, avec ou sans 237)
// auth.js stocke : telephone.replace(/\s/g,'').replace(/^\+/,'')
// Ex: '+237699001286' → '237699001286'
//     '699001286'     → '699001286'
function variantesTelephone(input: string): string[] {
  const t = input.replace(/[\s\-\.]/g, '').replace(/^\+/, ''); // ex: '699001286' ou '237699001286'
  const avecIndicatif = t.startsWith('237') ? t : `237${t}`;   // '237699001286'
  const sansIndicatif = t.startsWith('237') ? t.slice(3) : t;  // '699001286'
  return [...new Set([t, avecIndicatif, sansIndicatif])];
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { telephone } = await req.json();
    if (!telephone) {
      return new Response(
        JSON.stringify({ error: 'Numéro de téléphone requis' }),
        { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    const variantes = variantesTelephone(telephone);

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Chercher l'utilisateur avec l'une des variantes de numéro
    const { data: utilisateur } = await supabaseAdmin
      .from('users')
      .select('id')
      .in('telephone', variantes)
      .limit(1)
      .maybeSingle();

    if (!utilisateur) {
      // Réponse identique — ne pas révéler l'existence du compte
      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    const tempPassword = genererMotDePasse();

    const { error: errReset } = await supabaseAdmin.auth.admin.updateUserById(
      utilisateur.id,
      { password: tempPassword }
    );

    if (errReset) {
      return new Response(
        JSON.stringify({ error: 'Impossible de réinitialiser le mot de passe.' }),
        { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, tempPassword }),
      { headers: { ...cors, 'Content-Type': 'application/json' } }
    );

  } catch (e) {
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } }
    );
  }
});
