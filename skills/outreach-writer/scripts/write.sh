#!/bin/bash
# outreach-writer/scripts/write.sh
# Generate personalized cold email sequences for scored leads

set -e

# Config
TIER_FILTER="${TIER_FILTER:-AB}"
SENDER_NAME="${SENDER_NAME:-Matt}"

# Args
INPUT_FILE="${1:-/dev/stdin}"

log() {
  echo "[$(date '+%H:%M:%S')] $1" >&2
}

# Read input
if [[ "$INPUT_FILE" == "/dev/stdin" ]]; then
  INPUT_DATA=$(cat)
else
  INPUT_DATA=$(cat "$INPUT_FILE")
fi

# Generate emails with Node.js
node -e '
const inputData = JSON.parse(process.argv[1]);
const tierFilter = process.argv[2] || "AB";
const senderName = process.argv[3] || "Matt";

const leads = inputData.leads || inputData;

// Filter by tier
const filteredLeads = leads.filter(lead => {
  if (tierFilter === "ALL") return true;
  return tierFilter.includes(lead.tier);
});

console.error(`[${new Date().toTimeString().slice(0,8)}] Processing ${filteredLeads.length} leads (tiers: ${tierFilter})`);

function generateEmail(lead) {
  const firstName = lead.name?.split(" ")[0] || "there";
  const company = lead.company || extractCompany(lead.headline);
  const topic = extractTopic(lead.engagement_text, lead.headline);
  const isComment = lead.engagement_type === "comment";
  const hasEngagement = isComment && lead.engagement_text && lead.engagement_text.length > 20;
  
  // Detect their role for context
  const h = (lead.headline || "").toLowerCase();
  const isFounder = h.includes("founder") || h.includes("ceo") || h.includes("owner");
  const isAgency = h.includes("agency") || h.includes("consultant");
  const isMarketing = h.includes("marketing") || h.includes("growth") || h.includes("vp");
  
  // Generate based on tier and context
  let email1, email2, email3;
  let subject;
  
  if (lead.tier === "A" && hasEngagement) {
    // A-tier with comment: highly personalized
    const insight = extractInsight(lead.engagement_text);
    subject = topic.toLowerCase();
    
    if (isFounder || isAgency) {
      email1 = `${firstName},

Your take on ${topic} is exactly how we think about outbound.

Let AI do the mining and the math. Let humans do the talking.

Built a system around that. $30/month. Works pretty well.

Want the playbook?

${senderName}`;
    } else {
      email1 = `${firstName},

${insight}

We\x27ve been running an experiment. AI handles prospecting and first-draft outreach, humans handle everything after the reply.

62x cheaper than hiring. Surprisingly not terrible.

Would you want to compare notes?

${senderName}`;
    }
    
    email2 = `${firstName},

Quick follow-up on the ${topic} thing.

Put together a short walkthrough of how the system works. Might save you some trial and error.

Want me to send it over?

${senderName}`;

    email3 = `${firstName},

No worries if timing is off.

If outbound ever becomes a bottleneck${company ? " at " + company : ""}, happy to share what we\x27ve figured out.

${senderName}`;

  } else if (lead.tier === "B" || (lead.tier === "A" && !hasEngagement)) {
    // B-tier or A without good comment: moderate personalization
    subject = company ? `${company.toLowerCase()} + ${topic}` : topic;
    
    email1 = `${firstName},

Saw your work on ${topic}. Good stuff.

We built a GTM system that finds prospects, scores them, and writes personalized outreach. Runs for about $30/month after setup.

Curious if this is on your radar?

${senderName}`;

    email2 = `${firstName},

Following up. Put together a 2-min walkthrough of how the system works.

${isFounder ? "Built it for founders who\x27d rather not hire a sales team yet." : "Might be useful if you\x27re looking to scale outbound without adding headcount."}

Worth a look?

${senderName}`;

    email3 = `${firstName},

Last note from me.

If lead gen ever becomes a priority, the offer stands.

${senderName}`;

  } else {
    // C-tier: light personalization
    subject = `quick question`;
    
    email1 = `${firstName},

We built a system that automates prospecting and outreach. AI does the legwork, you take the calls.

Running it for about $30/month.

Would this be useful for ${company || "what you\x27re building"}?

${senderName}`;

    email2 = `${firstName},

Quick follow-up. Happy to share how the system works if it\x27s relevant.

${senderName}`;

    email3 = `${firstName},

Closing the loop. Here if you ever want to chat about automating outbound.

${senderName}`;
  }
  
  return {
    lead: {
      name: lead.name,
      email: lead.email || null,
      company: company,
      linkedin_url: lead.linkedin_url,
      tier: lead.tier,
      icp_score: lead.icp_score
    },
    sequence: [
      { step: 1, delay_days: 0, subject: subject, body: email1 },
      { step: 2, delay_days: 3, subject: `re: ${subject}`, body: email2 },
      { step: 3, delay_days: 7, subject: `re: ${subject}`, body: email3 }
    ],
    personalization_notes: hasEngagement 
      ? `A-tier. Referenced their ${topic} comment. ${isFounder ? "Founder angle." : isAgency ? "Agency angle." : "Marketing angle."}`
      : `${lead.tier}-tier. Topic: ${topic}. ${company ? "Company: " + company : "No company detected."}`
  };
}

