import SwiftUI

struct WalkPanel: View {
    @Bindable var viewModel: ExploreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading
            chips
            field
        }
        .padding(EdgeInsets(top: 24, leading: 18, bottom: 18, trailing: 18))
        .glassEffect(.regular.tint(Color.paper.opacity(0.72)), in: .rect(corners: .concentric(minimum: .fixed(42))))
        .padding(8)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Where shall we walk today?")
                .font(.title.bold())
                .tracking(-0.56)
            Text("Say how long you have, what you love, and what to skip.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Chip(title: viewModel.durationTitle, symbol: "clock", isOn: true) {
                    viewModel.nextDuration()
                }
                Chip("Viewpoints", selection: $viewModel.topics)
                Chip("No crowds", selection: $viewModel.topics)
            }
            HStack(spacing: 8) {
                Chip("Architecture", selection: $viewModel.topics)
                Chip("Coffee stops", selection: $viewModel.topics)
            }
        }
    }

    private var field: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle")
                .foregroundStyle(.tint)
            TextField("Describe your walk", text: $viewModel.text)
                .submitLabel(.go)
            Button {
            } label: {
                Image(systemName: "arrow.up")
                    .fontWeight(.semibold)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .disabled(!viewModel.canSend)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(height: 56)
        .background(Color.primary.opacity(0.06), in: .capsule)
    }
}
