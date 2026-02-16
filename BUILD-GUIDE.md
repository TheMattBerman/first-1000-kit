# FIRST 1000 KIT — BUILD GUIDE
## APIs, Prompts, Orchestration

**Build Timeline:** Feb 14-20, 2026  
**Launch:** Newsletter Tue Feb 18 | Giveaway Thu Feb 20 9PM | Follow-up Tue Feb 25 AM

---

## TOOL ACCOUNTS NEEDED

### You Already Have:
| Tool | Location | Use For |
|------|----------|---------|
| **Fresh LinkedIn Data API** | RapidAPI | LinkedIn posts, comments, reactions, profiles ⭐ |
| **Hunter.io** | (your account) | Email finding + verification ⭐ |
| **ScrapeCreators** | `/scrape` skill | TikTok, Instagram, X, Meta Ads |
| **Firecrawl** | `/prospect-intel` skill | Website scraping |
| **DataForSEO** | `/prospect-intel` skill | SEO + competitor data |
| **Apify** | `x-scraper` skill | Twitter scraping (optional) |

### Need to Add:
| Tool | Signup | Plan | Est. Cost |
|------|--------|------|-----------|
| Apollo.io | https://app.apollo.io | Free tier (50 credits/mo) | Free (backup enrichment) |
| Instantly.ai | https://instantly.ai | Growth ($30/mo) | $30/mo |

### Already Have:
- **RapidAPI key:** `YOUR_RAPIDAPI_KEY_HERE`
- **Hunter.io:** Already have account (includes email verification)

**Total NEW cost:** ~$30/mo (Instantly only — Hunter handles email + verification)

### RapidAPI Endpoints Used:
| Endpoint | Purpose | Credits |
|----------|---------|---------|
| `POST /search-posts` | Find posts by keyword | 2/call |
| `GET /get-profile-posts` | Get influencer's posts | 2/call |
| `GET /get-post-comments` | Extract commenters | bundled |
| `GET /get-post-reactions` | Extract reactors | bundled |
| `GET /get-linkedin-profile` | Full profile data + email | 1-3/call |
| `GET /get-company-by-domain` | Company enrichment | 1/call |

**Docs:** https://fdocs.info/api-reference

---

---

## INTEGRATION WITH YOUR EXISTING SKILLS

Your current `/scrape` and `/prospect-intel` skills already do a lot. Here's how First 1000 extends them:

| Existing Skill | What It Does | First 1000 Extension |
|----------------|--------------|---------------------|
| `/scrape` | Pulls TikTok, IG, X, Meta ads | **Add LinkedIn post mining** |
| `/prospect-intel` | Full prospect research | **Use for pre-call briefs** |
| `x-scraper` | Twitter scraping via Apify | **LinkedIn uses RapidAPI (separate)** |

**The gap we're filling:** LinkedIn engagement mining → email enrichment → outreach automation

---

## SKILL 1: `linkedin-miner`

### Purpose
Scrape LinkedIn posts in a niche and extract everyone who engaged (liked, commented).

### Fresh LinkedIn Data API (RapidAPI)
**Host:** `fresh-linkedin-profile-data.p.rapidapi.com`  
**Docs:** https://fdocs.info/api-reference  
**Your Key:** `YOUR_RAPIDAPI_KEY_HERE`

### Endpoints Used

**1. Search Posts**
```bash
curl -X POST "https://fresh-linkedin-profile-data.p.rapidapi.com/search-posts" \
  -H "x-rapidapi-key: $RAPIDAPI_KEY" \
  -H "x-rapidapi-host: fresh-linkedin-profile-data.p.rapidapi.com" \
  -H "Content-Type: application/json" \
  -d '{
    "search_keywords": "AI marketing automation",
    "sort_by": "Top match",
    "date_posted": "Past week",
    "page": 1
  }'
```

