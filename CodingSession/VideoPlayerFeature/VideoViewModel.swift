import Photos
import RxRelay

@MainActor
final class VideoPlayerModel {
    let playerItem = BehaviorRelay<AVPlayerItem?>(value: nil)
    private let asset: PHAsset
    private let provider: PlayerItemProtocol
    
    init(asset: PHAsset, provider: PlayerItemProtocol) {
        guard asset.mediaType == .video else {
            fatalError("Asset must be a video.")
        }
        self.asset = asset
        self.provider = provider
    }
    
    func start() {
        Task {
            await requestPlayerItem()
        }
    }
    
    private func requestPlayerItem() async {
        playerItem.accept(await provider.requestPlayerItem(for: asset))
    }
}
