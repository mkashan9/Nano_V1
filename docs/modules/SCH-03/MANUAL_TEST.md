# SCH-03 manual test

Use a school admin on development (or preview **School** shell).

1. Open **Teachers**. Confirm Ms. Khan (or seed) appears.
2. **Add teacher** with a unique email; copy the temporary password dialog.
3. **Suspend** then **Restore** with a reason.
4. Paste CSV (`display_name,email`), **Preview**, then **Commit import** only
   when preview shows zero failures.
5. Confirm a row that duplicates an existing email blocks commit (nothing written).

Reply **NEXT** to approve, or **FIX:** with defects.
