import Foundation
import FoundationModels

public enum ClaudeError: Error {
    case truncated
    case server(String)
    case http(Int, String)
}

enum MessagesStream {
    nonisolated(nonsending) static func forward(_ lines: some AsyncSequence<String, any Error>, into channel: LanguageModelExecutorGenerationChannel) async throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var toolCalls: [Int: (id: String, name: String)] = [:]

        for try await line in lines where !line.isEmpty {
            let event = try decoder.decode(Event.self, from: Data(line.utf8))
            switch event.type {
            case "content_block_start":
                if let index = event.index, let block = event.contentBlock, let id = block.id, let name = block.name {
                    toolCalls[index] = (id, name)
                }
            case "content_block_delta":
                guard let delta = event.delta else { continue }
                if let text = delta.text {
                    await channel.send(.response(action: .appendText(text, tokenCount: 1)))
                } else if let thinking = delta.thinking {
                    await channel.send(.reasoning(action: .appendText(thinking, tokenCount: 1)))
                } else if let signature = delta.signature {
                    await channel.send(.reasoning(action: .updateSignature(Data(signature.utf8), tokenCount: 0)))
                } else if let json = delta.partialJson, let index = event.index, let call = toolCalls[index] {
                    await channel.send(.toolCalls(action: .toolCall(id: call.id, name: call.name, action: .appendArguments(json, tokenCount: 1))))
                }
            case "message_delta":
                switch event.delta?.stopReason {
                case "max_tokens": throw ClaudeError.truncated
                case "refusal": throw LanguageModelError.refusal(.init(explanation: "Claude declined to answer", debugDescription: "stop_reason: refusal"))
                default: break
                }
            case "error":
                throw ClaudeError.server(event.error?.message ?? "stream error")
            default:
                continue
            }
        }
    }

    private struct Event: Decodable {
        struct Block: Decodable {
            let id: String?
            let name: String?
        }

        struct Delta: Decodable {
            let text: String?
            let thinking: String?
            let signature: String?
            let partialJson: String?
            let stopReason: String?
        }

        struct Failure: Decodable {
            let message: String
        }

        let type: String
        let index: Int?
        let contentBlock: Block?
        let delta: Delta?
        let error: Failure?
    }
}
