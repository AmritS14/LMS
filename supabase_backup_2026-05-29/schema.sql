-- ============================================================================
-- Supabase backup: public schema DDL
-- Project: kezcsrprvhzysftopjqd
-- Captured: 2026-05-29
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Enums
-- ----------------------------------------------------------------------------
do $$ begin
    create type public.user_role as enum ('borrower','loan_officer','manager','admin');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.application_status as enum ('draft','submitted','assigned','under_review','document_pending','manager_review','approved','rejected','disbursed','closed');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.application_event_type as enum ('submitted','assigned','review_started','document_requested','documents_uploaded','sent_to_manager','approved','rejected','comment_added','status_changed','auto_assigned','manually_reassigned','manager_review_started','disbursed','closed');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.document_kind as enum ('identityProof','addressProof','incomeProof','bankStatement','collateral','other');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.document_verification_status as enum ('pending','verified','rejected');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.emi_status as enum ('upcoming','paid','overdue');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.employment_type as enum ('salaried','selfEmployed','business','retired','unemployed');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.kyc_status as enum ('pending','submitted','verified','rejected');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.loan_status as enum ('active','overdue','defaulted','foreclosed','settled','closed');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.loan_type as enum ('personal','home','vehicle','education','business');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.required_document_type as enum ('pan_card','aadhaar_card','salary_slip','bank_statement','itr','passport_photo','employment_certificate','address_proof','other');
exception when duplicate_object then null; end $$;

-- Legacy "_old" types preserved for completeness (left from prior migrations).
do $$ begin
    create type public.user_role_old as enum ('borrower','loanOfficer','manager','admin');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.application_status_old as enum ('draft','submitted','underReview','additionalInfoRequired','recommended','approved','rejected','disbursed','closed');
exception when duplicate_object then null; end $$;

do $$ begin
    create type public.application_event_type_old as enum ('submitted','assigned','under_review','document_requested','documents_uploaded','recommended','escalated','approved','rejected','comment_added');
exception when duplicate_object then null; end $$;

-- ----------------------------------------------------------------------------
-- Tables
-- ----------------------------------------------------------------------------
create table if not exists public.users (
    id                    uuid primary key references auth.users(id) on delete cascade,
    full_name             text not null,
    email                 text not null unique,
    phone                 text,
    created_at            timestamptz default now(),
    role                  public.user_role,
    must_change_password  boolean default false,
    is_active             boolean default true,
    mfa_required          boolean default false,
    last_login_at         timestamptz
);

create table if not exists public.borrower_profiles (
    id              uuid primary key references public.users(id) on delete cascade,
    date_of_birth   date,
    address_line1   text,
    address_line2   text,
    city            text,
    state           text,
    pin_code        integer,
    country         text,
    pan_number      text,
    aadhaar_last4   text,
    employment_type public.employment_type,
    monthly_income  numeric,
    kyc_status      public.kyc_status default 'pending',
    credit_score    integer
);

create table if not exists public.staff_profiles (
    id             uuid primary key references public.users(id) on delete cascade,
    employee_id    text not null unique,
    branch_id      uuid,
    department     text,
    reports_to_id  uuid references public.users(id)
);

create table if not exists public.loan_products (
    id                    uuid primary key default gen_random_uuid(),
    name                  text not null unique,
    description           text,
    minimum_amount        numeric,
    maximum_amount        numeric,
    minimum_tenure_months integer,
    maximum_tenure_months integer,
    minimum_interest_rate numeric,
    maximum_interest_rate numeric,
    is_active             boolean default true,
    created_at            timestamptz default now()
);

create table if not exists public.loan_product_required_documents (
    id              uuid primary key default gen_random_uuid(),
    loan_product_id uuid not null references public.loan_products(id) on delete cascade,
    document_type   public.required_document_type not null,
    is_mandatory    boolean default true,
    created_at      timestamptz default now(),
    unique (loan_product_id, document_type)
);

create table if not exists public.loan_applications (
    id                  uuid primary key default gen_random_uuid(),
    borrower_id         uuid not null references public.users(id),
    assigned_officer_id uuid references public.users(id),
    requested_amount    numeric not null,
    tenure_months       integer not null,
    interest_rate       double precision not null,
    created_at          timestamptz default now(),
    updated_at          timestamptz default now(),
    status              public.application_status,
    loan_product_id     uuid not null references public.loan_products(id)
);

