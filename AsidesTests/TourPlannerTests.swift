import FoundationModels
import MapKit
import Testing
@testable import Asides

@Test @MainActor func plannerDropsStopsOutsideTheCatalog() async throws {
    let planner = TourPlanner(model: ScriptedModel(executorConfiguration: ["p1", "p9", "p2", "p3"]), catalog: threePlaces())

    let plan = try await planner.plan("churches", in: "Stare Miasto", minutes: 60)

    #expect(plan.stops.map(\.placeID) == ["p1", "p2", "p3"])
    #expect(planner.draft?.title == "Old Town")
}

@Test @MainActor func plannerFailsWithFewerThanThreeRealStops() async {
    let planner = TourPlanner(model: ScriptedModel(executorConfiguration: ["p1", "p9", "p2"]), catalog: threePlaces())

    await #expect(throws: TourPlanError.self) {
        try await planner.plan("churches", in: "Stare Miasto", minutes: 60)
    }
}

@MainActor private func threePlaces() -> PlaceCatalog {
    let catalog = PlaceCatalog(center: CLLocation(latitude: 52.2476, longitude: 21.0136))
    for index in 1...3 {
        let item = MKMapItem(location: CLLocation(latitude: 52.2476, longitude: 21.0136), address: nil)
        item.name = "Place \(index)"
        _ = catalog.id(for: item)
    }
    return catalog
}

private struct ScriptedModel: LanguageModel {
    let capabilities = LanguageModelCapabilities([.toolCalling, .guidedGeneration])
    let executorConfiguration: [String]

    struct Executor: LanguageModelExecutor {
        let stops: [String]

        init(configuration: [String]) {
            stops = configuration
        }

        nonisolated(nonsending) func respond(to request: LanguageModelExecutorGenerationRequest, model: ScriptedModel, streamingInto channel: LanguageModelExecutorGenerationChannel) async throws {
            let stopsJSON = stops.map { #"{"placeID":"\#($0)","name":"Stop","hook":"Look up"}"# }.joined(separator: ",")
            await channel.send(.response(action: .appendText(#"{"title":"Old Town","subtitle":"A short walk","#, tokenCount: 1)))
            await channel.send(.response(action: .appendText(#""stops":[\#(stopsJSON)]}"#, tokenCount: 1)))
        }
    }
}
