-- Migration: eligibility rules engine + privacy consent + appeals + claim codes.
-- Run once in the Supabase SQL Editor.

alter table assistance   add column if not exists rules jsonb default '[]'::jsonb;
alter table users        add column if not exists consented_at timestamptz;
alter table applications add column if not exists citizen_note text,
                         add column if not exists claim_code text,
                         add column if not exists claim_code_expires_at timestamptz,
                         add column if not exists admin_note text;

-- Eligibility rules per program (applies to every user's copy).
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
