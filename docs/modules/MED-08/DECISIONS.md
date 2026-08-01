# MED-08 — Decisions

## Plugins live in the app, interfaces stay in the design system

`nano_design_system` is shared with admin_web. Putting `video_player` and
`just_audio` behind the seams there would have made an administration console
depend on codecs it never uses. Instead the concrete players live in
`apps/student_app/lib/app/playback/`, and `NanoClipPlayer` exposes a `view`
widget the stage places without inspecting. admin_web keeps its own
`package:web` element view from MED-06.

## The players are `Listenable`

A clip ends on its own. Without a notification the stage would keep showing the
last frame forever, or would have to poll. Making both seams `Listenable` is
what lets the still come back the moment playback finishes.

## Real players are built in `main`, not in the app state

If `_NanoStudentAppState` created them when none was passed, every widget test
would reach for a platform plugin that is not there. Building them in `main`
keeps production real and tests on the recording doubles, which is also what
keeps `Listen` correctly absent in tests.

## A published clip may lift a mood one rung, and no further

`CompanionAssetManifest` declared a fixed tier per mood and could only drop.
That made the approved Wan greeting clip unreachable, because greeting is
declared `localAnimation`. The map is now read as the floor the app can always
reach offline, and an approved clip may raise a mood one rung above it: a mood
that already animates locally can become a clip; a mood that is still art stays
still art however much is published.

The alternative — declaring more moods clip-worthy — would have put video on
routine moments, which costs render spend, needs the network, and is motion
nobody asked for. This way coverage is decided by what a human approves.

## Static art is the floor under every tier

`choose` now looks for the picture at the reaction's own tier slot and then at
the `mode_mood_staticArt` slot. Nobody publishes a separate picture per tier,
and a clip still needs a still to rest on before it starts and after it ends.

## A slow URL never paints the wrong Nori

Minting a signed URL is asynchronous. The controller records which asset it is
resolving and discards a URL that lands after the reaction moved on, so a slow
mint cannot paint the previous picture under the current caption.

## Home uses the greeting that can be spoken

The first greeting variant names the companion the learner chose, and a
personalised line is never recorded (ADR-0008). With seed 0 the home screen
therefore always showed the one greeting the Guide can never say aloud. Home
now seeds the second variant, so the voice is reachable in the ordinary path
rather than only in a contrived one.

## Presentation follows the track, not the role (defect found in USER_TEST)

The owner reported the same UI whether they signed in as a Junior or a Senior
account. Two faults met.

`ExperiencePolicy.roleFor` returns `AppRole.independentStudent` for every
independent learner whatever their track, and `usesJuniorPresentation` was
`role == juniorStudent`. So the role could not express "independent and six
years old"; both test accounts are independent, so both rendered Senior.

Separately, the track lives in `student_onboarding` and the auth bootstrap
reads `profiles`, so sign-in could never know it. `_loadOnboarding` did read
it — and then used it for nothing. Only `_onOnboardingCompleted` upgraded the
principal, so the track applied in the session onboarding finished in, and was
dropped on every launch after that.

`SessionPrincipal` now carries `experienceTrack`, presentation prefers it and
falls back to the role when it is unknown, and `_loadOnboarding` applies it. A
role still decides entitlement — what a learner may reach — while the track
decides presentation. Keeping them separate is the point: merging them would
mean promoting a child to a different role to change how a screen looks.

This also matters beyond layout. Senior treats `home` as a quiet event, so a
Junior wrongly rendered as Senior gets no companion on the one screen every
session starts on — which is what made MED-08 look like it had shipped nothing.

## Lesson video is built but idle

Every `topic_versions` row carries `video_provider = 'fixture'` and a slug, so
there is nothing to decode. The player opens anything whose reference parses as
an http URL and keeps the one-second clock otherwise. Deciding playability from
the *reference* rather than the provider name means an embed-only provider is
also correctly treated as not directly playable.

The clock stays for a second reason: watch credit is security-sensitive, and a
test should be able to prove the accounting without a codec.
