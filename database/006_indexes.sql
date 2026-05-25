-- =====================================
-- LOAN APPLICATION INDEXES
-- =====================================

create index if not exists idx_loan_applications_borrower_id
on public.loan_applications(borrower_id);

create index if not exists idx_loan_applications_assigned_officer_id
on public.loan_applications(assigned_officer_id);

create index if not exists idx_loan_applications_loan_product_id
on public.loan_applications(loan_product_id);

create index if not exists idx_loan_applications_status
on public.loan_applications(status);

-- =====================================
-- STAFF PROFILE INDEXES
-- =====================================

create index if not exists idx_staff_profiles_reports_to_id
on public.staff_profiles(reports_to_id);

-- =====================================
-- LOAN DOCUMENT INDEXES
-- =====================================

create index if not exists idx_loan_documents_owner_id
on public.loan_documents(owner_id);

create index if not exists idx_loan_documents_status
on public.loan_documents(status);

-- =====================================
-- LOAN APPLICATION DOCUMENT INDEXES
-- =====================================

create index if not exists idx_loan_application_documents_application_id
on public.loan_application_documents(application_id);

create index if not exists idx_loan_application_documents_document_id
on public.loan_application_documents(document_id);

-- =====================================
-- LOAN APPLICATION EVENT INDEXES
-- =====================================

create index if not exists idx_loan_application_events_application_id
on public.loan_application_events(application_id);

create index if not exists idx_loan_application_events_created_at
on public.loan_application_events(created_at);

-- =====================================
-- MESSAGE THREAD INDEXES
-- =====================================

create index if not exists idx_message_threads_application_id
on public.message_threads(application_id);

create index if not exists idx_message_threads_updated_at
on public.message_threads(updated_at);

-- =====================================
-- CHAT MESSAGE INDEXES
-- =====================================

create index if not exists idx_chat_messages_thread_id
on public.chat_messages(thread_id);

create index if not exists idx_chat_messages_sent_at
on public.chat_messages(sent_at);

-- =====================================
-- LOAN INDEXES
-- =====================================

create index if not exists idx_loans_application_id
on public.loans(application_id);

create index if not exists idx_loans_borrower_id
on public.loans(borrower_id);

create index if not exists idx_loans_status
on public.loans(status);

-- =====================================
-- EMI INDEXES
-- =====================================

create index if not exists idx_emis_loan_id
on public.emis(loan_id);

create index if not exists idx_emis_due_date
on public.emis(due_date);

create index if not exists idx_emis_status
on public.emis(status);

