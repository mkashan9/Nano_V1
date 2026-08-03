import 'package:nano_design_system/nano_design_system.dart';

/// Visual fixtures matching `UI_reference/kids/profile.jpeg` (VIS-04).
abstract final class JuniorProfileFixtures {
  static const displayLevel = 7;
  static const xpCurrent = 320;
  static const xpMax = 500;

  static const recent = <({String title, String subject, String asset})>[
    (title: 'Counting Fun', subject: 'Math', asset: 'math'),
    (title: 'Wild Animals', subject: 'Science', asset: 'science'),
    (title: 'The Letter A', subject: 'Reading', asset: 'reading'),
  ];

  static const journey = <JuniorJourneyDay>[
    JuniorJourneyDay(label: 'Mon', state: JuniorJourneyDayState.completed),
    JuniorJourneyDay(label: 'Tue', state: JuniorJourneyDayState.completed),
    JuniorJourneyDay(label: 'Wed', state: JuniorJourneyDayState.completed),
    JuniorJourneyDay(label: 'Thu', state: JuniorJourneyDayState.completed),
    JuniorJourneyDay(label: 'Fri', state: JuniorJourneyDayState.reward),
    JuniorJourneyDay(label: 'Sat', state: JuniorJourneyDayState.upcoming),
    JuniorJourneyDay(label: 'Sun', state: JuniorJourneyDayState.upcoming),
  ];
}
