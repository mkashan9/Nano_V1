# CMP-04 Reaction and Placement Plan

Identity: `nano_humanoid_companion_v1`  
Voice: `gentle_young_male_c48e8683`  
Video provider: Gradio Space `cinderholm/wan2-2-i2v-v3` (existing `wan_i2v_space` adapter)

## Approved appearances

| ID | Event | Jr | Sr | Tier | Anchor | Clip | Speech |
|----|-------|----|----|------|--------|------|--------|
| intro_speaking | appOpen / onboarding | large scene | n/a | 2 | beside onboarding panel | intro_speaking | yes |
| home_greeting_speaking | home (session first) | hero lower-right | silent nod chip | 2/1 | Continue Learning card | home_greeting | Jr yes / Sr no |
| welcome_back_speaking | returnFromInactivity | hero | small | 2 | card edge | welcome_back | yes |
| guide_point | learningEntry / topicOpened | featured / next card | recommend chip | 2/0 | card right edge | guide_point | optional |
| listening | videoStart / quizQuestion | mentor slot | compact | 0/2 | beside player / quiz | listening | optional start |
| correct_small_celebration | quizCorrect (immediate ok) | small | smaller | 1/2 | quiz card corner | correct_small | no speech |
| gentle_retry_speaking | quizRepeatedMistake | quiz stage | compact | 2 | quiz card | gentle_retry | once/q |
| lesson_complete_speaking | videoComplete | beside Complete | compact | 2 | player frame | lesson_complete | yes |
| quiz_complete_speaking | quizComplete (trusted) | result panel | restrained | 2 | result card | quiz_complete | yes |
| level_up_speaking | levelUp (trusted) | story/aside | aside | 2 | achievement area | level_up | yes |
| long_video_refresh_speaking | longVideoRefresh | checkpoint sheet | sheet | 2 | checkpoint | long_refresh | yes |

## Rejected appearances

- Permanent floating bubble / CircleAvatar companion
- Companion inside community chat / message lists
- Video after every subject tap or every correct answer speech
- Celebrating before server-confirmed XP/score
- Covering Start, answers, captions, nav, Play Again

Canonical machine plan: `assets/companion/reaction_plan.yaml`
