import {
  configuredVideoAdapter,
  configuredVoiceAdapter,
} from './configured_provider.ts';
import { fishAudioVoiceAdapter } from './fish_audio_voice.ts';
import { geminiVeoAdapter } from './gemini_veo.ts';
import { geminiVoiceAdapter } from './gemini_voice.ts';
import { json2VideoComposeAdapter } from './json2video_compose.ts';
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
    // The Learning Guide's voice (MED-06). The adapters it replaced stay
    // registered: the database decides which provider a request uses, and a
    // provider row that is switched back should not also need a redeploy.
    fishAudioVoiceAdapter(),
    geminiVoiceAdapter(),
    configuredVoiceAdapter(),
    // Companion clips (MED-06), composed from approved art rather than
    // generated from a description. Same reasoning for the ones below it.
    json2VideoComposeAdapter(),
    geminiVeoAdapter(),
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
