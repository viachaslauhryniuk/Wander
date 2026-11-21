import AVFoundation
import Observation

@Observable
final class Narrator: NSObject, AVAudioPlayerDelegate {
    private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    var time: TimeInterval {
        get { player?.currentTime ?? 0 }
        set { player?.currentTime = newValue }
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    static func speech(for story: Story) async throws -> Data {
        var request = URLRequest(url: ModelProvider.workerURL.appending(path: "v1/speech"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(ModelProvider.installID, forHTTPHeaderField: "x-asides-install")
        let text = ([story.headline] + story.paragraphs + [story.lookFor]).joined(separator: "\n\n")
        request.httpBody = try JSONEncoder().encode(["text": text])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }

    func play(_ audio: Data) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(data: audio)
        player?.delegate = self
        isPlaying = player?.play() ?? false
    }

    func toggle(_ audio: Data) {
        guard let player, player.data == audio else { return play(audio) }
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying = player.isPlaying
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
