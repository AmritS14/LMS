# Aadhaar Paperless Offline KYC — Implementation Handoff

**Branch:** `doc-verify`
**Status:** Plan agreed, no code written yet
**Owner of backend deploy:** teammate "arshitsinghal" (deployed at `https://arshitsinghal-lms-backend.hf.space`)

---

## 1. What we're building

Two parallel paths for Aadhaar KYC, both selectable by the borrower:

| Path | What borrower uploads | Verification | Outcome |
|---|---|---|---|
| **A. Aadhaar XML (UIDAI Paperless KYC)** | `.zip` from `myaadhaar.uidai.gov.in/offline-ekyc` + 4-char Share Phrase | Backend: unzip → parse XML → verify UIDAI RSA signature → compare mobile/email hashes against borrower profile | Auto-`verified` or auto-`rejected` |
| **B. Aadhaar photo** | Photos of card front/back (or PDF) | None — stored as-is | `pending`, officer reviews manually |

**Out of scope (per user):**
- Face recognition / selfie matching — explicitly skipped.
- PAN, bank statement, address proof, salary slip — separate phase, plan already documented in chat but not in scope for this handoff.
- DigiLocker — Phase 2.

---

## 2. End-to-end workflows

### 2a. Borrower flow — XML path

1. Borrower opens `KYCView` → taps the **ID Proof** row.
2. A chooser sheet appears: **"Aadhaar XML (instant verification)"** vs **"Upload photo of Aadhaar (manual review)"**.
3. XML chosen → `AadhaarKYCView` opens with three sections:
   - **Step 1 (Instructions)**: "How to download your Aadhaar XML" — button opens `https://myaadhaar.uidai.gov.in/offline-ekyc` in Safari.
   - **Step 2 (File)**: `fileImporter` restricted to `.zip` only.
   - **Step 3 (Share Phrase)**: `SecureField` (4 chars, but accept any length backend-side).
4. Submit → POST multipart to backend `/kyc/aadhaar/verify`.
5. Render result inline:
   - ✅ Verified — show name, DOB, masked Aadhaar (last 4), "Verified by UIDAI"
   - ❌ Invalid signature / tampered — clear error, allow retry with a different file
   - ❌ Wrong share phrase — inline retry without re-picking the file

### 2b. Borrower flow — photo path

1. From the same chooser, "Upload photo" → existing `KYCView` upload flow (PhotosPicker + fileImporter).
2. Goes through existing `documents.upload(...)` → `POST /documents/upload` with `kind=identityProof`.
3. Borrower sees the same "Uploaded ✓" state. Status stays `pending` until officer reviews.

### 2c. Officer flow

1. Officer opens an application → Documents section → taps the Aadhaar document.
2. `DocumentReviewSheet` opens.
3. If a `kyc_verifications` row exists for this document (XML path), replace the mock "OCR Match 98%" block with a **Verification Report Card**:
   - 🟢/🔴 **UIDAI Signature**: valid / invalid (with cert subject + signing date)
   - 🟢/🟡 **Mobile hash**: match / no profile mobile / mismatch
   - 🟢/🟡 **Email hash**: match / no profile email / mismatch
   - 📋 **Demographics**: name, DOB, gender, address (parsed from XML)
   - 🕒 **XML generated**: timestamp from `referenceId` + age badge (⚠️ if >180 days)
   - 🎯 **Auto-decision**: `auto_verified` / `needs_review` / `auto_rejected`
4. If no `kyc_verifications` row (photo path), keep the existing sheet behavior — no auto-verdict, manual Verify/Reject only.
5. Existing Verify/Reject buttons unchanged; officer can override the auto-decision. The override path calls existing `documents.verifyDocument` / `documents.rejectDocument`.

### 2d. Auto-decision matrix (backend)

| Signature | Mobile hash | XML age | Result |
|---|---|---|---|
| ❌ invalid | — | — | `auto_rejected` |
| ✅ valid | ✅ match | ≤ 180 days | `auto_verified` |
| ✅ valid | ✅ match | > 180 days | `needs_review` |
| ✅ valid | ❌ mismatch | any | `needs_review` |
| ✅ valid | profile has no mobile on file | any | `needs_review` |

When `auto_verified`, the backend also marks the underlying `loan_documents` row `status=verified` so it flows through the existing audit pipeline.

---

## 3. Backend changes (NestJS — `lms-backend/`)

Deployed instance: `https://arshitsinghal-lms-backend.hf.space`
Existing OpenAPI spec at `/api-json` confirms no `/kyc/*` routes exist yet. New module to add:

