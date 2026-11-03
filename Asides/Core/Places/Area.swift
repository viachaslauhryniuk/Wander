import CoreLocation
import MapKit

struct Area {
    let name: String
    let center: CLLocation

    static let demo = Area(name: DemoTour.neighborhood, center: DemoTour.center)

    static func current() async throws -> Area? {
        for try await update in CLLocationUpdate.liveUpdates() {
            guard let location = update.location else { continue }
            let name = try? await MKReverseGeocodingRequest(location: location)?.mapItems.first?.addressRepresentations?.cityWithContext
            return Area(name: name ?? "Nearby", center: location)
        }
        return nil
    }
}
