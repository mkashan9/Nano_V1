# ADM-03 manual test

Use a platform superadmin on development (or preview Superadmin).

1. Open **Users**. Confirm fixture or live profiles list (no email fields).
2. Search a learner by name. **Suspend** with a reason, then **Restore** with a
   reason.
3. On a school admin row, **Replace admin** with a staff/teacher user id and a
   reason. Confirm the prior admin shows as left and the new one as admin.
4. **Revoke** sessions for a user who has active sessions. Confirm the count
   drops and they cannot stay signed in on that device.
5. Open **Platform** and confirm recent audit mentions suspend/restore/revoke.

Reply **NEXT** to approve, or **FIX:** with defects.
