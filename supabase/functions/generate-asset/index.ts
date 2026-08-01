import { createClient } from 'jsr:@supabase/supabase-js@2';

import {
  errorResponse,
  jsonResponse,
  preflight,
  requireEnv,
  sha256Hex,
} from '../_shared/http.ts';
import { adapterFor } from './adapters/registry.ts';
import { ProviderError } from './adapters/types.ts';

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

const bucket = 'generated-assets';

interface RequestBody {
  kind?: string;
  slot?: string;
  prompt?: string;
  prompt_version?: string;
  locale?: string;
  aspect_ratio?: string;
  provider_id?: string;
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

  const kind = body.kind;
  if (kind !== 'image' && kind !== 'voice' && kind !== 'video') {
    return errorResponse('BAD_REQUEST', 'kind must be image, voice, or video.');
  }
  if (!body.slot || !body.prompt || !body.prompt_version) {
    return errorResponse(
      'BAD_REQUEST',
      'slot, prompt, and prompt_version are required.',
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
  const requested = await caller.rpc('request_generated_asset', {
    p_kind: kind,
    p_slot: body.slot,
    p_prompt: body.prompt,
    p_prompt_version: body.prompt_version,
    p_locale: body.locale ?? 'en',
    p_aspect_ratio: body.aspect_ratio ?? '1:1',
    p_provider_id: body.provider_id ?? null,
  });

  if (requested.error) {
    const code = requested.error.code === 'NM001' ? 'FORBIDDEN' : 'REQUEST_REFUSED';
    const status = requested.error.code === 'NM001' ? 403 : 400;
    return errorResponse(code, requested.error.message, status);
  }

  const asset = (requested.data as { reused: boolean; asset: Record<string, unknown> });
  if (asset.reused || asset.asset.status !== 'requested') {
    // Already answered, or already in flight somewhere else. Nothing to pay for.
    return jsonResponse({ reused: asset.reused, asset: asset.asset });
  }

  const assetId = asset.asset.id as string;
  const providerId = asset.asset.provider_id as string;
  const promptHash = asset.asset.prompt_hash as string;
  const locale = asset.asset.locale as string;
  const aspectRatio = asset.asset.aspect_ratio as string;
  const slot = asset.asset.slot as string;

  // Step 2: claim it, so a retried invocation cannot start a second provider call.
  const claim = await worker.rpc('claim_generated_asset', { p_asset_id: assetId });
  if (claim.error) {
    return jsonResponse({ reused: true, asset: asset.asset });
  }

  const startedAt = Date.now();
  try {
    const adapter = adapterFor(providerId, kind);
    const generated = await adapter.generate({
      kind,
      slot,
      prompt: body.prompt,
      locale,
      aspectRatio,
      promptHash,
    });

    const path = `${kind}/${slot}/${locale}/${promptHash}.${generated.extension}`;
    const upload = await worker.storage.from(bucket).upload(path, generated.bytes, {
      contentType: generated.contentType,
      upsert: true,
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
        prompt_version: body.prompt_version,
        aspect_ratio: aspectRatio,
        locale,
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
