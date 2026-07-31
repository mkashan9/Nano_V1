import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class LocalePreviewPage extends StatelessWidget {
  const LocalePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.copyOf(context);
    final locale = NanoLocaleScope.localeOf(context);
    return NanoScaffold(
      appBar: AppBar(title: Text(copy.localePreviewTitle)),
      body: ListView(
        children: [
          Text(copy.localePreviewBody),
          const SizedBox(height: NanoSpacing.md),
          Text(
            copy.sampleSentence,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: NanoSpacing.md),
          Text(
            '${copy.languageEnglish} / ${copy.languageUrdu}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            'Direction: ${locale.isRtl ? 'RTL' : 'LTR'} · tag=${locale.tag}',
          ),
          const SizedBox(height: NanoSpacing.lg),
          Text(copy.greeting('Ali'), style: Theme.of(context).textTheme.titleLarge),
          Text(copy.subjects),
          Text(copy.todaysMission),
          Text(copy.maintenanceTitle),
          const SizedBox(height: NanoSpacing.lg),
          JuniorActionCard(
            title: copy.subjects,
            subtitle: copy.continueLearning,
            backgroundColor: NanoColors.worldMath,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
