# LRN-01 Manual Test

1. Run the student app without live auth (preview personas).
2. As **Junior**, open Home → tap **Math**.
3. Confirm **Counting to 20** is startable and **Adding small numbers** shows "Finish Counting to 20 first".
4. Use the debug persona switch to **Senior**.
5. Tap **Math** again and confirm the same topic titles appear (same version IDs under the hood).
6. If browsing the catalog page in tests/gallery, search **living** and confirm only **Science** remains.
7. Confirm a draft Coding subject never appears for Junior or Senior.

Optional live check: with a classified development session, `select * from learning_catalog` as the learner should never return `coding` draft rows.
