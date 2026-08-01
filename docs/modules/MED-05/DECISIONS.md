# MED-05 decisions

## Approval is publication, and it says so

There is no separate `published` flag. A second switch would let an asset be
approved but invisible, or visible but unapproved, and the first time those two
disagree a child sees something nobody signed off. The UI calls `approved`
**Published** so the reviewer reads the consequence rather than the paperwork.

## Rejection un-publishes, and the file goes with it

Rejecting is not "mark for later". The catalog stops returning the row and the
storage policy stops serving the object in the same statement. The safe
direction is always cheap to travel.

## A rejection must carry a reason

The prompt is reused. Without a sentence explaining what was wrong, the next
generation reproduces the same problem and the reviewer rejects it again.
`NM010` is raised for an empty note rather than storing a blank record.

## Rejected rows are not reuse candidates

MED-02's reuse index made a slot answerable exactly once. That is correct until
the answer is rejected: the slot then holds a permanent bad answer and can never
be asked again. The index now excludes `rejected`, and
`request_generated_asset` skips rejected rows, so rejecting frees the slot.

The reverse case is refused: if a newer asset already fills a slot, un-rejecting
the old one raises `NM010` instead of silently creating two answers.

## The audit log has a sequence, not just a timestamp

Two decisions in one transaction share `now()`. History ordered by time was
therefore non-deterministic and the tests caught it. `seq` is a generated
identity column, and `created_at` uses `clock_timestamp()`; history orders by
`seq`.

## Append-only is about revision, not about deletion

The guard first blocked the cascade as well, which quietly meant that the first
decision made about an asset pinned that asset in the table forever. Nobody
chose that, and the error message would have been baffling. A decision cannot be
edited or erased while the asset it describes exists; deleting the asset takes
its per-asset detail with it, exactly as the foreign key already said. The
record that has to outlive everything is the `audit_events` entry, which the
review path writes and this table cannot reach.

## The reviewer can see what the learner cannot

`generated_assets_bucket_read_admin` gives platform admins read access to the
whole bucket. Without it a reviewer would be deciding on a filename. It is the
one place in Nano where unapproved bytes are readable, and it is scoped to the
role that owns the decision.

## Refusals are one code

Everything the review path can say no to — wrong role, missing reason, no file,
unknown decision, empty batch, occupied slot — raises `NM010` with a sentence.
The screen shows the server's sentence rather than inventing its own, so the
reviewer reads the actual reason.

## A batch is atomic

Approving twenty assets and having six succeed leaves a reviewer with no idea
what is live. `review_generated_assets` decides all of them or none.

## Voice and video previews are honest

No plugin is attached yet, so the screen shows content type, size, and checksum
rather than a dead player. A reviewer approving a clip today is approving its
provenance, and the screen says so instead of implying playback.
