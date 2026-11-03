import ClaudeLanguageModel
import Foundation
import FoundationModels
import UIKit

enum ModelProvider {
    static let model: (any LanguageModel)? = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "WorkerURL") as? String, let url = URL(string: value) else { return nil }
        return ClaudeLanguageModel(endpoint: url, installID: UIDevice.current.identifierForVendor?.uuidString ?? "unknown")
    }()
}
