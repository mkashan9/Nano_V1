# FND-02 Known Issues

1. **Git missing from PATH** — Flutter/`dart pub get` fail with `git : The term 'git' is not recognized`. Git for Windows must be on User PATH (`C:\Program Files\Git\cmd`). Open a **new** terminal after PATH changes.
2. Golden tests are local PNG baselines under `test/goldens/` — CI may need `--update-goldens` policy later.
3. Full responsive shells deferred to FND-03.
4. Gallery is development-oriented (shown when env debug tools enabled).
