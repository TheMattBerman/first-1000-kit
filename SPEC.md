# THE FIRST 1000 CUSTOMERS KIT
## OpenClaw GTM System — Full Spec

**Created:** Feb 14, 2026  
**Status:** Spec Complete → Ready to Build  
**Owner:** @themattberman

---

## OVERVIEW

An OpenClaw-powered GTM system that replaces a $150K GTM engineer hire with ~$200/month in tools.

**The Promise:**  
Input your ICP + niche → Output booked meetings with warm leads

**Target Users:**
- Bootstrapped SaaS founders
- Solo founders launching products
- Small teams without GTM budget
- Agency owners doing outbound

---

## SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                      FIRST 1000 KIT                             │
│                                                                  │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │
│  │   SOURCE    │   │   SOURCE    │   │   SOURCE    │           │
│  │   LinkedIn  │   │   ICP       │   │  Competitor │           │
│  │   Mining    │   │   Search    │   │   Audience  │           │
│  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘           │
│         │                 │                 │                   │
│         └────────────┬────┴────────────────┘                   │
│                      ▼                                          │
│         ┌─────────────────────────┐                            │
│         │      ENRICHMENT         │                            │
│         │  Apollo + ZeroBounce    │                            │
│         │  + Company Intel        │                            │
│         └───────────┬─────────────┘                            │
│                     ▼                                           │
│         ┌─────────────────────────┐                            │
│         │     ICP SCORING         │                            │
│         │  Title + Company +      │                            │
│         │  Signals = 0-100        │                            │
│         └───────────┬─────────────┘                            │
│                     ▼                                           │
│         ┌─────────────────────────┐                            │
│         │   PERSONALIZATION       │                            │
│         │  Research + Write       │                            │
│         │  Custom First Lines     │                            │
│         └───────────┬─────────────┘                            │
│                     ▼                                           │
│         ┌─────────────────────────┐                            │
│         │      OUTREACH           │                            │
│         │   Instantly.ai          │                            │
│         │   Sequences             │                            │
│         └───────────┬─────────────┘                            │
│                     ▼                                           │
│         ┌─────────────────────────┐                            │
│         │    PRE-CALL PREP        │                            │
│         │   Deep Research         │                            │
│         │   Before Meetings       │                            │
│         └─────────────────────────┘                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## THE 7 SKILLS

### Skill 1: `linkedin-miner`
**Purpose:** Find warm leads by mining engagement on niche content

**Inputs:**
- Niche keywords/topics
- Influencer handles to monitor
- Competitor company pages

**Process:**
1. Use RapidAPI (Fresh LinkedIn Data) to pull recent posts on topic
2. Extract all engagers (likers + commenters)
3. Prioritize commenters (higher intent)
4. Capture the context (what post they engaged with, what they said)

**Outputs:**
- Raw lead list with LinkedIn URLs
- Engagement context for personalization
- Engagement type (like/comment/share)

**API/Tools:**
- RapidAPI (Fresh LinkedIn Data API) — sync, fast, profile enrichment built-in
- Note: Use `urn=` parameter (not `post_url=`) for comments/reactions

**Sample Command:**
```
"find everyone who engaged with AI marketing posts this week"
```

---

### Skill 2: `icp-prospector`
**Purpose:** Find companies matching ICP criteria

**Inputs:**
- Industry/vertical
- Company size range
- Tech stack requirements
- Funding stage
- Geography
- Growth signals to look for

**Process:**
1. Use Perplexity Deep Research to find matching companies
2. Check for growth signals (hiring, funding, tech changes)
3. Validate against criteria
4. Output ranked list

**Outputs:**
- Company list with basic info
- Growth signal indicators
- Confidence score

**API/Tools:**
- Perplexity API
- Could enrich with: Crunchbase, BuiltWith

**Sample Command:**
```
"find 50 DTC brands doing $1-10M revenue using Klaviyo and Shopify Plus"
```

---

### Skill 3: `lead-enricher`
**Purpose:** Turn raw leads into actionable contacts

**Inputs:**
- LinkedIn URLs or company names
- Target titles (CEO, CMO, Head of Growth, etc.)

**Process:**
1. Find decision maker at company
2. Pull email via Apollo/Hunter
3. Get LinkedIn profile data
4. Pull recent posts/activity
5. Get company context (size, funding, tech stack)

**Outputs:**
- Full contact record:
  - Name, title, email (verified)
  - LinkedIn URL
  - Company name, size, industry
  - Recent activity/posts
  - Tech stack
  - Funding info

**API/Tools:**
- Hunter.io (primary)
- Apollo.io (backup)
- RapidAPI (LinkedIn profile enrichment)
- BuiltWith (tech stack, optional)

**Sample Command:**
```
"enrich these 50 leads, find the Head of Marketing or CMO"
```

---

