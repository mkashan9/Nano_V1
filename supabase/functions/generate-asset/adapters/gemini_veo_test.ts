// MED-04 adapter checks. NOT RUN in this module: no Deno runtime is installed on
// the development machine and the function has never been deployed. Written now
// so that `deno test --allow-env` covers the parts that would otherwise only be
// discovered by a clip that is paid for twice, or by a job nobody collects.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1';

import { GeminiVeoAdapter } from './gemini_veo.ts';
import { adapterFor } from './registry.ts';
import { ProviderError } from './types.ts';

const request = {
  kind: 'video' as const,
  slot: 'celebration_celebration_shortClip',
  prompt: 'A small round friendly companion does a happy hop.',
  locale: 'en',
  aspectRatio: '9:16',
  promptHash: 'a1b2c3d4',
  durationSeconds: 4,
};

const jobName = 'models/veo-2.0-generate-001/operations/abc123';

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/// The first bytes of an MP4: an ftyp box. Enough to prove the download is
/// carried through untouched.
const fakeMp4 = new Uint8Array([
  0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d,
]);

Deno.test('no key means no clip, and no retry', async () => {
  Deno.env.delete('VIDEO_PROVIDER_API_KEY');
  const error = await assertRejects(
    () =>
      new GeminiVeoAdapter().generateOrPending(
        request,
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
  assertEquals(error.retryable, false);
});

Deno.test('a request with no job submits one and asks to be called back', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  let seen: { url: string; body: Record<string, any>; key: string | null } | null = null;

  const outcome = await new GeminiVeoAdapter().generateOrPending(request, (url, init) => {
    seen = {
      url: String(url),
      body: JSON.parse(String(init?.body)),
      key: new Headers(init?.headers).get('x-goog-api-key'),
    };
    return Promise.resolve(json({ name: jobName }));
  });

  const call = seen!;
  assertEquals(call.key, 'test-key');
  // A key in a query string ends up in logs; this one is a header.
  assertEquals(call.url.includes('test-key'), false);
  assertEquals(call.url.endsWith(':predictLongRunning'), true);
  assertEquals(call.body.instances[0].prompt, request.prompt);
  // Shape and length are the authored ones, not the adapter's opinion.
  assertEquals(call.body.parameters.aspectRatio, '9:16');
  assertEquals(call.body.parameters.durationSeconds, 4);
  assertEquals(call.body.parameters.personGeneration, 'dont_allow');

  assertEquals(outcome.status, 'pending');
  if (outcome.status !== 'pending') return;
  assertEquals(outcome.providerJobId, jobName);
  assertEquals(outcome.pollAfterSeconds > 0, true);
});

Deno.test('a duration nobody authored falls back rather than being sent empty', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  let body: Record<string, any> = {};

  await new GeminiVeoAdapter().generateOrPending(
    { ...request, durationSeconds: undefined },
    (_url, init) => {
      body = JSON.parse(String(init?.body));
      return Promise.resolve(json({ name: jobName }));
    },
  );

  assertEquals(body.parameters.durationSeconds, 4);
});

Deno.test('a job that is still running is polled, never restarted', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const calls: Array<{ url: string; method: string }> = [];

  const outcome = await new GeminiVeoAdapter().generateOrPending(
    { ...request, providerJobId: jobName },
    (url, init) => {
      calls.push({ url: String(url), method: init?.method ?? 'GET' });
      return Promise.resolve(json({ name: jobName, done: false }));
    },
  );

  // The whole point of the job id: one submit, however many invocations.
  assertEquals(calls.length, 1);
  assertEquals(calls[0].method, 'GET');
  assertEquals(calls[0].url.endsWith(jobName), true);
  assertEquals(outcome.status, 'pending');
  if (outcome.status !== 'pending') return;
  assertEquals(outcome.providerJobId, jobName);
});

Deno.test('a finished job is downloaded and handed over as an mp4', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  Deno.env.set('VIDEO_COST_MICROS_PER_CLIP', '12345');
  const downloadUri = 'https://generativelanguage.googleapis.com/v1beta/files/f:download';
  const seen: string[] = [];

  const outcome = await new GeminiVeoAdapter().generateOrPending(
    { ...request, providerJobId: jobName },
    (url) => {
      seen.push(String(url));
      if (String(url) === downloadUri) {
        return Promise.resolve(
          new Response(fakeMp4, { headers: { 'content-type': 'video/mp4' } }),
        );
      }
      return Promise.resolve(json({
        name: jobName,
        done: true,
        response: {
          generateVideoResponse: {
            generatedSamples: [{ video: { uri: downloadUri } }],
          },
        },
      }));
    },
  );

  assertEquals(seen.length, 2);
  assertEquals(outcome.status, 'ready');
  if (outcome.status !== 'ready') return;
  assertEquals(outcome.bytes.contentType, 'video/mp4');
  assertEquals(outcome.bytes.extension, 'mp4');
  assertEquals(outcome.bytes.bytes, fakeMp4);
  // The job survives into provenance, so a stored clip can be traced back.
  assertEquals(outcome.bytes.providerReference, jobName);
  assertEquals(outcome.bytes.costMicros, 12345);
  Deno.env.delete('VIDEO_COST_MICROS_PER_CLIP');
});

