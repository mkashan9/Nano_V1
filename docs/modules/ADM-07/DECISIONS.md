# ADM-07 decisions

## Admin half of handbook NOT-01

Templates and enable/disable live here. Inbox, push, and preferences stay with
STU-06 / NOT-01 / NOT-02 so R6 can land without R2/R10 consumers.

## Publish / disable mirrors ADM-06

Draft → publish. Disable requires a reason; published rows archive and set
`enabled=false`. Mandatory templates are flagged for later mute policy.

## No inbox writes yet

Creating or publishing a template does not insert `inbox_items`. Fan-out waits
for STU-06 / NOT-01.
