import ClaudeLanguageModel
import Foundation
import FoundationModels
import UIKit

enum ModelProvider {
    static let workerURL: URL = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "WorkerURL") as? String, let url = URL(string: value) else {
            fatalError("Set WORKER_URL in Secrets.xcconfig")
        }
        return url
    }()

    static let installID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

    static let model: any LanguageModel = ClaudeLanguageModel(endpoint: workerURL, installID: installID)
}
