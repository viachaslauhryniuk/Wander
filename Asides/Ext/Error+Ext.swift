import Foundation
import FoundationModels
import MapKit

extension Error {
    var message: String {
        switch self as any Error {
        case let error as URLError where [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dataNotAllowed].contains(error.code):
            "No connection. Check your internet and try again."
        case LanguageModelError.rateLimited:
            "Too many requests. Try again in a minute."
        case LanguageModelError.refusal:
            "The guide can't help with that. Try rephrasing your request."
        case TourPlanError.tooFewPlaces:
            "There aren't enough good places nearby. Try a broader request or another area."
        case MKError.placemarkNotFound:
            "Couldn't find that place. Try another name."
        default:
            "Something went wrong. Try again."
        }
    }
}
