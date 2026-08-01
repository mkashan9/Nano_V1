import {
  type AssetRequest,
  type GeneratedBytes,
  maxAssetBytes,
  ProviderError,
  type ProviderAdapter,
} from './types.ts';

// MED-03: the Learning Guide's voice.
//
// Gemini's speech models expose a set of named voices, one of which is Aoede, and
// return raw signed 16-bit little-endian PCM rather than a playable file. Two
// consequences shape this adapter:
//
//   * The bytes are wrapped in a WAV header here. Nothing downstream should have
//     to know that a provider handed us a headerless stream.
//   * Only the line itself is sent. The voice carries the tone, so no style
//     instruction is prefixed — a model asked to "say this warmly" sometimes says
//     "say this warmly", and a child would hear it.
//
// The key never leaves this runtime. It is read from the environment at call time,
// never logged, and never returned in an error message.

const defaultEndpoint = 'https://generativelanguage.googleapis.com/v1beta';
const defaultModel = 'gemini-3.1-flash-tts-preview';

/// Gemini names languages by region. Nano has two.
const languageCodes: Record<string, string> = {
  en: 'en-US',
  ur: 'ur-PK',
};

interface InlineDataPart {
  inlineData?: { mimeType?: string; data?: string };
}

export class GeminiVoiceAdapter implements ProviderAdapter {
  readonly id = 'gemini_voice_aoede';
  readonly kind = 'voice' as const;

  async generate(
    request: AssetRequest,
    fetchImpl: typeof fetch = fetch,
  ): Promise<GeneratedBytes> {
    const key = (Deno.env.get('VOICE_PROVIDER_API_KEY') ?? '').trim();
    if (key === '') {
      // Not a fault to retry: a recording simply cannot be made until an operator
      // supplies a key, and every line already has a caption.
      throw new ProviderError(
        'PROVIDER_UNCONFIGURED',
        'VOICE_PROVIDER_API_KEY is not set',
      );
    }

    // A voice name is required rather than defaulted: silently recording in the
    // wrong voice would pass every check and sound wrong to a child.
    const voiceName = (request.voiceName ?? '').trim();
    if (voiceName === '') {
      throw new ProviderError(
        'PROVIDER_UNCONFIGURED',
        'No provider voice name was resolved for this request',
      );
    }

    const endpoint = (Deno.env.get('VOICE_PROVIDER_URL') ?? defaultEndpoint)
      .replace(/\/$/, '');
    const model = (Deno.env.get('VOICE_PROVIDER_MODEL') ?? defaultModel).trim();

    let response: Response;
    try {
      response = await fetchImpl(
        `${endpoint}/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            // A header, not a query parameter: a URL can end up in a log.
            'x-goog-api-key': key,
          },
          body: JSON.stringify({
            contents: [{ parts: [{ text: request.prompt }] }],
            generationConfig: {
              responseModalities: ['AUDIO'],
              speechConfig: {
                languageCode: languageCodes[request.locale] ?? 'en-US',
                voiceConfig: { prebuiltVoiceConfig: { voiceName } },
              },
            },
          }),
        },
      );
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_UNREACHABLE',
        `${this.id} could not be reached`,
        true,
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
      // The provider's own message may quote the prompt, so only the status is kept.
      throw new ProviderError(
        'PROVIDER_REJECTED',
        `${this.id} returned ${response.status}`,
      );
    }

    let payload: {
      candidates?: Array<{ content?: { parts?: InlineDataPart[] } }>;
    };
    try {
      payload = await response.json();
    } catch (_error) {
      throw new ProviderError(
        'PROVIDER_BAD_RESPONSE',
        `${this.id} returned unreadable JSON`,
        true,
      );
    }

    const part = payload.candidates?.[0]?.content?.parts
      ?.find((candidate) => candidate.inlineData?.data);
    const encoded = part?.inlineData?.data;
    if (!encoded) {
      // A refusal or a safety block arrives as a well-formed response with no
      // audio in it, which is a rejection rather than an outage.
      throw new ProviderError(
        'PROVIDER_EMPTY_RESPONSE',
        `${this.id} returned no audio`,
      );
    }

    const pcm = decodeBase64(encoded, this.id);
    const sampleRate = sampleRateFrom(part?.inlineData?.mimeType);
    const bytes = wavFromPcm16(pcm, sampleRate);
    if (bytes.byteLength > maxAssetBytes) {
      throw new ProviderError(
        'PROVIDER_RESPONSE_TOO_LARGE',
        `${this.id} returned ${bytes.byteLength} bytes`,
      );
    }

    return {
      bytes,
      contentType: 'audio/wav',
      extension: 'wav',
      // Gemini bills speech by tokens, and the response does not price itself, so
      // the only honest figure available here is an operator's estimate. Left at
      // zero the request ceiling is still the effective daily limit (MED-02).
      costMicros: estimatedCostMicros(request.prompt),
    };
  }
}

export function geminiVoiceAdapter(): GeminiVoiceAdapter {
  return new GeminiVoiceAdapter();
}

function estimatedCostMicros(prompt: string): number {
  const perThousand = Number(
    Deno.env.get('VOICE_PROVIDER_COST_MICROS_PER_1K_CHARS') ?? '0',
  );
  if (!Number.isFinite(perThousand) || perThousand <= 0) return 0;
  return Math.ceil((prompt.length / 1000) * perThousand);
}

function decodeBase64(value: string, providerId: string): Uint8Array {
  try {
    const binary = atob(value);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index++) {
      bytes[index] = binary.charCodeAt(index);
    }
    if (bytes.byteLength === 0) {
      throw new Error('empty');
    }
    return bytes;
  } catch (_error) {
    throw new ProviderError(
      'PROVIDER_BAD_RESPONSE',
      `${providerId} returned audio that could not be decoded`,
      true,
    );
  }
}

/// The rate arrives as `audio/L16;codec=pcm;rate=24000`. Guessing wrong makes the
/// voice sound too fast or too slow, so the header is read rather than assumed.
export function sampleRateFrom(mimeType: string | undefined): number {
  const match = /rate=(\d+)/.exec(mimeType ?? '');
  const parsed = match ? Number(match[1]) : NaN;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 24000;
}

/// Wrap mono signed 16-bit PCM in a 44-byte RIFF/WAVE header.
export function wavFromPcm16(
  pcm: Uint8Array,
  sampleRate: number,
  channels = 1,
): Uint8Array {
  const bitsPerSample = 16;
  const blockAlign = (channels * bitsPerSample) / 8;
  const out = new Uint8Array(44 + pcm.byteLength);
  const view = new DataView(out.buffer);

  writeAscii(out, 0, 'RIFF');
  view.setUint32(4, 36 + pcm.byteLength, true);
  writeAscii(out, 8, 'WAVE');
  writeAscii(out, 12, 'fmt ');
  view.setUint32(16, 16, true); // PCM header length
  view.setUint16(20, 1, true); // format 1 = uncompressed PCM
  view.setUint16(22, channels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * blockAlign, true); // bytes per second
  view.setUint16(32, blockAlign, true);
  view.setUint16(34, bitsPerSample, true);
  writeAscii(out, 36, 'data');
  view.setUint32(40, pcm.byteLength, true);
  out.set(pcm, 44);
  return out;
}

function writeAscii(target: Uint8Array, offset: number, value: string): void {
  for (let index = 0; index < value.length; index++) {
    target[offset + index] = value.charCodeAt(index);
  }
}
