import {
  type AssetRequest,
  type GeneratedBytes,
  maxAssetBytes,
  ProviderError,
  type ProviderAdapter,
} from './types.ts';

// MED-06: the Learning Guide's voice, through Fish Audio.
//
// Fish is simpler to talk to than the model this replaces. One POST, one body of
// audio back, already encoded — no base64, no headerless PCM, no WAV header to
// write by hand. Three things are still worth knowing:
//
//   * The model is a *header*, not a body field, and it is required. Sending the
//     wrong one is a 401 rather than a fallback, so it is read from the
//     environment with a working default rather than guessed per request.
//   * A voice is a `reference_id` from Fish's library. Nano has not picked one,
//     so the registry says `stock` and this adapter sends no reference at all,
//     which is Fish's own default voice. That is a deliberate value, not a
//     missing one: an empty registry entry would read as an oversight.
//   * MP3 comes back, not WAV. Smaller over a classroom connection and playable
//     everywhere Nano runs.
//
// The key is read at call time, sent as a bearer header, and never logged,
// returned, or written into a URL. Every line already has a caption, so an
// unconfigured provider is an ordinary recorded failure and never a blank screen.

const defaultEndpoint = 'https://api.fish.audio';
const defaultModel = 's2.1-pro-free';

/// The registry's word for "no particular voice". Anything else is sent to Fish
/// verbatim as a reference_id.
const stockVoice = 'stock';

export class FishAudioVoiceAdapter implements ProviderAdapter {
  readonly id = 'fish_audio_voice';
  readonly kind = 'voice' as const;

  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    const key = (Deno.env.get('VOICE_PROVIDER_API_KEY') ?? '').trim();
    if (key === '') {
      // Not a fault to retry: a recording simply cannot be made until an
      // operator supplies a key, and every line already has a caption.
      throw new ProviderError(
        'PROVIDER_UNCONFIGURED',
        'VOICE_PROVIDER_API_KEY is not set',
      );
    }

    const text = request.prompt.trim();
    if (text === '') {
      throw new ProviderError('PROVIDER_EMPTY_REQUEST', 'There is nothing to say');
    }

    const endpoint = (Deno.env.get('VOICE_PROVIDER_URL') ?? defaultEndpoint)
      .replace(/\/$/, '');
    const model = (Deno.env.get('VOICE_PROVIDER_MODEL') ?? defaultModel).trim();

    // A registered voice that is not the stock voice must arrive resolved. An
    // unresolved one is refused rather than quietly recorded in whatever voice
    // the account happens to default to — that would pass every check and sound
    // wrong to a child.
    const registered = (request.voiceName ?? '').trim();
    if (registered === '') {
      throw new ProviderError(
        'PROVIDER_UNCONFIGURED',
        'No provider voice was resolved for this request',
      );
    }
    const referenceId = registered.toLowerCase() === stockVoice ? undefined : registered;

    let response: Response;
    try {
      response = await fetchImpl(`${endpoint}/v1/tts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${key}`,
          // Required by Fish, and a header rather than a body field.
          model,
        },
        body: JSON.stringify({
          text,
          ...(referenceId ? { reference_id: referenceId } : {}),
          format: 'mp3',
          mp3_bitrate: 128,
          // Fish reads digits and abbreviations more steadily with this on, and
          // a learning app says numbers out loud constantly.
          normalize: true,
          // Quality over latency. Nothing waits on this: a recording is made
          // once, reviewed, and then served from storage forever.
          latency: 'normal',
        }),
      });
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_UNREACHABLE',
        `${this.id} could not be reached`,
        true,
      );
    }

    if (response.status === 402) {
      // Fish's own word for an empty balance. Distinct from a rejection because
      // the request was fine and asking again tomorrow may well work.
      throw new ProviderError(
        'PROVIDER_OUT_OF_CREDIT',
        `${this.id} reports no remaining credit`,
      );
    }
    if (response.status >= 500 || response.status === 429) {
      throw new ProviderError(
        'PROVIDER_UNAVAILABLE',
        `${this.id} returned ${response.status}`,
        true,
      );
    }
    if (!response.ok) {
      // The provider's own message may quote the line, so only the status is
      // kept: an authored line is not something to scatter through logs.
      throw new ProviderError(
        'PROVIDER_REJECTED',
        `${this.id} returned ${response.status}`,
      );
    }

    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.byteLength === 0) {
      throw new ProviderError('PROVIDER_EMPTY_RESPONSE', `${this.id} returned no audio`);
    }
    if (bytes.byteLength > maxAssetBytes) {
      throw new ProviderError(
        'PROVIDER_RESPONSE_TOO_LARGE',
        `${this.id} returned ${bytes.byteLength} bytes`,
      );
    }

    return {
      bytes,
      contentType: 'audio/mpeg',
      extension: 'mp3',
      providerReference: referenceId ?? `${model}:${stockVoice}`,
      costMicros: estimatedCostMicros(text),
    };
  }
}

export function fishAudioVoiceAdapter(): FishAudioVoiceAdapter {
  return new FishAudioVoiceAdapter();
}

/// Fish bills by the size of the text, and the response does not price itself,
/// so this is arithmetic on a published rate rather than a figure the provider
/// told us. Unlike the adapter it replaces, the default is not zero: a cost
/// budget that reads zero for every recording is a cost budget that never stops
/// anything (MED-02), and a wrong-but-honest estimate refuses sooner than never.
const defaultCostMicrosPer1kChars = 15_000;

function estimatedCostMicros(text: string): number {
  const configured = Number(
    Deno.env.get('VOICE_PROVIDER_COST_MICROS_PER_1K_CHARS') ?? '',
  );
  const perThousand = Number.isFinite(configured) && configured > 0
    ? configured
    : defaultCostMicrosPer1kChars;
  // Fish counts UTF-8 bytes, and Urdu costs several bytes a character. Counting
  // characters would under-bill Urdu by a factor of three against a budget that
  // exists to stop surprises.
  const bytes = new TextEncoder().encode(text).length;
  return Math.ceil((bytes / 1000) * perThousand);
}
