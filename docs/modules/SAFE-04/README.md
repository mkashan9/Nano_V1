# SAFE-04 — Open Community Controls

Communities are open for senior learners (Discord-like): school enrollment is
unrelated. Platform admins keep only an emergency kill switch (default on).
Juniors never receive the entitlement.

## Owns

- `platform_community_policy` singleton (emergency switch, default on)
- Platform Community controls page
- `my_community_entitlements` + bootstrap `featureFlags['communities']`
- `nano_internal.assert_communities_allowed` for COM modules

## Does not own

- School admin Communities settings (explicitly out of scope)
- Community discovery / rooms / chat → COM-01+
- Moderation queue → SAFE-02
