-- Profile additions: extra personal-info fields on users + seed values.
-- Run this after schema.sql + seed.sql.

alter table users
  add column if not exists email              text,
  add column if not exists phone              text,
  add column if not exists date_of_birth      date,
  add column if not exists citizenship        text,
  add column if not exists address            text,
  add column if not exists weight_kg          numeric,
  add column if not exists height_cm          numeric,
  add column if not exists eyes_color         text,
  add column if not exists complexion         text,
  add column if not exists birth_country      text,
  add column if not exists birth_province     text,
  add column if not exists birth_municipality text,
  add column if not exists marital_status     text;

update users set
  full_name          = 'Lualhati Recto',
  email              = 'lualhatirecto@gmail.com',
  phone              = '+63 966 452 9917',
  date_of_birth      = '1990-05-14',
  citizenship        = 'Filipino',
  address            = '123 Mabini St, Brgy. San Isidro, Quezon City, Metro Manila, Philippines',
  weight_kg          = 55,
  height_cm          = 157,
  eyes_color         = 'Brown',
  complexion         = 'Fair',
  birth_country      = 'Philippines',
  birth_province     = 'Metro Manila',
  birth_municipality = 'Quezon City',
  marital_status     = 'Single'
where id = '11111111-1111-1111-1111-111111111111';

-- Keep the ID card consistent with the profile name.
update id_cards set full_name = 'LUALHATI RECTO'
where user_id = '11111111-1111-1111-1111-111111111111';
