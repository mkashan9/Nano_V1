# SOC-01 decisions

- Keep legal `profiles.display_name` for school/admin; social handle is separate.
- Friend codes are opaque 8-char tokens; peers never receive another learner's
  friend code in limited-profile JSON.
- Not-found and not-discoverable share the same client error (NS024).
- Friend graph deferred to SOC-02.
