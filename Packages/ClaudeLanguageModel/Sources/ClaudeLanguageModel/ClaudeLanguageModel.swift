import Foundation
import FoundationModels

public struct ClaudeLanguageModel: LanguageModel {
    public struct Configuration: Hashable, Sendable {
        let endpoint: URL
        let installID: String
    }

    public let capabilities = LanguageModelCapabilities([.toolCalling, .guidedGeneration, .reasoning])
    public let executorConfiguration: Configuration

    public init(endpoint: URL, installID: String) {
        executorConfiguration = Configuration(endpoint: endpoint, installID: installID)
    }

    public struct Executor: LanguageModelExecutor {
        let configuration: Configuration

        public init(configuration: Configuration) {
            self.configuration = configuration
        }

        public nonisolated(nonsending) func respond(to request: LanguageModelExecutorGenerationRequest, model: ClaudeLanguageModel, streamingInto channel: LanguageModelExecutorGenerationChannel) async throws {
            var urlRequest = URLRequest(url: configuration.endpoint.appending(path: "v1/messages"))
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(configuration.installID, forHTTPHeaderField: "X-Asides-Install")
            urlRequest.httpBody = try MessagesRequest.body(for: request, model: "claude-sonnet-5-5", defaultEffort: "high")

            let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                let data = try await bytes.reduce(into: Data()) { $0.append($1) }
                let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? String(decoding: data, as: UTF8.self)
                if status == 429 {
                    throw LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: message))
                }
                throw ClaudeError.http(status, message)
            }
            try await MessagesStream.forward(bytes.lines, into: channel)
        }
    }
}
