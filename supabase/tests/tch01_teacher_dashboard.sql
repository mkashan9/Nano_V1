-- TCH-01 teacher dashboard RPC presence and caller scope.

do $$
begin
  if to_regprocedure('public.teacher_dashboard()') is null then
    raise exception 'teacher_dashboard missing';
  end if;
  if to_regprocedure('nano_internal.require_teacher_school_id()') is null then
    raise exception 'require_teacher_school_id missing';
  end if;
end $$;

-- Seed teacher sees own school assignments only.
select set_config('request.jwt.claim.sub', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('role', 'authenticated', true);

do $$
declare
  v jsonb;
begin
  v := public.teacher_dashboard();
  if coalesce((v->>'school_code'), '') = '' then
    raise exception 'teacher_dashboard missing school_code';
  end if;
  if (v->>'teacher_id') is distinct from 'cccccccc-cccc-cccc-cccc-cccccccccccc' then
    raise exception 'teacher_dashboard teacher_id mismatch';
  end if;
  if jsonb_typeof(v->'assignments') is distinct from 'array' then
    raise exception 'teacher_dashboard assignments must be array';
  end if;
end $$;

-- Student cannot call teacher dashboard.
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true);

do $$
begin
  begin
    perform public.teacher_dashboard();
    raise exception 'student should not call teacher_dashboard';
  exception
    when others then
      if sqlerrm not like '%teacher membership%' and sqlstate <> 'NS072' then
        raise;
      end if;
  end;
end $$;
