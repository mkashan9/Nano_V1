# SAFE-04 — School and Global Community Controls

Platform and school opt-in switches for Communities. Defaults are off.
Junior / undecided learners never receive the `communities` entitlement.

## Owns

- `platform_community_policy` singleton
- `school_community_policies` per school
- Admin UIs: school Settings → Communities; platform Community controls
- `my_community_entitlements` + bootstrap `featureFlags['communities']`
- `nano_internal.assert_communities_allowed` for COM modules

## Does not own

- Community discovery / rooms / chat → COM-01+
- Moderation queue → SAFE-02
- Rate limits / link rules → SAFE-03
