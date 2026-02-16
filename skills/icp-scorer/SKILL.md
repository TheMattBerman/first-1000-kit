---
name: icp-scorer
description: Score leads against your Ideal Customer Profile. Analyzes title, company, industry fit and assigns A/B/C/D tiers for prioritization.
---

# ICP Scorer

Score leads against your Ideal Customer Profile to prioritize outreach.

## What It Does

1. Takes enriched leads from lead-enricher
2. Analyzes each lead's title, company, industry
3. Scores against configurable ICP criteria
4. Assigns tiers: A (80+), B (60-79), C (40-59), D (<40)

## Invocation

```bash
# Score leads with default ICP
./scripts/score.sh leads.json > scored.json

# Score with custom ICP config
ICP_CONFIG=my-icp.json ./scripts/score.sh leads.json > scored.json

# Filter to A/B tier only
./scripts/score.sh leads.json | jq '.leads | map(select(.tier == "A" or .tier == "B"))'
```

## Setup

### Environment Variables
```bash
# For AI-powered scoring (optional but recommended)
export ANTHROPIC_API_KEY="sk-ant-..."
# OR
export OPENAI_API_KEY="sk-..."
```

### ICP Configuration

Create `icp-config.json`:
```json
{
  "target_titles": [
    "VP Marketing",
    "Head of Marketing", 
    "CMO",
    "Director of Marketing",
    "Head of Growth",
    "Founder",
    "CEO",
    "Agency Owner"
  ],
  "target_industries": [
    "SaaS",
    "E-commerce",
    "DTC",
    "Marketing Agency",
    "Technology"
  ],
  "company_size": {
    "min": 10,
    "max": 500,
    "ideal": "50-200"
  },
  "keywords": [
    "AI", "automation", "marketing", "growth", "scale"
  ],
  "exclude_titles": [
    "Student",
    "Intern",
    "Looking for",
    "Open to work"
  ]
}
```

## Scoring Rubric

| Category | Points | Criteria |
|----------|--------|----------|
| **Title Match** | 0-25 | Exact match = 25, Close = 20, Related = 15, Adjacent = 10 |
| **Company Size** | 0-20 | Perfect fit = 20, In range = 15, Close = 10 |
| **Industry** | 0-20 | Exact match = 20, Adjacent = 15, Related = 10 |
| **Keywords** | 0-15 | Multiple matches = 15, Some = 10, Few = 5 |
| **Engagement** | 0-10 | From intent_score (comment > reaction) |
| **Signals** | 0-10 | Hiring, funding, growth mentions |

**Total: 100 points**

## Tier Assignment

| Tier | Score | Action |
|------|-------|--------|
| **A** | 80-100 | Priority outreach, heavy personalization |
| **B** | 60-79 | Include in sequence, moderate personalization |
| **C** | 40-59 | Lower priority, template outreach |
| **D** | 0-39 | Skip or save for later |

## Input Format

Expects output from lead-enricher:
```json
{
  "leads": [
    {
      "name": "Jane Doe",
      "headline": "VP Marketing at Acme Corp | AI Enthusiast",
      "company": "Acme Corp",
      "company_size": "51-200",
      "company_industry": "SaaS",
      "linkedin_url": "https://linkedin.com/in/janedoe",
      "intent_score": 10,
      "engagement_text": "Great insights on AI automation!"
    }
  ]
}
```

## Output Format

```json
{
  "meta": {
    "total_leads": 50,
    "tier_a": 8,
    "tier_b": 15,
    "tier_c": 12,
    "tier_d": 15,
    "scored_at": "2026-02-14T15:00:00Z"
  },
  "leads": [
    {
      "name": "Jane Doe",
      "headline": "VP Marketing at Acme Corp | AI Enthusiast",
      "company": "Acme Corp",
      "linkedin_url": "https://linkedin.com/in/janedoe",
      "icp_score": 85,
      "tier": "A",
      "score_breakdown": {
        "title_match": 25,
        "company_size": 20,
        "industry": 20,
        "keywords": 10,
        "engagement": 10,
        "signals": 0
      },
      "score_reason": "Exact title match (VP Marketing), ideal company size, SaaS industry, AI keywords in headline"
    }
  ]
}
```

## Scoring Modes

### Mode 1: Rule-Based (Fast, Free)
Uses keyword matching and rules. Good for high volume.

```bash
SCORING_MODE=rules ./scripts/score.sh leads.json
```

### Mode 2: AI-Powered (Better, Costs Tokens)
Uses Claude/GPT to analyze fit. Better for nuanced scoring.

```bash
SCORING_MODE=ai ./scripts/score.sh leads.json
```

## Usage in First 1000 Kit

```bash
# Full pipeline
./linkedin-miner/scripts/mine.sh "AI marketing" 20 > raw.json
./lead-enricher/scripts/profile-enrich.sh raw.json | \
  ./lead-enricher/scripts/enrich.sh > enriched.json
./icp-scorer/scripts/score.sh enriched.json > scored.json

# Get A-tier leads only
cat scored.json | jq '.leads | map(select(.tier == "A"))'
```

## Example ICP Configs

### For Agency Services
```json
{
  "target_titles": ["Founder", "CEO", "Agency Owner", "Managing Director"],
  "target_industries": ["Marketing Agency", "Creative Agency", "Digital Agency"],
  "company_size": {"min": 5, "max": 50}
}
```

### For SaaS Product
```json
{
  "target_titles": ["VP Marketing", "Head of Growth", "CMO", "Director Marketing"],
  "target_industries": ["SaaS", "Technology", "Software"],
  "company_size": {"min": 50, "max": 500}
}
```

### For E-commerce/DTC
```json
{
  "target_titles": ["Founder", "CEO", "Head of Marketing", "E-commerce Manager"],
  "target_industries": ["E-commerce", "DTC", "Retail", "Consumer Goods"],
  "company_size": {"min": 10, "max": 200}
}
```
