import Anthropic from "@anthropic-ai/sdk";
import { MAX_BYTES, validate } from "./validate";

const GUIDE_PREFIX =
  "You are Asides, a city walking guide. Only help with walks, places, their history and practical tips for the walk.";

export default {
  async fetch(request, env): Promise<Response> {
    if (new URL(request.url).pathname !== "/v1/messages") return error(404, "not found");
    if (request.method !== "POST") return error(405, "method not allowed");

    const install = request.headers.get("x-asides-install") ?? "unknown";
    const ip = request.headers.get("cf-connecting-ip") ?? "local";
    const { success } = await env.RATE_LIMITER.limit({ key: `${install}:${ip}` });
    if (!success) return error(429, "too many requests, try again in a minute");

    if (Number(request.headers.get("content-length") ?? 0) > MAX_BYTES) return error(400, "body too large");

    const result = validate(await request.text());
    if (!result.ok) {
      console.warn("rejected:", result.error);
      return error(400, result.error);
    }
    const body = result.body;

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
    try {
      const stream = await client.beta.messages.create({
        ...(body as Omit<Anthropic.Beta.Messages.MessageCreateParamsStreaming, "stream">),
        system: body.system ? `${GUIDE_PREFIX}\n\n${body.system}` : GUIDE_PREFIX,
        stream: true,
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
      });
      return new Response(stream.toReadableStream(), {
        headers: { "content-type": "application/x-ndjson", "cache-control": "no-store" },
      });
    } catch (failure) {
      return upstreamError(failure);
    }
  },
} satisfies ExportedHandler<Env>;

function upstreamError(failure: unknown): Response {
  if (failure instanceof Anthropic.APIError && failure.status === 429) return error(429, "rate limited, try again shortly");
  if (failure instanceof Anthropic.APIError && failure.status === 400) return error(400, failure.message);
  console.error("upstream failure", failure instanceof Anthropic.APIError ? failure.status : String(failure));
  return error(502, "upstream unavailable");
}

function error(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}
