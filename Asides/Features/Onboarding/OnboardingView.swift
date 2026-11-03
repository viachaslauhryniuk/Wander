import CoreLocation
import MapKit
import SwiftUI

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool

    private static let locationManager = CLLocationManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(initialPosition: .camera(MapCamera(centerCoordinate: DemoTour.center.coordinate, distance: 3000)), interactionModes: [])
                .phaseAnimator([false, true]) { map, moved in
                    map
                        .scaleEffect(1.12)
                        .offset(x: moved ? -18 : 0, y: moved ? -26 : 0)
                } animation: { _ in
                    .easeInOut(duration: 10)
                }
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Image(.logoTile)
                        .resizable()
                        .frame(width: 44, height: 44)
                    Text("Asides")
                        .font(.title3.bold())
                }

                Text("Every street has an aside")
                    .font(.largeTitle.bold())
                    .tracking(-0.68)

                VStack(alignment: .leading, spacing: 16) {
                    row("sparkle", "Say what you love and get a real route.")
                    row("headphones", "A story at every stop. Ask the guide anything.")
                    row("lock.fill", "Claude sees your request, never your exact location.")
                }

                VStack(spacing: 10) {
                    Button {
                        Self.locationManager.requestWhenInUseAuthorization()
                        withAnimation {
                            hasOnboarded = true
                        }
                    } label: {
                        Text("Get started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)

                    Text("Next, iOS will ask to use your location.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(EdgeInsets(top: 28, leading: 22, bottom: 20, trailing: 22))
            .glassEffect(in: .rect(corners: .concentric(minimum: .fixed(42))))
            .padding(10)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.accentText)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12), in: .circle)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
