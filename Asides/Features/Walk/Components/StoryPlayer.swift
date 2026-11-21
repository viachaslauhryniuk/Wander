import SwiftUI

struct StoryPlayer: View {
    let viewModel: WalkViewModel
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.hasArrived ? "Now playing · stop \(viewModel.playerStop?.number ?? 1)" : "First stop")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.7)
                    .foregroundStyle(Color.accentText)
                Text(viewModel.headline ?? "A story about this place")
                    .font(.title3.bold())
                    .skeleton(viewModel.headline == nil)
                Text(viewModel.playerStop?.name ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button("End walk", systemImage: "stop.fill", action: onEnd)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                Spacer()
                Button(viewModel.narrator.isPlaying ? "Pause" : "Play", systemImage: viewModel.narrator.isPlaying ? "pause.fill" : "play.fill") {
                    if let story = viewModel.story {
                        viewModel.narrator.toggle(story)
                    }
                }
                .labelStyle(.iconOnly)
                .font(.title3)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.extraLarge)
                .disabled(viewModel.story == nil)
                Button("Next stop", systemImage: "forward.end.fill", action: viewModel.arrive)
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .disabled(viewModel.nextStop == nil)
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        .glassEffect(in: .rect(corners: .concentric(minimum: .fixed(42))))
        .padding(8)
    }
}
