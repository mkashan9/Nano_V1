import 'package:admin_web/features/school/presentation/school_branding_settings_page.dart';
import 'package:admin_web/features/school/presentation/school_marks_policies_page.dart';
import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-01 + SCH-06 Settings hub: Branding and Policies tabs.
class SchoolSettingsPage extends StatelessWidget {
  const SchoolSettingsPage({
    super.key,
    required this.dashboardRepository,
    required this.marksPolicyRepository,
  });

  final SchoolDashboardRepository dashboardRepository;
  final SchoolMarksPolicyRepository marksPolicyRepository;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(text: copy.schoolSettingsBrandingTab),
                Tab(text: copy.schoolSettingsPoliciesTab),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SchoolBrandingSettingsPage(repository: dashboardRepository),
                SchoolMarksPoliciesPage(repository: marksPolicyRepository),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
