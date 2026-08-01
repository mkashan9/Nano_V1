// MED-07 Wan image-to-video adapter checks.
//
// Run with `deno test --allow-env supabase/functions/generate-asset/adapters/`.
// See docs/modules/MED-07/TEST_REPORT.md for whether that command has actually
// been run on this machine.
//
// Most of these encode something that was measured against the live Space
// rather than something read in a document, because the published schema and
// the Space disagree in at least one place that costs an hour to find.

import { assertEquals, assertRejects, assertStringIncludes } from 'jsr:@std/assert@1';

import { adapterFor } from './registry.ts';
import { ProviderError } from './types.ts';
import { readEventStream, WanI2VSpaceAdapter } from './wan_i2v_space.ts';

const sourceUrl =
  'https://project.supabase.co/storage/v1/object/sign/generated-assets/x?token=t';

const request = {
  kind: 'video' as const,
  slot: 'guide_greeting_shortClip',
  prompt: 'A small round friendly companion waves hello.',
  locale: 'en',
  aspectRatio: '1:1',
  promptHash: 'a1b2c3d4',
  durationSeconds: 3,
  sourceImageUrl: sourceUrl,
  motion: 'driftIn',
};

const fakeJpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a]);
const fakeMp4 = new Uint8Array([
  0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d,
]);

function sse(frames: string[]): Response {
  return new Response(
    new ReadableStream({
      start(controller) {
        for (const frame of frames) {
          controller.enqueue(new TextEncoder().encode(`${frame}\n\n`));
        }
        controller.close();
      },
    }),
    { headers: { 'Content-Type': 'text/event-stream' } },
  );
}

const completeFrame = 'event: complete\ndata: ' + JSON.stringify([
  { path: '/tmp/gradio/abc/out.mp4', url: 'https://space.hf.space/gradio_api/file=/tmp/gradio/abc/out.mp4' },
  { path: '/tmp/gradio/abc/out.mp4', url: 'https://space.hf.space/gradio_api/file=/tmp/gradio/abc/out.mp4', size: 193088 },
  42,
]);

/// A fetch that plays the whole happy path and records what it was asked.
function happyFetch(seen: { calls: string[]; payload?: any }) {
  return (url: string | URL | Request, init?: RequestInit): Promise<Response> => {
    const href = String(url);
    seen.calls.push(href);

    if (href === sourceUrl) {
      return Promise.resolve(new Response(fakeJpeg));
    }
    if (href.endsWith('/gradio_api/upload')) {
      return Promise.resolve(
        new Response(JSON.stringify(['/tmp/gradio/xyz/companion.jpg']), {
          headers: { 'Content-Type': 'application/json' },
        }),
      );
    }
    if (href.endsWith('/gradio_api/call/generate_video')) {
      seen.payload = JSON.parse(String(init?.body));
      return Promise.resolve(
        new Response(JSON.stringify({ event_id: 'evt-1' }), {
          headers: { 'Content-Type': 'application/json' },
        }),
      );
    }
    if (href.includes('/gradio_api/call/generate_video/evt-1')) {
      return Promise.resolve(sse(['event: heartbeat\ndata: null', completeFrame]));
    }
    if (href.includes('gradio_api/file=')) {
      return Promise.resolve(new Response(fakeMp4));
    }
    return Promise.reject(new Error(`unexpected call to ${href}`));
  };
}

function reset(): void {
  Deno.env.delete('VIDEO_SPACE_URL');
  Deno.env.delete('VIDEO_SPACE_DEADLINE_SECONDS');
}

Deno.test('a clip is uploaded, rendered, and downloaded', async () => {
  reset();
  const seen = { calls: [] as string[], payload: undefined as any };
  const bytes = await new WanI2VSpaceAdapter().generate(request, happyFetch(seen));

  assertEquals(bytes.contentType, 'video/mp4');
  assertEquals(bytes.extension, 'mp4');
  assertEquals(bytes.providerReference, 'evt-1');
  // A public Space bills nothing, and pretending otherwise would make MED-02's
  // budget refuse clips that cost no money.
  assertEquals(bytes.costMicros, 0);

  // The picture is uploaded before it is referenced. The Space will not fetch
  // a URL, which was measured.
  const upload = seen.calls.findIndex((c) => c.endsWith('/gradio_api/upload'));
  const call = seen.calls.findIndex((c) => c.endsWith('/gradio_api/call/generate_video'));
  assertEquals(upload < call, true);
});

Deno.test('frame_multiplier goes as a number, not the published string', async () => {
  reset();
  const seen = { calls: [] as string[], payload: undefined as any };
  await new WanI2VSpaceAdapter().generate(request, happyFetch(seen));

  // Position 13. The Space publishes this as a string and then rejects strings
  // against the choices [16,32,64,128], answering with a bare `event: error`
  // and no message. Regressing this costs an hour to rediscover.
  assertEquals(seen.payload.data[13], 16);
  assertEquals(typeof seen.payload.data[13], 'number');
});

