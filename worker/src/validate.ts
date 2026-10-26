const MAX_BYTES = 64 * 1024;
const MODEL = "claude-sonnet-5-5";
const MAX_TOKENS = 16_000;
const MAX_MESSAGES = 60;
const MAX_TOOLS = 4;
const TOP_LEVEL_FIELDS = new Set(["model", "max_tokens", "system", "messages", "tools", "output_config"]);
const OUTPUT_CONFIG_FIELDS = new Set(["format", "effort"]);
const EFFORTS = new Set(["low", "medium", "high"]);
const MESSAGE_BLOCKS = new Set(["text", "thinking", "tool_use", "tool_result"]);
const TOOL_RESULT_BLOCKS = new Set(["text"]);

export type MessagesBody = {
  model: string;
  max_tokens: number;
  system?: string;
  messages: { role: "user" | "assistant"; content: unknown }[];
  tools?: Record<string, unknown>[];
  output_config?: { format?: Record<string, unknown>; effort?: string };
};

export type Validation = { ok: true; body: MessagesBody } | { ok: false; error: string };

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

const fail = (error: string): Validation => ({ ok: false, error });

export function validate(raw: string): Validation {
  if (new TextEncoder().encode(raw).length > MAX_BYTES) return fail("body too large");

  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    return fail("invalid JSON");
  }
  if (!isRecord(body)) return fail("invalid JSON: expected an object");

  const unknownField = Object.keys(body).find((key) => !TOP_LEVEL_FIELDS.has(key));
  if (unknownField) return fail(`unknown field: ${unknownField}`);

  if (body.model !== MODEL) return fail("model not allowed");

  const maxTokens = body.max_tokens;
  if (typeof maxTokens !== "number" || !Number.isInteger(maxTokens) || maxTokens < 1 || maxTokens > MAX_TOKENS) {
    return fail(`max_tokens must be 1...${MAX_TOKENS}`);
  }

  if (body.system !== undefined && typeof body.system !== "string") return fail("system must be a string");

  const messages = body.messages;
  if (!Array.isArray(messages) || messages.length === 0 || messages.length > MAX_MESSAGES) {
    return fail(`messages: 1...${MAX_MESSAGES} required`);
  }
  for (const message of messages) {
    const error = checkMessage(message);
    if (error) return fail(error);
  }

  const tools = body.tools;
  if (tools !== undefined) {
    if (!Array.isArray(tools) || tools.length > MAX_TOOLS) return fail(`tools: at most ${MAX_TOOLS}`);
    if (!tools.every((tool) => isRecord(tool) && typeof tool.name === "string")) return fail("tools: invalid tool");
  }

  const outputConfig = body.output_config;
  if (outputConfig !== undefined) {
    const error = checkOutputConfig(outputConfig);
    if (error) return fail(error);
  }

  return { ok: true, body: body as MessagesBody };
}

function checkMessage(message: unknown): string | undefined {
  if (!isRecord(message) || (message.role !== "user" && message.role !== "assistant")) {
    return "messages: role must be user or assistant";
  }
  return checkContent(message.content, MESSAGE_BLOCKS);
}

function checkContent(content: unknown, allowed: Set<string>): string | undefined {
  if (typeof content === "string") return undefined;
  if (!Array.isArray(content)) return "content must be a string or a list of blocks";
  for (const block of content) {
    if (!isRecord(block) || typeof block.type !== "string") return "content block without a type";
    if (!allowed.has(block.type)) return `content type not allowed: ${block.type}`;
    if (block.type === "tool_result" && block.content !== undefined) {
      const error = checkContent(block.content, TOOL_RESULT_BLOCKS);
      if (error) return error;
    }
  }
  return undefined;
}

function checkOutputConfig(outputConfig: unknown): string | undefined {
  if (!isRecord(outputConfig)) return "output_config must be an object";
  const unknownField = Object.keys(outputConfig).find((key) => !OUTPUT_CONFIG_FIELDS.has(key));
  if (unknownField) return `output_config: unknown field ${unknownField}`;
  const { effort, format } = outputConfig;
  if (effort !== undefined && (typeof effort !== "string" || !EFFORTS.has(effort))) {
    return "effort must be low, medium or high";
  }
  if (format !== undefined && !(isRecord(format) && format.type === "json_schema" && isRecord(format.schema))) {
    return "output_config.format must be a json_schema";
  }
  return undefined;
}