**2. Get Post Comments**
```bash
curl -X GET "https://fresh-linkedin-profile-data.p.rapidapi.com/get-post-comments?post_url=https://linkedin.com/feed/update/urn:li:activity:123" \
  -H "x-rapidapi-key: $RAPIDAPI_KEY" \
  -H "x-rapidapi-host: fresh-linkedin-profile-data.p.rapidapi.com"
```

**3. Get Post Reactions**
```bash
curl -X GET "https://fresh-linkedin-profile-data.p.rapidapi.com/get-post-reactions?post_url=https://linkedin.com/feed/update/urn:li:activity:123" \
  -H "x-rapidapi-key: $RAPIDAPI_KEY" \
  -H "x-rapidapi-host: fresh-linkedin-profile-data.p.rapidapi.com"
```

### What It Returns

**Comments:**
```json
{
  "data": [
    {
      "commenter": {
        "name": "Jane Doe",
        "headline": "VP Marketing at Acme Corp",
        "linkedin_url": "https://linkedin.com/in/janedoe"
      },
      "text": "Great insights on automation!",
      "created_datetime": "01/15/2026, 9:30:00 AM"
    }
  ]
}
```

**Reactions:**
```json
{
  "data": [
    {
      "reactor": {
        "name": "Bob Wilson",
        "headline": "Head of Growth at TechCo",
        "linkedin_url": "https://linkedin.com/in/bobwilson",
        "urn": "ACoAABOPHB8BM6..."
      },
      "type": "LIKE"
    }
  ]
}
```

### Skill Script (bash)
See `linkedin-miner/scripts/mine.sh` for the full implementation.

### Extraction Prompt (Claude)
```markdown
# LinkedIn Engagement Extractor

Given the raw LinkedIn post data, extract all engagers into a structured lead list.

## Priority Order:
1. **Commenters** (highest intent - they took time to write)
2. **Reactors** (lower intent but still engaged)

## For Each Engager, Extract:
- Full name
- Title/occupation
- LinkedIn profile URL
- Company (if visible)
- Engagement type (comment/like)
- Engagement context (what they said or reacted to)

## Output Format (JSON):
```json
{
  "leads": [
    {
      "name": "Jane Doe",
      "title": "VP Marketing",
      "company": "Acme Corp",
      "linkedin_url": "https://linkedin.com/in/janedoe",
      "engagement_type": "comment",
      "engagement_context": "Their comment: 'Great insights on AI automation!'",
      "post_topic": "AI marketing automation",
      "intent_score": 8
    }
  ]
}
```

## Intent Scoring (1-10):
- 10: Commented with question or detailed response
- 8: Commented with agreement/insight
- 6: Commented with simple reaction ("Great post!")
- 4: Liked/reacted
- 2: Just followed the author
```

---

## SKILL 2: `icp-prospector`

### Purpose
Find companies matching ICP criteria using Perplexity Deep Research.

### Perplexity API
**Endpoint:** `https://api.perplexity.ai/chat/completions`  
**Model:** `sonar` or `sonar-pro`

### Request Format
```bash
curl -X POST "https://api.perplexity.ai/chat/completions" \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sonar-pro",
    "messages": [
      {
        "role": "user",
        "content": "Find 25 DTC e-commerce brands doing $1-10M revenue that use Shopify Plus and Klaviyo. For each, provide: company name, website, estimated revenue, tech stack confirmation, and any recent news about growth or funding."
      }
    ]
  }'
```

