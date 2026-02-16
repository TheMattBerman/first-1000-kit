#!/bin/bash
# lead-enricher/scripts/enrich.sh
# Enrich leads with emails using Hunter.io + Apollo fallback

set -e

# Config
HUNTER_API_KEY="${HUNTER_API_KEY}"
APOLLO_API_KEY="${APOLLO_API_KEY:-}"
MIN_SCORE="${MIN_SCORE:-70}"

# Args
INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-}"
SKIP_APOLLO="${3:-false}"

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# Check for Hunter API key
if [[ -z "$HUNTER_API_KEY" ]]; then
  log "ERROR: HUNTER_API_KEY not set"
  exit 1
fi

# Read input
if [[ "$INPUT_FILE" == "/dev/stdin" ]]; then
  INPUT_DATA=$(cat)
else
  INPUT_DATA=$(cat "$INPUT_FILE")
fi

# Process with node
RESULT=$(node << 'ENRICHER_SCRIPT' "$INPUT_DATA" "$HUNTER_API_KEY" "$APOLLO_API_KEY" "$MIN_SCORE" "$SKIP_APOLLO"
const https = require('https');
const inputData = JSON.parse(process.argv[2]);
const HUNTER_KEY = process.argv[3];
const APOLLO_KEY = process.argv[4];
const MIN_SCORE = parseInt(process.argv[5]) || 70;
const SKIP_APOLLO = process.argv[6] === 'true';

// Simple HTTP GET
function httpGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ error: 'parse_error' });
        }
      });
    }).on('error', reject);
  });
}

// Simple HTTP POST
function httpPost(url, body, headers) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ error: 'parse_error' });
        }
      });
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(body));
    req.end();
  });
}

// Extract domain from company name
function guessDomain(company) {
  if (!company) return null;
  // Simple heuristic: lowercase, remove common suffixes, add .com
  const cleaned = company.toLowerCase()
    .replace(/\s+(inc|llc|ltd|corp|co|company|corporation|group)\.?$/i, '')
    .replace(/[^a-z0-9]/g, '');
  return cleaned + '.com';
}

// Hunter Email Finder
async function hunterFind(firstName, lastName, domain) {
  const url = `https://api.hunter.io/v2/email-finder?domain=${domain}&first_name=${encodeURIComponent(firstName)}&last_name=${encodeURIComponent(lastName)}&api_key=${HUNTER_KEY}`;
  const result = await httpGet(url);
  
  if (result.data && result.data.email) {
    return {
      email: result.data.email,
      score: result.data.score || 0,
      verified: result.data.verification?.status === 'valid',
      source: 'hunter'
    };
  }
  return null;
}

// Apollo fallback
async function apolloFind(firstName, lastName, company, linkedinUrl) {
  if (!APOLLO_KEY || SKIP_APOLLO) return null;
  
  const body = {
    first_name: firstName,
    last_name: lastName,
    organization_name: company,
    reveal_personal_emails: false
  };
  
  if (linkedinUrl) {
    body.linkedin_url = linkedinUrl;
  }
  
  const result = await httpPost('https://api.apollo.io/api/v1/people/match', body, {
    'x-api-key': APOLLO_KEY
  });
  
  if (result.person && result.person.email) {
    return {
      email: result.person.email,
      score: result.person.email_status === 'verified' ? 90 : 60,
      verified: result.person.email_status === 'verified',
      source: 'apollo'
    };
  }
  return null;
}

// Sleep helper
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Main enrichment
async function main() {
  const leads = inputData.leads || inputData;
  const enrichedLeads = [];
  
  let hunterHits = 0;
  let apolloHits = 0;
  let failed = 0;
  
  for (let i = 0; i < leads.length; i++) {
    const lead = leads[i];
    console.error(`[${i+1}/${leads.length}] ${lead.name} @ ${lead.company}`);
    
    // Guess domain
    const domain = guessDomain(lead.company);
    let result = null;
    
    // Try Hunter first
    if (domain && lead.first_name && lead.last_name) {
      try {
        result = await hunterFind(lead.first_name, lead.last_name, domain);
        if (result && result.score >= MIN_SCORE) {
          hunterHits++;
          console.error(`  ✅ Hunter: ${result.email} (score: ${result.score})`);
        } else if (result) {
          console.error(`  ⚠️ Hunter: low score (${result.score}), trying Apollo...`);
          result = null;
        }
      } catch (e) {
        console.error(`  ⚠️ Hunter error: ${e.message}`);
      }
    }
    
    // Apollo fallback
    if (!result && APOLLO_KEY && !SKIP_APOLLO) {
      try {
        result = await apolloFind(lead.first_name, lead.last_name, lead.company, lead.linkedin_url);
        if (result) {
          apolloHits++;
          console.error(`  ✅ Apollo: ${result.email}`);
        }
      } catch (e) {
        console.error(`  ⚠️ Apollo error: ${e.message}`);
      }
    }
    
    // Build enriched lead
    const enrichedLead = {
      ...lead,
      email: result?.email || null,
      email_source: result?.source || null,
      email_score: result?.score || 0,
      email_verified: result?.verified || false,
      domain: domain,
      enrichment_status: result ? 'success' : 'failed'
    };
    
    if (!result) failed++;
    enrichedLeads.push(enrichedLead);
    
    // Rate limit
    await sleep(300);
  }
  
  const output = {
    meta: {
      total_leads: leads.length,
      enriched: hunterHits + apolloHits,
      hunter_hits: hunterHits,
      apollo_hits: apolloHits,
      failed: failed,
      enriched_at: new Date().toISOString()
    },
    leads: enrichedLeads
  };
  
  console.log(JSON.stringify(output, null, 2));
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
ENRICHER_SCRIPT
)

# Output
if [[ -n "$OUTPUT_FILE" ]]; then
  echo "$RESULT" > "$OUTPUT_FILE"
  log "Saved to: $OUTPUT_FILE"
else
  echo "$RESULT"
fi
