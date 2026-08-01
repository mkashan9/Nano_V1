# SCH-02 decisions

- School-owned structure is separate from platform `learning_subjects`; optional
  `learning_subject_id` mapping only.
- Archive (`status=archived`) instead of hard delete.
- Policies deferred to SCH-06; terms/years stay SCH-01 label for now.
- Writes only via school-admin SECURITY DEFINER RPCs.
