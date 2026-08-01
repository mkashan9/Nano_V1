# CMP-03 known issues

- Cooldowns and the session budget live in memory only. Closing the app starts a
  fresh session, so a learner who relaunches twice in a minute can be greeted
  twice. Persisting the last-seen moments belongs with the preferences work.
- Art is still the placeholder circle from FND-03. Placement decides the size;
  what fills it arrives with MED-01.
- Game and social surfaces have placements in the table but no screens to place
  them on yet.
- The resume greeting fires wherever the learner happens to be, which is right,
  but on a surface whose placement is `hidden` (settings) it is held as a
  reaction with nowhere to render until they move. It is not lost; it is simply
  not shown there.
- `returnFromInactivity` counts activity as reported companion moments, not raw
  interaction. A learner reading one long page for an hour and then backgrounding
  the app may be greeted on return.
