import UIKit
import TPStrings
import AppBundle

final class DIntroPageViewController: UIPageViewController {

    var pageChangingHandler: ((Int) -> Void)?

    var numberOfPages: Int {
        viewModels.count
    }

    private lazy var viewModels: [DIntroContentViewModel] = [
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage1"), title: "Intro.Page1.Title".tp_loc(), description: "Intro.Page1.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage2"), title: "Intro.Page2.Title".tp_loc(), description: "Intro.Page2.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage3"), title: "Intro.Page3.Title".tp_loc(), description: "Intro.Page3.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage4"), title: "Intro.Page4.Title".tp_loc(), description: "Intro.Page4.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage5"), title: "Intro.Page5.Title".tp_loc(), description: "Intro.Page5.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage6"), title: "Intro.Page6.Title".tp_loc(), description: "Intro.Page6.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage7"), title: "Intro.Page7.Title".tp_loc(), description: "Intro.Page7.Description".tp_loc()),
        DIntroContentViewModel(coverImage: UIImage(bundleImageName: "DOnboarding/OnboardingPage8"), title: "Intro.Page8.Title".tp_loc(), description: "Intro.Page8.Description".tp_loc())
    ]

    private lazy var pages: [UIViewController] = viewModels.map(DIntroContentViewController.init(viewModel:))

    // MARK: - Initialization

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        dataSource = self
        delegate = self

        setViewControllers([pages[0]], direction: .forward, animated: false)
    }
}

// MARK: - UIPageViewControllerDataSource

extension DIntroPageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else { return nil }

        guard pages.count > previousIndex else { return nil }

        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }

        let nextIndex = viewControllerIndex + 1

        guard nextIndex < pages.count else { return nil }

        guard pages.count > nextIndex else { return nil }

        return pages[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate

extension DIntroPageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        guard let currentController = pageViewController.viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentController) else {
            return
        }

        pageChangingHandler?(currentIndex)
    }
}
