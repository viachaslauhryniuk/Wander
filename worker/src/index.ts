import Anthropic from "@anthropic-ai/sdk";
import { MAX_BYTES, validate } from "./validate";

const VOICE = "JBFqnCBsd6RMkjVDRZzb";
const MAX_SPEECH_CHARS = 5000;
const GUIDE_PREFIX =
  "You are Asides, a city walking guide. Only help with walks, places, their history and practical tips for the walk.";

export default {
  async fetch(request, env): Promise<Response> {
    const path = new URL(request.url).pathname;
    if (path !== "/v1/messages" && path !== "/v1/speech") return error(404, "not found");
    if (request.method !== "POST") return error(405, "method not allowed");

    const install = request.headers.get("x-asides-install") ?? "unknown";
    const ip = request.headers.get("cf-connecting-ip") ?? "local";
    const { success } = await env.RATE_LIMITER.limit({ key: `${install}:${ip}` });
    if (!success) return error(429, "too many requests, try again in a minute");

    if (Number(request.headers.get("content-length") ?? 0) > MAX_BYTES) return error(400, "body too large");

    if (path === "/v1/speech") return speech(await request.text(), env);

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

async function speech(raw: string, env: Env): Promise<Response> {
  let text: unknown;
  try {
    text = JSON.parse(raw).text;
  } catch {
    return error(400, "invalid JSON");
  }
  if (typeof text !== "string" || text.length === 0 || text.length > MAX_SPEECH_CHARS) {
    return error(400, `text must be 1...${MAX_SPEECH_CHARS} characters`);
  }
  const upstream = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${VOICE}?output_format=mp3_44100_128`, {
    method: "POST",
    headers: { "xi-api-key": env.ELEVENLABS_API_KEY, "content-type": "application/json" },
    body: JSON.stringify({ text, model_id: "eleven_multilingual_v2" }),
  });
  if (!upstream.ok) {
    console.error("speech upstream failure", upstream.status);
    return error(upstream.status === 429 ? 429 : 502, "speech unavailable");
  }
  return new Response(upstream.body, { headers: { "content-type": "audio/mpeg", "cache-control": "no-store" } });
}

function upstreamError(failure: unknown): Response {
  if (failure instanceof Anthropic.APIError && failure.status === 429) return error(429, "rate limited, try again shortly");
  if (failure instanceof Anthropic.APIError && failure.status === 400) return error(400, failure.message);
  console.error("upstream failure", failure instanceof Anthropic.APIError ? failure.status : String(failure));
  return error(502, "upstream unavailable");
}

function error(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}
