# Lumen — Daily Affirmations — Full Build Specification Pack

**Purpose:** This repository contains a complete, implementation-ready specification for a mobile app similar to *I am – Daily Affirmations* (Monkey Taps), with additional focus on:
- Evidence-aligned, psychologically safe messaging (avoids “toxic positivity” and known pitfalls of generic positive self-statements).
- On-device ML for **background image generation** (and optional on-device personalization), prioritizing privacy.
- Offline-first architecture, with optional cloud sync.

**Audience:** A coding agent / engineering team. This is optimized for direct conversion into backlog items, architecture, schemas, and code.

**Date:** 2026-02-17 (Europe/Madrid assumed for examples)

---

## What’s inside

### Product & UX
- `docs/01_Product_Requirements_Document.md` — product goals, scope, success metrics, competitive notes.
- `docs/02_Functional_Requirements.md` — numbered requirements (FR/NFR) with acceptance criteria.
- `docs/03_UX_Flows_and_Wireframes.md` — screen-by-screen flows, edge cases, navigation model, widgets/watch.
- `docs/04_Content_Design_and_Messaging_Guidelines.md` — tone, safety constraints, writing rules, examples.
- `docs/05_Research_and_Clinical_Safety_Notes.md` — evidence summary & practical design implications.

### Engineering
- `docs/06_Tech_Architecture.md` — iOS-first architecture, modules, dependencies, build targets.
- `docs/07_Data_Model_and_Storage.md` — local DB schema, sync model, migrations, caching.
- `docs/08_Backend_and_API_Spec.md` — optional backend (content delivery + sync) w/ OpenAPI.
- `docs/09_OnDevice_ML_Backgrounds_and_Personalization.md` — Core ML diffusion pipeline + safety.
- `docs/10_Notifications_Widgets_Watch.md` — reminder scheduler, widget timelines, complications.
- `docs/11_Subscriptions_and_Paywall.md` — products, entitlement gating, trial, restore, receipts.
- `docs/12_Privacy_Security_Compliance.md` — GDPR notes, app-store policies, data retention.
- `docs/13_QA_Test_Plan.md` — test matrix, failure modes, performance budgets.
- `docs/14_Analytics_Experiments.md` — events, funnels, A/B tests, guardrails.
- `docs/15_Roadmap_and_Sprints.md` — MVP → v1 → v2 cut-lines and sprint plan.
- `docs/16_Risks_and_Mitigations.md` — safety, ML, policy, and content risks + mitigations.

### Assets & Schemas
- `assets/schemas/*.json` — JSON Schemas for affirmations, categories, content packs, and user prefs.
- `assets/sample_content/*.json` — sample categories + affirmation content.
- `assets/openapi/openapi.yaml` — OpenAPI 3.1 for the optional backend.
- `assets/diagrams/*.mermaid` — architecture + dataflow diagrams (render in Mermaid).
- `assets/copy/*.md` — ready-to-use copy blocks for onboarding, paywall, crisis/help.

### Scripts (optional helper)
- `scripts/validate_content_pack.py` — basic content validation helper (optional for CI).

---

## How a coding agent should use this pack

1. Read in order:
   1) PRD → 2) Functional requirements → 3) UX flows → 6) Architecture → 7) Data model → 9) ML → 10) Notifications → 11) Monetization.
2. Create epics by mapping requirement IDs (e.g., **FR-1.2**) to tickets.
3. Implement the local-first app first (MVP), then add optional backend sync, then ML generation improvements.

---

## Naming & trademark note

This spec intentionally uses the working name **“Lumen”**. Replace with final brand name after trademark search.

---

## Disclaimer

This app is a **wellness** product and must not claim to diagnose, treat, cure, or prevent disease. See `docs/12_Privacy_Security_Compliance.md` and `docs/05_Research_and_Clinical_Safety_Notes.md` for guardrails.
