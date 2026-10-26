import Foundation
import FoundationModels
import Testing
@testable import ClaudeLanguageModel

@Generable struct TestStop {
    @Guide(description: "Short place id from search_places, like p3") var placeID: String
    var name: String
}

@Generable struct TestPlan {
    @Guide(description: "Evocative title") var title: String
    @Guide(description: "Stops in walking order", .count(3...8)) var stops: [TestStop]
}

@Generable struct TestSearch {
    @Guide(description: "What to look for") var query: String
    @Guide(description: "Optional place category") var category: String?
}

@Test func transcriptBecomesMessagesRequest() throws {
    let transcript = Transcript(entries: [
        .instructions(.init(segments: [.text(.init(content: "You are a guide."))], toolDefinitions: [])),
        .prompt(.init(segments: [.text(.init(content: "Hi"))])),
        .response(.init(assetIDs: [], segments: [.text(.init(content: "Hello!"))])),
        .prompt(.init(segments: [.text(.init(content: "Plan a walk in Warsaw"))])),
        .reasoning(.init(segments: [], signature: Data("sig-123".utf8))),
        .toolCalls(.init([
            .init(id: "toolu_1", toolName: "search_places", arguments: GeneratedContent(properties: ["query": "church"])),
            .init(id: "toolu_2", toolName: "search_places", arguments: GeneratedContent(properties: ["query": "cafe"])),
        ])),
        .toolOutput(.init(id: "toolu_1", toolName: "search_places", segments: [.text(.init(content: #"[{"id":"p1"}]"#))])),
        .toolOutput(.init(id: "toolu_2", toolName: "search_places", segments: [.text(.init(content: #"[{"id":"p2"}]"#))])),
    ])
    let request = LanguageModelExecutorGenerationRequest(
        id: UUID(),
        transcript: transcript,
        enabledTools: [.init(name: "search_places", description: "Find places", parameters: TestSearch.generationSchema)],
        schema: TestPlan.generationSchema,
        generationOptions: GenerationOptions(temperature: 0.7, maximumResponseTokens: 4000),
        contextOptions: ContextOptions(reasoningLevel: .moderate),
        metadata: [:]
    )

    let body = try MessagesRequest.body(for: request, model: "claude-sonnet-5-5", defaultEffort: "high")

    let actual = try #require(try JSONSerialization.jsonObject(with: body) as? NSDictionary)
    let expected = try #require(try JSONSerialization.jsonObject(with: Data(expectedBody.utf8)) as? NSDictionary)
    #expect(actual == expected)

    let json = String(decoding: body, as: UTF8.self)
    let titleIndex = try #require(json.range(of: #""title""#)).lowerBound
    let stopsIndex = try #require(json.range(of: #""stops""#)).lowerBound
    #expect(titleIndex < stopsIndex, "schema properties must keep the struct order")
}

private let expectedBody = #"""
{
  "model": "claude-sonnet-5-5",
  "max_tokens": 4000,
  "system": "You are a guide.",
  "messages": [
    { "role": "user", "content": [{ "type": "text", "text": "Hi" }] },
    { "role": "assistant", "content": [{ "type": "text", "text": "Hello!" }] },
    { "role": "user", "content": [{ "type": "text", "text": "Plan a walk in Warsaw" }] },
    { "role": "assistant", "content": [
      { "type": "thinking", "thinking": "", "signature": "sig-123" },
      { "type": "tool_use", "id": "toolu_1", "name": "search_places", "input": { "query": "church" } },
      { "type": "tool_use", "id": "toolu_2", "name": "search_places", "input": { "query": "cafe" } }
    ] },
    { "role": "user", "content": [
      { "type": "tool_result", "tool_use_id": "toolu_1", "content": [{ "type": "text", "text": "[{\"id\":\"p1\"}]" }] },
      { "type": "tool_result", "tool_use_id": "toolu_2", "content": [{ "type": "text", "text": "[{\"id\":\"p2\"}]" }] }
    ] }
  ],
  "tools": [{
    "name": "search_places",
    "description": "Find places",
    "strict": true,
    "input_schema": {
      "type": "object",
      "properties": {
        "query": { "type": "string", "description": "What to look for" },
        "category": { "type": "string", "description": "Optional place category" }
      },
      "required": ["query"],
      "additionalProperties": false
    }
  }],
  "output_config": {
    "effort": "medium",
    "format": {
      "type": "json_schema",
      "schema": {
        "type": "object",
        "properties": {
          "title": { "type": "string", "description": "Evocative title" },
          "stops": { "type": "array", "description": "Stops in walking order", "items": { "$ref": "#/$defs/TestStop" } }
        },
        "required": ["title", "stops"],
        "additionalProperties": false,
        "$defs": {
          "TestStop": {
            "type": "object",
            "properties": {
              "placeID": { "type": "string", "description": "Short place id from search_places, like p3" },
              "name": { "type": "string" }
            },
            "required": ["placeID", "name"],
            "additionalProperties": false
          }
        }
      }
    }
  }
}
"""#
