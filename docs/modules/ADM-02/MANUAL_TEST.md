# ADM-02 manual test

Use a platform superadmin on development (or preview Superadmin).

1. Open **Schools**. Confirm Alpha / Beta appear.
2. **Create** a school with code `GAMMA01` and a name. Confirm it lists.
3. Try creating the same code again — expect rejection.
4. Change a school **Status** with a reason. Confirm it updates.
5. On a school that **Needs admin**, assign the first admin (use a real staff
   profile id on live; fixture id works in preview). Confirm **Has admin**.
6. Assign again — expect rejection.
7. Open **Platform** and confirm recent audit mentions school changes.

Reply **NEXT** to approve, or **FIX:** with defects.
