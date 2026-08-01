import {
  type AssetRequest,
  type GeneratedBytes,
  ProviderError,
  type ProviderAdapter,
  readBody,
} from './types.ts';

// MED-07: reaction clips as character animation, through Wan 2.2 image-to-video.
//
// MED-06 composed clips by panning a camera over a still. The owner's verdict on
// the first one was that it looks very fake, and it did: nothing in the picture
// moved. This adapter animates the picture instead — Nori waves, blinks, and
// breathes — while still starting from art a reviewer already approved.
//
// Four things about this provider shape the code more than the model does:
//
//   * **It is not resumable.** Disconnecting from the event stream kills the
//     job; reconnecting to the same event id returns an error, not the render.
//     That was measured, not assumed. So unlike MED-04's Veo and MED-06's
//     json2video there is no pending/collect here: this adapter holds the
//     connection for the whole render or comes back with nothing.
//   * **It will not fetch a URL.** The picture has to be uploaded to the Space
//     first, then referenced by the path it hands back.
//   * **`frame_multiplier` is a number**, despite the published schema calling
//     it a string. Sending "16" is rejected against the choices [16,32,64,128],
//     and the rejection arrives as a bare `event: error` with no message.
//   * **It can invent.** An image-to-video model can deform a face or grow a
//     limb, which is exactly what json2video could not do. The negative prompt
//     pushes against that, but the real control is MED-05: a human approves
//     every clip before a child sees it. Do not weaken that gate on the
//     strength of this prompt.
//
// It is a public Hugging Face Space with no SLA, owned by nobody Nano has an
// agreement with. It can sleep, queue behind strangers, or vanish. Every
// failure here is therefore shaped to let the caller fall back to the composer
// rather than leave a reaction with no clip at all.

const defaultSpace = 'https://cinderholm-wan2-2-i2v-v3.hf.space';

/// The render itself took 31s warm and 78s cold while this was being written.
/// A ceiling well above both, and still under an Edge Function's wall clock,
/// so a Space that has queued us behind other people's jobs gives up in time
/// for the fallback to run inside the same invocation.
const defaultDeadlineSeconds = 110;

/// Steps buys quality with time. Six is what the Space itself defaults to and
/// what produced art that stayed on model; raising it risks the deadline.
const defaultSteps = 6;

/// What the character does, per authored motion. MED-06's motions named camera
/// moves because a composer could only move a camera. The names are kept so no
/// authored clip has to be rewritten, but they now describe the character,
/// which is the whole point of this module.
const motionDirection: Record<string, string> = {
  hold:
    'The character stays still and simply breathes, blinking once, calm and attentive.',
  settle:
    'The character settles gently into place and gives a small, warm smile.',
  driftIn:
    'The character gently waves hello and blinks, with a warm friendly smile.',
  pushIn:
    'The character celebrates with a happy little bounce and raises both arms.',
  dip:
    'The character tilts its head and gives an encouraging nod.',
};

/// Pushed against on every request. Most of these are the failure modes of an
/// image-to-video model applied to a cartoon mascot: melting faces, spare
/// limbs, and the character wandering off model.
const negativePrompt = [
  'static, still, frozen, no motion',
  'deformed, disfigured, malformed, distorted',
  'extra limbs, extra arms, extra fingers, fused fingers, missing limbs',
  'face morphing, changing face, inconsistent character, off model',
  'multiple characters, duplicate character',
  'blurry, low quality, jpeg artifacts, grainy',
  'watermark, text, subtitles, logo, signature',
  'camera shake, rapid movement, violent motion',
  'photorealistic, live action, human skin',
].join(', ');

interface FileData {
  readonly path?: string;
  readonly url?: string;
}

export class WanI2VSpaceAdapter implements ProviderAdapter {
  readonly id = 'wan_i2v_space';
  readonly kind = 'video' as const;

  // Deliberately no `generateOrPending`. See the note about resumability: a job
  // this adapter cannot come back to must not be recorded as one that it can.
  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    // The compose gate, restated at the adapter boundary. The database only
    // supplies art a reviewer approved, so an absent picture means this was
    // reached by a path that skipped that check.
    if (!request.sourceImageUrl) {
      throw new ProviderError(
        'PROVIDER_NO_SOURCE_ART',
        `${this.id} animates approved art and was given none`,
      );
    }

    const motion = (request.motion ?? '').trim();
    const direction = motionDirection[motion];
    if (!direction) {
      // Picking a movement for an unknown name would put motion nobody
      // authored in front of a child.
      throw new ProviderError(
        'PROVIDER_UNKNOWN_MOTION',
        `${this.id} does not know the motion ${motion || '(none)'}`,
      );
    }

    const space = (Deno.env.get('VIDEO_SPACE_URL') ?? defaultSpace)
      .replace(/\/$/, '');
    const deadline = Date.now() + deadlineSeconds() * 1000;

