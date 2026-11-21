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
    private(set) var route: WalkingRoute?
    private var catalog: PlaceCatalog?
    private let model: any LanguageModel

    init(model: any LanguageModel) {
        self.model = model
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
        let catalog = PlaceCatalog(center: area.center)
        self.catalog = catalog
        let plan = try await TourPlanner(model: model, catalog: catalog).plan(request, in: area.name, minutes: minutes) { draft = $0 }
        self.plan = plan
        let route = try? await WalkingRoute(through: plan.stops.compactMap { catalog.items[$0.placeID] })
        try Task.checkCancellation()
        self.route = route
    }

    func reset() {
        draft = nil
        plan = nil
        route = nil
        catalog = nil
    }
}
