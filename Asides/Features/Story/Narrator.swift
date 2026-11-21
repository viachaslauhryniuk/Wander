import AVFoundation
import Observation

@Observable
final class Narrator {
    private let player = AVPlayer()
    private var url: URL?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
    }

    var isPlaying: Bool {
        player.timeControlStatus != .paused
    }

    var time: TimeInterval {
        get {
            let seconds = player.currentTime().seconds
            return seconds.isFinite ? seconds : 0
        }
        set { player.seek(to: CMTime(seconds: newValue, preferredTimescale: 600)) }
    }

    var duration: TimeInterval {
        let seconds = player.currentItem?.duration.seconds ?? 0
        return seconds.isFinite ? seconds : 0
    }

    static func speech(for story: Story) async throws -> URL {
        var request = URLRequest(url: ModelProvider.workerURL.appending(path: "v1/speech"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(ModelProvider.installID, forHTTPHeaderField: "x-asides-install")
        let text = ([story.headline] + story.paragraphs + [story.lookFor]).joined(separator: "\n\n")
        request.httpBody = try JSONEncoder().encode(["text": text])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).mp3")
        try data.write(to: url)
        return url
    }

    func play(_ url: URL) {
        self.url = url
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()
    }

    func toggle(_ url: URL) {
        guard self.url == url else { return play(url) }
        if isPlaying {
            player.pause()
        } else {
            if time >= duration {
                time = 0
            }
            player.play()
        }
    }

    func stop() {
        player.replaceCurrentItem(with: nil)
        url = nil
    }
}
