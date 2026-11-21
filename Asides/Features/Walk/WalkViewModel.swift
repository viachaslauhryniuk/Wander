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
    var reading: TourSession.Stop?
    var chat: GuideChat?
    private(set) var scene: MKLookAroundScene?
    private(set) var next = 0
    private(set) var location: CLLocation?
    private let plan: TourPlan
    private let neighborhood: String

    init(session: TourSession, plan: TourPlan, neighborhood: String) {
        self.session = session
        self.plan = plan
        self.neighborhood = neighborhood
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

    var audio: URL? {
        playerStop.flatMap { writer.audio[$0.placeID] }
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
        if let audio {
            narrator.play(audio)
        } else {
            narrator.stop()
        }
        if let playerStop {
            read(playerStop)
        }
    }

    func read(_ stop: TourSession.Stop) {
        reading = stop
        scene = nil
        Task {
            scene = try? await MKLookAroundSceneRequest(coordinate: stop.coordinate).scene
        }
    }

    func ask(about stop: TourSession.Stop) {
        guard let story = writer.stories[stop.placeID], let planned = plan.stops.first(where: { $0.placeID == stop.placeID }), let catalog = session.catalog else { return }
        chat = GuideChat(model: session.model, stop: planned, story: story, neighborhood: neighborhood, catalog: catalog)
    }

    func end() {
        narrator.stop()
    }
}
