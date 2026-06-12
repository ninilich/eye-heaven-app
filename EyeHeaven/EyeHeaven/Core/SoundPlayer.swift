import AVFoundation

@MainActor
enum SoundPlayer {
    private nonisolated(unsafe) static var startPlayer: AVAudioPlayer?
    private nonisolated(unsafe) static var endPlayer: AVAudioPlayer?

    static func preload() {
        startPlayer = makePlayer("gong_start")
        endPlayer = makePlayer("gong_end")
    }

    static func playBreakStart() {
        guard AppSettings.shared.soundEnabled else { return }
        startPlayer?.currentTime = 0
        startPlayer?.play()
    }

    static func playBreakEnd() {
        guard AppSettings.shared.soundEnabled else { return }
        endPlayer?.currentTime = 0
        endPlayer?.play()
    }

    private nonisolated static func makePlayer(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }
}
