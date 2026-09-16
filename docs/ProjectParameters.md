# Project Parameters

**This block is the single source of truth** for every name, ID, version, prefix, namespace, and
quoting decision in this project. Nothing in AL code hardcodes a value that belongs here — always
derive it from this file. Confirmed by AJ Ansari on 2026-09-16.

## 1.1 Extension Identity

| Parameter | Value |
|---|---|
| Extension Name | BBB Rating Insights |
| Publisher | onlyCopilotFans |
| Deployment Target | SaaS PTE |
| Use Namespace | Yes |
| Namespace | OnlyCopilotFans.BBBInsights |
| Localization | US |
| Approvers | One person (AJ Ansari — Functional Consultant / Technical Lead / Dev Manager) |

## 1.2 Object ID Allocation

| Block | From | To | Notes |
|---|---|---|---|
| Primary allocation | 50601 | 50620 | 20 IDs. Expanded from an original 50611–50620 (10 IDs) once a rough object count showed zero growth buffer (Standards §5.2). |

| Parameter | Value |
|---|---|
| Permission Sets required? | Yes — this project owns a table (BBB Fetch Log); reserve ≥ 2 IDs for permission sets (Standards §5.3). |

## 1.3 Naming & API Parameters

| Parameter | Value |
|---|---|
| AL Object Prefix | `ocpfBbb` |
| APIPublisher | `'onlyCopilotFans'` |
| APIGroup Prefix | `ocpfBbb` |
| APIVersion | `'v1.0'` |
| Namespace | `OnlyCopilotFans.BBBInsights` (same as §1.1) |
| Permission Set App Code | `BBBRI` |
| Permission Set Names | `OCPFBBB BBBRI, VIEW` (19 chars) / `OCPFBBB BBBRI, EDIT` (19 chars) |

## 1.4 Platform & Runtime

| Parameter | Value |
|---|---|
| AL Runtime | 16.0 |
| BC Application Minimum | 27.0.0.0 *(unverified against a live source — Microsoft Learn was unreachable from this session; confirm against your actual sandbox at project setup)* |
| Recommended BC Version | 27.5+ *(same caveat)* |
| Symbol Source | To be filled in at §1.10 project setup, once symbols are downloaded. |

## 1.5 Feature Flags (Fixed)

`NoImplicitWith` — **Enabled (enforced)**, per every project this framework builds.

## 1.6 Onboarding & Discoverability

| Parameter | Value |
|---|---|
| Assisted Setup Wizard | No — no Setup table or configuration exists to walk through. |
| Activity Cues | No |
| Departments / My Business Central placement | No |

## 1.7 Model & Effort Assignment

| Role | Model | Thinking Effort |
|---|---|---|
| Main (code edits, continuity documents) | Sonnet 5 (`claude-sonnet-5`) | High |
| Light (post-generation checklist, symbol verification) | Haiku 4.5 (`claude-haiku-4-5-20251001`) | High |
| Reasoning (FRD/TDD authorship, Sanity Check, Gap-Fit, Code Review, diagnosis) | Opus 5 (`claude-opus-5`) | High |

No OCPF plugin is installed in this session, so Light/Reasoning delegation uses the general
Agent tool with an explicit model override rather than the `ocpf-light`/`ocpf-reasoning`
sub-agents.

## 1.8 Framework File Tracking

`.gitignore` excludes this runbook (`CLAUDE.md`... *actually tracked, see note*), `standardsGuide/`,
`opsGuide/`, and `.ocpf/` (except `.ocpf/notifications.json`, which is always excluded). **Note:**
`CLAUDE.md` itself was committed to the repository in an earlier session before this framework's
own §1.8 question was asked; it is left tracked rather than retroactively removed, since removing
project instructions the user already committed is not this step's call to make unilaterally.

## 1.9 Languages & Translation

| Parameter | Value |
|---|---|
| Working language | English |
| Target languages | None beyond source — US and Canada both served in English only (see ChangeLog DEFINE-002). |
| Source language | en-US |
| Source wording | US wording directly in source, no translation files |
| Document languages | N/A — no additional-language documents |
| Customer-language documents | No — no customer-facing documents (invoices/emails) are in this project's scope |
| Translatable data | No — BBB Grade/Accreditation/Complaint Count are structured reference data, not user-authored translatable text |
| Translation tooling | N/A |

## Where Packages Will Live

Built `.app` packages always go to **`outputAppPackage/`** in the project root — never `out/`,
`output/`, or ad hoc. Established here per the runbook's intake requirement, ahead of Step 07's
first package.
