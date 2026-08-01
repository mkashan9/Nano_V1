import {
  configuredVideoAdapter,
  configuredVoiceAdapter,
} from './configured_provider.ts';
import { geminiVoiceAdapter } from './gemini_voice.ts';
import { PollinationsImageAdapter } from './pollinations_image.ts';
import { GeneratedAssetKind, ProviderAdapter, ProviderError } from './types.ts';

/// The adapters this function knows how to run (MED-01).
///
/// The database decides which provider a request uses; this map only says how to
/// run it. A provider id that reaches here without an adapter is a deployment
/// mismatch, and it fails as a recorded, named failure rather than a crash.
export function adapters(): ProviderAdapter[] {
  return [
    new PollinationsImageAdapter(),
    // The Learning Guide's voice (MED-03). The generic voice adapter stays
    // registered so a project pointed at a different service keeps working.
    geminiVoiceAdapter(),
    configuredVoiceAdapter(),
    configuredVideoAdapter(),
  ];
}

export function adapterFor(
  providerId: string,
  kind: GeneratedAssetKind,
): ProviderAdapter {
  const adapter = adapters().find((candidate) => candidate.id === providerId);
  if (!adapter) {
    throw new ProviderError(
      'ADAPTER_MISSING',
      `No adapter is deployed for provider ${providerId}`,
    );
  }
  if (adapter.kind !== kind) {
    throw new ProviderError(
      'ADAPTER_KIND_MISMATCH',
      `Adapter ${providerId} does not serve ${kind}`,
    );
  }
  return adapter;
}