Deno.test('a clip is charged even when nobody configured a price', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  Deno.env.delete('VIDEO_COST_MICROS_PER_CLIP');
  const downloadUri = 'https://example.test/clip.mp4';

  const outcome = await new GeminiVeoAdapter().generateOrPending(
    { ...request, providerJobId: jobName },
    (url) =>
      Promise.resolve(
        String(url) === downloadUri ? new Response(fakeMp4) : json({
          name: jobName,
          done: true,
          response: { generatedVideos: [{ video: { uri: downloadUri } }] },
        }),
      ),
  );

  assertEquals(outcome.status, 'ready');
  if (outcome.status !== 'ready') return;
  // Video is the expensive kind: a cost budget that reads zero never bites.
  assertEquals(outcome.bytes.costMicros > 0, true);
});

Deno.test('a busy provider is retryable; a refusal is not', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const adapter = new GeminiVeoAdapter();

  for (const status of [429, 500, 503]) {
    const error = await assertRejects(
      () =>
        adapter.generateOrPending(
          request,
          () => Promise.resolve(new Response('', { status })),
        ),
      ProviderError,
    );
    assertEquals(error.retryable, true, `status ${status}`);
  }

  const rejected = await assertRejects(
    () =>
      adapter.generateOrPending(
        request,
        () => Promise.resolve(new Response('', { status: 400 })),
      ),
    ProviderError,
  );
  assertEquals(rejected.code, 'PROVIDER_REJECTED');
  assertEquals(rejected.retryable, false);
});

Deno.test('an unreachable provider is not a crash', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new GeminiVeoAdapter().generateOrPending(
        request,
        () => Promise.reject(new TypeError('network')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNREACHABLE');
  assertEquals(error.retryable, true);
});

Deno.test('a job that finished with nothing in it is a failure, not an empty file', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new GeminiVeoAdapter().generateOrPending(
        { ...request, providerJobId: jobName },
        () => Promise.resolve(json({ name: jobName, done: true, response: {} })),
      ),
    ProviderError,
  );
  // A safety filter finishes the job and returns no sample.
  assertEquals(error.code, 'PROVIDER_EMPTY');
});

Deno.test('a job the provider failed carries no provider prose', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new GeminiVeoAdapter().generateOrPending(
        { ...request, providerJobId: jobName },
        () =>
          Promise.resolve(json({
            name: jobName,
            done: true,
            error: { code: 3, message: 'the direction said something disallowed' },
          })),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_REJECTED');
  assertEquals(error.message.includes('disallowed'), false);
});

Deno.test('a clip too big for the bucket is refused before it is read', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const downloadUri = 'https://example.test/huge.mp4';

  const error = await assertRejects(
    () =>
      new GeminiVeoAdapter().generateOrPending(
        { ...request, providerJobId: jobName },
        (url) =>
          Promise.resolve(
            String(url) === downloadUri
              ? new Response(fakeMp4, {
                headers: { 'content-length': String(64 * 1024 * 1024) },
              })
              : json({
                name: jobName,
                done: true,
                response: {
                  generateVideoResponse: {
                    generatedSamples: [{ video: { uri: downloadUri } }],
                  },
                },
              }),
          ),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_TOO_LARGE');
});

Deno.test('the synchronous contract refuses rather than blocking for minutes', async () => {
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () => new GeminiVeoAdapter().generate(request, () => Promise.resolve(json({ name: jobName }))),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_PENDING');
  assertEquals(error.retryable, true);
});

Deno.test('the clip provider id resolves to the asynchronous adapter', () => {
  const adapter = adapterFor('gemini_veo_video', 'video');
  assertEquals(adapter.id, 'gemini_veo_video');
  assertEquals(typeof adapter.generateOrPending, 'function');
  // The MED-01 stub is still reachable under its own id.
  assertEquals(adapterFor('configured_video', 'video').id, 'configured_video');
});
