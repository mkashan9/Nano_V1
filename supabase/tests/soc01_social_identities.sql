-- SOC-01 smoke: table + RPCs exist (full auth flows need live JWT).
select 'social_identities' as check,
  to_regclass('public.social_identities') is not null as ok;

select 'my_social_identity' as check,
  to_regprocedure('public.my_social_identity()') is not null as ok;

select 'claim_username' as check,
  to_regprocedure('public.claim_username(text)') is not null as ok;

select 'rotate_friend_code' as check,
  to_regprocedure('public.rotate_friend_code()') is not null as ok;

select 'lookup_limited_profile' as check,
  to_regprocedure('public.lookup_limited_profile(text)') is not null as ok;