Deno.test('the ask describes the character moving, and forbids it deforming', async () => {
  reset();
  const seen = { calls: [] as string[], payload: undefined as any };
  await new WanI2VSpaceAdapter().generate(request, happyFetch(seen));

  const prompt = String(seen.payload.data[2]);
  const negative = String(seen.payload.data[4]);

  // driftIn used to mean a camera drifting in. It now means Nori waving, which
  // is the entire reason this module exists.
  assertStringIncludes(prompt, 'waves hello');
  assertStringIncludes(prompt, 'no camera movement');
  // An i2v model can grow a limb on a mascot. The review gate is the real
  // control, but the ask should not invite it.
  assertStringIncludes(negative, 'extra limbs');
  assertStringIncludes(negative, 'off model');
});

Deno.test('the same ask yields the same clip', async () => {
  reset();
  const first = { calls: [] as string[], payload: undefined as any };
  const second = { calls: [] as string[], payload: undefined as any };
  await new WanI2VSpaceAdapter().generate(request, happyFetch(first));
  await new WanI2VSpaceAdapter().generate(request, happyFetch(second));

  assertEquals(first.payload.data[8], second.payload.data[8]);
  // randomize_seed stays off, or the seed above would be decoration.
  assertEquals(first.payload.data[9], false);
});

Deno.test('no approved art means no call to the Space', async () => {
  reset();
  const error = await assertRejects(
    () =>
      new WanI2VSpaceAdapter().generate(
        { ...request, sourceImageUrl: undefined },
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_NO_SOURCE_ART');
  // Not retryable, and deliberately not in the fallback set: a missing picture
  // is the compose gate working, not a provider having a bad day.
  assertEquals(error.retryable, false);
});

Deno.test('an unauthored motion is refused rather than invented', async () => {
  reset();
  const error = await assertRejects(
    () =>
      new WanI2VSpaceAdapter().generate(
        { ...request, motion: 'backflip' },
        () => Promise.reject(new Error('must not be called')),
      ),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNKNOWN_MOTION');
});

Deno.test('a bare error event is retryable, so the composer can cover', async () => {
  reset();
  const error = await assertRejects(
    () =>
      new WanI2VSpaceAdapter().generate(request, (url) => {
        const href = String(url);
        if (href === sourceUrl) return Promise.resolve(new Response(fakeJpeg));
        if (href.endsWith('/upload')) {
          return Promise.resolve(new Response(JSON.stringify(['/tmp/a.jpg'])));
        }
        if (href.endsWith('/generate_video')) {
          return Promise.resolve(new Response(JSON.stringify({ event_id: 'evt-1' })));
        }
        return Promise.resolve(sse(['event: error\ndata: null']));
      }),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_REJECTED');
  assertEquals(error.retryable, true);
});

Deno.test('a Space that is asleep is retryable', async () => {
  reset();
  const error = await assertRejects(
    () =>
      new WanI2VSpaceAdapter().generate(request, (url) => {
        if (String(url) === sourceUrl) return Promise.resolve(new Response(fakeJpeg));
        return Promise.resolve(new Response('starting', { status: 503 }));
      }),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNAVAILABLE');
  assertEquals(error.retryable, true);
});

Deno.test('a stream that stops without finishing does not become a clip', async () => {
  const error = await assertRejects(
    () => readEventStream(sse(['event: heartbeat\ndata: null']).body!, 'wan_i2v_space'),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_UNEXPECTED_RESPONSE');
  assertEquals(error.retryable, true);
});

Deno.test('completing with no file is a failure, not an empty clip', async () => {
  const frame = 'event: complete\ndata: ' + JSON.stringify([null, null, 42]);
  const error = await assertRejects(
    () => readEventStream(sse([frame]).body!, 'wan_i2v_space'),
    ProviderError,
  );
  assertEquals(error.code, 'PROVIDER_EMPTY_RESPONSE');
});

Deno.test('a frame split across reads is still understood', async () => {
  const half = completeFrame.slice(0, 40);
  const rest = completeFrame.slice(40);
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      const encode = (s: string) => controller.enqueue(new TextEncoder().encode(s));
      encode('event: heartbeat\ndata: null\n\n');
      encode(half);
      encode(rest + '\n\n');
      controller.close();
    },
  });

  const video = await readEventStream(body, 'wan_i2v_space');
  assertStringIncludes(String(video.url), 'out.mp4');
});

Deno.test('the adapter never claims a job it cannot come back to', () => {
  const adapter = adapterFor('wan_i2v_space', 'video');
  assertEquals(adapter.id, 'wan_i2v_space');
  // Measured against the live Space: disconnecting kills the render and
  // reconnecting to the event id answers `error`. Offering generateOrPending
  // would record a provider_job_id that can never be collected.
  assertEquals(adapter.generateOrPending, undefined);
});

Deno.test('the composer is still registered, because it is the fallback', () => {
  assertEquals(adapterFor('json2video_compose', 'video').id, 'json2video_compose');
});
