# CMP-01 manual test

Run `student_app` as Junior.

1. Finish a quiz **correctly** (Counting → **Take quiz**). On the results screen,
   confirm the companion appears with a celebration and a short line such as
   "Nicely done!" beside it.
2. Finish a quiz **wrongly**. Confirm the companion offers another try instead of
   a scolding ("Some of these need another look. We can try again.") and that the
   art changes with the mood.
3. In Settings, turn **sound off** and finish a quiz again. Confirm the line is
   still readable as a caption.
4. Turn **captions off** and finish again. Confirm the companion is still visible
   and nothing else on the results screen moves or resizes.
5. Turn on **Classroom Mode** (or reduced motion) and finish again. Confirm the
   companion is static and quiet, and the results themselves are unchanged.
6. Open the component gallery (developer surface) and toggle Junior/Senior.
   Confirm Junior shows a large companion for every listed moment, and Senior
   shows only the result moments, smaller — ordinary navigation moments render
   nothing.
7. Switch to Senior and finish a quiz via **Review & finish**. Confirm the
   companion reaction is present but small and beside the results, not centred
   above them.

Nothing here needs network access; the companion should behave identically with
the device offline.

Reply `NEXT` to approve, or `FIX: …` if the guidance, captions, or density look
wrong.
