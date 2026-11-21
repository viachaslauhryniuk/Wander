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
    var walk: WalkViewModel?
    var error: (any Error)?
    var isChoosingArea = false
    var areaQuery = ""
    private(set) var isLocationDenied = false
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

    var durationTitle: String {
        hours == 1 ? "1 hour" : "\(hours) hours"
    }

    func nextDuration() {
        hours = hours % 3 + 1
    }

    func loadArea() async {
        area = try? await Area.current()
        isLocationDenied = area == nil
        if let area {
            withAnimation {
                position = Self.overview(of: area)
            }
        }
    }

    func chooseArea() {
        let query = areaQuery
        Task {
            do {
                let area = try await Area.named(query)
                self.area = area
                withAnimation {
                    position = Self.overview(of: area)
                }
            } catch {
                self.error = error
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
                if !Task.isCancelled {
                    self.error = error
                    stop()
                }
            }
        }
    }

    func startWalk() {
        guard let plan = session.plan, let area else { return }
        walk = WalkViewModel(session: session, plan: plan, neighborhood: area.name)
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
        let line = session.line
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
