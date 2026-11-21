import SwiftUI

struct NextStopCard: View {
    let viewModel: WalkViewModel

    private var subtitle: String {
        guard viewModel.nextStop != nil else { return "Walk complete" }
        guard let distance = viewModel.distance else { return "Next" }
        let meters = Measurement(value: distance, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road))
        return "Next · \(meters) · \(Int((distance / 80).rounded(.up))) min"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.nextStop == nil ? "checkmark" : "figure.walk")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.tint, in: .circle)
            VStack(alignment: .leading, spacing: 3) {
                Text(subtitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(viewModel.nextStop?.name ?? "That was the last stop")
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(viewModel.nextStop?.number ?? viewModel.stops.count) / \(viewModel.stops.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 18)
        .frame(height: 76)
        .glassEffect(in: .capsule)
        .padding(.horizontal, 10)
    }
}
