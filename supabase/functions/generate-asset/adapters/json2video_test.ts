// MED-06 json2video adapter checks.
//
// Run with `deno test --allow-env supabase/functions/generate-asset/adapters/`.
// See docs/modules/MED-06/TEST_REPORT.md for whether that command has actually
// been run on this machine.

import { assertEquals, assertRejects } from 'jsr:@std/assert@1';

import { Json2VideoComposeAdapter } from './json2video_compose.ts';
import { adapterFor } from './registry.ts';
import { ProviderError } from './types.ts';

const sourceUrl = 'https://project.supabase.co/storage/v1/object/sign/generated-assets/x?token=t';

const request = {
  kind: 'video' as const,
  slot: 'celebration_celebration_shortClip',
  prompt: 'A small round friendly companion does a happy hop.',
  locale: 'en',
  aspectRatio: '1:1',
  promptHash: 'a1b2c3d4',
  durationSeconds: 3,
  sourceImageUrl: sourceUrl,
  motion: 'pushIn',
};

const project = 'JkGxEoPRF9EgRb32';

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/// The first bytes of an MP4: an ftyp box.
const fakeMp4 = new Uint8Array([
  0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d,
]);

function reset(): void {
  Deno.env.delete('VIDEO_PROVIDER_URL');
  Deno.env.delete('VIDEO_COST_MICROS_PER_CLIP');
}

Deno.test('no key means no clip, and no retry', async () => {
  reset();
  Deno.env.delete('VIDEO_PROVIDER_API_KEY');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        request,
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNCONFIGURED');
  assertEquals(error.retryable, false);
});

Deno.test('a submission is a movie made of the approved picture', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  let seen: { url: string; body: Record<string, any>; key: string | null } | null = null;

  const outcome = await new Json2VideoComposeAdapter().generateOrPending(
    request,
    (url, init) => {
      seen = {
        url: String(url),
        body: JSON.parse(String(init?.body)),
        key: new Headers(init?.headers).get('x-api-key'),
      };
      return Promise.resolve(json({ success: true, project }));
    },
  );

  const call = seen!;
  assertEquals(call.url, 'https://api.json2video.com/v2/movies');
  assertEquals(call.key, 'test-key');
  // A key in a query string ends up in logs; this one is a header.
  assertEquals(call.url.includes('test-key'), false);

  const element = call.body.scenes[0].elements[0];
  // The whole point of the module: the clip is the approved art, not a
  // description of it. Nothing resembling the direction is sent at all.
  assertEquals(element.type, 'image');
  assertEquals(element.src, sourceUrl);
  assertEquals(JSON.stringify(call.body).includes('companion'), false);
  // The authored length, not the adapter's opinion.
  assertEquals(call.body.scenes[0].duration, 3);

  assertEquals(outcome.status, 'pending');
  if (outcome.status !== 'pending') return;
  assertEquals(outcome.providerJobId, project);
  assertEquals(outcome.pollAfterSeconds > 0, true);
});

Deno.test('each authored motion renders as a different movie', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const adapter = new Json2VideoComposeAdapter();
  const rendered: Record<string, string> = {};

  for (const motion of ['hold', 'settle', 'driftIn', 'pushIn', 'dip']) {
    await adapter.generateOrPending({ ...request, motion }, (_url, init) => {
      const body = JSON.parse(String(init?.body));
      rendered[motion] = JSON.stringify(body.scenes[0].elements[0]);
      return Promise.resolve(json({ success: true, project }));
    });
  }

  // Five names that all rendered the same thing would be five names for one
  // motion, and a curator would have no way to tell.
  assertEquals(new Set(Object.values(rendered)).size, 5);
  // The still one is still: a reaction authored as `hold` must not drift.
  assertEquals(JSON.parse(rendered.hold).zoom, 0);
  assertEquals('pan' in JSON.parse(rendered.hold), false);
});

Deno.test('a motion nobody has seen is refused, not improvised', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        { ...request, motion: 'backflip' },
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'COMPOSITION_MOTION_UNKNOWN');
});

Deno.test('no approved art means no render is even started', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        { ...request, sourceImageUrl: undefined },
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  // The database refuses this first. Reaching it means the worker and the
  // database disagree, which is worth failing loudly over.
  assertEquals(error.code, 'COMPOSITION_SOURCE_MISSING');
});

Deno.test('a render that is still going is polled, never resubmitted', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const calls: Array<{ url: string; method: string }> = [];

  const outcome = await new Json2VideoComposeAdapter().generateOrPending(
    { ...request, providerJobId: project },
    (url, init) => {
      calls.push({ url: String(url), method: init?.method ?? 'GET' });
      return Promise.resolve(json({ success: true, movie: { status: 'running' } }));
    },
  );

  // The whole point of the project id: one submit, however many invocations.
  assertEquals(calls.length, 1);
  assertEquals(calls[0].method, 'GET');
  assertEquals(calls[0].url.includes(`project=${project}`), true);
  assertEquals(outcome.status, 'pending');
});