### 3a. New module: `src/kyc/aadhaar/`

```
src/kyc/aadhaar/
  aadhaar.module.ts
  aadhaar.controller.ts        # routes
  aadhaar.service.ts           # orchestration
  zip-unpacker.ts              # pyzipper-equivalent: unzip with share phrase
  xml-signature-verifier.ts    # XML C14N + RSA-SHA256 verify against UIDAI cert
  uidai-cert.ts                # loads + caches uidai_auth_prod.cer
  hash-compare.ts              # mobile/email hash recomputation
  dto/
    verify-aadhaar.dto.ts      # multipart: zip (File), sharePhrase (string)
    aadhaar-report.dto.ts      # response shape
  trust/
    uidai_auth_prod.cer        # pinned UIDAI public cert (refresh script in repo)
```

### 3b. Endpoints

| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| `POST` | `/kyc/aadhaar/verify` | Bearer | multipart: `zip` (file), `sharePhrase` (string), `applicationId` (uuid, optional) | `AadhaarReportDto` + persists `loan_documents` row (kind=`identityProof`, status follows auto-decision) + `kyc_verifications` row |
| `GET` | `/kyc/aadhaar/report/:documentId` | Bearer | — | `AadhaarReportDto` (officer-side fetch) |

`AadhaarReportDto` shape:
```ts
{
  documentId: string,
  signatureValid: boolean,
  signerCert: { subject: string, signingTime: string } | null,
  mobileHashMatch: 'match' | 'mismatch' | 'no_profile_value',
  emailHashMatch:  'match' | 'mismatch' | 'no_profile_value',
  referenceId: string,           // last4+timestamp
  xmlGeneratedAt: string,        // ISO from referenceId
  xmlAgeDays: number,
  demographics: { name, dob, gender, careOf, address: {...} },
  photoUrl: string | null,       // jpeg in Supabase storage
  autoDecision: 'auto_verified' | 'needs_review' | 'auto_rejected',
  rejectionReason: string | null
}
```

### 3c. Node libraries to add (`lms-backend/package.json`)

- `adm-zip` or `node-stream-zip` — ZIP extraction (note: stdlib zips support AES; UIDAI uses ZipCrypto / AES depending on portal version — pick a lib that supports both, e.g. `node-7z-archive`)
- `xml-crypto` — XMLDSig verification (C14N + RSA-SHA256)
- `xmldom` or `fast-xml-parser` — XML parsing
- `node-forge` or built-in `crypto` — SHA256 chains for hash comparison + cert handling
- `sharp` + `jpeg-js` + a JP2000 decoder (`openjpeg-wasm` via `npm:openjpeg`) — convert XML photo from JP2000 → JPEG. (If JP2000 decode proves painful in Node, fallback: store raw photo bytes and let the iOS client decode using `CGImageSource` which supports JP2000 natively.)

### 3d. Verification algorithm (canonical)

```
1. Unzip request.file using request.sharePhrase  → offline.xml
   If unzip fails → 422 "wrong_share_phrase"
2. Parse offline.xml → OfflinePaperlessKyc / UidData
3. Canonicalize XML (Exclusive C14N) → verify enveloped RSA-SHA256 signature
   against pinned UIDAI cert (uidai_auth_prod.cer).
   If invalid → autoDecision = auto_rejected, persist row, return.
4. Extract referenceId → last digit of Aadhaar (N) + timestamp.
5. If borrower profile has mobile:
     expectedMobileHash = sha256_chain(mobile, sharePhrase, N)
     mobileHashMatch = (expected == Poi/@m) ? 'match' : 'mismatch'
   else mobileHashMatch = 'no_profile_value'
   (same for email)
6. Decode photo (Pht element, base64 → JP2000 bytes) → JPEG → upload to
   Supabase storage at `aadhaar-photos/{document_id}.jpg` (private bucket, signed URLs only).
7. Decide autoDecision per matrix.
8. Insert loan_documents row (status = verified|rejected|pending per decision,
   file_name = "aadhaar_offline_kyc.xml", remote_url = signed URL to stored ZIP).
9. Insert kyc_verifications row with full report.
10. Return AadhaarReportDto.
```

`sha256_chain(value, phrase, N)`:
```
h = SHA256(value + phrase)
if N == 0: return hex(h)
for _ in range(N): h = SHA256(hex(h))
return hex(h)
```

### 3e. Supabase storage

