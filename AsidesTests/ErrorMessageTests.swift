import Foundation
import FoundationModels
import MapKit
import Testing
@testable import Asides

@Test func errorsMapToReadableMessages() {
    #expect(URLError(.notConnectedToInternet).message == "No connection. Check your internet and try again.")
    #expect(LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "")).message == "Too many requests. Try again in a minute.")
    #expect(TourPlanError.tooFewPlaces.message == "There aren't enough good places nearby. Try a broader request or another area.")
    #expect(MKError(.placemarkNotFound).message == "Couldn't find that place. Try another name.")
    #expect(CancellationError().message == "Something went wrong. Try again.")
}
