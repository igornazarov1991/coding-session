import Foundation
import RxRelay
import Photos
import UIKit

@MainActor
final class VideoListModel {
    private let assetsProvider: AssetsProtocol
    let assets = BehaviorRelay<[PHAsset]>(value: [])
    let imageFetched = PublishRelay<(Int, UIImage?)>()
    let authorizationStatus = BehaviorRelay<PHAuthorizationStatus>(value: .notDetermined)
    
    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.unitsStyle = .positional
        return formatter
    }()
    
    init(assetsProvider: AssetsProtocol = AssetsProvider()) {
        self.assetsProvider = assetsProvider
    }
    
    func start() {
        Task {
            await requestAuthorization()
        }
    }
    
    private func requestAuthorization() async {
        let status = await assetsProvider.requestAuthorization()
        authorizationStatus.accept(status)
    }
    
    func fetchAssets() {
        assets.accept(assetsProvider.fetchAssets())
    }
    
    func fetchImage(index: Int, size: CGSize) {
        Task {
            let asset = assets.value[index]
            let image = await assetsProvider.fetchImage(for: asset, size: size)
            imageFetched.accept((index, image))
        }
    }
    
    func resetCachedAssets() {
        assetsProvider.resetCachedAssets()
    }
    
    func updateCachedAssets(
        added addedIndexPaths: [IndexPath],
        removed removedIndexPaths: [IndexPath],
        size: CGSize
    ) {
        assetsProvider.updateCachedAssets(
            added: addedIndexPaths,
            removed: removedIndexPaths,
            size: size
        )
    }
    
    func duration(for asset: PHAsset) -> String? {
        return formatter.string(from: asset.duration)
    }
}
