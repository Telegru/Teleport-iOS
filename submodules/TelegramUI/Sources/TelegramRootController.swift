import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ContactListUI
import CallListUI
import ChatListUI
import SettingsUI
import AppBundle
import DatePickerNode
import DebugSettingsUI
import TabBarUI
import WallpaperBackgroundNode
import ChatPresentationInterfaceState
import CameraScreen
import MediaEditorScreen
import LegacyComponents
import LegacyMediaPickerUI
import LegacyCamera
import AvatarNode
import LocalMediaResources
import ImageCompression
import TextFormat
import MediaEditor
import PeerInfoScreen
import PeerInfoStoryGridScreen
import ShareWithPeersScreen
import ChatEmptyNode

import TPNews
import ItemListUI
import TelegramUIPreferences
import WebUI
import PresentationDataUtils
import LocalizedPeerData

private class DetailsChatPlaceholderNode: ASDisplayNode, NavigationDetailsPlaceholderNode {
    private var presentationData: PresentationData
    private var presentationInterfaceState: ChatPresentationInterfaceState
    
    let wallpaperBackgroundNode: WallpaperBackgroundNode
    let emptyNode: ChatEmptyNode
    
    init(context: AccountContext) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.presentationInterfaceState = ChatPresentationInterfaceState(chatWallpaper: self.presentationData.chatWallpaper, theme: self.presentationData.theme, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, nameDisplayOrder: self.presentationData.nameDisplayOrder, limitsConfiguration: context.currentLimitsConfiguration.with { $0 }, fontSize: self.presentationData.chatFontSize, bubbleCorners: self.presentationData.chatBubbleCorners, accountPeerId: context.account.peerId, mode: .standard(.default), chatLocation: .peer(id: context.account.peerId), subject: nil, peerNearbyData: nil, greetingData: nil, pendingUnpinnedAllMessages: false, activeGroupCallInfo: nil, hasActiveGroupCall: false, importState: nil, threadData: nil, isGeneralThreadClosed: nil, replyMessage: nil, accountPeerColor: nil, businessIntro: nil)
        
        self.wallpaperBackgroundNode = createWallpaperBackgroundNode(context: context, forChatDisplay: true, useSharedAnimationPhase: true)
        self.emptyNode = ChatEmptyNode(context: context, interaction: nil)
        
        super.init()
        
        self.addSubnode(self.wallpaperBackgroundNode)
        self.addSubnode(self.emptyNode)
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        self.presentationInterfaceState = ChatPresentationInterfaceState(chatWallpaper: self.presentationData.chatWallpaper, theme: self.presentationData.theme, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, nameDisplayOrder: self.presentationData.nameDisplayOrder, limitsConfiguration: self.presentationInterfaceState.limitsConfiguration, fontSize: self.presentationData.chatFontSize, bubbleCorners: self.presentationData.chatBubbleCorners, accountPeerId: self.presentationInterfaceState.accountPeerId, mode: .standard(.default), chatLocation: self.presentationInterfaceState.chatLocation, subject: nil, peerNearbyData: nil, greetingData: nil, pendingUnpinnedAllMessages: false, activeGroupCallInfo: nil, hasActiveGroupCall: false, importState: nil, threadData: nil, isGeneralThreadClosed: nil, replyMessage: nil, accountPeerColor: nil, businessIntro: nil)
        
        self.wallpaperBackgroundNode.update(wallpaper: presentationData.chatWallpaper, animated: false)
    }
    
    func updateLayout(size: CGSize, needsTiling: Bool, transition: ContainedViewLayoutTransition) {
        let contentBounds = CGRect(origin: .zero, size: size)
        self.wallpaperBackgroundNode.updateLayout(size: size, displayMode: needsTiling ? .aspectFit : .aspectFill, transition: transition)
        transition.updateFrame(node: self.wallpaperBackgroundNode, frame: contentBounds)
        
        self.emptyNode.updateLayout(interfaceState: self.presentationInterfaceState, subject: .detailsPlaceholder, loadingNode: nil, backgroundNode: self.wallpaperBackgroundNode, size: contentBounds.size, insets: .zero, transition: transition)
        transition.updateFrame(node: self.emptyNode, frame: CGRect(origin: .zero, size: size))
        self.emptyNode.update(rect: contentBounds, within: contentBounds.size, transition: transition)
    }
}

public final class TelegramRootController: NavigationController, TelegramRootControllerInterface {
    private let context: AccountContext
    
    public var rootTabController: TabBarController?
    
    public var contactsController: ContactsController?
    public var callListController: CallListController?
    public var chatListController: ChatListController?
    public var newsFeedController: ViewController?
    public var accountSettingsController: PeerInfoScreen?
    
//    private var appsController: ViewController?
    private var dahlSettingsController: ViewController?
//    private var walletController: ViewController?
    private var channelsController: ViewController?
    private var wallController: DWallController?
    
    private var permissionsDisposable: Disposable?
    private var presentationDataDisposable: Disposable?
    private var presentationData: PresentationData
    
    private var detailsPlaceholderNode: DetailsChatPlaceholderNode?
    
    private var applicationInFocusDisposable: Disposable?
    private var storyUploadEventsDisposable: Disposable?
    
    private var walletBot: AttachMenuBot?
    private var walletDisposable: Disposable?
    
    private var appsBot: TelegramUser?
    private var appsBotWebViewResult: RequestWebViewResult?
    private var appsBotSettings: BotAppSettings?
    private var appsBotDisposable: Disposable?
    
