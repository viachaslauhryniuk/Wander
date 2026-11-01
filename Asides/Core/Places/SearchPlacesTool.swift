import FoundationModels

struct SearchPlacesTool: Tool {
    let name = "search_places"
    let description = "Finds real places within about 1.5 km of the starting point. Each line starts with the place's short id."
    let catalog: PlaceCatalog

    @Generable struct Arguments {
        @Guide(description: "What to look for, like baroque church or specialty coffee") var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        try await catalog.search(arguments.query)
    }
}
