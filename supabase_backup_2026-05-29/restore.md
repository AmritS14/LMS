# Restore notes

## Order of operations
1. Create a fresh Supabase project (or reset target schema).
2. Run `schema.sql` against the database (e.g. via `psql` or the SQL editor).
3. Import `auth.users` first — either re-invite via the Auth admin API or
   use the GoTrue admin import endpoint. The trigger
   `on_auth_user_created` will auto-create `public.users` + `public.borrower_profiles`
   rows for borrower-style new users; for staff/admin you'll need to set
   `raw_app_meta_data->>'skip_auto_profile' = 'true'` before insert OR delete
   the auto-created rows and re-insert from the backup.
4. Load `data/*.json` files in this order to satisfy FK constraints:
   - users
   - borrower_profiles
   - staff_profiles
   - loan_products
   - loan_product_required_documents
   - loan_applications
   - loan_documents
   - loan_application_documents
   - loans
   - emis
   - message_threads
   - chat_messages
   - audit_entries
   - loan_application_events
5. Re-create the `loan_documents` storage bucket using `storage_buckets.json`
   and upload object bodies (not in this backup — see README).
6. Replay `migrations.json` entries into `supabase_migrations.schema_migrations`
   if you want the migration history to match.

## Loading JSON data
A simple loader (psql + `jsonb_to_recordset`) example:

```sql
insert into public.loan_products
select * from jsonb_to_recordset(
  pg_read_file('/path/to/data/loan_products.json')::jsonb
) as x(
  id uuid, name text, description text, minimum_amount numeric,
  maximum_amount numeric, minimum_tenure_months int, maximum_tenure_months int,
  minimum_interest_rate numeric, maximum_interest_rate numeric,
  is_active boolean, created_at timestamptz
);
```

Adjust the column list per table. For arrays (`message_threads.participant_ids`)
cast via `::uuid[]`.
