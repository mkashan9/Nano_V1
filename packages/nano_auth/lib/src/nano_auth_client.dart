import 'package:supabase/supabase.dart';

/// Shared Supabase client construction for Nano apps.
///
/// The plain `supabase` package defaults to PKCE, which requires
/// `asyncStorage`. Until apps adopt `supabase_flutter` session persistence,
/// email/password flows use the implicit auth flow so Flutter web signup,
/// sign-in, and recovery work without that storage.
abstract final class NanoAuthClient {
  static SupabaseClient create(String url, String anonKey) {
    return SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }
}
