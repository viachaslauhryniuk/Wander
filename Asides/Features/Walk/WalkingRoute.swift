@preconcurrency import MapKit

struct WalkingRoute {
    let legs: [MKRoute]

    var minutes: Int {
        Int((legs.reduce(0) { $0 + $1.expectedTravelTime } / 60).rounded())
    }

    var kilometers: Double {
        legs.reduce(0) { $0 + $1.distance } / 1000
    }

    var coordinates: [CLLocationCoordinate2D] {
        legs.flatMap { UnsafeBufferPointer(start: $0.polyline.points(), count: $0.polyline.pointCount).map(\.coordinate) }
    }

    init(through stops: [MKMapItem]) async throws {
        var legs: [MKRoute] = []
        for (from, to) in zip(stops, stops.dropFirst()) {
            let request = MKDirections.Request()
            request.source = from
            request.destination = to
            request.transportType = .walking
            guard let leg = try await MKDirections(request: request).calculate().routes.first else {
                throw MKError(.directionsNotFound)
            }
            legs.append(leg)
        }
        self.legs = legs
    }
}
