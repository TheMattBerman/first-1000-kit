#!/bin/bash
# signal-scanner/scripts/scan.sh
# Deep research on A-tier leads using Perplexity sonar-deep-research

set -e

PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY:-}"

if [[ -z "$PERPLEXITY_API_KEY" ]]; then
  echo "Error: PERPLEXITY_API_KEY not set" >&2
  exit 1
fi

INPUT="${1:-/dev/stdin}"
LEADS=$(cat "$INPUT")

log() { echo "[$(date '+%H:%M:%S')] $1" >&2; }

A_TIER=$(echo "$LEADS" | jq '[.leads[] | select(.tier == "A")]')
TOTAL=$(echo "$A_TIER" | jq 'length')

log "Deep researching $TOTAL A-tier leads via Perplexity..."

RESULTS="[]"
WITH_SIGNALS=0
PRIORITY_1=0

for i in $(seq 0 $((TOTAL - 1))); do
  LEAD=$(echo "$A_TIER" | jq ".[$i]")
  NAME=$(echo "$LEAD" | jq -r '.name')
  COMPANY=$(echo "$LEAD" | jq -r '.company // "Unknown"')
  TITLE=$(echo "$LEAD" | jq -r '.headline // ""')
  
  log "Researching: $NAME @ $COMPANY"
  
  # Master prompt for deep research
  QUERY="You are my sales research analyst. Research this lead:

Name: $NAME
Title: $TITLE  
Company: $COMPANY

Return:

## 1. COMPANY INTEL
- What does the company do? (1 sentence)
- Company size and stage (startup/scaleup/enterprise)
- Recent funding? (amount, date, investors)

## 2. BUYING SIGNALS
Check for:
- Hiring for growth/marketing/sales roles?
- Recent product launches or announcements?
- Press coverage in last 6 months?
- Expansion signals (new markets, headcount growth)?

## 3. PERSON INTEL
- Their background and career path
- Recent LinkedIn posts or interviews (summarize their POV)
- What do they care about publicly?

## 4. OUTREACH HOOK
Write a personalized first line for a cold email that:
- References something specific to them
- Is under 20 words
- Feels human

Be specific. Use real data. If you can't find something, say 'Not found'."

  # Call Perplexity Deep Research
  RESPONSE=$(curl -s "https://api.perplexity.ai/chat/completions" \
    -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"sonar-deep-research\",
      \"messages\": [{\"role\": \"user\", \"content\": $(echo "$QUERY" | jq -Rs .)}]
    }" 2>/dev/null || echo '{}')
  
  CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // "No response"')
  
  # Detect signals from response
  SIGNAL_COUNT=0
  echo "$CONTENT" | grep -qi "series\|raised\|funding\|million\|seed" && SIGNAL_COUNT=$((SIGNAL_COUNT + 1))
  echo "$CONTENT" | grep -qi "hiring\|job.*open\|recruiting\|positions" && SIGNAL_COUNT=$((SIGNAL_COUNT + 1))
  echo "$CONTENT" | grep -qi "announced\|launch\|partnership\|techcrunch\|press" && SIGNAL_COUNT=$((SIGNAL_COUNT + 1))
  echo "$CONTENT" | grep -qi "growth\|expand\|revenue\|doubled\|scaling" && SIGNAL_COUNT=$((SIGNAL_COUNT + 1))
  
  # Priority assignment
  PRIORITY=0
  [[ $SIGNAL_COUNT -ge 3 ]] && PRIORITY=1 && PRIORITY_1=$((PRIORITY_1 + 1))
  [[ $SIGNAL_COUNT -eq 2 ]] && PRIORITY=2
  [[ $SIGNAL_COUNT -eq 1 ]] && PRIORITY=3
  [[ $SIGNAL_COUNT -gt 0 ]] && WITH_SIGNALS=$((WITH_SIGNALS + 1))
  
  # Build result with full research
  RESULT=$(echo "$LEAD" | jq \
    --arg research "$CONTENT" \
    --argjson signal_count "$SIGNAL_COUNT" \
    --argjson priority "$PRIORITY" \
    '. + {
      deep_research: $research,
      signal_score: $signal_count,
      priority: $priority
    }')
  
  RESULTS=$(echo "$RESULTS" | jq --argjson lead "$RESULT" '. + [$lead]')
  
  log "  → $SIGNAL_COUNT signals found, Priority $PRIORITY"
  
  # Rate limiting (deep research takes longer)
  sleep 2
done

# Output final JSON
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --argjson total "$TOTAL" \
  --argjson with_signals "$WITH_SIGNALS" \
  --argjson priority_1 "$PRIORITY_1" \
  --arg scanned_at "$TIMESTAMP" \
  --argjson leads "$RESULTS" \
  '{
    meta: {
      total_scanned: $total,
      with_signals: $with_signals,
      priority_1: $priority_1,
      model: "sonar-deep-research",
      scanned_at: $scanned_at
    },
    leads: $leads
  }'

log "Done. $WITH_SIGNALS leads with signals, $PRIORITY_1 Priority 1."
