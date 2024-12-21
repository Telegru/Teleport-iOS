//
//  DIntroContentViewController.swift
//  TPOnboarding
//
//  Created by Lenar Gilyazov on 19.12.2024.
//

import UIKit
import SnapKit

final class DIntroContentViewController: UIViewController {
    
    // MARK: - Private properties
    
    private let viewModel: DIntroContentViewModel
    
    // MARK: - Private UI components
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var textsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Playfair144pt-Bold", size: 36)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
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
    
    init(viewModel: DIntroContentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life cycle
    
    override func loadView() {
        super.loadView()
        setupView()
    }
    
    // MARK: - Private methods
    
    private func setupView() {
        view.backgroundColor = .clear
        
        addSubviews()
        makeConstraints()
        
        coverImageView.image = viewModel.coverImage
        titleLabel.text = viewModel.title
        descriptionLabel.attributedText = viewModel.description.attributedString()
    }
    
    private func addSubviews() {
        view.addSubview(coverImageView)
        view.addSubview(textsStackView)
    }
    
    private func makeConstraints() {
        coverImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(280.0)
        }
        
        textsStackView.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(34.0)
            $0.leading.trailing.equalToSuperview().inset(66.0)
        }
    }
}

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
