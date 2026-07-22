-- eGov SSO support: bind eGovPH accounts to local users.
-- Run this after schema.sql + seed.sql + profile.sql.

alter table users add column if not exists egov_uniqid text unique;
