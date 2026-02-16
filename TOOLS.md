# TOOLS.md — First 1000 Kit

## API Endpoints

### RapidAPI (LinkedIn Mining) — Primary
- API: Fresh LinkedIn Data
- Host: `fresh-linkedin-profile-data.p.rapidapi.com`
- Key: Set in `RAPIDAPI_KEY`
- Why: Sync API (fast), already subscribed, profile enrichment built-in
- Note: Use `urn=` parameter (not `post_url=`) for comments/reactions

**Key Endpoints:**
| Endpoint | Purpose |
|----------|---------|
| POST /search-posts | Find posts by keyword |
| GET /get-profile-posts | Get influencer's posts |
| GET /get-post-comments | Extract commenters |
| GET /get-post-reactions | Extract reactors |

### Hunter.io (Email Finding)
- Endpoint: `https://api.hunter.io/v2/`
- Key: Set in `HUNTER_API_KEY`
- Includes verification

### Apollo (Backup Enrichment)
- Endpoint: `https://api.apollo.io/api/v1/`
- Key: Set in `APOLLO_API_KEY`
- Free tier: 50 credits/month

### Instantly (Email Sending)
- Endpoint: `https://api.instantly.ai/api/v1/`
- Key: Set in `INSTANTLY_API_KEY`
- Configure sequences in Instantly UI

### Apify (Twitter/X Scraping) — Optional
- Actor: `apidojo/tweet-scraper` (paid actor, free ones broken)
- Token: Set in `APIFY_TOKEN`
- Use for: Twitter engagement mining

## Script Locations

```
skills/
├── linkedin-miner/scripts/
│   ├── mine.sh      → RapidAPI scraper
│   └── extract.sh   → Lead extraction
├── lead-enricher/scripts/
│   └── enrich.sh    → Hunter + Apollo
├── icp-scorer/scripts/
│   └── score.sh     → Scoring logic
├── outreach-writer/prompts/
│   └── email-writer.md → Claude prompt
└── instantly-loader/scripts/
    └── load.sh      → API upload
```

## Custom ICP

Edit scoring weights in `skills/icp-scorer/scripts/score.sh`:
- Target titles
- Industry keywords  
- Seniority levels
- Engagement weights

## Daily Limits

| Tool | Recommended Daily |
|------|-------------------|
| LinkedIn scrape (RapidAPI) | 200-500 posts |
| Hunter lookups | 50-100 (depends on plan) |
| Instantly sends | 50-100 per account |
