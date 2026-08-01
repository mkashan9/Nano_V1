# QZ-01 known issues

- **No bulk import UI yet.** Provenance is a text field; CSV import arrives with
  content-ops tooling.
- **Draft editing is create-new-version, not in-place form editing.** A new draft
  on an existing question is supported by the RPC; the UI currently creates a
  fresh question each time.
- **School admin Content destination stays a placeholder.** Only superadmin sees
  the question bank.
- **Supabase repository is not wired into a live admin boot by default.** The app
  uses the fake bank unless a repository is injected, matching other modules.
- **Short-answer and media-heavy items are out of scope.** Kind is
  multiple_choice or true_false for the pilot bank.
