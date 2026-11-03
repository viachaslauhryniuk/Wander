import MapKit
import SwiftUI

struct ExploreView: View {
    @State private var viewModel: ExploreViewModel

    init(isDemo: Bool) {
        viewModel = ExploreViewModel(isDemo: isDemo)
    }

    var body: some View {
        Map(initialPosition: viewModel.initialPosition) {
            if !viewModel.isDemo {
                UserAnnotation()
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
            WalkPanel(viewModel: viewModel)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .overlay(alignment: .topLeading) {
            ExploreBadges(place: viewModel.area?.name, isDemo: viewModel.isDemo)
        }
        .task {
            await viewModel.loadArea()
        }
    }
}
