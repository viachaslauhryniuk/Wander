import AVFoundation
import SwiftUI

@main
struct AsidesApp: App {
    init() {
        AVPlayer.isObservationEnabled = true
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
