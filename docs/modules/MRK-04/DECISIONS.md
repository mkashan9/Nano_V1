# MRK-04 decisions

- Publish is a server transaction; draft-only save/import remains.
- Corrections require a non-empty reason and must change status, marks, or remarks.
- Prior values append to `marks_corrections`; rows are immutable.
- Closed linked result periods reject teacher publish/correct (privileged path later).
- Assessment status moves `draft → published → corrected`.
