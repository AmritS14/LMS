-- =====================================
-- ROLE CHECK HELPER
-- =====================================

create or replace function public.has_role(
required_role user_role
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
select exists (
select 1
from public.users
where id = auth.uid()
and role = required_role
and is_active = true
);
$$;

-- =====================================
-- STAFF CHECK HELPER
-- =====================================

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
select exists (
select 1
from public.users
where id = auth.uid()
and role in (
'loan_officer',
'manager',
'admin'
)
and is_active = true
);
$$;

-- =====================================
-- NEW USER HANDLER
-- =====================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

-- Skip automatic borrower provisioning
-- for admin-created staff accounts
if coalesce(
(new.raw_app_meta_data->>'skip_auto_profile')::boolean,
false
) then
return new;
end if;

insert into public.users (
id,
email,
full_name,
role,
must_change_password,
mfa_required
)
values (
new.id,
new.email,
coalesce(
new.raw_user_meta_data->>'full_name',
''
),
'borrower',
false,
false
);

insert into public.borrower_profiles (
id
)
values (
new.id
);

return new;
end;
$$;

-- =====================================
-- UPDATED_AT HELPER
-- =====================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
new.updated_at = now();
return new;
end;
$$;

