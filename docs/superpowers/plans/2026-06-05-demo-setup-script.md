# Demo Setup Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a suite of modular Node.js scripts using the `@supabase/supabase-js` client to backup the current database state, wipe all data, and seed a comprehensive demonstration dataset.

**Architecture:** A set of standalone TypeScript files in `lms-backend/src/scripts/demo-setup/` containing a backup script, a truncate script, and a seed script, all orchestrated by `run-all.ts`. Execution requires `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.

**Tech Stack:** TypeScript, Node.js, `@supabase/supabase-js`, `dotenv`.

---

### Task 1: Setup Configuration & Client

**Files:**
- Create: `lms-backend/src/scripts/demo-setup/config.ts`
- Create: `lms-backend/src/scripts/demo-setup/test-config.ts`

- [ ] **Step 1: Write the failing test / execution check**
```typescript
// lms-backend/src/scripts/demo-setup/test-config.ts
import { supabase } from './config';

async function run() {
  if (!process.env.SUPABASE_URL) throw new Error("Missing URL");
  const { data, error } = await supabase.from('loan_products').select('id').limit(1);
  if (error) throw error;
  console.log("Config OK");
}
run().catch(console.error);
```

- [ ] **Step 2: Run test to verify it fails**
Run: `npx ts-node src/scripts/demo-setup/test-config.ts` (from `lms-backend`)
Expected: FAIL with missing file/module error.

- [ ] **Step 3: Write minimal implementation**
```typescript
// lms-backend/src/scripts/demo-setup/config.ts
import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://kezcsrprvhzysftopjqd.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || ''; // Must be provided in env

if (!supabaseKey) {
  throw new Error('SUPABASE_SERVICE_ROLE_KEY is required in environment');
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});
```

- [ ] **Step 4: Run test to verify it passes**
Run: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemNzcnBydmh6eXNmdG9wanFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTI3MTU1MCwiZXhwIjoyMDk0ODQ3NTUwfQ.4r2o-4Y0q7mp9IYVKiDErHp5BCCpVhqFH-xN824TrPM npx ts-node src/scripts/demo-setup/test-config.ts` (from `lms-backend`)
Expected: PASS (prints "Config OK").

- [ ] **Step 5: Commit**
```bash
git add src/scripts/demo-setup/config.ts src/scripts/demo-setup/test-config.ts
git commit -m "feat: add demo setup config and client"
```

---

### Task 2: Implement Backup Script

**Files:**
- Create: `lms-backend/src/scripts/demo-setup/backup.ts`

- [ ] **Step 1: Write the script**
```typescript
// lms-backend/src/scripts/demo-setup/backup.ts
import { supabase } from './config';
import * as fs from 'fs';
import * as path from 'path';

export async function runBackup() {
  console.log('Starting backup...');
  const tables = ['users', 'staff_profiles', 'loan_products', 'loan_applications', 'application_events', 'documents', 'loans', 'emis'];
  const backupData: Record<string, any> = {};

  for (const table of tables) {
    const { data, error } = await supabase.from(table).select('*');
    if (error) throw error;
    backupData[table] = data;
    console.log(`Backed up ${data.length} rows from ${table}`);
  }

  const backupDir = path.join(__dirname, 'backups');
  if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir);

  const filename = path.join(backupDir, `backup_${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
  fs.writeFileSync(filename, JSON.stringify(backupData, null, 2));
  console.log(`Backup saved to ${filename}`);
  return filename;
}

if (require.main === module) {
  runBackup().catch(console.error);
}
```

- [ ] **Step 2: Run script to verify it works**
Run: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemNzcnBydmh6eXNmdG9wanFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTI3MTU1MCwiZXhwIjoyMDk0ODQ3NTUwfQ.4r2o-4Y0q7mp9IYVKiDErHp5BCCpVhqFH-xN824TrPM npx ts-node src/scripts/demo-setup/backup.ts` (from `lms-backend`)
Expected: PASS (prints "Starting backup...", creates file in backups folder).

