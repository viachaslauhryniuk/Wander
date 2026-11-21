import MapKit
import SwiftUI

struct OverviewSheet: View {
    let viewModel: ExploreViewModel

    private var route: WalkingRoute? {
        viewModel.session.route
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let plan = viewModel.session.plan {
                    VStack(alignment: .leading, spacing: 24) {
                        header(plan)
                        stops(plan)
                    }
                    .padding(EdgeInsets(top: 28, leading: 22, bottom: 16, trailing: 22))
                }
            }
            Button {
            } label: {
                Label("Start walk", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .padding(16)
        }
        .presentationBackground(Color.paper)
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .interactiveDismissDisabled()
    }

    private func header(_ plan: TourPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let place = viewModel.area?.name {
                Text("Walking tour · \(place)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.7)
                    .foregroundStyle(Color.accentText)
            }
            Text(plan.title)
                .font(.title.bold())
                .tracking(-0.56)
            Text(plan.subtitle)
                .foregroundStyle(.secondary)
            if let route {
                HStack(spacing: 14) {
                    Label(Duration.seconds(route.minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)), systemImage: "figure.walk")
                    Label(Measurement(value: route.kilometers, unit: UnitLength.kilometers).formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(1)))), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            }
        }
    }

    private func stops(_ plan: TourPlan) -> some View {
        let legs = route?.legs ?? []
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(plan.stops.enumerated()), id: \.element.placeID) { index, stop in
                VStack(alignment: .leading, spacing: 0) {
                    row(stop, number: index + 1)
                    if index < plan.stops.count - 1 {
                        walk(index < legs.count ? legs[index] : nil)
                    }
                }
            }
        }
    }

    private func row(_ stop: PlannedStop, number: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.footnote.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.tint, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.name)
                    .font(.callout.weight(.semibold))
                Text(stop.hook)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func walk(_ leg: MKRoute?) -> some View {
        HStack(spacing: 12) {
            Path { path in
                path.move(to: CGPoint(x: 14, y: 4))
                path.addLine(to: CGPoint(x: 14, y: 28))
            }
            .stroke(.tint.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0, 6]))
            .frame(width: 28, height: 32)
            if let leg {
                Text("\(Int((leg.expectedTravelTime / 60).rounded(.up))) min walk")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
