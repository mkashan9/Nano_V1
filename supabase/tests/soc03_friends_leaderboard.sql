select 'my_friends_leaderboard' as check,
  to_regprocedure('public.my_friends_leaderboard(integer)') is not null as ok;
