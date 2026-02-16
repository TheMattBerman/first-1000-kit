---
name: linkedin-miner
description: Mine LinkedIn posts for engaged prospects using Fresh LinkedIn Data API (RapidAPI). Scrapes posts by keyword/influencer and extracts engagers (commenters + reactors) with profile data.
---

# LinkedIn Miner

Mine LinkedIn engagement to find warm prospects. People who engage with niche content are already interested in the topic — they're warm leads.

## What It Does

1. Searches LinkedIn posts by keyword OR scrapes influencer's posts
2. Extracts all engagers (commenters + reactors)
3. Returns profile data: name, headline, LinkedIn URL
4. Prioritizes commenters (higher intent than likers)

## API: Fresh LinkedIn Data (RapidAPI)

Uses Matt's existing RapidAPI subscription — no additional costs.

**Endpoints Used:**
| Endpoint | Purpose | Credits |
|----------|---------|---------|
| POST /search-posts | Find posts by keyword | 2/call |
| GET /get-profile-posts | Get influencer's posts | 2/call |
| GET /get-post-comments | Extract commenters | (included) |
| GET /get-post-reactions | Extract reactors | (included) |

## Invocation

```bash
# Search by keyword
./scripts/mine.sh "AI marketing automation" 10

# Scrape influencer's posts (use LinkedIn URN)
./scripts/mine.sh --influencer "ACoAABOPHB8BM6..." 5

# Output to file
./scripts/mine.sh "SaaS growth" 20 > leads.json
```

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `<query>` | Search keyword/topic | Required |
| `--influencer` | LinkedIn URN to scrape posts from | None |
| `<max_posts>` | Max posts to process | 10 |

## Setup

### Environment Variables
```bash
export RAPIDAPI_KEY="YOUR_RAPIDAPI_KEY_HERE"
```

### Dependencies
- `curl` (for API calls)
- `jq` (for JSON parsing)

## Output Format

```json
{
  "meta": {
    "query": "AI marketing automation",
    "posts_processed": 10,
    "total_engagers": 156,
    "commenters": 32,
    "reactors": 124,
    "scraped_at": "2026-02-14T15:00:00Z"
  },
  "leads": [
    {
      "name": "Jane Doe",
      "headline": "VP Marketing at Acme Corp",
      "linkedin_url": "https://linkedin.com/in/janedoe",
      "linkedin_urn": "ACoAABOPHB8BM6...",
      "engagement_type": "comment",
      "engagement_text": "Great insights on automation!",
      "post_url": "https://linkedin.com/feed/update/...",
      "intent_score": 8
    }
  ]
}
```

## Intent Scoring

| Score | Engagement Type |
|-------|-----------------|
| 10 | Detailed comment with question |
| 8 | Comment with insight/agreement |
| 6 | Simple comment ("Great post!") |
| 4 | Reaction (like, celebrate, etc.) |

## Pipeline Flow

```
linkedin-miner → lead-enricher → email-verifier → icp-scorer → outreach-writer → instantly-loader
```

## Credit Costs

| Action | Credits |
|--------|---------|
| Search 10 posts | 2 |
| Get comments (per post) | ~0 (bundled) |
| Get reactions (per post) | ~0 (bundled) |
| **Total for 10 posts** | ~2-4 credits |

## Example Workflow

```bash
# Morning routine: Mine fresh engagers
./scripts/mine.sh "AI for agencies" 20 > today_leads.json

# Mine from competitor's audience
./scripts/mine.sh --influencer "ACoAAcompetitor123" 10 > competitor_leads.json
```
