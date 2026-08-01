import {
  type AssetRequest,
  dimensionsFor,
  type GeneratedBytes,
  type GenerateOutcome,
  maxAssetBytes,
  ProviderError,
  type ProviderAdapter,
} from './types.ts';

// MED-06: reaction clips, composed rather than imagined.
//
// The adapter this replaces described a companion to a model and hoped the
// footage that came back looked like Nano's companion. This one is handed the
// companion — the actual approved picture, the one a reviewer already signed off
// and a learner may already have seen — and asks a compositor to move it. Two
// consequences follow, and they are the whole reason for the switch:
//
//   * The clip cannot show anything the picture does not. There is no model to
//     invent a sixth finger or a stranger's face.
//   * The clip cannot exist before the picture is approved. That rule is not
//     enforced here; the database refuses the request before this adapter is
//     reached, and `sourceImageUrl` is only ever populated for approved art.
//
// json2video is asynchronous in the same shape Veo was, so the pending contract
// from MED-04 carries over unchanged: submitting and collecting are the same
// method, told apart by whether the asset row already carries a project id.
//
// The key is read at call time, sent as a header, and never logged or returned.
// Every reaction has local art, so an unconfigured provider is an ordinary
// recorded failure and no learner notices.

const defaultEndpoint = 'https://api.json2video.com';

/// A compositor renders in seconds, not minutes, but it queues. json2video's own
/// guidance is five to ten seconds between polls.
const pollAfterSubmit = 10;
const pollAfterCheck = 8;

/// What each authored motion renders, in the only vocabulary a compositor has:
/// a Ken Burns push and drift, plus fades. There are no keyframes here, so none
/// of these is a hop or a nod — they are named for the movement they actually
/// produce, and a curator picking one gets exactly what the name says.
///
/// `zoom` is json2video's -10..10 scale; `pan-distance` is 0.01..0.5. Every value
/// in this table sits at the quiet end of both, because the companion appears
/// beside a child who is reading.
interface Motion {
  readonly zoom: number;
  readonly pan?: 'left' | 'right' | 'top' | 'bottom';
  readonly panDistance?: number;
  readonly fadeIn: number;
  readonly fadeOut: number;
}

const motions: Record<string, Motion> = {
  hold: { zoom: 0, fadeIn: 0.3, fadeOut: 0.3 },
  settle: { zoom: 1, pan: 'top', panDistance: 0.03, fadeIn: 0.4, fadeOut: 0.4 },
  driftIn: { zoom: 1, pan: 'left', panDistance: 0.06, fadeIn: 0.6, fadeOut: 0.3 },
  pushIn: { zoom: 3, fadeIn: 0.2, fadeOut: 0.4 },
  dip: { zoom: 1, pan: 'bottom', panDistance: 0.04, fadeIn: 0.3, fadeOut: 0.3 },
};

interface SubmitPayload {
  success?: boolean;
  project?: string;
  message?: string;
}

interface StatusPayload {
  success?: boolean;
  movie?: {
    status?: string;
    url?: string | null;
    message?: string;
  };
}

export class Json2VideoComposeAdapter implements ProviderAdapter {
  readonly id = 'json2video_compose';
  readonly kind = 'video' as const;

  /// Present only because every adapter has it. A render that happened to finish
  /// inside one invocation would be luck, not a contract.
  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    const outcome = await this.generateOrPending(request, fetchImpl);
    if (outcome.status === 'ready') return outcome.bytes;
    throw new ProviderError(
      'PROVIDER_PENDING',
      `${this.id} started a render that is not finished`,
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

    const project = (request.providerJobId ?? '').trim();
    return project === ''
      ? await this.submit(request, endpoint, key, fetchImpl)
      : await this.collect(project, endpoint, key, fetchImpl);
  }

