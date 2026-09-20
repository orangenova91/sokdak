-- 계정 삭제: 앱 스토어 정책(앱 내 계정 삭제 제공)을 위한 RPC.
-- auth.users 행을 지우면 profiles → posts/comments/reactions/reports/blocks 가 연쇄 삭제된다.

create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon, authenticated;
grant execute on function public.delete_my_account() to authenticated;

-- 정책 함수는 로그인 사용자의 RLS 평가에만 필요하므로 비로그인(anon)의 RPC 호출은 막는다.
revoke execute on function public.setting_bool(text) from public, anon;
revoke execute on function public.setting_int(text, int) from public, anon;
