import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_games/nano_games.dart';

/// Adapts [NanoFeedback] to the game feedback sink.
class NanoGameFeedbackSink implements GameFeedbackSink {
  NanoGameFeedbackSink(this.feedback);

  final NanoFeedback feedback;

  @override
  Future<void> tick() => feedback.hapticSelection();

  @override
  Future<void> success() => feedback.success();
}