- New private bucket: `aadhaar-photos` (RLS: borrower can read own; officer assigned to application can read via service role).
- ZIP itself stored in existing `loan_documents` bucket under `{owner_id}/aadhaar_{document_id}.zip`, encrypted at rest. Retention policy: keep for audit, never expose share phrase.

### 3f. UIDAI cert handling

- Bundle current cert in `trust/uidai_auth_prod.cer`.
- Source: `https://uidai.gov.in/images/authDoc/uidai_auth_prod.cer`
- Add a manual refresh script `scripts/refresh-uidai-cert.ts` — UIDAI rotates the cert occasionally; we want a one-line command + commit when that happens.
- The verifier accepts both the current and previous cert during a grace window (XMLs already issued under the previous cert remain valid until they expire from natural staleness).

---

## 4. Database changes (Supabase migration)

New table `kyc_verifications`:

```sql
create table kyc_verifications (
  id                  uuid primary key default gen_random_uuid(),
  document_id         uuid not null references loan_documents(id) on delete cascade,
  owner_id            uuid not null references auth.users(id),
  kind                text not null default 'aadhaar_offline',
  signature_valid     boolean not null,
  signer_subject      text,
  signing_time        timestamptz,
  mobile_hash_match   text check (mobile_hash_match in ('match','mismatch','no_profile_value')),
  email_hash_match    text check (email_hash_match  in ('match','mismatch','no_profile_value')),
  reference_id        text,
  xml_generated_at    timestamptz,
  name                text,
  dob                 date,
  gender              text,
  address_json        jsonb,
  photo_url           text,
  auto_decision       text not null check (auto_decision in ('auto_verified','needs_review','auto_rejected')),
  rejection_reason    text,
  created_at          timestamptz not null default now()
);

create index kyc_verifications_document_id_idx on kyc_verifications(document_id);
create index kyc_verifications_owner_id_idx on kyc_verifications(owner_id);

-- RLS
alter table kyc_verifications enable row level security;

create policy "borrower reads own"
  on kyc_verifications for select
  using (auth.uid() = owner_id);

create policy "staff reads if assigned"
  on kyc_verifications for select
  using (
    exists (
      select 1
      from loan_applications la
      join loan_application_documents lad on lad.application_id = la.id
      where lad.document_id = kyc_verifications.document_id
        and (la.assigned_officer_id = auth.uid() or la.managing_manager_id = auth.uid())
    )
    or exists (select 1 from staff_profiles where user_id = auth.uid() and role = 'admin')
  );

-- writes only via service role (backend)
```

Migration goes in: `lms-backend/supabase/migrations/<timestamp>_kyc_verifications.sql` (and applied via Supabase MCP `apply_migration` or the dashboard).

---

## 5. iOS changes

### 5a. New files

- `Shared/Services/AadhaarKYCService.swift` — protocol.
- `Shared/Services/Supabase/SupabaseAadhaarKYCService.swift` — real impl, multipart POST to `/kyc/aadhaar/verify`, GET `/kyc/aadhaar/report/{id}`.
- `Shared/Services/Mocks/MockAadhaarKYCService.swift` — fake impl for previews/dev. Returns a successful report with hardcoded demographics after a 1-second delay.
- `BorrowerApp/Views/AadhaarKYCView.swift` — the 3-step screen (Instructions → File picker → Share Phrase → Submit → Result).
- `StaffApp/Views/LoanOfficer/AadhaarVerificationReportCard.swift` — the report card subview, rendered inside `DocumentReviewSheet`.

### 5b. Modified files

- `Shared/AppEnvironment.swift` — add `let aadhaarKYC: AadhaarKYCService` property; wire in both BorrowerApp and StaffApp entry points.
- `Shared/Models.swift` — add `AadhaarVerificationReport` struct mirroring `AadhaarReportDto`.
- `BorrowerApp/Views/KYCView.swift` — replace the single `identityProof` row with a tappable row that presents a chooser sheet (XML vs Photo). XML route pushes `AadhaarKYCView`; Photo route keeps existing PhotosPicker/fileImporter behavior.
- `StaffApp/Views/LoanOfficer/DocumentReviewSheet.swift` — fetch verification report on appear if document kind == `identityProof`; if present, swap the mock OCR block for `AadhaarVerificationReportCard`. Existing buttons & flow untouched.
- `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` — add helper to fetch the Aadhaar report from the service and cache on the application.

### 5c. Service protocol shape