### Skill 4: `email-verifier`
**Purpose:** Clean the list before sending

**Inputs:**
- List of email addresses

**Process:**
1. Run through ZeroBounce API
2. Check validity, deliverability, spam risk
3. Remove bad emails
4. Flag risky ones

**Outputs:**
- Cleaned email list
- Verification status for each
- Bounce risk score

**API/Tools:**
- ZeroBounce API
- Alternatives: NeverBounce, MillionVerifier

**Sample Command:**
```
"verify all emails in today's lead batch"
```

---

### Skill 5: `icp-scorer`
**Purpose:** Rank leads by fit

**Inputs:**
- Enriched lead data
- ICP criteria weights

**Process:**
1. Score each lead against ICP criteria:
   - Title match (0-25 pts)
   - Company size match (0-20 pts)
   - Industry match (0-20 pts)
   - Tech stack match (0-15 pts)
   - Growth signals (0-10 pts)
   - Engagement quality (0-10 pts)
2. Calculate total ICP score (0-100)
3. Rank and tier (A/B/C leads)

**Outputs:**
- Scored lead list
- Tier assignments
- Priority order for outreach

**Sample Command:**
```
"score today's leads against our SaaS founder ICP"
```

---

### Skill 6: `outreach-writer`
**Purpose:** Write personalized cold emails that convert

**Inputs:**
- Enriched lead data
- Engagement context (if from LinkedIn mining)
- Your offer/value prop
- Your voice/tone guidelines

**Process:**
1. Research the prospect (quick Perplexity dive)
2. Find the angle:
   - If from LinkedIn: reference the post they engaged with
   - If from ICP search: reference company situation
3. Write personalized first line
4. Write full email in your voice
5. Generate follow-up sequence (3 emails)

**Outputs:**
- Email 1 (initial outreach)
- Email 2 (follow-up, 3 days)
- Email 3 (break-up, 7 days)
- All personalized per lead

**Sample Command:**
```
"write outreach for today's A-tier leads"
```

**Email Framework:**
```
Subject: [Personalized based on context]

[Personalized first line - reference their post/company/situation]

[1-2 sentences on the problem you solve]

[Soft CTA - not "book a call", more "worth a conversation?"]

[Signature]
```

---

### Skill 7: `instantly-loader`
**Purpose:** Push sequences to Instantly.ai

**Inputs:**
- Leads with emails
- Written email sequences

**Process:**
1. Format leads for Instantly CSV/API
2. Create campaign if needed
3. Upload leads to campaign
4. Set sequence timing
5. Activate

**Outputs:**
- Confirmation of loaded leads
- Campaign status
- Send schedule

**API/Tools:**
- Instantly.ai API
- Alternative: Smartlead, Lemlist

**Sample Command:**
```
"load today's leads into Instantly and start the sequence"
```

---

### Skill 8: `pre-call-research`
**Purpose:** Deep prep before any booked meeting

**Inputs:**
- Prospect name + company
- Meeting context (how they came in)

**Process:**
1. Deep Research via Perplexity:
   - Person's background, career history
   - Recent posts, interviews, podcasts
   - Company situation (funding, growth, challenges)
   - Competitive landscape
2. Generate talking points
3. Prepare objection responses
4. Identify mutual connections/interests

**Outputs:**
- 1-page briefing doc
- Key talking points
- Potential objections + responses
- Suggested questions to ask
- Delivered 30 min before call

**Sample Command:**
```
"prep me for my 2pm call with [Name] from [Company]"
```

---

## TOOL STACK

| Tool | Purpose | Cost | Required? |
|------|---------|------|-----------|
| **OpenClaw** | Orchestration | — | ✅ Yes |
| **RapidAPI** | LinkedIn scraping | ~$30-50/mo | ✅ Yes |
| **Hunter.io** | Email finding | Free-$50/mo | ✅ Yes |
| **Apollo.io** | Backup enrichment | Free | Optional |
| **Instantly.ai** | Email sending | $30/mo | ✅ Yes |
| **Perplexity** | Pre-call research | $20/mo | Optional |
| **TweetClaw** | X/Twitter tweet search, reply search, follower export, monitors | Account dependent | Optional |
| **Apify** | Raw Twitter/X scraping | ~$30/mo | Optional |

**Total Monthly Cost:** ~$60-130  
**vs GTM Engineer:** $150,000/year ($12,500/month)

---

## BUILD PLAN

### Phase 1: Core Skills (Week 1)
- [ ] `lead-enricher` — Apollo API integration
- [ ] `email-verifier` — ZeroBounce integration
- [ ] `outreach-writer` — Prompt engineering + voice training

**Milestone:** Can enrich a lead list and write personalized emails

### Phase 2: Prospecting (Week 2)
- [ ] `icp-prospector` — Perplexity integration
- [ ] `linkedin-miner` — RapidAPI LinkedIn scraper
- [ ] `icp-scorer` — Scoring logic

