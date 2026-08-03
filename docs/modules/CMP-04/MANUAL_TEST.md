# CMP-04 Manual Test

## Launch

```bash
cd d:/nano-cmp04-worktree/apps/student_app
flutter run -d chrome --dart-define=NANO_DEBUG_TOOLS=true
```

Or open debug build and navigate to `/dev/companion-cmp04`.

## Sequence

1. Gallery: confirm humanoid poses (not purple bean); identity version `nano_humanoid_companion_v1`; voice id `gentle_young_male_c48e8683`.
2. Junior Profile: student avatar top-left; humanoid portrait top-right (not fox).
3. Junior Home: companion greeting once per session; dismiss; layout returns; no purple mascot.
4. Sound off: captions remain; no audio.
5. Reduced motion: static poses only.
6. Classroom Mode: non-essential reactions suppressed.
7. Topic detail: topicOpened point pose once.
8. Topic player: video start / long refresh (static) / complete without covering controls.
9. Quiz complete: celebration after trusted result; missing clip → static.
10. Communities chat: no companion interruption.
11. Offline: static poses still render.
