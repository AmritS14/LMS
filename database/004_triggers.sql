-- =====================================
-- AUTH USER CREATION TRIGGER
-- =====================================

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- =====================================
-- UPDATED_AT TRIGGERS
-- =====================================

create trigger set_loan_applications_updated_at
before update on public.loan_applications
for each row
execute function public.set_updated_at();

create trigger set_message_threads_updated_at
before update on public.message_threads
for each row
execute function public.set_updated_at();

