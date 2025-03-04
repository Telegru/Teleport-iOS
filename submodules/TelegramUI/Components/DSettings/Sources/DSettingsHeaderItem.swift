import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import Postbox
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import ComponentFlow
import AvatarNode
import EmojiStatusComponent
import ListItemComponentAdaptor
import ComponentDisplayAdapters
import MultilineTextComponent
import TPStrings

final class DSettingsHeaderItem: ListViewItem, ItemListItem, ListItemComponentAdaptor.ItemGenerator {
    let context: AccountContext
    let theme: PresentationTheme
    let componentTheme: PresentationTheme
    let strings: PresentationStrings
    let topInset: CGFloat
    let sectionId: ItemListSectionId
    let showBackground: Bool
    
    init(
        context: AccountContext,
        theme: PresentationTheme,
        strings: PresentationStrings,
        topInset: CGFloat,
        sectionId: ItemListSectionId,
        showBackground: Bool
    ) {
        self.context = context
        self.theme = theme
        self.componentTheme = theme
        self.strings = strings
        self.topInset = topInset
        self.sectionId = sectionId
        self.showBackground = showBackground
    }
    
    func nodeConfiguredForParams(
        async: @escaping (@escaping () -> Void) -> Void,
        params: ListViewItemLayoutParams,
        synchronousLoads: Bool,
        previousItem: ListViewItem?,
        nextItem: ListViewItem?,
        completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void
    ) {
        async {
            let node = DSettingsHeaderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply(.None) })
                })
            }
        }
    }
    
    func updateNode(
        async: @escaping (@escaping () -> Void) -> Void,
        node: @escaping () -> ListViewItemNode,
        params: ListViewItemLayoutParams,
        previousItem: ListViewItem?,
        nextItem: ListViewItem?,
        animation: ListViewItemUpdateAnimation,
        completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void
    ) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? DSettingsHeaderItemNode {
                let makeLayout = nodeValue.asyncLayout()
                
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply(animation)
                        })
                    }
                }
            }
        }
    }
    
    func item() -> ListViewItem {
        self
    }
    
    static func ==(lhs: DSettingsHeaderItem, rhs: DSettingsHeaderItem) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.componentTheme !== rhs.componentTheme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.showBackground != rhs.showBackground {
            return false
        }
        return true
    }
}

final class DSettingsHeaderItemNode: ListViewItemNode {
    private let background = ComponentView<Empty>()
    private let imageNode: ImageNode
    private let title = ComponentView<Empty>()
    private let subtitle = ComponentView<Empty>()
    
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    
    private var item: DSettingsHeaderItem?
    
    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.maskNode = ASImageNode()
        
