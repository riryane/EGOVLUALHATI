-- Seed data for the eGovLualhati MVP demo.
-- Fixed UUIDs so the client (CURRENT_USER_ID) and card links are deterministic.

insert into users (id, full_name, location, avatar_url) values
  ('11111111-1111-1111-1111-111111111111',
   'Lualhati Dela Cruz',
   'Metro Manila',
   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4AOT-gxCM6tq8X9shPsAa6OTtSESBDJ8RUFkAfk5uv_6S8nCj7kr_mAc&s=10');

insert into assistance
  (id, user_id, program_name, agency, category, assistance_type, description,
   subtitle, amount_label, eligibility_status, eligibility_title, eligibility_desc,
   requirements, accent_color, primary_action, sort_order)
values
  ('a0000000-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111',
   'Pantawid Pamilyang Pilipino Program (4Ps)', 'DSWD', 'Cash Aid', 'For Pick-up',
   'Conditional cash transfer for the poorest of the poor to improve health, nutrition, and education.',
   null, 'Variable amount', 'possible', 'Possibly Eligible',
   'You meet 2 out of 3 requirements. Complete the rest to apply.',
   '[{"text":"Income below threshold (PHP 12,000)","met":true},{"text":"Has children aged 0-18 in the household","met":true},{"text":"Complies with health and education conditions","met":false}]'::jsonb,
   '#f59e0b', 'Apply Now', 1),

  ('a0000000-0000-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111111',
   'Assistance to Individuals in Crisis Situation (AICS)', 'DSWD', 'Cash Aid', 'For Pick-up',
   'Financial assistance for medical, educational, burial, or transportation needs.',
   null, 'Up to PHP 10,000', 'eligible', 'Eligible',
   'You meet all the requirements for this program.',
   '[{"text":"Filipino citizen in a crisis situation","met":true},{"text":"Valid government-issued ID","met":true}]'::jsonb,
   '#10b981', 'Apply Now', 2),

  ('a0000000-0000-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111111',
   'TUPAD Program', 'DOLE', 'Livelihood', 'For Pick-up',
   'Emergency employment for displaced workers, underemployed, and seasonal workers.',
   null, 'Regional Wage Rate', 'possible', 'Possibly Eligible',
   'You meet 1 out of 2 requirements. Complete the rest to apply.',
   '[{"text":"Displaced, underemployed, or seasonal worker","met":true},{"text":"Not a beneficiary of a similar program","met":false}]'::jsonb,
   '#0ea5e9', 'Apply Now', 3),

  ('a0000000-0000-0000-0000-000000000004',
   '11111111-1111-1111-1111-111111111111',
   'CHED Tulong Dunong Program', 'CHED', 'Livelihood', 'For Pick-up',
   'Financial assistance for qualified and deserving college students.',
   null, 'PHP 15,000 / year', 'eligible', 'Eligible',
   'You meet all the requirements for this program.',
   '[{"text":"Enrolled in a recognized higher education institution","met":true},{"text":"Family income below threshold","met":true}]'::jsonb,
   '#8b5cf6', 'Apply Now', 4),

  ('a0000000-0000-0000-0000-000000000005',
   '11111111-1111-1111-1111-111111111111',
   'Ayuda Food Pack', 'DSWD', 'Health', 'For Pick-up',
   'Free food packs for indigent families in your barangay.',
   'Free Food for the Family', null, 'eligible', 'Eligible',
   'You meet all the requirements for this program.',
   '[{"text":"Resident of Brgy. San Isidro, Quezon City","met":true},{"text":"Included in the list of indigent families","met":true}]'::jsonb,
   '#10b981', 'Set Reminder', 5);

insert into id_cards
  (user_id, id_type, id_number, full_name, date_of_birth, sex, address, photo_url, date_issued)
values
  ('11111111-1111-1111-1111-111111111111',
   'PhilSys National ID', '1234-5678-9012-3456', 'LUALHATI M. DELA CRUZ',
   '1990-05-14', 'Female',
   '123 Mabini St, Brgy. San Isidro, Quezon City, Metro Manila',
   'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4AOT-gxCM6tq8X9shPsAa6OTtSESBDJ8RUFkAfk5uv_6S8nCj7kr_mAc&s=10',
   '2023-08-01');
