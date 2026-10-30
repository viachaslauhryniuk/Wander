import FoundationModels
import Observation

@Observable
final class StoryWriter {
    private(set) var drafts: [String: Story.PartiallyGenerated] = [:]
    private(set) var stories: [String: Story] = [:]
    private(set) var failures: [String: any Error] = [:]
    private var writing: Set<String> = []
    private let model: any LanguageModel
    private let plan: TourPlan
    private let neighborhood: String

    private static let instructions = """
        Write the story of one stop on a walking tour, to be read or heard while standing there. \
        Use plain, vivid language. Include only what you are confident is true about this place: \
        if you know little about it, describe what can be seen and why it matters instead of \
        inventing facts. Never mention your own knowledge or its limits. Write in the language of \
        the tour title.
        """

    init(model: any LanguageModel, plan: TourPlan, neighborhood: String) {
        self.model = model
        self.plan = plan
        self.neighborhood = neighborhood
    }

    func prepare(stop index: Int) {
        for stop in plan.stops.dropFirst(index).prefix(2) where stories[stop.placeID] == nil && !writing.contains(stop.placeID) {
            writing.insert(stop.placeID)
            failures[stop.placeID] = nil
            Task { await write(stop) }
        }
    }

    private func write(_ stop: PlannedStop) async {
        defer { writing.remove(stop.placeID) }
        do {
            let session = LanguageModelSession(model: model, instructions: Self.instructions)
            let stream = session.streamResponse(to: "Tour: \(plan.title)\nNeighborhood: \(neighborhood)\nStop: \(stop.name)\nWhy it is on the tour: \(stop.hook)", generating: Story.self)
            for try await snapshot in stream {
                drafts[stop.placeID] = snapshot.content
            }
            var story = try await stream.collect().content
            story.paragraphs = Array(story.paragraphs.prefix(4))
            stories[stop.placeID] = story
        } catch {
            failures[stop.placeID] = error
        }
    }
}
