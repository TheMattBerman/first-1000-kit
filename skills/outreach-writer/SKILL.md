---
name: outreach-writer
description: Generate personalized cold emails for scored leads. Creates subject lines, opening hooks, and follow-up sequences based on lead context and engagement.
---

# Outreach Writer

Turn scored leads into personalized cold email sequences that convert.

## What It Does

1. Takes scored leads from icp-scorer
2. Analyzes their engagement context + profile
3. Generates personalized subject line, first line, body
4. Creates 3-email sequence (initial + 2 follow-ups)

## Invocation

```bash
# Generate emails for all A/B tier leads
./scripts/write.sh scored.json > emails.json

# Generate for specific tier
TIER_FILTER="A" ./scripts/write.sh scored.json > a_tier_emails.json

# Use custom offer/voice config
OFFER_CONFIG=my-offer.json ./scripts/write.sh scored.json > emails.json
```

## Setup

### Environment Variables
```bash
# Claude API (recommended)
export ANTHROPIC_API_KEY="sk-ant-..."

# OR OpenAI
export OPENAI_API_KEY="sk-..."
```

### Offer Configuration

Create `offer-config.json`:
```json
{
  "product": "First 1000 Kit",
  "one_liner": "AI-powered GTM system that finds, scores, and reaches your first 1000 customers",
  "pain_points": [
    "Spending hours on manual prospecting",
    "Cold outreach that gets ignored",
    "No system for consistent lead gen"
  ],
  "proof_points": [
    "Built the system I used to land our first 50 customers",
    "Runs for ~$30/month after setup"
  ],
  "cta": "Want me to show you how it works?",
  "sender_name": "Matt"
}
```

## Email Framework

### Subject Line Rules
- 3-6 words, lowercase
- Reference their context OR curiosity gap
- NO spam triggers (free, guarantee, limited time)

### First Line Rules  
- Reference something SPECIFIC about them
- Their comment, their company, their content
- NOT "I saw you're the VP of Marketing"
- YES "Your take on [topic] got me thinking..."

### Body Rules
- 2-3 sentences max
- One clear value prop
- Specific to their situation
- No feature dumps

### CTA Rules
- Soft ask, not hard
- NOT "Book a 15-min call"
- YES "Worth a look?" or "Curious if this resonates?"

## Input Format

Expects output from icp-scorer:
```json
{
  "leads": [
    {
      "name": "Lisa Chen",
      "headline": "Founder & CEO at GrowthLabs",
      "company": "GrowthLabs",
      "linkedin_url": "https://linkedin.com/in/lisachen",
      "engagement_text": "We've been seeing similar results...",
      "engagement_type": "comment",
      "icp_score": 80,
      "tier": "A"
    }
  ]
}
```

## Output Format

```json
{
  "meta": {
    "total_emails": 25,
    "tier_a": 8,
    "tier_b": 17,
    "generated_at": "2026-02-14T15:00:00Z"
  },
  "emails": [
    {
      "lead": {
        "name": "Lisa Chen",
        "email": "lisa@growthlabs.com",
        "company": "GrowthLabs",
        "tier": "A"
      },
      "sequence": [
        {
          "step": 1,
          "delay_days": 0,
          "subject": "your take on ai results",
          "body": "Hi Lisa,\n\nYour comment about AI results at agencies caught my eye — especially the point about knowing when to use AI vs human creativity.\n\nWe built a system that handles the repetitive GTM work (prospecting, scoring, outreach) so agency founders can focus on the creative strategy.\n\nWorth a quick look?\n\nBest,\nMatt"
        },
        {
          "step": 2,
          "delay_days": 3,
          "subject": "re: your take on ai results",
          "body": "Hi Lisa,\n\nQuick follow-up — I put together a 2-min walkthrough of how the system works.\n\nMight be useful for GrowthLabs if you're looking to scale without adding headcount.\n\n[Link]\n\nMatt"
        },
        {
          "step": 3,
          "delay_days": 7,
          "subject": "re: your take on ai results",
          "body": "Hi Lisa,\n\nNo worries if the timing isn't right — just wanted to leave the door open.\n\nIf lead gen ever becomes a bottleneck at GrowthLabs, I'm around.\n\nBest,\nMatt"
        }
      ],
      "personalization_notes": "Referenced her comment about AI vs human creativity. Positioned for agency founder context."
    }
  ]
}
```

## Personalization Tiers

### A-Tier (80+ score)
- Deep personalization
- Reference specific comment/content
- Custom value prop for their situation
- Research their company

### B-Tier (60-79 score)
- Moderate personalization
- Reference engagement context
- Industry-specific angle
- Template body with custom first line

### C-Tier (40-59 score)  
- Light personalization
- First name + company
- Generic value prop
- Template sequence

## Voice Guidelines

**Tone:** Smart friend who figured something out, not salesy pitch
**Length:** Short. Every word earns its place.
**No:** "Hope this email finds you well", "I'd love to pick your brain", "synergy"
**Yes:** Direct, specific, human

## Usage in First 1000 Kit

```bash
# Full pipeline
./linkedin-miner/scripts/mine.sh "AI marketing" 20 > raw.json
./lead-enricher/scripts/profile-enrich.sh raw.json | \
  ./lead-enricher/scripts/enrich.sh > enriched.json
./icp-scorer/scripts/score.sh enriched.json > scored.json
./outreach-writer/scripts/write.sh scored.json > emails.json

# Load to Instantly
./instantly-loader/scripts/load.sh emails.json
```

## Templates

### For Agency Owners
```
Subject: quick thought on [topic]

Hi [First],

Your [comment/post] about [specific thing] resonated — [brief insight or agreement].

We built [product] to help [their situation]. [One specific benefit].

Worth exploring?

Best,
[Sender]
```

### For VPs/Directors
```
Subject: [company] + [topic]

Hi [First],

Saw your take on [topic] — [specific reference to their engagement].

[Company] seems like a fit for what we're building: [one-liner value prop].

Curious if this is on your radar?

[Sender]
```

### Follow-up 1 (Day 3)
```
Subject: re: [original subject]

Hi [First],

Quick follow-up — [new angle or asset].

[Short value add]

[Soft CTA]

[Sender]
```

### Follow-up 2 / Break-up (Day 7)
```
Subject: re: [original subject]

Hi [First],

No worries if timing isn't right.

[Leave door open statement]

[Sender]
```
