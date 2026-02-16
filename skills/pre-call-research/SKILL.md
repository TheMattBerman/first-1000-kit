---
name: pre-call-research
description: Generate comprehensive research briefs before sales calls. Pulls company info, recent news, prospect background, and suggests talking points.
---

# Pre-Call Research

Deep research brief before any booked meeting. Know more about them than they expect.

## What It Does

1. Takes meeting details (name, company, how they came in)
2. Researches the person and company
3. Generates talking points, questions, objection prep
4. Delivers brief before the call

## Invocation

```bash
# Generate brief
./scripts/research.sh --name "Lisa Chen" --company "GrowthLabs" --context "replied to cold email about AI"

# From lead data
./scripts/research.sh --lead lead.json

# Output to file
./scripts/research.sh --name "Lisa Chen" --company "GrowthLabs" > brief.md
```

## Setup

### Environment Variables
```bash
# For AI-powered research (recommended)
export ANTHROPIC_API_KEY="sk-ant-..."
# OR
export OPENAI_API_KEY="sk-..."

# Optional: Enhanced search
export PERPLEXITY_API_KEY="pplx-..."
```

## Output Format

```markdown
# Pre-Call Brief: Lisa Chen @ GrowthLabs
**Meeting:** Friday 2pm CST
**Source:** Replied to cold email about AI outbound

## TL;DR
Founder/CEO of marketing automation agency. Interested in AI for client work.
Likely evaluating tools. Decision maker with budget authority.

## About Lisa Chen
- Founder & CEO at GrowthLabs (2019-present)
- Previous: Marketing Director at TechCorp (2015-2019)
- Active on LinkedIn, posts about AI and agency growth
- Communication style: Direct, data-driven

## About GrowthLabs
- Marketing automation agency, ~15 employees
- Focus: B2B SaaS clients
- Tech stack: HubSpot, Zapier, likely evaluating AI tools
- Recent: Hiring for "AI Strategist" role (growth signal)

## Likely Pain Points
1. Manual prospecting eating into billable hours
2. Client demand for "AI solutions" outpacing capability
3. Scaling without proportional headcount increase

## Talking Points
1. "You mentioned AI vs human creativity in your comment..."
2. "GrowthLabs seems to be growing fast. How are you handling lead gen for clients?"
3. "What's your current outbound stack look like?"

## Questions to Ask
1. What prompted you to respond to the email?
2. Are you looking for internal use or client delivery?
3. What's your timeline for implementing something?

## Objection Prep
| Objection | Response |
|-----------|----------|
| "We already have tools" | "What's the gap between where you are and where you want to be?" |
| "Budget is tight" | "$30/month is less than one hour of agency time" |
| "Need to see ROI first" | "Happy to show you our results. 50 customers from this system." |

## Recommended Next Step
If interested: Offer 2-week pilot with their ICP
If unsure: Send case study, follow up in 1 week
```

## Integration with Calendar

Set up a trigger (n8n, Zapier, or cron job) to:
1. Detect new meeting booked (Cal.com webhook)
2. Extract attendee info
3. Run pre-call-research
4. Deliver brief to Slack/email 30 min before

## Research Sources

| Source | What It Provides |
|--------|------------------|
| LinkedIn (RapidAPI) | Title, company, experience, posts |
| Company website | About, team, recent news |
| Crunchbase | Funding, size, investors |
| Job postings | Growth signals, tech stack |
| Google News | Recent mentions, PR |

## Usage

```bash
# Before a call
./scripts/research.sh \
  --name "Lisa Chen" \
  --company "GrowthLabs" \
  --linkedin "https://linkedin.com/in/lisachen" \
  --context "Replied to cold email about AI outbound"

# From pipeline data
cat verified.json | jq '.emails[0].lead' | ./scripts/research.sh --lead -
```

## Best Practices

1. **Do the research** - 10 minutes of prep beats 30 minutes of fumbling
2. **Find the hook** - What specific thing can you reference?
3. **Know their pain** - What problem made them respond?
4. **Have a next step** - Don't end the call without one
5. **Take notes** - Update CRM immediately after