function extractCompany(headline) {
  if (!headline) return null;
  const atMatch = headline.match(/(?:at|@)\s+([A-Za-z0-9\-]+)/i);
  if (atMatch) return atMatch[1];
  const pipeMatch = headline.match(/^([A-Za-z0-9\-]+)\s*\|/);
  if (pipeMatch) return pipeMatch[1];
  return null;
}

function extractTopic(engagementText, headline) {
  const text = (engagementText || headline || "").toLowerCase();
  
  const topics = [
    { pattern: /ai\s*(marketing|automation|vs|versus)/i, label: "AI" },
    { pattern: /automation/i, label: "automation" },
    { pattern: /marketing/i, label: "marketing" },
    { pattern: /growth/i, label: "growth" },
    { pattern: /outreach|cold\s*email/i, label: "outreach" },
    { pattern: /lead\s*gen|prospecting/i, label: "lead gen" },
    { pattern: /agency|agencies/i, label: "agency growth" },
    { pattern: /saas/i, label: "SaaS" },
    { pattern: /scale|scaling/i, label: "scaling" }
  ];
  
  for (const t of topics) {
    if (t.pattern.test(text)) return t.label;
  }
  
  return "AI marketing";
}

function extractInsight(text) {
  if (!text) return "Your take resonated.";
  
  // Try to find a quotable phrase
  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 10);
  if (sentences.length > 0) {
    const best = sentences[0].trim();
    if (best.length < 60) {
      return `"${best}" ... that resonated.`;
    } else if (best.length < 100) {
      return `Your point about ${best.slice(0, 50).trim()}... that stuck with me.`;
    }
  }
  
  // Fallback
  return "That comment stuck with me.";
}

// Generate all emails
const emails = filteredLeads.map(generateEmail);

// Count tiers
const tierCounts = { A: 0, B: 0, C: 0, D: 0 };
emails.forEach(e => tierCounts[e.lead.tier]++);

console.error(`[${new Date().toTimeString().slice(0,8)}] Generated ${emails.length} email sequences`);

console.log(JSON.stringify({
  meta: {
    total_emails: emails.length,
    tier_a: tierCounts.A,
    tier_b: tierCounts.B,
    tier_c: tierCounts.C,
    tier_d: tierCounts.D,
    generated_at: new Date().toISOString()
  },
  emails: emails
}, null, 2));
' "$INPUT_DATA" "$TIER_FILTER" "$SENDER_NAME"
