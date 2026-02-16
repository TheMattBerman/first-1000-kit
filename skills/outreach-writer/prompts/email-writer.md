# Cold Outreach Writer Prompt

Write a personalized cold email for the following lead.

## Lead Context

- **Name:** {{name}}
- **First Name:** {{first_name}}
- **Title:** {{title}}
- **Company:** {{company}}
- **Engagement Type:** {{engagement_type}}
- **Engagement Context:** {{engagement_text}}
- **Post Topic:** {{post_topic}}
- **ICP Score:** {{score}} (Tier {{tier}})

## Our Offer

{{offer_description}}

Default offer if not specified:
> We help marketing teams create AI-generated UGC content at scale — turning product photos into scroll-stopping video ads without the $500/video production cost.

## Voice Guidelines

- Casual but professional
- First-person, conversational
- No corporate speak or buzzwords
- Sound like a real person, not a template
- Short sentences, easy to scan

## Email Framework

### Subject Line
- 3-6 words, all lowercase
- Reference their engagement OR create curiosity
- Examples: "quick thought on [topic]", "your comment on [topic]", "[topic] question"

### First Line
- Reference their SPECIFIC engagement
- Show you actually read what they said
- Make it feel 1:1, not mass email

Templates based on engagement:
- **Comment with insight:** "Your comment on [post] about [their point] got me thinking..."
- **Comment with question:** "Saw your question about [topic] on [post] — actually working on something related..."
- **Simple comment:** "Your take on [topic] resonated — especially [specific word they used]..."
- **Reaction only:** "Noticed you're following the [topic] conversation — curious if [question]..."

### Body
- 2-3 sentences max
- One clear value prop
- Connect to THEIR situation/pain
- Use "you/your" more than "I/we"

### CTA
- Soft, not pushy
- Give them an easy out
- Examples:
  - "Worth exploring?"
  - "Curious if this resonates?"
  - "Any interest in seeing how we're doing this?"
  - "Open to a quick look?"

### Signature
Keep it simple:
```
Best,
{{sender_name}}
```

## Output Format

Generate 3 emails:

```json
{
  "subject": "lowercase subject line here",
  "body": "Full email body with proper line breaks",
  "version": "primary"
}
```

Create 3 versions:
1. **Primary:** Direct reference to their engagement
2. **Curiosity:** Lead with interesting question/insight
3. **Social Proof:** Lead with similar company result

## Follow-Up Sequence

### Email 2 (Day 3)
- Reply to original subject ("re: [subject]")
- Bump up, don't resend
- Add new angle or specificity
- Maintain soft CTA

### Email 3 (Day 7)
- Break-up email
- Give them permission to say no
- Leave door open for future
- Shortest of the three

## Anti-Patterns (Avoid)

❌ "I hope this email finds you well"
❌ "I noticed you're the [title] at [company]"
❌ "I'd love to pick your brain"
❌ "Let me know if you have 15 minutes"
❌ "I think you'd be a great fit"
❌ "Just wanted to reach out"
❌ "I came across your profile"
❌ Any emoji in subject line
❌ ALL CAPS or excessive punctuation

## Example Output

**Subject:** your take on ai ugc

**Body:**
```
Hi Jane,

Your comment on Mike's post about AI automation caught my eye — especially the point about brand consistency being the missing piece.

We've been helping DTC brands solve exactly that — turning one product photo into 20 on-brand UGC videos without the $500/video cost.

Worth a quick look?

Best,
Matt
```
