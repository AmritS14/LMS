import Foundation
import AVFoundation

@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func playSound(named name: String, type: String = "wav") {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            print("Sound file \(name).\(type) not found in bundle.")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Successfully playing sound: \(name).\(type)")
        } catch {
            print("Could not play sound file: \(error.localizedDescription)")
        }
    }
}
