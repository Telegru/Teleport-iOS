//
//  DIntroViewController.swift
//  Telegram
//
//  Created by Lenar Gilyazov on 19.12.2024.
//

import UIKit
import RMIntro
import SSignalKit
import LegacyComponents

private enum DeviceScreen: Int {
    case inch35 = 0, inch4, inch47, inch55, inch65, iPad, iPadPro
}

private final class DIntroView: UIView {
    var onLayout: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

public final class DIntroViewController: UIViewController {
    
    // Public properties
    
    public var defaultFrame: CGRect = .zero
    public var isEnabled: Bool = true
    public var startMessaging: (() -> Void)?
    public var startMessagingInAlternativeLanguage: ((String) -> Void)?
    public var createStartButton: ((CGFloat) -> UIView)!
    
    // Orientation
    
    public override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return .portrait
    }
    
    // Private properties
    
    private var loadedView: Bool = false
    private var alternativeLocalization: SVariable?
    private var alternativeLocalizationInfo: TGSuggestedLocalization?
    private var localizationsDisposable: SDisposable?
    private var deviceScreen: DeviceScreen {
        let viewSize = view.frame.size
        let max = Int(max(viewSize.width, viewSize.height))
        var deviceScreen = DeviceScreen.inch55
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch max {
            case 1366:
                deviceScreen = .iPadPro
                
            default:
                deviceScreen = .iPad
            }
        } else {
            switch max {
            case 480:
                deviceScreen = .inch35
                
            case 568:
                deviceScreen = .inch4
                
            case 667:
                deviceScreen = .inch47
                
            case 896:
                deviceScreen = .inch65
            
            default: break
            }
        }
        
        return deviceScreen
    }
    
    // UI
    private var startButton: UIView?
    private lazy var pageViewController = DIntroPageViewController()
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.tintColor = .white
        control.numberOfPages = pageViewController.numberOfPages
        return control
    }()
    private lazy var alternativeLanguageButton: TGModernButton = {
        let button = TGModernButton()
        button.modernHighlight = true
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 18.0)
        button.isHidden = true
        button.addTarget(self, action: #selector(alternativeLanguageButtonPressed), for: .touchUpInside)
        return button
    }()
    
    deinit {
        localizationsDisposable?.dispose()
    }
    
    public init(suggestedLocalizationSignal: SSignal) {
        isEnabled = true
        
        super.init(nibName: nil, bundle: nil)
        
        localizationsDisposable = suggestedLocalizationSignal.deliver(on: .main())
            .startStrict(next: { [weak self] next in
                guard let self,
                      let next = next as? TGSuggestedLocalization else {
                    return
                }
                if alternativeLocalizationInfo == nil {
                    alternativeLocalizationInfo = next
                    alternativeLanguageButton.setTitle("Intro.Continue".tp_loc(), for: .normal)
                    alternativeLanguageButton.isHidden = false
                    alternativeLanguageButton.sizeToFit()
                    
                    if isViewLoaded {
                        alternativeLanguageButton.alpha = 0.0
                        UIView.animate(withDuration: 0.3) {
                            self.alternativeLanguageButton.alpha = self.isEnabled ? 1.0 : 0.6
                            self.viewWillLayoutSubviews()
                        }
                    }
                }
            }, file: #file, line: #line)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        view = DIntroView(frame: defaultFrame)
        
        (view as? DIntroView)?.onLayout = { [weak self] in
            self?.updateLayout()
        }
        viewDidLoad()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard !loadedView else { return }
        loadedView = true
        
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .black
        addSubviews()
        
        pageViewController.pageChangingHandler = { [weak self] page in
            self?.pageControl.currentPage = page
        }
    }
    
    private func addSubviews() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        view.addSubview(alternativeLanguageButton)
        view.addSubview(pageControl)
    }
    
    private func updateLayout() {
        var startButtonY: CGFloat = 0
        var languageButtonSpread: CGFloat = 60.0
        var languageButtonOffset: CGFloat = 26.0
        
        switch deviceScreen {
        case .iPad, .iPadPro:
            startButtonY = 120
        case .inch35:
            startButtonY = 75
            if !alternativeLanguageButton.isHidden {
                startButtonY -= 30.0
            }
            languageButtonSpread = 65
            languageButtonOffset = 15
        case .inch4:
            startButtonY = 75
            languageButtonSpread = 50.0
            languageButtonOffset = 20.0
        case .inch47:
            startButtonY = 75 + 5
        case .inch55:
            startButtonY = 75 + 20
        case .inch65:
            startButtonY = 75 + 30
        }
        
        if !alternativeLanguageButton.isHidden {
            startButtonY += languageButtonSpread
        }
        
        pageViewController.view.frame = view.bounds
        
        let startButtonWidth: CGFloat = min(430.0 - 48.0, view.bounds.size.width - 48.0)
        let startButton = createStartButton(startButtonWidth)
        if startButton.superview == nil {
            self.startButton = startButton
            view.addSubview(startButton)
        }
        
        self.startButton?.frame = CGRect(
            x: (self.view.bounds.size.width - startButtonWidth) / 2.0,
            y: view.bounds.size.height - startButtonY,
            width: startButtonWidth,
            height: 50.0
        )
        
        alternativeLanguageButton.frame = CGRect(
            x: (self.view.bounds.size.width - alternativeLanguageButton.frame.size.width) / 2.0,
            y: self.startButton!.frame.maxY + languageButtonOffset,
            width: alternativeLanguageButton.frame.size.width,
            height: alternativeLanguageButton.frame.size.height
        )
        
        pageControl.frame = CGRect(
            x: 0,
            y: self.startButton!.frame.origin.y - 85,
            width: view.bounds.size.width,
            height: 33
        )
    }
    
    @objc
    private func alternativeLanguageButtonPressed() {
        let language = Locale.current.languageCode == "ru" ? "en" : "ru"
        startMessagingInAlternativeLanguage?(language)
    }
    
    @objc
    private func startButtonPressed() {
        startMessaging?()
    }
}
