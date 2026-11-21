import Foundation
import FoundationModels
import Observation

@Observable
final class GuideChat: Identifiable {
    struct Message: Identifiable {
        let id = UUID()
        let isGuide: Bool
        var text: String
    }

    let stopName: String
    var question = ""
    var error: (any Error)?
    private(set) var messages: [Message] = []
    private(set) var isAnswering = false
    private let session: LanguageModelSession

    init(model: any LanguageModel, stop: PlannedStop, story: Story, neighborhood: String, catalog: PlaceCatalog) {
        let instructions = """
            Answer questions from someone standing at this stop of a walking tour. Keep answers to \
            a few conversational sentences of plain text, without Markdown. When they ask what is nearby, call search_places and \
            recommend only places it returned, by name and distance, never by id. If you do not \
            know something, say so briefly.

            Neighborhood: \(neighborhood)
            Stop: \(stop.name)
            Story they just heard: \(story.headline)
            \(story.paragraphs.joined(separator: "\n"))
            """
        stopName = stop.name
        session = LanguageModelSession(model: model, tools: [SearchPlacesTool(catalog: catalog)], instructions: instructions)
    }

    var canSend: Bool {
        !isAnswering && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send() {
        guard canSend else { return }
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        question = ""
        isAnswering = true
        Task {
            do {
                try await ask(text)
            } catch {
                question = text
                self.error = error
            }
            isAnswering = false
        }
    }

    func ask(_ question: String) async throws {
        messages.append(Message(isGuide: false, text: question))
        messages.append(Message(isGuide: true, text: ""))
        do {
            for try await snapshot in session.streamResponse(to: question) {
                messages[messages.count - 1].text = snapshot.content
            }
        } catch {
            messages.removeLast(2)
            throw error
        }
    }
}
