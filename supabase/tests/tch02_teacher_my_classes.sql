-- TCH-02 My Classes + roster scope guard.

do $$
begin
  if to_regprocedure('public.teacher_my_classes()') is null then
    raise exception 'teacher_my_classes missing';
  end if;
  if to_regprocedure('public.teacher_class_roster(uuid)') is null then
    raise exception 'teacher_class_roster missing';
  end if;
end $$;

select set_config('request.jwt.claim.sub', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('role', 'authenticated', true);

do $$
declare
  v jsonb;
  v_assignment_id uuid;
begin
  v := public.teacher_my_classes();
  if jsonb_typeof(v->'assignments') is distinct from 'array' then
    raise exception 'teacher_my_classes assignments must be array';
  end if;

  if jsonb_array_length(v->'assignments') > 0 then
    v_assignment_id := (v->'assignments'->0->>'id')::uuid;
    v := public.teacher_class_roster(v_assignment_id);
    if (v->>'assignment_id') is distinct from v_assignment_id::text then
      raise exception 'roster assignment_id mismatch';
    end if;
    if jsonb_typeof(v->'students') is distinct from 'array' then
      raise exception 'roster students must be array';
    end if;
    if v ? 'email' then
      raise exception 'roster must not include email';
    end if;
  end if;

  begin
    perform public.teacher_class_roster('00000000-0000-0000-0000-000000000099');
    raise exception 'foreign assignment should be denied';
  exception
    when others then
      if sqlerrm not like '%active scope%' and sqlstate <> 'NS074' then
        raise;
      end if;
  end;
end $$;

select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true);

do $$
begin
  begin
    perform public.teacher_my_classes();
    raise exception 'student should not list teacher classes';
  exception
    when others then
      if sqlerrm not like '%teacher membership%' and sqlstate <> 'NS072' then
        raise;
      end if;
  end;
end $$;
