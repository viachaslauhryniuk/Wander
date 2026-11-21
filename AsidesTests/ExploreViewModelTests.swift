import Testing
@testable import Asides

@Test @MainActor func demoLoadsTheDemoArea() async {
    let viewModel = ExploreViewModel(session: TourSession(model: nil))

    await viewModel.loadArea()

    #expect(viewModel.area?.name == DemoTour.neighborhood)
}

@Test @MainActor func requestJoinsTextAndTopics() {
    let viewModel = ExploreViewModel(session: TourSession(model: nil))
    viewModel.text = "  old churches \n"
    viewModel.topics = ["Viewpoints", "No crowds"]

    #expect(viewModel.request == "old churches\nNo crowds, Viewpoints")
}
