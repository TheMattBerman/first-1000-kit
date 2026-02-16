---
name: email-verifier
description: Verify email addresses before sending to protect deliverability. Uses Hunter.io verification API. Filters out invalid, disposable, and risky emails.
---

# Email Verifier

Verify emails before loading into Instantly to protect your sender reputation.

## What It Does

1. Takes enriched leads with emails
2. Verifies each email via Hunter.io
3. Filters out invalid, disposable, and high-risk emails
4. Returns clean list ready for outreach

## Why This Matters

- **Bounce rate > 5%** = domain reputation damage
- **Spam traps** = instant blacklist
- **Disposable emails** = wasted sends
- **Accept-all domains** = risky but sometimes worth it

## Invocation

```bash
# Verify all emails
./scripts/verify.sh enriched.json > verified.json

# Strict mode (reject accept-all)
STRICT=true ./scripts/verify.sh enriched.json > verified.json

# Just check one email
./scripts/verify.sh --email "jane@acme.com"
```

## Setup

### Environment Variables
```bash
export HUNTER_API_KEY="your_hunter_api_key"
```

## Verification Statuses

| Status | Meaning | Action |
|--------|---------|--------|
| `valid` | Confirmed deliverable | ✅ Send |
| `accept_all` | Domain accepts any email | ⚠️ Send with caution |
| `invalid` | Will bounce | ❌ Remove |
| `disposable` | Temporary email | ❌ Remove |
| `webmail` | Personal email (gmail, etc) | ⚠️ Flag for review |
| `unknown` | Can't verify | ⚠️ Send with caution |

## Input Format

Expects leads with email field:
```json
{
  "leads": [
    {
      "name": "Jane Doe",
      "email": "jane@acme.com",
      "company": "Acme Corp"
    }
  ]
}
```

Or from outreach-writer:
```json
{
  "emails": [
    {
      "lead": {
        "name": "Jane Doe",
        "email": "jane@acme.com"
      },
      "sequence": [...]
    }
  ]
}
```

## Output Format

```json
{
  "meta": {
    "total": 50,
    "valid": 42,
    "accept_all": 5,
    "invalid": 2,
    "disposable": 1,
    "skipped": 0,
    "verified_at": "2026-02-14T15:00:00Z"
  },
  "leads": [
    {
      "name": "Jane Doe",
      "email": "jane@acme.com",
      "email_status": "valid",
      "email_score": 91,
      "safe_to_send": true
    }
  ]
}
```

## Hunter API Response

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

## Usage in Pipeline

```bash
# Full pipeline with verification
./linkedin-miner/scripts/mine.sh "AI marketing" 20 > raw.json
./lead-enricher/scripts/profile-enrich.sh raw.json | \
  ./lead-enricher/scripts/enrich.sh > enriched.json
./icp-scorer/scripts/score.sh enriched.json > scored.json
./outreach-writer/scripts/write.sh scored.json > emails.json
./email-verifier/scripts/verify.sh emails.json > verified.json
./instantly-loader/scripts/load.sh verified.json
```

## Rate Limits

| Plan | Verifications/month |
|------|---------------------|
| Free | 50 |
| Starter | 500 |
| Growth | 2,500 |
| Pro | 10,000 |

## Note: Hunter Email Finder Already Verifies

If you used Hunter's Email Finder in lead-enricher, emails are already verified. This skill is for:
- Emails from other sources (Apollo, LinkedIn, manual)
- Re-verification before sending
- Strict compliance requirements
