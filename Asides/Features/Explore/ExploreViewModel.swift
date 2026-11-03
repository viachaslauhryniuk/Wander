import MapKit
import Observation
import SwiftUI

@Observable
final class ExploreViewModel {
    let isDemo: Bool
    var text = ""
    var topics: Set<String> = []
    private(set) var hours = 2
    private(set) var area: Area?

    init(isDemo: Bool) {
        self.isDemo = isDemo
    }

    var canSend: Bool {
        !text.allSatisfy(\.isWhitespace) || !topics.isEmpty
    }

    var durationTitle: String {
        hours == 1 ? "1 hour" : "\(hours) hours"
    }

    var initialPosition: MapCameraPosition {
        guard isDemo else { return .userLocation(fallback: .automatic) }
        return .camera(MapCamera(centerCoordinate: Area.demo.center.coordinate, distance: 3000))
    }

    func nextDuration() {
        hours = hours % 3 + 1
    }

    func loadArea() async {
        area = isDemo ? .demo : try? await Area.current()
    }
}