- [ ] **Step 3: Commit**
```bash
git add src/scripts/demo-setup/backup.ts
git commit -m "feat: add backup script for demo setup"
```

---

### Task 3: Implement Truncate Script

**Files:**
- Create: `lms-backend/src/scripts/demo-setup/truncate.ts`

- [ ] **Step 1: Write the script**
```typescript
// lms-backend/src/scripts/demo-setup/truncate.ts
import { supabase } from './config';

export async function runTruncate() {
  console.log('Starting truncate...');
  
  // 1. Delete all auth users (cascades to public.users and everything else)
  let hasMore = true;
  let page = 1;
  while (hasMore) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw error;
    if (data.users.length === 0) {
      hasMore = false;
      break;
    }
    for (const user of data.users) {
      const { error: delErr } = await supabase.auth.admin.deleteUser(user.id);
      if (delErr) console.error(`Error deleting user ${user.id}`, delErr);
    }
  }
  console.log('Deleted all auth users');

  // 2. Clear remaining tables in reverse dependency order just to be safe
  const tables = ['emis', 'loans', 'application_events', 'documents', 'loan_applications', 'staff_profiles', 'loan_products'];
  for (const table of tables) {
    const { error } = await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000'); // delete all
    if (error) console.log(`Note: clear ${table} returned error (may already be empty):`, error.message);
  }
  console.log('Truncate complete.');
}

if (require.main === module) {
  runTruncate().catch(console.error);
}
```

- [ ] **Step 2: Run script to verify it works**
Run: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemNzcnBydmh6eXNmdG9wanFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTI3MTU1MCwiZXhwIjoyMDk0ODQ3NTUwfQ.4r2o-4Y0q7mp9IYVKiDErHp5BCCpVhqFH-xN824TrPM npx ts-node src/scripts/demo-setup/truncate.ts`
Expected: PASS (prints "Truncate complete.").

- [ ] **Step 3: Commit**
```bash
git add src/scripts/demo-setup/truncate.ts
git commit -m "feat: add truncate script for demo setup"
```

---

### Task 4: Implement Seed Script - Auth and Profiles

**Files:**
- Create: `lms-backend/src/scripts/demo-setup/seed.ts`

- [ ] **Step 1: Write the script (part 1)**
```typescript
// lms-backend/src/scripts/demo-setup/seed.ts
import { supabase } from './config';

export async function runSeed() {
  console.log('Starting seed...');
  
  // Loan Product
  const { data: product, error: prodErr } = await supabase.from('loan_products').insert({
    name: 'Standard Personal Loan', interest_rate: 12.5, max_amount: 500000, min_amount: 10000, tenure_rules: {}
  }).select().single();
  if (prodErr) throw prodErr;

  const users = [
    { email: 'admin@demo.com', role: 'admin', name: 'Admin User' },
    { email: 'manager@demo.com', role: 'manager', name: 'Branch Manager' },
    { email: 'lo_demo@demo.com', role: 'loan_officer', name: 'Demo Officer' },
    { email: 'lo_active@demo.com', role: 'loan_officer', name: 'Active Officer' },
    { email: 'lo_3@demo.com', role: 'loan_officer', name: 'Officer 3' },
    { email: 'lo_4@demo.com', role: 'loan_officer', name: 'Officer 4' },
    { email: 'borrower_new@demo.com', role: 'borrower', name: 'Fresh Borrower' },
    { email: 'borrower_1@demo.com', role: 'borrower', name: 'Borrower 1' },
    { email: 'borrower_2@demo.com', role: 'borrower', name: 'Borrower 2' },
    { email: 'borrower_3@demo.com', role: 'borrower', name: 'Borrower 3' },
    { email: 'borrower_4@demo.com', role: 'borrower', name: 'Borrower 4' },
    { email: 'borrower_5@demo.com', role: 'borrower', name: 'Borrower 5' },
    { email: 'borrower_6@demo.com', role: 'borrower', name: 'Borrower 6' },
    { email: 'borrower_7@demo.com', role: 'borrower', name: 'Borrower 7' },
    { email: 'borrower_8@demo.com', role: 'borrower', name: 'Borrower 8' },
    { email: 'borrower_9@demo.com', role: 'borrower', name: 'Borrower 9' }
  ];

  const userIds: Record<string, string> = {};

  for (const u of users) {
    const { data: authUser, error: authErr } = await supabase.auth.admin.createUser({
      email: u.email, password: 'Password123!', email_confirm: true
    });
    if (authErr) throw authErr;
    userIds[u.email] = authUser.user.id;

    // Supabase triggers may auto-create the public.users row, we update it.
    await supabase.from('users').update({
      role: u.role, full_name: u.name, phone: '555-000-0000'
    }).eq('id', authUser.user.id);

    if (u.role !== 'borrower') {
      await supabase.from('staff_profiles').insert({
        employee_id: `EMP-${Math.floor(Math.random()*10000)}`,
        department: 'Operations', designation: u.role, workload_info: {}, id: authUser.user.id
      });
    }
  }

  console.log('Auth and base data seeded.');
}

