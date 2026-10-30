import FoundationModels
import Observation

enum TourPlanError: Error {
    case tooFewPlaces
}

@Observable
final class TourPlanner {
    private(set) var draft: TourPlan.PartiallyGenerated?
    let catalog: PlaceCatalog
    private let model: any LanguageModel

    private static let instructions = """
        Plan a walking tour through real places. Call search_places as many times as you need, \
        looking for varied things that suit the request. Use only places it returned: copy the id \
        into placeID and the name into name. Order the stops so each one is close to the previous \
        one, and fit the walk into the given time. Write in the language of the request.
        """

    init(model: any LanguageModel, catalog: PlaceCatalog) {
        self.model = model
        self.catalog = catalog
    }

    func plan(_ request: String, in neighborhood: String, minutes: Int) async throws -> TourPlan {
        let session = LanguageModelSession(model: model, tools: [SearchPlacesTool(catalog: catalog)], instructions: Self.instructions)
        let stream = session.streamResponse(to: "\(request)\nNeighborhood: \(neighborhood)\nTime: about \(minutes) minutes", generating: TourPlan.self)

        for try await snapshot in stream {
            draft = snapshot.content
        }

        var plan = try await stream.collect().content
        plan.stops = Array(plan.stops.filter { catalog.items[$0.placeID] != nil }.prefix(8))
        guard plan.stops.count >= 3 else { throw TourPlanError.tooFewPlaces }
        return plan
    }
}
