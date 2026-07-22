-- Ayuda applications: one row per submitted application.
-- Status lifecycle: pending → approved → for_pickup → done, or rejected.
-- Run this after schema.sql + seed.sql.

create table applications (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references users(id),
  assistance_id uuid references assistance(id),
  status        text not null default 'pending',
  -- 'pending' | 'approved' | 'rejected' | 'for_pickup' | 'done'
  applied_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Demo history for every existing user: one past application per program,
-- covering the whole status lifecycle.
insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'done', '2026-06-10'
from assistance where program_name like 'Assistance to Individuals%';

insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'for_pickup', '2026-07-15'
from assistance where program_name = 'TUPAD Program';

insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'approved', '2026-07-18'
from assistance where program_name = 'CHED Tulong Dunong Program';

insert into applications (user_id, assistance_id, status, applied_at)
select user_id, id, 'rejected', '2026-05-20'
from assistance where program_name like 'Pantawid%';