Deno.test('a finished render is downloaded and handed over as an mp4', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  Deno.env.set('VIDEO_COST_MICROS_PER_CLIP', '12345');
  const movieUrl = 'https://assets.json2video.com/clients/x/renders/y.mp4';
  const seen: Array<{ url: string; key: string | null }> = [];

  const outcome = await new Json2VideoComposeAdapter().generateOrPending(
    { ...request, providerJobId: project },
    (url, init) => {
      seen.push({ url: String(url), key: new Headers(init?.headers).get('x-api-key') });
      return Promise.resolve(
        String(url) === movieUrl
          ? new Response(fakeMp4, { headers: { 'content-type': 'video/mp4' } })
          : json({ success: true, movie: { status: 'done', url: movieUrl } }),
      );
    },
  );

  assertEquals(seen.length, 2);
  // The rendered file is on a public CDN, so the key is deliberately not sent
  // to it.
  assertEquals(seen[1].key, null);
  assertEquals(outcome.status, 'ready');
  if (outcome.status !== 'ready') return;
  assertEquals(outcome.bytes.contentType, 'video/mp4');
  assertEquals(outcome.bytes.extension, 'mp4');
  assertEquals(outcome.bytes.bytes, fakeMp4);
  assertEquals(outcome.bytes.providerReference, project);
  assertEquals(outcome.bytes.costMicros, 12345);
  reset();
});

Deno.test('a clip is charged even when nobody configured a price', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const movieUrl = 'https://assets.json2video.com/clients/x/renders/y.mp4';

  const outcome = await new Json2VideoComposeAdapter().generateOrPending(
    { ...request, providerJobId: project },
    (url) =>
      Promise.resolve(
        String(url) === movieUrl
          ? new Response(fakeMp4)
          : json({ success: true, movie: { status: 'done', url: movieUrl } }),
      ),
  );

  assertEquals(outcome.status, 'ready');
  if (outcome.status !== 'ready') return;
  assertEquals(outcome.bytes.costMicros > 0, true);
});

Deno.test('a failed render carries no provider prose, and no signed link', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        { ...request, providerJobId: project },
        () =>
          Promise.resolve(json({
            success: true,
            movie: {
              status: 'error',
              message: `Failed to download element: HTTP 404 at ${sourceUrl}`,
            },
          })),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_REJECTED');
  // The provider quotes our own signed URL back at us; a log is not the place
  // for it.
  assertEquals(error.message.includes('token='), false);
});

Deno.test('a render the provider gave up on is fatal, not endlessly polled', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        { ...request, providerJobId: project },
        () => Promise.resolve(json({ success: true, movie: { status: 'timeout' } })),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_REJECTED');
  assertEquals(error.retryable, false);
});

Deno.test('a spent plan says so instead of looking like a bad request', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        request,
        () => Promise.resolve(new Response('{"success":false}', { status: 401 })),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_NOT_ENTITLED');
  assertEquals(error.retryable, false);
});

Deno.test('a busy provider is retryable; a refusal is not', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const adapter = new Json2VideoComposeAdapter();

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
});

Deno.test('an unreachable provider is not a crash', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        request,
        () => Promise.reject(new TypeError('network')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNREACHABLE');
  assertEquals(error.retryable, true);
});

Deno.test('a clip too big for the bucket is refused before it is read', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const movieUrl = 'https://assets.json2video.com/clients/x/renders/huge.mp4';

  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generateOrPending(
        { ...request, providerJobId: project },
        (url) =>
          Promise.resolve(
            String(url) === movieUrl
              ? new Response(fakeMp4, {
                headers: { 'content-length': String(64 * 1024 * 1024) },
              })
              : json({ success: true, movie: { status: 'done', url: movieUrl } }),
          ),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_TOO_LARGE');
});

Deno.test('the synchronous contract refuses rather than blocking for minutes', async () => {
  reset();
  Deno.env.set('VIDEO_PROVIDER_API_KEY', 'test-key');
  const error = await assertRejects(
    () =>
      new Json2VideoComposeAdapter().generate(
        request,
        () => Promise.resolve(json({ success: true, project })),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_PENDING');
  assertEquals(error.retryable, true);
});

Deno.test('the default clip provider id resolves to the compositor', () => {
  const adapter = adapterFor('json2video_compose', 'video');
  assertEquals(adapter.id, 'json2video_compose');
  assertEquals(typeof adapter.generateOrPending, 'function');
  // The generative adapter is still reachable by id, so a provider row that is
  // switched back does not also need a redeploy.
  assertEquals(adapterFor('gemini_veo_video', 'video').id, 'gemini_veo_video');
});
