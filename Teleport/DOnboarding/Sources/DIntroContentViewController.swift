import UIKit

final class DIntroContentViewController: UIViewController {
    
    private let viewModel: DIntroContentViewModel
    private lazy var contentView = DIntroContentView()
    
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
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.viewModel = viewModel
    }
    
//    private func makeConstraints() {
//        
//        coverImageView.snp.makeConstraints {
//            $0.top.leading.trailing.equalToSuperview()
//            $0.height.equalTo(UIScreen.main.bounds.width < 375.0 ? 280.0 : 140.0)
//        }
//        
//        textsStackView.snp.makeConstraints {
//            $0.top.equalTo(coverImageView.snp.bottom).offset(34.0)
//            $0.leading.trailing.equalToSuperview().inset(66.0)
//        }
//    }
}
