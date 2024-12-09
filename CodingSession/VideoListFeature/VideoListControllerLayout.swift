import UIKit

extension VideoListController: UICollectionViewDelegateFlowLayout {
    private var spacer: CGFloat {
        return 3.0
    }
    
    private var columnCount: Int {
        return 3
    }
    
    var itemSize: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let spacerWidth = spacer * CGFloat(columnCount - 1)
        let size = (screenWidth - spacerWidth) / CGFloat(columnCount)
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        itemSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
