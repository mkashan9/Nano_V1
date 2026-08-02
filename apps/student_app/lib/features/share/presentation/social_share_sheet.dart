import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// SOC-04: preview + destination picker for a privacy-safe [ShareCard].
Future<ShareOutcome?> showSocialShareSheet({
  required BuildContext context,
  required ShareCard card,
  required NanoCopy copy,
  Future<ShareOutcome> Function(SocialSharePlan plan)? dispatcher,
}) {
  return showModalBottomSheet<ShareOutcome>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SocialShareSheet(
        card: card,
        copy: copy,
        dispatcher: dispatcher ?? SocialShareDispatcher.dispatch,
      );
    },
  );
}

/// Platform share helpers. Injectable for tests.
class SocialShareDispatcher {
  static Future<ShareOutcome> dispatch(SocialSharePlan plan) async {
    if (plan.isDeferred) return ShareOutcome.deferred;
    switch (plan.target) {
      case ShareTarget.clipboard:
        await Clipboard.setData(ClipboardData(text: plan.shareText));
        return ShareOutcome.copied;
      case ShareTarget.system:
        await Share.share(plan.shareText);
        return ShareOutcome.shared;
      case ShareTarget.whatsApp:
        final uri = plan.whatsAppUri;
        if (uri == null) return ShareOutcome.failed;
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        return ok ? ShareOutcome.openedExternal : ShareOutcome.failed;
      case ShareTarget.communities:
        return ShareOutcome.deferred;
    }
  }
}

class SocialShareSheet extends StatelessWidget {
  const SocialShareSheet({
    super.key,
    required this.card,
    required this.copy,
    required this.dispatcher,
  });

  final ShareCard card;
  final NanoCopy copy;
  final Future<ShareOutcome> Function(SocialSharePlan plan) dispatcher;

  Future<void> _run(BuildContext context, ShareTarget target) async {
    final plan = SocialSharePlan.of(card, target, urdu: copy.isUrdu);
    final outcome = await dispatcher(plan);
    if (!context.mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urdu = copy.isUrdu;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NanoSpacing.md,
          0,
          NanoSpacing.md,
          NanoSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.shareSheetTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.md),
              ShareCardPreview(card: card, urdu: urdu),
              const SizedBox(height: NanoSpacing.md),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(copy.shareCopyLabel),
                onTap: () => _run(context, ShareTarget.clipboard),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: Text(copy.shareSystemLabel),
                onTap: () => _run(context, ShareTarget.system),
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: Text(copy.shareWhatsAppLabel),
                onTap: () => _run(context, ShareTarget.whatsApp),
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(copy.shareCommunitiesLabel),
                subtitle: Text(copy.shareCommunitiesHint),
                onTap: () => _run(context, ShareTarget.communities),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rendered card surface for privacy review (text only; no school fields).
class ShareCardPreview extends StatelessWidget {
  const ShareCardPreview({
    super.key,
    required this.card,
    required this.urdu,
  });

  final ShareCard card;
  final bool urdu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Share card preview',
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: const Key('share-card-preview'),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(NanoRadii.senior),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.headlineFor(urdu: urdu),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                card.bodyFor(urdu: urdu),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                'Nano',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String shareOutcomeMessage(ShareOutcome outcome, NanoCopy copy) {
  return switch (outcome) {
    ShareOutcome.copied => copy.shareCopiedSnack,
    ShareOutcome.shared => copy.shareSharedSnack,
    ShareOutcome.openedExternal => copy.shareOpenedSnack,
    ShareOutcome.deferred => copy.shareCommunitiesHint,
    ShareOutcome.failed => copy.shareFailedSnack,
  };
}
