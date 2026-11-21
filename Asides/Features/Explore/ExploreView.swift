import MapKit
import SwiftUI

struct ExploreView: View {
    @State private var viewModel: ExploreViewModel
    @Namespace private var glass

    init(session: TourSession) {
        viewModel = ExploreViewModel(session: session)
    }

    var body: some View {
        Map(position: $viewModel.position) {
            if !viewModel.isDemo {
                UserAnnotation()
            }
            MapPolyline(coordinates: viewModel.line)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            ForEach(viewModel.session.stops) { stop in
                Marker(stop.name, monogram: Text("\(stop.number)"), coordinate: stop.coordinate)
                    .tint(Color.accentColor)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapPitchToggle()
            if !viewModel.isDemo {
                MapUserLocationButton()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GlassEffectContainer {
                if viewModel.isBuilding {
                    BuildingPanel(viewModel: viewModel)
                        .glassEffectID("panel", in: glass)
                } else if !viewModel.isOverviewShown {
                    WalkPanel(viewModel: viewModel)
                        .glassEffectID("panel", in: glass)
                }
            }
            .animation(.smooth, value: viewModel.isBuilding)
            .animation(.smooth, value: viewModel.session.draft?.title)
            .animation(.smooth, value: viewModel.session.draft?.subtitle)
            .animation(.smooth, value: viewModel.session.stops.count)
            .animation(.smooth, value: viewModel.session.plan == nil)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .overlay(alignment: .topLeading) {
            if viewModel.isOverviewShown {
                Button("Back", systemImage: "chevron.left") {
                    viewModel.isOverviewShown = false
                }
                    .labelStyle(.iconOnly)
                    .fontWeight(.semibold)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .padding([.horizontal, .top], 16)
            } else {
                ExploreBadges(place: viewModel.area?.name, isDemo: viewModel.isDemo)
            }
        }
        .sheet(isPresented: $viewModel.isOverviewShown, onDismiss: viewModel.stop) {
            OverviewSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadArea()
        }
    }
}