    private var tabs: [DAppTab]?
    
    override public var minimizedContainer: MinimizedContainer? {
        didSet {
            self.minimizedContainer?.navigationController = self
            self.minimizedContainerUpdated(self.minimizedContainer)
        }
    }
    
    public var minimizedContainerUpdated: (MinimizedContainer?) -> Void = { _ in }
        
    public init(context: AccountContext) {
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(mode: .automaticMasterDetail, theme: NavigationControllerTheme(presentationTheme: self.presentationData.theme))
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            if let strongSelf = self {
                strongSelf.detailsPlaceholderNode?.updatePresentationData(presentationData)
                
                let previousTheme = strongSelf.presentationData.theme
                strongSelf.presentationData = presentationData
                if previousTheme !== presentationData.theme {
                    (strongSelf.rootTabController as? TabBarControllerImpl)?.updateTheme(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData), theme: TabBarControllerTheme(rootControllerTheme: presentationData.theme))
                    strongSelf.rootTabController?.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
                }
            }
        })
        
        if context.sharedContext.applicationBindings.isMainApp {
            self.applicationInFocusDisposable = (context.sharedContext.applicationBindings.applicationIsActive
            |> distinctUntilChanged
            |> deliverOn(Queue.mainQueue())).startStrict(next: { value in
                context.sharedContext.mainWindow?.setForceBadgeHidden(!value)
            })
            
            self.storyUploadEventsDisposable = (context.engine.messages.allStoriesUploadEvents()
            |> deliverOnMainQueue).startStrict(next: { [weak self] event in
                guard let self else {
                    return
                }
                let (stableId, id) = event
                moveStorySource(engine: self.context.engine, peerId: self.context.account.peerId, from: Int64(stableId), to: Int64(id))
            })
        }
        
//        let botsKey = ValueBoxKey(length: 8)
//        botsKey.setInt64(0, value: 0)
//        walletDisposable = (context.engine.data.subscribe(TelegramEngine.EngineData.Item.ItemCache.Item(collectionId: Namespaces.CachedItemCollection.attachMenuBots, id: botsKey))
//        |> mapToSignal { entry -> Signal<AttachMenuBot?, NoError> in
//            let bots: [AttachMenuBots.Bot] = entry?.get(AttachMenuBots.self)?.bots ?? []
//            return context.engine.data.get(
//                EngineDataMap(bots.map(\.peerId).map(TelegramEngine.EngineData.Item.Peer.Peer.init))
//            )
//            |> mapToSignal { peersMap -> Signal<AttachMenuBot?, NoError> in
//                let result = bots
//                    .filter {
//                        guard let peer = peersMap[$0.peerId] else {
//                            return false
//                        }
//                        guard case let .user(user) = peer else {
//                            return false
//                        }
//                        return user.username == "wallet"
//                    }
//                    .map {
//                        ($0, peersMap[$0.peerId]!)
//                    }
//                    .first
//                
//                guard let bot = result?.0,
//                      let peer = result?.1 else {
//                    return .single(nil)
//                }
//                
//                return .single(AttachMenuBot(peer: peer, shortName: bot.name, icons: bot.icons, peerTypes: bot.peerTypes, flags: bot.flags))
//            }
//        }
//        |> filter { $0 != nil }
//        |> take(1)
//        |> deliverOnMainQueue)
//        .start(next: { [weak self] walletBot in
//            guard let self else { return }
//            self.walletBot = walletBot
//            self.walletController = self.walletControllerIfPossible()
//            if let tabs, tabs.contains(where: { $0 == .wallet }) {
//                updateRootControllers(tabs: tabs)
//            }
//        })
        
