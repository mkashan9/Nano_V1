import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-01 Settings: edit school branding and mark setup complete.
class SchoolBrandingSettingsPage extends StatefulWidget {
  const SchoolBrandingSettingsPage({
    super.key,
    required this.repository,
  });

  final SchoolDashboardRepository repository;

  @override
  State<SchoolBrandingSettingsPage> createState() =>
      _SchoolBrandingSettingsPageState();
}

class _SchoolBrandingSettingsPageState
    extends State<SchoolBrandingSettingsPage> {
  NanoViewState _state = const NanoViewLoading();
  var _busy = false;
  final _displayName = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _primary = TextEditingController();
  final _secondary = TextEditingController();
  final _year = TextEditingController();
  final _logo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _address.dispose();
    _email.dispose();
    _phone.dispose();
    _primary.dispose();
    _secondary.dispose();
    _year.dispose();
    _logo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final dashboard = await widget.repository.load();
      if (!mounted) return;
      _displayName.text = dashboard.displayName;
      _address.text = dashboard.addressLine;
      _email.text = dashboard.contactEmail;
      _phone.text = dashboard.contactPhone;
      _primary.text = dashboard.primaryColor;
      _secondary.text = dashboard.secondaryColor;
      _year.text = dashboard.academicYearLabel;
      _logo.text = dashboard.logoUrl;
      setState(() => _state = const NanoViewReady());
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _save({bool markComplete = false}) async {
    setState(() => _busy = true);
    try {
      await widget.repository.updateBranding(
        displayName: _displayName.text,
        addressLine: _address.text,
        contactEmail: _email.text,
        contactPhone: _phone.text,
        primaryColor: _primary.text.trim(),
        secondaryColor: _secondary.text.trim(),
        academicYearLabel: _year.text,
        logoUrl: _logo.text,
        markSetupComplete: markComplete,
      );
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.schoolBrandingSaved)),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              children: [
                Text(
                  copy.schoolBrandingTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: NanoSpacing.xs),
                Text(copy.schoolBrandingSubtitle),
                const SizedBox(height: NanoSpacing.lg),
                TextField(
                  controller: _displayName,
                  decoration: InputDecoration(
                    labelText: copy.schoolDisplayName,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _year,
                  decoration: InputDecoration(
                    labelText: copy.schoolAcademicYear,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _primary,
                  decoration: InputDecoration(
                    labelText: copy.schoolPrimaryColor,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _secondary,
                  decoration: InputDecoration(
                    labelText: copy.schoolSecondaryColor,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: copy.schoolAddress,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: copy.schoolContactEmail,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _phone,
                  decoration: InputDecoration(
                    labelText: copy.schoolContactPhone,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _logo,
                  decoration: InputDecoration(
                    labelText: copy.schoolLogoUrl,
                  ),
                ),
                const SizedBox(height: NanoSpacing.lg),
                Wrap(
                  spacing: NanoSpacing.sm,
                  runSpacing: NanoSpacing.sm,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : () => _save(),
                      child: Text(copy.schoolSaveBranding),
                    ),
                    OutlinedButton(
                      onPressed:
                          _busy ? null : () => _save(markComplete: true),
                      child: Text(copy.schoolMarkSetupComplete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