  private async submit(
    request: AssetRequest,
    endpoint: string,
    key: string,
    fetchImpl: typeof fetch,
  ): Promise<GenerateOutcome> {
    const source = (request.sourceImageUrl ?? '').trim();
    if (source === '') {
      // The database refuses this case first, so reaching it means the worker
      // and the database disagree. Refusing loudly is better than composing a
      // blank movie that a reviewer would then have to reject.
      throw new ProviderError(
        'COMPOSITION_SOURCE_MISSING',
        `${this.id} was given no approved art to animate`,
      );
    }

    const motion = motions[(request.motion ?? '').trim()];
    if (!motion) {
      // A motion nobody has seen rendered is not something to improvise on a
      // screen a child is watching.
      throw new ProviderError(
        'COMPOSITION_MOTION_UNKNOWN',
        `${this.id} does not know the motion ${request.motion ?? '(none)'}`,
      );
    }

    const duration = clampDuration(request.durationSeconds ?? 4);
    const { width, height } = dimensionsFor(request.aspectRatio);

    const response = await this.call(fetchImpl, `${endpoint}/v2/movies`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // A header, not a query parameter: a URL can end up in a log.
        'x-api-key': key,
      },
      body: JSON.stringify({
        resolution: 'custom',
        width,
        height,
        quality: 'high',
        // json2video reuses a previous render of identical input. The asset row
        // already refuses to ask twice, so this only helps when a job is
        // resubmitted after a crash — and then it is exactly what we want.
        cache: true,
        scenes: [{
          duration,
          elements: [{
            type: 'image',
            src: source,
            duration,
            // The art was approved in this exact shape (the database checks),
            // so covering the canvas crops nothing.
            resize: 'cover',
            zoom: motion.zoom,
            ...(motion.pan ? { pan: motion.pan } : {}),
            ...(motion.panDistance ? { 'pan-distance': motion.panDistance } : {}),
            'fade-in': motion.fadeIn,
            'fade-out': motion.fadeOut,
          }],
        }],
      }),
    });

    const payload = await this.readJson<SubmitPayload>(response);
    const project = (payload.project ?? '').trim();
    if (payload.success === false || project === '') {
      throw new ProviderError(
        'PROVIDER_EMPTY',
        `${this.id} accepted the request without naming a project`,
        true,
      );
    }

    return { status: 'pending', providerJobId: project, pollAfterSeconds: pollAfterSubmit };
  }

  private async collect(
    project: string,
    endpoint: string,
    key: string,
    fetchImpl: typeof fetch,
  ): Promise<GenerateOutcome> {
    const response = await this.call(
      fetchImpl,
      `${endpoint}/v2/movies?project=${encodeURIComponent(project)}`,
      { method: 'GET', headers: { 'x-api-key': key } },
    );

    const payload = await this.readJson<StatusPayload>(response);
    const status = (payload.movie?.status ?? '').trim();

    if (status === 'pending' || status === 'running' || status === 'queued') {
      return { status: 'pending', providerJobId: project, pollAfterSeconds: pollAfterCheck };
    }
    if (status === 'error' || status === 'timeout') {
      // The compositor's message names our own source URL, which is a signed
      // link, so only the status word is kept.
      throw new ProviderError(
        'PROVIDER_REJECTED',
        `${this.id} render finished as ${status}`,
      );
    }
    if (status !== 'done') {
      throw new ProviderError(
        'PROVIDER_BAD_RESPONSE',
        `${this.id} reported an unknown status`,
        true,
      );
    }

    const url = (payload.movie?.url ?? '').trim();
    if (url === '') {
      throw new ProviderError('PROVIDER_EMPTY', `${this.id} finished with no clip`);
    }

    const bytes = await this.download(url, fetchImpl);
    return {
      status: 'ready',
      bytes: {
        bytes,
        contentType: 'video/mp4',
        extension: 'mp4',
        providerReference: project,
        costMicros: costPerClipMicros(),
      },
    };
  }

  /// The rendered file is on json2video's CDN and is not behind the API key, so
  /// this download deliberately sends no credentials.
  private async download(
    url: string,
    fetchImpl: typeof fetch,
  ): Promise<Uint8Array<ArrayBuffer>> {
    const response = await this.call(fetchImpl, url, { method: 'GET' });

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
    if (response.status === 401) {
      // json2video answers 401 both for a bad key and for an exhausted plan.
      // Either way a person has to act, so it is not dressed up as retryable.
      throw new ProviderError(
        'PROVIDER_NOT_ENTITLED',
        `${this.id} refused the key or the plan quota is spent`,
      );
    }
    if (!response.ok) {
      throw new ProviderError('PROVIDER_REJECTED', `${this.id} returned ${response.status}`);
    }
    return response;
  }

  private async readJson<T>(response: Response): Promise<T> {
    try {
      return await response.json() as T;
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_BAD_RESPONSE',
        `${this.id} returned unreadable JSON`,
        true,
      );
    }
  }
}

export function json2VideoComposeAdapter(): Json2VideoComposeAdapter {
  return new Json2VideoComposeAdapter();
}

/// The library allows one to eight seconds; a compositor will happily render
/// longer, and a clip that outstays a reaction is worse than no clip.
function clampDuration(seconds: number): number {
  if (!Number.isFinite(seconds)) return 4;
  return Math.min(8, Math.max(1, Math.round(seconds)));
}

/// json2video bills rendered time against a plan allowance rather than pricing
/// each movie, so this is an operator's estimate: roughly a fifth of a cent for
/// a few seconds at typical plan rates. It is deliberately not zero — a cost
/// budget that reads zero for every clip is a cost budget that never stops
/// anything (MED-02) — and the owner corrects it once a real invoice exists.
const defaultCostMicrosPerClip = 15_000;

function costPerClipMicros(): number {
  const configured = Number(Deno.env.get('VIDEO_COST_MICROS_PER_CLIP') ?? '');
  if (!Number.isFinite(configured) || configured <= 0) return defaultCostMicrosPerClip;
  return Math.round(configured);
}