create table if not exists public.loan_documents (
    id          uuid primary key default gen_random_uuid(),
    owner_id    uuid not null references public.users(id),
    kind        public.document_kind not null,
    file_name   text not null,
    remote_url  text,
    status      public.document_verification_status default 'pending',
    uploaded_at timestamptz default now()
);

create table if not exists public.loan_application_documents (
    application_id uuid not null references public.loan_applications(id) on delete cascade,
    document_id    uuid not null references public.loan_documents(id) on delete cascade,
    linked_at      timestamptz default now(),
    primary key (application_id, document_id)
);

create table if not exists public.loans (
    id                  uuid primary key default gen_random_uuid(),
    application_id      uuid not null references public.loan_applications(id),
    borrower_id         uuid not null references public.users(id),
    principal           numeric not null,
    interest_rate       double precision not null,
    tenure_months       integer not null,
    disbursement_date   date not null,
    outstanding_balance numeric not null,
    status              public.loan_status default 'active'
);

create table if not exists public.emis (
    id                  uuid primary key default gen_random_uuid(),
    loan_id             uuid not null references public.loans(id) on delete cascade,
    installment_number  integer not null,
    due_date            date not null,
    principal_component numeric not null,
    interest_component  numeric not null,
    total_amount        numeric not null,
    status              public.emi_status default 'upcoming',
    paid_at             timestamptz
);

create table if not exists public.message_threads (
    id                   uuid primary key default gen_random_uuid(),
    participant_ids      uuid[] not null,
    application_id       uuid references public.loan_applications(id),
    last_message_preview text,
    updated_at           timestamptz default now()
);

create table if not exists public.chat_messages (
    id        uuid primary key default gen_random_uuid(),
    thread_id uuid not null references public.message_threads(id) on delete cascade,
    sender_id uuid not null references public.users(id),
    body      text not null,
    sent_at   timestamptz default now(),
    read_at   timestamptz
);

create table if not exists public.audit_entries (
    id          uuid primary key default gen_random_uuid(),
    actor_id    uuid not null references public.users(id),
    action      text not null,
    entity_type text not null,
    entity_id   uuid not null,
    metadata    jsonb default '{}'::jsonb,
    timestamp   timestamptz default now(),
    actor_role  public.user_role
);

create table if not exists public.loan_application_events (
    id             uuid primary key default gen_random_uuid(),
    application_id uuid not null references public.loan_applications(id) on delete cascade,
    actor_id       uuid references public.users(id),
    remark         text,
    metadata       jsonb default '{}'::jsonb,
    created_at     timestamptz default now(),
    event_type     public.application_event_type,
    from_status    public.application_status,
    to_status      public.application_status
);

-- ----------------------------------------------------------------------------
-- Indexes (non-PK / non-unique already declared above)
-- ----------------------------------------------------------------------------
create index if not exists idx_chat_messages_thread_id            on public.chat_messages(thread_id);
create index if not exists idx_emis_loan_id                       on public.emis(loan_id);
create index if not exists idx_loan_application_documents_application_id on public.loan_application_documents(application_id);
create index if not exists idx_loan_application_documents_document_id    on public.loan_application_documents(document_id);
create index if not exists idx_loan_application_events_application_id    on public.loan_application_events(application_id);
create index if not exists idx_loan_applications_assigned_officer_id     on public.loan_applications(assigned_officer_id);
create index if not exists idx_loan_applications_borrower_id             on public.loan_applications(borrower_id);
create index if not exists idx_loan_applications_loan_product_id         on public.loan_applications(loan_product_id);
create index if not exists idx_loan_documents_owner_id                   on public.loan_documents(owner_id);
create index if not exists idx_loans_application_id                      on public.loans(application_id);
create index if not exists idx_loans_borrower_id                         on public.loans(borrower_id);
create index if not exists idx_message_threads_application_id            on public.message_threads(application_id);
create index if not exists idx_staff_profiles_reports_to_id              on public.staff_profiles(reports_to_id);

-- ----------------------------------------------------------------------------
-- Functions
-- ----------------------------------------------------------------------------
create or replace function public.has_role(required_role public.user_role)
returns boolean
language sql
stable security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.users
    where id = auth.uid() and role = required_role
  );
