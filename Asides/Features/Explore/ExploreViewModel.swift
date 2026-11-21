import MapKit
import Observation
import SwiftUI

@Observable
final class ExploreViewModel {
    let session: TourSession
    var text = ""
    var topics: Set<String> = []
    var position: MapCameraPosition
    private(set) var hours = 2
    private(set) var area: Area?
    private(set) var isBuilding = false
    private var buildTask: Task<Void, Never>?

    init(session: TourSession) {
        self.session = session
        position = session.isDemo ? Self.overview(of: .demo) : .userLocation(fallback: .automatic)
    }

    var isDemo: Bool {
        session.isDemo
    }

    var request: String {
        [text.trimmingCharacters(in: .whitespacesAndNewlines), topics.sorted().joined(separator: ", ")]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var canSend: Bool {
        area != nil && !request.isEmpty
    }

    var durationTitle: String {
        hours == 1 ? "1 hour" : "\(hours) hours"
    }

    func nextDuration() {
        hours = hours % 3 + 1
    }

    func loadArea() async {
        area = isDemo ? .demo : try? await Area.current()
        if let area {
            withAnimation {
                position = Self.overview(of: area)
            }
        }
    }

    func send() {
        guard canSend, let area else { return }
        isBuilding = true
        buildTask = Task {
            do {
                try await session.build(request, in: area, minutes: hours * 60)
            } catch {
                if !Task.isCancelled { stop() }
            }
        }
    }

    func stop() {
        buildTask?.cancel()
        isBuilding = false
        session.reset()
    }

    private static func overview(of area: Area) -> MapCameraPosition {
        .camera(MapCamera(centerCoordinate: area.center.coordinate, distance: 9000))
    }
}
