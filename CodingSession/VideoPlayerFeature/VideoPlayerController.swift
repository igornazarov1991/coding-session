import UIKit
import Photos
import RxSwift

final class VideoPlayerController: UIViewController {
    weak var coordinator: MainCoordinatorProtocol?
    
    private let viewModel: VideoPlayerModel
    private let disposeBag = DisposeBag()
    private var player: AVPlayer?
    
    init(viewModel: VideoPlayerModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        player?.pause()
        player?.seek(to: .zero)
        player = nil
    }
    
    private func bind() {
        viewModel.playerItem
            .asObservable()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] playerItem in
                guard let self, let playerItem else { return }
                self.handlePlayerItem(playerItem)
            })
            .disposed(by: disposeBag)
        
        viewModel.start()
    }
    
    private func handlePlayerItem(_ playerItem: AVPlayerItem) {
        player = AVPlayer(playerItem: playerItem)
        guard let player else { return }
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.layer.bounds.inset(by: view.safeAreaInsets)
        view.layer.addSublayer(playerLayer)
        player.play()
    }
}
