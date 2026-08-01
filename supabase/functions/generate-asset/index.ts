import { createClient } from 'jsr:@supabase/supabase-js@2';

import {
  errorResponse,
  jsonResponse,
  preflight,
  requireEnv,
  sha256Hex,
} from '../_shared/http.ts';
import { adapterFor } from './adapters/registry.ts';
import {
  type GenerateOutcome,
  type ProviderAdapter,
  ProviderError,
} from './adapters/types.ts';

// MED-01 generate-asset: the only place a provider is called.
//
// Authorization is not decided here. The caller's own token asks the database for
// the asset, so a learner's token is refused by `request_generated_asset` before
// any provider is reached, and this function cannot be tricked into paying for
// work nobody was allowed to ask for. The service role appears only after that,
// to claim the job and record what came back.
//
// An identical ask never reaches a provider: the database returns the existing
// row and this function returns it unchanged.
//
// MED-04 adds an asynchronous path for clips. Veo answers with a job name, not
// bytes, so a later ask for the same reaction collects that job rather than
// starting a second one — which is what stops a clip being paid for twice
// because the first invocation ended before the provider did.

const bucket = 'generated-assets';

interface RequestBody {
  kind?: string;
  slot?: string;
  prompt?: string;
  prompt_version?: string;
  locale?: string;
  aspect_ratio?: string;
  provider_id?: string;
  feature?: string;
  school_id?: string;
  /// MED-03: ask for a recording of an authored line instead of a prompt. The
  /// words, the version, and the voice then come from the database, so a caller
  /// cannot have the Learning Guide say something nobody published.
  narration_slug?: string;
  voice_id?: string;
  /// MED-04: ask for a clip of a published reaction instead of a prompt. The
  /// direction and the allowed shapes come from the database, so a caller cannot
  /// quietly generate a clip of something no curator approved.
  clip_slug?: string;
}

