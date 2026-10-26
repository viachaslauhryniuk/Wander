import { describe, expect, it } from "vitest";
import { validate } from "../src/validate";

const validBody = {
  model: "claude-sonnet-5-5",
  max_tokens: 12000,
  system: "You are a city walking guide.",
  messages: [
    { role: "user", content: "Plan a walk" },
    {
      role: "assistant",
      content: [
        { type: "thinking", thinking: "", signature: "sig" },
        { type: "tool_use", id: "t1", name: "search_places", input: { query: "church" } },
      ],
    },
    {
      role: "user",
      content: [{ type: "tool_result", tool_use_id: "t1", content: [{ type: "text", text: "[]" }] }],
    },
  ],
  tools: [{ name: "search_places", description: "Find places", input_schema: { type: "object" } }],
  output_config: { effort: "high", format: { type: "json_schema", schema: { type: "object" } } },
};

const withChanges = (changes: Record<string, unknown>) => JSON.stringify({ ...validBody, ...changes });

function expectRejected(raw: string, reason: RegExp) {
  const result = validate(raw);
  expect(result.ok).toBe(false);
  if (!result.ok) expect(result.error).toMatch(reason);
}

describe("validate", () => {
  it("accepts a body the adapter sends", () => {
    const result = validate(JSON.stringify(validBody));
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.body.model).toBe("claude-sonnet-5-5");
  });

  it("rejects invalid JSON", () => {
    expectRejected("{not json", /json/i);
  });

  it("rejects a body over 64 KB", () => {
    expectRejected(withChanges({ system: "x".repeat(65 * 1024) }), /too large/i);
  });

  it("rejects unknown top-level fields", () => {
    expectRejected(withChanges({ stream: false }), /stream/);
  });

  it("rejects any other model", () => {
    expectRejected(withChanges({ model: "claude-opus-5-5" }), /model/);
  });

  it("rejects max_tokens above 16000", () => {
    expectRejected(withChanges({ max_tokens: 16001 }), /max_tokens/);
  });

  it("rejects more than 60 messages", () => {
    const messages = Array.from({ length: 61 }, () => ({ role: "user", content: "hi" }));
    expectRejected(withChanges({ messages }), /messages/);
  });

  it("rejects more than 4 tools", () => {
    expectRejected(withChanges({ tools: Array(5).fill(validBody.tools[0]) }), /tools/);
  });

  it("rejects image blocks", () => {
    const messages = [{ role: "user", content: [{ type: "image", source: { type: "url", url: "https://x" } }] }];
    expectRejected(withChanges({ messages }), /image/);
  });

  it("rejects images hidden inside tool results", () => {
    const messages = [
      { role: "user", content: [{ type: "tool_result", tool_use_id: "t1", content: [{ type: "image" }] }] },
    ];
    expectRejected(withChanges({ messages }), /image/);
  });

  it("rejects unknown output_config fields", () => {
    expectRejected(withChanges({ output_config: { effort: "high", task_budget: {} } }), /output_config/);
  });

  it("rejects an effort above high", () => {
    expectRejected(withChanges({ output_config: { effort: "max" } }), /effort/);
  });
});
