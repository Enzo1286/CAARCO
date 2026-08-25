#!/bin/sh
# Redemarre les services du projet Supabase de production.
#   sh scripts/restart_supabase.sh
#
# QUAND s'en servir : l'application n'affiche plus aucune donnee et l'API
# renvoie 503 avec le code PGRST002 (« Could not query the database for the
# schema cache »). Dans ce cas la BASE va bien : c'est PostgREST, la couche API,
# qui est bloquee. Inutile de chercher dans le code de l'app.
#
# Pour verifier avant de redemarrer :
#   sh scripts/etat_supabase.sh
#
# ⚠️ Le redemarrage coupe le service 1 a 10 minutes, pour TOUS les utilisateurs,
# y compris ceux du Play Store. A ne lancer que si l'API est deja hors service.
set -e
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
PROJET="dxwkikaniawpfljvteog"
TOKEN=$(grep '^SUPABASE_ACCESS_TOKEN=' "$RACINE/App/.env" | cut -d= -f2- | tr -d '\r"')

printf 'Redemarrer le projet Supabase CAARCO (production) ? [oui/NON] '
read reponse
[ "$reponse" = "oui" ] || { echo "Annule."; exit 0; }

echo "Demande de redemarrage..."
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -w '\nHTTP %{http_code}\n' \
  "https://api.supabase.com/v1/projects/$PROJET/restart"

echo
echo "Redemarrage lance. Comptez 1 a 10 minutes."
echo "Suivez la reprise avec : sh scripts/etat_supabase.sh"
