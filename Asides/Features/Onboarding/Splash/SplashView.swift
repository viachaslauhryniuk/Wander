import Lottie
import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.launchBackground
            LottieView(animation: .named("splash"))
                .playing(loopMode: .playOnce)
                .frame(width: 112, height: 112)
        }
        .ignoresSafeArea()
    }
}
