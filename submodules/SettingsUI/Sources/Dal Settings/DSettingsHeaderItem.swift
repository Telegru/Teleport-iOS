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
import PeerInfoCoverComponent
import AvatarNode
import EmojiStatusComponent
import ListItemComponentAdaptor
import ComponentDisplayAdapters
import MultilineTextComponent

final class DSettingsHeaderItem: ListViewItem, ItemListItem, ListItemComponentAdaptor.ItemGenerator {
    let context: AccountContext
    let theme: PresentationTheme
    let componentTheme: PresentationTheme
    let strings: PresentationStrings
    let topInset: CGFloat
    let sectionId: ItemListSectionId
    
    init(
        context: AccountContext,
        theme: PresentationTheme,
        strings: PresentationStrings,
        topInset: CGFloat,
        sectionId: ItemListSectionId
    ) {
        self.context = context
        self.theme = theme
        self.componentTheme = theme
        self.strings = strings
        self.topInset = topInset
        self.sectionId = sectionId
    }
    
//    func nodeConfiguredForParams(
//        async: @escaping (@escaping () -> Void) -> Void,
//        params: ListViewItemLayoutParams,
//        synchronousLoads: Bool,
//        previousItem: ListViewItem?,
//        nextItem: ListViewItem?,
//        completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void
//    ) {
//        async {
//            let node =
//        }
//    }
}

final class DSettingsHeaderItemNode: ListViewItemNode {
    private let background = ComponentView<Empty>()
    private let imageNode: ImageNode
    private let title = ComponentView<Empty>()
    private let subtitle = ComponentView<Empty>()
    
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    
    private var item: DSettingsHeaderItem?
    
    init() {
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.maskNode = ASImageNode()
        
        self.imageNode = ImageNode()
        self.imageNode.isLayerBacked = true
        
//        displayDimensions: CGSize = CGSize(width: 60.0, height: 60.0)
//        self.imageNode.clipsToBounds = true
//        self.imageNode.cornerRadius = displayDimensions.height * 0.25
        
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
                
                self.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                self.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                
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
                    self.topStripeNode.isHidden = true
                    self.bottomStripeNode.isHidden = true
                    self.maskNode.isHidden = true
                } else {
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
                
                let iconSize: CGFloat = 104.0
            })
        }
    }
}
