# FLUTTER_BASELINE

## Toolchain

| Item | Value |
|------|-------|
| Flutter | 3.44.6 stable |
| Dart | 3.12.2 |
| DevTools | 2.57.0 |
| doctor | No issues found |
| Web | Chrome, Edge available |
| Android | SDK 36 configured |
| Windows desktop | Feature flag disabled in this SDK install |

---

### Finding: Product apps

Status: FAIL  
Evidence: `apps/student_app`, `apps/teacher_app`, `apps/admin_web` do not exist yet.  
Risk: Cannot ship product UI until FND-01 scaffolds workspace.  
Required action: Create Melos/pub workspace and apps in FND-01.  
Blocking: YES (for product UI modules; not for AUD-01)

### Finding: avatar_trials

Status: WARNING  
Evidence: Runnable Flutter project with companion trials; `flutter analyze`/`test` deferred to module gate if touched.  
Risk: Not a production shell; mixed assets.  
Required action: Quarantine; reuse selectively with license checks.  
Blocking: NO

### Finding: Packages

Status: FAIL  
Evidence: Shared packages (`nano_design_system`, etc.) not created.  
Risk: Expected for greenfield.  
Required action: FND-01 / FND-02.  
Blocking: YES (for UI modules after AUD-01)

### Finding: Tests

Status: WARNING  
Evidence: Only `avatar_trials/test/widget_test.dart` present.  
Risk: No product coverage yet.  
Required action: Each module adds tests per acceptance.  
Blocking: NO
