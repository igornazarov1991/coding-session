import Photos

protocol PlayerItemProtocol {
    @MainActor func requestPlayerItem(for asset: PHAsset) async -> AVPlayerItem?
}

final class PlayerItemProvider : PlayerItemProtocol {
    lazy var requestOptions: PHVideoRequestOptions = {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        return options
    }()
    
    func requestPlayerItem(for asset: PHAsset) async -> AVPlayerItem? {
        await withCheckedContinuation { continuation in
            PHImageManager.default().requestPlayerItem(
                forVideo: asset,
                options: requestOptions
            ) { playerItem, _ in
                continuation.resume(returning: playerItem)
            }
        }
    }
}
