# XP-02 known issues

**Admin cannot edit thresholds yet.** Rows are migration-seeded; ADM-05 owns
the editor.

**Level-up is not yet a companion event.** Crossing a band updates the number
on Home and Me; the Celebration Nori moment for a level-up still waits on a
later hook (CMP / XP-03 territory).

**Max level is soft.** Level 40 is the last seeded row. Extra XP past that
band stays on level 40 with `xp_to_next = 0`; extending the table is a data
change, not a client change.
