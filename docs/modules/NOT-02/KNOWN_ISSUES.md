# NOT-02 known issues

- Quiet-hour evaluation uses an injectable clock in fake push only; UI simulate
  push uses wall clock (may not hit quiet window during daytime demos).
- Preferences are not yet wired through main/shell shared push instance.
- No live preference persistence.
