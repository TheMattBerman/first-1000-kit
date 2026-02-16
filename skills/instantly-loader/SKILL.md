---
name: instantly-loader
description: Load leads and email sequences into Instantly.ai campaigns. Handles lead upload, custom variables, and campaign management.
---

# Instantly Loader

Push verified leads and personalized sequences into Instantly.ai for automated sending.

## What It Does

1. Takes verified leads with email sequences
2. Formats for Instantly API
3. Uploads to specified campaign
4. Sets custom variables for personalization

## Invocation

```bash
# Load leads to campaign
./scripts/load.sh verified.json --campaign "First1000-Feb"

# Create new campaign first
./scripts/load.sh verified.json --create-campaign "First1000-Feb"

# Dry run (show what would upload)
DRY_RUN=true ./scripts/load.sh verified.json --campaign "abc123"

# List existing campaigns
./scripts/campaigns.sh
```

## Setup

### Environment Variables
```bash
export INSTANTLY_API_KEY="your_instantly_api_key"
```

### Get Your API Key
1. Go to https://app.instantly.ai/settings/integrations
2. Copy API key
3. Set in environment

## Input Format

Expects output from email-verifier (which includes sequences from outreach-writer):
```json
{
  "emails": [
    {
      "lead": {
        "name": "Lisa Chen",
        "email": "lisa@growthlabs.com",
        "company": "GrowthLabs",
        "linkedin_url": "https://linkedin.com/in/lisachen",
        "tier": "A"
      },
      "sequence": [
        {
          "step": 1,
          "delay_days": 0,
          "subject": "ai",
          "body": "Lisa,\n\nYour take on AI..."
        },
        {
          "step": 2,
          "delay_days": 3,
          "subject": "re: ai",
          "body": "Lisa,\n\nQuick follow-up..."
        }
      ]
    }
  ]
}
```

## Instantly Lead Format

```json
{
  "email": "lisa@growthlabs.com",
  "first_name": "Lisa",
  "last_name": "Chen",
  "company_name": "GrowthLabs",
  "personalization": "Your take on AI is exactly how we think about outbound.",
  "custom_variables": {
    "linkedin_url": "https://linkedin.com/in/lisachen",
    "tier": "A",
    "subject_1": "ai",
    "body_1": "Lisa,\n\nYour take on AI...",
    "subject_2": "re: ai",
    "body_2": "Lisa,\n\nQuick follow-up..."
  }
}
```

## API Endpoints

### Add Leads to Campaign
```bash
POST https://api.instantly.ai/api/v1/lead/add
{
  "api_key": "YOUR_KEY",
  "campaign_id": "campaign_abc123",
  "skip_if_in_workspace": true,
  "leads": [...]
}
```

### List Campaigns
```bash
GET https://api.instantly.ai/api/v1/campaign/list?api_key=YOUR_KEY
```

### Create Campaign
```bash
POST https://api.instantly.ai/api/v1/campaign/create
{
  "api_key": "YOUR_KEY",
  "name": "First1000-Feb",
  "daily_limit": 50
}
```

### Get Campaign Status
```bash
GET https://api.instantly.ai/api/v1/campaign/status?api_key=YOUR_KEY&campaign_id=abc123
```

## Setting Up Sequences in Instantly

After loading leads, configure your sequence in Instantly UI:

**Email 1 (Day 0):**
```
Subject: {{subject_1}}
Body: {{body_1}}
```

**Email 2 (Day 3):**
```
Subject: {{subject_2}}
Body: {{body_2}}
```

**Email 3 (Day 7):**
```
Subject: {{subject_3}}
Body: {{body_3}}
```

Or use Instantly's native sequence builder with the `personalization` field:
```
Subject: quick thought on {{topic}}
Body: {{personalization}}

[Rest of template]
```

## Output Format

```json
{
  "meta": {
    "campaign_id": "abc123",
    "campaign_name": "First1000-Feb",
    "leads_uploaded": 42,
    "leads_skipped": 3,
    "loaded_at": "2026-02-14T15:00:00Z"
  },
  "results": {
    "success": ["lisa@growthlabs.com", "..."],
    "skipped": ["already@exists.com"],
    "failed": []
  }
}
```

## Usage in Pipeline

```bash
# Full pipeline
./linkedin-miner/scripts/mine.sh "AI marketing" 20 > raw.json
./lead-enricher/scripts/profile-enrich.sh raw.json | \
  ./lead-enricher/scripts/enrich.sh > enriched.json
./icp-scorer/scripts/score.sh enriched.json > scored.json
./outreach-writer/scripts/write.sh scored.json > emails.json
./email-verifier/scripts/verify.sh emails.json > verified.json
./instantly-loader/scripts/load.sh verified.json --campaign "First1000-Feb"

# One-liner
./linkedin-miner/scripts/mine.sh "AI marketing" 20 2>/dev/null | \
  ./icp-scorer/scripts/score.sh | \
  ./outreach-writer/scripts/write.sh | \
  ./instantly-loader/scripts/load.sh --campaign "First1000"
```

## Best Practices

### Daily Limits
- Start with 20-30 emails/day per inbox
- Warm up new domains: 5 → 10 → 20 → 50 over 2-4 weeks
- Multiple inboxes scale faster than one high-volume inbox

### Timing
- B2B: Tuesday-Thursday, 8-10am recipient's timezone
- Avoid Mondays (inbox overload) and Fridays (checked out)

### Monitoring
- Track open rates (aim for 40%+)
- Track reply rates (aim for 5%+)
- Pause campaigns if bounce rate > 3%
