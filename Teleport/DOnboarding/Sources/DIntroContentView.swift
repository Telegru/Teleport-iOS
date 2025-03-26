import UIKit

final class DIntroContentView: UIView {
    
    // MARK: - Private properties
    
    var viewModel: DIntroContentViewModel? {
        didSet {
            guard let viewModel else { return }
            setup(for: viewModel)
        }
    }
    
    // MARK: - Private UI components
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Playfair144pt-Bold", size: 36)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        addSubview(coverImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let coverHeight = calculateCoverHeight()
        coverImageView.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: frame.width,
                height: coverHeight
            )
        )
        
        let textInset = calculateTextInset()
        let titleX = textInset
        let titleY = coverImageView.frame.maxY + 34.0
        let titleWidth = frame.width - textInset * 2.0
        let titleHeight = titleLabel.systemLayoutSizeFitting(CGSize(width: titleWidth, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        
        titleLabel.frame = CGRect(
            x: titleX,
            y: titleY,
            width: titleWidth,
            height: titleHeight
        )
        
        let descriptionX = textInset
        let descriptionY = titleLabel.frame.maxY + 12.0
        let descriptionWidth = frame.width - textInset * 2.0
        let descriptionHeight = descriptionLabel.systemLayoutSizeFitting(CGSize(width: descriptionWidth, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        descriptionLabel.frame = CGRect(
            x: descriptionX,
            y: descriptionY,
            width: descriptionWidth,
            height: descriptionHeight
        )
    }
    
    // MARK: - Private methods
    
    private func setup(for viewModel: DIntroContentViewModel?) {
        coverImageView.image = viewModel?.coverImage
        titleLabel.text = viewModel?.title
        descriptionLabel.attributedText = viewModel?.description.attributedString()
    }
    
    private func calculateCoverHeight() -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 276.0
        }
        if frame.width < 375.0 {
            return 180.0
        } else {
            return 280.0
        }
    }
    
    private func calculateTextInset() -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch frame.width {
                case 700...CGFloat.infinity:
                    return 254.0
                case 400..<700:
                    return 100.0
                default:
                    return 22.0
            }
        }
        
        if frame.width <= 375.0 {
            return 22.0
        } else {
            return 66.0
        }
    }
}

// MARK: - String + Attr

private extension String {
    
    typealias Fonts = (default: UIFont, bold: UIFont)
    
    static func defaultFonts() -> Fonts {
        let font = UIFont.systemFont(ofSize: 17.0)
        return (font, .boldSystemFont(ofSize: 17.0))
    }
    
    func attributedString(
        withFonts fonts: Fonts = defaultFonts()
    ) -> NSAttributedString {
        let components = self.components(separatedBy: "**")
        let sequence = components.enumerated()
        let attributedString = NSMutableAttributedString()
        
        return sequence.reduce(into: attributedString) { string, pair in
            let isBold = !pair.offset.isMultiple(of: 2)
            let font = isBold ? fonts.bold : fonts.default
            
            string.append(NSAttributedString(
                string: pair.element,
                attributes: [.font: font]
            ))
        }
    }
}
