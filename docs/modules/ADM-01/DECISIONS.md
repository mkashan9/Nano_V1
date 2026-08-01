# ADM-01 decisions

## Dashboard vs later admin modules

MODULE_STATUS splits ADM-01 (dashboard), ADM-02 (school create/codes), and
ADM-03 (global user control). Handbook ADM-01 is broader; this module takes
the read-only operational surface and leaves writes to the later IDs.

## Safe summaries only

School rows and audit preview never include email, guardian, marks,
attendance, or actor user ids. Search is name/code only.

## Absorb, do not replace

Content (QZ) and Moderation (MED-05) stay on the existing shell destinations.
