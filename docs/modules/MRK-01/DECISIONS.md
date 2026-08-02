# MRK-01 decisions

- Create/update only while status is `draft` (publish stays MRK-04).
- Assessment requires active teacher assignment scope.
- Category + name + date + positive total marks required; weight optional (≥ 0).
- Optional `result_period_id` must be an open school period when provided.
- Drafts are private (RPC-only table access; students never see drafts).
- `assessment_versions` / marks tables deferred to later MRK slices.
