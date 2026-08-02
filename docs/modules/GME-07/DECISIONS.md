# GME-07 decisions

- Reuse ADM-06 `enabled=false` + archive as the kill flag (no separate table).
- Force-abort active sessions on disable; host polls every ~8s (injectable).
- Dedicated EN/UR copy for start-block vs mid-play kill.
