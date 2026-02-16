#!/bin/bash
# email-verifier/scripts/verify.sh
# Verify emails using Hunter.io before sending

set -e

# Config
HUNTER_API_KEY="${HUNTER_API_KEY:-}"
STRICT="${STRICT:-false}"  # If true, reject accept_all emails

# Args
INPUT_FILE="${1:-/dev/stdin}"

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# Check for single email mode
if [[ "$1" == "--email" ]]; then
  EMAIL="$2"
  if [[ -z "$HUNTER_API_KEY" ]]; then
    echo "Error: HUNTER_API_KEY not set" >&2
    exit 1
  fi
  
  RESULT=$(curl -s "https://api.hunter.io/v2/email-verifier?email=$EMAIL&api_key=$HUNTER_API_KEY")
  echo "$RESULT" | jq '{
    email: .data.email,
    status: .data.status,
    result: .data.result,
    score: .data.score,
    safe_to_send: (.data.status == "valid" or .data.status == "accept_all")
  }'
  exit 0
fi

# Read input
if [[ "$INPUT_FILE" == "/dev/stdin" ]]; then
  INPUT_DATA=$(cat)
else
  INPUT_DATA=$(cat "$INPUT_FILE")
fi

# Check for API key
if [[ -z "$HUNTER_API_KEY" ]]; then
  log "Warning: HUNTER_API_KEY not set. Passing through without verification."
  echo "$INPUT_DATA"
  exit 0
fi

# Verify using Node.js
node -e '
const https = require("https");
const inputData = JSON.parse(process.argv[1]);
const apiKey = process.argv[2];
const strict = process.argv[3] === "true";

// Handle both formats: {leads: [...]} or {emails: [...]}
let items = inputData.leads || inputData.emails || inputData;
const isEmailFormat = !!inputData.emails;

// Extract emails to verify
const toVerify = items.map((item, idx) => ({
  idx,
  email: isEmailFormat ? item.lead?.email : item.email,
  item
})).filter(x => x.email);

console.error(`[${new Date().toTimeString().slice(0,8)}] Verifying ${toVerify.length} emails...`);

// Hunter API call
function verifyEmail(email) {
  return new Promise((resolve) => {
    const url = `https://api.hunter.io/v2/email-verifier?email=${encodeURIComponent(email)}&api_key=${apiKey}`;
    
    https.get(url, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try {
          const result = JSON.parse(data);
          resolve(result.data || { status: "error" });
        } catch (e) {
          resolve({ status: "error", error: e.message });
        }
      });
    }).on("error", (e) => {
      resolve({ status: "error", error: e.message });
    });
  });
}

// Sleep helper
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  const stats = {
    total: toVerify.length,
    valid: 0,
    accept_all: 0,
    invalid: 0,
    disposable: 0,
    unknown: 0,
    skipped: items.length - toVerify.length
  };
  
  const verifiedItems = [];
  
  for (let i = 0; i < toVerify.length; i++) {
    const { idx, email, item } = toVerify[i];
    
    console.error(`[${new Date().toTimeString().slice(0,8)}] [${i+1}/${toVerify.length}] ${email}`);
    
    const result = await verifyEmail(email);
    
    // Determine if safe to send
    let safeToSend = false;
    let status = result.status || "unknown";
    
    if (status === "valid") {
      safeToSend = true;
      stats.valid++;
      console.error(`  ✅ Valid (score: ${result.score})`);
    } else if (status === "accept_all") {
      safeToSend = !strict;
      stats.accept_all++;
      console.error(`  ⚠️ Accept-all ${strict ? "(rejected)" : "(risky but sending)"}`);
    } else if (result.disposable) {
      status = "disposable";
      stats.disposable++;
      console.error(`  ❌ Disposable`);
    } else if (status === "invalid") {
      stats.invalid++;
      console.error(`  ❌ Invalid`);
    } else {
      stats.unknown++;
      safeToSend = true; // Send unknown, but flag
      console.error(`  ⚠️ Unknown`);
    }
    
    // Update item with verification results
    if (isEmailFormat) {
      item.lead.email_status = status;
      item.lead.email_score = result.score || 0;
      item.lead.safe_to_send = safeToSend;
    } else {
      item.email_status = status;
      item.email_score = result.score || 0;
      item.safe_to_send = safeToSend;
    }
    
    if (safeToSend) {
      verifiedItems.push(item);
    }
    
    // Rate limit
    await sleep(250);
  }
  
  console.error(`[${new Date().toTimeString().slice(0,8)}] Done. ${verifiedItems.length} safe to send.`);
  
  // Output
  const output = {
    meta: {
      ...stats,
      passed: verifiedItems.length,
      verified_at: new Date().toISOString()
    }
  };
  
  if (isEmailFormat) {
    output.emails = verifiedItems;
  } else {
    output.leads = verifiedItems;
  }
  
  console.log(JSON.stringify(output, null, 2));
}

main().catch(e => {
  console.error("Error:", e);
  process.exit(1);
});
' "$INPUT_DATA" "$HUNTER_API_KEY" "$STRICT"
