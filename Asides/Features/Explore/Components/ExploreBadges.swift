import SwiftUI

struct ExploreBadges: View {
    let place: String?
    let isDemo: Bool
    @State private var isDemoInfoShown = false

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                if let place {
                    badge(Label(place, systemImage: "mappin"))
                        .glassEffect(in: .capsule)
                }
                if isDemo {
                    Button {
                        isDemoInfoShown = true
                    } label: {
                        badge(Label("Demo", systemImage: "info.circle"))
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isDemoInfoShown) {
                        demoInfo
                    }
                }
            }
        }
        .padding([.horizontal, .top], 16)
    }

    private var demoInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Demo mode")
                .font(.headline)
            Text("This build isn't connected to an AI model, so instead of planning a walk it shows one written in advance. Whatever you ask for, you get the same seven stops through Warsaw's Old Town.")
            Text("Connect the Worker, and Claude plans a new walk around you.")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(20)
        .frame(width: 300)
        .presentationCompactAdaptation(.popover)
    }

    private func badge(_ content: some View) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .frame(height: 44)
    }
}