    const artwork = await this.#fetchArtwork(request.sourceImageUrl, fetchImpl);
    const uploadedPath = await this.#upload(space, artwork, fetchImpl);
    const eventId = await this.#start(
      space,
      uploadedPath,
      direction,
      request,
      fetchImpl,
    );
    const video = await this.#awaitResult(space, eventId, deadline, fetchImpl);
    const bytes = await this.#download(space, video, fetchImpl);

    return {
      bytes,
      contentType: 'video/mp4',
      extension: 'mp4',
      providerReference: eventId,
      // A public Space bills nothing. Recorded honestly as free rather than
      // padded with an estimate: MED-02's budget should stop real spending,
      // and pretending this costs money would make it refuse for no reason.
      costMicros: 0,
    };
  }

  async #fetchArtwork(
    url: string,
    fetchImpl: typeof fetch,
  ): Promise<Uint8Array<ArrayBuffer>> {
    let response: Response;
    try {
      response = await fetchImpl(url);
    } catch (_error) {
      throw new ProviderError(
        'COMPOSITION_SOURCE_UNREADABLE',
        'Approved art could not be read',
        true,
      );
    }
    if (!response.ok) {
      throw new ProviderError(
        'COMPOSITION_SOURCE_UNREADABLE',
        `Approved art returned ${response.status}`,
        true,
      );
    }
    return await readBody(response, this.id);
  }

  /// The Space refuses to fetch a remote picture, so it has to be handed the
  /// bytes. Measured: passing a signed URL as FileData fails with a bare error.
  async #upload(
    space: string,
    artwork: Uint8Array<ArrayBuffer>,
    fetchImpl: typeof fetch,
  ): Promise<string> {
    const form = new FormData();
    form.append(
      'files',
      new Blob([artwork], { type: 'image/jpeg' }),
      'companion.jpg',
    );

    const response = await this.#send(
      () => fetchImpl(`${space}/gradio_api/upload`, { method: 'POST', body: form }),
      'upload',
    );

    const paths = await response.json().catch(() => null);
    const path = Array.isArray(paths) ? paths[0] : undefined;
    if (typeof path !== 'string' || path === '') {
      throw new ProviderError(
        'PROVIDER_UNEXPECTED_RESPONSE',
        `${this.id} did not return an uploaded path`,
        true,
      );
    }
    return path;
  }

  async #start(
    space: string,
    uploadedPath: string,
    direction: string,
    request: AssetRequest,
    fetchImpl: typeof fetch,
  ): Promise<string> {
    // Positional, in the order the Space publishes. A named-argument API this
    // is not, so the order is the contract and reordering it silently animates
    // the wrong thing.
    const data = [
      { path: uploadedPath, meta: { _type: 'gradio.FileData' }, orig_name: 'companion.jpg' },
      null,
      `${direction} Clean flat background, cartoon mascot style preserved, `
      + 'the character stays centered and on model, gentle looping motion, '
      + 'no camera movement.',
      defaultSteps,
      negativePrompt,
      clipSeconds(request.durationSeconds),
      1,
      1,
      // The same ask yields the same clip, so a lost file can be remade rather
      // than re-rolled into something a reviewer has to judge again.
      seedFrom(request.promptHash),
      false,
      6,
      'UniPCMultistep',
      3,
      // A number. The published schema says string; the Space rejects strings.
      16,
      true,
      [],
      true,
    ];

    const response = await this.#send(
      () =>
        fetchImpl(`${space}/gradio_api/call/generate_video`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ data }),
        }),
      'call',
    );

    const body = await response.json().catch(() => null);
    const eventId = (body as { event_id?: string } | null)?.event_id;
    if (typeof eventId !== 'string' || eventId === '') {
      throw new ProviderError(
        'PROVIDER_UNEXPECTED_RESPONSE',
        `${this.id} did not return an event id`,
        true,
      );
    }
    return eventId;
  }

  /// Holds the stream to the end. There is no coming back to this job later, so
  /// giving up here means giving up on the render — which is survivable only
  /// because the caller has a composer to fall back to.
  async #awaitResult(
    space: string,
    eventId: string,
    deadline: number,
    fetchImpl: typeof fetch,
  ): Promise<FileData> {
    const remaining = deadline - Date.now();
    if (remaining <= 0) {
      throw new ProviderError('PROVIDER_TIMEOUT', `${this.id} ran out of time`, true);
    }

    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), remaining);
    let response: Response;
    try {
      response = await fetchImpl(
        `${space}/gradio_api/call/generate_video/${eventId}`,
        { signal: abort.signal },
      );
    } catch (_error) {
      clearTimeout(timer);
      throw new ProviderError(
        'PROVIDER_TIMEOUT',
        `${this.id} did not finish within the deadline`,
        true,
      );
    }

    if (!response.ok || !response.body) {
      clearTimeout(timer);
      throw new ProviderError(
        'PROVIDER_UNAVAILABLE',
        `${this.id} returned ${response.status} for the result stream`,
        true,
      );
    }

    try {
      return await readEventStream(response.body, this.id);
    } catch (error) {
      if (error instanceof ProviderError) throw error;
      throw new ProviderError(
        'PROVIDER_TIMEOUT',
        `${this.id} did not finish within the deadline`,
        true,
      );
    } finally {
      clearTimeout(timer);
    }
  }

  async #download(
    space: string,
    video: FileData,
    fetchImpl: typeof fetch,
  ): Promise<Uint8Array<ArrayBuffer>> {
    const url = video.url
      ?? (video.path ? `${space}/gradio_api/file=${video.path}` : undefined);
    if (!url) {
      throw new ProviderError(
        'PROVIDER_UNEXPECTED_RESPONSE',
        `${this.id} finished without a file to fetch`,
        true,
      );
    }

    const response = await this.#send(() => fetchImpl(url), 'download');
    return await readBody(response, this.id);
  }

  /// One place for "the Space is having a bad day". Every one of these is
  /// retryable, because every one of them is a reason to use the composer
  /// instead rather than to tell a reviewer the clip is impossible.
  async #send(call: () => Promise<Response>, stage: string): Promise<Response> {
    let response: Response;
    try {
      response = await call();
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_UNREACHABLE',
        `${this.id} could not be reached during ${stage}`,
        true,
      );
    }
    if (!response.ok) {
      throw new ProviderError(
        'PROVIDER_UNAVAILABLE',
        `${this.id} returned ${response.status} during ${stage}`,
        true,
      );
    }
    return response;
  }
}

