-- SOC-02 smoke: friend graph objects exist.
select 'friend_requests' as check,
  to_regclass('public.friend_requests') is not null as ok;
select 'friendships' as check,
  to_regclass('public.friendships') is not null as ok;
select 'blocks' as check,
  to_regclass('public.blocks') is not null as ok;
select 'send_friend_request' as check,
  to_regprocedure('public.send_friend_request(text)') is not null as ok;
select 'my_friends' as check,
  to_regprocedure('public.my_friends()') is not null as ok;
select 'block_user' as check,
  to_regprocedure('public.block_user(text)') is not null as ok;
