select 'build_share_card' as check,
  to_regprocedure('public.build_share_card(text,uuid,integer,boolean)') is not null as ok;
