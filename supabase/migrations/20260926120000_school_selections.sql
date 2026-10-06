-- 급식 대시보드용 소속 학교 선택(나이스 학교기본정보 기준).
-- profiles와 분리된 별도 테이블이다: profiles는 모든 로그인 사용자에게 읽기가 열려 있어
-- (닉네임 등 게시글 표시용) 여기 넣으면 학교 정보가 다른 이용자에게도 노출된다.
-- 이 테이블은 본인만 읽고 쓸 수 있다.

create table public.school_selections (
  user_id uuid primary key references auth.users (id) on delete cascade,
  office_code text not null,
  school_code text not null,
  school_name text not null,
  updated_at timestamptz not null default now()
);

alter table public.school_selections enable row level security;
revoke all on public.school_selections from anon, authenticated;

grant select on public.school_selections to authenticated;
grant insert (user_id, office_code, school_code, school_name)
  on public.school_selections to authenticated;
grant update (office_code, school_code, school_name)
  on public.school_selections to authenticated;
grant delete on public.school_selections to authenticated;

create policy school_selections_read on public.school_selections for select to authenticated
  using (user_id = auth.uid());
create policy school_selections_insert on public.school_selections for insert to authenticated
  with check (user_id = auth.uid());
create policy school_selections_update on public.school_selections for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy school_selections_delete on public.school_selections for delete to authenticated
  using (user_id = auth.uid());

create trigger school_selections_touch_updated_at
  before update on public.school_selections
  for each row execute function public.touch_updated_at();
