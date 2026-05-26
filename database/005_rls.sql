-- =====================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================

alter table public.users enable row level security;

alter table public.borrower_profiles enable row level security;

alter table public.staff_profiles enable row level security;

alter table public.loan_products enable row level security;

alter table public.loan_product_required_documents enable row level security;

alter table public.loan_applications enable row level security;

alter table public.loan_application_events enable row level security;

alter table public.loan_documents enable row level security;

alter table public.loan_application_documents enable row level security;

alter table public.loans enable row level security;

alter table public.emis enable row level security;

alter table public.message_threads enable row level security;

alter table public.chat_messages enable row level security;

alter table public.audit_entries enable row level security;

-- =====================================
-- REVOKE BROAD DEFAULT ACCESS
-- =====================================

revoke all on all tables in schema public from authenticated;

-- =====================================
-- USERS
-- =====================================

grant select on public.users to authenticated;

grant update (
full_name,
phone
)
on public.users
to authenticated;

-- =====================================
-- BORROWER PROFILES
-- =====================================

grant select, update
on public.borrower_profiles
to authenticated;

-- =====================================
-- STAFF PROFILES
-- =====================================

grant select
on public.staff_profiles
to authenticated;

-- =====================================
-- LOAN APPLICATIONS
-- =====================================

grant select, insert, update
on public.loan_applications
to authenticated;

-- =====================================
-- LOAN APPLICATION EVENTS
-- =====================================

grant select, insert
on public.loan_application_events
to authenticated;

-- =====================================
-- LOAN DOCUMENTS
-- =====================================

grant select, insert
on public.loan_documents
to authenticated;

-- =====================================
-- LOAN APPLICATION DOCUMENTS
-- =====================================

grant select, insert
on public.loan_application_documents
to authenticated;

-- =====================================
-- LOAN PRODUCTS
-- =====================================

grant select
on public.loan_products
to authenticated;

grant select
on public.loan_product_required_documents
to authenticated;

-- =====================================
-- LOANS + EMIS
-- =====================================

grant select
on public.loans
to authenticated;

grant select
on public.emis
to authenticated;

-- =====================================
-- MESSAGING
-- =====================================

grant select, insert, update
on public.message_threads
to authenticated;

grant select, insert, update
on public.chat_messages
to authenticated;

-- =====================================
-- AUDIT
-- =====================================

grant select
on public.audit_entries
to authenticated;


-- =====================================
-- USERS POLICIES
-- =====================================

create policy "Admins can read all users"
on public.users
for select
using (
has_role('admin')
);

create policy "Users can read own profile"
on public.users
for select
using (
auth.uid() = id
);

create policy "Users can update own profile"
on public.users
for update
using (
auth.uid() = id
);

-- =====================================
-- BORROWER PROFILE POLICIES
-- =====================================

create policy "Borrowers can view own profile"
on public.borrower_profiles
for select
using (
auth.uid() = id
);

create policy "Borrowers can update own profile"
on public.borrower_profiles
for update
using (
auth.uid() = id
);

-- =====================================
-- STAFF PROFILE POLICIES
-- =====================================

create policy "Staff view own profile"
on public.staff_profiles
for select
using (
id = auth.uid()
);

create policy "Admins view all staff"
on public.staff_profiles
for select
using (
has_role('admin')
);

create policy "Admins manage staff"
on public.staff_profiles
for all
using (
has_role('admin')
);

create policy "Managers view team staff"
on public.staff_profiles
for select
using (
has_role('manager')
AND reports_to_id = auth.uid()
);


-- =====================================
-- LOAN APPLICATION POLICIES
-- =====================================

create policy "Borrowers can create applications"
on public.loan_applications
for insert
with check (
auth.uid() = borrower_id
AND has_role('borrower')
);

create policy "Borrowers can view own applications"
on public.loan_applications
for select
using (
auth.uid() = borrower_id
);

create policy "Loan officers view assigned applications"
on public.loan_applications
for select
using (
has_role('loan_officer')
AND assigned_officer_id = auth.uid()
);

create policy "Loan officers update assigned applications"
on public.loan_applications
for update
using (
has_role('loan_officer')
AND assigned_officer_id = auth.uid()
);

create policy "Managers view team applications"
on public.loan_applications
for select
using (
has_role('manager')
AND exists (
select 1
from public.staff_profiles sp
where sp.id = loan_applications.assigned_officer_id
and sp.reports_to_id = auth.uid()
)
);

create policy "Managers update team applications"
on public.loan_applications
for update
using (
has_role('manager')
AND exists (
select 1
from public.staff_profiles sp
where sp.id = loan_applications.assigned_officer_id
and sp.reports_to_id = auth.uid()
)
);

create policy "Admins view all applications"
on public.loan_applications
for select
using (
has_role('admin')
);

create policy "Admins update applications"
on public.loan_applications
for update
using (
has_role('admin')
);

-- =====================================
-- LOAN APPLICATION EVENT POLICIES
-- =====================================

create policy "Borrowers can view own application events"
on public.loan_application_events
for select
using (
exists (
select 1
from public.loan_applications la
where la.id = loan_application_events.application_id
and la.borrower_id = auth.uid()
)
);

create policy "Staff can view application events"
on public.loan_application_events
for select
using (
is_staff()
);

create policy "Staff can create application events"
on public.loan_application_events
for insert
with check (
is_staff()
);

-- =====================================
-- LOAN DOCUMENT POLICIES
-- =====================================

