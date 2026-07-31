# LRN-02 Plan

1. Migration: unique topic order, prerequisite shape trigger, shared lock helper, RPC-only progress writes, Science second topic seed.
2. Domain: `TopicAction`, `TopicProgress`, `TopicGateException`, action policy.
3. Data: `LearningProgressRepository` (fake + Supabase) mapping NL001–NL003.
4. UI: `TopicDetailPage`; subject list opens locked and unlocked topics into it.
5. Tests: domain, data, widget, adversarial SQL.
6. Status docs + owner manual test.