### ICP Prospecting Prompt
```markdown
# ICP Company Prospector

## Your Task
Find companies that match the following Ideal Customer Profile:

### ICP Criteria:
- **Industry:** {{industry}}
- **Revenue Range:** {{revenue_range}}
- **Employee Count:** {{employee_range}}
- **Tech Stack:** Must use {{required_tech}}
- **Geography:** {{geography}}
- **Growth Signals:** {{growth_signals}}

### For Each Company, Provide:
1. Company name
2. Website URL
3. Estimated revenue (if available)
4. Employee count
5. Tech stack (confirmed via BuiltWith, job postings, or other sources)
6. Recent growth signals:
   - Recent funding?
   - Hiring aggressively?
   - Launching new products?
   - Founder doing podcast circuit?
7. Key decision maker name + title (if findable)
8. Why they're a good fit (1-2 sentences)

### Output Format:
Return as JSON array:
```json
{
  "companies": [
    {
      "name": "Acme Corp",
      "website": "https://acme.com",
      "estimated_revenue": "$5M ARR",
      "employees": "25-50",
      "tech_stack": ["Shopify Plus", "Klaviyo", "Gorgias"],
      "growth_signals": ["Raised $2M seed in Jan 2026", "Hiring 3 marketers"],
      "decision_maker": {"name": "Jane Smith", "title": "VP Marketing"},
      "fit_reason": "Growing DTC brand in wellness space, actively scaling marketing team"
    }
  ]
}
```

Find {{count}} companies. Prioritize quality over quantity.
```

---

## SKILL 3: `lead-enricher`

### Purpose
Enrich leads with emails, company data, and context.

### Option A: Hunter.io (You Already Have) ⭐ PRIMARY

**Endpoint:** `https://api.hunter.io/v2/`  
**Auth:** `api_key` query param or `Authorization: Bearer YOUR_KEY`

#### Email Finder (Name + Domain → Email)
```bash
curl "https://api.hunter.io/v2/email-finder?domain=acme.com&first_name=Jane&last_name=Doe&api_key=$HUNTER_API_KEY"
```

**Response:**
```json
{
  "data": {
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane.doe@acme.com",
    "score": 91,
    "domain": "acme.com",
    "position": "VP Marketing",
    "linkedin": "https://linkedin.com/in/janedoe",
    "verification": {
      "status": "valid"
    }
  }
}
```

#### Domain Search (Find All Emails at Company)
```bash
curl "https://api.hunter.io/v2/domain-search?domain=acme.com&api_key=$HUNTER_API_KEY"
```

#### Email Verifier
```bash
curl "https://api.hunter.io/v2/email-verifier?email=jane@acme.com&api_key=$HUNTER_API_KEY"
```

**Response:**
```json
{
  "data": {
    "email": "jane@acme.com",
    "status": "valid",
    "score": 91,
    "result": "deliverable"
  }
}
```

### Option B: Apollo.io (Backup / More Data)

**Endpoint:** `POST https://api.apollo.io/api/v1/people/match`

Use when you need MORE data than Hunter provides (company size, funding, tech stack).

#### Single Person Enrichment
```bash
curl -X POST "https://api.apollo.io/api/v1/people/match" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_APOLLO_API_KEY" \
  -d '{
    "first_name": "Jane",
    "last_name": "Doe",
    "organization_name": "Acme Corp",
    "reveal_personal_emails": false,
    "reveal_phone_number": false
  }'
```

#### Bulk Enrichment (up to 10)
```bash
curl -X POST "https://api.apollo.io/api/v1/people/bulk_match" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_APOLLO_API_KEY" \
  -d '{
    "reveal_personal_emails": false,
    "details": [
      {"first_name": "Jane", "last_name": "Doe", "organization_name": "Acme Corp"},
      {"first_name": "John", "last_name": "Smith", "linkedin_url": "https://linkedin.com/in/johnsmith"}
    ]
  }'
```

**What Apollo Returns (More Company Data):**
```json
{
  "person": {
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane@acme.com",
    "email_status": "verified",
    "title": "VP Marketing",
    "linkedin_url": "https://linkedin.com/in/janedoe",
    "organization": {
      "name": "Acme Corp",
      "website_url": "https://acme.com",
      "estimated_num_employees": 50,
      "industry": "E-commerce",
      "founded_year": 2020,
      "technologies": ["Shopify", "Klaviyo", "Gorgias"]
    }
  }
}
```

### Option C: ScrapeCreators (Company Data)

