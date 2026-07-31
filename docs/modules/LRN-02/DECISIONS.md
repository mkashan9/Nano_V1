# LRN-02 Decisions

## Write path is RPC-only

Direct `INSERT`/`UPDATE` policies on `learning_progress` are revoked for `authenticated`. Learners write only through `public.start_topic` and `public.save_topic_progress`. That keeps prerequisite locks binding even if a client is patched.

## One helper for read and write

`nano_internal.topic_lock_titles` feeds both the catalog view and the write guards. Displayed locks and enforced locks cannot drift.

## Completion stays out of client reach

Neither RPC ever writes `status = 'completed'`. A 100% save still returns `in_progress`. Verified completion belongs to LRN-03 (video) and QZ-05 (scoring).

## SECURITY DEFINER RPCs are intentional

`start_topic` and `save_topic_progress` are callable by `authenticated` as security definer (same pattern as `revoke_device_session`). They authenticate the caller, refuse locked and unpublished topics, and only touch the caller's own row.

## Ordering is a database invariant

`topics (subject_id, sort_order)` is unique. Prerequisites must stay inside one subject and must not form a cycle, enforced by `nano_internal.assert_prerequisite_shape`.
