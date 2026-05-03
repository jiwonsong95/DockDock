import AppKit

@MainActor
enum SnapSoundService {
    private static var snapSound: NSSound?

    static func play() {
        guard let sound = sound() else {
            return
        }

        if sound.isPlaying {
            sound.stop()
        }

        sound.currentTime = 0
        sound.play()
    }

    private static func sound() -> NSSound? {
        if let snapSound {
            return snapSound
        }

        guard let url = Bundle.main.url(forResource: "Snap", withExtension: "mp3"),
              let sound = NSSound(contentsOf: url, byReference: false) else {
            return nil
        }

        sound.volume = 0.65
        snapSound = sound
        return sound
    }
}
