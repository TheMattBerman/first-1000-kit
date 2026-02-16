# The First 1000 Customers Kit

**An open-source AI GTM system that replaces a $150K hire with ~$100/month in tools.**

Built with [OpenClaw](https://openclaw.ai) — the AI agent framework.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw](https://img.shields.io/badge/Built%20with-OpenClaw-blue)](https://openclaw.ai)

---

## What It Does

```
LinkedIn Engagement → Verified Emails → Personalized Outreach → Booked Meetings
```

This kit automates the entire top-of-funnel GTM process:

1. **Mine LinkedIn** — Find people engaging with niche content (warm leads, not cold lists)
2. **Enrich** — Get verified work emails via Hunter.io + Apollo
3. **Score** — Rank leads against your ICP (A/B/C/D tiers)
4. **Write** — Generate hyper-personalized cold emails using AI
5. **Send** — Load into Instantly.ai sequences

**The result:** A full pipeline from "who's talking about my space?" to "meeting booked" — running on autopilot.

---

## Why This Exists

I've spent 20 years in marketing. Scaled Fireball Whisky from one state to a billion-dollar global brand. Ran campaigns for Heineken, Hennessy, Buffalo Trace. Now I run [Emerald Digital](https://emerald.digital), an AI-first marketing agency.

Here's what I learned: **Most startups can't afford a GTM engineer.** So founders do outbound manually (slow), hire too early (expensive), or skip it entirely (fatal).

This kit is the system I wish I had. It does what a $150K/year GTM hire does — for about $100/month in API costs.

I'm open-sourcing it because the best marketing happens when founders can actually reach their customers.

---

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/themattberman/first-1000-kit.git
cd first-1000-kit
```

### 2. Get your API keys

| Service | Purpose | Link |
|---------|---------|------|
| RapidAPI | LinkedIn scraping | [rapidapi.com](https://rapidapi.com) → "Fresh LinkedIn Profile Data" |
| Hunter.io | Email finding | [hunter.io](https://hunter.io) |
| Instantly.ai | Email sending | [instantly.ai](https://instantly.ai) |

### 3. Configure

```bash
cp .env.example .env
cp brand-config.example.json brand-config.json

# Edit both files with your keys and ICP
```

### 4. Run

```bash
# Full pipeline: find 50 leads in your niche
./run.sh "AI marketing automation" 50

# Or run with OpenClaw agent
openclaw start
# Then message: "Mine LinkedIn for AI marketing, 50 leads"
```

See [SETUP.md](SETUP.md) for detailed instructions.

---

## The 7 Skills

| Skill | What It Does |
|-------|--------------|
| `linkedin-miner` | Scrapes LinkedIn posts, extracts everyone who engaged |
| `lead-enricher` | Finds verified emails via Hunter.io + Apollo |
| `email-verifier` | Validates emails before sending |
| `icp-scorer` | Scores leads against your ideal customer profile |
| `outreach-writer` | Generates personalized cold emails with AI |
| `instantly-loader` | Pushes sequences to Instantly.ai |
| `pre-call-research` | Deep research before sales calls |

Each skill can run standalone or as part of the full pipeline.

---

## How It Works

### The Pipeline

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  LinkedIn       │────▶│   Enrichment    │────▶│   ICP Scoring   │
│  Mining         │     │   (emails)      │     │   (A/B/C/D)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Instantly.ai   │◀────│   Outreach      │◀────│   A-Tier        │
│  Sequences      │     │   Writer        │     │   Leads         │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Why LinkedIn Engagement?

Traditional outbound scrapes LinkedIn for titles and blasts generic emails. Response rates: 1-2%.

This system finds people **actively engaging with content in your niche**. They commented on a post about AI marketing? They're already thinking about it. That's a warm lead.

Response rates with warm + personalized: 8-15%.

---

## Configuration

### Brand & ICP

Edit `brand-config.json` to define:

```json
{
  "icp": {
    "target_titles": ["VP Marketing", "Head of Growth", "CMO"],
    "target_industries": ["SaaS", "E-commerce"],
    "company_size": { "min": 50, "max": 500 }
  },
  "outreach": {
    "sender_name": "Your Name",
    "tone": "professional but conversational",
    "pain_points": ["Problem 1 you solve", "Problem 2"]
  }
}
```

Or just tell the OpenClaw agent your ICP conversationally — it'll figure it out.

---

## Costs

| Tool | Monthly Cost |
|------|--------------|
| RapidAPI | ~$30-50 |
| Hunter.io | Free - $50 |
| Instantly.ai | $30 |
| **Total** | **~$60-130/mo** |

**vs hiring a GTM engineer:** $150,000/year

---

## Running with OpenClaw

This kit is built for [OpenClaw](https://openclaw.ai), an open-source AI agent framework.

```bash
# Install OpenClaw
npm install -g openclaw

# Copy kit to workers directory
cp -r first-1000-kit ~/clawd/workers/first-1000

# Start the agent
cd ~/clawd/workers/first-1000
openclaw start
```

Then just message it naturally:

- "Mine LinkedIn for people talking about AI automation"
- "Enrich and score against my ICP"  
- "Write outreach for A-tier leads"
- "Load to Instantly"

The agent handles the orchestration.

---

## File Structure

```
first-1000-kit/
├── README.md              # You're here
├── SETUP.md               # Detailed setup guide
├── run.sh                 # Pipeline runner
├── .env.example           # API key template
├── brand-config.example.json  # ICP template
├── skills/
│   ├── linkedin-miner/
│   ├── lead-enricher/
│   ├── email-verifier/
│   ├── icp-scorer/
│   ├── outreach-writer/
│   ├── instantly-loader/
│   └── pre-call-research/
├── SOUL.md                # Agent personality (for OpenClaw)
├── AGENTS.md              # Agent instructions
└── SPEC.md                # Full system spec
```

---

## Contributing

This is open source. PRs welcome.

Ideas for contribution:
- Additional lead sources (Twitter/X, Reddit, etc.)
- More email providers (Lemlist, Apollo sequences)
- Better scoring models
- UI/dashboard

---

## License

MIT License. Use it, fork it, build on it.

---

## About

Built by [Matt Berman](https://twitter.com/themattberman).

- 🐦 Twitter/X: [@themattberman](https://twitter.com/themattberman)
- 📰 Newsletter: [Big Players](https://bigplayers.co)
- 🏢 Agency: [Emerald Digital](https://emerald.digital)

This is how bootstrapped founders compete with funded teams.

---

*Star the repo if this helps. It tells me to keep building.*
