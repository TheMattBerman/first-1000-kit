#!/bin/bash
# instantly-loader/scripts/load.sh
# Load leads and sequences into Instantly.ai

set -e

# Config
INSTANTLY_API_KEY="${INSTANTLY_API_KEY:-}"
DRY_RUN="${DRY_RUN:-false}"
BASE_URL="https://api.instantly.ai/api/v1"

# Parse args
INPUT_FILE=""
CAMPAIGN_ID=""
CAMPAIGN_NAME=""
CREATE_CAMPAIGN="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    --campaign)
      CAMPAIGN_ID="$2"
      shift 2
      ;;
    --create-campaign)
      CREATE_CAMPAIGN="true"
      CAMPAIGN_NAME="$2"
      shift 2
      ;;
    *)
      INPUT_FILE="$1"
      shift
      ;;
  esac
done

INPUT_FILE="${INPUT_FILE:-/dev/stdin}"

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# Check API key
if [[ -z "$INSTANTLY_API_KEY" ]]; then
  log "Error: INSTANTLY_API_KEY not set"
  exit 1
fi

# Read input
if [[ "$INPUT_FILE" == "/dev/stdin" ]]; then
  INPUT_DATA=$(cat)
else
  INPUT_DATA=$(cat "$INPUT_FILE")
fi

# Create campaign if requested
if [[ "$CREATE_CAMPAIGN" == "true" && -n "$CAMPAIGN_NAME" ]]; then
  log "Creating campaign: $CAMPAIGN_NAME"
  
  CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/campaign/create" \
    -H "Content-Type: application/json" \
    -d "{
      \"api_key\": \"$INSTANTLY_API_KEY\",
      \"name\": \"$CAMPAIGN_NAME\",
      \"daily_limit\": 50
    }")
  
  CAMPAIGN_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id // empty')
  
  if [[ -z "$CAMPAIGN_ID" ]]; then
    log "Error creating campaign:"
    echo "$CREATE_RESPONSE" | jq . >&2
    exit 1
  fi
  
  log "Created campaign: $CAMPAIGN_ID"
fi

# Require campaign ID
if [[ -z "$CAMPAIGN_ID" ]]; then
  log "Error: No campaign specified. Use --campaign ID or --create-campaign NAME"
  exit 1
fi

# Load leads using Node.js
node -e '
const https = require("https");
const inputData = JSON.parse(process.argv[1]);
const apiKey = process.argv[2];
const campaignId = process.argv[3];
const dryRun = process.argv[4] === "true";

// Handle both formats
const items = inputData.emails || inputData.leads || inputData;

console.error(`[${new Date().toTimeString().slice(0,8)}] Preparing ${items.length} leads for upload...`);

// Format leads for Instantly
const leads = items.map(item => {
  const lead = item.lead || item;
  const sequence = item.sequence || [];
  
  // Parse name
  const nameParts = (lead.name || "").split(" ");
  const firstName = nameParts[0] || "";
  const lastName = nameParts.slice(1).join(" ") || "";
  
  // Build custom variables
  const customVars = {
    linkedin_url: lead.linkedin_url || "",
    tier: lead.tier || "",
    company: lead.company || ""
  };
  
  // Add sequence steps as custom vars
  sequence.forEach((step, i) => {
    customVars[`subject_${i+1}`] = step.subject || "";
    customVars[`body_${i+1}`] = step.body || "";
  });
  
  // Extract first line for personalization field
  const firstBody = sequence[0]?.body || "";
  const lines = firstBody.split("\n").filter(l => l.trim());
  const personalization = lines.slice(1, 3).join(" ").slice(0, 200);
  
  return {
    email: lead.email,
    first_name: firstName,
    last_name: lastName,
    company_name: lead.company || "",
    personalization: personalization,
    custom_variables: customVars
  };
}).filter(l => l.email);

console.error(`[${new Date().toTimeString().slice(0,8)}] ${leads.length} leads ready`);

if (dryRun) {
  console.error("[DRY RUN] Would upload:");
  leads.slice(0, 3).forEach(l => {
    console.error(`  - ${l.email} (${l.first_name} ${l.last_name})`);
  });
  if (leads.length > 3) {
    console.error(`  ... and ${leads.length - 3} more`);
  }
  
  console.log(JSON.stringify({
    meta: {
      dry_run: true,
      campaign_id: campaignId,
      leads_would_upload: leads.length
    },
    sample_leads: leads.slice(0, 3)
  }, null, 2));
  process.exit(0);
}

// Upload to Instantly
function uploadLeads(leads) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      api_key: apiKey,
      campaign_id: campaignId,
      skip_if_in_workspace: true,
      leads: leads
    });
    
    const options = {
      hostname: "api.instantly.ai",
      path: "/api/v1/lead/add",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(data)
      }
    };
    
    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", chunk => body += chunk);
      res.on("end", () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          resolve({ error: body });
        }
      });
    });
    
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

async function main() {
  // Upload in batches of 100
  const batchSize = 100;
  const results = { success: [], skipped: [], failed: [] };
  
  for (let i = 0; i < leads.length; i += batchSize) {
    const batch = leads.slice(i, i + batchSize);
    console.error(`[${new Date().toTimeString().slice(0,8)}] Uploading batch ${Math.floor(i/batchSize) + 1}/${Math.ceil(leads.length/batchSize)}...`);
    
    try {
      const response = await uploadLeads(batch);
      
      if (response.status === "success" || response.leads_uploaded) {
        batch.forEach(l => results.success.push(l.email));
        console.error(`  ✅ Uploaded ${batch.length} leads`);
      } else if (response.error) {
        batch.forEach(l => results.failed.push(l.email));
        console.error(`  ❌ Error: ${JSON.stringify(response)}`);
      } else {
        // Partial success
        const uploaded = response.leads_uploaded || 0;
        const skipped = response.leads_skipped || 0;
        console.error(`  ⚠️ Uploaded: ${uploaded}, Skipped: ${skipped}`);
      }
    } catch (e) {
      batch.forEach(l => results.failed.push(l.email));
      console.error(`  ❌ Error: ${e.message}`);
    }
  }
  
  console.error(`[${new Date().toTimeString().slice(0,8)}] Done. Success: ${results.success.length}, Failed: ${results.failed.length}`);
  
  console.log(JSON.stringify({
    meta: {
      campaign_id: campaignId,
      leads_uploaded: results.success.length,
      leads_skipped: results.skipped.length,
      leads_failed: results.failed.length,
      loaded_at: new Date().toISOString()
    },
    results: results
  }, null, 2));
}

main().catch(e => {
  console.error("Fatal error:", e);
  process.exit(1);
});
' "$INPUT_DATA" "$INSTANTLY_API_KEY" "$CAMPAIGN_ID" "$DRY_RUN"
