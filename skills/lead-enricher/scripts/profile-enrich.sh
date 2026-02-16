#!/bin/bash
# lead-enricher/scripts/profile-enrich.sh
# Enrich leads with full LinkedIn profile data using Fresh LinkedIn Data API (RapidAPI)
# Run this BEFORE enrich.sh to get profile data + potential emails from LinkedIn

set -e

# Config
RAPIDAPI_KEY="${RAPIDAPI_KEY:-YOUR_RAPIDAPI_KEY_HERE}"
RAPIDAPI_HOST="fresh-linkedin-profile-data.p.rapidapi.com"
BASE_URL="https://$RAPIDAPI_HOST"

# Args
INPUT_FILE="${1:-/dev/stdin}"

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# Read input
if [[ "$INPUT_FILE" == "/dev/stdin" ]]; then
  INPUT_DATA=$(cat)
else
  INPUT_DATA=$(cat "$INPUT_FILE")
fi

# Extract leads array
LEADS=$(echo "$INPUT_DATA" | jq -c '.leads // .')
LEAD_COUNT=$(echo "$LEADS" | jq 'length')

log "Enriching $LEAD_COUNT leads with LinkedIn profile data..."

# Process each lead
ENRICHED_LEADS="[]"
ENRICHED_COUNT=0
EMAILS_FOUND=0

for i in $(seq 0 $((LEAD_COUNT - 1))); do
  LEAD=$(echo "$LEADS" | jq -c ".[$i]")
  LINKEDIN_URL=$(echo "$LEAD" | jq -r '.linkedin_url // empty')
  NAME=$(echo "$LEAD" | jq -r '.name // "Unknown"')
  
  log "[$((i+1))/$LEAD_COUNT] $NAME"
  
  if [[ -z "$LINKEDIN_URL" ]]; then
    log "  ⚠️ No LinkedIn URL, skipping"
    ENRICHED_LEADS=$(echo "$ENRICHED_LEADS" | jq ". + [$LEAD]")
    continue
  fi
  
  # Call RapidAPI profile endpoint
  PROFILE=$(curl -s -X GET "$BASE_URL/get-linkedin-profile?linkedin_url=$LINKEDIN_URL&include_skills=false" \
    -H "x-rapidapi-key: $RAPIDAPI_KEY" \
    -H "x-rapidapi-host: $RAPIDAPI_HOST" 2>/dev/null || echo '{}')
  
  # Check for valid response
  if echo "$PROFILE" | jq -e '.data.full_name' > /dev/null 2>&1; then
    ENRICHED_COUNT=$((ENRICHED_COUNT + 1))
    
    # Extract profile data
    PROFILE_DATA=$(echo "$PROFILE" | jq '.data')
    EMAIL=$(echo "$PROFILE_DATA" | jq -r '.email // empty')
    
    if [[ -n "$EMAIL" && "$EMAIL" != "null" ]]; then
      EMAILS_FOUND=$((EMAILS_FOUND + 1))
      log "  ✅ Found email: $EMAIL"
    fi
    
    # Merge profile data into lead
    ENRICHED_LEAD=$(echo "$LEAD" | jq \
      --argjson profile "$PROFILE_DATA" '
      . + {
        first_name: ($profile.first_name // .first_name),
        last_name: ($profile.last_name // .last_name),
        full_name: ($profile.full_name // .name),
        title: ($profile.job_title // .headline),
        headline: ($profile.headline // .headline),
        company: ($profile.company // .company),
        company_domain: ($profile.company_domain // null),
        company_size: ($profile.company_employee_range // null),
        company_industry: ($profile.company_industry // null),
        location: ($profile.location // null),
        follower_count: ($profile.follower_count // null),
        connection_count: ($profile.connection_count // null),
        linkedin_email: ($profile.email // null),
        experiences: ($profile.experiences // null),
        skills: ($profile.skills // null),
        profile_enriched: true
      }
    ')
    
    ENRICHED_LEADS=$(echo "$ENRICHED_LEADS" | jq ". + [$ENRICHED_LEAD]")
    log "  ✅ Enriched: $NAME @ $(echo "$PROFILE_DATA" | jq -r '.company // "Unknown"')"
  else
    log "  ⚠️ Could not fetch profile"
    ENRICHED_LEADS=$(echo "$ENRICHED_LEADS" | jq ". + [$LEAD]")
  fi
  
  # Rate limit (1 credit per profile, be nice to API)
  sleep 0.5
done

log "Done. Enriched: $ENRICHED_COUNT, Emails found: $EMAILS_FOUND"

# Output
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --argjson total "$LEAD_COUNT" \
  --argjson enriched "$ENRICHED_COUNT" \
  --argjson emails_found "$EMAILS_FOUND" \
  --arg enriched_at "$TIMESTAMP" \
  --argjson leads "$ENRICHED_LEADS" \
  '{
    meta: {
      total_leads: $total,
      profile_enriched: $enriched,
      linkedin_emails_found: $emails_found,
      enriched_at: $enriched_at
    },
    leads: $leads
  }'
