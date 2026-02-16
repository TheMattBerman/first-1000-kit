#!/bin/bash
# linkedin-miner/scripts/mine.sh
# Mine LinkedIn posts and extract engagers using Fresh LinkedIn Data API (RapidAPI)

set -e

# Config
RAPIDAPI_KEY="${RAPIDAPI_KEY:-YOUR_RAPIDAPI_KEY_HERE}"
RAPIDAPI_HOST="fresh-linkedin-profile-data.p.rapidapi.com"
BASE_URL="https://$RAPIDAPI_HOST"

# Parse args
INFLUENCER=""
if [[ "$1" == "--influencer" ]]; then
  INFLUENCER="$2"
  MAX_POSTS="${3:-10}"
else
  SEARCH_QUERY="${1:-AI marketing}"
  MAX_POSTS="${2:-10}"
fi

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# Temp files for collecting engagers
ENGAGERS_FILE=$(mktemp)
trap "rm -f $ENGAGERS_FILE" EXIT

# Step 1: Get posts (either by search or by influencer)
if [[ -n "$INFLUENCER" ]]; then
  log "Fetching posts from influencer: $INFLUENCER"
  
  POSTS=$(curl -s -X GET "$BASE_URL/get-profile-posts?linkedin_url=https://linkedin.com/in/$INFLUENCER&type=posts" \
    -H "x-rapidapi-key: $RAPIDAPI_KEY" \
    -H "x-rapidapi-host: $RAPIDAPI_HOST")
  
  # Extract post URNs
  POST_URNS=$(echo "$POSTS" | jq -r '.data[0:'"$MAX_POSTS"'] | .[].urn // empty')
else
  log "Searching posts for: '$SEARCH_QUERY'"
  
  POSTS=$(curl -s -X POST "$BASE_URL/search-posts" \
    -H "x-rapidapi-key: $RAPIDAPI_KEY" \
    -H "x-rapidapi-host: $RAPIDAPI_HOST" \
    -H "Content-Type: application/json" \
    -d "{
      \"search_keywords\": \"$SEARCH_QUERY\",
      \"sort_by\": \"Top match\",
      \"date_posted\": \"Past week\",
      \"page\": 1
    }")
  
  # Extract post URNs from search results
  POST_URNS=$(echo "$POSTS" | jq -r '.data[0:'"$MAX_POSTS"'] | .[].urn // empty')
fi

POST_COUNT=$(echo "$POST_URNS" | grep -c . || echo 0)
log "Found $POST_COUNT posts to process"

if [[ "$POST_COUNT" -eq 0 ]]; then
  log "No posts found"
  echo '{"meta":{"posts_processed":0,"total_engagers":0},"leads":[]}'
  exit 0
fi

# Step 2: For each post, get comments and reactions
PROCESSED=0
TOTAL_COMMENTERS=0
TOTAL_REACTORS=0

for URN in $POST_URNS; do
  PROCESSED=$((PROCESSED + 1))
  POST_URL="https://www.linkedin.com/feed/update/urn:li:activity:$URN/"
  log "Processing post $PROCESSED/$POST_COUNT: $URN"
  
  # Get comments (use urn= parameter, not post_url=)
  COMMENTS=$(curl -s -X GET "$BASE_URL/get-post-comments?urn=$URN" \
    -H "x-rapidapi-key: $RAPIDAPI_KEY" \
    -H "x-rapidapi-host: $RAPIDAPI_HOST" 2>/dev/null || echo '{"data":[]}')
  
  # Extract commenters
  COMMENTER_COUNT=$(echo "$COMMENTS" | jq '.data | length // 0')
  TOTAL_COMMENTERS=$((TOTAL_COMMENTERS + COMMENTER_COUNT))
  
  echo "$COMMENTS" | jq -c '.data[]? | {
    name: .commenter.name,
    headline: .commenter.headline,
    linkedin_url: .commenter.linkedin_url,
    linkedin_urn: .commenter.urn,
    engagement_type: "comment",
    engagement_text: .text,
    post_url: "'"$POST_URL"'",
    intent_score: (if (.text | length) > 100 then 10 elif (.text | length) > 30 then 8 else 6 end)
  }' >> "$ENGAGERS_FILE" 2>/dev/null || true
  
  # Get reactions (use urn= parameter)
  REACTIONS=$(curl -s -X GET "$BASE_URL/get-post-reactions?urn=$URN" \
    -H "x-rapidapi-key: $RAPIDAPI_KEY" \
    -H "x-rapidapi-host: $RAPIDAPI_HOST" 2>/dev/null || echo '{"data":[]}')
  
  # Extract reactors
  REACTOR_COUNT=$(echo "$REACTIONS" | jq '.data | length // 0')
  TOTAL_REACTORS=$((TOTAL_REACTORS + REACTOR_COUNT))
  
  echo "$REACTIONS" | jq -c '.data[]? | {
    name: .reactor.name,
    headline: .reactor.headline,
    linkedin_url: .reactor.linkedin_url,
    linkedin_urn: .reactor.urn,
    engagement_type: "reaction",
    reaction_type: .type,
    post_url: "'"$POST_URL"'",
    intent_score: 4
  }' >> "$ENGAGERS_FILE" 2>/dev/null || true
  
  # Small delay to avoid rate limits
  sleep 0.5
done

# Step 3: Dedupe by LinkedIn URL and format output
TOTAL_ENGAGERS=$(wc -l < "$ENGAGERS_FILE" | tr -d ' ')
log "Collected $TOTAL_ENGAGERS engagers (Commenters: $TOTAL_COMMENTERS, Reactors: $TOTAL_REACTORS)"

# Build final output
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Dedupe and sort by intent score (commenters first)
LEADS=$(cat "$ENGAGERS_FILE" | jq -s '
  group_by(.linkedin_url) | 
  map(max_by(.intent_score)) |
  sort_by(-.intent_score)
')

UNIQUE_COUNT=$(echo "$LEADS" | jq 'length')
log "Unique leads after dedup: $UNIQUE_COUNT"

# Output final JSON
jq -n \
  --arg query "${SEARCH_QUERY:-influencer:$INFLUENCER}" \
  --argjson posts_processed "$PROCESSED" \
  --argjson total_engagers "$TOTAL_ENGAGERS" \
  --argjson commenters "$TOTAL_COMMENTERS" \
  --argjson reactors "$TOTAL_REACTORS" \
  --argjson unique_leads "$UNIQUE_COUNT" \
  --arg scraped_at "$TIMESTAMP" \
  --argjson leads "$LEADS" \
  '{
    meta: {
      query: $query,
      posts_processed: $posts_processed,
      total_engagers: $total_engagers,
      commenters: $commenters,
      reactors: $reactors,
      unique_leads: $unique_leads,
      scraped_at: $scraped_at
    },
    leads: $leads
  }'
