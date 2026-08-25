#!/bin/sh
# Etat des services Supabase de production (lecture seule, sans risque).
#   sh scripts/etat_supabase.sh
#
# REST a 503 + projet ACTIVE_HEALTHY  → PostgREST bloque : redemarrage utile
#   (voir scripts/restart_supabase.sh)
# REST a 521/522/525                  → redemarrage en cours, patienter
# Tout a 200                          → les services vont bien : si l'app ne
#   charge toujours rien, le probleme est ailleurs (Metro, reseau du telephone)
set -e
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
PROJET="dxwkikaniawpfljvteog"
ENVF="$RACINE/App/.env"
TOKEN=$(grep '^SUPABASE_ACCESS_TOKEN=' "$ENVF" | cut -d= -f2- | tr -d '\r"')
URL=$(grep '^EXPO_PUBLIC_SUPABASE_URL=' "$ENVF" | cut -d= -f2- | tr -d '\r"')
KEY=$(grep '^EXPO_PUBLIC_SUPABASE_ANON_KEY=' "$ENVF" | cut -d= -f2- | tr -d '\r"')

printf 'projet   : '
curl -s -m 30 -H "Authorization: Bearer $TOKEN" \
  "https://api.supabase.com/v1/projects/$PROJET" \
  | python -c "import sys,json;print(json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo '(injoignable)'

for ep in "rest/v1/users?select=id&limit=1" "auth/v1/health"; do
  nom=$(echo "$ep" | cut -d? -f1)
  printf '%-16s ' "$nom"
  curl -s -o /dev/null -w 'HTTP %{http_code}  %{time_total}s\n' -m 20 \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" "$URL/$ep"
done
