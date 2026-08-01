// MED-06 Fish Audio adapter checks.
//
// Run with `deno test --allow-env supabase/functions/generate-asset/adapters/`.
// See docs/modules/MED-06/TEST_REPORT.md for whether that command has actually
// been run on this machine.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1';

import { FishAudioVoiceAdapter } from './fish_audio_voice.ts';
import { adapterFor } from './registry.ts';
import { ProviderError } from './types.ts';

const request = {
  kind: 'voice' as const,
  slot: 'guide_greeting_staticArt',
  prompt: 'Assalam o alaikum. Ready when you are.',
  locale: 'en',
  aspectRatio: '1:1',
  promptHash: 'a1b2c3d4',
  voiceName: 'stock',
};

/// The first bytes of an MP3 frame. Enough to prove the body is carried through
/// untouched rather than re-encoded or wrapped.
const fakeMp3 = new Uint8Array([0xff, 0xfb, 0x90, 0x64, 0x00, 0x00]);

function audio(bytes = fakeMp3, status = 200): Response {
  return new Response(bytes, { status, headers: { 'Content-Type': 'audio/mpeg' } });
}

function reset(): void {
  Deno.env.delete('VOICE_PROVIDER_URL');
  Deno.env.delete('VOICE_PROVIDER_MODEL');
  Deno.env.delete('VOICE_PROVIDER_COST_MICROS_PER_1K_CHARS');
}

Deno.test('no key means no recording, and no retry', async () => {
  reset();
  Deno.env.delete('VOICE_PROVIDER_API_KEY');
  const error = await assertRejects(
    () =>
      new FishAudioVoiceAdapter().generate(
        request,
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  // Every line already has a caption, so this is a settled answer rather than
  // something to keep asking about.
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
  assertEquals(error.retryable, false);
});

Deno.test('the line is sent as mp3 with the key in a header', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  let seen: { url: string; body: Record<string, any>; headers: Headers } | null = null;

  const generated = await new FishAudioVoiceAdapter().generate(request, (url, init) => {
    seen = {
      url: String(url),
      body: JSON.parse(String(init?.body)),
      headers: new Headers(init?.headers),
    };
    return Promise.resolve(audio());
  });

  const call = seen!;
  assertEquals(call.url, 'https://api.fish.audio/v1/tts');
  // A key in a query string ends up in logs; this one is a bearer header.
  assertEquals(call.url.includes('test-key'), false);
  assertEquals(call.headers.get('Authorization'), 'Bearer test-key');
  // Fish takes the model as a header and refuses without it.
  assertEquals(call.headers.get('model'), 's2.1-pro-free');
  assertEquals(call.body.text, request.prompt);
  assertEquals(call.body.format, 'mp3');

  assertEquals(generated.contentType, 'audio/mpeg');
  assertEquals(generated.extension, 'mp3');
  assertEquals(generated.bytes, fakeMp3);
});

Deno.test('the stock voice sends no reference, a chosen voice sends one', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const adapter = new FishAudioVoiceAdapter();
  let body: Record<string, any> = {};
  const capture = (_url: string | URL | Request, init?: RequestInit) => {
    body = JSON.parse(String(init?.body));
    return Promise.resolve(audio());
  };

  await adapter.generate(request, capture);
  // Absent, not empty: Fish reads an empty reference_id as a reference to
  // nothing rather than as "your default voice".
  assertEquals('reference_id' in body, false);

  await adapter.generate({ ...request, voiceName: 'b1a2c3d4e5' }, capture);
  assertEquals(body.reference_id, 'b1a2c3d4e5');
});

Deno.test('an unresolved voice is refused rather than guessed', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new FishAudioVoiceAdapter().generate(
        { ...request, voiceName: undefined },
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  // Recording in whichever voice the account defaults to would pass every check
  // and sound wrong to a child.
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
});

Deno.test('the model and the host are configuration, not code', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  Deno.env.set('VOICE_PROVIDER_URL', 'https://fish.internal/');
  Deno.env.set('VOICE_PROVIDER_MODEL', 's2-pro');
  let seen = { url: '', model: '' };

  await new FishAudioVoiceAdapter().generate(request, (url, init) => {
    seen = { url: String(url), model: new Headers(init?.headers).get('model') ?? '' };
    return Promise.resolve(audio());
  });

  // The trailing slash is the kind of thing that produces a double slash and a
  // 404 six months later.
  assertEquals(seen.url, 'https://fish.internal/v1/tts');
  assertEquals(seen.model, 's2-pro');
  reset();
});

Deno.test('a recording is charged even when nobody configured a price', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');

  const generated = await new FishAudioVoiceAdapter().generate(
    request,
    () => Promise.resolve(audio()),
  );

  // A cost budget that reads zero for every recording never stops anything.
  assertEquals(generated.costMicros > 0, true);
});

Deno.test('urdu is billed by bytes, the way the provider counts it', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  Deno.env.set('VOICE_PROVIDER_COST_MICROS_PER_1K_CHARS', '15000');
  const adapter = new FishAudioVoiceAdapter();
  const respond = () => Promise.resolve(audio());

  const english = await adapter.generate({ ...request, prompt: 'Well done!' }, respond);
  const urdu = await adapter.generate(
    { ...request, locale: 'ur', prompt: 'بہت خوب!' },
    respond,
  );

  // Eight Urdu characters are far more than eight bytes. Counting characters
  // would under-bill Urdu against a budget that exists to stop surprises.
  assertEquals(urdu.costMicros > english.costMicros, true);
  reset();
});

Deno.test('an empty balance says so instead of looking like a bad request', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new FishAudioVoiceAdapter().generate(
        request,
        () => Promise.resolve(new Response('{"status":402}', { status: 402 })),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_OUT_OF_CREDIT');
});

Deno.test('a busy provider is retryable; a refusal is not', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const adapter = new FishAudioVoiceAdapter();

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

Deno.test('a rejection never echoes the line back into a log', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new FishAudioVoiceAdapter().generate(
        { ...request, prompt: 'Shabash, you finished the whole set.' },
        () =>
          Promise.resolve(
            new Response(
              JSON.stringify({ message: 'rejected: Shabash, you finished the whole set.' }),
              { status: 400 },
            ),
          ),
      ),
    ProviderError,
  );
  assertEquals(error.message.includes('Shabash'), false);
});

Deno.test('an unreachable provider is not a crash', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new FishAudioVoiceAdapter().generate(
        request,
        () => Promise.reject(new TypeError('network')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNREACHABLE');
  assertEquals(error.retryable, true);
});

Deno.test('a well-formed response with no audio in it is a failure', async () => {
  reset();
  Deno.env.set('VOICE_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new FishAudioVoiceAdapter().generate(
        request,
        () => Promise.resolve(new Response(new Uint8Array(), { status: 200 })),
      ),
    ProviderError,
  );
  // Storing a zero-byte MP3 as a ready recording would look like success and
  // play as silence.
  assertEquals(error.code, 'PROVIDER_EMPTY_RESPONSE');
});

Deno.test('the default voice provider id resolves to Fish', () => {
  const adapter = adapterFor('fish_audio_voice', 'voice');
  assertEquals(adapter.id, 'fish_audio_voice');
  assertEquals(adapter.kind, 'voice');
  // The adapters it replaced are still reachable by id, so a provider row that
  // is switched back does not also need a redeploy.
  assertEquals(adapterFor('gemini_voice_aoede', 'voice').id, 'gemini_voice_aoede');
});
