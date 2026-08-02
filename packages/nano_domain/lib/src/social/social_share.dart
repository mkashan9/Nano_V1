import '../xp/share_card.dart';

/// SOC-04 share destinations for privacy-safe [ShareCard] payloads.
enum ShareTarget {
  clipboard,
  system,
  whatsApp,
  communities,
}

/// Result of attempting a share action.
enum ShareOutcome {
  copied,
  shared,
  openedExternal,
  deferred,
  failed,
}

/// Builds destination URIs / copy payloads without touching private fields.
class SocialSharePlan {
  const SocialSharePlan({
    required this.target,
    required this.shareText,
  });

  final ShareTarget target;
  final String shareText;

  /// WhatsApp share link. Empty for other targets.
  Uri? get whatsAppUri {
    if (target != ShareTarget.whatsApp) return null;
    return Uri.https('wa.me', '/', {
      'text': shareText,
    });
  }

  static SocialSharePlan of(ShareCard card, ShareTarget target, {required bool urdu}) {
    return SocialSharePlan(
      target: target,
      shareText: card.shareTextFor(urdu: urdu),
    );
  }

  /// Communities stay deferred until COM-01 membership exists.
  bool get isDeferred => target == ShareTarget.communities;
}
