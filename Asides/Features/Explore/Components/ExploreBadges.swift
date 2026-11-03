import SwiftUI

struct ExploreBadges: View {
    let place: String?
    let isDemo: Bool

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                if let place {
                    badge(Label(place, systemImage: "mappin"))
                }
                if isDemo {
                    badge(Text("Demo"))
                }
            }
        }
        .padding([.horizontal, .top], 16)
    }

    private func badge(_ content: some View) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .frame(height: 44)
            .glassEffect(in: .capsule)
    }
}
