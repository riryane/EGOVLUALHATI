# E-Tulong — Technical Documentation

*Lualhatinnovators · eGov Hackathon · integrated module concept for the eGovPH Super App*

---

## 1. Architecture at a glance

```
┌─────────────────────────── Browser (citizen / agency) ───────────────────────────┐
│  Static HTML + CSS + JavaScript (ES modules, no framework, no build step)        │
│                                                                                  │
│   login.html ──► eGov SSO ──────────────► hackathon-sso.e.gov.ph                 │
│   login.html ──► SMS OTP ───────────────► ws-message.e.gov.ph        (eMessage)  │
│   camera.html ─► Document OCR ──────────► egov-ai-core-ws.oueg.info  (eGov AI)   │
│   face-liveness.html ─► Liveness scan ──► hackathon-face-liveness-api.e.gov.ph   │
│   admin.html ──► claim codes / notices ─► ws-message.e.gov.ph        (eMessage)  │
│                                                                                  │
│   all pages ──► data (users, programs, applications) ──► Supabase (PostgreSQL    │
│                                                          via PostgREST)          │
└──────────────────────────────────────────────────────────────────────────────────┘
```

**Design decision — buildless static frontend.** The prototype is plain HTML/JS served statically. Rationale: hackathon speed, zero deployment complexity, and it proves the integrations are pure HTTP — the same calls port unchanged to any production stack. The trade-off (secrets in client code) is a known, deliberate MVP concession — see §9.

**Design decision — Supabase as the data layer.** PostgreSQL with an instant REST API (PostgREST) and a JS client. It stands in for what would be an agency-side service in production. Row Level Security is intentionally disabled for the MVP (see §9).

---

## 2. Data model (PostgreSQL)

Four tables, deliberately minimal:

| Table | Purpose | Notable columns |
|---|---|---|
| `users` | Citizen profiles, populated from SSO | `egov_uniqid` (unique, binds the eGovPH identity), full profile fields, `consented_at` (RA 10173 consent timestamp) |
| `assistance` | Ayuda program catalog, per user | `requirements` (jsonb), `documents` (jsonb checklist), `rules` (jsonb — eligibility engine input), `eligibility_status` (seeded fallback) |
| `applications` | One row per submitted application | `status` (state machine, §6), `admin_note` (rejection reason / info request), `citizen_note` (appeal), `submitted_documents` (jsonb evidence snapshot), `claim_code` + `claim_code_expires_at` (2FA pick-up) |
| `id_cards` | Digital ID (PhilSys) render data | `pcn` from the SSO `national_id` block |

Foreign keys use `on delete cascade`. The seeded demo user's `assistance` rows double as the **catalog template**: on first SSO login, a new user gets a copy of the catalog (production would use a single shared catalog table with per-user computed state).

---

## 3. API integrations (all live, no mocks)

### 3.1 eGov SSO — identity & auto-registration
OAuth2 authorization-code style flow:
1. eGovPH redirects to the partner URL with `?exchange_code=...` (our `login.html` handles this pattern; a paste-a-code path exists for sandbox testing).
2. `POST /api/token` with `{exchange_code, scope: SSO_AUTHENTICATION, partner_code, partner_secret}` → short-lived bearer `access_token`. Exchange codes are **single-use** and expire quickly.
3. `POST /api/partner/sso_authentication` with the bearer → full citizen profile (identity, address, PhilSys `national_id` incl. PCN, health data, etc.).
4. We match by `uniqid` (per the eGov integration guide): existing user → profile refresh; new user → auto-registration + catalog copy + Digital ID row. The profile snapshot is stored in the session — **pages never re-read the users table for profile data; the SSO payload is the source of truth** (this satisfies the eGov checklist item "profile updates occur exclusively through eGovPH").

### 3.2 eMessage — SMS channel
`POST /messaging/v1/sms/push` with header `X-EMESSAGE-Auth: <token>`, body `{number(E.164), message}`. Used for **three distinct purposes**:
- **Login OTP**: 6-digit code, 5-minute TTL, verified client-side; account resolved by registered mobile number (possession factor).
- **Status notifications**: every agency decision (approved / rejected with reason / info requested / ready for pick-up / completed / cycle reset) texts the citizen.
- **Pick-up claim codes**: see §7.

### 3.3 eGov Face Liveness — proof of live presence
1. `POST /v1/liveness/session` (`x-api-key`) with `{action: 'post', delay}` → `{token, url}`.
2. The hosted scanner URL is embedded **in an iframe inside the app** (`allow="camera"`) — the `post` action means completion is announced via `postMessage`; we also poll the result endpoint as a safety net. (We verified the scanner sends no `X-Frame-Options`, so embedding is supported.)
3. `GET /v1/liveness/result/{token}` (`x-api-key`) → `{status, confidence_score, reference_image_url}`.
4. **We enforce the vendor's recommended threshold: `status === 'SUCCEEDED' && confidence_score >= 95.0`.** Below threshold or non-success → rejected with retry. Only after passing is the application recorded.

### 3.4 eGov AI Document Extractor — OCR
1. `POST /api/v1/egov/integration/token` with `{access_code}` → `{access_token, expires_in_seconds: 172800, credits_total: 200}`. We **cache the token and auto-refresh 5 minutes before expiry**; a 401 triggers one refresh-and-retry.
2. `POST /api/v1/egov/integration/document_extractor/generate` — `multipart/form-data` with the captured camera frame (JPEG from a canvas snapshot) — returns structured extracted fields.
3. **Our validation layer on top:** the extractor reads *any* document; it does not know what the program requires. We match the extracted text against keyword sets derived from the required document name (e.g. a "Barangay Residency Certificate" must mention barangay/residency/certificate). Mismatch → "Wrong Document?" with Retake. This is the difference between *OCR* and *verification*.

