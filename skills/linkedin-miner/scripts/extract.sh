#!/bin/bash
# linkedin-miner/scripts/extract.sh
# Extract engagers from raw LinkedIn post data

set -e

INPUT_FILE="${1:-/dev/stdin}"
COMMENTS_ONLY="${2:-false}"

# Read input
if [[ "$INPUT_FILE" == "/dev/stdin" ]]; then
  RAW_DATA=$(cat)
else
  RAW_DATA=$(cat "$INPUT_FILE")
fi

# Process with node for complex JSON handling
node << 'EOF' "$RAW_DATA" "$COMMENTS_ONLY"
const data = JSON.parse(process.argv[2]);
const commentsOnly = process.argv[3] === 'true';

const leads = [];
const seen = new Set();

// Process each post
for (const post of data) {
  const postTopic = post.text?.slice(0, 100) || 'Unknown topic';
  const postUrl = post.url || '';
  
  // Extract commenters (highest intent)
  if (post.comments && Array.isArray(post.comments)) {
    for (const comment of post.comments) {
      const author = comment.author;
      if (!author || !author.publicId) continue;
      
      const key = author.publicId;
      if (seen.has(key)) continue;
      seen.add(key);
      
      // Parse company from occupation
      let company = '';
      let title = author.occupation || '';
      if (title.includes(' at ')) {
        const parts = title.split(' at ');
        title = parts[0].trim();
        company = parts.slice(1).join(' at ').trim();
      }
      
      leads.push({
        name: `${author.firstName || ''} ${author.lastName || ''}`.trim(),
        first_name: author.firstName || '',
        last_name: author.lastName || '',
        title: title,
        company: company,
        linkedin_url: `https://linkedin.com/in/${author.publicId}`,
        linkedin_id: author.profileId || '',
        engagement_type: 'comment',
        engagement_text: comment.text?.slice(0, 200) || '',
        post_topic: postTopic,
        post_url: postUrl,
        intent_score: comment.text?.length > 50 ? 10 : (comment.text?.length > 20 ? 8 : 6)
      });
    }
  }
  
  // Extract reactors (lower intent, skip if comments-only)
  if (!commentsOnly && post.reactions && Array.isArray(post.reactions)) {
    for (const reaction of post.reactions) {
      const profile = reaction.profile;
      if (!profile || !profile.publicId) continue;
      
      const key = profile.publicId;
      if (seen.has(key)) continue;
      seen.add(key);
      
      // Parse company from occupation
      let company = '';
      let title = profile.occupation || '';
      if (title.includes(' at ')) {
        const parts = title.split(' at ');
        title = parts[0].trim();
        company = parts.slice(1).join(' at ').trim();
      }
      
      leads.push({
        name: `${profile.firstName || ''} ${profile.lastName || ''}`.trim(),
        first_name: profile.firstName || '',
        last_name: profile.lastName || '',
        title: title,
        company: company,
        linkedin_url: `https://linkedin.com/in/${profile.publicId}`,
        linkedin_id: profile.profileId || '',
        engagement_type: 'reaction',
        engagement_text: reaction.type || 'LIKE',
        post_topic: postTopic,
        post_url: postUrl,
        intent_score: 4
      });
    }
  }
}

// Sort by intent score (highest first)
leads.sort((a, b) => b.intent_score - a.intent_score);

// Output
const output = {
  meta: {
    total_posts: data.length,
    total_leads: leads.length,
    commenters: leads.filter(l => l.engagement_type === 'comment').length,
    reactors: leads.filter(l => l.engagement_type === 'reaction').length,
    extracted_at: new Date().toISOString()
  },
  leads: leads
};

console.log(JSON.stringify(output, null, 2));
EOF
