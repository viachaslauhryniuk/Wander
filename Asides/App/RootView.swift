import MapKit
import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var isSplashShown = true

    var body: some View {
        ZStack {
            if hasOnboarded {
                Map()
            } else {
                OnboardingView(hasOnboarded: $hasOnboarded)
            }
            if isSplashShown {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.easeOut(duration: 0.4)) {
                isSplashShown = false
            }
        }
    }
}
