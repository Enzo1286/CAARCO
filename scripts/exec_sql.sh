#!/bin/sh
# Execute un fichier SQL sur la prod Supabase via l'API Management.
#   sh scripts/exec_sql.sh <fichier.sql>
# Le token est lu dans App/.env et n'est jamais affiche.
# NB : passe par curl -- l'API rejette urllib (Cloudflare, error 1010).
set -e
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
FICHIER="$1"
[ -f "$FICHIER" ] || { echo "Fichier introuvable : $FICHIER" >&2; exit 2; }

TOKEN=$(grep '^SUPABASE_ACCESS_TOKEN=' "$RACINE/App/.env" | cut -d= -f2- | tr -d '\r"')
PAYLOAD=$(python -c "
import io, json, sys
sql = io.open(sys.argv[1], encoding='utf-8').read()
sys.stdout.write(json.dumps({'query': sql}))
" "$FICHIER")

printf '%s' "$PAYLOAD" | curl -s -X POST \
  "https://api.supabase.com/v1/projects/dxwkikaniawpfljvteog/database/query" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @-
echo
