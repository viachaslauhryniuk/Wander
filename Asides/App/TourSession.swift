import FoundationModels
import MapKit
import Observation

@Observable
final class TourSession {
    struct Stop: Identifiable {
        let id: GenerationID
        let placeID: String
        let number: Int
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    private(set) var draft: TourPlan.PartiallyGenerated?
    private(set) var plan: TourPlan?
    private(set) var route: WalkingRoute?
    let model: any LanguageModel
    private var catalog: PlaceCatalog?

    init(model: any LanguageModel) {
        self.model = model
    }

    var line: [CLLocationCoordinate2D] {
        route?.coordinates ?? stops.map(\.coordinate)
    }

    var stops: [Stop] {
        var stops: [Stop] = []
        for stop in draft?.stops ?? [] {
            guard let name = stop.name, let placeID = stop.placeID, let item = catalog?.items[placeID] else { continue }
            stops.append(Stop(id: stop.id, placeID: placeID, number: stops.count + 1, name: name, coordinate: item.location.coordinate))
        }
        return stops
    }

    func build(_ request: String, in area: Area, minutes: Int) async throws {
        reset()
        let catalog = PlaceCatalog(center: area.center)
        self.catalog = catalog
        let plan = try await TourPlanner(model: model, catalog: catalog).plan(request, in: area.name, minutes: minutes) { await reveal($0) }
        self.plan = plan
        let route = try? await WalkingRoute(through: plan.stops.compactMap { catalog.items[$0.placeID] })
        try Task.checkCancellation()
        self.route = route
    }

    private func reveal(_ draft: TourPlan.PartiallyGenerated) async {
        for index in (self.draft?.stops?.count ?? 0)..<(draft.stops?.count ?? 0) {
            if index > 0 {
                try? await Task.sleep(for: .seconds(0.4))
            }
            var partial = draft
            partial.stops = draft.stops.map { Array($0.prefix(index + 1)) }
            self.draft = partial
        }
        self.draft = draft
    }

    func reset() {
        draft = nil
        plan = nil
        route = nil
        catalog = nil
    }
}