Deno.serve(async (request) => {
  const options = preflight(request);
  if (options) return options;

  if (request.method !== 'POST') {
    return errorResponse('METHOD_NOT_ALLOWED', 'Use POST.', 405);
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization) {
    return errorResponse('UNAUTHENTICATED', 'Sign in first.', 401);
  }

  let body: RequestBody;
  try {
    body = await request.json() as RequestBody;
  } catch (_error) {
    return errorResponse('BAD_REQUEST', 'Body must be JSON.');
  }

  const clipSlug = body.clip_slug?.trim();
  const narrationSlug = body.narration_slug?.trim();
  const kind = clipSlug ? 'video' : narrationSlug ? 'voice' : body.kind;
  if (kind !== 'image' && kind !== 'voice' && kind !== 'video') {
    return errorResponse('BAD_REQUEST', 'kind must be image, voice, or video.');
  }
  if (!clipSlug && !narrationSlug && (!body.slot || !body.prompt || !body.prompt_version)) {
    return errorResponse(
      'BAD_REQUEST',
      'Send clip_slug, narration_slug, or slot, prompt, and prompt_version.',
    );
  }

  let supabaseUrl: string;
  let anonKey: string;
  let serviceKey: string;
  try {
    supabaseUrl = requireEnv('SUPABASE_URL');
    anonKey = requireEnv('SUPABASE_ANON_KEY');
    serviceKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
  } catch (_error) {
    // The name of a missing value is a deployment detail, not a caller's business.
    return errorResponse('NOT_CONFIGURED', 'Generation is not configured.', 503);
  }

  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const worker = createClient(supabaseUrl, serviceKey);

  // Step 1: the caller's own permissions decide whether this request exists.
  const requested = clipSlug
    ? await caller.rpc('request_reaction_clip', {
      p_slug: clipSlug,
      p_aspect_ratio: body.aspect_ratio ?? '1:1',
    })
    : narrationSlug
    ? await caller.rpc('request_narration_line', {
      p_slug: narrationSlug,
      p_locale: body.locale ?? 'en',
      p_voice_id: body.voice_id ?? null,
    })
    : await caller.rpc('request_generated_asset', {
      p_kind: kind,
      p_slot: body.slot,
      p_prompt: body.prompt,
      p_prompt_version: body.prompt_version,
      p_locale: body.locale ?? 'en',
      p_aspect_ratio: body.aspect_ratio ?? '1:1',
      p_provider_id: body.provider_id ?? null,
      p_feature: body.feature ?? 'companion',
      p_school_id: body.school_id ?? null,
      p_voice_id: body.voice_id ?? null,
    });

  if (requested.error) {
    // A spent budget is its own answer: nothing is broken and retrying today
    // cannot help, so it is not dressed up as a generic refusal.
    if (requested.error.code === 'NM006') {
      return errorResponse('QUOTA_EXCEEDED', requested.error.message, 429);
    }
    // A line that cannot be recorded — no wording in this language, or a name
    // placeholder that belongs to the learner — is a settled answer too. The
    // message explains which, because a curator can act on it.
    if (requested.error.code === 'NM007') {
      return errorResponse('NOT_RECORDABLE', requested.error.message, 422);
    }
    // A reaction that has no direction for this shape is the same kind of
    // settled answer: asking again will not invent an authored framing.
    if (requested.error.code === 'NM009') {
      return errorResponse('NOT_AUTHORABLE', requested.error.message, 422);
    }
    const code = requested.error.code === 'NM001' ? 'FORBIDDEN' : 'REQUEST_REFUSED';
    const status = requested.error.code === 'NM001' ? 403 : 400;
    return errorResponse(code, requested.error.message, status);
  }

  const asset = (requested.data as { reused: boolean; asset: Record<string, unknown> });
  const status = asset.asset.status as string;

  // Already answered. Nothing to pay for, and nothing left to collect.
  if (status === 'ready' || status === 'failed') {
    return jsonResponse({ reused: asset.reused, asset: asset.asset });
  }

  const assetId = asset.asset.id as string;
  const providerId = asset.asset.provider_id as string;
  const promptHash = asset.asset.prompt_hash as string;
  const locale = asset.asset.locale as string;
  const aspectRatio = asset.asset.aspect_ratio as string;
  const slot = asset.asset.slot as string;
  // The prompt is read back from the row rather than from the body: for an
  // authored line or clip the database chose the words, and for anything else
  // the row is what the hash was built from.
  const prompt = asset.asset.prompt as string;
  const promptVersion = asset.asset.prompt_version as string;
  const voiceId = asset.asset.voice_id as string | null;
  // An in-flight clip carries the provider's handle on the row. Reading it here
  // is what lets a later ask collect the job the first ask started (MED-04).
  let providerJobId = (asset.asset.provider_job_id as string | null) ?? null;

  // A generating row with no job yet is someone else's claim. Leaving it alone
  // is what stops two workers from both paying for the same clip.
  if (status === 'generating' && !providerJobId) {
    return jsonResponse({ reused: true, asset: asset.asset });
  }

  // A registered voice becomes a provider-side voice name here, where the service
  // role can read the registry. An adapter never guesses one.
  let voiceName: string | undefined;
  if (voiceId) {
    const voice = await worker
      .from('narration_voices')
      .select('provider_voice_name')
      .eq('id', voiceId)
      .maybeSingle();
    voiceName = voice.data?.provider_voice_name as string | undefined;
  }

  // Authored clip length, when this ask was for a reaction. Absent for every
  // other path; the adapter then uses its own default.
  let durationSeconds: number | undefined;
  if (clipSlug) {
    const clip = await worker
      .from('reaction_clips')
      .select('id')
      .eq('slug', clipSlug)
      .maybeSingle();
    if (clip.data?.id) {
      const version = await worker
        .from('reaction_clip_versions')
        .select('duration_seconds')
        .eq('clip_id', clip.data.id)
        .eq('status', 'published')
        .maybeSingle();
      const authored = Number(version.data?.duration_seconds);
      if (Number.isFinite(authored) && authored > 0) durationSeconds = authored;
    }
  }

  // Step 2: claim it when it is waiting. An already-generating job with a handle
  // skips this — claiming would refuse, and the handle is enough to collect.
  if (status === 'requested') {
    const claim = await worker.rpc('claim_generated_asset', { p_asset_id: assetId });
    if (claim.error) {
      return jsonResponse({ reused: true, asset: asset.asset });
    }
    const claimed = claim.data as { asset?: Record<string, unknown> } | null;
    // Prefer the claimed row's handle: a previous attempt may have left one, and
    // that is cheaper than starting a second provider job.
    const claimedJob = claimed?.asset?.provider_job_id as string | null | undefined;
    if (claimedJob) providerJobId = claimedJob;
  }

  const startedAt = Date.now();
  try {
    const adapter = adapterFor(providerId, kind);
    const outcome = await runAdapter(adapter, {
      kind,
      slot,
      prompt,
      locale,
      aspectRatio,
      promptHash,
      voiceName,
      providerJobId: providerJobId ?? undefined,
      durationSeconds,
    });

    if (outcome.status === 'pending') {
      // The job outlives this invocation. Recording the handle is what lets the
      // next ask for the same reaction collect it instead of starting another.
      const progress = await worker.rpc('record_generated_asset_progress', {
        p_asset_id: assetId,
        p_provider_job_id: outcome.providerJobId,
        p_poll_after_seconds: outcome.pollAfterSeconds,
      });
      if (progress.error) {
        return errorResponse('RECORD_FAILED', progress.error.message, 500);
      }
      // 200 rather than 202: clients that only accept a success status still see
      // the pending flag, and the asset row is the durable answer either way.
      return jsonResponse({
        reused: false,
        pending: true,
        asset: progress.data,
      });
    }

    const generated = outcome.bytes;
    const path = `${kind}/${slot}/${locale}/${promptHash}.${generated.extension}`;
    const upload = await worker.storage.from(bucket).upload(path, generated.bytes, {
      contentType: generated.contentType,
      upsert: true,
      // The path contains the request hash, so these bytes never change under
      // this name: a year is safe, and it is what keeps a clip from being
      // fetched twice on the same device.
      cacheControl: '31536000',
    });
    if (upload.error) {
      throw new ProviderError('STORAGE_WRITE_FAILED', upload.error.message, true);
    }

    const recorded = await worker.rpc('record_generated_asset_result', {
      p_asset_id: assetId,
      p_storage_bucket: bucket,
      p_storage_path: path,
      p_content_type: generated.contentType,
      p_byte_size: generated.bytes.byteLength,
      p_checksum: `sha256:${await sha256Hex(generated.bytes)}`,
      p_provider_reference: generated.providerReference ?? null,
      p_cost_micros: generated.costMicros,
      p_latency_ms: Date.now() - startedAt,
      p_rights: 'platform-owned',
      p_provenance: {
        provider_id: providerId,
        prompt_version: promptVersion,
        aspect_ratio: aspectRatio,
        locale,
        voice_id: voiceId,
        voice_name: voiceName ?? null,
        narration_slug: narrationSlug ?? null,
        clip_slug: clipSlug ?? null,
        provider_job_id: providerJobId ?? generated.providerReference ?? null,
        generated_at: new Date().toISOString(),
      },
    });
    if (recorded.error) {
      return errorResponse('RECORD_FAILED', recorded.error.message, 500);
    }

    return jsonResponse({ reused: false, asset: recorded.data });
  } catch (error) {
    const failure = error instanceof ProviderError
      ? error
      : new ProviderError('PROVIDER_FAILED', 'Generation failed', true);

    const recorded = await worker.rpc('record_generated_asset_failure', {
      p_asset_id: assetId,
      p_error_code: failure.code,
      p_error_message: failure.message,
      p_latency_ms: Date.now() - startedAt,
    });

    // A failure is data, not a broken request: the asset row carries the reason and
    // every companion slot still has its local fallback.
    return jsonResponse({
      reused: false,
      asset: recorded.data ?? null,
      error: { code: failure.code, retryable: failure.retryable },
    });
  }
});

/// Prefer the asynchronous contract when an adapter has one. Everything else
/// remains a single call that returns bytes, wrapped so the rest of the function
/// only has to understand one shape.
async function runAdapter(
  adapter: ProviderAdapter,
  request: Parameters<ProviderAdapter['generate']>[0],
): Promise<GenerateOutcome> {
  if (adapter.generateOrPending) {
    return await adapter.generateOrPending(request);
  }
  return { status: 'ready', bytes: await adapter.generate(request) };
}
