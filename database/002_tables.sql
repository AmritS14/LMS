-- =====================================
-- USERS
-- =====================================

create table public.users (
id uuid primary key references auth.users(id) on delete cascade,

```
full_name text not null,
email text not null unique,
phone text,

role user_role,

must_change_password boolean default false,
is_active boolean default true,
mfa_required boolean default false,

last_login_at timestamptz,

created_at timestamptz default now()
```

);

-- =====================================
-- BORROWER PROFILES
-- =====================================

create table public.borrower_profiles (
id uuid primary key references public.users(id) on delete cascade,

```
date_of_birth date,

address_line1 text,
address_line2 text,

city text,
state text,

pin_code integer,
country text,

pan_number text,
aadhaar_last4 text,

employment_type employment_type,

monthly_income numeric,

kyc_status kyc_status default 'pending',

credit_score integer
```

);

-- =====================================
-- STAFF PROFILES
-- =====================================

create table public.staff_profiles (
id uuid primary key references public.users(id) on delete cascade,

```
employee_id text not null unique,

branch_id uuid,

department text,

reports_to_id uuid references public.users(id)
```

);

-- =====================================
-- LOAN PRODUCTS
-- =====================================

create table public.loan_products (
id uuid primary key default gen_random_uuid(),

```
name text not null unique,

description text,

minimum_amount numeric,
maximum_amount numeric,

minimum_tenure_months integer,
maximum_tenure_months integer,

minimum_interest_rate numeric,
maximum_interest_rate numeric,

is_active boolean default true,

created_at timestamptz default now()
```

);

-- =====================================
-- LOAN PRODUCT REQUIRED DOCUMENTS
-- =====================================

create table public.loan_product_required_documents (
id uuid primary key default gen_random_uuid(),

```
loan_product_id uuid not null
    references public.loan_products(id)
    on delete cascade,

document_type required_document_type not null,

is_mandatory boolean default true,

created_at timestamptz default now(),

unique (loan_product_id, document_type)
```

);

-- =====================================
-- LOAN APPLICATIONS
-- =====================================

create table public.loan_applications (
id uuid primary key default gen_random_uuid(),

```
borrower_id uuid not null
    references public.users(id),

assigned_officer_id uuid
    references public.users(id),

loan_product_id uuid not null
    references public.loan_products(id),

requested_amount numeric not null,

tenure_months integer not null,

interest_rate double precision not null,

status application_status default 'submitted',

created_at timestamptz default now(),
updated_at timestamptz default now()
```

);

-- =====================================
-- LOAN APPLICATION EVENTS
-- =====================================

create table public.loan_application_events (
id uuid primary key default gen_random_uuid(),

```
application_id uuid not null
    references public.loan_applications(id)
    on delete cascade,

actor_id uuid
    references public.users(id),

event_type application_event_type,

from_status application_status,
to_status application_status,

remark text,

metadata jsonb default '{}'::jsonb,

created_at timestamptz default now()
```

);

-- =====================================
-- LOAN DOCUMENTS
-- =====================================

create table public.loan_documents (
id uuid primary key default gen_random_uuid(),

```
owner_id uuid not null
    references public.users(id),

kind document_kind not null,

file_name text not null,

remote_url text,

status document_verification_status
    default 'pending',

uploaded_at timestamptz default now()
```

);

-- =====================================
-- LOAN APPLICATION DOCUMENTS
-- =====================================

create table public.loan_application_documents (
application_id uuid not null
references public.loan_applications(id)
on delete cascade,

```
document_id uuid not null
    references public.loan_documents(id)
    on delete cascade,

linked_at timestamptz default now(),

primary key (application_id, document_id)
```

);

-- =====================================
-- LOANS
-- =====================================

create table public.loans (
id uuid primary key default gen_random_uuid(),

```
application_id uuid not null
    references public.loan_applications(id),

borrower_id uuid not null
    references public.users(id),

principal numeric not null,

interest_rate double precision not null,

tenure_months integer not null,

disbursement_date date not null,

outstanding_balance numeric not null,

status loan_status default 'active'
```

);

-- =====================================
-- EMIS
-- =====================================

create table public.emis (
id uuid primary key default gen_random_uuid(),

```
loan_id uuid not null
    references public.loans(id)
    on delete cascade,

installment_number integer not null,

due_date date not null,

principal_component numeric not null,
interest_component numeric not null,

total_amount numeric not null,

status emi_status default 'upcoming',

paid_at timestamptz
```

);

-- =====================================
-- MESSAGE THREADS
-- =====================================

create table public.message_threads (
id uuid primary key default gen_random_uuid(),

```
participant_ids uuid[] not null,

application_id uuid
    references public.loan_applications(id)
    on delete cascade,

last_message_preview text,

updated_at timestamptz default now()
```

);

-- =====================================
-- CHAT MESSAGES
-- =====================================

create table public.chat_messages (
id uuid primary key default gen_random_uuid(),

```
thread_id uuid not null
    references public.message_threads(id)
    on delete cascade,

sender_id uuid not null
    references public.users(id),

body text not null,

sent_at timestamptz default now(),

read_at timestamptz
```

);

-- =====================================
-- AUDIT ENTRIES
-- =====================================

create table public.audit_entries (
id uuid primary key default gen_random_uuid(),

```
actor_id uuid not null
    references public.users(id),

actor_role user_role,

action text not null,

entity_type text not null,

entity_id uuid not null,

metadata jsonb default '{}'::jsonb,

timestamp timestamptz default now()
```

);

