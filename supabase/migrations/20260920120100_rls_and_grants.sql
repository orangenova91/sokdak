-- 접근 제어: 모든 테이블 RLS 활성화 + 컬럼 단위 권한 최소화
-- 익명 로그인 사용자도 role은 authenticated 이므로 anon에는 아무 권한도 주지 않는다.

alter table public.regions               enable row level security;
alter table public.categories            enable row level security;
alter table public.app_settings          enable row level security;
alter table public.profiles              enable row level security;
alter table public.allowed_email_domains enable row level security;
alter table public.verified_identities   enable row level security;
alter table public.verification_requests enable row level security;
alter table public.posts                 enable row level security;
alter table public.comments              enable row level security;
alter table public.post_reactions        enable row level security;
alter table public.comment_likes         enable row level security;
alter table public.reports               enable row level security;
alter table public.blocks                enable row level security;

-- 기본 부여 권한을 걷어내고 필요한 것만 다시 부여
revoke all on
  public.regions, public.categories, public.app_settings, public.profiles,
  public.allowed_email_domains, public.verified_identities, public.verification_requests,
  public.posts, public.comments, public.post_reactions, public.comment_likes,
  public.reports, public.blocks
from anon, authenticated;

-- 인증 관련 3개 테이블은 정책도 권한도 없다. service_role(Edge Function)만 접근한다.

-- 참조 데이터: 읽기 전용
grant select on public.regions, public.categories to authenticated;
create policy regions_read    on public.regions    for select to authenticated using (true);
create policy categories_read on public.categories for select to authenticated using (true);
-- app_settings는 클라이언트에 노출하지 않는다.

-- 프로필
grant select on public.profiles to authenticated;
grant insert (id, nickname, region_code, school_level) on public.profiles to authenticated;
grant update (nickname, region_code, school_level) on public.profiles to authenticated;

create policy profiles_read   on public.profiles for select to authenticated using (true);
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- 게시글
grant select on public.posts to authenticated;
grant insert (board, category, region_code, title, body) on public.posts to authenticated;
grant update (category, title, body) on public.posts to authenticated;
grant delete on public.posts to authenticated;

create policy posts_read on public.posts for select to authenticated
  using (
    author_id = auth.uid()
    or (
      not is_hidden
      and not exists (
        select 1 from public.blocks b
         where b.blocker_id = auth.uid() and b.blocked_id = posts.author_id
      )
    )
  );

-- 글쓰기: 본인 프로필 지역에만, 글쓰기가 열린 지역에서만.
-- require_verified_to_post 가 true가 되면 인증 교사만 쓸 수 있다.
create policy posts_insert on public.posts for insert to authenticated
  with check (
    author_id = auth.uid()
    and posts.region_code = (select p.region_code from public.profiles p where p.id = auth.uid())
    and exists (select 1 from public.regions r where r.code = posts.region_code and r.is_active)
    and (
      not public.setting_bool('require_verified_to_post')
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
  );

create policy posts_update on public.posts for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy posts_delete on public.posts for delete to authenticated
  using (author_id = auth.uid());

-- 댓글: 미인증 사용자도 작성 가능 (읽기·공감·댓글은 자유)
grant select on public.comments to authenticated;
grant insert (post_id, parent_id, body) on public.comments to authenticated;
grant update (body) on public.comments to authenticated;
grant delete on public.comments to authenticated;

create policy comments_read on public.comments for select to authenticated
  using (
    author_id = auth.uid()
    or (
      not is_hidden
      and not exists (
        select 1 from public.blocks b
         where b.blocker_id = auth.uid() and b.blocked_id = comments.author_id
      )
    )
  );

-- 보이는 글에만 댓글 작성 가능 (숨김·차단된 글 제외)
create policy comments_insert on public.comments for insert to authenticated
  with check (
    author_id = auth.uid()
    and exists (select 1 from public.posts p where p.id = comments.post_id)
  );

create policy comments_update on public.comments for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy comments_delete on public.comments for delete to authenticated
  using (author_id = auth.uid());

-- 공감: 내 것만 조회 (집계는 posts.reaction_count 로)
grant select, insert, delete on public.post_reactions to authenticated;
create policy post_reactions_read on public.post_reactions for select to authenticated
  using (user_id = auth.uid());
create policy post_reactions_insert on public.post_reactions for insert to authenticated
  with check (user_id = auth.uid());
create policy post_reactions_delete on public.post_reactions for delete to authenticated
  using (user_id = auth.uid());

grant select, insert, delete on public.comment_likes to authenticated;
create policy comment_likes_read on public.comment_likes for select to authenticated
  using (user_id = auth.uid());
create policy comment_likes_insert on public.comment_likes for insert to authenticated
  with check (user_id = auth.uid());
create policy comment_likes_delete on public.comment_likes for delete to authenticated
  using (user_id = auth.uid());

-- 신고: 넣기만 가능. 누적 처리는 apply_report 트리거가 한다.
grant insert (target_type, target_id, reason) on public.reports to authenticated;
create policy reports_insert on public.reports for insert to authenticated
  with check (reporter_id = auth.uid());

-- 차단
grant select, insert, delete on public.blocks to authenticated;
create policy blocks_read on public.blocks for select to authenticated
  using (blocker_id = auth.uid());
create policy blocks_insert on public.blocks for insert to authenticated
  with check (blocker_id = auth.uid());
create policy blocks_delete on public.blocks for delete to authenticated
  using (blocker_id = auth.uid());
