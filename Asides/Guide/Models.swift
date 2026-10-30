import FoundationModels

@Generable struct TourPlan {
    @Guide(description: "Evocative title, at most 4 words") var title: String
    @Guide(description: "One-line subtitle") var subtitle: String
    @Guide(description: "Stops in walking order, 3 to 8") var stops: [PlannedStop]
}

@Generable struct PlannedStop {
    @Guide(description: "Short place id from search_places, like p3") var placeID: String
    var name: String
    @Guide(description: "One-sentence hook, under 12 words") var hook: String
}

@Generable struct Story {
    var headline: String
    @Guide(description: "2 to 4 short paragraphs") var paragraphs: [String]
    @Guide(description: "One concrete thing to look for on site") var lookFor: String
}
