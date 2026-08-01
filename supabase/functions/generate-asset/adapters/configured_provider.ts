import {
  AssetRequest,
  dimensionsFor,
  GeneratedAssetKind,
  GeneratedBytes,
  ProviderAdapter,
  ProviderError,
  readBody,
} from './types.ts';

/// Voice and video adapter for whichever provider the environment names (MED-01).
///
/// No provider is chosen yet: MED-03 picks the Aoede voice and MED-04 picks the
/// clip provider. What MED-01 fixes now is the shape — the key is read from Edge
/// Function environment and never travels anywhere else, and a missing key is an
/// ordinary recorded failure rather than an exception. That matters because every
/// companion moment already has a local fallback: an unconfigured provider makes a
/// generated extra unavailable, never a screen unusable.
export class ConfiguredProviderAdapter implements ProviderAdapter {
  constructor(
    readonly id: string,
    readonly kind: GeneratedAssetKind,
    private readonly keyEnv: string,
    private readonly urlEnv: string,
    private readonly contentType: string,
    private readonly extension: string,
  ) {}

  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    const key = Deno.env.get(this.keyEnv);
    const endpoint = Deno.env.get(this.urlEnv);
    if (!key || key.trim() === '' || !endpoint || endpoint.trim() === '') {
      throw new ProviderError(
        'PROVIDER_UNCONFIGURED',
        `${this.id} has no provider configured in this environment`,
      );
    }

    const { width, height } = dimensionsFor(request.aspectRatio);
    let response: Response;
    try {
      response = await fetchImpl(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // The key exists in this process and in the request to the provider.
          // It is never logged, returned, or stored.
          Authorization: `Bearer ${key}`,
        },
        body: JSON.stringify({
          prompt: request.prompt,
          locale: request.locale,
          slot: request.slot,
          aspect_ratio: request.aspectRatio,
          width,
          height,
          seed: request.promptHash,
        }),
      });
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_UNREACHABLE',
        `Could not reach ${this.id}`,
        true,
      );
    }

    if (!response.ok) {
      throw new ProviderError(
        response.status >= 500 ? 'PROVIDER_UNAVAILABLE' : 'PROVIDER_REJECTED',
        `${this.id} responded ${response.status}`,
        response.status >= 500,
      );
    }

    const bytes = await readBody(response, this.id);
    return {
      bytes,
      contentType: response.headers.get('content-type') ?? this.contentType,
      extension: this.extension,
      providerReference: response.headers.get('x-request-id') ?? undefined,
      costMicros: Number(response.headers.get('x-cost-micros') ?? '0') || 0,
    };
  }
}

export function configuredVoiceAdapter(): ConfiguredProviderAdapter {
  return new ConfiguredProviderAdapter(
    'configured_voice',
    'voice',
    'VOICE_PROVIDER_API_KEY',
    'VOICE_PROVIDER_URL',
    'audio/mpeg',
    'mp3',
  );
}

export function configuredVideoAdapter(): ConfiguredProviderAdapter {
  return new ConfiguredProviderAdapter(
    'configured_video',
    'video',
    'VIDEO_PROVIDER_API_KEY',
    'VIDEO_PROVIDER_URL',
    'video/mp4',
    'mp4',
  );
}
