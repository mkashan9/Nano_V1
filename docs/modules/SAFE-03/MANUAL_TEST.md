# SAFE-03 manual test

1. As a learner, try reporting with details containing `nano_banned_phrase_test`
   — expect a restricted-content error.
2. Try report details with `https://evil.example/x` — expect link blocked.
3. Try report details with a YouTube URL — should be allowed (subject to other rules).
4. Spam friend requests beyond the hourly limit — expect rate-limit message.