$$;

create or replace function public.is_management()
returns boolean
language sql
stable security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.users
    where id = auth.uid() and role in ('manager','admin')
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.users
    where id = auth.uid() and role in ('loan_officer','manager','admin')
  );
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  if coalesce((new.raw_app_meta_data->>'skip_auto_profile')::boolean, false) then
    return new;
  end if;

  insert into public.users (id, email, full_name, phone, role, must_change_password, mfa_required)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'contact_phone',
    'borrower',
    false,
    false
  );

  insert into public.borrower_profiles (id) values (new.id);
  return new;
end;
$$;

create or replace function public.rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path to 'pg_catalog'
as $$
declare
  cmd record;
begin
  for cmd in
    select * from pg_event_trigger_ddl_commands()
    where command_tag in ('CREATE TABLE','CREATE TABLE AS','SELECT INTO')
      and object_type in ('table','partitioned table')
  loop
    if cmd.schema_name is not null
       and cmd.schema_name in ('public')
       and cmd.schema_name not in ('pg_catalog','information_schema')
       and cmd.schema_name not like 'pg_toast%'
       and cmd.schema_name not like 'pg_temp%' then
      begin
        execute format('alter table if exists %s enable row level security', cmd.object_identity);
        raise log 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      exception when others then
        raise log 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      end;
    else
      raise log 'rls_auto_enable: skip % (system schema or not in enforced list)', cmd.object_identity;
    end if;
  end loop;
end;
$$;

-- ----------------------------------------------------------------------------
-- Triggers
-- ----------------------------------------------------------------------------
drop trigger if exists set_loan_applications_updated_at on public.loan_applications;
create trigger set_loan_applications_updated_at
before update on public.loan_applications
for each row execute function public.set_updated_at();

drop trigger if exists set_message_threads_updated_at on public.message_threads;
create trigger set_message_threads_updated_at
before update on public.message_threads
for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- Row Level Security
-- ----------------------------------------------------------------------------
alter table public.users                            enable row level security;
alter table public.borrower_profiles                enable row level security;
alter table public.staff_profiles                   enable row level security;
alter table public.loan_products                    enable row level security;
alter table public.loan_product_required_documents  enable row level security;
alter table public.loan_applications                enable row level security;
alter table public.loan_documents                   enable row level security;
alter table public.loan_application_documents       enable row level security;
alter table public.loans                            enable row level security;
alter table public.emis                             enable row level security;
alter table public.message_threads                  enable row level security;
alter table public.chat_messages                    enable row level security;
alter table public.audit_entries                    enable row level security;
alter table public.loan_application_events          enable row level security;

-- Policies (see policies.sql block below; consolidated here for restore convenience)