```swift
protocol AadhaarKYCService: Sendable {
    func verify(zipData: Data, sharePhrase: String, applicationID: UUID?) async throws -> AadhaarVerificationReport
    func report(documentID: UUID) async throws -> AadhaarVerificationReport?
}
```

`AadhaarVerificationReport` mirrors `AadhaarReportDto` from §3b 1-to-1.

---

## 6. Implementation order

1. **Backend module first** (`lms-backend/src/kyc/aadhaar/*`). Use a real Aadhaar XML test fixture from UIDAI samples in unit tests. Verify locally with `npm run start:dev`. Deploy to HF Space.
2. **Supabase migration** for `kyc_verifications`.
3. **iOS service layer**: protocol + mock + Supabase impl. Wire into `AppEnvironment`.
4. **`AadhaarKYCView`** + `KYCView` chooser. End-to-end test borrower upload against real backend.
5. **`AadhaarVerificationReportCard`** + `DocumentReviewSheet` integration. End-to-end test officer view.
6. **Polish**: error states, loading states, age badge, accessibility.

Steps 1–2 are blocking for everything else. Steps 3–4 can be developed in parallel against the mock service before backend is deployed.

---

## 7. Open questions / decisions not yet locked

1. **Backend ownership**: arshitsinghal is the named deployer of the HF Space. We need to confirm:
   - Will the Aadhaar module live in this repo's `lms-backend/` folder (which is currently empty — backend source is in `lms-backend.zip`) or in a separate repo?
   - Who pushes the deploy?
2. **JP2000 decoding**: do we decode photo on backend (Node JP2000 libs are awkward) or pass raw bytes to iOS (CGImageSource supports JP2000)? Recommendation: backend converts to JPEG so the officer UI doesn't need any JP2000 handling.
3. **Photo path UI copy**: should the chooser say "Upload photo (slower — manual review required)" to nudge borrowers toward the XML path? Recommended yes.
4. **Reject UX when signature fails**: silent retry, or hard error with explanation? Recommendation: explanatory error ("This file appears to be modified or not issued by UIDAI") with a "Try again" button.
5. **DocumentKind**: do we need a new `aadhaarXML` case alongside `identityProof`, or stuff both into `identityProof` and discriminate via `kyc_verifications` presence? Recommendation: keep `identityProof`, discriminate via the verification row (less churn across iOS/backend).

---

## 8. Files / references

**Existing code touched**
- `Shared/Services/DocumentService.swift` — pattern to mirror for the new service protocol
- `Shared/Services/Supabase/SupabaseDocumentService.swift` — pattern for multipart POST + bearer auth
- `Shared/Services/Mocks/MockSupportServices.swift` — pattern for mock impls
- `BorrowerApp/Views/KYCView.swift` — borrower upload UI
- `StaffApp/Views/LoanOfficer/DocumentReviewSheet.swift` — officer review UI (lines 86–145 are the mock OCR block to replace)
- `StaffApp/Views/LoanOfficer/LOAppViewModel.swift:634` — `updateDocumentReview` already wires through `verifyDocument`/`rejectDocument`; nothing to change there

**External references**
- UIDAI XML download portal: `https://myaadhaar.uidai.gov.in/offline-ekyc`
- UIDAI public signing cert: `https://uidai.gov.in/images/authDoc/uidai_auth_prod.cer`
- UIDAI Paperless Offline e-KYC spec: `https://uidai.gov.in/en/ecosystem/authentication-devices-documents/about-aadhaar-paperless-offline-e-kyc.html`
- Reference Node implementation: `https://github.com/nteshxx/aadhaar-offline-ekyc`
- xml-crypto (the Node XMLDSig lib): `https://github.com/node-saml/xml-crypto`
- Backend Swagger (current): `https://arshitsinghal-lms-backend.hf.space/api`

**Backend verification — confirmed live 2026-05-29**
- `/auth/me`, `/documents/upload`, `/documents/{id}/verify` — all present
- `/kyc/*` — **not present** (this is the work to add)

---

## 9. Compliance reminders

- Never log share phrase. Never persist plaintext share phrase.
- Aadhaar number is not in the XML (only last 4) — don't try to reconstruct it.
- UIDAI rules forbid republishing the XML / sharing share code. Storage is OK for audit but RLS must restrict reads to the borrower + their assigned officer/manager + admins.
- DPDP Act 2023 + Aadhaar Act apply — borrower consent UI must precede the upload (a checkbox: "I authorize Infosys LMS to verify my Aadhaar offline KYC document with UIDAI").
