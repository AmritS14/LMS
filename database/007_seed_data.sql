-- =====================================
-- DEFAULT LOAN PRODUCTS
-- =====================================

insert into public.loan_products (
id,
name,
description,
minimum_amount,
maximum_amount,
minimum_tenure_months,
maximum_tenure_months,
minimum_interest_rate,
maximum_interest_rate,
is_active
)
values

(
gen_random_uuid(),
'Personal Loan',
'General purpose unsecured personal loan',
10000,
1000000,
6,
60,
10,
18,
true
),

(
gen_random_uuid(),
'Home Loan',
'Residential home financing loan',
500000,
50000000,
60,
360,
7,
12,
true
),

(
gen_random_uuid(),
'Vehicle Loan',
'Vehicle financing loan',
50000,
5000000,
12,
84,
8,
15,
true
);

-- =====================================
-- DEFAULT REQUIRED DOCUMENTS
-- =====================================

insert into public.loan_product_required_documents (
loan_product_id,
document_type,
is_mandatory
)
select
lp.id,
d.document_type,
d.is_mandatory
from public.loan_products lp
join (
values

```
-- Personal Loan
('Personal Loan', 'pan_card'::required_document_type, true),
('Personal Loan', 'aadhaar_card'::required_document_type, true),
('Personal Loan', 'salary_slip'::required_document_type, true),
('Personal Loan', 'bank_statement'::required_document_type, true),

-- Home Loan
('Home Loan', 'pan_card'::required_document_type, true),
('Home Loan', 'aadhaar_card'::required_document_type, true),
('Home Loan', 'salary_slip'::required_document_type, true),
('Home Loan', 'bank_statement'::required_document_type, true),
('Home Loan', 'itr'::required_document_type, true),

-- Vehicle Loan
('Vehicle Loan', 'pan_card'::required_document_type, true),
('Vehicle Loan', 'aadhaar_card'::required_document_type, true),
('Vehicle Loan', 'bank_statement'::required_document_type, true),
('Vehicle Loan', 'itr'::required_document_type, false)
```

) as d(product_name, document_type, is_mandatory)
on lp.name = d.product_name;

