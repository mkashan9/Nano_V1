// The adapter contract every provider implements (MED-01).
//
// An adapter turns a request into bytes. It does not decide who may ask, what to
// charge, where the file is stored, or what happens on failure — those belong to
// the database and to the function that calls the adapter. Keeping adapters this
// small is what lets a provider be swapped without touching any rule.

export type GeneratedAssetKind = 'image' | 'voice' | 'video';

export interface AssetRequest {
  readonly kind: GeneratedAssetKind;
  readonly slot: string;
  readonly prompt: string;
  readonly locale: string;
  readonly aspectRatio: string;
  /// Stable per request, so a provider that accepts a seed returns the same
  /// output for the same ask.
  readonly promptHash: string;
  /// The provider's own name for the voice, resolved from the registry (MED-03).
  /// Absent for anything that is not a recording.
  readonly voiceName?: string;
}

export interface GeneratedBytes {
  readonly bytes: Uint8Array;
  readonly contentType: string;
  readonly extension: string;
  readonly providerReference?: string;
  /// What the call cost, in millionths of a currency unit. Zero for a free path.
  readonly costMicros: number;
}

export interface ProviderAdapter {
  readonly id: string;
  readonly kind: GeneratedAssetKind;
  generate(request: AssetRequest, fetchImpl?: typeof fetch): Promise<GeneratedBytes>;
}

/// A failure a caller may be told about, by code. The message stays for logs and
/// for the asset row; it is never provider output echoed back verbatim.
export class ProviderError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly retryable = false,
  ) {
    super(message);
    this.name = 'ProviderError';
  }
}

/// Ten megabytes: enough for a short clip, small enough that a runaway provider
/// response cannot fill a bucket.
export const maxAssetBytes = 10 * 1024 * 1024;

/// Aspect ratio to pixels, so a provider that wants dimensions gets them from the
/// same string the hash was built from.
export function dimensionsFor(aspectRatio: string): { width: number; height: number } {
  const base = 768;
  const [rawWidth, rawHeight] = aspectRatio.split(':');
  const widthRatio = Number(rawWidth);
  const heightRatio = Number(rawHeight);
  if (!Number.isFinite(widthRatio) || !Number.isFinite(heightRatio)
      || widthRatio <= 0 || heightRatio <= 0) {
    return { width: base, height: base };
  }
  if (widthRatio >= heightRatio) {
    return {
      width: base,
      height: Math.round((base * heightRatio) / widthRatio),
    };
  }
  return {
    width: Math.round((base * widthRatio) / heightRatio),
    height: base,
  };
}

/// A provider seed derived from the request, so regenerating an asset that was
/// lost produces the same picture rather than a different one.
export function seedFrom(promptHash: string): number {
  return parseInt(promptHash.slice(0, 8), 16) % 2_147_483_647;
}

export async function readBody(
  response: Response,
  providerId: string,
): Promise<Uint8Array> {
  const buffer = new Uint8Array(await response.arrayBuffer());
  if (buffer.byteLength === 0) {
    throw new ProviderError(
      'PROVIDER_EMPTY_RESPONSE',
      `${providerId} returned no bytes`,
      true,
    );
  }
  if (buffer.byteLength > maxAssetBytes) {
    throw new ProviderError(
      'PROVIDER_RESPONSE_TOO_LARGE',
      `${providerId} returned ${buffer.byteLength} bytes`,
    );
  }
  return buffer;
}
