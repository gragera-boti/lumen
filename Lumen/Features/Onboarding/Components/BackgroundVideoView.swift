import AVFoundation
import SwiftUI

struct BackgroundVideoView: UIViewRepresentable {
    let videoName: String
    let videoExtension: String
    
    func makeUIView(context: Context) -> UIView {
        return LoopingVideoUIView(videoName: videoName, videoExtension: videoExtension)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class LoopingVideoUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    init(videoName: String, videoExtension: String) {
        super.init(frame: .zero)
        
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            print("Failed to find video: \(videoName).\(videoExtension)")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        queuePlayer.isMuted = true
        queuePlayer.play()
        
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
