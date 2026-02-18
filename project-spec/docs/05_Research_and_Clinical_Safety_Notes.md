# 05 — Research and Clinical Safety Notes (for Product + Content)

This document summarizes the evidence used to shape messaging and safety design and provides a **reference list** so content/design decisions can be audited.

> **Important:** This is not medical advice. It is a product design interpretation of published research and professional frameworks.

---

## 1) Key distinction: self-affirmation interventions vs “positive self-statements”

### 1.1 Self-affirmation theory
Self-affirmation theory (Steele, 1988) proposes that people are motivated to maintain self-integrity. When threatened, reflecting on important values can reduce defensiveness and buffer stress.

**Design implications**
- “Values reflection” exercises align more closely with the classic literature than repeating generic positive claims.
- Lumen includes (P1) an optional “Values reflection” mini-exercise (2–3 minutes, once a week) that:
  - lets users choose values that matter (e.g., kindness, growth, family)
  - prompts them to write 2–3 sentences about why that value matters
  - stores text locally by default

### 1.2 Meta-analysis: self-affirmation interventions & well-being
A recent APA meta-analysis synthesized **129 independent tests** from **67 published articles** on self-affirmation interventions and well-being in nonclinical/general populations.

**Design implications**
- Effects are generally **modest** and heterogeneous.
- Lumen must avoid overclaiming (“will rewire your brain” as certainty). Prefer “may help” language.
- Product should include:
  - optional, brief reflection prompts (values-based)
  - a wide range of “believable” affirmation intensities

---

## 2) Evidence on backfire effects for strong positive self-statements

A well-cited line of research found that repeating strong positive self-statements can worsen mood for individuals with low self-esteem when statements conflict with self-view.

**Design implications**
- Provide **Gentle mode** (default ON).
- Prefer believable, process-oriented statements (“I’m learning”, “I can take one step”) rather than absolute identity claims.
- Include a “Not for me” action that suppresses content for ≥ 90 days.
- Tag content with `absolute=true` and `intensity=HIGH` to support filtering.

---

## 3) Self-compassion as a safer foundation for “hard days”

A 2023 meta-analysis of randomized controlled trials suggests self-compassion-focused interventions can reduce depressive symptoms, anxiety, and stress (effects vary and overall risk of bias can be high depending on included trials).

**Design implications**
- Add a **Self-compassion** tag and category content.
- Keep claims cautious and avoid positioning as treatment.
- Use “common humanity” language that reduces shame and isolation.

---

## 4) Mental health app evaluation frameworks (relevant even for wellness)

Even as a wellness app, Lumen touches mental well-being. Use established evaluation frameworks to reduce risk.

### 4.1 APA App Evaluation Model
The American Psychiatric Association’s model provides a structured way to evaluate apps: access, privacy & security, clinical foundation, usability, and data integration.

**Design implications**
- Clear privacy policy and data practices summary in-app
- Crisis/help resources are prominent and always accessible
- Transparent limitations: no diagnosis, no treatment

### 4.2 AHRQ evaluation approaches
AHRQ protocols emphasize transparency and careful evaluation of interventions, including risk classification and evidence standards.

**Design implications**
- Provide content governance and QA process.
- Offer user reporting and correction path.

---

## 5) NICE depression guideline context (do not overreach)
NICE NG222 describes treatment and management for depression in adults. Lumen should:
- Avoid presenting itself as a recommended depression treatment.
- Encourage professional support if symptoms are severe or persistent.

---

## 6) On-device generative AI safety/policy (background generation)

### 6.1 Apple / Core ML diffusion
Apple has published an ML Research post and open-source tooling for deploying Stable Diffusion with Core ML.

**Design implications**
- Use Apple’s tooling to run image generation on-device.
- Prefer on-demand model download to reduce app size.

### 6.2 Google Play AI-generated content policy (if Android)
Google Play expects generative AI apps to prevent restricted content and provide reporting mechanisms.

**Design implications**
- Restrict prompts and styles (MVP).
- Provide “Report generated image” UI.
- Implement safety checks, especially if free-form prompts are added later.

---

## 7) Practical “safety by design” outcomes in Lumen (what we implement)

- **Gentle mode** defaults and filters.
- **Sensitive topics opt-in** (grief/illness/trauma).
- **Dislike suppression** + reason capture.
- **No diagnosis/treatment language**.
- **Crisis resources** always accessible.
- **No free-form prompts** for image generation in MVP.
- **No uploading of user content by default**.

---

## 8) References & links (primary sources preferred)

### 8.1 Self-affirmation theory & interventions
- Steele, C. M. (1988). *The psychology of self-affirmation: Sustaining the integrity of the self.* (Advances in Experimental Social Psychology).
- Zhang, Y., et al. (2025). *The Impact of Self-Affirmation Interventions on Well-Being: A Meta-Analysis.* American Psychologist. DOI: **10.1037/amp0001591** (PDF: https://www.apa.org/pubs/journals/releases/amp-amp0001591.pdf)

### 8.2 Backfire effects for positive self-statements
- Wood, J. V., Perunovic, W. Q. E., & Lee, J. W. (2009). *Positive Self-Statements: Power for Some, Peril for Others.* Psychological Science, 20, 860–866.

### 8.3 Self-compassion interventions
- Han, A., & Kim, T. H. (2023). *Effects of Self-Compassion Interventions on Reducing Depressive Symptoms, Anxiety, and Stress: A Meta-Analysis.* Mindfulness. DOI: **10.1007/s12671-023-02148-x** (PDF: https://link.springer.com/content/pdf/10.1007/s12671-023-02148-x.pdf)

### 8.4 App evaluation frameworks & guidelines
- American Psychiatric Association — App Evaluation Model: https://www.psychiatry.org/psychiatrists/practice/mental-health-apps/the-app-evaluation-model
- AHRQ — Mental Health Apps Evaluation Protocol: https://effectivehealthcare.ahrq.gov/products/mental-health-apps/protocol
- NICE NG222 — Depression in adults: treatment and management: https://www.nice.org.uk/guidance/ng222

### 8.5 Generative AI policies & tooling
- Apple ML Research — Stable Diffusion with Core ML on Apple Silicon: https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon
- GitHub — apple/ml-stable-diffusion: https://github.com/apple/ml-stable-diffusion
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Google Play — AI-Generated Content policy: https://support.google.com/googleplay/android-developer/answer/14094294
