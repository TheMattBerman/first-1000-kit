#!/bin/bash
# icp-scorer/scripts/score.sh
# Score leads against ICP criteria

set -e

# Config
SCORING_MODE="${SCORING_MODE:-rules}"  # rules or ai

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

# Score using Node.js for complex logic
node -e '
const inputData = JSON.parse(process.argv[1]);

// Default ICP config
const icp = {
  target_titles: [
    "VP Marketing", "Head of Marketing", "CMO", "Chief Marketing Officer",
    "Director of Marketing", "Marketing Director", "Head of Growth",
    "Growth Lead", "Founder", "Co-founder", "CEO", "Owner",
    "Agency Owner", "Managing Director", "Head of Digital"
  ],
  related_titles: [
    "Marketing Manager", "Growth Manager", "Digital Marketing",
    "Brand Manager", "Demand Gen", "Performance Marketing"
  ],
  target_industries: [
    "SaaS", "Software", "Technology", "E-commerce", "DTC",
    "Marketing", "Agency", "Advertising", "Digital", "AI"
  ],
  keywords_positive: [
    "AI", "automation", "marketing", "growth", "scale", "agency",
    "founder", "startup", "SaaS", "DTC", "e-commerce", "brand"
  ],
  keywords_negative: [
    "student", "intern", "looking for", "open to work", "seeking",
    "fresher", "entry level", "junior", "unemployed"
  ]
};

const leads = inputData.leads || inputData;

function scoreTitle(headline) {
  if (!headline) return { score: 0, reason: "No headline" };
  
  const h = headline.toLowerCase();
  
  // Check for negative keywords first
  for (const neg of icp.keywords_negative) {
    if (h.includes(neg.toLowerCase())) {
      return { score: 0, reason: "Excluded: " + neg, excluded: true };
    }
  }
  
  // Exact title match
  for (const t of icp.target_titles) {
    if (h.includes(t.toLowerCase())) {
      return { score: 25, reason: "Exact match: " + t };
    }
  }
  
  // Related title match
  for (const t of icp.related_titles) {
    if (h.includes(t.toLowerCase())) {
      return { score: 15, reason: "Related: " + t };
    }
  }
  
  // Founder/CEO signals
  if (h.includes("founder") || h.includes("ceo") || h.includes("owner")) {
    return { score: 20, reason: "Decision maker (founder/CEO)" };
  }
  
  // Seniority + marketing
  const senior = ["head", "director", "vp", "chief", "lead", "senior"].some(w => h.includes(w));
  const mktg = ["marketing", "growth", "brand", "digital", "demand"].some(w => h.includes(w));
  
  if (senior && mktg) return { score: 12, reason: "Seniority + marketing signals" };
  if (mktg) return { score: 8, reason: "Marketing-related role" };
  
  return { score: 3, reason: "No clear title match" };
}

function scoreIndustry(headline, company, industry) {
  const text = [headline, company, industry].filter(Boolean).join(" ").toLowerCase();
  
  for (const ind of icp.target_industries) {
    if (text.includes(ind.toLowerCase())) {
      return { score: 20, reason: "Industry: " + ind };
    }
  }
  
  const tech = ["tech", "digital", "software", "app", "platform", "ai", "automation"];
  if (tech.some(s => text.includes(s))) {
    return { score: 12, reason: "Tech-adjacent industry" };
  }
  
  return { score: 5, reason: "Unknown industry" };
}

function scoreCompanySize(sizeStr) {
  if (!sizeStr) return { score: 10, reason: "Size unknown" };
  const s = sizeStr.toLowerCase();
  
  if (s.includes("51-200") || s.includes("50-200")) return { score: 20, reason: "Ideal size (51-200)" };
  if (s.includes("11-50") || s.includes("10-50")) return { score: 18, reason: "Growing (11-50)" };
  if (s.includes("201-500")) return { score: 15, reason: "Mid-size (201-500)" };
  if (s.includes("1-10") || s.includes("self")) return { score: 12, reason: "Small (1-10)" };
  if (s.includes("501") || s.includes("1000")) return { score: 8, reason: "Enterprise (500+)" };
  
  return { score: 10, reason: "Size unclear" };
}

function scoreKeywords(headline, text) {
  const combined = [headline, text].filter(Boolean).join(" ").toLowerCase();
  const matched = icp.keywords_positive.filter(kw => combined.includes(kw.toLowerCase()));
  
  if (matched.length >= 4) return { score: 15, reason: "Keywords: " + matched.slice(0,3).join(", ") };
  if (matched.length >= 2) return { score: 10, reason: "Keywords: " + matched.join(", ") };
  if (matched.length >= 1) return { score: 5, reason: "Keyword: " + matched[0] };
  
  return { score: 0, reason: "No keywords" };
}

function scoreEngagement(intentScore, type) {
  const score = Math.min(10, intentScore || 4);
  const reason = type === "comment" ? "Commented (high intent)" : "Reacted";
  return { score, reason };
}

function getTier(score) {
  if (score >= 80) return "A";
  if (score >= 60) return "B";
  if (score >= 40) return "C";
  return "D";
}

// Score all leads
const scoredLeads = [];
const tiers = { A: 0, B: 0, C: 0, D: 0 };

for (const lead of leads) {
  const title = scoreTitle(lead.headline);
  if (title.excluded) continue;
  
  const industry = scoreIndustry(lead.headline, lead.company, lead.company_industry);
  const size = scoreCompanySize(lead.company_size);
  const keywords = scoreKeywords(lead.headline, lead.engagement_text);
  const engagement = scoreEngagement(lead.intent_score, lead.engagement_type);
  
  const total = title.score + industry.score + size.score + keywords.score + engagement.score;
  const tier = getTier(total);
  tiers[tier]++;
  
  scoredLeads.push({
    ...lead,
    icp_score: total,
    tier: tier,
    score_breakdown: {
      title_match: title.score,
      industry: industry.score,
      company_size: size.score,
      keywords: keywords.score,
      engagement: engagement.score
    },
    score_reason: [title.reason, industry.reason, keywords.reason]
      .filter(r => r && !r.includes("No ") && !r.includes("Unknown"))
      .join("; ") || "Low fit"
  });
}

scoredLeads.sort((a, b) => b.icp_score - a.icp_score);

console.log(JSON.stringify({
  meta: {
    total_leads: scoredLeads.length,
    tier_a: tiers.A,
    tier_b: tiers.B,
    tier_c: tiers.C,
    tier_d: tiers.D,
    scored_at: new Date().toISOString()
  },
  leads: scoredLeads
}, null, 2));
' "$INPUT_DATA"
