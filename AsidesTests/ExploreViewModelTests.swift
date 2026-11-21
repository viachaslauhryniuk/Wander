import Testing
@testable import Asides

@Test @MainActor func requestJoinsTextAndTopics() {
    let viewModel = ExploreViewModel(session: TourSession(model: ScriptedModel(executorConfiguration: [])))
    viewModel.text = "  old churches \n"
    viewModel.topics = ["Viewpoints", "No crowds"]

    #expect(viewModel.request == "old churches\nNo crowds, Viewpoints")
}