---

## 4. Auth & session model

- Session = `users.id` + a **profile snapshot** persisted at login (localStorage). Every page runs a guard (`requireSession`) that redirects to login when either is missing.
- Three login paths: eGov SSO (primary), SMS OTP (possession of registered SIM), and an explicit **Demo Mode** (clearly labeled; exists because sandbox services have downtime).
- Logout wipes session, profile, and captured-document flags.
- Production upgrade path: eGov-managed sessions (per their checklist, partners remove manual auth entirely).

## 5. Eligibility rules engine

`assets/js/eligibility.js` — eligibility is **computed at runtime**, not stored. Each program carries `rules` (jsonb); rule types implemented:

| Rule | Evaluates |
|---|---|
| `age_range {min,max}` | age derived from the SSO birth date |
| `residency {keyword}` | address containment match |
| `profile_complete {fields}` | required profile fields present — output names exactly what's missing |
| `no_active_same_category` | no other active application in the same program category (prevents benefit stacking) |

Verdict: all rules met → *Eligible*; otherwise *Possibly Eligible* with a per-rule pass/fail checklist. The same engine runs on the **agency side** against the applicant's profile, so citizen and officer see the same computation. Seeded values remain only as a fallback for rule-less programs. New rule types are added by extending one switch statement — the catalog is data-driven.

## 6. Application lifecycle (state machine)

```
             ┌────────────► rejected ──► appealed ──► (approve/deny again)
             │                  │                        
 pending ────┼──► info_requested ──► (citizen submits doc) ──► pending
             │                  
             └──► approved ──► for_pickup ──► done ──► expired (cycle reset)
```

- **All transitions are agency-side** (citizen chips are read-only) — except the citizen-initiated *appeal* and *info response*.
- Deny and Request Info **require a written message** (`admin_note`), shown to the citizen and included in the SMS — due-process by construction.
- Rejection triggers a **re-apply cooldown** (demo: 2 min; production: policy-defined, e.g. 30 days); the citizen may **appeal during the cooldown** (`citizen_note`), putting the case in the agency's Appealed queue with both sides shown.
- `expired` (cycle reset) preserves history while unlocking re-application — the "next year's ayuda" scenario.
- Duplicate protection: an active application blocks re-applying to the same program.

## 7. Two-factor pick-up verification

At the distribution counter, "claimed" is confirmed with two factors:
1. **Something you have** — the officer taps *Send Verification Code*: a fresh 6-digit code (5-minute TTL) is generated, stored on the application, and SMSed to the **registered** mobile number. The citizen reads it back; the officer confirms. Checked against the freshest DB state; expiry and mismatch handled; codes are single-purpose and cleared after use.
2. **Something you are** — identity was already bound at application time by face liveness (§3.3) and at claim time by the Digital ID.

This prevents claiming by proxy and ghost beneficiaries — the registered SIM must be physically present.

## 8. Evidence trail

- Captured documents are keyed **by document name**, so one verified document (e.g. SSS Employment Record) satisfies every program that requires it — the "stop re-submitting the same photocopy" feature, implemented.
- On submission, the application stores a `submitted_documents` **snapshot**: each document, whether verified, and **how** (eGov record source vs. Camera OCR). The agency reviews evidence *as submitted*, not a live view that could change after the fact.

## 9. Known limitations & production roadmap (deliberate MVP concessions)

Be upfront about these — they are scoping decisions, not oversights:

| MVP state | Production design |
|---|---|
| API secrets in client JS | Backend proxy / edge functions hold all secrets; browser never sees them. All current sandbox keys to be rotated. |
| Supabase RLS disabled; public write access | RLS policies per user; agency actions via authenticated server endpoints only |
| Agency portal has no login | Agency SSO + RBAC (reviewer vs releaser) + full **audit log** (who decided what, when, why — decisions are appealable public acts) |
| Sessions in localStorage, no expiry | eGov-managed sessions per partner checklist |
| Captured-document flags in localStorage | Document store rows tied to the user, uploaded evidence retained per records-retention rules |
| Rules engine runs client-side | Server-side evaluation (client must not be trusted to declare itself eligible) |
| Per-user catalog copies | Single shared catalog; per-user state computed |
| Demo bypasses on API failure | Removed; replaced by retry queues and status pages |

Compliance groundwork already present: RA 10173 consent gate with stored `consented_at`, plain-language privacy notice (collection, purpose, retention, NPC rights, DPO), and notes on accessibility/Filipino localization as next steps.

## 10. Repository map

```
prototype/
  login.html            SSO + OTP + demo login, consent-aware
  main-dashboard.html   eGovPH-style home, consent gate
  index.html            eAyuda: search, category + eligibility filters, computed verdicts
  details.html          program detail: computed checklist, apply gate, cooldown, reasons
  document-requirements.html  per-program checklist, shared captures, missing-doc modal
  camera.html           live camera → eGov AI OCR → document-type validation
  face-liveness.html    embedded eGov liveness → threshold check → submission + snapshot
  transactions.html     My Applications: search, filters, notes, appeal, info response
  admin.html            Agency portal: search, review, decisions with reasons, 2FA claim,
                        cycle reset, applicant details (computed eligibility + evidence)
  digital-id.html / profile.html / privacy.html
  assets/js/
    supabase-client.js  data client (URL + publishable key)
    session.js          session, guards, logout
    egov-sso.js         SSO flow + auto-registration
    emessage.js         SMS send
    egov-ai.js          OCR token lifecycle + extraction
    eligibility.js      rules engine
    clock.js            live status-bar clock
  supabase/
    setup_all.sql       one-shot schema + seeds (fresh environments)
    migration_*.sql     incremental migrations
```
