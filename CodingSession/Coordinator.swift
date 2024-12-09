import UIKit
import Photos

@MainActor
protocol CoordinatorProtocol {
    var childCoordinators: [CoordinatorProtocol] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}

protocol MainCoordinatorProtocol: CoordinatorProtocol, AnyObject {
    func displayVideoDetails(_ asset: PHAsset)
    func openSettings()
}

@MainActor
class MainCoordinator: MainCoordinatorProtocol {
    var childCoordinators = [CoordinatorProtocol]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = VideoListController(viewModel: VideoListModel())
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: false)
    }
    
    func displayVideoDetails(_ asset: PHAsset) {
        let viewModel = VideoPlayerModel(asset: asset, provider: PlayerItemProvider())
        let videoPlayerController = VideoPlayerController(viewModel: viewModel)
        videoPlayerController.coordinator = self
        navigationController.pushViewController(videoPlayerController, animated: true)
    }
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
