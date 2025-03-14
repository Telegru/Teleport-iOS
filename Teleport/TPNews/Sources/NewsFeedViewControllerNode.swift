import AsyncDisplayKit
import Display
import WebKit

final class NewsFeedViewControllerNode: ASDisplayNode {
    
    // Private UI Properties
    private var webView: WKWebView?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        let configuration = WKWebViewConfiguration()
        let userController = WKUserContentController()
        configuration.userContentController = userController
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        self.webView = webView
        view.addSubview(webView)
        loadHomePage()
    }
    
    // MARK: - Internal methods
    
    func loadHomePage() {
        guard let url = URL(string: Constants.baseLink) else {
            return
        }
        webView?.load(URLRequest(url: url))
    }
    
    // MARK: - Layout
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.webView?.frame = CGRect(
            origin: CGPoint(
                x: 0.0,
                y: navigationBarHeight),
            size: CGSize(
                width: layout.size.width,
                height: max(1.0, layout.size.height - navigationBarHeight)
            )
        )
    }
}

// MARK: - NewsFeedViewControllerNode + WKNavigationDelegate

extension NewsFeedViewControllerNode: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        guard let navigationActionURL = navigationAction.request.url else {
            return decisionHandler(.cancel)
        }
        let host = navigationActionURL.host
        if host?.hasSuffix(Constants.host) == true {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
}

// MARK: - NewsFeedViewControllerNode + Constants

extension NewsFeedViewControllerNode {
    
    private enum Constants {
        static let baseLink = "https://m.business-gazeta.ru"
        static let host = "business-gazeta.ru"
    }
}
