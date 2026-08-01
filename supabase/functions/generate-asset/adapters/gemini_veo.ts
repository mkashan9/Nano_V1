import {
  type AssetRequest,
  type GeneratedBytes,
  type GenerateOutcome,
  maxAssetBytes,
  ProviderError,
  type ProviderAdapter,
} from './types.ts';

// MED-04: short companion clips, through Veo on the Gemini API.
//
// Every provider before this one answered in the same breath it was asked. Veo
// does not: the submit call returns an operation name and the frames arrive
// minutes later, often long after the invocation that asked for them has ended.
// That single fact shapes the whole adapter.
//
//   * Submitting and collecting are the same method, told apart by whether the
//     request already carries a job. The caller does not decide which one it is
//     doing; the asset row does, because the row is what survives.
//   * A job is never started when one exists. Starting a second Veo job for a
//     clip already in flight is a real charge for footage nobody will use.
//   * The result is a download URL, not bytes. The extra fetch is part of the
//     job, so a URL that 404s is a failed generation rather than a ready asset
//     pointing at nothing.
//
// The key is read at call time, sent as a header, and never logged, returned, or
// written into a URL. A clip is always optional — every reaction has local art —
// so an unconfigured provider is an ordinary recorded failure, never a broken
// screen.

const defaultEndpoint = 'https://generativelanguage.googleapis.com/v1beta';
const defaultModel = 'veo-2.0-generate-001';

/// Seconds to leave a job alone. A freshly submitted clip cannot possibly be
/// ready, so the first wait is the longer one.
const pollAfterSubmit = 20;
const pollAfterCheck = 15;

interface OperationPayload {
  name?: string;
  done?: boolean;
  error?: { code?: number; message?: string };
  response?: {
    generateVideoResponse?: {
      generatedSamples?: Array<{ video?: { uri?: string } }>;
    };
    generatedVideos?: Array<{ video?: { uri?: string } }>;
  };
}

export class GeminiVeoAdapter implements ProviderAdapter {
  readonly id = 'gemini_veo_video';
  readonly kind = 'video' as const;

