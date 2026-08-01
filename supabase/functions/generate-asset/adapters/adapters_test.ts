// Adapter tests (MED-01). Run with `deno test --allow-env` once a Deno toolchain
// is available; see docs/modules/MED-01/TEST_REPORT.md for why they are recorded
// as NOT RUN in this environment.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1';

import { configuredVoiceAdapter } from './configured_provider.ts';
import { PollinationsImageAdapter } from './pollinations_image.ts';
import { adapterFor } from './registry.ts';
import { dimensionsFor, ProviderError, seedFrom } from './types.ts';

const request = {
  kind: 'image' as const,
  slot: 'guide_greeting_staticArt',
  prompt: 'a friendly round companion waving',
  locale: 'en',
  aspectRatio: '16:9',
  promptHash: 'a1b2c3d4e5f6',
};

Deno.test('aspect ratio maps to dimensions, and nonsense falls back to square', () => {
  assertEquals(dimensionsFor('1:1'), { width: 768, height: 768 });
  assertEquals(dimensionsFor('16:9'), { width: 768, height: 432 });
  assertEquals(dimensionsFor('9:16'), { width: 432, height: 768 });
  assertEquals(dimensionsFor('nonsense'), { width: 768, height: 768 });
  assertEquals(dimensionsFor('0:0'), { width: 768, height: 768 });
});

Deno.test('the seed comes from the request, so a regeneration repeats', () => {
  assertEquals(seedFrom(request.promptHash), seedFrom(request.promptHash));
});

Deno.test('the image adapter sends the prompt, size, and seed', async () => {
  let seen: URL | null = null;
  const adapter = new PollinationsImageAdapter();
  const result = await adapter.generate(request, (input) => {
    seen = new URL(String(input));
    return Promise.resolve(
      new Response(new Uint8Array([1, 2, 3]), {
        headers: { 'content-type': 'image/png' },
      }),
    );
  });

  assertEquals(seen!.searchParams.get('width'), '768');
  assertEquals(seen!.searchParams.get('height'), '432');
  assertEquals(
    seen!.searchParams.get('seed'),
    String(seedFrom(request.promptHash)),
  );
  assertEquals(decodeURIComponent(seen!.pathname).endsWith(request.prompt), true);
  assertEquals(result.contentType, 'image/png');
  assertEquals(result.extension, 'png');
  assertEquals(result.costMicros, 0);
});

Deno.test('a provider error carries a code, not provider prose', async () => {
  const adapter = new PollinationsImageAdapter();
  const error = await assertRejects(
    () => adapter.generate(request, () => Promise.resolve(new Response('no', { status: 503 }))),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNAVAILABLE');
  assertEquals(error.retryable, true);
});

Deno.test('an empty response is a failure, not an empty file', async () => {
  const adapter = new PollinationsImageAdapter();
  const error = await assertRejects(
    () => adapter.generate(request, () => Promise.resolve(new Response(new Uint8Array()))),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_EMPTY_RESPONSE');
});

Deno.test('a missing key is an unconfigured provider, not a crash', async () => {
  Deno.env.delete('VOICE_PROVIDER_API_KEY');
  Deno.env.delete('VOICE_PROVIDER_URL');
  const error = await assertRejects(
    () =>
      configuredVoiceAdapter().generate(
        { ...request, kind: 'voice' },
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
});

Deno.test('the registry refuses an unknown provider and a wrong kind', () => {
  assertEquals(adapterFor('pollinations_image', 'image').id, 'pollinations_image');
  try {
    adapterFor('nope', 'image');
    throw new Error('FAIL: unknown provider accepted');
  } catch (error) {
    assertEquals((error as ProviderError).code, 'ADAPTER_MISSING');
  }
  try {
    adapterFor('configured_voice', 'image');
    throw new Error('FAIL: wrong kind accepted');
  } catch (error) {
    assertEquals((error as ProviderError).code, 'ADAPTER_KIND_MISMATCH');
  }
});
