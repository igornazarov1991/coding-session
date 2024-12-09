import UIKit
import Photos

typealias AssetsProtocol = AuthorizationProtocol & AssetsFetcher & AssetsCache

protocol AuthorizationProtocol {
    @MainActor var autorizationStatus: PHAuthorizationStatus { get }
    @MainActor func requestAuthorization() async -> PHAuthorizationStatus
}

protocol AssetsFetcher {
    @MainActor func fetchAssets() -> [PHAsset]
    @MainActor func fetchImage(for asset: PHAsset, size: CGSize) async -> UIImage?
}

protocol AssetsCache {
    func resetCachedAssets()
    func updateCachedAssets(added addedIndexPaths: [IndexPath], removed removedIndexPaths: [IndexPath], size: CGSize)
}

final class AssetsProvider: AssetsProtocol {
    let assetsManager = PHCachingImageManager()
    
    lazy var fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        return fetchOptions
    }()
    
    lazy var fetchResult: PHFetchResult<PHAsset> = {
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        return fetchResult
    }()
    
    private var contentMode: PHImageContentMode { .aspectFill }
    private var accessLevel: PHAccessLevel { .readWrite }
    
    // MARK: AuthorizationProtocol
    
    var autorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: accessLevel)
    }
    
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: accessLevel)
    }
    
    // MARK: AssetsFetcher
    
    func fetchAssets() -> [PHAsset] {
        var videoAssets: [PHAsset] = []
           
        fetchResult.enumerateObjects { (asset, _, _) in
            videoAssets.append(asset)
        }
        
        return videoAssets
    }
    
    func fetchImage(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: asset, targetSize: size, contentMode: contentMode, options: requestOptions) { (image, _) in
                continuation.resume(returning: image)
            }
        }
    }
    
    // MARK: AssetsCache
    
    func resetCachedAssets() {
        assetsManager.stopCachingImagesForAllAssets()
    }
    
    func updateCachedAssets(
        added addedIndexPaths: [IndexPath],
        removed removedIndexPaths: [IndexPath],
        size: CGSize
    ) {
        let addedAssets = addedIndexPaths.map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedIndexPaths.map { indexPath in fetchResult.object(at: indexPath.item) }
        
        assetsManager.startCachingImages(
            for: addedAssets,
            targetSize: size,
            contentMode: contentMode,
            options: nil
        )
        
        assetsManager.stopCachingImages(
            for: removedAssets,
            targetSize: size,
            contentMode: contentMode,
            options: nil
        )
    }
}
