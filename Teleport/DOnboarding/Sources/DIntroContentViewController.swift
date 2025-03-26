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
}
