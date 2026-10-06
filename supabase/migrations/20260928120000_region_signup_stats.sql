-- 시도교육청별 가입 비율.
-- 분모는 2026 교육기본통계의 시도 소계 교원수(정규+기간제). 직원·강사와
-- 고등학교 유형 내역(일반고 등)은 넣지 않는다.
-- 5명 미만인 교육청은 인원을 돌려주지 않는다.

create table public.region_teacher_counts (
  region_code text primary key references public.regions (code),
  teacher_count int not null check (teacher_count > 0),
  stats_year int not null
);

insert into public.region_teacher_counts (region_code, teacher_count, stats_year) values
  ('seoul',     70816,  2026),
  ('busan',     28236,  2026),
  ('daegu',     22982,  2026),
  ('incheon',   28131,  2026),
  ('gwangju',   15650,  2026),
  ('daejeon',   15405,  2026),
  ('ulsan',     11457,  2026),
  ('sejong',    6563,   2026),
  ('gyeonggi',  134020, 2026),
  ('gangwon',   16399,  2026),
  ('chungbuk',  17363,  2026),
  ('chungnam',  25070,  2026),
  ('jeonbuk',   21233,  2026),
  ('jeonnam',   21965,  2026),
  ('gyeongbuk', 27548,  2026),
  ('gyeongnam', 35420,  2026),
  ('jeju',      7287,   2026);

alter table public.region_teacher_counts enable row level security;
revoke all on public.region_teacher_counts from anon, authenticated;

create function public.region_signup_stats()
returns table (
  region_code text,
  region_name text,
  sort_order int,
  teacher_count int,
  stats_year int,
  signup_count int,
  suppressed boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with counts as (
    select profiles.region_code, count(*)::int as n
    from public.profiles
    group by profiles.region_code
  )
  select
    r.code,
    r.name,
    r.sort_order,
    t.teacher_count,
    t.stats_year,
    case when coalesce(c.n, 0) >= 5 then coalesce(c.n, 0) else null end,
    coalesce(c.n, 0) < 5
  from public.regions r
  join public.region_teacher_counts t on t.region_code = r.code
  left join counts c on c.region_code = r.code
  order by r.sort_order;
$$;

revoke all on function public.region_signup_stats() from public, anon, authenticated;
grant execute on function public.region_signup_stats() to authenticated;
