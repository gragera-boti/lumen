# 04 — Content Design & Messaging Guidelines (Evidence-Aligned)

This document defines rules for affirmation text, tips, and any user-facing mental-health adjacent messaging.

> **Principle:** The app is a *wellness tool*, not therapy. Content must be supportive, not prescriptive, and must avoid medical claims.

---

## 1) Core messaging principles

### 1.1 Be kind, not commanding
- Prefer: “You can…” “It might help to…” “One small step…”
- Avoid: “You must…” “You should…” “Just think positive…”

### 1.2 Prefer realism over intensity
Research suggests some “positive self-statements” can be unhelpful or even iatrogenic for people with low self-esteem when they strongly contradict self-view.  
**Design implication:** default to *believable* statements; offer “gentle mode”; avoid forced repetition.

### 1.3 Use self-compassion framing
Self-compassion is typically defined by self-kindness, common humanity, and mindfulness.  
**Design implication:** affirmations can include “It’s okay to struggle” + “I’m not alone” + “I can be kind to myself.”

### 1.4 Avoid toxic positivity
- Avoid invalidating pain: “Everything happens for a reason”, “Just be grateful.”
- If gratitude content exists, include balanced framing: “Even in hard times, I can notice one small good thing.”

### 1.5 Avoid medical or therapeutic claims
- Do not claim to treat depression/anxiety/PTSD.
- Do not prescribe medication changes, supplements, or medical advice.
- Avoid “cure”, “heal”, “fix your trauma” language.

### 1.6 Respect diversity & inclusion
- Avoid gender assumptions.
- Avoid body shaming or weight loss as “value”.
- Allow content filters:
  - Spiritual language (opt-in)
  - Manifestation language (opt-in)
  - Body/fitness content (opt-in)
  - Sensitive topics (opt-in)

---

## 2) Content taxonomy & metadata requirements

Each affirmation must include metadata so the app can filter and personalize safely.

### 2.1 Required fields (curated content)
- `id` (stable UUID)
- `text`
- `locale`
- `categoryIds[]`
- `tags[]` (short, controlled vocabulary)
- `tone` ∈ {GENTLE, NEUTRAL, ENERGETIC, SPIRITUAL}
- `intensity` ∈ {LOW, MEDIUM, HIGH}
- `absolute` ∈ {true,false}  (true = “I always…”, “Nothing can…”)
- `sensitiveTopic` ∈ {true,false}
- `contraindications[]` (e.g., {“CHRONIC_ILLNESS”} if it references perfect health)
- `readingLevel` (approx: 4–8 for accessibility)

### 2.2 Controlled tags (examples)
- EMOTIONS: calm, hope, self_trust, resilience
- CONTEXT: work, relationships, sleep, boundaries
- STYLE: mindfulness, values, gratitude, self_compassion
- AVOIDANCE: body_focus, health_gratitude, religious

---

## 3) Writing rules (do/don’t)

### 3.1 “Believable” ladder
Provide 3 variants where possible:

- **Gentle:** “I’m doing the best I can with what I have today.”
- **Neutral:** “I can take one helpful step today.”
- **Energetic:** “I’m ready to take action on what matters to me today.”

Do not ship only “Energetic” variants.

### 3.2 Prefer process and agency
- Prefer: “I can practice…”, “I’m learning…”
- Avoid: “I am perfect”, “I am unstoppable”

### 3.3 Avoid moralizing
- Avoid: “I should be grateful”, “I must forgive”
- Prefer: “I can explore forgiveness when I’m ready”

### 3.4 Avoid comparative worth
- Avoid: “I’m better than others”
- Prefer: “I have my own strengths”

### 3.5 Avoid references to severe topics unless user opts in
Examples of sensitive topics:
- Grief, chronic illness, trauma, abuse, addiction, suicide
Default should exclude these unless user opts in.

---

## 4) Special populations / contexts (guardrails)

### 4.1 Chronic illness / disability
Avoid statements that imply:
- guaranteed health improvement
- “my body is perfect/healthy”
- shame for limitations

Preferred:
- “I can be gentle with my body today.”
- “I can ask for the support I deserve.”

### 4.2 Grief
Avoid:
- “Everything happens for a reason.”
Preferred:
- “My feelings are valid. I can grieve in my own way.”

### 4.3 Anxiety / panic
Avoid:
- “There is nothing to worry about.”
Preferred:
- “I can take one slow breath right now.”

### 4.4 Work stress / burnout
Avoid:
- “I must hustle.”
Preferred:
- “Rest is part of my productivity.”

---

## 5) Micro-tips (optional, safe “helpful prompts”)

**Rule:** Tips must be low-risk, general, and optional. No diagnosis language.

Examples:
- “Try a 10-second pause: inhale 4, exhale 6.”
- “Name one thing you can control in the next hour.”
- “If this feels hard, choose the gentlest version.”

Avoid:
- “If you’re depressed, do X.”
- “This will cure anxiety.”

---

## 6) Crisis / safety messaging

### 6.1 When to show
- On first run (link)
- Settings (always visible)
- If user searches for self-harm terms (P2)
- If user repeatedly chooses “Low mood” (P1)

### 6.2 Copy guidelines
- Calm, direct, non-alarming.
- Encourage contacting local emergency services and trusted people.
- Provide “I’m not in crisis” dismiss option.

---

## 7) Content QA checklist (for editors)
- [ ] No promises of guaranteed outcomes.
- [ ] No medical advice or treatment claims.
- [ ] No shaming/invalidating language.
- [ ] Text length fits on smallest device with Large Text.
- [ ] Tags and contraindications set correctly.
- [ ] Gentle variant exists for high-intensity domains.

---

## 8) Examples library (ready to seed content)

### Self-love (Gentle)
- “I deserve kindness, especially from myself.”
- “I can speak to myself like I would to a friend.”
- “I don’t have to earn rest.”

### Calm / anxiety
- “I can return to my breath, one inhale at a time.”
- “This feeling is uncomfortable, not dangerous.”
- “I can take the next right step.”

### Confidence
- “I can do hard things in small steps.”
- “I’m allowed to learn as I go.”
- “I trust myself to adapt.”

### Boundaries
- “It’s okay to say no.”
- “My needs matter too.”
- “I can choose what I engage with.”

### Sleep wind-down
- “I can let today be done.”
- “Rest is safe and allowed.”
- “My body knows how to relax.”

---

## 9) Handling user-generated affirmations
- Allow users to write anything for themselves, but:
  - Provide gentle warnings if they include self-harming content (P2) and route to crisis screen.
  - Do not upload custom affirmation text to analytics.
  - If cloud sync exists, encrypt in transit and at rest; disclose in privacy policy.

---

## 10) Localization notes
- Localize by meaning, not word-for-word.
- Maintain reading level target.
- Avoid idioms that don’t translate.
