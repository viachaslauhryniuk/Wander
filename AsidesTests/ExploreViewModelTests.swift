import Testing
@testable import Asides

@Test @MainActor func demoLoadsTheDemoArea() async {
    let viewModel = ExploreViewModel(isDemo: true)

    await viewModel.loadArea()

    #expect(viewModel.area?.name == DemoTour.neighborhood)
}
