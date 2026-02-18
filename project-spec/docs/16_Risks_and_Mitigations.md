# 16 — Risks & Mitigations

## 1) Content safety risks

### Risk: “Affirmations feel invalidating”
- Example: chronic illness users see “I’m grateful for my perfect health.”
**Mitigation**
- Sensitive topics opt-in
- Contraindications metadata
- Gentle mode default for low mood
- Dislike suppression + reason capture

### Risk: “Toxic positivity”
**Mitigation**
- Content guidelines enforce realism and self-compassion framing
- Avoid absolutes, “just be positive”
- Include validating language

---

## 2) Regulatory / policy risks

### Risk: App perceived as medical treatment
**Mitigation**
- Wellness disclaimers
- No diagnostic questionnaires
- No clinical claims in marketing

### Risk: Generative AI policy violations
**Mitigation**
- No free-form prompts in MVP
- Safety classifier (P1)
- Reporting UI
- Restrict outputs to non-people scenes (abstract/nature)

---

## 3) ML performance & device variability

### Risk: Generation too slow or battery-heavy
**Mitigation**
- Device gating + tiered parameters
- Cancel button
- Thermal/battery checks
- Offer curated themes as default

### Risk: Model download size
**Mitigation**
- On-demand download
- Wi-Fi only toggle
- Provide deletion and storage estimate

---

## 4) Retention / engagement risks

### Risk: Notifications annoy users
**Mitigation**
- Onboarding asks user preference explicitly
- Quiet hours
- Frequency caps
- Test notification button

---

## 5) Data/privacy risks

### Risk: Logging sensitive behavior
**Mitigation**
- Avoid sending affirmation IDs/content
- Opt-out
- Minimal third-party SDKs

---

## 6) Content ops risks

### Risk: Content quality regressions when updating packs
**Mitigation**
- Content validation pipeline + schema checks
- Editorial QA checklist
- Rollout % with remote config (if backend)