export function wanI2VSpaceAdapter(): WanI2VSpaceAdapter {
  return new WanI2VSpaceAdapter();
}

/// Server-sent events, hand-parsed because the payload is small and pulling in
/// a parser for `event:`/`data:` pairs would be more code than this.
///
/// `complete` carries the render. `error` carries nothing useful — the Space
/// sends a literal `data: null` whether the payload was malformed or the job
/// died, which is why the argument validation above is so specific.
export async function readEventStream(
  body: ReadableStream<Uint8Array>,
  providerId: string,
): Promise<FileData> {
  const reader = body.pipeThrough(new TextDecoderStream()).getReader();
  let buffered = '';

  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffered += value;

      let split = buffered.indexOf('\n\n');
      while (split !== -1) {
        const frame = buffered.slice(0, split);
        buffered = buffered.slice(split + 2);
        const parsed = parseFrame(frame, providerId);
        if (parsed) return parsed;
        split = buffered.indexOf('\n\n');
      }
    }
  } finally {
    reader.cancel().catch(() => {});
  }

  throw new ProviderError(
    'PROVIDER_UNEXPECTED_RESPONSE',
    `${providerId} closed the stream without finishing`,
    true,
  );
}

function parseFrame(frame: string, providerId: string): FileData | null {
  let event = '';
  let payload = '';
  for (const line of frame.split('\n')) {
    if (line.startsWith('event:')) event = line.slice(6).trim();
    if (line.startsWith('data:')) payload = line.slice(5).trim();
  }

  if (event === 'heartbeat' || event === 'generating' || event === '') return null;

  if (event === 'error') {
    throw new ProviderError(
      'PROVIDER_REJECTED',
      `${providerId} rejected the request`,
      true,
    );
  }

  if (event !== 'complete') return null;

  const parsed = safeParse(payload);
  // Returns are positional too: [video, download, seed]. Either of the first
  // two is the same file; the second carries a size and is preferred when the
  // first is bare.
  const first = Array.isArray(parsed) ? parsed[0] as FileData | null : null;
  const second = Array.isArray(parsed) ? parsed[1] as FileData | null : null;
  const video = second?.url || second?.path ? second : first;

  if (!video || (!video.url && !video.path)) {
    throw new ProviderError(
      'PROVIDER_EMPTY_RESPONSE',
      `${providerId} completed without a video`,
      true,
    );
  }
  return video;
}

function safeParse(payload: string): unknown {
  try {
    return JSON.parse(payload);
  } catch (_error) {
    return null;
  }
}

function deadlineSeconds(): number {
  const configured = Number(Deno.env.get('VIDEO_SPACE_DEADLINE_SECONDS') ?? '');
  return Number.isFinite(configured) && configured > 0
    ? configured
    : defaultDeadlineSeconds;
}

/// The Space accepts a window rather than any length. Authored clips are short
/// by design (MED-04), so this clamps rather than refuses.
function clipSeconds(authored?: number): number {
  if (!Number.isFinite(authored ?? NaN)) return 3.5;
  return Math.min(5, Math.max(1.5, authored as number));
}

function seedFrom(promptHash: string): number {
  const parsed = parseInt(promptHash.slice(0, 8), 16);
  return Number.isFinite(parsed) ? parsed % 2_147_483_647 : 42;
}
