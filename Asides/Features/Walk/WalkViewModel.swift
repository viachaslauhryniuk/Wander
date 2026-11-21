import CoreLocation
import MapKit
import Observation
import SwiftUI

@Observable
final class WalkViewModel: Identifiable {
    let session: TourSession
    let writer: StoryWriter
    let narrator = Narrator()
    var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    private(set) var next = 0
    private(set) var location: CLLocation?

    init(session: TourSession, plan: TourPlan, neighborhood: String) {
        self.session = session
        writer = StoryWriter(model: session.model, plan: plan, neighborhood: neighborhood)
        writer.prepare(stop: 0)
    }

    var stops: [TourSession.Stop] {
        session.stops
    }

    var nextStop: TourSession.Stop? {
        stops.indices.contains(next) ? stops[next] : nil
    }

    var playerStop: TourSession.Stop? {
        stops.indices.contains(next - 1) ? stops[next - 1] : stops.first
    }

    var hasArrived: Bool {
        next > 0
    }

    var story: Story? {
        playerStop.flatMap { writer.stories[$0.placeID] }
    }

    var headline: String? {
        story?.headline ?? playerStop.flatMap { writer.drafts[$0.placeID]?.headline }
    }

    var distance: CLLocationDistance? {
        guard let location, let nextStop else { return nil }
        return location.distance(from: CLLocation(latitude: nextStop.coordinate.latitude, longitude: nextStop.coordinate.longitude))
    }

    func track() async {
        let background = CLBackgroundActivitySession()
        defer { background.invalidate() }
        do {
            for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                guard let location = update.location else { continue }
                self.location = location
                if let distance, distance < 40 {
                    arrive()
                }
            }
        } catch {}
    }

    func arrive() {
        guard nextStop != nil else { return }
        next += 1
        writer.prepare(stop: next)
        if let story {
            narrator.read(story)
        }
    }

    func end() {
        narrator.stop()
    }
}
