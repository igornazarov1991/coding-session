//
//  ViewController.swift
//  CodingSession
//
//  Created by Pavel Ilin on 01.11.2023.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Accelerate
import Photos

class VideoListController: UIViewController {
    weak var coordinator: MainCoordinatorProtocol?
    
    private let viewModel: VideoListModel
    
    private struct State {
        var thumbnailSize: CGSize = .zero // The size of the images to be prepared
        var previousPreheatRect = CGRect.zero // Update cache only if the visible area is significantly different from the last preheated area
    }
    private var state: State = .init()
    
    private let disposeBag = DisposeBag()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: createCollectionViewLayout()
        )
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        collectionView.register(
            VideoCell.self,
            forCellWithReuseIdentifier: VideoCell.reuseIdentifier
        )
        return collectionView
    }()
    
    private lazy var accessDeniedView: UIView = {
        let label = UILabel()
        label.text = "Access denied"
        label.textAlignment = .center
        
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Open Settings"
        let action = UIAction { [weak self] _ in
            self?.coordinator?.openSettings()
        }
        let button = UIButton(configuration: configuration, primaryAction: action)
        
        let stackView = UIStackView(
            arrangedSubviews: [
                label,
                button
            ]
        )
        stackView.axis = .vertical
        stackView.spacing = 16
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        return stackView
    }()
    
    init(viewModel: VideoListModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        resetCachedAssets()
        bind()
        viewModel.start()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let scale = UIScreen.main.scale
        let scaledSize = itemSize.width * scale
        state.thumbnailSize = CGSize(width: scaledSize, height: scaledSize)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateCachedAssets()
    }
    
    // MARK: Binding
    
    private func bind() {
        bindStatus()
        bindCollectionView()
        bindImageFetch()
    }
    
    private func bindStatus() {
        viewModel.authorizationStatus
            .asObservable()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                self.handleAuthorizationStatusChange(status)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindCollectionView() {
        viewModel.assets
            .filter({ !$0.isEmpty })
            .bind(to: collectionView.rx.items(cellIdentifier: VideoCell.reuseIdentifier, cellType: VideoCell.self)) { (row, element, cell) in }
            .disposed(by: disposeBag)
        
        collectionView.rx.willDisplayCell
            .observe(on: MainScheduler.instance)
            .map({ ($0.cell as! VideoCell, $0.at.item) })
            .subscribe { [weak self] cell, indexPath in
                guard let self = self else { return }
                cell.animateProgress(true)
                self.viewModel.fetchImage(index: indexPath, size: itemSize)
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .map({ $0.item })
            .subscribe { [weak self] indexPath in
                guard let self else { return }
                let row = indexPath.element ?? 0
                let asset = self.viewModel.assets.value[row]
                self.coordinator?.displayVideoDetails(asset)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindImageFetch() {
        viewModel.imageFetched
            .observe(on: MainScheduler.instance)
            .filter({ $0.1 != nil })
            .map({ ($0.0, $0.1!) })
            .subscribe(onNext: { [unowned self] index, image in
                let indexPath = IndexPath(item: index, section: 0)
                guard let cell = collectionView.cellForItem(at: indexPath) as? VideoCell else {
                    return
                }
                cell.animateProgress(false)
                cell.image = image
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: PHAuthorizationStatus
    
    private func handleAuthorizationStatusChange(_ status: PHAuthorizationStatus) {
        switch status {
        case .authorized, .limited:
            accessAuthorized()
        case .notDetermined:
            print("The user hasn't been aksed yet")
        case .denied:
            print("The user explicitly denied this app's access.")
            accessDenied()
        case .restricted:
            print("The system restricted this app's access.")
        @unknown default:
            break
        }
    }
    
    private func accessAuthorized() {
        viewModel.fetchAssets()
    }
    
    private func accessDenied() {
        view.bringSubviewToFront(accessDeniedView)
    }
    
    func createCollectionViewLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.collectionView?.allowsSelection = true
        layout.itemSize = itemSize
        layout.minimumInteritemSpacing = 3
        layout.minimumLineSpacing = 3
        return layout
    }
    
    // MARK: Cache
    
    private func resetCachedAssets() {
        viewModel.resetCachedAssets()
        state.previousPreheatRect = .zero
    }
    
    private func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else { return }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        let delta = abs(preheatRect.midY - state.previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        let (addedRects, removedRects) = RectCalculator.differencesBetweenRects(state.previousPreheatRect, preheatRect)
        let addedIndexPaths = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
        let removedIndexPaths = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
        
        viewModel.updateCachedAssets(
            added: addedIndexPaths,
            removed: removedIndexPaths,
            size: state.thumbnailSize
        )
        
        state.previousPreheatRect = preheatRect
    }
}

extension VideoListController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}
