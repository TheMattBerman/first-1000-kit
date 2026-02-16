#!/bin/bash
# pre-call-research/scripts/deep-research.sh
# Deep pre-call research using Perplexity sonar-deep-research

set -e

PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY:-}"

if [[ -z "$PERPLEXITY_API_KEY" ]]; then
  echo "Error: PERPLEXITY_API_KEY not set" >&2
  exit 1
fi

# Parse args
NAME="$1"
COMPANY="$2"
TITLE="${3:-}"
CONTEXT="${4:-}"

if [[ -z "$NAME" ]]; then
  echo "Usage: deep-research.sh <name> <company> [title] [context]" >&2
  exit 1
fi

log() { echo "[$(date '+%H:%M:%S')] $1" >&2; }

log "Deep researching: $NAME @ $COMPANY"

# Master prompt
QUERY="You are my sales research analyst preparing me for a call with a prospect.

## PROSPECT INFO
- **Name:** $NAME
- **Company:** $COMPANY
- **Title:** $TITLE
- **Context:** $CONTEXT

Research this prospect and return a comprehensive pre-call brief:

## 1. COMPANY INTEL
- What does $COMPANY do? (1 sentence)
- Company size and stage (startup/scaleup/enterprise)
- Recent funding? (amount, date, investors)
- Revenue signals if available
- Key competitors

## 2. BUYING SIGNALS
Check for these indicators they might be ready to buy:
- Hiring for growth/marketing/sales roles? (links to job posts if found)
- Recent product launches or announcements?
- Press coverage in last 6 months?
- Leadership changes?
- Tech stack changes or migrations?
- Expansion (new markets, offices, headcount growth)?

## 3. PERSON INTEL
Research $NAME specifically:
- Their background (previous companies, career path)
- Recent LinkedIn posts or interviews (summarize their POV)
- Speaking engagements or podcasts?
- What do they seem to care about publicly?
- Decision-making authority level?

## 4. LIKELY PAIN POINTS
Based on their role and company situation, what problems are they probably dealing with?
- List 3 specific pain points relevant to their context
- Rank by likely priority

## 5. CONVERSATION ANGLES
Suggest:
- 3 specific talking points relevant to their situation
- 2 questions to ask that show I did my homework
- 1 observation or compliment that feels genuine

## 6. OBJECTION PREP
What objections might they raise? How should I handle each?

## 7. RECOMMENDED APPROACH
- Best opening line for the call
- Key value prop to emphasize
- Ideal next step to propose

---

Be specific. Use real data from your research. If you can't find something, say 'Not found' — don't make it up.

Prioritize recency. Something from this month matters more than something from 2 years ago."

# Call Perplexity Deep Research
log "Calling Perplexity sonar-deep-research..."

RESPONSE=$(curl -s "https://api.perplexity.ai/chat/completions" \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"sonar-deep-research\",
    \"messages\": [{\"role\": \"user\", \"content\": $(echo "$QUERY" | jq -Rs .)}]
  }")

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // "Error: No response"')

# Output the brief
TODAY=$(date '+%A, %B %d, %Y')

echo "# Pre-Call Brief: $NAME @ $COMPANY"
echo "**Generated:** $TODAY"
echo "**Model:** Perplexity sonar-deep-research"
echo ""
echo "---"
echo ""
echo "$CONTENT"
echo ""
echo "---"
echo "*Research completed at $(date '+%H:%M:%S')*"

log "Done."
