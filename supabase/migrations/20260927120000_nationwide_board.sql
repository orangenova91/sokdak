-- 전국 공통 게시판: 모든 지역에서 글쓰기 가능, 지역은 표시용 메타데이터만.

update public.regions set is_active = true;

drop policy if exists posts_insert on public.posts;

-- 본인 프로필 지역 코드를 글에 기록. is_active 제한 없음.
create policy posts_insert on public.posts for insert to authenticated
  with check (
    author_id = auth.uid()
    and posts.region_code = (select p.region_code from public.profiles p where p.id = auth.uid())
    and exists (select 1 from public.regions r where r.code = posts.region_code)
    and (
      not public.setting_bool('require_verified_to_post')
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
  );

-- 전국 피드용 인덱스 (board + 시간)
create index if not exists posts_board_feed_idx
  on public.posts (board, created_at desc)
  where not is_hidden;
