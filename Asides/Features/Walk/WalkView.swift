import MapKit
import SwiftUI

struct WalkView: View {
    @Bindable var viewModel: WalkViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Map(position: $viewModel.position) {
            UserAnnotation()
            MapPolyline(coordinates: viewModel.session.line)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            ForEach(viewModel.stops) { stop in
                Marker(stop.name, monogram: Text("\(stop.number)"), coordinate: stop.coordinate)
                    .tint(stop.number <= viewModel.next ? Color.gray : Color.accentColor)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapPitchToggle()
        }
        .safeAreaInset(edge: .top) {
            NextStopCard(viewModel: viewModel)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StoryPlayer(viewModel: viewModel) {
                viewModel.end()
                dismiss()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(item: $viewModel.reading) { stop in
            StoryView(viewModel: viewModel, stop: stop)
        }
        .task {
            await viewModel.track()
        }
    }
}
