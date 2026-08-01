# QZ-01 decisions

## Question identity is separate from versions

`questions` holds the stable slug. Content lives on `question_versions` so a
republish never rewrites history. Attempts (QZ-05) will point at a version id.

## No learner read path

Correct answers live on `question_versions`. There is no SELECT policy for
learners. QZ-02 will expose a learner-safe projection that drops `is_correct`
when a quiz is attached to a video.

## SECURITY DEFINER authoring RPCs

`create_question_draft`, `publish_question_version`, and
`retire_question_version` check `nano_internal.is_platform_admin()` and write
audit rows. Direct table writes are also allowed for platform admins via RLS,
but the RPCs are the supported path so duplicate detection and publish/retire
transitions stay consistent.

## Duplicate detection is a stem hash, not NLP

Stems are lower-cased and whitespace-collapsed, then SHA-256 hashed. The create
RPC returns matching versions so the UI can warn without inventing client-side
matching that could drift from the server.

## One published version per question

Publishing a draft retires any previously published version of the same
question. Retired rows stay in place for history.

## Preview is curator chrome over the same version id

Junior and Senior preview cards differ in layout density and companion presence,
but both print the same version id. Student quiz shells (QZ-03/QZ-04) will reuse
the same content model.
