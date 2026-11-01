import MapKit

enum DemoTour {
    static let neighborhood = "Stare Miasto, Warsaw"
    static let center = CLLocation(latitude: 52.24981, longitude: 21.01215)

    static let plan = TourPlan(
        title: "Warsaw Rebuilt From Memory",
        subtitle: "From the Royal Route to the New Town, through a city that came back",
        stops: stops.map { PlannedStop(placeID: $0.id, name: $0.name, hook: $0.hook) }
    )

    static let stories = Dictionary(uniqueKeysWithValues: stops.map { ($0.id, $0.story) })

    static func catalog() -> PlaceCatalog {
        let catalog = PlaceCatalog(center: center)
        for stop in stops {
            let item = MKMapItem(location: CLLocation(latitude: stop.latitude, longitude: stop.longitude), address: nil)
            item.name = stop.name
            _ = catalog.id(for: item)
        }
        return catalog
    }

    private struct Stop {
        let id: String
        let name: String
        let hook: String
        let latitude: Double
        let longitude: Double
        let story: Story
    }

    private static let stops = [
        Stop(
            id: "p1",
            name: "Pomnik Adama Mickiewicza",
            hook: "A poet's statue unveiled in silence on the Royal Route.",
            latitude: 52.24373,
            longitude: 21.01484,
            story: Story(
                headline: "A Monument Unveiled in Silence",
                paragraphs: [
                    "Krakowskie Przedmieście is part of the Royal Route, the old road running south from the castle. Start at the statue of Adam Mickiewicz, Poland's great Romantic poet.",
                    "Warsaw was under Russian rule when this monument went up. It was unveiled on 24 December 1898, the hundredth anniversary of the poet's birth, in front of about 12,000 people. There were no speeches. The crowd stood in silence.",
                    "The Germans destroyed the statue during the Second World War and parts of it were taken to Germany. Some were recovered, and the monument was unveiled a second time in January 1950.",
                ],
                lookFor: "The bronze poet on his tall plinth. Step back until you can see all of him, and picture this street full of silent people."
            )
        ),
        Stop(
            id: "p2",
            name: "Kościół św. Anny",
            hook: "A church saved from sliding down the escarpment in 1949.",
            latitude: 52.24627,
            longitude: 21.01435,
            story: Story(
                headline: "The Church That Almost Slid Away",
                paragraphs: [
                    "St. Anne's was founded in 1454 by Anna, Duchess of Mazovia, for Bernardine friars. It began as a Gothic brick church and changed over the centuries. The neoclassical front you see dates from 1788, the work of Chrystian Piotr Aigner.",
                    "Its closest call came after the war. In April 1949, while the tunnel for the new W-Z Route was being dug below the church, the Vistula escarpment began to slide and the building was in danger of collapse.",
                    "Crews pumped water out of the slope and reinforced the walls, and a retaining wall more than 50 metres long now holds the hillside in place.",
                ],
                lookFor: "The bell tower standing beside the church. It now serves as a viewing terrace, with a view over Castle Square and the Old Town."
            )
        ),
        Stop(
            id: "p3",
            name: "Kolumna Zygmunta III Wazy",
            hook: "A king on a column, toppled in 1944 and raised again.",
            latitude: 52.24728,
            longitude: 21.01328,
            story: Story(
                headline: "The King Who Fell and Rose",
                paragraphs: [
                    "The man on top is Sigismund III Vasa, the king who moved the royal court from Kraków to Warsaw. His son, Władysław IV, put up this column in his honour in 1644.",
                    "During the Warsaw Uprising, on 1 September 1944, German fire brought the column down and badly damaged the bronze statue. In 1949 the repaired king went back up on a new granite column, about 22 metres above the square.",
                ],
                lookFor: "The old column segments lying on the ground at the southwest corner of the Royal Castle. One is the red marble of 1644, the other the granite that replaced it in 1887."
            )
        ),
        Stop(
            id: "p4",
            name: "Zamek Królewski",
            hook: "Its tower clock stopped at 11:15 on 17 September 1939.",
            latitude: 52.24783,
            longitude: 21.01412,
            story: Story(
                headline: "The Clock That Stopped at 11:15",
                paragraphs: [
                    "This was the seat of Polish kings, and the Constitution of 3 May 1791 was drafted here.",
                    "On 17 September 1939 German aircraft set the castle on fire, and the tower clock stopped at 11:15. Museum staff led by Stanisław Lorentz saved what they could of the interiors and the art. After the failed Uprising of 1944, the Germans blew up what was left.",
                    "Rebuilding was approved only in January 1971, and it was paid for almost entirely by donations from Poles at home and abroad. The clock ran again in 1974, with thousands of people there to see it. The interiors opened to the public in 1984.",
                ],
                lookFor: "The clock on the tall tower above the main entrance, the first part of the castle Warsaw got back."
            )
        ),
        Stop(
            id: "p5",
            name: "Rynek Starego Miasta",
            hook: "A square rebuilt from ruins, now a World Heritage Site.",
            latitude: 52.24981,
            longitude: 21.01215,
            story: Story(
                headline: "A Square Rebuilt From Memory",
                paragraphs: [
                    "Nearly everything around you is younger than it looks. More than 85 percent of Warsaw's historic centre was destroyed by Nazi troops during the Uprising of 1944.",
                    "The rebuilders worked from old records, and among the best known were the 18th-century city views painted by Bernardo Bellotto. In 1980 UNESCO listed the centre as a World Heritage Site.",
                    "Each of the four sides of the square has a name: Barss, Dekert, Kołłątaj and Zakrzewski, after notable Poles who once lived there.",
                ],
                lookFor: "The Mermaid in the middle of the square, the symbol of the city. Konstanty Hegel's statue was placed here in 1855. This one is a copy, and the original is in the Museum of Warsaw."
            )
        ),
        Stop(
            id: "p6",
            name: "Barbakan",
            hook: "A brick bastion from the 1500s, rebuilt after the war.",
            latitude: 52.25059,
            longitude: 21.01014,
            story: Story(
                headline: "The Gate in the Walls",
                paragraphs: [
                    "This semicircular brick bastion guarded the way north out of the Old Town, toward the New Town. It was designed by Jan Baptist the Venetian in the mid-16th century.",
                    "By the 18th century it had been partly demolished, and what remained was built into apartment houses. In 1952 to 1954 it was rebuilt from old drawings and engravings, using bricks taken from old buildings demolished in Nysa and Wrocław.",
                ],
                lookFor: "The Little Insurgent on the city walls nearby, a small boy in an oversized helmet who stands for the youngest soldiers of the 1944 Uprising."
            )
        ),
        Stop(
            id: "p7",
            name: "Rynek Nowego Miasta",
            hook: "A separate town until 1791, with a domed church.",
            latitude: 52.2528,
            longitude: 21.00832,
            story: Story(
                headline: "The Other Warsaw",
                paragraphs: [
                    "Past the Barbican you left old Warsaw. The New Town grew up to the north in the early 15th century, its market square was here before 1408, and it remained a town of its own until it was incorporated into Warsaw in 1791.",
                    "The church on the square is St. Kazimierz, designed by Tylman van Gameren and built in 1688 to 1692 to mark the victory over the Turkish army at Vienna. It was destroyed in 1944 and rebuilt in 1947 to 1953.",
                    "You also walked along Freta Street to get here. At number 16 Maria Skłodowska was born on 7 November 1867. The world knows her as Marie Curie, and the house is now a museum about her.",
                ],
                lookFor: "The dome of St. Kazimierz at the edge of the square."
            )
        ),
    ]
}
