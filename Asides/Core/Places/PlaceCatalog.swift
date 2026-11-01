import MapKit

final class PlaceCatalog {
    private(set) var items: [String: MKMapItem] = [:]
    private let center: CLLocation

    init(center: CLLocation) {
        self.center = center
    }

    func search(_ query: String) async throws -> String {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: center.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
        request.regionPriority = .required

        let found: [MKMapItem]
        do {
            found = try await MKLocalSearch(request: request).start().mapItems
        } catch MKError.placemarkNotFound {
            found = []
        }
        guard !found.isEmpty else { return "No places found" }
        return found.prefix(10).map(line).joined(separator: "\n")
    }

    private func line(for item: MKMapItem) -> String {
        let category = item.pointOfInterestCategory?.rawValue.replacing("MKPOICategory", with: "") ?? "Place"
        let distance = Int(item.location.distance(from: center))
        return "\(id(for: item)) \(item.name ?? "Unnamed"), \(category), \(distance) m"
    }

    func id(for item: MKMapItem) -> String {
        if let known = items.first(where: { isSame($0.value, item) }) { return known.key }
        let id = "p\(items.count + 1)"
        items[id] = item
        return id
    }

    private func isSame(_ a: MKMapItem, _ b: MKMapItem) -> Bool {
        if let identifier = a.identifier, identifier == b.identifier { return true }
        return a.name == b.name && a.location.distance(from: b.location) < 20
    }
}
