import CoreLocation
import MapKit

struct Area {
    let name: String
    let center: CLLocation

    static func current() async throws -> Area? {
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationDeniedGlobally { return nil }
            guard let location = update.location else { continue }
            let name = try? await MKReverseGeocodingRequest(location: location)?.mapItems.first?.addressRepresentations?.cityWithContext
            return Area(name: name ?? "Nearby", center: location)
        }
        return nil
    }

    static func named(_ query: String) async throws -> Area {
        guard let item = try await MKGeocodingRequest(addressString: query)?.mapItems.first else {
            throw MKError(.placemarkNotFound)
        }
        return Area(name: item.name ?? query, center: item.location)
    }
}