create policy "Owners can insert docs"
on public.loan_documents
for insert
with check (
auth.uid() = owner_id
);

create policy "Borrowers view own documents"
on public.loan_documents
for select
using (
owner_id = auth.uid()
);

create policy "Loan officers view assigned documents"
on public.loan_documents
for select
using (
has_role('loan_officer')
AND exists (
select 1
from public.loan_application_documents lad
join public.loan_applications la
on la.id = lad.application_id
where lad.document_id = loan_documents.id
and la.assigned_officer_id = auth.uid()
)
);

create policy "Managers view team documents"
on public.loan_documents
for select
using (
has_role('manager')
AND exists (
select 1
from public.loan_application_documents lad
join public.loan_applications la
on la.id = lad.application_id
join public.staff_profiles sp
on sp.id = la.assigned_officer_id
where lad.document_id = loan_documents.id
and sp.reports_to_id = auth.uid()
)
);

create policy "Admins view all documents"
on public.loan_documents
for select
using (
has_role('admin')
);

-- =====================================
-- LOAN APPLICATION DOCUMENT POLICIES
-- =====================================

create policy "Borrowers link own documents"
on public.loan_application_documents
for insert
with check (
exists (
select 1
from public.loan_applications la
join public.loan_documents ld
on ld.id = loan_application_documents.document_id
where la.id = loan_application_documents.application_id
and la.borrower_id = auth.uid()
and ld.owner_id = auth.uid()
)
);

create policy "Borrowers view own linked documents"
on public.loan_application_documents
for select
using (
exists (
select 1
from public.loan_applications la
where la.id = loan_application_documents.application_id
and la.borrower_id = auth.uid()
)
);

create policy "Staff view linked documents"
on public.loan_application_documents
for select
using (
is_staff()
);


-- =====================================
-- LOAN PRODUCT POLICIES
-- =====================================

create policy "Users view active loan products"
on public.loan_products
for select
using (
is_active = true
);

create policy "Admins manage loan products"
on public.loan_products
for all
using (
has_role('admin')
);

-- =====================================
-- REQUIRED DOCUMENT POLICIES
-- =====================================

create policy "Users view required documents"
on public.loan_product_required_documents
for select
using (
true
);

create policy "Admins manage required documents"
on public.loan_product_required_documents
for all
using (
has_role('admin')
);

-- =====================================
-- MESSAGE THREAD POLICIES
-- =====================================

create policy "Participants can view threads"
on public.message_threads
for select
using (
auth.uid() = any(participant_ids)
);

create policy "Participants can create threads"
on public.message_threads
for insert
with check (
auth.uid() = any(participant_ids)
);

create policy "Participants can update threads"
on public.message_threads
for update
using (
auth.uid() = any(participant_ids)
);

-- =====================================
-- CHAT MESSAGE POLICIES
-- =====================================

create policy "Senders and thread participants can view"
on public.chat_messages
for select
using (
exists (
select 1
from public.message_threads
where message_threads.id = chat_messages.thread_id
and auth.uid() = any(message_threads.participant_ids)
)
);

create policy "Participants can send messages"
on public.chat_messages
for insert
with check (
sender_id = auth.uid()
AND exists (
select 1
from public.message_threads mt
where mt.id = thread_id
and auth.uid() = any(mt.participant_ids)
)
);

create policy "Participants can update messages"
on public.chat_messages
for update
using (
exists (
select 1
from public.message_threads mt
where mt.id = thread_id
and auth.uid() = any(mt.participant_ids)
)
);

-- =====================================
-- LOAN POLICIES
-- =====================================

create policy "Borrowers view own loans"
on public.loans
for select
using (
auth.uid() = borrower_id
);

create policy "Loan officers view assigned loans"
on public.loans
for select
using (
has_role('loan_officer')
AND exists (
select 1
from public.loan_applications la
where la.id = loans.application_id
and la.assigned_officer_id = auth.uid()
)
);

create policy "Managers view team loans"
on public.loans
for select
using (
has_role('manager')
AND exists (
select 1
from public.loan_applications la
join public.staff_profiles sp
on sp.id = la.assigned_officer_id
where la.id = loans.application_id
and sp.reports_to_id = auth.uid()
)
);

create policy "Admins view all loans"
on public.loans
for select
using (
has_role('admin')
);

-- =====================================
-- EMI POLICIES
-- =====================================

create policy "Borrowers view own EMIs"
on public.emis
for select
using (
exists (
select 1
from public.loans
where loans.id = emis.loan_id
and loans.borrower_id = auth.uid()
)
);

create policy "Loan officers view assigned EMIs"
on public.emis
for select
using (
has_role('loan_officer')
AND exists (
select 1
from public.loans l
join public.loan_applications la
on la.id = l.application_id
where l.id = emis.loan_id
and la.assigned_officer_id = auth.uid()
)
);

create policy "Managers view team EMIs"
on public.emis
for select
using (
has_role('manager')
AND exists (
select 1
from public.loans l
join public.loan_applications la
on la.id = l.application_id
join public.staff_profiles sp
on sp.id = la.assigned_officer_id
where l.id = emis.loan_id
and sp.reports_to_id = auth.uid()
)
);

create policy "Admins view all EMIs"
on public.emis
for select
using (
has_role('admin')
);

-- =====================================
-- AUDIT POLICIES
-- =====================================

create policy "Admins can view audit logs"
on public.audit_entries
for select
using (
has_role('admin')
);

