#!/bin/bash
# pre-call-research/scripts/research.sh
# Generate pre-call research brief

set -e

# Config
RAPIDAPI_KEY="${RAPIDAPI_KEY:-YOUR_RAPIDAPI_KEY_HERE}"

# Parse args
NAME=""
COMPANY=""
LINKEDIN=""
CONTEXT=""
LEAD_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      NAME="$2"
      shift 2
      ;;
    --company)
      COMPANY="$2"
      shift 2
      ;;
    --linkedin)
      LINKEDIN="$2"
      shift 2
      ;;
    --context)
      CONTEXT="$2"
      shift 2
      ;;
    --lead)
      LEAD_FILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# If lead file provided, extract details
if [[ -n "$LEAD_FILE" ]]; then
  if [[ "$LEAD_FILE" == "-" ]]; then
    LEAD_DATA=$(cat)
  else
    LEAD_DATA=$(cat "$LEAD_FILE")
  fi
  NAME=$(echo "$LEAD_DATA" | jq -r '.name // empty')
  COMPANY=$(echo "$LEAD_DATA" | jq -r '.company // empty')
  LINKEDIN=$(echo "$LEAD_DATA" | jq -r '.linkedin_url // empty')
  CONTEXT=$(echo "$LEAD_DATA" | jq -r '.engagement_text // .score_reason // empty')
fi

if [[ -z "$NAME" ]]; then
  echo "Error: --name required" >&2
  exit 1
fi

log "Researching: $NAME @ $COMPANY"

# Fetch LinkedIn profile if URL provided
PROFILE_DATA="{}"
if [[ -n "$LINKEDIN" && -n "$RAPIDAPI_KEY" ]]; then
  log "Fetching LinkedIn profile..."
  PROFILE_DATA=$(curl -s -X GET \
    "https://fresh-linkedin-profile-data.p.rapidapi.com/get-linkedin-profile?linkedin_url=$LINKEDIN&include_skills=false" \
    -H "x-rapidapi-key: $RAPIDAPI_KEY" \
    -H "x-rapidapi-host: fresh-linkedin-profile-data.p.rapidapi.com" | jq '.data // {}')
fi

# Generate brief using Node.js
node -e '
const name = process.argv[1];
const company = process.argv[2];
const context = process.argv[3];
const profile = JSON.parse(process.argv[4] || "{}");

const firstName = name.split(" ")[0];
const today = new Date().toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric" });

// Extract profile info
const headline = profile.headline || "";
const about = profile.about || "";
const currentTitle = profile.job_title || headline.split("|")[0]?.trim() || "";
const currentCompany = profile.company || company || "";
const experiences = profile.experiences || [];
const location = profile.location || "";
const followers = profile.follower_count || 0;

// Detect role type
const h = headline.toLowerCase();
const isFounder = h.includes("founder") || h.includes("ceo") || h.includes("owner");
const isAgency = h.includes("agency") || h.includes("consultant");
const isMarketing = h.includes("marketing") || h.includes("growth");

// Generate brief
let brief = `# Pre-Call Brief: ${name}${company ? " @ " + company : ""}
**Date:** ${today}
${context ? `**Context:** ${context}\n` : ""}
---

## TL;DR
`;

// TL;DR based on what we know
if (isFounder) {
  brief += `${currentTitle}${currentCompany ? " at " + currentCompany : ""}. Decision maker with budget authority.\n`;
} else if (isMarketing) {
  brief += `${currentTitle}${currentCompany ? " at " + currentCompany : ""}. Likely evaluating solutions for their team.\n`;
} else {
  brief += `${currentTitle}${currentCompany ? " at " + currentCompany : ""}.\n`;
}

if (context) {
  brief += `Engaged with content about ${extractTopic(context)}.\n`;
}

// About the person
brief += `
## About ${firstName}
`;

if (headline) {
  brief += `- **Current:** ${headline}\n`;
}
if (location) {
  brief += `- **Location:** ${location}\n`;
}
if (followers > 1000) {
  brief += `- **LinkedIn Followers:** ${followers.toLocaleString()} (active presence)\n`;
}
if (experiences.length > 0) {
  const prev = experiences.find(e => e.company !== currentCompany);
  if (prev) {
    brief += `- **Previous:** ${prev.title} at ${prev.company}\n`;
  }
}
if (about) {
  brief += `- **Bio:** ${about.slice(0, 200)}${about.length > 200 ? "..." : ""}\n`;
}

// About the company
if (company) {
  brief += `
## About ${company}
`;
  if (profile.company_industry) {
    brief += `- **Industry:** ${profile.company_industry}\n`;
  }
  if (profile.company_employee_range) {
    brief += `- **Size:** ${profile.company_employee_range} employees\n`;
  }
  if (profile.company_domain) {
    brief += `- **Website:** ${profile.company_domain}\n`;
  }
}

// Pain points based on role
brief += `
## Likely Pain Points
`;

if (isFounder) {
  brief += `1. Wearing too many hats, outbound falling through cracks
2. Hiring sales is expensive, want to validate before committing
3. Need predictable pipeline, not just referrals
`;
} else if (isAgency) {
  brief += `1. Manual prospecting eating into billable hours
2. Client demand for "AI solutions" outpacing capability  
3. Scaling without proportional headcount increase
`;
} else if (isMarketing) {
  brief += `1. Pressure to do more with less
2. Proving ROI on new initiatives
3. Finding time for strategic work vs execution
`;
} else {
  brief += `1. Manual tasks taking too much time
2. Looking for efficiency gains
3. Staying ahead of AI curve
`;
}

// Talking points
brief += `
## Talking Points
1. ${context ? `Reference their engagement: "${context.slice(0, 60)}..."` : "Ask what prompted them to take the call"}
2. "What does your current outbound process look like?"
3. "If this worked perfectly, what would change for ${company || "you"}?"
`;

// Questions
brief += `
## Questions to Ask
1. What prompted you to respond / take this call?
2. What are you currently using for prospecting?
3. What does success look like in the next 90 days?
4. Who else would need to be involved in a decision?
`;

// Objection prep
brief += `
## Objection Prep
| Objection | Response |
|-----------|----------|
| "We already have tools" | "What\x27s the gap between where you are and where you want to be?" |
| "Budget is tight" | "$30/month is less than one hour of your time" |
| "Need to think about it" | "Totally fair. What questions would help you decide?" |
| "Send me more info" | "Happy to. What specifically would be most useful?" |
`;

// Next steps
brief += `
## Recommended Next Step
- **If interested:** Offer to walk through a live demo with their ICP
- **If unsure:** Send case study, schedule follow-up in 1 week
- **If not a fit:** Ask for referral, stay connected on LinkedIn
`;

console.log(brief);

function extractTopic(text) {
  const t = text.toLowerCase();
  if (t.includes("ai")) return "AI";
  if (t.includes("automation")) return "automation";
  if (t.includes("marketing")) return "marketing";
  if (t.includes("outbound")) return "outbound";
  if (t.includes("growth")) return "growth";
  return "their industry";
}
' "$NAME" "$COMPANY" "$CONTEXT" "$PROFILE_DATA"
