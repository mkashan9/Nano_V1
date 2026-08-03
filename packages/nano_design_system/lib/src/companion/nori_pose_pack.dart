import 'package:nano_domain/nano_domain.dart';

import 'companion_pose_pack.dart';

/// Deprecated: use [CompanionPosePack]. Kept as [NoriPosePack] for call-site compat.
@Deprecated('Use CompanionPosePack (CMP-04 humanoid companion).')
abstract final class NoriPosePack {
  static const package = CompanionPosePack.package;

  static String assetFor(CompanionMood mood) =>
      CompanionPosePack.assetFor(mood);

  static Iterable<String> get all => CompanionPosePack.all;
}
