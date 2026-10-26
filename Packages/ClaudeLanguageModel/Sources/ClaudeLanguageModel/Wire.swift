import Foundation
import FoundationModels

enum MessagesRequest {
    static func body(for request: LanguageModelExecutorGenerationRequest, model: String, defaultEffort: String) throws -> Data {
        var system: [String] = []
        var messages: [(role: String, content: [JSON])] = []
        func append(_ role: String, _ content: [JSON]) {
            if messages.last?.role == role {
                messages[messages.count - 1].content += content
            } else {
                messages.append((role, content))
            }
        }

        for entry in request.transcript {
            switch entry {
            case .instructions(let instructions):
                system.append(try text(of: instructions.segments, in: entry))
            case .prompt(let prompt):
                append("user", try textBlocks(prompt.segments, in: entry))
            case .response(let response):
                append("assistant", try textBlocks(response.segments, in: entry))
            case .reasoning(let reasoning):
                guard let signature = reasoning.signature else { continue }
                append("assistant", [.object([
                    ("type", .value("thinking")),
                    ("thinking", .value(try text(of: reasoning.segments, in: entry))),
                    ("signature", .value(String(decoding: signature, as: UTF8.self))),
                ])])
            case .toolCalls(let calls):
                append("assistant", try calls.map { call -> JSON in
                    .object([
                        ("type", .value("tool_use")),
                        ("id", .value(call.id)),
                        ("name", .value(call.toolName)),
                        ("input", .value(try JSONSerialization.jsonObject(with: Data(call.arguments.jsonString.utf8)))),
                    ])
                })
            case .toolOutput(let output):
                append("user", [.object([
                    ("type", .value("tool_result")),
                    ("tool_use_id", .value(output.id)),
                    ("content", .array(try textBlocks(output.segments, in: entry))),
                ])])
            @unknown default:
                throw unsupported(entry)
            }
        }

        var body: [(String, JSON)] = [
            ("model", .value(model)),
            ("max_tokens", .value(request.generationOptions.maximumResponseTokens ?? 12_000)),
        ]
        if !system.isEmpty {
            body.append(("system", .value(system.joined(separator: "\n\n"))))
        }
        body.append(("messages", .array(messages.map { JSON.object([("role", .value($0.role)), ("content", .array($0.content))]) })))
        if !request.enabledToolDefinitions.isEmpty {
            body.append(("tools", .array(try request.enabledToolDefinitions.map { tool -> JSON in
                .object([
                    ("name", .value(tool.name)),
                    ("description", .value(tool.description)),
                    ("strict", .value(true)),
                    ("input_schema", try schema(tool.parameters)),
                ])
            })))
        }
        var outputConfig: [(String, JSON)] = [("effort", .value(effort(request.contextOptions.reasoningLevel, default: defaultEffort)))]
        if let format = request.schema {
            outputConfig.append(("format", .object([("type", .value("json_schema")), ("schema", try schema(format))])))
        }
        body.append(("output_config", .object(outputConfig)))
        return Data(try JSON.object(body).encoded().utf8)
    }

    static func schema(_ schema: GenerationSchema) throws -> JSON {
        convert(try JSONSerialization.jsonObject(with: JSONEncoder().encode(schema)))
    }

    private static let schemaKeys: Set<String> = [
        "type", "properties", "required", "items", "$defs", "$ref", "description",
        "enum", "const", "anyOf", "allOf", "format", "additionalProperties",
    ]

    private static func convert(_ value: Any) -> JSON {
        if let items = value as? [Any] { return .array(items.map(convert)) }
        guard let object = value as? [String: Any] else { return .value(value) }
        let order = object["x-order"] as? [String] ?? []
        return .object(object.filter { schemaKeys.contains($0.key) }.sorted { $0.key < $1.key }.map { key, value -> (String, JSON) in
            switch key {
            case "properties", "$defs":
                let members = value as? [String: Any] ?? [:]
                let names = order.filter { members[$0] != nil } + members.keys.filter { !order.contains($0) }.sorted()
                return (key, .object(names.map { ($0, convert(members[$0]!)) }))
            case "items", "anyOf", "allOf", "additionalProperties":
                return (key, convert(value))
            default:
                return (key, .value(value))
            }
        })
    }

    private static func effort(_ level: ContextOptions.ReasoningLevel?, default defaultEffort: String) -> String {
        switch level {
        case .light: "low"
        case .moderate: "medium"
        case .deep: "high"
        default: defaultEffort
        }
    }

    private static func textBlocks(_ segments: [Transcript.Segment], in entry: Transcript.Entry) throws -> [JSON] {
        try segments.map { JSON.object([("type", .value("text")), ("text", .value(try text(of: $0, in: entry)))]) }
    }

    private static func text(of segments: [Transcript.Segment], in entry: Transcript.Entry) throws -> String {
        try segments.map { try text(of: $0, in: entry) }.joined()
    }

    private static func text(of segment: Transcript.Segment, in entry: Transcript.Entry) throws -> String {
        switch segment {
        case .text(let text): return text.content
        case .structure(let structure): return structure.content.jsonString
        default: throw unsupported(entry)
        }
    }

    private static func unsupported(_ entry: Transcript.Entry) -> LanguageModelError {
        .unsupportedTranscriptContent(.init(unsupportedContent: [entry], debugDescription: "Claude adapter sends text and structured content only"))
    }
}

enum JSON {
    case object([(String, JSON)])
    case array([JSON])
    case value(Any)

    func encoded() throws -> String {
        switch self {
        case .object(let members):
            return "{" + (try members.map { try JSON.value($0.0).encoded() + ":" + $0.1.encoded() }).joined(separator: ",") + "}"
        case .array(let items):
            return "[" + (try items.map { try $0.encoded() }).joined(separator: ",") + "]"
        case .value(let value):
            let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .withoutEscapingSlashes])
            return String(decoding: data, as: UTF8.self)
        }
    }
}
