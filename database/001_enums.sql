-- =====================================
-- USER ROLES
-- =====================================

create type user_role as enum (
  'borrower',
  'loan_officer',
  'manager',
  'admin'
);

-- =====================================
-- APPLICATION STATUS
-- =====================================

create type application_status as enum (
  'draft',
  'submitted',
  'assigned',
  'under_review',
  'document_pending',
  'manager_review',
  'approved',
  'rejected',
  'disbursed',
  'closed'
);

-- =====================================
-- APPLICATION EVENT TYPES
-- =====================================

create type application_event_type as enum (
  'submitted',
  'assigned',
  'review_started',
  'document_requested',
  'documents_uploaded',
  'sent_to_manager',
  'approved',
  'rejected',
  'comment_added',
  'status_changed'
);

-- =====================================
-- REQUIRED DOCUMENT TYPES
-- =====================================

create type required_document_type as enum (
  'pan_card',
  'aadhaar_card',
  'salary_slip',
  'bank_statement',
  'itr',
  'passport_photo',
  'employment_certificate',
  'address_proof',
  'other'
);

-- =====================================
-- DOCUMENT TYPES
-- =====================================

create type document_kind as enum (
  'identityProof',
  'addressProof',
  'incomeProof',
  'bankStatement',
  'collateral',
  'other'
);

-- =====================================
-- DOCUMENT VERIFICATION STATUS
-- =====================================

create type document_verification_status as enum (
  'pending',
  'verified',
  'rejected'
);

-- =====================================
-- EMI STATUS
-- =====================================

create type emi_status as enum (
  'upcoming',
  'paid',
  'overdue'
);

-- =====================================
-- EMPLOYMENT TYPES
-- =====================================

create type employment_type as enum (
  'salaried',
  'selfEmployed',
  'business',
  'retired',
  'unemployed'
);

-- =====================================
-- KYC STATUS
-- =====================================

create type kyc_status as enum (
  'pending',
  'submitted',
  'verified',
  'rejected'
);

-- =====================================
-- LOAN STATUS
-- =====================================

create type loan_status as enum (
  'active',
  'overdue',
  'defaulted',
  'foreclosed',
  'settled',
  'closed'
);
