import AppKit

enum SoundPlayer {
    static func playBreakStart() {
        guard AppSettings.shared.soundEnabled else { return }
        play(named: "Glass", volume: 0.35)
    }

    static func playBreakEnd() {
        guard AppSettings.shared.soundEnabled else { return }
        play(named: "Glass", volume: 0.35)
    }

    private static func play(named name: String, volume: Float) {
        guard let sound = NSSound(named: .init(name)) else { return }
        sound.volume = volume
        sound.play()
    }
}
