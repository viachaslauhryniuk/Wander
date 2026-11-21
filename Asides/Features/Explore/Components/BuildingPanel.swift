import SwiftUI

struct BuildingPanel: View {
    let viewModel: ExploreViewModel

    private var session: TourSession {
        viewModel.session
    }

    private var isFinished: Bool {
        session.plan != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            heading
            list
            if !isFinished {
                Label("Checking real places in Apple Maps…", systemImage: "mappin")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(EdgeInsets(top: 22, leading: 22, bottom: 24, trailing: 22))
        .glassEffect(.regular.tint(Color.paper.opacity(0.72)), in: .rect(corners: .concentric(minimum: .fixed(42))))
        .padding(8)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .foregroundStyle(.tint)
            Text("Building your walk")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentText)
            Spacer()
            Label("Claude", systemImage: "cloud")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(Color.primary.opacity(0.06), in: .capsule)
            Button(action: viewModel.stop) {
                Text("Stop")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.draft?.title ?? "Your walk")
                .font(.title.bold())
                .tracking(-0.56)
                .skeleton(session.draft?.title == nil)
                .contentTransition(.identity)
            Text(session.draft?.subtitle ?? "A few words about the walk ahead")
                .foregroundStyle(.secondary)
                .skeleton(session.draft?.subtitle == nil)
                .contentTransition(.identity)
        }
    }

    private var list: some View {
        var names: [String?] = session.stops.map(\.name)
        if !isFinished {
            names.append(nil)
        }
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(names.indices, id: \.self) { index in
                row(index + 1, name: names[index])
            }
        }
    }

    private func row(_ number: Int, name: String?) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.footnote.bold())
                .foregroundStyle(name == nil ? Color.accentText : .white)
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .strokeBorder(.tint, style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                    Circle()
                        .fill(.tint)
                        .scaleEffect(name == nil ? 0 : 1)
                }
            Text(name ?? "A place nearby")
                .font(.callout.weight(.medium))
                .skeleton(name == nil)
            Spacer()
            if name != nil {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
    }
}
