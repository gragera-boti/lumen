# 12 — Privacy, Security, and Compliance

## 1) Positioning: wellness, not medical
Lumen must be marketed as a **wellness** app:
- No diagnosis, treatment, cure, or prevention claims.
- Avoid “clinically proven to treat depression/anxiety” language.
- If research is referenced, keep it high-level and avoid implying equivalence to therapy.

---

## 2) Data inventory (MVP)

### 2.1 Stored on device
- selected categories, tone
- reminder schedule
- favorites
- seen history (limited)
- generated themes
- custom affirmations (user-authored)

### 2.2 Optional (if analytics enabled)
- app events (screen views, actions)
- performance metrics
**Never send**:
- custom affirmation text
- full history of viewed affirmations
- anything that could be interpreted as health diagnosis data

### 2.3 Optional (if cloud sync enabled)
- favorites
- preferences
- custom affirmations (sensitive; encrypt and clearly disclose)

---

## 3) User controls
- Opt-out of analytics (if analytics present)
- Export data (JSON)
- Delete all data (local reset)
- If cloud sync exists: delete account and server data

---

## 4) Security requirements
- Use Keychain for auth tokens
- TLS for all network calls
- Prefer App Group container with file protection enabled
- Minimize third-party SDKs

---

## 5) AI-generated content compliance

### 5.1 Apple (App Store)
- Follow current App Review Guidelines.
- If generative AI is used, ensure the app does not facilitate objectionable content.
- Provide transparent behavior and user controls.

### 5.2 Google Play (if Android)
Google Play’s AI-generated content policy expects:
- Prevention of prohibited/offensive content
- A way for users to report AI-generated content
- Use feedback to improve filters

**Design requirement:** keep prompts constrained; add reporting UI; implement safety checks.

---

## 6) GDPR (EU/EEA) considerations
Assuming EU users:
- Lawful basis for any analytics (consent if required).
- Clear privacy policy and data retention.
- If user account exists: right of access, deletion, portability.
- Avoid collecting special category data (health) unless strictly necessary and with explicit consent.

---

## 7) “Get help now” / crisis content
- Provide safety resources without collecting location.
- Allow user to select country/region if they want localized numbers.
- Keep copy simple and non-judgmental.

---

## 8) App store metadata checklist
- Privacy policy URL
- Terms of use URL
- Accurate data collection disclosure (App Privacy labels / Data Safety)
- Subscription disclosures
- Age rating appropriate for content

---

## 9) Audit checklist before launch
- [ ] Privacy policy matches actual behavior
- [ ] No unmoderated user-to-user content
- [ ] Generative image prompts are restricted
- [ ] Reporting flow exists (Android required if gen AI shipped)
- [ ] All permissions requested in context
- [ ] No medical claims in screenshots/descriptions