//        appsBotDisposable = (
//            context.engine.peers.resolvePeerByName(name: "@tapps", referrer: nil, ageLimit: 10)
//            |> mapToSignal { result -> Signal<(TelegramUser, BotAppSettings?)?, NoError> in
//                guard case let .result(peer) = result else {
//                    return .single(nil)
//                }
//                guard case let .user(user) = peer else {
//                    return .single(nil)
//                }
//                return context.engine.data.get(TelegramEngine.EngineData.Item.Peer.BotAppSettings(id: user.id))
//                |> mapToSignal {
//                    return .single((user, $0))
//                }
//            }
//            |> filter { $0 != nil }
//            |> take(1)
//            |> deliverOnMainQueue)
//        .start(next: { [weak self] in
//            guard let self, let result = $0 else { return }
//            let (user, appSettings) = result
//            guard let botInfo = user.botInfo, botInfo.flags.contains(.hasWebApp) else {
//                return
//            }
//            self.appsBot = user
//            self.appsBotSettings = appSettings
////            self.appsController = appsControllerIfPossible()
//            if let tabs, tabs.contains(where: { $0 == .apps }) {
//                updateRootControllers(tabs: tabs)
//            }
//            
//            let _ = (context.engine.messages.requestMainWebView(peerId: user.id, botId: user.id, source: .generic, themeParams: generateWebAppThemeParams(presentationData.theme))
//                     |> take(1)
//                     |> deliverOnMainQueue)
//                .start(next: { [weak self] in
//                    guard let self else { return }
//                    self.appsBotWebViewResult = $0
//                    self.appsController = appsControllerIfPossible()
//                    if let tabs, tabs.contains(where: { $0 == .apps }) {
//                        updateRootControllers(tabs: tabs)
//                    }
//                })
//        })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.permissionsDisposable?.dispose()
        self.presentationDataDisposable?.dispose()
        self.applicationInFocusDisposable?.dispose()
        self.storyUploadEventsDisposable?.dispose()
        self.walletDisposable?.dispose()
        self.appsBotDisposable?.dispose()
    }
    
    public func getContactsController() -> ViewController? {
        return self.contactsController
    }
    
    public func getChatsController() -> ViewController? {
        return self.chatListController
    }
    
    public func getPrivacySettings() -> Promise<AccountPrivacySettings?>? {
        return self.accountSettingsController?.privacySettings
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let needsRootWallpaperBackgroundNode: Bool
        if case .regular = layout.metrics.widthClass {
            needsRootWallpaperBackgroundNode = true
        } else {
            needsRootWallpaperBackgroundNode = false
        }
        
        if needsRootWallpaperBackgroundNode {
            let detailsPlaceholderNode: DetailsChatPlaceholderNode
            if let current = self.detailsPlaceholderNode {
                detailsPlaceholderNode = current
            } else {
                detailsPlaceholderNode = DetailsChatPlaceholderNode(context: self.context)
                detailsPlaceholderNode.wallpaperBackgroundNode.update(wallpaper: self.presentationData.chatWallpaper, animated: false)
                self.detailsPlaceholderNode = detailsPlaceholderNode
            }
            self.updateDetailsPlaceholderNode(detailsPlaceholderNode)
        } else if let _ = self.detailsPlaceholderNode {
            self.detailsPlaceholderNode = nil
            self.updateDetailsPlaceholderNode(nil)
        }
    
        super.containerLayoutUpdated(layout, transition: transition)
    }
    
    public func addRootControllers(
        tabs: [DAppTab]
    ) {
        self.tabs = tabs
        let tabBarController = TabBarControllerImpl(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), theme: TabBarControllerTheme(rootControllerTheme: self.presentationData.theme))
        tabBarController.navigationPresentation = .master
        let chatListController = self.context.sharedContext.makeChatListController(context: self.context, location: .chatList(groupId: .root), controlsHistoryPreload: true, hideNetworkActivityStatus: false, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
        let newsFeedController = self.context.sharedContext.makeNewsFeedController(context: self.context)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            chatListController.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
        }
        let callListController = CallListController(context: self.context, mode: .tab)
        
        var controllers: [ViewController] = []
        
        let contactsController = ContactsController(context: self.context)
        contactsController.switchToChatsController = {  [weak self] in
            self?.openChatsController(activateSearch: false)
        }
        
        var restoreSettignsController: (ViewController & SettingsController)?
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            restoreSettignsController = sharedContext.switchingData.settingsController
        }
        restoreSettignsController?.updateContext(context: self.context)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            sharedContext.switchingData = (nil, nil, nil)
        }
        
        let dahlSettingsController = {
            let icon = UIImage(bundleImageName: "Chat List/Tabs/IconDahl")
            let controller = dalsettingsController(
                context: self.context,
                tabBarItem: ItemListControllerTabBarItem(
                    title: "Dahl.TabTitle".tp_loc(lang: presentationData.strings.baseLanguageCode),
                    image: icon,
                    selectedImage: icon
                )
            )
            return controller
        }()
        
        let accountSettingsController = PeerInfoScreenImpl(context: self.context, updatedPresentationData: nil, peerId: self.context.account.peerId, avatarInitiallyExpanded: false, isOpenedFromChat: false, nearbyPeerDistance: nil, reactionSourceMessageId: nil, callMessages: [], isSettings: true)
        accountSettingsController.tabBarItemDebugTapAction = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.pushViewController(debugController(sharedContext: strongSelf.context.sharedContext, context: strongSelf.context))
        }
        accountSettingsController.parentController = self
        
//        let walletController = walletControllerIfPossible()
        
//        let appsController = appsControllerIfPossible()
        
        let wallController = DWallController(context: context)
        
        tabs.forEach {
            switch $0 {
            case .calls:
                controllers.append(callListController)
            case .chats:
                controllers.append(chatListController)
            case .contacts:
                controllers.append(contactsController)
            case .dahlSettings:
                controllers.append(dahlSettingsController)
            case .settings:
                controllers.append(accountSettingsController)
//            case .wallet:
//                if let walletController {
//                    controllers.append(walletController)
//                }
//            case .apps:
//                if let appsController {
//                    controllers.append(appsController)
//                }
                
            #if DEBUG
            case .wall:
                controllers.append(wallController)
            #endif
            }
        }
                
        let index = (restoreSettignsController != nil ? controllers.firstIndex(where: { $0 === accountSettingsController }) : controllers.firstIndex(where: { $0 === chatListController })) ?? 0
        tabBarController.setControllers(controllers, selectedIndex: index)
        
        self.contactsController = contactsController
        self.callListController = callListController
        self.chatListController = chatListController
        self.newsFeedController = newsFeedController
        self.accountSettingsController = accountSettingsController
        self.dahlSettingsController = dahlSettingsController
