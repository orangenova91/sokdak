-- 교무실 속닥속닥: 초기 스키마
-- 가입은 Supabase 익명 로그인(auth.users)으로 처리하고, 앱 프로필은 public.profiles에 둔다.

-- ---------------------------------------------------------------------------
-- 참조 데이터
-- ---------------------------------------------------------------------------

create table public.regions (
  code text primary key,
  name text not null,
  is_active boolean not null default false, -- 글쓰기가 열린 지역
  sort_order int not null default 0
);

insert into public.regions (code, name, is_active, sort_order) values
  ('seoul',     '서울', false, 1),
  ('busan',     '부산', false, 2),
  ('daegu',     '대구', false, 3),
  ('incheon',   '인천', false, 4),
  ('gwangju',   '광주', false, 5),
  ('daejeon',   '대전', false, 6),
  ('ulsan',     '울산', true,  7),
  ('sejong',    '세종', false, 8),
  ('gyeonggi',  '경기', false, 9),
  ('gangwon',   '강원', false, 10),
  ('chungbuk',  '충북', false, 11),
  ('chungnam',  '충남', false, 12),
  ('jeonbuk',   '전북', false, 13),
  ('jeonnam',   '전남', false, 14),
  ('gyeongbuk', '경북', false, 15),
  ('gyeongnam', '경남', false, 16),
  ('jeju',      '제주', false, 17);

create table public.categories (
  board text not null check (board in ('sokdak', 'knowhow')),
  code text not null,
  name text not null,
  sort_order int not null default 0,
  primary key (board, code)
);

insert into public.categories (board, code, name, sort_order) values
  ('sokdak',  'vent',     '푸념',       1),
  ('sokdak',  'cheer',    '위로·응원',  2),
  ('sokdak',  'daily',    '일상·잡담',  3),
  ('knowhow', 'class',    '수업',       1),
  ('knowhow', 'admin',    '업무·행정',  2),
  ('knowhow', 'homeroom', '학급경영',   3),
  ('knowhow', 'parents',  '학부모 응대', 4),
  ('knowhow', 'records',  '생활기록부', 5),
  ('knowhow', 'welfare',  '복지·인사',  6);

-- 운영 정책 스위치. 코드 수정 없이 값만 바꿔서 정책을 전환한다.
create table public.app_settings (
  key text primary key,
  value jsonb not null
);

insert into public.app_settings (key, value) values
  ('require_verified_to_post', 'false'),  -- true로 바꾸면 글쓰기는 인증 교사만
  ('report_hide_threshold',    '3');      -- 신고 N건 누적 시 자동 숨김

create function public.setting_bool(k text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce((select (value #>> '{}')::boolean from public.app_settings where key = k), false);
$$;

create function public.setting_int(k text, fallback int)
returns int
language sql stable security definer set search_path = public
as $$
  select coalesce((select (value #>> '{}')::int from public.app_settings where key = k), fallback);
$$;

-- ---------------------------------------------------------------------------
-- 프로필
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 12),
  region_code text not null references public.regions (code),
  school_level text not null
    check (school_level in ('elementary', 'middle', 'high', 'special', 'other')),
  is_verified boolean not null default false,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 교사 인증 (Edge Function만 접근. 클라이언트 정책 없음)
-- 이메일 원문은 저장하지 않고 서버 비밀값을 섞은 HMAC 해시만 저장한다.
-- verified_identities에는 user_id를 두지 않아 해시와 계정이 연결되지 않는다.
-- ---------------------------------------------------------------------------

create table public.allowed_email_domains (
  domain text primary key,
  region_code text references public.regions (code), -- 도메인으로 지역이 확정되면 지정
  note text
);

insert into public.allowed_email_domains (domain, region_code, note) values
  ('korea.kr',  null,    '정부 공무원 메일'),
  ('use.go.kr', 'ulsan', '울산광역시교육청 (실제 도메인 확인 필요)');

create table public.verified_identities (
  email_hash text primary key,
  verified_at timestamptz not null default now()
);

-- 인증 코드 발송~확인 사이에만 존재하는 임시 행. 성공하면 삭제한다.
create table public.verification_requests (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email_hash text not null,
  code_hash text not null,
  attempts int not null default 0,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 콘텐츠
-- ---------------------------------------------------------------------------

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  board text not null,
  category text not null,
  region_code text not null references public.regions (code),
  author_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title text check (title is null or char_length(title) <= 100),
  body text not null check (char_length(body) between 1 and 5000),
  is_hidden boolean not null default false,
  comment_count int not null default 0,
  reaction_count int not null default 0,
  report_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (board, category) references public.categories (board, code)
);

create index posts_feed_idx on public.posts (region_code, board, created_at desc)
  where not is_hidden;
create index posts_author_idx on public.posts (author_id);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  parent_id uuid references public.comments (id) on delete cascade,
  author_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  is_hidden boolean not null default false,
  like_count int not null default 0,
  report_count int not null default 0,
  created_at timestamptz not null default now()
);

create index comments_post_idx on public.comments (post_id, created_at);
create index comments_author_idx on public.comments (author_id);

-- 속닥방 공감: 좋아요 / 나도 그래요 / 힘내요
create table public.post_reactions (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('like', 'me_too', 'cheer')),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id, kind)
);

create table public.comment_likes (
  comment_id uuid not null references public.comments (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('post', 'comment')),
  target_id uuid not null,
  reason text not null
    check (reason in ('abuse', 'privacy', 'defamation', 'spam', 'other')),
  created_at timestamptz not null default now(),
  unique (reporter_id, target_type, target_id)
);

create table public.blocks (
  blocker_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

-- ---------------------------------------------------------------------------
-- 트리거: 수정 시각, 집계 카운터, 신고 누적 자동 숨김
-- 카운터와 is_hidden은 클라이언트가 직접 못 바꾸므로 security definer로 갱신한다.
-- ---------------------------------------------------------------------------

create function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger posts_touch_updated_at
  before update on public.posts
  for each row execute function public.touch_updated_at();

create function public.bump_comment_count()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  else
    update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;

create trigger comments_bump_count
  after insert or delete on public.comments
  for each row execute function public.bump_comment_count();

create function public.bump_reaction_count()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set reaction_count = reaction_count + 1 where id = new.post_id;
  else
    update public.posts set reaction_count = greatest(reaction_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;

create trigger post_reactions_bump_count
  after insert or delete on public.post_reactions
  for each row execute function public.bump_reaction_count();

create function public.bump_comment_like_count()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.comments set like_count = like_count + 1 where id = new.comment_id;
  else
    update public.comments set like_count = greatest(like_count - 1, 0) where id = old.comment_id;
  end if;
  return null;
end;
$$;

create trigger comment_likes_bump_count
  after insert or delete on public.comment_likes
  for each row execute function public.bump_comment_like_count();

create function public.apply_report()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  threshold int := public.setting_int('report_hide_threshold', 3);
begin
  if new.target_type = 'post' then
    update public.posts
       set report_count = report_count + 1,
           is_hidden = is_hidden or (report_count + 1 >= threshold)
     where id = new.target_id;
  else
    update public.comments
       set report_count = report_count + 1,
           is_hidden = is_hidden or (report_count + 1 >= threshold)
     where id = new.target_id;
  end if;
  return null;
end;
$$;

create trigger reports_apply
  after insert on public.reports
  for each row execute function public.apply_report();
