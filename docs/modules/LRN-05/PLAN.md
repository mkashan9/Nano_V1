# LRN-05 plan

1. Add `last_activity_at` to `public.learning_catalog`. — done
2. Create `public.learning_progress_summary` (per subject, owner-scoped). — done
3. Create `public.learning_next_up` (ranked, with reason). — done
4. Verify ranking and isolation against the development project. — done
5. Adversarial SQL for locks, eligibility, drafts, and cross-learner reads. — done
6. Domain models: `SubjectProgress`, `NextUpSuggestion`, `LearningInsights`. — done
7. `LearningInsightsRepository` with fake and Supabase implementations. — done
8. `LearningProgressPage` with recommendation, alternatives, and per-subject rows. — done
9. Thread the repository through main, router, shell, profile, and catalog. — done
10. Tests: domain, data, widget. — done
11. Docs and status files. — done
12. Owner manual test. — pending
