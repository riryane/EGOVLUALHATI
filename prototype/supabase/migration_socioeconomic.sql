-- Migration: socio-economic profile fields from the eGov SSO payload.
-- These feed the eligibility rules engine (income_below, occupation_required,
-- education_recent). Run once in the Supabase SQL Editor.

alter table users
  add column if not exists occupation      text,
  add column if not exists industry        text,
  add column if not exists expected_salary text,   -- SSO bracket, e.g. "130,001-180,000"
  add column if not exists education       jsonb,  -- SSO educational_attainment list
  add column if not exists region          text,
  add column if not exists barangay        text;
