import AVFoundation

final class TTSService {
    static let shared = TTSService()
    private let synth = AVSpeechSynthesizer()
    private init() {}

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "de-DE")
        u.rate = 0.45
        u.pitchMultiplier = 1.0
        u.volume = 1.0
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
