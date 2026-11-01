import AVFoundation
import NaturalLanguage
import Observation

@Observable
final class Narrator: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var isPlaying = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func read(_ story: Story) {
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let text = ([story.headline] + story.paragraphs + [story.lookFor]).joined(separator: "\n\n")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = NLLanguageRecognizer.dominantLanguage(for: text).flatMap { voice(for: $0.rawValue) }
        synthesizer.speak(utterance)
        isPlaying = true
    }

    func toggle(_ story: Story) {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
        } else if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isPlaying = false
        } else {
            read(story)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
    }

    private func voice(for language: String) -> AVSpeechSynthesisVoice? {
        let installed = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(language) && !$0.voiceTraits.contains(.isNoveltyVoice) }
        let best = installed.filter { $0.quality != .default }.max { $0.quality.rawValue < $1.quality.rawValue }
        return best ?? AVSpeechSynthesisVoice(language: language)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
