# 19 — Content Operations (Authoring, QA, Releases)

This document describes how to build and maintain the affirmation library responsibly.

---

## 1) Roles
- **Content Editor (lead):** owns style guide and release decisions.
- **Reviewer (psychology-informed):** checks for harmful messaging and medical claims.
- **Localization partner:** localizes by meaning (not literal translation).
- **Engineer:** runs schema validation and packaging.

---

## 2) Content authoring workflow (recommended)

1. Draft affirmations in a spreadsheet or CMS with columns:
   - id
   - locale
   - text
   - categoryIds
   - tone, intensity, absolute
   - sensitiveTopic, contraindications
   - tags
   - isPremium
2. Run content QA checklist (see `docs/04_*`).
3. Run automated validation:
   - schema validation
   - length checks
   - forbidden phrase checks
4. Human review + sign-off.
5. Build content pack:
   - export `categories.json` and `affirmations.json`
   - generate `meta.json` with checksum
6. Ship:
   - MVP: bundled in app
   - P1: hosted as downloadable pack

---

## 3) Automated checks (high value)
- Max length and line breaks
- Forbidden absolutes in Gentle mode set
- Forbidden medical claims list (regex)
- Sensitive topics flagged properly
- Reading level estimate (optional)

Example forbidden phrases list (expand carefully):
- “cure”, “diagnose”, “treat your depression”
- “stop your medication”
- “guaranteed”
- “always”, “never” (soft rule; allow rare exceptions)

---

## 4) Localization strategy
- Keep a master locale (en-GB).
- Localizers should adapt:
  - idioms
  - cultural references
  - formality level
- Keep affirmations short; avoid complex grammar for accessibility.
- Add per-locale contraindications if needed.

---

## 5) Sensitive content policy
Sensitive topics (grief, illness) require:
- explicit opt-in setting
- gentler copy
- strict avoidance of platitudes

---

## 6) Content updates & rollback
If remote content packs are used:
- Support staged rollout (e.g., 10% → 50% → 100%)
- If crash rate increases or complaints spike:
  - rollback to previous pack
  - preserve user favorites by stable IDs

---

## 7) Legal/policy considerations
- Do not copy content from copyrighted sources.
- Curate original text, or ensure proper licensing.
- Avoid misrepresenting research (no “clinically proven” unless true and supported).
