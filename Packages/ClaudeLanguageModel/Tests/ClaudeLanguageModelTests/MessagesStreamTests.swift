import Foundation
import FoundationModels
import Testing
@testable import ClaudeLanguageModel

@Test func streamBecomesTranscriptEntries() async throws {
    let session = LanguageModelSession(model: RecordedModel(), tools: [RecordedSearch()], instructions: "You are a guide.")

    let response = try await session.respond(to: "Plan a walk")

    #expect(response.content == "Start at Rynek.")
    let entries = Array(session.transcript)
    try #require(entries.count == 6)
    guard case .reasoning(let reasoning) = entries[2],
          case .toolCalls(let calls) = entries[3],
          case .toolOutput(let output) = entries[4] else {
        Issue.record("unexpected transcript: \(entries)")
        return
    }
    #expect(text(reasoning.segments) == "Need places.")
    #expect(reasoning.signature == Data("sig-abc".utf8))
    #expect(calls.map(\.id) == ["toolu_1"])
    #expect(calls.map(\.toolName) == ["search_places"])
    #expect(try calls[0].arguments.value(String.self, forProperty: "query") == "church")
    #expect(output.id == "toolu_1")
    #expect(text(output.segments) == "p1 church")
}

private struct RecordedModel: LanguageModel {
    let capabilities = LanguageModelCapabilities([.toolCalling, .reasoning])
    let executorConfiguration = 0

    struct Executor: LanguageModelExecutor {
        init(configuration: Int) {}

        func prewarm(model: RecordedModel, transcript: Transcript) {}

        nonisolated(nonsending) func respond(to request: LanguageModelExecutorGenerationRequest, model: RecordedModel, streamingInto channel: LanguageModelExecutorGenerationChannel) async throws {
            var lines = toolTurn
            if case .toolOutput = request.transcript.last { lines = answerTurn }
            let stream = AsyncThrowingStream<String, any Error> { continuation in
                for line in lines { continuation.yield(line) }
                continuation.finish()
            }
            try await MessagesStream.forward(stream, into: channel)
        }
    }
}

private struct RecordedSearch: Tool {
    let name = "search_places"
    let description = "Find places"

    @Generable struct Arguments {
        var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        "p1 \(arguments.query)"
    }
}

private func text(_ segments: [Transcript.Segment]) -> String {
    segments.map { if case .text(let text) = $0 { text.content } else { "" } }.joined()
}

private let toolTurn = [
    #"{"type":"message_start","message":{"id":"msg_1","type":"message","role":"assistant","model":"claude-sonnet-5-5","content":[],"stop_reason":null,"usage":{"input_tokens":120,"output_tokens":1}}}"#,
    #"{"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":"","signature":""}}"#,
    #"{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Need places."}}"#,
    #"{"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"sig-abc"}}"#,
    #"{"type":"content_block_stop","index":0}"#,
    #"{"type":"ping"}"#,
    #"{"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"search_places","input":{}}}"#,
    #"{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"query\": \"chu"}}"#,
    #"{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"rch\"}"}}"#,
    #"{"type":"content_block_stop","index":1}"#,
    #"{"type":"message_delta","delta":{"stop_reason":"tool_use","stop_sequence":null},"usage":{"output_tokens":40}}"#,
    #"{"type":"message_stop"}"#,
]

private let answerTurn = [
    #"{"type":"message_start","message":{"id":"msg_2","type":"message","role":"assistant","model":"claude-sonnet-5-5","content":[],"stop_reason":null,"usage":{"input_tokens":180,"output_tokens":1}}}"#,
    #"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#,
    #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Start at "}}"#,
    #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Rynek."}}"#,
    #"{"type":"content_block_stop","index":0}"#,
    #"{"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":6}}"#,
    #"{"type":"message_stop"}"#,
]
