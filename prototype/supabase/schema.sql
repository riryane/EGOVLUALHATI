-- eGovLualhati MVP schema — 3 tables, minimal fields only.
-- No RLS, no auth. Buildless client reads with the anon key.

create table users (
  id         uuid primary key default gen_random_uuid(),
  full_name  text not null,        -- greeting uses the given name uppercased
  location   text,                 -- "Metro Manila"
  avatar_url text
);

create table assistance (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid references users(id),
  program_name      text not null,      -- "Pantawid Pamilyang Pilipino Program (4Ps)"
  agency            text,               -- "DSWD" | "DOLE" | "CHED"
  category          text,               -- "Health" | "Cash Aid" | "Livelihood"
  assistance_type   text,               -- "Cash Transfer" | "In-Kind Assistance"
  description       text,               -- card body copy
  subtitle          text,               -- in-kind only, e.g. "Free Food for the Family"
  amount_label      text,               -- "Up to PHP 10,000"
  eligibility_status text,              -- 'eligible' | 'possible' (maps to CSS class)
  eligibility_title text,               -- "Eligible" | "Possibly Eligible"
  eligibility_desc  text,               -- "You meet all the requirements…"
  requirements      jsonb,              -- [{ "text": "...", "met": true }]
  accent_color      text,               -- hex tint for the card icon
  primary_action    text,               -- "Apply Now" | "Set Reminder"
  sort_order        int default 0
);

create table id_cards (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users(id),
  id_type       text,          -- "PhilSys National ID"
  id_number     text,          -- "1234-5678-9012-3456"
  full_name     text,          -- as printed on the card
  date_of_birth date,
  sex           text,
  address       text,
  photo_url     text,
  date_issued   date
);