        self.imageNode = ImageNode()
        self.imageNode.isLayerBacked = true
        self.imageNode.clipsToBounds = true
        
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
    }
    
    func asyncLayout() -> (_ item: DSettingsHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, neighbors in
            let separatorHeight = UIScreenPixel
            
            let contentSize = CGSize(width: params.width, height: 210.0 + item.topInset)
            var insets = itemListNeighborsGroupedInsets(neighbors, params)
            if params.width <= 320.0 {
                insets.top = 0.0
            }
            
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (layout, { [weak self] animation in
                guard let self else {
                    return
                }
                self.item = item
                
                self.backgroundNode.backgroundColor = item.theme.rootController.navigationBar.opaqueBackgroundColor
                self.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                self.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                
                if self.backgroundNode.supernode == nil {
                    self.addSubnode(self.backgroundNode)
                }
                if self.topStripeNode.supernode == nil {
                    self.addSubnode(self.topStripeNode)
                }
                if self.bottomStripeNode.supernode == nil {
                    self.addSubnode(self.bottomStripeNode)
                }
                if self.maskNode.supernode == nil {
                    self.addSubnode(self.maskNode)
                }
                
                if params.isStandalone {
                    let transition = ContainedViewLayoutTransition.animated(duration: 0.2, curve: .easeInOut)
                    transition.updateAlpha(node: self.backgroundNode, alpha: item.showBackground ? 1.0 : 0.0)
                    transition.updateAlpha(node: self.bottomStripeNode, alpha: item.showBackground ? 1.0 : 0.0)
                    
                    self.backgroundNode.isHidden = false
                    self.topStripeNode.isHidden = true
                    self.bottomStripeNode.isHidden = false
                    self.maskNode.isHidden = true
                    
                    self.bottomStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: contentSize.height - separatorHeight), size: CGSize(width: layoutSize.width, height: separatorHeight))
                } else {
                    self.backgroundNode.isHidden = true
                    
                    let hasCorners = itemListHasRoundedBlockLayout(params)
                    var hasTopCorners = false
                    var hasBottomCorners = false
                    switch neighbors.top {
                    case .sameSection(false):
                        self.topStripeNode.isHidden = true
                    default:
                        hasTopCorners = true
                        self.topStripeNode.isHidden = hasCorners
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                    case .sameSection(false):
                        bottomStripeInset = 0.0
                        bottomStripeOffset = -separatorHeight
                        self.bottomStripeNode.isHidden = true
                    default:
                        bottomStripeInset = 0.0
                        bottomStripeOffset = 0.0
                        hasBottomCorners = true
                        self.bottomStripeNode.isHidden = hasCorners
                    }
                    
                    self.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(
                        item.componentTheme,
                        top: hasTopCorners,
                        bottom: hasBottomCorners
                    )
                    : nil
                    
                    self.topStripeNode.frame = CGRect(
                        origin: CGPoint(
                            x: 0.0,
                            y: -min(insets.top, separatorHeight)
                        ),
                        size: CGSize(
                            width: layoutSize.width,
                            height: separatorHeight
                        )
                    )
                    
                    self.bottomStripeNode.frame = CGRect(
                        origin: CGPoint(
                            x: bottomStripeInset,
                            y: contentSize.height + bottomStripeOffset
                        ),
                        size: CGSize(
                            width: layoutSize.width - bottomStripeInset,
                            height: separatorHeight
                        )
                    )
                }
                
                let backgroundFrame = CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: params.width,
                        height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)
                    )
                )
                
                let coverFrame = backgroundFrame.insetBy(dx: params.leftInset, dy: 0.0)
                
                let iconSize: CGFloat = 100.0
                let iconFrame = CGRect(
                    origin: CGPoint(
                        x: floor((coverFrame.width - iconSize) * 0.5),
                        y: coverFrame.minY + item.topInset + 24.0
                    ),
                    size: CGSize(
                        width: iconSize,
                        height: iconSize
                    )
                )
                
                self.imageNode.cornerRadius = iconSize * (item.theme.squareStyle ? 0.125 : 0.5)
                
                if let backgroundView = self.background.view {
                    if backgroundView.superview == nil {
                        backgroundView.clipsToBounds = true
                        self.view.insertSubview(backgroundView, at: 1)
                    }
                    backgroundView.frame = coverFrame
                }
                self.imageNode.setSignal(.single(UIImage(bundleImageName: "DahlSettings/AppIcon")))
                
                if self.imageNode.supernode == nil {
                    self.addSubnode(self.imageNode)
                }
                self.imageNode.frame = iconFrame.offsetBy(dx: coverFrame.minX, dy: 0.0)
                
                let titleColor = item.theme.list.itemPrimaryTextColor
                let subtitleColor = item.theme.list.itemSecondaryTextColor
                
                let maxTitleWidth = coverFrame.width - 16.0
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let titleString = "DahlSettings.Header.Title".tp_loc(lang: item.strings.baseLanguageCode, with: appVersion)
                let titleSize = self.title.update(
                    transition: .immediate,
                    component: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(string: titleString, font: Font.semibold(28.0), textColor: titleColor)),
                        maximumNumberOfLines: 1
                    )),
                    environment: {},
                    containerSize: CGSize(width: maxTitleWidth, height: 100.0)
                )
                
                let titleContentWidth = titleSize.width
                let titleFrame = CGRect(origin: CGPoint(x: coverFrame.minX + floor((coverFrame.width - titleContentWidth) * 0.5), y: iconFrame.maxY + 10.0), size: titleSize)
                if let titleView = self.title.view {
                    if titleView.superview == nil {
                        titleView.layer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
                        self.view.addSubview(titleView)
                    }
                    titleView.bounds = CGRect(origin: CGPoint(), size: titleFrame.size)
                    animation.animator.updatePosition(layer: titleView.layer, position: titleFrame.origin, completion: nil)
                }
                
                let subtitleString = "DahlSettings.Header.Subtitle".tp_loc(lang: item.strings.baseLanguageCode)
                
                let subtitleSize = self.subtitle.update(
                    transition: .immediate,
                    component: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(string: subtitleString, font: Font.regular(17.0), textColor: subtitleColor)),
                        horizontalAlignment: .center,
                        truncationType: .end,
                        maximumNumberOfLines: 0
                    )),
                    environment: {},
                    containerSize: CGSize(width: coverFrame.width - 16.0, height: 100.0)
                )
                let subtitleFrame = CGRect(origin: CGPoint(x: coverFrame.minX + floor((coverFrame.width - subtitleSize.width) * 0.5), y: titleFrame.maxY + 3.0), size: subtitleSize)
                if let subtitleView = self.subtitle.view {
                    if subtitleView.superview == nil {
                        self.view.addSubview(subtitleView)
                    }
                    subtitleView.frame = subtitleFrame
                }
                
                self.maskNode.frame = backgroundFrame.insetBy(dx: params.leftInset, dy: 0.0)
                self.backgroundNode.frame = backgroundFrame
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
