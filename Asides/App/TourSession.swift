import FoundationModels
import MapKit
import Observation

@Observable
final class TourSession {
    struct Stop: Identifiable {
        let id: GenerationID
        let number: Int
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    private(set) var draft: TourPlan.PartiallyGenerated?
    private(set) var plan: TourPlan?
    private var catalog: PlaceCatalog?
    private let model: (any LanguageModel)?

    init(model: (any LanguageModel)?) {
        self.model = model
    }

    var isDemo: Bool {
        model == nil
    }

    var modelName: String {
        isDemo ? "Demo" : "Claude"
    }

    var stops: [Stop] {
        var stops: [Stop] = []
        for stop in draft?.stops ?? [] {
            guard let name = stop.name, let placeID = stop.placeID, let item = catalog?.items[placeID] else { continue }
            stops.append(Stop(id: stop.id, number: stops.count + 1, name: name, coordinate: item.location.coordinate))
        }
        return stops
    }

    func build(_ request: String, in area: Area, minutes: Int) async throws {
        reset()
        guard let model else { return try await playDemo() }
        let catalog = PlaceCatalog(center: area.center)
        self.catalog = catalog
        plan = try await TourPlanner(model: model, catalog: catalog).plan(request, in: area.name, minutes: minutes) { draft = $0 }
    }

    func reset() {
        draft = nil
        plan = nil
        catalog = nil
    }

    private func playDemo() async throws {
        catalog = DemoTour.catalog()
        let full = DemoTour.plan.asPartiallyGenerated()
        for count in 0...DemoTour.plan.stops.count {
            var draft = full
            draft.stops = full.stops.map { Array($0.prefix(count)) }
            self.draft = draft
            try await Task.sleep(for: .seconds(0.4))
        }
        plan = DemoTour.plan
    }
}
