# XP-06 implementation plan

1. Domain `ShareCard` + privacy helpers; featured pin budget constant.
2. Migration: `featured_achievements`, `my_featured_achievements`,
   `set_featured_achievements`, `build_share_card`.
3. `ShareCardRepository` (fake + Supabase).
4. Wire Me pin/share and quiz results share; pass repository from `main`.
5. Package + SQL tests; docs; stop at USER_TEST.
