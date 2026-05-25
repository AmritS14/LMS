# LMS Backend — Complete Architecture & API Walkthrough

Backend URL:
`https://arshitsinghal-lms-backend.hf.space/api#/`

---

# 1. SYSTEM OVERVIEW

This LMS (Loan Management System) backend is built using:

- NestJS
- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Swagger/OpenAPI
- JWT Authentication
- Row Level Security (RLS)

The architecture intentionally splits responsibilities between:

| Layer | Responsibility |
|---|---|
| Supabase | Database, Auth, Storage, RLS, Realtime |
| NestJS API | Business workflows, transitions, approvals, orchestration |
| Frontend | UI, state management, realtime UX |

This separation is VERY important.

The backend API is NOT meant to replace Supabase querying.
It is meant to enforce:

- business rules
- workflow state transitions
- authorization logic
- financial calculations
- privileged operations

---

# 2. HIGH LEVEL FLOW

## Core Lending Lifecycle

```text
Borrower Registers/Login
↓
Borrower Creates Loan Application
↓
System Auto Assigns Officer
↓
Officer Reviews Application
↓
Officer Requests Additional Documents
↓
Borrower Uploads Documents
↓
Officer Sends To Manager
↓
Manager/Admin Approves
↓
Loan Disbursed
↓
EMI Schedule Generated
↓
Borrower Pays EMIs
↓
Loan Closed
```

---

# 3. USER ROLES

## Borrower
Can:
- create applications
- upload documents
- view own applications
- view own loans
- pay EMIs
- participate in chats

Cannot:
- approve loans
- verify documents
- create staff

---

## Loan Officer
Can:
- view assigned applications
- review applications
- request documents
- verify documents
- reject applications
- send applications to managers

Cannot:
- create staff
- disburse loans
- create admins

---

## Manager
Can:
- approve applications
- reject applications
- verify documents
- review escalated applications

---

## Admin
Can:
- everything
- create staff
- manage workflows
- disburse loans

---

# 4. DATABASE TABLES

This section explains:

- what each table stores
- who can access it
- whether frontend should query directly
- whether API should be used

---

# USERS TABLE

## Purpose
Stores base system user records.

Usually synced with Supabase Auth.

## Contains

- id
- email
- role
- phone
- full_name
- flags

## Access Pattern

| Operation | Source |
|---|---|
| Read current profile | API `/auth/me` |
| Read public profile info | Supabase |
| Authentication | Supabase Auth |

## Why `/auth/me` exists

Frontend needs:

- role
- permissions
- onboarding state
- security flags

immediately after login.

---

# STAFF_PROFILES TABLE

## Purpose
Stores employee-specific metadata.

## Contains

- employee_id
- department
- designation
- workload info

## Used For

- officer assignment
- admin dashboard
- manager hierarchy

## Access

| Operation | Source |
|---|---|
| Admin management | API |
| Officer dashboards | Supabase |

---

# LOAN_PRODUCTS TABLE

## Purpose
Defines loan offerings.

## Contains

- name
- interest_rate
- max_amount
- min_amount
- tenure rules

## Access

Frontend should query:

```text
Supabase directly
```

Reason:
- simple read-only data
- benefits from realtime
- no business logic needed

---

# LOAN_APPLICATIONS TABLE

## Purpose
Core loan workflow entity.

This is the heart of the system.

## Contains

- borrower_id
- assigned_officer_id
- status
- requested_amount
- tenure_months
- interest_rate
- loan_product_id
- timestamps

## Status Lifecycle

```text
submitted
↓
assigned
↓
under_review
↓
document_pending
↓
pending_manager_approval
↓
approved
↓
rejected
↓
disbursed
↓
closed
```

## Access Pattern

| Operation | Source |
|---|---|
| List borrower apps | Supabase |
| List assigned officer apps | Supabase |
| Create application | API |
| Change status | API |
| Assignment logic | API |
| Approval logic | API |

## IMPORTANT

Frontend SHOULD NOT directly update statuses.

Only API should perform workflow transitions.

Reason:
- transition validation
- audit trails
- business rules
- role enforcement

---

# APPLICATION_EVENTS TABLE

## Purpose
Stores immutable workflow timeline.

Acts as:

- audit log
- activity feed
- workflow history

## Contains

- application_id
- actor_id
- event_type
- remarks
- timestamps

## Example Events

```text
application_created
assigned
review_started
documents_requested
documents_uploaded
sent_to_manager
approved
rejected
loan_disbursed
```

## Access

Frontend should fetch:

