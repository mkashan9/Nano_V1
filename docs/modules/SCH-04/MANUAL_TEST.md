# SCH-04 manual test

Use a school admin on development (or preview **School** shell).

1. Open **Students**. Confirm Ali (or seed) appears.
2. **Add student** with a unique email; copy the temporary password.
3. **Suspend** then **Restore** with a reason.
4. Paste CSV (`display_name,email,class_name`), **Preview**, then **Commit**
   when failures are zero. Unknown class names must fail preview.
5. Duplicate email must block commit.

Reply **NEXT** to approve, or **FIX:** with defects.
