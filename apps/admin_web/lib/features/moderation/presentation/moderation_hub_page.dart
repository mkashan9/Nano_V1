import 'package:admin_web/features/moderation/presentation/asset_review_page.dart';
import 'package:admin_web/features/moderation/presentation/user_reports_queue_page.dart';
import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Moderation destination: media review (MED-05) + user reports (SAFE-02).
class ModerationHubPage extends StatelessWidget {
  const ModerationHubPage({
    super.key,
    this.assetReviewRepository,
    this.moderationQueueRepository,
  });

  final AssetReviewRepository? assetReviewRepository;
  final ModerationQueueRepository? moderationQueueRepository;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final tabs = <Tab>[
      if (assetReviewRepository != null) Tab(text: copy.assetReviewTitle),
      if (moderationQueueRepository != null) Tab(text: copy.reportsQueueTitle),
    ];
    final views = <Widget>[
      if (assetReviewRepository != null)
        AssetReviewPage(repository: assetReviewRepository!),
      if (moderationQueueRepository != null)
        UserReportsQueuePage(repository: moderationQueueRepository!),
    ];

    if (tabs.isEmpty) {
      return const Center(child: Text('Moderation tools unavailable'));
    }
    if (tabs.length == 1) {
      return views.first;
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(tabs: tabs),
          Expanded(child: TabBarView(children: views)),
        ],
      ),
    );
  }
}