//        self.walletController = walletController
//        self.appsController = appsController
        self.wallController = wallController
        self.rootTabController = tabBarController
        self.pushViewController(tabBarController, animated: false)
    }
        
    public func updateRootControllers(tabs: [DAppTab]) {
        guard let rootTabController = self.rootTabController as? TabBarControllerImpl else {
            return
        }
        self.tabs = tabs
        var controllers: [ViewController] = []
        
        tabs.forEach {
            switch $0 {
            case .calls:
                controllers.append(callListController!)
            case .chats:
                controllers.append(chatListController!)
            case .contacts:
                controllers.append(contactsController!)
            case .dahlSettings:
                controllers.append(dahlSettingsController!)
            case .settings:
                controllers.append(accountSettingsController!)
//            case .wallet:
//                if let walletController {
//                    controllers.append(walletController)
//                }
//            case .apps:
//                if let appsController {
//                    controllers.append(appsController)
//                }
                
            #if DEBUG
            case .wall:
                controllers.append(wallController!)
            #endif
            }
        }
        
        let selectedIndex = controllers.firstIndex { $0 === rootTabController.currentController } ?? controllers.firstIndex { $0 === accountSettingsController }
        rootTabController.setControllers(controllers, selectedIndex: selectedIndex)
    }
    
    public func openChatsController(activateSearch: Bool, filter: ChatListSearchFilter = .chats, query: String? = nil) {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        if activateSearch {
            self.popToRoot(animated: false)
        }
        
        if let index = rootTabController.controllers.firstIndex(where: { $0 is ChatListController}) {
            rootTabController.selectedIndex = index
        }
        
        if activateSearch {
            self.chatListController?.activateSearch(filter: filter, query: query)
        }
    }
    
    public func openRootCompose() {
        self.chatListController?.activateCompose()
    }
    
    public func openRootCamera() {
        guard let controller = self.viewControllers.last as? ViewController else {
            return
        }
        controller.view.endEditing(true)
        presentedLegacyShortcutCamera(context: self.context, saveCapturedMedia: false, saveEditedPhotos: false, mediaGrouping: true, parentController: controller)
    }
    
    public func openAppIcon() {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        self.popToRoot(animated: false)
        
        if let index = rootTabController.controllers.firstIndex(where: { $0 is PeerInfoScreenImpl }) {
            rootTabController.selectedIndex = index
        }
        
        let themeController = themeSettingsController(context: self.context, focusOnItemTag: .icon)
        var controllers: [UIViewController] = Array(self.viewControllers.prefix(1))
        controllers.append(themeController)
        self.setViewControllers(controllers, animated: true)
    }
    
    @discardableResult
    public func openStoryCamera(customTarget: Stories.PendingTarget?, transitionIn: StoryCameraTransitionIn?, transitionedIn: @escaping () -> Void, transitionOut: @escaping (Stories.PendingTarget?, Bool) -> StoryCameraTransitionOut?) -> StoryCameraTransitionInCoordinator? {
        guard let controller = self.viewControllers.last as? ViewController else {
            return nil
        }
        controller.view.endEditing(true)
        
        let context = self.context
        
        let externalState = MediaEditorTransitionOutExternalState(
            storyTarget: nil,
            isForcedTarget: customTarget != nil,
            isPeerArchived: false,
            transitionOut: nil
        )
        
        var presentImpl: ((ViewController) -> Void)?
        var returnToCameraImpl: (() -> Void)?
        var dismissCameraImpl: (() -> Void)?
        var showDraftTooltipImpl: (() -> Void)?
        let cameraController = CameraScreenImpl(
            context: context,
            mode: .story,
            transitionIn: transitionIn.flatMap {
                if let sourceView = $0.sourceView {
                    return CameraScreenImpl.TransitionIn(
                        sourceView: sourceView,
                        sourceRect: $0.sourceRect,
                        sourceCornerRadius: $0.sourceCornerRadius
                    )
                } else {
                    return nil
                }
            },
            transitionOut: { finished in
                if let transitionOut = (externalState.transitionOut ?? transitionOut)(finished ? externalState.storyTarget : nil, externalState.isPeerArchived), let destinationView = transitionOut.destinationView {
                    return CameraScreenImpl.TransitionOut(
                        destinationView: destinationView,
                        destinationRect: transitionOut.destinationRect,
                        destinationCornerRadius: transitionOut.destinationCornerRadius,
                        completion: transitionOut.completion
                    )
                } else {
                    return nil
                }
            },
            completion: { result, resultTransition, dismissed in
                let subject: Signal<MediaEditorScreenImpl.Subject?, NoError> = result
                |> map { value -> MediaEditorScreenImpl.Subject? in
                    func editorPIPPosition(_ position: CameraScreenImpl.PIPPosition) -> MediaEditorScreenImpl.PIPPosition {
                        switch position {
                        case .topLeft:
                            return .topLeft
                        case .topRight:
                            return .topRight
                        case .bottomLeft:
                            return .bottomLeft
                        case .bottomRight:
                            return .bottomRight
                        }
                    }
                    switch value {
                    case .pendingImage:
                        return nil
                    case let .image(image):
                        return .image(image: image.image, dimensions: PixelDimensions(image.image.size), additionalImage: image.additionalImage, additionalImagePosition: editorPIPPosition(image.additionalImagePosition))
                    case let .video(video):
                        return .video(videoPath: video.videoPath, thumbnail: video.coverImage, mirror: video.mirror, additionalVideoPath: video.additionalVideoPath, additionalThumbnail: video.additionalCoverImage, dimensions: video.dimensions, duration: video.duration, videoPositionChanges: video.positionChangeTimestamps, additionalVideoPosition: editorPIPPosition(video.additionalVideoPosition))
                    case let .videoCollage(collage):
                        func editorCollageItem(_ item: CameraScreenImpl.Result.VideoCollage.Item) -> MediaEditorScreenImpl.Subject.VideoCollageItem {
                            let content: MediaEditorScreenImpl.Subject.VideoCollageItem.Content
                            switch item.content {
                            case let .image(image):
                                content = .image(image)
                            case let .video(path, duration):
                                content = .video(path, duration)
                            case let .asset(asset):
                                content = .asset(asset)
                            }
                            return MediaEditorScreenImpl.Subject.VideoCollageItem(
                                content: content,
                                frame: item.frame,
                                contentScale: item.contentScale,
                                contentOffset: item.contentOffset
                            )
                        }
                        return .videoCollage(items: collage.items.map { editorCollageItem($0) })
                    case let .asset(asset):
                        return .asset(asset)
                    case let .draft(draft):
                        return .draft(draft, nil)
                    }
                }
                
                var transitionIn: MediaEditorScreenImpl.TransitionIn?
                if let resultTransition, let sourceView = resultTransition.sourceView {
                    transitionIn = .gallery(
                        MediaEditorScreenImpl.TransitionIn.GalleryTransitionIn(
                            sourceView: sourceView,
                            sourceRect: resultTransition.sourceRect,
                            sourceImage: resultTransition.sourceImage
                        )
                    )
                } else {
                    transitionIn = .camera
                }
                
                let mediaEditorCustomTarget = customTarget.flatMap { value -> EnginePeer.Id? in
                    switch value {
                    case .myStories:
                        return nil
                    case let .peer(id):
                        return id
                    case let .botPreview(id, _):
                        return id
                    }
                }
                
                let controller = MediaEditorScreenImpl(
                    context: context,
                    mode: .storyEditor,
                    subject: subject,
                    customTarget: mediaEditorCustomTarget,
                    transitionIn: transitionIn,
                    transitionOut: { finished, isNew in
                        if finished, let transitionOut = (externalState.transitionOut ?? transitionOut)(externalState.storyTarget, false), let destinationView = transitionOut.destinationView {
                            return MediaEditorScreenImpl.TransitionOut(
                                destinationView: destinationView,
                                destinationRect: transitionOut.destinationRect,
                                destinationCornerRadius: transitionOut.destinationCornerRadius,
                                completion: transitionOut.completion
                            )
                        } else if !finished, let resultTransition, let (destinationView, destinationRect) = resultTransition.transitionOut(isNew) {
                            return MediaEditorScreenImpl.TransitionOut(
                                destinationView: destinationView,
                                destinationRect: destinationRect,
                                destinationCornerRadius: 0.0,
                                completion: nil
                            )
                        } else {
                            return nil
                        }
                    }, completion: { [weak self] result, commit in
                        guard let self else {
                            dismissCameraImpl?()
                            commit({})
                            return
                        }
                        
                        if let customTarget, case .botPreview = customTarget {
                            externalState.storyTarget = customTarget
                            self.proceedWithStoryUpload(target: customTarget, result: result, existingMedia: nil, forwardInfo: nil, externalState: externalState, commit: commit)
                            
                            dismissCameraImpl?()
                            return
                         } else {
                             let target: Stories.PendingTarget
                             let targetPeerId: EnginePeer.Id
                             if let customTarget, case let .peer(id) = customTarget {
                                 target = .peer(id)
                                 targetPeerId = id
                             } else {
                                 if let sendAsPeerId = result.options.sendAsPeerId {
                                     target = .peer(sendAsPeerId)
                                     targetPeerId = sendAsPeerId
                                 } else {
                                     target = .myStories
                                     targetPeerId = context.account.peerId
                                 }
                             }
                             externalState.storyTarget = target
                             
                             let _ = (self.context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: targetPeerId))
                             |> deliverOnMainQueue).startStandalone(next: { [weak self] peer in
                                guard let self, let peer else {
                                    return
                                }
                                 
                                if case let .user(user) = peer {
                                    externalState.isPeerArchived = user.storiesHidden ?? false
                                } else if case let .channel(channel) = peer {
                                    externalState.isPeerArchived = channel.storiesHidden ?? false
                                }
                                 
                                self.proceedWithStoryUpload(target: target, result: result, existingMedia: nil, forwardInfo: nil, externalState: externalState, commit: commit)
                                
                                dismissCameraImpl?()
                            })
                        }
                    } as (MediaEditorScreenImpl.Result, @escaping (@escaping () -> Void) -> Void) -> Void
                )
                controller.cancelled = { showDraftTooltip in
                    if showDraftTooltip {
                        showDraftTooltipImpl?()
                    }
                    returnToCameraImpl?()
                }
                controller.dismissed = {
                    dismissed()
                }
                presentImpl?(controller)
            }
        )
        cameraController.transitionedIn = transitionedIn
        controller.push(cameraController)
        presentImpl = { [weak cameraController] c in
            if let navigationController = cameraController?.navigationController as? NavigationController {
                var controllers = navigationController.viewControllers
                controllers.append(c)
                navigationController.setViewControllers(controllers, animated: false)
            }
        }
        dismissCameraImpl = { [weak cameraController] in
            cameraController?.dismiss(animated: false)
        }
        returnToCameraImpl = { [weak cameraController] in
            if let cameraController {
                cameraController.returnFromEditor()
            }
        }
        showDraftTooltipImpl = { [weak cameraController] in
            if let cameraController {
                cameraController.presentDraftTooltip()
            }
        }
        return StoryCameraTransitionInCoordinator(
            animateIn: { [weak cameraController] in
                if let cameraController {
                    cameraController.updateTransitionProgress(0.0, transition: .immediate)
                    cameraController.completeWithTransitionProgress(1.0, velocity: 0.0, dismissing: false)
                }
            },
            updateTransitionProgress: { [weak cameraController] transitionFraction in
                if let cameraController {
                    cameraController.updateTransitionProgress(transitionFraction, transition: .immediate)
                }
            },
            completeWithTransitionProgressAndVelocity: { [weak cameraController] transitionFraction, velocity in
                if let cameraController {
                    cameraController.completeWithTransitionProgress(transitionFraction, velocity: velocity, dismissing: false)
                }
            })
    }
    
    public func proceedWithStoryUpload(target: Stories.PendingTarget, result: MediaEditorScreenResult, existingMedia: EngineMedia?, forwardInfo: Stories.PendingForwardInfo?, externalState: MediaEditorTransitionOutExternalState, commit: @escaping (@escaping () -> Void) -> Void) {
        guard let result = result as? MediaEditorScreenImpl.Result else {
            return
        }
        let context = self.context
        let targetPeerId: EnginePeer.Id?
        switch target {
        case let .peer(peerId):
            targetPeerId = peerId
        case .myStories:
            targetPeerId = context.account.peerId
        case .botPreview:
            targetPeerId = nil
        }

        if let rootTabController = self.rootTabController {
            if let index = rootTabController.controllers.firstIndex(where: { $0 is ChatListController}) {
                rootTabController.selectedIndex = index
            }
            if forwardInfo != nil {
                var viewControllers = self.viewControllers
                var dismissNext = false
                var range: Range<Int>?
                for i in (0 ..< viewControllers.count).reversed() {
                    let controller = viewControllers[i]
                    if controller is MediaEditorScreen {
                        dismissNext = true
                    }
                    if dismissNext {
                        if controller !== self.rootTabController {
                            if let current = range {
                                range = current.lowerBound - 1 ..< current.upperBound
                            } else {
                                range = i ..< i
                            }
                        } else {
                            break
                        }
                    }
                }
                if let range {
                    viewControllers.removeSubrange(range)
                    self.setViewControllers(viewControllers, animated: false)
                }
            } else if self.viewControllers.contains(where: { $0 is PeerInfoStoryGridScreen }) {
                var viewControllers: [UIViewController] = []
                for i in (0 ..< self.viewControllers.count) {
                    let controller = self.viewControllers[i]
                    if i == 0 {
                        viewControllers.append(controller)
                    } else if controller is MediaEditorScreen {
                        viewControllers.append(controller)
                    } else if controller is ShareWithPeersScreen {
                        viewControllers.append(controller)
                    }
                }
                self.setViewControllers(viewControllers, animated: false)
            }
        }
        
        let completionImpl: () -> Void = { [weak self] in
            guard let self else {
                return
            }
            
            var chatListController: ChatListControllerImpl?
            
            if externalState.isPeerArchived {
                var viewControllers = self.viewControllers
                
                let archiveController = ChatListControllerImpl(context: context, location: .chatList(groupId: .archive), controlsHistoryPreload: false, hideNetworkActivityStatus: false, previewing: false, enableDebugActions: false)
                if !externalState.isForcedTarget {
                    externalState.transitionOut = archiveController.storyCameraTransitionOut()
                }
                chatListController = archiveController
                viewControllers.insert(archiveController, at: 1)
                self.setViewControllers(viewControllers, animated: false)
            } else {
                chatListController = self.chatListController as? ChatListControllerImpl
                if !externalState.isForcedTarget {
                    externalState.transitionOut = chatListController?.storyCameraTransitionOut()
                }
            }
             
            if let chatListController {
                let _ = (chatListController.hasPendingStories
                |> filter { $0 }
                |> take(1)
                |> timeout(externalState.isPeerArchived ? 0.5 : 0.25, queue: .mainQueue(), alternate: .single(true))
                |> deliverOnMainQueue).startStandalone(completed: { [weak chatListController] in
                    guard let chatListController else {
                        return
                    }
                    
                    if let targetPeerId {
                        chatListController.scrollToStories(peerId: targetPeerId)
                    }
                    Queue.mainQueue().justDispatch {
                        commit({})
                    }
                })
            } else {
                Queue.mainQueue().justDispatch {
                    commit({})
                }
            }
        }
        
        if let _ = self.chatListController as? ChatListControllerImpl {
            var media: EngineStoryInputMedia?
            
            if let mediaResult = result.media {
                switch mediaResult {
                case let .image(image, dimensions):
                    let tempFile = TempBox.shared.tempFile(fileName: "file")
                    defer {
                        TempBox.shared.dispose(tempFile)
                    }
                    if let imageData = compressImageToJPEG(image, quality: 0.7, tempFilePath: tempFile.path) {
                        media = .image(dimensions: dimensions, data: imageData, stickers: result.stickers)
                    }
                case let .video(content, firstFrameImage, values, duration, dimensions):
                    let adjustments: VideoMediaResourceAdjustments
                    if let valuesData = try? JSONEncoder().encode(values) {
                        let data = MemoryBuffer(data: valuesData)
                        let digest = MemoryBuffer(data: data.md5Digest())
                        adjustments = VideoMediaResourceAdjustments(data: data, digest: digest, isStory: true)
                        
                        let resource: TelegramMediaResource
                        switch content {
                        case let .imageFile(path):
                            resource = LocalFileVideoMediaResource(randomId: Int64.random(in: .min ... .max), path: path, adjustments: adjustments)
                        case let .videoFile(path):
                            resource = LocalFileVideoMediaResource(randomId: Int64.random(in: .min ... .max), path: path, adjustments: adjustments)
                        case let .asset(localIdentifier):
                            resource = VideoLibraryMediaResource(localIdentifier: localIdentifier, conversion: .compress(adjustments))
                        }
                        let tempFile = TempBox.shared.tempFile(fileName: "file")
                        defer {
                            TempBox.shared.dispose(tempFile)
                        }
                        let imageData = firstFrameImage.flatMap { compressImageToJPEG($0, quality: 0.6, tempFilePath: tempFile.path) }
                        let firstFrameFile = imageData.flatMap { data -> TempBoxFile? in
                            let file = TempBox.shared.tempFile(fileName: "image.jpg")
                            if let _ = try? data.write(to: URL(fileURLWithPath: file.path)) {
                                return file
                            } else {
                                return nil
                            }
                        }
                        
                        var coverTime: Double?
                        if let coverImageTimestamp = values.coverImageTimestamp {
                            if let trimRange = values.videoTrimRange {
                                coverTime = min(duration, coverImageTimestamp - trimRange.lowerBound)
                            } else {
                                coverTime = min(duration, coverImageTimestamp)
                            }
                        }
                        
                        media = .video(dimensions: dimensions, duration: duration, resource: resource, firstFrameFile: firstFrameFile, stickers: result.stickers, coverTime: coverTime)
                    }
                default:
                    break
                }
            } else if let existingMedia {
                media = .existing(media: existingMedia._asMedia())
            }
            
            if let media {
                let _ = (context.engine.messages.uploadStory(
                    target: target,
                    media: media,
                    mediaAreas: result.mediaAreas,
                    text: result.caption.string,
                    entities: generateChatInputTextEntities(result.caption),
                    pin: result.options.pin,
                    privacy: result.options.privacy,
                    isForwardingDisabled: result.options.isForwardingDisabled,
                    period: result.options.timeout,
                    randomId: result.randomId,
                    forwardInfo: forwardInfo
                )
                |> deliverOnMainQueue).startStandalone(next: { stableId in
                    moveStorySource(engine: context.engine, peerId: context.account.peerId, from: result.randomId, to: Int64(stableId))
                })
            }
            completionImpl()
        }
    }
    
    public func openSettings() {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        self.popToRoot(animated: false)
    
        if let index = rootTabController.controllers.firstIndex(where: { $0 is PeerInfoScreenImpl }) {
            rootTabController.selectedIndex = index
        }
    }
    
    public func openBirthdaySetup() {
        self.accountSettingsController?.openBirthdaySetup()
    }
    
    public func openPhotoSetup() {
        self.accountSettingsController?.openAvatarSetup()
    }
    
    private func walletControllerIfPossible() -> ViewController? {
        guard let walletBot else { return nil }
        
        var openUrlImpl: ((String, Bool, Bool, @escaping () -> Void) -> Void)?
        
        let params = WebAppParameters(source: .generic, peerId: self.context.account.peerId, botId: walletBot.peer.id, botName: walletBot.peer.compactDisplayTitle, botVerified: walletBot.peer.isVerified, botAddress: walletBot.peer.addressName ?? "", appName: "", url: nil, queryId: nil, payload: nil, buttonText: nil, keepAliveSignal: nil, forceHasSettings: walletBot.flags.contains(.hasSettings), fullSize: true, isFullscreen: true, appSettings: nil
        )
        let updatedPresentationData = (initial: self.presentationData, signal: self.context.sharedContext.presentationData)
        let controller = StackedWebAppController(context: context, updatedPresentationData: updatedPresentationData, params: params, replyToMessageId: nil, threadId: nil)
        controller.openUrl = { url, concealed, forceUpdate, commit in
            openUrlImpl?(url, concealed, forceUpdate, commit)
        }
        controller.getNavigationController = { [weak self] in
            (self?.rootTabController?.navigationController as? NavigationController) ?? (self?.context.sharedContext.mainWindow?.viewController as? NavigationController)
        }
        
        openUrlImpl = { [weak self, weak controller] url, concealed, forceUpdate, commit in
            guard let self else { return }
            let _ = openUserGeneratedUrl(
                context: context,
                peerId: context.account.peerId,
                url: url,
                concealed: concealed,
                present: { [weak self] c in
                    self?.rootTabController?.present(c, in: .window(.root))
                },
                openResolved: { [weak self] result in
                    guard let self else { return }
                    var navigationController: NavigationController?
                    if let current = self.navigationController as? NavigationController {
                        navigationController = current
                    } else if let current = controller?.navigationController as? NavigationController {
                        navigationController = current
                    }
                    
                    context.sharedContext.openResolvedUrl(
                        result,
                        context: context,
                        urlContext: .generic,
                        navigationController: navigationController,
                        forceExternal: false,
                        forceUpdate: forceUpdate,
                        openPeer: { [weak self] peer, navigation in
                            if let self, let navigationController {
                                PeerInfoScreenImpl.openPeer(context: context, peerId: peer.id, navigation: navigation, navigationController: navigationController)
                            }
                            commit()
                        },
                        sendFile: nil,
                        sendSticker: nil,
                        sendEmoji: nil,
                        requestMessageActionUrlAuth: nil,
                        joinVoiceChat: nil,
                        present: { [weak self] c, a in
                            self?.rootTabController?.present(c, in: .window(.root), with: a)
                        },
                        dismissInput: { [weak self] in
                            self?.context.sharedContext.mainWindow?.viewController?.view.endEditing(false)
                        },
                        contentContext: nil,
                        progress: nil,
                        completion: nil
                    )
                })
        }
        let icon = UIImage(bundleImageName: "Chat List/Tabs/IconWallet")
        controller.tabBarItem.image = icon
        controller.tabBarItem.selectedImage = icon
        controller.tabBarItem.title = "Wallet.TabTitle".tp_loc(lang: presentationData.strings.baseLanguageCode)
        return controller
    }
    
    private func appsControllerIfPossible() -> ViewController? {
        guard let peer = appsBot else { return nil }
        var openUrlImpl: ((String, Bool, Bool, @escaping () -> Void) -> Void)?
        let updatedPresentationData = (initial: self.presentationData, signal: self.context.sharedContext.presentationData)
        let params = {
            if let appsBotWebViewResult {
                WebAppParameters(
                source: .simple, peerId: peer.id, botId: peer.id, botName: EnginePeer.user(peer).compactDisplayTitle, botVerified: peer.isVerified, botAddress: peer.addressName ?? "", appName: "", url: appsBotWebViewResult.url, queryId: appsBotWebViewResult.queryId, payload: nil, buttonText: nil, keepAliveSignal: appsBotWebViewResult.keepAliveSignal, forceHasSettings: false, fullSize: true, isFullscreen: true, appSettings: appsBotSettings)
            } else {
                WebAppParameters(
                source: .generic, peerId: peer.id, botId: peer.id, botName: EnginePeer.user(peer).compactDisplayTitle, botVerified: peer.isVerified, botAddress: peer.addressName ?? "", appName: "", url: "", queryId: nil, payload: nil, buttonText: nil, keepAliveSignal: nil, forceHasSettings: false, fullSize: true, isFullscreen: true, appSettings: appsBotSettings)
            }
        }()
            
        let controller = StackedWebAppController(context: context, updatedPresentationData: updatedPresentationData, params: params, replyToMessageId: nil, threadId: nil)
        
        controller.openUrl = { url, concealed, forceUpdate, commit in
            openUrlImpl?(url, concealed, forceUpdate, commit)
        }
        
        controller.getNavigationController = { [weak self] in
            (self?.rootTabController?.navigationController as? NavigationController) ?? (self?.context.sharedContext.mainWindow?.viewController as? NavigationController)
        }
        
        openUrlImpl = { [weak self, weak controller] url, concealed, forceUpdate, commit in
            guard let self else { return }
            let _ = openUserGeneratedUrl(
                context: context,
                peerId: context.account.peerId,
                url: url,
                concealed: concealed,
                present: { [weak controller] c in
                    controller?.present(c, in: .window(.root))
                },
                openResolved: { [weak self] result in
                    guard let self else { return }
                    var navigationController: NavigationController?
                    if let current = self.navigationController as? NavigationController {
                        navigationController = current
                    } else if let current = controller?.navigationController as? NavigationController {
                        navigationController = current
                    }
                    
                    context.sharedContext.openResolvedUrl(
                        result,
                        context: context,
                        urlContext: .generic,
                        navigationController: navigationController,
                        forceExternal: false,
                        forceUpdate: forceUpdate,
                        openPeer: { [weak self] peer, navigation in
                            if let self, let navigationController {
                                PeerInfoScreenImpl.openPeer(context: context, peerId: peer.id, navigation: navigation, navigationController: navigationController)
                            }
                            commit()
                        },
                        sendFile: nil,
                        sendSticker: nil,
                        sendEmoji: nil,
                        requestMessageActionUrlAuth: nil,
                        joinVoiceChat: nil,
                        present: { [weak self] c, a in
                            self?.rootTabController?.present(c, in: .window(.root), with: a)
                        },
                        dismissInput: { [weak self] in
                            self?.context.sharedContext.mainWindow?.viewController?.view.endEditing(false)
                        },
                        contentContext: nil,
                        progress: nil,
                        completion: nil
                    )
                })
        }
        
        let icon = UIImage(bundleImageName: "Chat List/Tabs/IconApps")
        controller.tabBarItem.image = icon
        controller.tabBarItem.selectedImage = icon
        controller.tabBarItem.title = "Apps.TabTitle".tp_loc(lang: presentationData.strings.baseLanguageCode)
        return controller
    }
}

//Xcode 16
#if canImport(ContactProvider)
extension MediaEditorScreenImpl.Result: @retroactive MediaEditorScreenResult {
    public var target: Stories.PendingTarget {
        if let sendAsPeerId = self.options.sendAsPeerId {
            return .peer(sendAsPeerId)
        } else {
            return .myStories
        }
    }
}
#else
extension MediaEditorScreenImpl.Result: MediaEditorScreenResult {
    public var target: Stories.PendingTarget {
        if let sendAsPeerId = self.options.sendAsPeerId {
            return .peer(sendAsPeerId)
        } else {
            return .myStories
        }
    }
}
#endif
