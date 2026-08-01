// MED-03 adapter checks. NOT RUN in this module: no Deno runtime is installed on
// the development machine and the function has never been deployed. Written now so
// the day a runtime exists, `deno test --allow-env` covers the parts that would
// otherwise only be discovered by a child hearing something wrong.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1';

import { GeminiVoiceAdapter, sampleRateFrom, wavFromPcm16 } from './gemini_voice.ts';
import { ProviderError } from './types.ts';

const request = {
  kind: 'voice' as const,
  slot: 'narration_idle-1',
  prompt: 'Take your time.',
  locale: 'en',
  aspectRatio: '1:1',
  promptHash: 'abc123',
  voiceName: 'Aoede',
};

function pcm(...samples: number[]): Uint8Array {
  const bytes = new Uint8Array(samples.length * 2);
  const view = new DataView(bytes.buffer);
  samples.forEach((sample, index) => view.setInt16(index * 2, sample, true));
  return bytes;
}

function audioResponse(bytes: Uint8Array, mimeType = 'audio/L16;codec=pcm;rate=24000') {
  let binary = '';
  bytes.forEach((byte) => binary += String.fromCharCode(byte));
  return new Response(
    JSON.stringify({
      candidates: [{
        content: { parts: [{ inlineData: { mimeType, data: btoa(binary) } }] },
      }],
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
}

Deno.test('a WAV header describes the audio that follows it', () => {
  const samples = pcm(0, 1000, -1000, 32767);
  const wav = wavFromPcm16(samples, 24000);
  const view = new DataView(wav.buffer);

  assertEquals(new TextDecoder().decode(wav.subarray(0, 4)), 'RIFF');
  assertEquals(new TextDecoder().decode(wav.subarray(8, 12)), 'WAVE');
  assertEquals(view.getUint32(4, true), 36 + samples.byteLength);
  assertEquals(view.getUint16(20, true), 1); // uncompressed PCM
  assertEquals(view.getUint16(22, true), 1); // mono
  assertEquals(view.getUint32(24, true), 24000);
  assertEquals(view.getUint32(28, true), 48000); // 24 kHz × 2 bytes
  assertEquals(view.getUint16(34, true), 16);
  assertEquals(view.getUint32(40, true), samples.byteLength);
  // The samples are copied through untouched: a header is all that was added.
  assertEquals(wav.subarray(44), samples);
});

Deno.test('the sample rate is read, not assumed', () => {
  assertEquals(sampleRateFrom('audio/L16;codec=pcm;rate=16000'), 16000);
  // A missing or unparseable rate falls back to the documented default rather
  // than to zero, which would make a file no player can open.
  assertEquals(sampleRateFrom('audio/L16'), 24000);
  assertEquals(sampleRateFrom(undefined), 24000);
});

Deno.test('no key means no recording, and no retry', async () => {
  Deno.env.delete('VOICE_PROVIDER_API_KEY');
  const error = await assertRejects(
    () => new GeminiVoiceAdapter().generate(request),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
  assertEquals(error.retryable, false);
});

Deno.test('a voice is never guessed', async () => {
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () => new GeminiVoiceAdapter().generate({ ...request, voiceName: '' }),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
});

Deno.test('the line is sent alone, in the registered voice', async () => {
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  let seen: { url: string; body: Record<string, unknown>; key: string | null } | null =
    null;

  const generated = await new GeminiVoiceAdapter().generate(
    { ...request, locale: 'ur' },
    (url, init) => {
      seen = {
        url: String(url),
        body: JSON.parse(String(init?.body)),
        key: new Headers(init?.headers).get('x-goog-api-key'),
      };
      return Promise.resolve(audioResponse(pcm(1, 2, 3)));
    },
  );

  const call = seen!;
  const config = (call.body.generationConfig as Record<string, any>);
  assertEquals(call.key, 'test-key');
  // A key in a query string ends up in logs; this one is a header.
  assertEquals(call.url.includes('test-key'), false);
  assertEquals(config.responseModalities, ['AUDIO']);
  assertEquals(config.speechConfig.voiceConfig.prebuiltVoiceConfig.voiceName, 'Aoede');
  assertEquals(config.speechConfig.languageCode, 'ur-PK');
  // Only the line itself: a style instruction risks being read aloud.
  assertEquals(
    (call.body.contents as any)[0].parts[0].text,
    'Take your time.',
  );

  assertEquals(generated.contentType, 'audio/wav');
  assertEquals(generated.extension, 'wav');
  assertEquals(generated.bytes.byteLength, 44 + 6);
});

Deno.test('a busy or broken provider is retryable; a refusal is not', async () => {
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const adapter = new GeminiVoiceAdapter();

  for (const status of [429, 500, 503]) {
    const error = await assertRejects(
      () => adapter.generate(request, () => Promise.resolve(new Response('', { status }))),
      ProviderError,
    );
    assertEquals(error.retryable, true, `status ${status}`);
  }

  const rejected = await assertRejects(
    () => adapter.generate(request, () => Promise.resolve(new Response('', { status: 400 }))),
    ProviderError,
  );
  assertEquals(rejected.code, 'PROVIDER_REJECTED');
  assertEquals(rejected.retryable, false);
});

Deno.test('a safety block arrives as a well-formed response with no audio', async () => {
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new GeminiVoiceAdapter().generate(
        request,
        () =>
          Promise.resolve(
            new Response(JSON.stringify({ candidates: [{ finishReason: 'SAFETY' }] }), {
              status: 200,
              headers: { 'Content-Type': 'application/json' },
            }),
          ),
      ),
    ProviderError,
  );
  // Not retryable: asking again for the same words gets the same answer.
  assertEquals(error.code, 'PROVIDER_EMPTY_RESPONSE');
  assertEquals(error.retryable, false);
});
