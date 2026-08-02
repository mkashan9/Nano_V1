# GME-06 — Game Audio, Haptics, and Classroom Mode

Game host respects FND-07 accessibility preferences: sound, haptics,
reduced motion, and Classroom Mode. Settings are passed on the bridge
`session_started` envelope and enforced for fixture/native feedback.

## Owns

- `GamePlaySettings` + bridge settings payload
- Host Classroom Mode toggle
- Feedback sink for tick/success gated by effective prefs

## Does not own

- Persisted preference storage (STU-02 / profile)
- Custom game music assets / volume mixer UI
- Kill switch → GME-07