if (require.main === module) {
  runSeed().catch(console.error);
}
```

- [ ] **Step 2: Run script to verify it works**
Run: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemNzcnBydmh6eXNmdG9wanFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTI3MTU1MCwiZXhwIjoyMDk0ODQ3NTUwfQ.4r2o-4Y0q7mp9IYVKiDErHp5BCCpVhqFH-xN824TrPM npx ts-node src/scripts/demo-setup/seed.ts`
Expected: PASS (prints "Auth and base data seeded.").

- [ ] **Step 3: Commit**
```bash
git add src/scripts/demo-setup/seed.ts
git commit -m "feat: add seed script (part 1 auth)"
```

---

### Task 5: Implement Seed Script - Applications & Workflow

**Files:**
- Modify: `lms-backend/src/scripts/demo-setup/seed.ts:54-55` (Append below line 54 `console.log('Auth and base data seeded.');`)

- [ ] **Step 1: Write the script modification**
```typescript
  // Helper to create application + events
  const createApp = async (borrowerEmail: string, officerEmail: string, status: string, amount: number) => {
    const { data: app, error } = await supabase.from('loan_applications').insert({
      borrower_id: userIds[borrowerEmail],
      assigned_officer_id: userIds[officerEmail],
      status, requested_amount: amount, tenure_months: 12, interest_rate: product.interest_rate, loan_product_id: product.id
    }).select().single();
    if (error) throw error;
    
    const events = [
      { application_id: app.id, actor_id: userIds[borrowerEmail], event_type: 'submitted', to_status: 'submitted' },
      { application_id: app.id, actor_id: userIds['admin@demo.com'], event_type: 'assigned', to_status: 'assigned' }
    ];
    if (status !== 'submitted' && status !== 'assigned') {
      events.push({ application_id: app.id, actor_id: userIds[officerEmail], event_type: 'review_started', to_status: 'under_review' });
    }
    if (status === 'document_pending') {
      events.push({ application_id: app.id, actor_id: userIds[officerEmail], event_type: 'documents_requested', to_status: 'document_pending' });
    }
    if (status === 'pending_manager_approval') {
      events.push({ application_id: app.id, actor_id: userIds[officerEmail], event_type: 'sent_to_manager', to_status: 'pending_manager_approval' });
    }
    if (status === 'approved' || status === 'active' || status === 'disbursed') {
      events.push({ application_id: app.id, actor_id: userIds[officerEmail], event_type: 'sent_to_manager', to_status: 'pending_manager_approval' });
      events.push({ application_id: app.id, actor_id: userIds['manager@demo.com'], event_type: 'approved', to_status: 'approved' });
    }
    await supabase.from('application_events').insert(events);
    return app;
  };

  // Demo LO
  const app1 = await createApp('borrower_1@demo.com', 'lo_demo@demo.com', 'disbursed', 100000); // Disbursed, >30 days overdue
  const app2 = await createApp('borrower_2@demo.com', 'lo_demo@demo.com', 'disbursed', 50000); // Disbursed, <30 days overdue
  await createApp('borrower_3@demo.com', 'lo_demo@demo.com', 'pending_manager_approval', 150000);
  await createApp('borrower_4@demo.com', 'lo_demo@demo.com', 'document_pending', 20000);
  await createApp('borrower_5@demo.com', 'lo_demo@demo.com', 'under_review', 30000);

  // Active LO
  await createApp('borrower_6@demo.com', 'lo_active@demo.com', 'rejected', 40000);
  await createApp('borrower_7@demo.com', 'lo_active@demo.com', 'submitted', 60000);
  await createApp('borrower_8@demo.com', 'lo_active@demo.com', 'approved', 80000);

  // Helper to create loan and EMIs
  const createLoan = async (app: any, daysOverdue: number) => {
    const disburseDate = new Date();
    disburseDate.setDate(disburseDate.getDate() - (daysOverdue + 45)); // Ensure the first EMI (due 30 days later) is overdue

    const { data: loan, error } = await supabase.from('loans').insert({
      application_id: app.id, borrower_id: app.borrower_id, principal: app.requested_amount, interest_rate: app.interest_rate,
      tenure_months: app.tenure_months, disbursement_date: disburseDate.toISOString().split('T')[0], outstanding_balance: app.requested_amount, status: 'active'
    }).select().single();
    if (error) throw error;

    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() - daysOverdue);

    await supabase.from('emis').insert({
      loan_id: loan.id, installment_number: 1, due_date: dueDate.toISOString().split('T')[0],
      principal_component: app.requested_amount / app.tenure_months, interest_component: 500, total_amount: (app.requested_amount / app.tenure_months) + 500,
      payment_status: 'pending' // Overdue
    });
  };

  await createLoan(app1, 40); // > 30 days overdue
  await createLoan(app2, 10); // < 30 days overdue

  console.log('Applications and Loans seeded.');
```

