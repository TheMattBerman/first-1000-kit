---
name: lead-enricher
description: Enrich leads with full LinkedIn profile data (RapidAPI) and verified work emails (Hunter.io + Apollo). Two-stage enrichment for maximum data capture.
---

# Lead Enricher

Turn LinkedIn leads into actionable contacts with full profile data and verified emails.

## What It Does

**Stage 1: Profile Enrichment (RapidAPI)**
- Fetches full LinkedIn profile data
- Gets company, title, industry, experience
- May find email directly from LinkedIn profile

**Stage 2: Email Enrichment (Hunter + Apollo)**
- Finds work email using Hunter.io
- Falls back to Apollo if Hunter misses
- Returns verified emails with confidence scores

## Invocation

```bash
# Full two-stage enrichment (recommended)
./scripts/profile-enrich.sh leads.json | ./scripts/enrich.sh > enriched.json

# Profile enrichment only (get profile data, skip email hunt)
./scripts/profile-enrich.sh leads.json > profiles.json

# Email enrichment only (skip profile, just find emails)
./scripts/enrich.sh leads.json > enriched.json
```

## Setup

### Environment Variables
```bash
# RapidAPI (for profile enrichment)
export RAPIDAPI_KEY="YOUR_RAPIDAPI_KEY_HERE"

# Hunter.io (for email finding) - REQUIRED for stage 2
export HUNTER_API_KEY="your_hunter_api_key"

# Apollo (optional fallback)
export APOLLO_API_KEY="your_apollo_api_key"
```

## Scripts

### profile-enrich.sh
Enriches leads with full LinkedIn profile data using RapidAPI.

**Input:** Output from linkedin-miner
**Output:** Same leads + profile data (company, title, industry, experience, skills)
**Cost:** 1 credit per profile

```bash
./scripts/profile-enrich.sh leads.json > profiles.json
```

### enrich.sh
Finds work emails using Hunter.io (primary) + Apollo (fallback).

**Input:** Leads with name + company
**Output:** Same leads + email, email_score, email_verified
**Cost:** 1 Hunter search per lead

```bash
./scripts/enrich.sh profiles.json > enriched.json
```

## Input Format

Expects output from linkedin-miner:
```json
{
  "leads": [
    {
      "name": "Jane Doe",
      "headline": "VP Marketing at Acme Corp",
      "linkedin_url": "https://linkedin.com/in/janedoe"
    }
  ]
}
```

## Output Format

After full enrichment:
```json
{
  "meta": {
    "total_leads": 50,
    "profile_enriched": 48,
    "linkedin_emails_found": 12,
    "hunter_hits": 30,
    "apollo_hits": 5,
    "failed": 3,
    "enriched_at": "2026-02-14T15:00:00Z"
  },
  "leads": [
    {
      "name": "Jane Doe",
      "first_name": "Jane",
      "last_name": "Doe",
      "title": "VP Marketing",
      "headline": "VP Marketing at Acme Corp | AI Enthusiast",
      "company": "Acme Corp",
      "company_domain": "acme.com",
      "company_size": "201-500",
      "company_industry": "Technology",
      "location": "San Francisco, CA",
      "linkedin_url": "https://linkedin.com/in/janedoe",
      "experiences": [...],
      "skills": "Marketing, AI, Growth",
      "email": "jane.doe@acme.com",
      "email_source": "hunter",
      "email_score": 91,
      "email_verified": true,
      "enrichment_status": "success",
      "profile_enriched": true
    }
  ]
}
```

## Enrichment Strategy

```
Stage 1: Profile Enrichment (RapidAPI)
├── Fetch full LinkedIn profile
├── Extract: name, title, company, industry, experience, skills
├── Check for LinkedIn email → if found, mark for skip in Stage 2
└── Cost: 1 credit per profile

Stage 2: Email Finding (Hunter + Apollo)
├── Skip leads with linkedin_email found
├── Hunter Email Finder (primary)
│   ├── If score >= 70 and verified: ✅ Done
│   └── If not found or low score: Try Apollo
├── Apollo Fallback
│   └── Search by name + company
└── Cost: 1 Hunter search per lead
```

## Credit Costs

| Service | Cost | Notes |
|---------|------|-------|
| RapidAPI Profile | 1 credit/profile | Full profile data |
| Hunter Email Finder | 1 search/lead | Varies by plan |
| Apollo | Free tier: 50/mo | Fallback only |

**Example: 100 leads**
- Profile enrichment: 100 credits (~$1-2)
- Hunter searches: ~88 (skip 12 with LinkedIn email)
- Total: ~$3-5 depending on plans

## Usage in First 1000 Kit

```bash
# Full pipeline
./linkedin-miner/scripts/mine.sh "AI marketing" 20 > raw.json

# Enrich with profiles + emails
./lead-enricher/scripts/profile-enrich.sh raw.json | \
  ./lead-enricher/scripts/enrich.sh > enriched.json

# Next: verify emails
./email-verifier/scripts/verify.sh enriched.json > verified.json
```

## Rate Limits

| Service | Limit | Notes |
|---------|-------|-------|
| RapidAPI | Based on plan | 500-5000/mo typical |
| Hunter | 25 free, then paid | $49/mo for 500 |
| Apollo | 50/mo free | Upgrade for more |
