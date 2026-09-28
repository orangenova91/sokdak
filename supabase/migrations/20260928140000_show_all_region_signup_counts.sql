-- 지역별 가입 수는 0명이어도 그대로 보여 준다.

create or replace function public.region_signup_stats()
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
    coalesce(c.n, 0),
    false
  from public.regions r
  join public.region_teacher_counts t on t.region_code = r.code
  left join counts c on c.region_code = r.code
  order by r.sort_order;
$$;

revoke all on function public.region_signup_stats() from public, anon, authenticated;
grant execute on function public.region_signup_stats() to authenticated;
