-- 설치된 빌드 번호(+뒤의 숫자)가 min_build_number 보다 작으면 앱 사용을 막는다.
-- 스토어에 그 빌드가 공개된 뒤에 min_build_number 를 올린다.
-- iOS 주소는 App Store Connect 앱 아이디가 생긴 뒤 채운다.

insert into public.app_settings (key, value) values
  ('min_build_number', '1'::jsonb),
  ('ios_store_url', '""'::jsonb),
  ('android_store_url', '"https://play.google.com/store/apps/details?id=com.schoolhub.sokdak"'::jsonb)
on conflict (key) do nothing;

create function public.app_update_requirement()
returns table (
  min_build_number int,
  ios_store_url text,
  android_store_url text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    coalesce(
      (select (value #>> '{}')::int from public.app_settings where key = 'min_build_number'),
      0
    ),
    coalesce(
      (select value #>> '{}' from public.app_settings where key = 'ios_store_url'),
      ''
    ),
    coalesce(
      (select value #>> '{}' from public.app_settings where key = 'android_store_url'),
      ''
    );
$$;

revoke all on function public.app_update_requirement() from public;
grant execute on function public.app_update_requirement() to anon, authenticated;
