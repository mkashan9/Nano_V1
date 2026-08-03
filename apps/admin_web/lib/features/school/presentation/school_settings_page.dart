import 'package:admin_web/features/school/presentation/school_branding_settings_page.dart';
import 'package:admin_web/features/school/presentation/school_communities_settings_page.dart';
import 'package:admin_web/features/school/presentation/school_marks_policies_page.dart';
import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-01 + SCH-06 + SAFE-04 Settings hub: Branding, Policies, Communities.
class SchoolSettingsPage extends StatelessWidget {
  const SchoolSettingsPage({
    super.key,
    required this.dashboardRepository,
    required this.marksPolicyRepository,
    required this.communityControlsRepository,
    required this.schoolId,
  });

  final SchoolDashboardRepository dashboardRepository;
  final SchoolMarksPolicyRepository marksPolicyRepository;
  final CommunityControlsRepository communityControlsRepository;
  final String schoolId;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(text: copy.schoolSettingsBrandingTab),
                Tab(text: copy.schoolSettingsPoliciesTab),
                Tab(text: copy.schoolSettingsCommunitiesTab),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SchoolBrandingSettingsPage(repository: dashboardRepository),
                SchoolMarksPoliciesPage(repository: marksPolicyRepository),
                SchoolCommunitiesSettingsPage(
                  repository: communityControlsRepository,
                  schoolId: schoolId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