```text
Supabase directly
```

Reason:
- append-only
- realtime friendly
- timeline UI

---

# DOCUMENTS TABLE

## Purpose
Stores uploaded borrower documents.

## Contains

- owner_id
- file_name
- storage path
- verification status
- document type

## Actual Files

Stored in:

```text
Supabase Storage
```

NOT PostgreSQL.

Table stores metadata only.

---

# DOCUMENT VERIFICATION FLOW

```text
Borrower uploads document
↓
Document record created
↓
Officer reviews
↓
Verified or rejected
```

## Access Pattern

| Operation | Source |
|---|---|
| Upload document | API |
| Get signed URL | API |
| View document list | Supabase |
| Verify/reject | API |

## Why signed URLs exist

Storage bucket is private.

API generates temporary access URLs.

This prevents:
- public exposure
- leaked documents
- unauthorized downloads

---

# CHAT TABLES

Likely:

- conversations
- messages
- participants

## Purpose
Borrower/officer communication.

## IMPORTANT

Chat SHOULD primarily use:

```text
Supabase directly
```

NOT NestJS.

Reason:
- realtime subscriptions
- simpler architecture
- lower latency
- less backend complexity

## Frontend Uses

- realtime subscriptions
- inserts
- live updates

## NestJS Role

Minimal.

Only if you later need:
- moderation
- AI summaries
- escalation logic
- compliance auditing

---

# LOANS TABLE

## Purpose
Represents actual active loans.

Created AFTER approval.

## Contains

- principal
- outstanding balance
- interest rate
- disbursement date
- status
- linked application

## Creation

Only via:

```text
POST /loans/applications/{id}/disburse
```

## IMPORTANT

Loan creation is NOT direct DB insert.

Reason:
- EMI generation
- accounting consistency
- audit logging
- financial integrity

---

# EMIS TABLE

## Purpose
Stores repayment schedule.

## Contains

- due dates
- principal component
- interest component
- payment status
- remaining balance

## Generated Automatically

When loan is disbursed.

## Access Pattern

| Operation | Source |
|---|---|
| Read EMI schedule | Supabase |
| Mark payment | API |

---

# 5. API EXPLANATION

---

# AUTH APIs

## GET /auth/me

### Purpose
Returns authenticated user profile.

### Used By

Frontend immediately after login.

### Frontend Usage

Determines:

- borrower dashboard?
- officer dashboard?
- manager dashboard?
- admin panel?

### Returns

- role
- permissions
- profile
- flags

---

# ADMIN APIs

## POST /admin/staff

### Purpose
Creates:

- auth account
- user row
- staff profile

for:

- officers
- managers
- admins

### Why API is required

Requires:

```text
service role privileges
```

Frontend should NEVER have this.

---

# APPLICATION APIs

---

## GET /applications/my

### Used By
Borrower.

### Purpose
Fetch own applications.

### Frontend
Borrower dashboard.

---

## GET /applications/assigned

### Used By
Loan officers.

### Purpose
Fetch assigned work queue.

### Frontend
Officer dashboard.

---

## GET /applications/{id}

### Purpose
Detailed application screen.

### Includes

- borrower info
- status
- amounts
- officer
- timestamps

---

## GET /applications/{id}/events

### Purpose
Workflow timeline.

### Frontend
Timeline/activity feed.

---

## POST /applications

### Purpose
Create loan application.

### Backend Logic

- validates product
- sets interest rate
- auto assigns officer
- creates audit event

### IMPORTANT

This MUST stay API-driven.

Reason:
- assignment logic
- orchestration
- validations

---

## POST /applications/{id}/start-review

### Purpose
Transition:

```text
assigned → under_review
```

### Used By
Officer.

---

## POST /applications/{id}/request-documents

### Purpose
Officer requests additional documents.

### Transition

```text
under_review → document_pending
```

### Frontend
Officer review screen.

---

## POST /applications/{id}/documents-uploaded

### Purpose
Borrower confirms requested docs uploaded.

### Important

Does NOT upload files.

Only links uploaded documents.

---

## POST /applications/{id}/send-to-manager

### Purpose
Escalates application.

### Transition

```text
under_review → pending_manager_approval
```

---

## POST /applications/{id}/approve

### Purpose
Manager/admin approval.

### Transition

```text
pending_manager_approval → approved
```

---

## POST /applications/{id}/reject

### Purpose
Reject application.

---

# DOCUMENT APIs

---

## POST /documents/upload

### Purpose
Uploads borrower document.

### Stores

