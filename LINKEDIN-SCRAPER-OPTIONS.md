# LinkedIn Scraper Options — First 1000 Kit

## What We Need
For the `linkedin-miner` skill, we need to:
1. Search/find posts in a niche (by keyword or influencer)
2. Extract everyone who ENGAGED (liked, commented)
3. Get their profile data (name, title, company, LinkedIn URL)

---

## DECISION: RapidAPI (Fresh LinkedIn Data)

We went with **RapidAPI Fresh LinkedIn Data** because:
1. ✅ Matt already subscribed
2. ✅ Sync API (faster than Apify's async actors)
3. ✅ Profile enrichment built-in
4. ✅ Returns engager data via `/get-post-comments` and `/get-post-reactions`

**Key insight:** Use `urn=` parameter (NOT `post_url=`) for comments/reactions endpoints.

---

## OPTION 1: RapidAPI Fresh LinkedIn ← SELECTED

**API:** `fresh-linkedin-profile-data.p.rapidapi.com`  
**Your Key:** `YOUR_RAPIDAPI_KEY_HERE`

### Endpoints Used:
```bash
# Search posts by keyword
POST /search-posts
{"search_keywords": "AI marketing", "sort_by": "Top match", "date_posted": "Past week"}

# Get influencer's posts
GET /get-profile-posts?linkedin_url=https://linkedin.com/in/username&type=posts

# Get commenters (use urn= NOT post_url=)
GET /get-post-comments?urn=7202146404788580353

# Get reactors (use urn= NOT post_url=)  
GET /get-post-reactions?urn=7202146404788580353
```

### What It Returns (Comments):
```json
{
  "data": [
    {
      "text": "Great insights on automation!",
      "commenter": {
        "name": "Jane Doe",
        "headline": "VP Marketing at Acme Corp",
        "linkedin_url": "https://linkedin.com/in/janedoe",
        "urn": "ACoAABOPHB8BM6..."
      }
    }
  ]
}
```

### ✅ Pros:
- Already subscribed (no new accounts)
- Sync API (results immediately, no polling)
- Returns ENGAGER profile data
- Includes comments/reactions endpoints
- Cost: ~$0.006/request

### ❌ Cons:
- None for our use case

---

## OPTION 2: Apify LinkedIn Post Scraper — BACKUP

**Actor:** `curious_coder/linkedin-post-search-scraper`  
**Token:** `YOUR_APIFY_TOKEN_HERE`

### Use For:
- Twitter/X scraping (via `apidojo/tweet-scraper`)
- Backup if RapidAPI has issues

### ❌ Why Not Primary:
- Async actors (need to poll for results)
- New subscription when we already have RapidAPI
- Slower overall workflow

---

## OPTION 3: ScrapeCreators — ENRICHMENT ONLY

**Base:** `api.scrapecreators.com`

### Use For:
- Company profile enrichment
- Instagram/TikTok data
- NOT for LinkedIn engagement mining

---

## FINAL ARCHITECTURE

```
┌─────────────────────────────────────────┐
│ 1. FIND POSTS (RapidAPI)                │
│    → POST /search-posts                 │
│    → or GET /get-profile-posts          │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 2. GET ENGAGERS (RapidAPI)              │
│    → GET /get-post-comments?urn=xxx     │
│    → GET /get-post-reactions?urn=xxx    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 3. ENRICH EMAILS (Hunter.io)            │
│    → Match name + company → email       │
│    → Apollo.io as fallback              │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 4. SCORE + OUTREACH                     │
│    → ICP scoring                        │
│    → Generate personalized emails       │
│    → Load to Instantly.ai               │
└─────────────────────────────────────────┘
```

---

## COST ESTIMATE

| Tool | Per Request | 100 Posts (500 leads) |
|------|-------------|----------------------|
| RapidAPI search | $0.006 | $0.60 |
| RapidAPI comments | ~included | ~$0 |
| RapidAPI reactions | ~included | ~$0 |
| Hunter.io | $0.05 | $25 |
| **Total** | — | **~$26** |

---

## IMPLEMENTATION

See `skills/linkedin-miner/scripts/mine.sh` for the working implementation.

Key parameters:
- `RAPIDAPI_KEY` — Your API key
- `RAPIDAPI_HOST` — `fresh-linkedin-profile-data.p.rapidapi.com`
- Use `urn=` for comments/reactions (NOT `post_url=`)
