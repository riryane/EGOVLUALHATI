-- ============================================================
-- eGovLualhati — COMPLETE database setup (run once, in full,
-- in the Supabase SQL Editor of a fresh project).
-- Replaces running schema/seed/profile/sso/documents/applications
-- files individually. Reflects the final MVP state.
-- ============================================================

-- ---------- tables ----------

create table users (
  id                 uuid primary key default gen_random_uuid(),
  full_name          text not null,
  location           text,
  avatar_url         text,
  email              text,
  phone              text,
  date_of_birth      date,
  citizenship        text,
  address            text,
  weight_kg          numeric,
  height_cm          numeric,
  eyes_color         text,
  complexion         text,
  birth_country      text,
  birth_province     text,
  birth_municipality text,
  marital_status     text,
  egov_uniqid        text unique,
  consented_at       timestamptz,
  occupation         text,
  industry           text,
  expected_salary    text,
  education          jsonb,
  region             text,
  barangay           text
);

create table assistance (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid references users(id) on delete cascade,
  program_name       text not null,
  agency             text,
  category           text,               -- Health | Cash Aid | Livelihood
  assistance_type    text,               -- all For Pick-up in this MVP
  description        text,
  subtitle           text,
  amount_label       text,
  eligibility_status text,               -- 'eligible' | 'possible'
  eligibility_title  text,
  eligibility_desc   text,
  requirements       jsonb,              -- [{text, met}]
  documents          jsonb default '[]'::jsonb, -- [{name, source, verified}]
  accent_color       text,
  primary_action     text,               -- 'Apply Now' | 'Set Reminder'
  sort_order         int default 0,
  rules              jsonb default '[]'::jsonb  -- eligibility rules (see eligibility.js)
);

create table id_cards (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users(id) on delete cascade,
  id_type       text,
  id_number     text,
  full_name     text,
  date_of_birth date,
  sex           text,
  address       text,
  photo_url     text,
  date_issued   date
);

create table applications (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users(id) on delete cascade,
  assistance_id uuid references assistance(id) on delete cascade,
  status        text not null default 'pending',
  -- pending | info_requested | approved | rejected | for_pickup | done
  applied_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  claim_code            text,
  claim_code_expires_at timestamptz,
  admin_note            text,
  citizen_note          text,
  submitted_documents   jsonb
);

-- MVP: no row level security anywhere.
alter table users        disable row level security;
alter table assistance   disable row level security;
alter table id_cards     disable row level security;
alter table applications disable row level security;

-- ---------- seed: demo citizen (also the catalog template for SSO users) ----------

insert into users (id, full_name, location, avatar_url, email, phone, date_of_birth,
                   citizenship, address, weight_kg, height_cm, eyes_color, complexion,
                   birth_country, birth_province, birth_municipality, marital_status) values
  ('11111111-1111-1111-1111-111111111111',
   'Lualhati Recto', 'Metro Manila',
   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4AOT-gxCM6tq8X9shPsAa6OTtSESBDJ8RUFkAfk5uv_6S8nCj7kr_mAc&s=10',
   'lualhatirecto@gmail.com', '+63 966 452 9917', '1990-05-14',
   'Filipino', '123 Mabini St, Brgy. San Isidro, Quezon City, Metro Manila, Philippines',
   55, 157, 'Brown', 'Fair', 'Philippines', 'Metro Manila', 'Quezon City', 'Single');

insert into assistance
  (id, user_id, program_name, agency, category, assistance_type, description,
   subtitle, amount_label, eligibility_status, eligibility_title, eligibility_desc,
   requirements, documents, accent_color, primary_action, sort_order)