**Milestone:** Can generate and score leads from multiple sources

### Phase 3: Automation (Week 3)
- [ ] `instantly-loader` — Instantly API integration
- [ ] `pre-call-research` — Deep research skill
- [ ] n8n workflows for daily automation

**Milestone:** Full end-to-end system running

### Phase 4: Polish (Week 4)
- [ ] SOUL.md template (GTM voice)
- [ ] Documentation
- [ ] Video walkthrough
- [ ] Package for giveaway

**Milestone:** Ready to ship

---

## GIVEAWAY STRATEGY

### Main Giveaway Post
```
I built the system that gets your SaaS its first 1000 customers 🤯

No GTM engineer. No agency. Just OpenClaw + this kit.

the flow:

1. Mine LinkedIn engagement
   → people who engage with niche content = warm
   
2. Enrich + verify
   → Apollo + ZeroBounce
   
3. Score against ICP  
   → title, company, signals = ranked list
   
4. Write personalized outreach
   → based on what they engaged with
   
5. Send via Instantly
   → automated follow-ups
   
6. Deep prep before every call
   → know them better than they know themselves

input: your ICP + niche topics
output: booked meetings with people who already care

this is how bootstrapped founders compete with funded teams.

$150K GTM engineer → $200/month in tools

comment FIRST1000 + like + follow
```

### Supporting Content (Thread Breakdown)
1. Tweet 1: The hook (above)
2. Tweet 2: LinkedIn mining deep dive
3. Tweet 3: The enrichment stack
4. Tweet 4: ICP scoring system
5. Tweet 5: The personalization secret
6. Tweet 6: Instantly setup
7. Tweet 7: Pre-call research
8. Tweet 8: The math ($150K vs $200)
9. Tweet 9: CTA (comment FIRST1000)

### Content Calendar
| Day | Content | Purpose |
|-----|---------|---------|
| Pre-launch | Tease: "building something for bootstrapped founders" | Build anticipation |
| Launch Day (Thu 9PM) | Main giveaway post | Drive comments/follows |
| Day +1 | Thread breakdown | Education + engagement |
| Day +2 | Results/testimonials | Social proof |
| Day +3 | FAQ post | Handle objections |
| Day +7 | "Still available" reminder | Second wave |

---

## WHAT THEY GET (The Kit)

### Folder Structure
```
first-1000-kit/
├── README.md                 # Quick start guide
├── SETUP.md                  # Tool setup instructions
├── skills/
│   ├── linkedin-miner/
│   │   ├── SKILL.md
│   │   └── scripts/
│   ├── icp-prospector/
│   │   ├── SKILL.md
│   │   └── prompts/
│   ├── lead-enricher/
│   │   ├── SKILL.md
│   │   └── scripts/
│   ├── email-verifier/
│   │   ├── SKILL.md
│   │   └── scripts/
│   ├── icp-scorer/
│   │   ├── SKILL.md
│   │   └── templates/
│   ├── outreach-writer/
│   │   ├── SKILL.md
│   │   └── prompts/
│   ├── instantly-loader/
│   │   ├── SKILL.md
│   │   └── scripts/
│   └── pre-call-research/
│       ├── SKILL.md
│       └── prompts/
├── templates/
│   ├── SOUL-gtm.md           # GTM voice template
│   ├── icp-scorecard.md      # ICP scoring template
│   └── email-sequences/      # Email templates
├── n8n/
│   └── workflows/            # n8n workflow JSONs
└── docs/
    ├── tool-setup.md         # API setup guides
    └── troubleshooting.md
```

---

## SUCCESS METRICS

### Giveaway Metrics
| Metric | Target |
|--------|--------|
| Comments | 500+ |
| Follows | 1,000+ |
| Engagement | 2,000+ |
| DMs sent | 300+ |

### Product Metrics (if monetized later)
| Metric | Target |
|--------|--------|
| Kit downloads | 1,000+ |
| Active users | 200+ |
| Testimonials | 20+ |

---

## FUTURE EXPANSION

### Potential Add-Ons
- CRM integration (HubSpot, Pipedrive)
- Slack notifications for replies
- Meeting scheduler integration (Cal.com)
- Response handler (AI reply drafts)
- Pipeline tracker dashboard

### Monetization Options
- Free kit → Paid "pro" version with support
- Cohort-based implementation program
- Done-for-you setup service
- Premium skills as add-ons

---

## NEXT STEPS

1. **Validate:** Post teaser, gauge interest
2. **Build:** Phase 1 skills (2-3 days)
3. **Test:** Run on your own outbound
4. **Document:** Create setup guides
5. **Package:** Prepare giveaway kit
6. **Launch:** Thursday 9PM slot
7. **Support:** DM delivery + follow-up

---

*This is the GTM system for the AI era. Ship it.*
