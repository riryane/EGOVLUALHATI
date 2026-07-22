-- Per-program document requirements.
-- Each assistance row gets its own `documents` list:
--   { name, source, verified } — verified=false means the citizen must capture it.
-- Run this after schema.sql + seed.sql.

alter table assistance add column if not exists documents jsonb default '[]'::jsonb;

-- 4Ps
update assistance set documents = '[
  {"name": "PSA Birth Certificate",                  "source": "eGov",    "verified": true},
  {"name": "National ID (PhilSys)",                  "source": "PhilSys", "verified": true},
  {"name": "SSS Employment Record",                  "source": null,      "verified": false},
  {"name": "Proof of Billing / Barangay Certificate","source": null,      "verified": false}
]'::jsonb where id = 'a0000000-0000-0000-0000-000000000001';

-- AICS
update assistance set documents = '[
  {"name": "National ID (PhilSys)",                  "source": "PhilSys", "verified": true},
  {"name": "Barangay Certificate of Indigency",      "source": null,      "verified": false},
  {"name": "Medical / Burial / Educational Document","source": null,      "verified": false}
]'::jsonb where id = 'a0000000-0000-0000-0000-000000000002';

-- TUPAD
update assistance set documents = '[
  {"name": "National ID (PhilSys)",                  "source": "PhilSys", "verified": true},
  {"name": "SSS Employment Record",                  "source": null,      "verified": false},
  {"name": "Barangay Residency Certificate",         "source": null,      "verified": false}
]'::jsonb where id = 'a0000000-0000-0000-0000-000000000003';

-- CHED Tulong Dunong
update assistance set documents = '[
  {"name": "PSA Birth Certificate",                  "source": "eGov",    "verified": true},
  {"name": "National ID (PhilSys)",                  "source": "PhilSys", "verified": true},
  {"name": "Certificate of Enrollment",              "source": null,      "verified": false},
  {"name": "Latest Grades / Report Card",            "source": null,      "verified": false}
]'::jsonb where id = 'a0000000-0000-0000-0000-000000000004';

-- Ayuda Food Pack: claimed in person, no application documents.
update assistance set documents = '[]'::jsonb
where id = 'a0000000-0000-0000-0000-000000000005';