Your `/scrape` skill already has ScrapeCreators configured. Use for LinkedIn company data:

```bash
curl -s "https://api.scrapecreators.com/v1/linkedin/company?url=https://linkedin.com/company/acme-corp" \
  -H "x-api-key: $SCRAPECREATORS_API_KEY"
```

### Recommended Enrichment Flow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Try Hunter.io first (you already have it)            │
│    → Email Finder: name + domain → email                │
│    → Built-in verification included                     │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          │ Email found?          │
          └───────────┬───────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
   ✅ YES                        ❌ NO
   Use Hunter email              │
   (already verified)            │
                                 ▼
                    ┌─────────────────────────────┐
                    │ 2. Fallback to Apollo       │
                    │    → More data sources      │
                    │    → Better for unusual     │
                    │      domains                │
                    └─────────────────────────────┘
```

### Enrichment Script (Hunter + Apollo Fallback)
```bash
#!/bin/bash
# lead-enricher/scripts/enrich.sh

HUNTER_API_KEY="${HUNTER_API_KEY}"
APOLLO_API_KEY="${APOLLO_API_KEY}"
INPUT_FILE="${1:-leads.json}"
OUTPUT_FILE="${2:-enriched.json}"

cat "$INPUT_FILE" | jq -c '.leads[]' | while read lead; do
  FIRST=$(echo $lead | jq -r '.name' | cut -d' ' -f1)
  LAST=$(echo $lead | jq -r '.name' | cut -d' ' -f2-)
  COMPANY=$(echo $lead | jq -r '.company')
  DOMAIN=$(echo $COMPANY | tr '[:upper:]' '[:lower:]' | sed 's/ //g').com
  
  # Try Hunter first
  HUNTER_RESULT=$(curl -s "https://api.hunter.io/v2/email-finder?domain=$DOMAIN&first_name=$FIRST&last_name=$LAST&api_key=$HUNTER_API_KEY")
  EMAIL=$(echo $HUNTER_RESULT | jq -r '.data.email // empty')
  
  if [[ -n "$EMAIL" ]]; then
    echo "✅ Hunter found: $EMAIL"
    echo "$HUNTER_RESULT" >> "$OUTPUT_FILE"
  else
    # Fallback to Apollo
    echo "⚠️ Hunter miss, trying Apollo..."
    APOLLO_RESULT=$(curl -s -X POST "https://api.apollo.io/api/v1/people/match" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $APOLLO_API_KEY" \
      -d "{\"first_name\": \"$FIRST\", \"last_name\": \"$LAST\", \"organization_name\": \"$COMPANY\"}")
    echo "$APOLLO_RESULT" >> "$OUTPUT_FILE"
  fi
  
  sleep 0.3  # Rate limiting
done
```

---

## SKILL 4: `email-verifier`

### Purpose
Verify emails before sending to protect deliverability.

### Option A: Hunter.io Verifier (You Already Have) ⭐

Hunter's Email Finder includes verification, but you can also verify any email:

```bash
curl "https://api.hunter.io/v2/email-verifier?email=jane@acme.com&api_key=$HUNTER_API_KEY"
```

**Response:**
```json
{
  "data": {
    "email": "jane@acme.com",
    "status": "valid",
    "result": "deliverable",
    "score": 91,
    "regexp": true,
    "gibberish": false,
    "disposable": false,
    "webmail": false,
    "mx_records": true,
    "smtp_server": true,
    "smtp_check": true,
    "accept_all": false,
    "block": false
  }
}
```

### Option B: ZeroBounce (Alternative)

If you need higher volume or a second verification source:

**Endpoint:** `GET https://api.zerobounce.net/v2/validate`

```bash
curl "https://api.zerobounce.net/v2/validate?api_key=$ZEROBOUNCE_API_KEY&email=jane@acme.com"
```

### Status Meanings (Both Services)
| Status | Meaning | Action |
|--------|---------|--------|
| `valid` / `deliverable` | Safe to send | ✅ Include |
| `invalid` | Will bounce | ❌ Remove |
| `accept_all` / `catch-all` | May work, risky | ⚠️ Deprioritize |
| `unknown` | Can't verify | ⚠️ Test carefully |
| `disposable` | Temporary email | ❌ Remove |
| `block` / `spamtrap` | Dangerous | ❌ Remove immediately |

### Verification Script (Hunter)
```bash
#!/bin/bash
# email-verifier/scripts/verify.sh

HUNTER_API_KEY="${HUNTER_API_KEY}"
INPUT_FILE="${1:-emails.txt}"
OUTPUT_FILE="${2:-verified.txt}"

while read email; do
  RESULT=$(curl -s "https://api.hunter.io/v2/email-verifier?email=$email&api_key=$HUNTER_API_KEY")
  STATUS=$(echo $RESULT | jq -r '.data.status')
  RESULT_TYPE=$(echo $RESULT | jq -r '.data.result')
  SCORE=$(echo $RESULT | jq -r '.data.score')
  
  if [[ "$STATUS" == "valid" && "$RESULT_TYPE" == "deliverable" ]]; then
    echo "✅ $email (score: $SCORE)" | tee -a "$OUTPUT_FILE"
  elif [[ "$RESULT_TYPE" == "accept_all" ]]; then
    echo "⚠️ $email (accept_all - risky)"
  else
    echo "❌ $email ($STATUS / $RESULT_TYPE)"
  fi
  
  sleep 0.2
done < "$INPUT_FILE"
```

### Note: Hunter Email Finder Already Verifies

When you use Hunter's Email Finder, the returned email includes verification:
```json
{
  "data": {
    "email": "jane@acme.com",
    "score": 91,  // Confidence score
    "verification": {
      "status": "valid"
    }
  }
}
```

So if you're using Hunter for enrichment, you may not need a separate verification step — just check the `score` (aim for 80+).

---

## SKILL 5: `icp-scorer`

### Purpose
Score leads against ICP criteria (0-100).

### Scoring Prompt
```markdown
# ICP Lead Scorer

Score the following lead against our Ideal Customer Profile.

## ICP Criteria:
- **Target Titles:** {{target_titles}}
- **Company Size:** {{company_size}}
- **Industry:** {{industry}}
- **Tech Stack:** {{tech_stack}}
- **Revenue Range:** {{revenue_range}}

## Scoring Rubric:

### Title Match (0-25 points)
- Exact match (e.g., "VP Marketing"): 25
- Close match (e.g., "Director of Marketing"): 20
- Related (e.g., "Marketing Manager"): 15
- Adjacent (e.g., "Head of Growth"): 10
- No match: 0

### Company Size (0-20 points)
- Perfect fit: 20
- Within range: 15
- Slightly outside: 10
- Way off: 0

### Industry Match (0-20 points)
- Exact match: 20
- Adjacent industry: 15
- Related: 10
- Unrelated: 0

### Tech Stack Match (0-15 points)
- Uses all required tech: 15
- Uses most: 10
- Uses some: 5
- Unknown/none: 0

### Growth Signals (0-10 points)
- Multiple strong signals: 10
- Some signals: 7
- Weak signals: 3
- No signals: 0

### Engagement Quality (0-10 points)
- Thoughtful comment: 10
- Simple comment: 7
- Reaction only: 4
- From ICP search (no engagement): 2

## Lead to Score:
```json
{{lead_data}}
```

## Output:
```json
{
  "lead_name": "Jane Doe",
  "total_score": 85,
  "tier": "A",
  "breakdown": {
    "title_match": 25,
    "company_size": 20,
    "industry": 15,
    "tech_stack": 15,
    "growth_signals": 7,
    "engagement": 3
  },
  "notes": "Strong title match, company size perfect, tech stack confirmed via job postings"
}
```

## Tier Assignments:
- **A-tier (80-100):** Prioritize, personalize heavily
- **B-tier (60-79):** Include in sequence, moderate personalization
- **C-tier (40-59):** Include but lower priority
- **D-tier (0-39):** Skip or save for later
```

---

## SKILL 6: `outreach-writer`

### Purpose
Write personalized cold emails that convert.

### Master Outreach Prompt
```markdown
# Cold Outreach Writer

Write a personalized cold email for the following lead.

## Lead Context:
- **Name:** {{name}}
- **Title:** {{title}}
- **Company:** {{company}}
- **Engagement Context:** {{engagement_context}}
- **Post They Engaged With:** {{post_topic}}
- **Their Recent Activity:** {{recent_activity}}
- **Company Situation:** {{company_context}}

## Our Offer:
{{offer_description}}

## Voice/Tone Guidelines:
{{voice_guidelines}}

## Email Framework:

### Subject Line Rules:
- 3-6 words
- Lowercase (feels personal)
- Reference their context OR curiosity gap
- NO spam triggers (free, guarantee, etc.)

### First Line Rules:
- Reference something SPECIFIC about them
- Show you did research
- NOT "I saw you're the VP of Marketing at Acme"
- YES "Your comment on [topic] about [specific point] got me thinking..."

### Body Rules:
- 2-3 short sentences max
- One clear value prop
- Specific to their situation
- No feature dumps

### CTA Rules:
- Soft ask, not hard
- NOT "Book a call" or "15 minutes?"
- YES "Worth exploring?" or "Curious if this resonates?"

## Output Format:
```json
{
  "subject": "quick thought on {{topic}}",
  "body": "Hi {{first_name}},\n\n[First line referencing their context]\n\n[Value prop specific to them]\n\n[Soft CTA]\n\nBest,\n{{sender_name}}",
  "follow_up_1": {
    "delay_days": 3,
    "subject": "re: quick thought on {{topic}}",
    "body": "[Follow-up referencing original + new angle]"
  },
  "follow_up_2": {
    "delay_days": 7,
    "subject": "re: quick thought on {{topic}}",
    "body": "[Break-up email, light, gives them an out]"
  }
}
```

## Example Output:

**Subject:** your take on ai ugc

**Body:**
Hi Jane,

Your comment on Mike's post about AI-generated UGC caught my eye — especially the point about brand consistency being the missing piece.

We've been helping DTC brands like [similar company] solve exactly that — turning one product photo into 20 on-brand UGC videos without the $500/video cost.

Worth a quick look?

Best,
Matt

---

Write 3 versions: (1) Direct, (2) Curiosity-driven, (3) Social proof angle

Pick the best one as primary.
```

---

## SKILL 7: `instantly-loader`

### Purpose
Push leads + sequences to Instantly.ai.

### Instantly API
**Base URL:** `https://api.instantly.ai/api/v1`
**Auth:** API key as query param or header

### Add Leads to Campaign
```bash
curl -X POST "https://api.instantly.ai/api/v1/lead/add" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "YOUR_INSTANTLY_API_KEY",
    "campaign_id": "campaign_abc123",
    "skip_if_in_workspace": true,
    "leads": [
      {
        "email": "jane@acme.com",
        "first_name": "Jane",
        "last_name": "Doe",
        "company_name": "Acme Corp",
        "personalization": "Your comment on AI UGC really resonated",
        "custom_variables": {
          "post_topic": "AI marketing",
          "engagement_type": "comment"
        }
      }
    ]
  }'
```

### Create Campaign (if needed)
```bash
curl -X POST "https://api.instantly.ai/api/v1/campaign/create" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "YOUR_INSTANTLY_API_KEY",
    "name": "First1000 - LinkedIn Engagers - Feb 2026",
    "daily_limit": 50
  }'
```

### Set Sequence
In Instantly UI or via API, create sequence with:
- **Email 1:** Day 0 (initial outreach)
- **Email 2:** Day 3 (follow-up)
- **Email 3:** Day 7 (break-up)

Use `{{personalization}}` variable in templates.

### Loader Script
```bash
#!/bin/bash
# instantly-loader/scripts/load.sh

INSTANTLY_API_KEY="${INSTANTLY_API_KEY:-$1}"
CAMPAIGN_ID="${2}"
LEADS_FILE="${3:-leads.json}"

# Format leads for Instantly
LEADS=$(cat "$LEADS_FILE" | jq '[.[] | {
  email: .email,
  first_name: .first_name,
  last_name: .last_name,
  company_name: .company,
  personalization: .personalized_first_line,
  custom_variables: {
    post_topic: .post_topic,
    engagement_type: .engagement_type
  }
}]')

# Upload to Instantly
curl -X POST "https://api.instantly.ai/api/v1/lead/add" \
  -H "Content-Type: application/json" \
  -d "{
    \"api_key\": \"$INSTANTLY_API_KEY\",
    \"campaign_id\": \"$CAMPAIGN_ID\",
    \"skip_if_in_workspace\": true,
    \"leads\": $LEADS
  }"
```

---

## SKILL 8: `pre-call-research`

### Purpose
Deep research before any booked meeting.

### Pre-Call Research Prompt
```markdown
# Pre-Call Research Brief

Generate a comprehensive research brief for an upcoming meeting.

## Meeting Context:
- **Prospect Name:** {{name}}
- **Title:** {{title}}
- **Company:** {{company}}
- **How They Came In:** {{source}} (e.g., "replied to cold email about AI UGC")
- **Meeting Time:** {{meeting_time}}

## Research to Conduct:

### Person Research:
1. Career history (current + past 2-3 roles)
2. Recent LinkedIn posts/activity (last 30 days)
3. Any podcast appearances or interviews
4. Their public takes on relevant topics
5. Mutual connections or shared experiences
6. Communication style indicators

### Company Research:
1. What they do (1-2 sentence summary)
2. Recent news (funding, launches, hires)
3. Competitive landscape
4. Current tech stack
5. Likely pain points based on their situation
6. Recent job postings (what are they building?)

### Meeting Prep:
1. 3 talking points based on their context
2. Questions to ask them
3. Likely objections + responses
4. How our solution fits their specific situation
5. Next steps to propose

## Output Format:

# Pre-Call Brief: {{name}} @ {{company}}
**Meeting:** {{meeting_time}}

## TL;DR
[2-3 sentences on who they are and why they're talking to you]

## About {{name}}
[Career history, recent activity, communication style]

## About {{company}}
[What they do, recent news, current situation]

## Their Likely Pain Points
1. [Pain point + evidence]
2. [Pain point + evidence]
3. [Pain point + evidence]

## Talking Points
1. [Point referencing their context]
2. [Point about your solution]
3. [Point about next steps]

## Questions to Ask
1. [Question about their current situation]
2. [Question about their goals]
3. [Question to qualify]

## Objection Prep
| Objection | Response |
|-----------|----------|
| [Common objection] | [Your response] |
| [Common objection] | [Your response] |

## Recommended Next Step
[What to propose at end of call]

---

Deliver this brief 30 minutes before the meeting.
```

---

## ORCHESTRATION FLOW

### Daily Automation (n8n or OpenClaw)

```
┌────────────────────────────────────────────────────────────┐
│ TRIGGER: Daily at 6 AM                                      │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  1. MINE LINKEDIN                                           │
│     └─ Run linkedin-miner with today's keywords             │
│     └─ Output: raw_leads.json (50-100 engagers)             │
│                                                              │
│  2. PROSPECTOR (parallel)                                   │
│     └─ Run icp-prospector for new companies                 │
│     └─ Output: companies.json (25 companies)                │
│                                                              │
│  3. ENRICH                                                  │
│     └─ Run lead-enricher on all leads                       │
│     └─ Output: enriched_leads.json                          │
│                                                              │
│  4. VERIFY                                                  │
│     └─ Run email-verifier on all emails                     │
│     └─ Output: verified_leads.json (remove invalids)        │
│                                                              │
│  5. SCORE                                                   │
│     └─ Run icp-scorer on verified leads                     │
│     └─ Output: scored_leads.json (with tiers)               │
│                                                              │
│  6. WRITE                                                   │
│     └─ Run outreach-writer on A/B tier leads                │
│     └─ Output: emails.json (personalized sequences)         │
│                                                              │
│  7. LOAD                                                    │
│     └─ Run instantly-loader to push to campaign             │
│     └─ Output: confirmation of loaded leads                 │
│                                                              │
│  8. REPORT                                                  │
│     └─ Send summary to Slack/email                          │
│     └─ "50 leads enriched, 35 verified, 20 A-tier loaded"   │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

### Meeting Trigger

```
┌────────────────────────────────────────────────────────────┐
│ TRIGGER: Meeting booked (Cal.com webhook or manual)         │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Extract meeting details (name, company, time)           │
│                                                              │
│  2. Run pre-call-research                                   │
│                                                              │
│  3. Generate brief                                          │
│                                                              │
│  4. Deliver to Slack/Notion 30 min before                   │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

---

## ENV VARIABLES NEEDED

```bash
# .env file for the kit

# You Already Have
RAPIDAPI_KEY=YOUR_RAPIDAPI_KEY_HERE  # LinkedIn mining + profile enrichment
HUNTER_API_KEY=xxxxx              # Email finding + verification
SCRAPECREATORS_API_KEY=xxxxx      # From your /scrape skill
PERPLEXITY_API_KEY=pplx-xxxxx

# Need to Add
APOLLO_API_KEY=xxxxx              # Backup enrichment (free tier)
INSTANTLY_API_KEY=xxxxx           # Email sending

# Optional
APIFY_TOKEN=YOUR_APIFY_TOKEN_HERE  # Backup for Twitter
ANTHROPIC_API_KEY=sk-ant-xxxxx    # For prompts (or use OpenClaw)
```

---

## BUILD PRIORITY ORDER

| Day | Task | Tools | Deliverable |
|-----|------|-------|-------------|
| **Day 1 (Sat)** | linkedin-miner | RapidAPI | Can scrape LinkedIn engagers ✅ |
| **Day 2 (Sun)** | lead-enricher | RapidAPI + Hunter + Apollo | Can get profiles + emails ✅ |
| **Day 3 (Mon)** | icp-scorer + outreach-writer | Prompts | Can score + write |
| **Day 4 (Tue)** | instantly-loader | Instantly API | Can send sequences |
| **Day 5 (Wed)** | pre-call-research + orchestration | Perplexity | Full flow |
| **Day 6 (Thu)** | Testing + package | All | Ready for giveaway |

### Simplified Stack:
```
RapidAPI (LinkedIn posts + profiles) → Hunter.io (work emails) → Instantly (send)
              ↓                               ↓
    Profile data + LinkedIn email      Apollo (backup)
```

### Why RapidAPI > Apify for LinkedIn:
- ✅ You already have it
- ✅ Direct endpoints for comments + reactions (no actor polling)
- ✅ Profile enrichment built-in (get email directly from LinkedIn)
- ✅ Faster (synchronous API calls vs async actor runs)

---

## TESTING CHECKLIST

- [ ] linkedin-miner returns structured leads
- [ ] lead-enricher finds emails for 60%+ of leads
- [ ] email-verifier correctly flags bad emails
- [ ] icp-scorer produces sensible scores
- [ ] outreach-writer generates personalized emails
- [ ] instantly-loader successfully adds leads
- [ ] pre-call-research generates useful briefs
- [ ] Full flow runs without manual intervention
- [ ] Daily summary delivers

---

*Ready to build. Let's ship this thing.*