- [ ] **Step 2: Run script to verify it works**
Run: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemNzcnBydmh6eXNmdG9wanFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTI3MTU1MCwiZXhwIjoyMDk0ODQ3NTUwfQ.4r2o-4Y0q7mp9IYVKiDErHp5BCCpVhqFH-xN824TrPM npx ts-node src/scripts/demo-setup/seed.ts`
Expected: PASS (prints "Applications and Loans seeded.").

- [ ] **Step 3: Commit**
```bash
git add src/scripts/demo-setup/seed.ts
git commit -m "feat: complete seed script with workflows and loans"
```

---

### Task 6: Implement Orchestrator

**Files:**
- Create: `lms-backend/src/scripts/demo-setup/run-all.ts`

- [ ] **Step 1: Write the script**
```typescript
// lms-backend/src/scripts/demo-setup/run-all.ts
import { runBackup } from './backup';
import { runTruncate } from './truncate';
import { runSeed } from './seed';

async function main() {
  console.log('--- DEMO SETUP START ---');
  try {
    await runBackup();
    await runTruncate();
    await runSeed();
    console.log('--- DEMO SETUP COMPLETE ---');
  } catch (error) {
    console.error('Demo setup failed:', error);
    process.exit(1);
  }
}

main();
```

- [ ] **Step 2: Run script to verify it works**
Run: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemNzcnBydmh6eXNmdG9wanFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTI3MTU1MCwiZXhwIjoyMDk0ODQ3NTUwfQ.4r2o-4Y0q7mp9IYVKiDErHp5BCCpVhqFH-xN824TrPM npx ts-node src/scripts/demo-setup/run-all.ts`
Expected: PASS (prints all logs sequentially and COMPLETE).

- [ ] **Step 3: Commit**
```bash
git add src/scripts/demo-setup/run-all.ts
git commit -m "feat: add orchestrator for demo setup"
```
