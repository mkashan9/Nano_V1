enum AppRole {
  juniorStudent,
  seniorStudent,
  independentStudent,
  teacher,
  schoolAdmin,
  superadmin,
}

extension AppRoleX on AppRole {
  bool get isStudent =>
      this == AppRole.juniorStudent ||
      this == AppRole.seniorStudent ||
      this == AppRole.independentStudent;

  bool get usesJuniorPresentation => this == AppRole.juniorStudent;

  bool get canEverUseFlex =>
      this == AppRole.seniorStudent; // independent never; junior N/A

  String get label => switch (this) {
        AppRole.juniorStudent => 'Junior',
        AppRole.seniorStudent => 'Senior',
        AppRole.independentStudent => 'Independent',
        AppRole.teacher => 'Teacher',
        AppRole.schoolAdmin => 'School admin',
        AppRole.superadmin => 'Superadmin',
      };
}
