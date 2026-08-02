# CLS-03 decisions

- Schedule and expiry are draft-editable; due schedules promote on list.
- Publish-now and schedule are mutually exclusive.
- Expired items stay in history (`is_expired`); ack blocked after expiry.
- Acknowledgements are idempotent and audited; open/ack shown as ack/roster.
- Student ack RPC ships here so counts are real; FLX-04 owns student UI.
