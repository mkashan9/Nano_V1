import {
  AssetRequest,
  dimensionsFor,
  GeneratedBytes,
  ProviderAdapter,
  ProviderError,
  readBody,
  seedFrom,
} from './types.ts';

/// Image adapter for image.pollinations.ai (MED-01).
///
/// The primary image path on purpose: it needs no privileged key, so the first
/// working generation path in Nano cannot leak one. The prompt travels in the URL
/// and the seed comes from the request hash, which makes a regeneration return the
/// same picture rather than a new one.
export class PollinationsImageAdapter implements ProviderAdapter {
  readonly id = 'pollinations_image';
  readonly kind = 'image' as const;

  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    const base = Deno.env.get('IMAGE_POLLINATIONS_BASE_URL')
      ?? 'https://image.pollinations.ai';
    const { width, height } = dimensionsFor(request.aspectRatio);
    const url = new URL(`${base}/prompt/${encodeURIComponent(request.prompt)}`);
    url.searchParams.set('width', String(width));
    url.searchParams.set('height', String(height));
    url.searchParams.set('seed', String(seedFrom(request.promptHash)));
    url.searchParams.set('nologo', 'true');

    let response: Response;
    try {
      response = await fetchImpl(url, { method: 'GET' });
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_UNREACHABLE',
        'Could not reach the image provider',
        true,
      );
    }

    if (!response.ok) {
      throw new ProviderError(
        response.status >= 500 ? 'PROVIDER_UNAVAILABLE' : 'PROVIDER_REJECTED',
        `Image provider responded ${response.status}`,
        response.status >= 500,
      );
    }

    const bytes = await readBody(response, this.id);
    const contentType = response.headers.get('content-type') ?? 'image/png';
    return {
      bytes,
      contentType,
      extension: contentType.includes('jpeg') ? 'jpg' : 'png',
      providerReference: url.pathname,
      costMicros: 0,
    };
  }
}
