# First 1000 Kit — Setup Guide

Get your AI GTM system running in 15 minutes.

---

## Step 1: Get Your API Keys

You need accounts with these services (free tiers work to start):

| Service | What For | Get It |
|---------|----------|--------|
| **RapidAPI** | LinkedIn scraping | [rapidapi.com](https://rapidapi.com) → Subscribe to "Fresh LinkedIn Profile Data" |
| **Hunter.io** | Email finding | [hunter.io](https://hunter.io) → Free: 25 searches/mo |
| **Instantly.ai** | Email sending | [instantly.ai](https://instantly.ai) → $30/mo Growth plan |

**Optional:**
| Service | What For | Get It |
|---------|----------|--------|
| Apollo.io | Backup enrichment | [apollo.io](https://apollo.io) → Free: 50 credits/mo |
| Perplexity | Pre-call research | [perplexity.ai](https://perplexity.ai) → $20/mo Pro |

---

## Step 2: Configure Environment

```bash
# Copy the template
cp .env.example .env

# Edit with your keys
nano .env
```

Your `.env` should look like:
```bash
RAPIDAPI_KEY=your_key_here
HUNTER_API_KEY=your_key_here
INSTANTLY_API_KEY=your_key_here

# Optional
APOLLO_API_KEY=your_key_here
PERPLEXITY_API_KEY=your_key_here
```

---

## Step 3: Configure Your Brand & ICP

Copy and edit the brand config:

```bash
cp brand-config.example.json brand-config.json
nano brand-config.json
```

This tells the system:
- Who you're targeting (ICP)
- Your product/service
- Your voice for outreach

**Or skip this** — just tell the agent your ICP when you run it. It'll ask if config is missing.

---

## Step 4: Test the Pipeline

```bash
# Quick test: Mine 10 leads
./run.sh "AI marketing automation" 10

# Check output
ls output/
cat output/*/scored.json | jq '.meta'
```

---

## Step 5: Run Your First Campaign

```bash
# Full pipeline: 50 leads
./run.sh "your niche topic" 50

# Review A-tier leads before sending
cat output/*/scored.json | jq '.leads | map(select(.tier == "A"))'

# Load to Instantly (after review)
./skills/instantly-loader/scripts/load.sh output/*/emails.json
```

---

## Directory Structure

After setup:
```
FIRST-1000-KIT/
├── .env                  # Your API keys (git-ignored)
├── brand-config.json     # Your ICP & brand (git-ignored)
├── run.sh                # Main pipeline runner
├── skills/               # Individual skills
│   ├── linkedin-miner/
│   ├── lead-enricher/
│   ├── icp-scorer/
│   ├── outreach-writer/
│   ├── instantly-loader/
│   └── pre-call-research/
└── output/               # Run outputs (git-ignored)
```

---

## Running as OpenClaw Agent

If you're using OpenClaw, copy this folder to your workers directory:

```bash
cp -r FIRST-1000-KIT ~/clawd/workers/first-1000
cd ~/clawd/workers/first-1000
openclaw start
```

Then just message it:
```
"Mine LinkedIn for AI marketing automation, 50 leads"
"Score against my ICP"
"Write outreach for A-tier"
"Load to Instantly"
```

---

## Troubleshooting

### "RapidAPI key not found"
Make sure `.env` exists and has `RAPIDAPI_KEY=...`

### "No leads found"
Try broader search terms or check RapidAPI subscription is active.

### "Low enrichment rate"
Hunter.io free tier is limited. Upgrade or use Apollo backup.

### "Scoring seems off"
Edit `brand-config.json` to better define your ICP.

---

## Cost Estimates

| Volume | RapidAPI | Hunter | Total |
|--------|----------|--------|-------|
| 50 leads/week | ~$5 | ~$5 | ~$10 |
| 200 leads/week | ~$20 | ~$20 | ~$40 |
| 500 leads/week | ~$50 | ~$50 | ~$100 |

Still way cheaper than a $150K GTM hire.

---

## Next Steps

1. Run a test campaign with 20-30 leads
2. Review the emails before sending
3. Track replies and iterate on your ICP
4. Scale up what works

Questions? [@themattberman](https://twitter.com/themattberman)