- file in Supabase Storage
- metadata in DB

### Returns

- document id
- storage path

---

## GET /documents/{id}/url

### Purpose
Generates signed URL.

### Why

Storage bucket is private.

### Used By

- officer document viewer
- manager verification UI

---

## POST /documents/{id}/verify

### Purpose
Marks document verified.

### Used By

- officers
- managers
- admins

---

## POST /documents/{id}/reject

### Purpose
Reject invalid/fake document.

---

# LOAN APIs

---

## POST /loans/applications/{id}/disburse

### Purpose
Converts approved application into active loan.

### Backend Logic

- creates loan
- generates EMI schedule
- creates audit events
- updates statuses

### IMPORTANT

Highly sensitive operation.

Must remain API-only.

---

# EMI APIs

---

## POST /emis/{id}/pay

### Purpose
Marks EMI paid.

### Backend Logic

- updates balances
- recalculates outstanding
- closes loan if completed

### Future Integration

Later:

- Razorpay
- UPI
- payment gateways

will call this.

---

# 6. WHAT SHOULD COME FROM SUPABASE VS API

This is the MOST important architectural section.

---

# USE SUPABASE DIRECTLY FOR:

## Realtime / Read-heavy / Simple Data

### Good candidates

- dashboards
- application lists
- events/timelines
- chat
- notifications
- EMI schedules
- document lists
- profile data
- loan lists
- counters
- analytics

## Why?

Benefits:

- realtime subscriptions
- lower latency
- less backend load
- simpler frontend
- easier scaling

---

# USE API FOR:

## Workflow / Orchestration / Sensitive Logic

### Good candidates

- create application
- approvals
- rejections
- disbursement
- repayments
- document verification
- staff creation
- assignment engine
- financial calculations

## Why?

Benefits:

- validation
- role enforcement
- transaction consistency
- audit logging
- business rules

---

# 7. RECOMMENDED FRONTEND ARCHITECTURE

---

# BORROWER APP

## Uses API For

- applying for loans
- uploading docs
- EMI payment actions

## Uses Supabase For

- dashboard
- realtime updates
- chat
- timelines
- loan tracking

---

# OFFICER DASHBOARD

## Uses API For

- review transitions
- document verification
- escalations

## Uses Supabase For

- assigned queue
- chat
- dashboards
- realtime application changes

---

# MANAGER DASHBOARD

## Uses API For

- approvals
- rejections
- disbursement

## Uses Supabase For

- queues
- analytics
- timelines

---

# 8. RLS STRATEGY

RLS is CRITICAL.

Your architecture intentionally relies heavily on:

```text
Supabase RLS
```

This allows frontend to safely query directly.

---

# Example Borrower Policy

Borrowers only see:

```sql
borrower_id = auth.uid()
```

---

# Example Officer Policy

Officers only see:

```sql
assigned_officer_id = auth.uid()
```

---

# WHY THIS MATTERS

Because frontend can safely:

```text
query Supabase directly
```

WITHOUT exposing all data.

This massively simplifies frontend architecture.

---

# 9. WHY NESTJS STILL EXISTS

Some people ask:

```text
why not use Supabase only?
```

Answer:

Because lending systems require:

- workflow enforcement
- financial calculations
- orchestration
- secure privileged actions
- audit integrity
- transactional logic

Pure frontend+Supabase becomes dangerous for these.

NestJS acts as:

```text
workflow and business logic layer
```

NOT just CRUD.

---

# 10. CURRENT SYSTEM STRENGTHS

The current architecture already includes:

- role auth
- document engine
- workflow state machine
- assignment system
- EMI generation
- audit events
- Swagger/OpenAPI
- Docker deployment
- Supabase integration
- RLS-first architecture
- production hosting

This is already significantly beyond most student projects.

---

# 11. FUTURE IMPROVEMENTS

Later possible additions:

- payment gateway integration
- OCR document extraction
- AI risk scoring
- notification engine
- Kafka/event queues
- repayment reminders
- analytics dashboards
- fraud detection
- soft delete systems
- versioned workflows
- background workers
- caching
- rate limiting
- distributed job queues

---

# 12. FINAL ARCHITECTURE SUMMARY

## Supabase Handles

- auth
- postgres
- storage
- realtime
- RLS
- subscriptions

## NestJS Handles

- workflows
- approvals
- transitions
- calculations
- orchestration
- sensitive operations

## Frontend Handles

- UI
- UX
- realtime rendering
- state management
- subscriptions
- form handling

This is the intended architecture of the LMS backend system.

