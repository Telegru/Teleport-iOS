import AccountContext
import AsyncDisplayKit
import AvatarNode
import ComponentDisplayAdapters
import ComponentFlow
import Display
import EmojiStatusComponent
import Foundation
import ItemListUI
import ListItemComponentAdaptor
import MultilineTextComponent
import Postbox
import PresentationDataUtils
import SwiftSignalKit
import TPStrings
import TPUI
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import UIKit

final class DIconSetPreviewItem: ListViewItem, ItemListItem, ListItemComponentAdaptor.ItemGenerator {
    let presentationData: ItemListPresentationData
    let sectionId: ItemListSectionId
    
    init(
        presentationData: ItemListPresentationData,
        sectionId: ItemListSectionId
    ) {
        self.presentationData = presentationData
        self.sectionId = sectionId
    }
    
    func nodeConfiguredForParams(
        async: @escaping (@escaping () -> Void) -> Void,
        params: ListViewItemLayoutParams,
        synchronousLoads: Bool,
        previousItem: ListViewItem?,
        nextItem: ListViewItem?,
        completion: @escaping (
            ListViewItemNode,
            @escaping () -> (
                Signal<Void, NoError>?, (ListViewItemApply) -> Void
            )
        ) -> Void
    ) {
        async {
            let node = DIconSetPreviewItemNode()
            let (layout, apply) = node.asyncLayout()(
                self, params,
                itemListNeighbors(
                    item: self, topItem: previousItem as? ItemListItem,
                    bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(
                    node,
                    {
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
        completion: @escaping (
            ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void
        ) -> Void
    ) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? DIconSetPreviewItemNode {
                let makeLayout = nodeValue.asyncLayout()
                
                async {
                    let (layout, apply) = makeLayout(
                        self, params,
                        itemListNeighbors(
                            item: self, topItem: previousItem as? ItemListItem,
                            bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(
                            layout,
                            { _ in
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
    
    static func == (lhs: DIconSetPreviewItem, rhs: DIconSetPreviewItem) -> Bool {
        if lhs.presentationData != rhs.presentationData {
            return false
        }
        return true
    }
}

final class DIconSetPreviewItemNode: ListViewItemNode {
    
    private var item: DIconSetPreviewItem?
    
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    
    private let scrollNode: ASScrollNode
    private var iconNodes: [ASDisplayNode]
    
    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.maskNode = ASImageNode()
        
        self.scrollNode = ASScrollNode()
        self.scrollNode.view.showsHorizontalScrollIndicator = false
        self.scrollNode.view.showsVerticalScrollIndicator = false
        self.scrollNode.canCancelAllTouchesInViews = true
        
        self.iconNodes = IconType.allCases.map { _ in
            return ASDisplayNode(viewBlock: {
                UIImageView()
            }, didLoad: nil)
        }
        
        super.init(layerBacked: false)
        
        self.iconNodes.forEach {
            self.scrollNode.addSubnode($0)
        }
    }
    
    override func didLoad() {
        super.didLoad()
        self.scrollNode.view.disablesInteractiveTransitionGestureRecognizer = true
    }
    
    func asyncLayout() -> (
        _ item: DIconSetPreviewItem, _ params: ListViewItemLayoutParams,
        _ neighbors: ItemListNeighbors
    ) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, neighbors in
            let separatorHeight = UIScreenPixel
            let height: CGFloat = 64.0
            let contentSize = CGSize(width: params.width, height: 64.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            
            let layout = ListViewItemNodeLayout(
                contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (
                layout,
                { [weak self] animation in
                    guard let self else { return }
                    let transition = animation.transition
                    
                    self.item = item
                    
                    self.backgroundNode.backgroundColor =
                    item.presentationData.theme.list
                        .itemBlocksBackgroundColor
                    self.topStripeNode.backgroundColor =
                    item.presentationData.theme.list
                        .itemBlocksSeparatorColor
                    self.bottomStripeNode.backgroundColor =
                    item.presentationData.theme.list
                        .itemBlocksSeparatorColor
                    
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
                    
                    self.backgroundNode.isHidden = false
                    
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
                    switch neighbors.bottom {
                    case .sameSection(false):
                        bottomStripeInset = 0.0
                        self.bottomStripeNode.isHidden = true
                    default:
                        bottomStripeInset = 0.0
                        hasBottomCorners = true
                        self.bottomStripeNode.isHidden = hasCorners
                    }
                    
                    self.maskNode.image =
                    hasCorners
                    ? PresentationResourcesItemList.cornersImage(
                        item.presentationData.theme,
                        top: hasTopCorners,
                        bottom: hasBottomCorners
                    )
                    : nil
                    
                    transition.updateFrame(
                        node: self.backgroundNode,
                        frame: CGRect(
                            origin: CGPoint(
                                x: 0.0, y: -min(insets.top, separatorHeight)),
                            size: CGSize(
                                width: params.width,
                                height: contentSize.height
                                + min(insets.top, separatorHeight)
                                + min(insets.bottom, separatorHeight))
                        )
                    )
                    transition.updateFrame(
                        node: self.maskNode,
                        frame: self.backgroundNode.frame.insetBy(
                            dx: params.leftInset, dy: 0.0)
                    )
                    transition.updateFrame(
                        node: self.topStripeNode,
                        frame: CGRect(
                            origin: CGPoint(
                                x: 0.0, y: -min(insets.top, separatorHeight)),
                            size: CGSize(
                                width: layoutSize.width, height: separatorHeight
                            )))
                    transition.updateFrame(
                        node: self.bottomStripeNode,
                        frame: CGRect(
                            origin: CGPoint(
                                x: bottomStripeInset,
                                y: contentSize.height - separatorHeight),
                            size: CGSize(
                                width: layoutSize.width - bottomStripeInset,
                                height: separatorHeight)))
                    
                    let iconsFrame = self.backgroundNode.frame.insetBy(
                        dx: params.leftInset, dy: 0.0)
                    
                    if self.scrollNode.supernode == nil {
                        self.addSubnode(self.scrollNode)
                    }
                    
                    let leftAndRightInset: CGFloat = 16
                    let topAndBottomInset: CGFloat = 20
                    let spaceBetweenIcons: CGFloat = 26
                    let iconSize: CGFloat = 24
                    let icons = IconType.allCases.compactMap {
                        TPIconManager.shared.icon($0)
                    }
                    
                    let contentSize = CGSize(
                        width: icons.reduce(0) { total, _ in
                            total + iconSize + spaceBetweenIcons
                        } + leftAndRightInset * 2 - spaceBetweenIcons, height: height)
                    
                    transition.updateFrame(
                        node: self.scrollNode,
                        frame: CGRect(
                            origin: maskNode.frame.origin,
                            size: iconsFrame.size
                        )
                    )
                    self.scrollNode.view.contentSize = contentSize
                    self.scrollNode.view.contentOffset = .zero
                    
                    var currentX: CGFloat = backgroundNode.frame.origin.x + leftAndRightInset
                    for (index, iconNode) in iconNodes.enumerated() {
                        if icons.count > index {
                            iconNode.isHidden = false
                            let image = icons[index]
                            (iconNode.view as! UIImageView).image = image.imageRendererFormat.opaque ? image : image.withRenderingMode(.alwaysTemplate)
                            iconNode.tintColor = item.presentationData.theme.rootController.tabBar.iconColor
                            iconNode.isUserInteractionEnabled = false
                            iconNode.tintColor =
                            item.presentationData.theme.rootController.tabBar.iconColor
                            iconNode.contentMode = image.size.width <= iconSize && image.size.height <= iconSize ? .center : .scaleAspectFit
                            transition.updateFrame(
                                node: iconNode,
                                frame: CGRect(
                                    origin: CGPoint(x: currentX, y: topAndBottomInset),
                                    size: CGSize(width: iconSize, height: iconSize)
                                )
                            )
                            currentX += iconSize + (index >= icons.count ? 0 : spaceBetweenIcons)
                        } else {
                            iconNode.isHidden = true
                        }
                    }
                }
            )
        }
    }
}