  /// Present only because every adapter has it. A clip that happens to finish
  /// inside one invocation would be luck, not a contract, so this refuses rather
  /// than blocking an Edge Function for minutes.
  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    const outcome = await this.generateOrPending(request, fetchImpl);
    if (outcome.status === 'ready') return outcome.bytes;
    throw new ProviderError(
      'PROVIDER_PENDING',
      `${this.id} started a job that is not finished`,
      true,
    );
  }

  async generateOrPending(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GenerateOutcome> {
    const key = (Deno.env.get('VIDEO_PROVIDER_API_KEY') ?? '').trim();
    if (key === '') {
      // Not retryable: no amount of asking again produces a key, and the
      // companion already has art for this reaction.
      throw new ProviderError(
        'PROVIDER_UNCONFIGURED',
        'VIDEO_PROVIDER_API_KEY is not set',
      );
    }

    const endpoint = (Deno.env.get('VIDEO_PROVIDER_URL') ?? defaultEndpoint)
      .replace(/\/$/, '');
    const model = (Deno.env.get('VIDEO_PROVIDER_MODEL') ?? defaultModel).trim();

    const jobId = (request.providerJobId ?? '').trim();
    return jobId === ''
      ? await this.submit(request, endpoint, model, key, fetchImpl)
      : await this.collect(jobId, endpoint, key, fetchImpl);
  }

  private async submit(
    request: AssetRequest,
    endpoint: string,
    model: string,
    key: string,
    fetchImpl: typeof fetch,
  ): Promise<GenerateOutcome> {
    // Shape and length are passed through exactly as authored. Veo accepts a
    // narrower set than the library allows, so an unsupported pair comes back as
    // a named rejection a curator can read — better than quietly reframing a
    // clip that was written for one shape into another.
    const response = await this.call(
      fetchImpl,
      `${endpoint}/models/${model}:predictLongRunning`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // A header, not a query parameter: a URL can end up in a log.
          'x-goog-api-key': key,
        },
        body: JSON.stringify({
          instances: [{ prompt: request.prompt }],
          parameters: {
            aspectRatio: request.aspectRatio,
            durationSeconds: request.durationSeconds ?? 4,
            numberOfVideos: 1,
            // The companion is not a person and no authored direction asks for
            // one. Refusing people at the provider means a prompt that drifts
            // cannot put a stranger's face in front of a child.
            personGeneration: 'dont_allow',
          },
        }),
      },
    );

    const operation = await this.readOperation(response);
    const name = (operation.name ?? '').trim();
    if (name === '') {
      throw new ProviderError(
        'PROVIDER_EMPTY',
        `${this.id} accepted the request without naming a job`,
        true,
      );
    }

    return { status: 'pending', providerJobId: name, pollAfterSeconds: pollAfterSubmit };
  }

  private async collect(
    jobId: string,
    endpoint: string,
    key: string,
    fetchImpl: typeof fetch,
  ): Promise<GenerateOutcome> {
    // The job name is already a path (`models/<model>/operations/<id>`), so it
    // is appended rather than built from parts we would have to keep in step.
    const response = await this.call(
      fetchImpl,
      `${endpoint}/${jobId.replace(/^\//, '')}`,
      { method: 'GET', headers: { 'x-goog-api-key': key } },
    );

    const operation = await this.readOperation(response);
    if (operation.done !== true) {
      return { status: 'pending', providerJobId: jobId, pollAfterSeconds: pollAfterCheck };
    }
    if (operation.error) {
      // The provider's own message may quote the direction, so only the code is
      // kept. A job that failed on its own terms fails again for the same words.
      throw new ProviderError(
        'PROVIDER_REJECTED',
        `${this.id} job failed with code ${operation.error.code ?? 'unknown'}`,
      );
    }

    const uri = operation.response?.generateVideoResponse?.generatedSamples?.[0]
      ?.video?.uri
      // Newer models report the same thing under a different name; both are read
      // so a model change is a configuration change, not a code change.
      ?? operation.response?.generatedVideos?.[0]?.video?.uri;
    if (!uri) {
      // A safety filter finishes the job and returns no sample, which is a
      // refusal rather than an outage.
      throw new ProviderError('PROVIDER_EMPTY', `${this.id} finished with no clip`);
    }

    const bytes = await this.download(uri, key, fetchImpl);
    return {
      status: 'ready',
      bytes: {
        bytes,
        contentType: 'video/mp4',
        extension: 'mp4',
        // The job name, so a finished asset can still be traced back to the
        // operation that produced it.
        providerReference: jobId,
        costMicros: costPerClipMicros(),
      },
    };
  }

  private async download(
    uri: string,
    key: string,
    fetchImpl: typeof fetch,
  ): Promise<Uint8Array> {
    const response = await this.call(fetchImpl, uri, {
      method: 'GET',
      headers: { 'x-goog-api-key': key },
    });

    // Checked before the body is read, so an oversized clip is refused rather
    // than buffered into memory first.
    const declared = Number(response.headers.get('content-length') ?? '0');
    if (Number.isFinite(declared) && declared > maxAssetBytes) {
      throw new ProviderError('PROVIDER_TOO_LARGE', `${this.id} returned ${declared} bytes`);
    }

    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.byteLength === 0) {
      throw new ProviderError('PROVIDER_EMPTY', `${this.id} returned no bytes`, true);
    }
    if (bytes.byteLength > maxAssetBytes) {
      throw new ProviderError(
        'PROVIDER_TOO_LARGE',
        `${this.id} returned ${bytes.byteLength} bytes`,
      );
    }
    return bytes;
  }

  /// One place where reaching the provider can go wrong, so submit, poll, and
  /// download all fail with the same vocabulary.
  private async call(
    fetchImpl: typeof fetch,
    url: string,
    init: RequestInit,
  ): Promise<Response> {
    let response: Response;
    try {
      response = await fetchImpl(url, init);
    } catch (_error) {
      throw new ProviderError('PROVIDER_UNREACHABLE', `${this.id} could not be reached`, true);
    }

    if (response.status >= 500 || response.status === 429) {
      throw new ProviderError(
        'PROVIDER_UNAVAILABLE',
        `${this.id} returned ${response.status}`,
        true,
      );
    }
    if (!response.ok) {
      throw new ProviderError('PROVIDER_REJECTED', `${this.id} returned ${response.status}`);
    }
    return response;
  }

  private async readOperation(response: Response): Promise<OperationPayload> {
    try {
      return await response.json() as OperationPayload;
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_BAD_RESPONSE',
        `${this.id} returned unreadable JSON`,
        true,
      );
    }
  }
}

export function geminiVeoAdapter(): GeminiVeoAdapter {
  return new GeminiVeoAdapter();
}

/// Veo prices a clip, not a token, and the operation does not price itself, so
/// the figure is an operator's estimate. Unlike voice this one has a non-zero
/// default: video is the expensive kind, and a cost budget that reads zero for
/// every clip is a cost budget that never stops anything (MED-02).
const defaultCostMicrosPerClip = 50_000;

function costPerClipMicros(): number {
  const configured = Number(Deno.env.get('VIDEO_COST_MICROS_PER_CLIP') ?? '');
  if (!Number.isFinite(configured) || configured <= 0) return defaultCostMicrosPerClip;
  return Math.round(configured);
}
