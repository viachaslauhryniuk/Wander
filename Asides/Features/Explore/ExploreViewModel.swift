import MapKit
import Observation
import SwiftUI

@Observable
final class ExploreViewModel {
    let session: TourSession
    var text = ""
    var topics: Set<String> = []
    var position: MapCameraPosition
    var isOverviewShown = false
    private(set) var hours = 2
    private(set) var area: Area?
    private(set) var isBuilding = false
    private var buildTask: Task<Void, Never>?

    init(session: TourSession) {
        self.session = session
        position = .userLocation(fallback: .automatic)
    }

    var request: String {
        [text.trimmingCharacters(in: .whitespacesAndNewlines), topics.sorted().joined(separator: ", ")]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var canSend: Bool {
        area != nil && !request.isEmpty
    }

    var line: [CLLocationCoordinate2D] {
        session.route?.coordinates ?? session.stops.map(\.coordinate)
    }

    var durationTitle: String {
        hours == 1 ? "1 hour" : "\(hours) hours"
    }

    func nextDuration() {
        hours = hours % 3 + 1
    }

    func loadArea() async {
        area = try? await Area.current()
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
                isBuilding = false
                isOverviewShown = true
                showRoute()
            } catch {
                if !Task.isCancelled { stop() }
            }
        }
    }

    func stop() {
        buildTask?.cancel()
        isBuilding = false
        session.reset()
        if let area {
            withAnimation {
                position = Self.overview(of: area)
            }
        }
    }

    private func showRoute() {
        var rect = MKPolyline(coordinates: line, count: line.count).boundingMapRect
        rect = rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
        rect.size.height *= 2
        withAnimation {
            position = .rect(rect)
        }
    }

    private static func overview(of area: Area) -> MapCameraPosition {
        .camera(MapCamera(centerCoordinate: area.center.coordinate, distance: 9000))
    }
}
