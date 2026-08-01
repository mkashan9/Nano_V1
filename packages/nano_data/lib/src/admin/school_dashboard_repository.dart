import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-01 school-admin overview and branding.
abstract class SchoolDashboardRepository {
  Future<SchoolDashboard> load();

  Future<SchoolDashboard> updateBranding({
    String? displayName,
    String? logoUrl,
    String? bannerUrl,
    String? addressLine,
    String? contactEmail,
    String? contactPhone,
    String? primaryColor,
    String? secondaryColor,
    String? academicYearLabel,
    bool markSetupComplete = false,
  });
}

class FakeSchoolDashboardRepository implements SchoolDashboardRepository {
  FakeSchoolDashboardRepository({SchoolDashboard? seed})
      : _dashboard = seed ??
            SchoolDashboard(
              schoolId: TenancyFixtures.alphaSchoolId,
              code: 'ALPHA01',
              name: 'Alpha Academy',
              displayName: 'Alpha Academy',
              status: 'active',
              learnerCount: 30,
              staffCount: 4,
              teacherCount: 3,
              classCount: 0,
              primaryColor: '#2F7BFF',
              secondaryColor: '#1B4F9C',
              academicYearLabel: '2026-27',
              addressLine: 'Lahore',
              contactEmail: 'office@alpha.example',
              setup: const SchoolSetupProgress(
                hasAdmin: true,
                brandingReady: true,
                contactReady: true,
                academicYearReady: true,
                setupCompleted: false,
              ),
            );

  SchoolDashboard _dashboard;
  var alwaysFail = false;
  var updateCount = 0;

  @override
  Future<SchoolDashboard> load() async {
    if (alwaysFail) throw StateError('School dashboard unavailable');
    return _dashboard;
  }

  @override
  Future<SchoolDashboard> updateBranding({
    String? displayName,
    String? logoUrl,
    String? bannerUrl,
    String? addressLine,
    String? contactEmail,
    String? contactPhone,
    String? primaryColor,
    String? secondaryColor,
    String? academicYearLabel,
    bool markSetupComplete = false,
  }) async {
    if (alwaysFail) throw StateError('School branding update failed');
    if (primaryColor != null && !SchoolBrandColorRules.isValid(primaryColor)) {
      throw StateError('Brand colors must be #RRGGBB hex values.');
    }
    if (secondaryColor != null &&
        !SchoolBrandColorRules.isValid(secondaryColor)) {
      throw StateError('Brand colors must be #RRGGBB hex values.');
    }
    updateCount++;
    final next = SchoolDashboard(
      schoolId: _dashboard.schoolId,
      code: _dashboard.code,
      name: _dashboard.name,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : _dashboard.displayName,
      status: _dashboard.status,
      logoUrl: logoUrl ?? _dashboard.logoUrl,
      bannerUrl: bannerUrl ?? _dashboard.bannerUrl,
      addressLine: addressLine ?? _dashboard.addressLine,
      contactEmail: contactEmail ?? _dashboard.contactEmail,
      contactPhone: contactPhone ?? _dashboard.contactPhone,
      primaryColor: primaryColor ?? _dashboard.primaryColor,
      secondaryColor: secondaryColor ?? _dashboard.secondaryColor,
      academicYearLabel: academicYearLabel ?? _dashboard.academicYearLabel,
      learnerCount: _dashboard.learnerCount,
      staffCount: _dashboard.staffCount,
      teacherCount: _dashboard.teacherCount,
      classCount: _dashboard.classCount,
      setup: SchoolSetupProgress(
        hasAdmin: true,
        brandingReady: true,
        contactReady:
            (contactEmail ?? _dashboard.contactEmail).trim().isNotEmpty ||
                (addressLine ?? _dashboard.addressLine).trim().isNotEmpty,
        academicYearReady:
            (academicYearLabel ?? _dashboard.academicYearLabel)
                .trim()
                .isNotEmpty,
        setupCompleted:
            markSetupComplete || _dashboard.setup.setupCompleted,
      ),
    );
    _dashboard = next;
    return next;
  }
}

class SupabaseSchoolDashboardRepository implements SchoolDashboardRepository {
  SupabaseSchoolDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SchoolDashboard> load() async {
    final raw = await _client.rpc('school_dashboard');
    if (raw is! Map) {
      throw StateError('School dashboard unavailable.');
    }
    return SchoolDashboard.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<SchoolDashboard> updateBranding({
    String? displayName,
    String? logoUrl,
    String? bannerUrl,
    String? addressLine,
    String? contactEmail,
    String? contactPhone,
    String? primaryColor,
    String? secondaryColor,
    String? academicYearLabel,
    bool markSetupComplete = false,
  }) async {
    final raw = await _client.rpc(
      'update_school_branding',
      params: {
        'p_display_name': displayName,
        'p_logo_url': logoUrl,
        'p_banner_url': bannerUrl,
        'p_address_line': addressLine,
        'p_contact_email': contactEmail,
        'p_contact_phone': contactPhone,
        'p_primary_color': primaryColor,
        'p_secondary_color': secondaryColor,
        'p_academic_year_label': academicYearLabel,
        'p_mark_setup_complete': markSetupComplete,
      },
    );
    if (raw is! Map) {
      throw StateError('School branding update failed.');
    }
    return SchoolDashboard.fromJson(Map<String, dynamic>.from(raw));
  }
}
