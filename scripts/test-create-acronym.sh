#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
SHORT="${1:-OMG}"
LONG="${2:-Oh My God}"

if [[ "${SHORT}" == "-h" || "${SHORT}" == "--help" ]]; then
    cat <<'EOF'
Usage:
  ./scripts/test-create-acronym.sh [short] [long]

Examples:
  ./scripts/test-create-acronym.sh OMG "Oh My God"
  BASE_URL=http://127.0.0.1:8080 ./scripts/test-create-acronym.sh API "Application Programming Interface"

Environment:
  BASE_URL   Override the API host. Default: http://127.0.0.1:8080
EOF
    exit 0
fi

short_json=$(perl -MJSON::PP -e 'print encode_json($ARGV[0])' "$SHORT")
long_json=$(perl -MJSON::PP -e 'print encode_json($ARGV[0])' "$LONG")
payload=$(printf '{"short":%s,"long":%s}' "$short_json" "$long_json")

echo "POST ${BASE_URL}/api/acronym"
echo "Payload: ${payload}"

curl --silent --show-error --fail-with-body \
    --request POST "${BASE_URL}/api/acronym" \
    --header "Content-Type: application/json" \
    --data "${payload}"

echo