values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'Pantawid Pamilyang Pilipino Program (4Ps)', 'DSWD', 'Cash Aid', 'For Pick-up',
   'Conditional cash transfer for the poorest of the poor to improve health, nutrition, and education.',
   null, 'Variable amount', 'possible', 'Possibly Eligible',
   'You meet 2 out of 3 requirements. Complete the rest to apply.',
   '[{"text":"Income below threshold (PHP 12,000)","met":true},{"text":"Has children aged 0-18 in the household","met":true},{"text":"Complies with health and education conditions","met":false}]'::jsonb,
   '[{"name":"PSA Birth Certificate","source":"eGov","verified":true},{"name":"National ID (PhilSys)","source":"PhilSys","verified":true},{"name":"SSS Employment Record","source":null,"verified":false},{"name":"Proof of Billing / Barangay Certificate","source":null,"verified":false}]'::jsonb,
   '#f59e0b', 'Apply Now', 1),

  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   'Assistance to Individuals in Crisis Situation (AICS)', 'DSWD', 'Cash Aid', 'For Pick-up',
   'Financial assistance for medical, educational, burial, or transportation needs.',
   null, 'Up to PHP 10,000', 'eligible', 'Eligible',
   'You meet all the requirements for this program.',
   '[{"text":"Filipino citizen in a crisis situation","met":true},{"text":"Valid government-issued ID","met":true}]'::jsonb,
   '[{"name":"National ID (PhilSys)","source":"PhilSys","verified":true},{"name":"Barangay Certificate of Indigency","source":null,"verified":false},{"name":"Medical / Burial / Educational Document","source":null,"verified":false}]'::jsonb,
   '#10b981', 'Apply Now', 2),

  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'TUPAD Program', 'DOLE', 'Livelihood', 'For Pick-up',
   'Emergency employment for displaced workers, underemployed, and seasonal workers.',
   null, 'Regional Wage Rate', 'possible', 'Possibly Eligible',
   'You meet 1 out of 2 requirements. Complete the rest to apply.',
   '[{"text":"Displaced, underemployed, or seasonal worker","met":true},{"text":"Not a beneficiary of a similar program","met":false}]'::jsonb,
   '[{"name":"National ID (PhilSys)","source":"PhilSys","verified":true},{"name":"SSS Employment Record","source":null,"verified":false},{"name":"Barangay Residency Certificate","source":null,"verified":false}]'::jsonb,
   '#0ea5e9', 'Apply Now', 3),

  ('a0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111',
   'CHED Tulong Dunong Program', 'CHED', 'Livelihood', 'For Pick-up',
   'Financial assistance for qualified and deserving college students.',
   null, 'PHP 15,000 / year', 'eligible', 'Eligible',
   'You meet all the requirements for this program.',
   '[{"text":"Enrolled in a recognized higher education institution","met":true},{"text":"Family income below threshold","met":true}]'::jsonb,
   '[{"name":"PSA Birth Certificate","source":"eGov","verified":true},{"name":"National ID (PhilSys)","source":"PhilSys","verified":true},{"name":"Certificate of Enrollment","source":null,"verified":false},{"name":"Latest Grades / Report Card","source":null,"verified":false}]'::jsonb,
   '#8b5cf6', 'Apply Now', 4),

  ('a0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111',
   'Ayuda Food Pack', 'DSWD', 'Health', 'For Pick-up',
   'Free food packs for indigent families in your barangay.',
   'Free Food for the Family', null, 'eligible', 'Eligible',
   'You meet all the requirements for this program.',
   '[{"text":"Resident of Brgy. San Isidro, Quezon City","met":true},{"text":"Included in the list of indigent families","met":true}]'::jsonb,
   '[]'::jsonb,
   '#10b981', 'Set Reminder', 5);

insert into id_cards
  (user_id, id_type, id_number, full_name, date_of_birth, sex, address, photo_url, date_issued)
values
  ('11111111-1111-1111-1111-111111111111',
   'PhilSys National ID', '1234-5678-9012-3456', 'LUALHATI RECTO',
   '1990-05-14', 'Female',
   '123 Mabini St, Brgy. San Isidro, Quezon City, Metro Manila',
   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4AOT-gxCM6tq8X9shPsAa6OTtSESBDJ8RUFkAfk5uv_6S8nCj7kr_mAc&s=10',
   '2023-08-01');

-- ---------- seed: demo application history ----------

insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'done', '2026-06-10' from assistance where program_name like 'Assistance to Individuals%';
insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'for_pickup', '2026-07-15' from assistance where program_name = 'TUPAD Program';
insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'approved', '2026-07-18' from assistance where program_name = 'CHED Tulong Dunong Program';

-- ---------- eligibility rules ----------

update assistance set rules = '[
  {"type": "age_range", "min": 18, "max": 65},
  {"type": "residency", "keyword": "Quezon City"},
  {"type": "profile_complete", "fields": ["date_of_birth", "address", "phone"]},
  {"type": "no_active_same_category"}
]'::jsonb where program_name like 'Pantawid%';

update assistance set rules = '[
  {"type": "age_range", "min": 18, "max": 100},
  {"type": "profile_complete", "fields": ["date_of_birth", "address", "phone"]},
  {"type": "no_active_same_category"}
]'::jsonb where program_name like 'Assistance to Individuals%';

update assistance set rules = '[
  {"type": "age_range", "min": 18, "max": 60},
  {"type": "profile_complete", "fields": ["date_of_birth", "address", "phone"]},
  {"type": "no_active_same_category"}
]'::jsonb where program_name = 'TUPAD Program';

update assistance set rules = '[
  {"type": "age_range", "min": 16, "max": 30},
  {"type": "profile_complete", "fields": ["date_of_birth", "address"]},
  {"type": "no_active_same_category"}
]'::jsonb where program_name = 'CHED Tulong Dunong Program';

update assistance set rules = '[
  {"type": "residency", "keyword": "Quezon City"},
  {"type": "profile_complete", "fields": ["address"]}
]'::jsonb where program_name = 'Ayuda Food Pack';
