#!/bin/bash
# First 1000 Kit — Full Pipeline
# Run the complete lead generation flow

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
OUTPUT_DIR="$SCRIPT_DIR/output/$(date +%Y-%m-%d)"

# Create output directory
mkdir -p "$OUTPUT_DIR"

log() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Args
SEARCH_QUERY="${1:-AI marketing automation}"
MAX_POSTS="${2:-50}"
CAMPAIGN_NAME="${3:-First1000-$(date +%Y%m%d)}"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║          FIRST 1000 CUSTOMERS KIT                ║"
echo "║                                                   ║"
echo "║  Query: $SEARCH_QUERY"
echo "║  Max Posts: $MAX_POSTS"
echo "║  Output: $OUTPUT_DIR"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Step 1: Mine LinkedIn
log "STEP 1: Mining LinkedIn for engagers..."
"$SKILLS_DIR/linkedin-miner/scripts/mine.sh" "$SEARCH_QUERY" "$MAX_POSTS" "$OUTPUT_DIR/01-raw-posts.json"

log "STEP 1b: Extracting engagers..."
"$SKILLS_DIR/linkedin-miner/scripts/extract.sh" "$OUTPUT_DIR/01-raw-posts.json" > "$OUTPUT_DIR/02-leads.json"

LEAD_COUNT=$(jq '.meta.total_leads' "$OUTPUT_DIR/02-leads.json")
echo "  → Extracted $LEAD_COUNT leads"

# Step 2: Enrich with emails
log "STEP 2: Enriching leads with emails..."
"$SKILLS_DIR/lead-enricher/scripts/enrich.sh" "$OUTPUT_DIR/02-leads.json" "$OUTPUT_DIR/03-enriched.json"

ENRICHED_COUNT=$(jq '.meta.enriched' "$OUTPUT_DIR/03-enriched.json")
echo "  → Enriched $ENRICHED_COUNT leads with emails"

# Step 3: Score against ICP
log "STEP 3: Scoring leads against ICP..."
"$SKILLS_DIR/icp-scorer/scripts/score.sh" "$OUTPUT_DIR/03-enriched.json" "$OUTPUT_DIR/04-scored.json"

A_TIER=$(jq '.meta.tier_a' "$OUTPUT_DIR/04-scored.json")
B_TIER=$(jq '.meta.tier_b' "$OUTPUT_DIR/04-scored.json")
echo "  → A-tier: $A_TIER | B-tier: $B_TIER"

# Step 4: Generate emails (A and B tier)
log "STEP 4: Generating personalized emails..."
# Filter to A+B tier with emails
jq '{leads: [.leads[] | select(.tier == "A" or .tier == "B") | select(.email != null)]}' \
  "$OUTPUT_DIR/04-scored.json" > "$OUTPUT_DIR/04b-qualified.json"

# TODO: Call Claude/OpenClaw for email generation
# For now, create placeholder
cat > "$OUTPUT_DIR/05-emails.json" << EOF
{
  "meta": {
    "note": "Email generation requires Claude API call",
    "leads_to_email": $(jq '.leads | length' "$OUTPUT_DIR/04b-qualified.json"),
    "generated_at": "$(date -Iseconds)"
  },
  "leads": $(jq '.leads' "$OUTPUT_DIR/04b-qualified.json")
}
EOF

QUALIFIED=$(jq '.leads | length' "$OUTPUT_DIR/04b-qualified.json")
echo "  → $QUALIFIED qualified leads ready for email generation"

# Step 5: Load to Instantly (manual for now)
log "STEP 5: Ready for Instantly"
echo "  → Qualified leads saved to: $OUTPUT_DIR/04b-qualified.json"
echo "  → Run manually:"
echo "     ./skills/instantly-loader/scripts/load.sh $OUTPUT_DIR/05-emails.json --new-campaign \"$CAMPAIGN_NAME\""

# Summary
log "PIPELINE COMPLETE"
echo "  Search Query:     $SEARCH_QUERY"
echo "  Posts Scraped:    $MAX_POSTS"
echo "  Total Leads:      $LEAD_COUNT"
echo "  Enriched:         $ENRICHED_COUNT"
echo "  A-Tier:           $A_TIER"
echo "  B-Tier:           $B_TIER"
echo "  Qualified:        $QUALIFIED"
echo ""
echo "  Output Directory: $OUTPUT_DIR"
echo ""
echo "  Next Steps:"
echo "  1. Review qualified leads: $OUTPUT_DIR/04b-qualified.json"
echo "  2. Generate emails with Claude"
echo "  3. Load to Instantly"
echo ""
