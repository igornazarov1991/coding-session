import UIKit

final class VideoCell: UICollectionViewCell {
    
    static let reuseIdentifier = "VideoCell"
    
    private var thumbImageView: UIImageView!
    private var durationLabel: UILabel!
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        indicator.center = self.contentView.center
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    var image: UIImage! {
        didSet {
            thumbImageView.image = image
        }
    }
    
    var title: String! {
        didSet {
            durationLabel.text = title
        }
    }
    
    var representedAssetIdentifier: String!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.image = nil
        self.title = nil
    }
    
    func animateProgress(_ animate: Bool) {
        if animate {
            activityIndicator.startAnimating()
            contentView.bringSubviewToFront(activityIndicator)
        } else {
            activityIndicator.stopAnimating()
            contentView.sendSubviewToBack(activityIndicator)
        }
    }
    
    private func configure() {
        thumbImageView = UIImageView(frame: .zero)
        contentView.addSubview(thumbImageView)
        thumbImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        
        durationLabel = UILabel(frame: .zero)
        contentView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(8)
            make.bottom.equalTo(-8)
        }
        
        contentView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        contentView.bringSubviewToFront(activityIndicator)
    }
}