-- users
create policy "Users can read own profile"   on public.users for select using (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
create policy "Admins can read all users"    on public.users for select using (public.has_role('admin'::public.user_role));
create policy "Admins update users"          on public.users for update using (public.has_role('admin'::public.user_role)) with check (public.has_role('admin'::public.user_role));

-- borrower_profiles
create policy "Borrowers can view own profile"   on public.borrower_profiles for select using (auth.uid() = id);
create policy "Borrowers can update own profile" on public.borrower_profiles for update using (auth.uid() = id);

-- staff_profiles
create policy "Staff view own profile"   on public.staff_profiles for select using (id = auth.uid());
create policy "Admins view all staff"    on public.staff_profiles for select using (public.has_role('admin'::public.user_role));
create policy "Admins manage staff"      on public.staff_profiles for all    using (public.has_role('admin'::public.user_role));
create policy "Managers view team staff" on public.staff_profiles for select using (public.has_role('manager'::public.user_role) and reports_to_id = auth.uid());

-- loan_products
create policy "Users view active loan products" on public.loan_products for select using (is_active = true);
create policy "Admins manage loan products"     on public.loan_products for all    using (public.has_role('admin'::public.user_role));

-- loan_product_required_documents
create policy "Users view required documents"   on public.loan_product_required_documents for select using (true);
create policy "Admins manage required documents" on public.loan_product_required_documents for all   using (public.has_role('admin'::public.user_role));

-- loan_applications
create policy "Borrowers can view own applications" on public.loan_applications for select using (auth.uid() = borrower_id);
create policy "Borrowers can create applications"   on public.loan_applications for insert with check (auth.uid() = borrower_id and public.has_role('borrower'::public.user_role));
create policy "Loan officers view assigned applications" on public.loan_applications for select using (public.has_role('loan_officer'::public.user_role) and assigned_officer_id = auth.uid());
create policy "Loan officers update assigned applications" on public.loan_applications for update using (public.has_role('loan_officer'::public.user_role) and assigned_officer_id = auth.uid());
create policy "Managers view team applications" on public.loan_applications for select using (public.has_role('manager'::public.user_role) and exists (select 1 from public.staff_profiles sp where sp.id = loan_applications.assigned_officer_id and sp.reports_to_id = auth.uid()));
create policy "Managers update team applications" on public.loan_applications for update using (public.has_role('manager'::public.user_role) and exists (select 1 from public.staff_profiles sp where sp.id = loan_applications.assigned_officer_id and sp.reports_to_id = auth.uid()));
create policy "Admins view all applications" on public.loan_applications for select using (public.has_role('admin'::public.user_role));
create policy "Admins update applications"   on public.loan_applications for update using (public.has_role('admin'::public.user_role));

-- loan_documents
create policy "Borrowers view own documents" on public.loan_documents for select using (owner_id = auth.uid());
create policy "Owners can insert docs"       on public.loan_documents for insert with check (auth.uid() = owner_id);
create policy "Loan officers view assigned documents" on public.loan_documents for select using (public.has_role('loan_officer'::public.user_role) and exists (select 1 from public.loan_application_documents lad join public.loan_applications la on la.id = lad.application_id where lad.document_id = loan_documents.id and la.assigned_officer_id = auth.uid()));
create policy "Managers view team documents" on public.loan_documents for select using (public.has_role('manager'::public.user_role) and exists (select 1 from public.loan_application_documents lad join public.loan_applications la on la.id = lad.application_id join public.staff_profiles sp on sp.id = la.assigned_officer_id where lad.document_id = loan_documents.id and sp.reports_to_id = auth.uid()));
create policy "Admins view all documents"    on public.loan_documents for select using (public.has_role('admin'::public.user_role));

-- loan_application_documents
create policy "Borrowers view own linked documents" on public.loan_application_documents for select using (exists (select 1 from public.loan_applications la where la.id = loan_application_documents.application_id and la.borrower_id = auth.uid()));
create policy "Borrowers link own documents"        on public.loan_application_documents for insert with check (exists (select 1 from public.loan_applications la join public.loan_documents ld on ld.id = loan_application_documents.document_id where la.id = loan_application_documents.application_id and la.borrower_id = auth.uid() and ld.owner_id = auth.uid()));
create policy "Staff view linked documents"         on public.loan_application_documents for select using (public.is_staff());

-- loans
create policy "Borrowers view own loans"        on public.loans for select using (auth.uid() = borrower_id);
create policy "Loan officers view assigned loans" on public.loans for select using (public.has_role('loan_officer'::public.user_role) and exists (select 1 from public.loan_applications la where la.id = loans.application_id and la.assigned_officer_id = auth.uid()));
create policy "Managers view team loans"        on public.loans for select using (public.has_role('manager'::public.user_role) and exists (select 1 from public.loan_applications la join public.staff_profiles sp on sp.id = la.assigned_officer_id where la.id = loans.application_id and sp.reports_to_id = auth.uid()));
create policy "Admins view all loans"           on public.loans for select using (public.has_role('admin'::public.user_role));

-- emis
create policy "Borrowers view own EMIs"          on public.emis for select using (exists (select 1 from public.loans where loans.id = emis.loan_id and loans.borrower_id = auth.uid()));
create policy "Loan officers view assigned EMIs" on public.emis for select using (public.has_role('loan_officer'::public.user_role) and exists (select 1 from public.loans l join public.loan_applications la on la.id = l.application_id where l.id = emis.loan_id and la.assigned_officer_id = auth.uid()));
create policy "Managers view team EMIs"          on public.emis for select using (public.has_role('manager'::public.user_role) and exists (select 1 from public.loans l join public.loan_applications la on la.id = l.application_id join public.staff_profiles sp on sp.id = la.assigned_officer_id where l.id = emis.loan_id and sp.reports_to_id = auth.uid()));
create policy "Admins view all EMIs"             on public.emis for select using (public.has_role('admin'::public.user_role));

-- message_threads
create policy "Participants can view threads"   on public.message_threads for select using (auth.uid() = any (participant_ids));
create policy "Participants can create threads" on public.message_threads for insert with check (auth.uid() = any (participant_ids));
create policy "Participants can update threads" on public.message_threads for update using (auth.uid() = any (participant_ids));

-- chat_messages
create policy "Senders and thread participants can view" on public.chat_messages for select using (exists (select 1 from public.message_threads mt where mt.id = chat_messages.thread_id and auth.uid() = any (mt.participant_ids)));
create policy "Participants can send messages"            on public.chat_messages for insert with check (sender_id = auth.uid() and exists (select 1 from public.message_threads mt where mt.id = chat_messages.thread_id and auth.uid() = any (mt.participant_ids)));
create policy "Participants can update messages"          on public.chat_messages for update using (exists (select 1 from public.message_threads mt where mt.id = chat_messages.thread_id and auth.uid() = any (mt.participant_ids)));

-- audit_entries
create policy "Admins can view audit logs" on public.audit_entries for select using (public.has_role('admin'::public.user_role));

-- loan_application_events
create policy "Borrowers can view own application events" on public.loan_application_events for select using (exists (select 1 from public.loan_applications la where la.id = loan_application_events.application_id and la.borrower_id = auth.uid()));
create policy "Staff can view application events"         on public.loan_application_events for select using (public.is_staff());
create policy "Staff can create application events"       on public.loan_application_events for insert with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- Grants
-- ----------------------------------------------------------------------------
grant insert, update, delete on public.loan_products to authenticated;
grant update on public.users to authenticated;

-- ----------------------------------------------------------------------------
-- auth.users trigger (calls handle_new_user)
-- ----------------------------------------------------------------------------
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- Audit Triggers and RPC integration
-- ----------------------------------------------------------------------------

-- RPC for client-side logging of non-table events
create or replace function public.log_audit_event(
    p_action text,
    p_entity_type text,
    p_entity_id uuid,
    p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
    v_actor_id uuid;
    v_actor_role public.user_role;
    v_audit_id uuid;
begin
    v_actor_id := auth.uid();
    if v_actor_id is null then
        raise exception 'No authenticated user session found';
    end if;

    select role into v_actor_role
    from public.users
    where id = v_actor_id;

    insert into public.audit_entries (
        actor_id,
        action,
        entity_type,
        entity_id,
        metadata,
        actor_role
    ) values (
        v_actor_id,
        p_action,
        p_entity_type,
        p_entity_id,
        p_metadata,
        v_actor_role
    ) returning id into v_audit_id;

    return v_audit_id;
end;
$$;

grant execute on function public.log_audit_event(text, text, uuid, jsonb) to authenticated;

-- General trigger function to log table-level changes
create or replace function public.log_table_change_to_audit()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
    v_actor_id uuid;
    v_actor_role public.user_role;
    v_action text;
    v_entity_type text;
    v_entity_id uuid;
    v_metadata jsonb := '{}'::jsonb;
begin
    v_actor_id := auth.uid();
    if v_actor_id is null then
        select id, role into v_actor_id, v_actor_role
        from public.users
        where role = 'admin'
        limit 1;
        
        if v_actor_id is null then
            return coalesce(NEW, OLD);
        end if;
    else
        select role into v_actor_role
        from public.users
        where id = v_actor_id;
    end if;

    if TG_TABLE_NAME = 'loan_products' then
        v_entity_type := 'loan_product';
        if TG_OP = 'INSERT' then
            v_entity_id := NEW.id;
            v_action := 'Created Loan Product';
            v_metadata := jsonb_build_object('name', NEW.name);
        elsif TG_OP = 'UPDATE' then
            v_entity_id := NEW.id;
            v_action := 'Updated Loan Product';
            v_metadata := jsonb_build_object('name', NEW.name);
        elsif TG_OP = 'DELETE' then
            v_entity_id := OLD.id;
            v_action := 'Deleted Loan Product';
            v_metadata := jsonb_build_object('name', OLD.name);
        end if;

    elsif TG_TABLE_NAME = 'loans' then
        v_entity_type := 'loan';
        if TG_OP = 'INSERT' then
            v_entity_id := NEW.id;
            v_action := 'Created Loan';
            v_metadata := jsonb_build_object('status', NEW.status);
        elsif TG_OP = 'UPDATE' then
            v_entity_id := NEW.id;
            if OLD.status is distinct from NEW.status then
                if NEW.status = 'archived' then
                    v_action := 'Archived Loan';
                elsif NEW.status = 'active' and OLD.status = 'archived' then
                    v_action := 'Restored Loan';
                else
                    v_action := 'Updated Loan Status';
                end if;
            else
                v_action := 'Updated Loan';
            end if;
            v_metadata := jsonb_build_object('status', NEW.status);
        elsif TG_OP = 'DELETE' then
            v_entity_id := OLD.id;
            v_action := 'Deleted Loan';
            v_metadata := jsonb_build_object('status', OLD.status);
        end if;

    elsif TG_TABLE_NAME = 'users' then
        v_entity_type := 'user';
        if TG_OP = 'UPDATE' then
            v_entity_id := NEW.id;
            if OLD.role is distinct from NEW.role and OLD.is_active is distinct from NEW.is_active then
                v_action := 'Updated User Role and Status';
                v_metadata := jsonb_build_object('new_role', NEW.role, 'is_active', NEW.is_active);
            elsif OLD.role is distinct from NEW.role then
                v_action := 'Updated User Role to ' || NEW.role;
                v_metadata := jsonb_build_object('new_role', NEW.role);
            elsif OLD.is_active is distinct from NEW.is_active then
                if NEW.is_active then
                    v_action := 'Activated User';
                else
                    v_action := 'Deactivated User';
                end if;
                v_metadata := jsonb_build_object('is_active', NEW.is_active);
            else
                return NEW;
            end if;
        elsif TG_OP = 'DELETE' then
            v_entity_id := OLD.id;
            v_action := 'Deleted User';
            v_metadata := jsonb_build_object('email', OLD.email);
        else
            return NEW;
        end if;

    elsif TG_TABLE_NAME = 'sanction_letters' then
        v_entity_type := 'loan_application';
        if TG_OP = 'INSERT' then
            v_entity_id := NEW.loan_application_id;
            v_action := 'Sanction Letter Generated';
            v_metadata := jsonb_build_object('ref', NEW.pdf_path);
        elsif TG_OP = 'UPDATE' then
            v_entity_id := NEW.loan_application_id;
            if OLD.status is distinct from NEW.status then
                if NEW.status = 'sent' then
                    v_action := 'Sanction Letter Sent';
                elsif NEW.status = 'accepted' or (OLD.is_accepted = false and NEW.is_accepted = true) then
                    v_action := 'Sanction Letter Accepted';
                else
                    v_action := 'Updated Sanction Letter';
                end if;
            else
                v_action := 'Updated Sanction Letter';
            end if;
            v_metadata := jsonb_build_object('status', NEW.status);
        elsif TG_OP = 'DELETE' then
            v_entity_id := OLD.loan_application_id;
            v_action := 'Deleted Sanction Letter';
        end if;
    end if;

    if v_action is not null then
        insert into public.audit_entries (
            actor_id,
            action,
            entity_type,
            entity_id,
            metadata,
            actor_role
        ) values (
            v_actor_id,
            v_action,
            v_entity_type,
            v_entity_id,
            v_metadata,
            v_actor_role
        );
    end if;

    return coalesce(NEW, OLD);
end;
$$;

drop trigger if exists audit_loan_products_trigger on public.loan_products;
create trigger audit_loan_products_trigger
after insert or update or delete on public.loan_products
for each row execute function public.log_table_change_to_audit();

drop trigger if exists audit_loans_trigger on public.loans;
create trigger audit_loans_trigger
after insert or update or delete on public.loans
for each row execute function public.log_table_change_to_audit();

drop trigger if exists audit_users_trigger on public.users;
create trigger audit_users_trigger
after update or delete on public.users
for each row execute function public.log_table_change_to_audit();

drop trigger if exists audit_sanction_letters_trigger on public.sanction_letters;
create trigger audit_sanction_letters_trigger
after insert or update or delete on public.sanction_letters
for each row execute function public.log_table_change_to_audit();

