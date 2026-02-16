#!/bin/bash
# instantly-loader/scripts/campaigns.sh
# List Instantly.ai campaigns

set -e

INSTANTLY_API_KEY="${INSTANTLY_API_KEY:-}"

if [[ -z "$INSTANTLY_API_KEY" ]]; then
  echo "Error: INSTANTLY_API_KEY not set" >&2
  exit 1
fi

curl -s "https://api.instantly.ai/api/v1/campaign/list?api_key=$INSTANTLY_API_KEY" | \
  jq '[.[] | {id, name, status, daily_limit: .daily_contact_limit}]'
