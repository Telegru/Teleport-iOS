import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import MergeLists
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import AppBundle
import ContextUI
import ListItemComponentAdaptor
import HexColor
import GradientBackground

private struct DChatListStyleEntry: Comparable, Identifiable {
    let type: DChatListViewStyle
    let title: String
    let selected: Bool
    let theme: PresentationTheme
    
    var stableId: Int32 {
        return type.rawValue
    }
    
    static func ==(lhs: DChatListStyleEntry, rhs: DChatListStyleEntry) -> Bool {
        if lhs.type.rawValue != rhs.type.rawValue {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        if lhs.selected != rhs.selected {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        return true
    }
    
    static func <(lhs: DChatListStyleEntry, rhs: DChatListStyleEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(context: AccountContext, action: @escaping (DChatListViewStyle) -> Void) -> ListViewItem {
        DChatListStyleItem(
            context: context,
            type: self.type,
            selected: self.selected,
            title: self.title,
            theme: self.theme,
            action: action
        )
    }
}

private final class DChatListStyleItem: ListViewItem {
    let context: AccountContext
    let type: DChatListViewStyle
    let selected: Bool
    let title: String
    let theme: PresentationTheme
    
    let action: (DChatListViewStyle) -> Void
    
    init(context: AccountContext, type: DChatListViewStyle, selected: Bool, title: String, theme: PresentationTheme, action: @escaping (DChatListViewStyle) -> Void) {
        self.context = context
        self.type = type
        self.selected = selected
        self.title = title
        self.theme = theme
        self.action = action
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = DChatListStyleItemNode()
            let (nodeLayout, apply) = node.asyncLayout()(self, params)
            node.insets = nodeLayout.insets
            node.contentSize = nodeLayout.contentSize
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in
                        apply(false)
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? DChatListStyleItemNode {
                let layout = nodeValue.asyncLayout()
                
                async {
                    let (nodeLayout, apply) = layout(self, params)
                    Queue.mainQueue().async {
                        completion(nodeLayout, { _ in
                            apply(animation.isAnimated)
                        })
                    }
                }
            }
        }
    }
    
    var selectable = true
    func selected(listView: ListView) {
        self.action(self.type)
    }
}

private let textFont = Font.regular(12.0)
private let selectedTextFont = Font.bold(12.0)

private var cachedBorderImages: [String: UIImage] = [:]
private func generateBorderImage(theme: PresentationTheme, bordered: Bool, selected: Bool) -> UIImage? {
    let key = "\(theme.list.itemBlocksBackgroundColor.hexString)_\(selected ? "s" + theme.list.itemAccentColor.hexString : theme.list.disclosureArrowColor.hexString)"
    if let image = cachedBorderImages[key] {
        return image
    } else {
        let image = generateImage(CGSize(width: 32.0, height: 32.0), rotatedContext: { size, context in
            let bounds = CGRect(origin: CGPoint(), size: size)
            context.clear(bounds)

            let lineWidth: CGFloat
            if selected {
                lineWidth = 2.0
                context.setLineWidth(lineWidth)
                context.setStrokeColor(theme.list.itemBlocksBackgroundColor.cgColor)
                
                context.strokeEllipse(in: bounds.insetBy(dx: 1.0 + lineWidth / 2.0, dy: 1.0 + lineWidth / 2.0))
                
                var accentColor = theme.list.itemAccentColor
                if accentColor.rgb == 0xffffff {
                    accentColor = UIColor(rgb: 0x999999)
                }
                context.setStrokeColor(accentColor.cgColor)
            } else {
                context.setStrokeColor(theme.list.disclosureArrowColor.withAlphaComponent(0.4).cgColor)
                lineWidth = 1.0
            }

            if bordered || selected {
                context.setLineWidth(lineWidth)
                context.strokeEllipse(in: bounds.insetBy(dx: 1.0 + lineWidth / 2.0, dy: 1.0 + lineWidth / 2.0))
            }
        })?.stretchableImage(withLeftCapWidth: 16, topCapHeight: 16)
        cachedBorderImages[key] = image
        return image
    }
}

private final class DChatListStylePreviewNode: ASDisplayNode {
    private let topImageNode: ASImageNode
    private let topTextContainerNode: ASDisplayNode
    private let topTitleNode: ASDisplayNode
    private var topLineNodes: [ASDisplayNode] = []
    
    private let bottomImageNode: ASImageNode
    private let bottomTextContainerNode: ASDisplayNode
    private let bottomTitleNode: ASDisplayNode
    private var bottomLineNodes: [ASDisplayNode] = []
    
    private var validLayout: CGSize?
    private var currentTheme: PresentationTheme?
    
    var type: DChatListViewStyle? {
        didSet {
            if oldValue != self.type {
                bottomLineNodes = []
                topLineNodes = []
                
                let numberOfLines: Int = {
                    switch type {
                        case .doubleLine:
                            return 1
                        case .tripleLine:
                            return 2
                        default:
                            return 0
                    }
                }()
                (0..<numberOfLines).forEach { _ in
                    let lineNode = ASDisplayNode()
                    lineNode.cornerRadius = 1.5
                    lineNode.clipsToBounds = true
                    self.topLineNodes.append(lineNode)
                }
                
                self.topTextContainerNode.addSubnode(self.topTitleNode)
                self.topLineNodes.forEach {
                    self.topTextContainerNode.addSubnode($0)
                }
                
                (0..<numberOfLines).forEach { _ in
                    let lineNode = ASDisplayNode()
                    lineNode.cornerRadius = 1.5
                    lineNode.clipsToBounds = true
                    self.bottomLineNodes.append(lineNode)
                }
                
                self.bottomTextContainerNode.addSubnode(self.bottomTitleNode)
                self.bottomLineNodes.forEach {
                    self.bottomTextContainerNode.addSubnode($0)
                }
            }
        }
    }
    
    override init() {
        self.topImageNode = ASImageNode()
        self.topImageNode.isLayerBacked = true
        self.bottomImageNode = ASImageNode()
        self.bottomImageNode.isLayerBacked = true
        
        self.topTextContainerNode = ASDisplayNode()
        self.topTextContainerNode.backgroundColor = .clear
        
        self.topTitleNode = ASDisplayNode()
        self.topTitleNode.cornerRadius = 1.5
        self.topTitleNode.clipsToBounds = true
        
        self.bottomTextContainerNode = ASDisplayNode()
        self.bottomTextContainerNode.backgroundColor = .clear
        
        self.bottomTitleNode = ASDisplayNode()
        self.bottomTitleNode.cornerRadius = 1.5
        self.bottomTitleNode.clipsToBounds = true
        
        super.init()
        
        self.addSubnode(self.topImageNode)
        self.addSubnode(self.topTextContainerNode)
        self.addSubnode(self.bottomImageNode)
        self.addSubnode(self.bottomTextContainerNode)
    }
    
    func updateLayout(size: CGSize) {
        self.validLayout = size
        
        let imageSideSize = 16.0
        let topImageY = (size.height - imageSideSize * 2.0 - 6.0) / 2.0
        let imageSize = CGSize(width: imageSideSize, height: imageSideSize)
        topImageNode.frame = CGRect(origin: CGPoint(x: 12.0, y: topImageY), size: imageSize)
        
        bottomImageNode.frame = CGRect(origin: CGPoint(x: 12.0, y: topImageNode.frame.maxY + 6.0), size: imageSize)
        
        topTitleNode.frame = CGRect(origin: .zero, size: CGSize(width: 30, height: 3))
        topLineNodes.enumerated().forEach { index, node in
            let y: CGFloat
            if index == 0 {
                y = topTitleNode.frame.maxY + 3.0
            } else {
                y = topLineNodes[index - 1].frame.maxY + 3.0
            }
            node.frame = CGRect(x: 0, y: y, width: 52, height: 3)
        }
        let topTextContainerHeight: CGFloat = (topLineNodes.last ?? topTitleNode).frame.maxY
        topTextContainerNode.frame = CGRect(
            x: 31.0,
            y: topImageNode.frame.center.y - topTextContainerHeight / 2.0,
            width: 52.0,
            height: topTextContainerHeight
        )
        
        bottomTitleNode.frame = CGRect(origin: .zero, size: CGSize(width: 30, height: 3))
        bottomLineNodes.enumerated().forEach { index, node in
            let y: CGFloat
            if index == 0 {
                y = bottomTitleNode.frame.maxY + 3.0
            } else {
                y = bottomLineNodes[index - 1].frame.maxY + 3.0
            }
            node.frame = CGRect(x: 0, y: y, width: 52, height: 3)
        }
        let bottomTextContainerHeight: CGFloat = (bottomLineNodes.last ?? bottomTitleNode).frame.maxY
        bottomTextContainerNode.frame = CGRect(
            x: 31.0,
            y: bottomImageNode.frame.center.y - bottomTextContainerHeight / 2.0,
            width: 52.0,
            height: bottomTextContainerHeight
        )
    }
    
    func updateTheme(_ theme: PresentationTheme) {
        guard theme !== currentTheme else { return }
        self.currentTheme = theme
        
        self.backgroundColor = theme.list.blocksBackgroundColor
        self.topTitleNode.backgroundColor = theme.list.itemBlocksSeparatorColor
        self.topLineNodes.enumerated().forEach { index, node in
            node.backgroundColor = theme.list.itemBlocksSeparatorColor.withAlphaComponent(0.4)
        }
        self.bottomLineNodes.enumerated().forEach { index, node in
            node.backgroundColor = theme.list.itemBlocksSeparatorColor.withAlphaComponent(0.4)
        }
        self.bottomTitleNode.backgroundColor = theme.list.itemBlocksSeparatorColor
        
        let imageSkeletonImage = generateFilledRoundedRectImage(
            size: CGSize(width: 16, height: 16),
            cornerRadius: theme.squareStyle ? 2.0 : 8.0,
            color: theme.list.itemBlocksSeparatorColor
        )
        
        self.topImageNode.image = imageSkeletonImage
        self.bottomImageNode.image = imageSkeletonImage
    }
}

private final class DChatListStyleItemNode: ListViewItemNode {
    private let containerNode: ContextControllerSourceNode
    private let previewNode: DChatListStylePreviewNode
    private let overlayNode: ASImageNode
    private let titleNode: TextNode
    var snapshotView: UIView?
    
    var item: DChatListStyleItem?
    
    init() {
        self.containerNode = ContextControllerSourceNode()
        
        self.previewNode = DChatListStylePreviewNode()
        self.previewNode.cornerRadius = 12.0
        self.previewNode.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 91.0, height: 55.0)
        )
        self.previewNode.isLayerBacked = true
        
        self.overlayNode = ASImageNode()
        self.overlayNode.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 99.0, height: 63.0)
        )
        self.overlayNode.isLayerBacked = true
        
        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        
        super.init(layerBacked: false, dynamicBounce: false, rotated: false, seeThrough: false)
        
        self.addSubnode(self.containerNode)
        self.containerNode.addSubnode(self.previewNode)
        self.containerNode.addSubnode(self.overlayNode)
        self.containerNode.addSubnode(self.titleNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.layer.sublayerTransform = CATransform3DMakeRotation(CGFloat.pi / 2.0, 0.0, 0.0, 1.0)
    }
    
    func asyncLayout() -> (DChatListStyleItem, ListViewItemLayoutParams) -> (ListViewItemNodeLayout, (Bool) -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        
        let currentItem = self.item
        
        return { [weak self] item, params in
            var updatedType = false
            var updatedTheme = false
            var updatedSelected = false
            
            if currentItem?.type != item.type {
                updatedType = true
            }
            if currentItem?.theme !== item.theme {
                updatedTheme = true
            }
            if currentItem?.selected != item.selected {
                updatedSelected = true
            }
            
            let title = NSAttributedString(string: item.title, font: item.selected ? selectedTextFont : textFont, textColor: item.selected ? item.theme.list.itemAccentColor : item.theme.list.itemPrimaryTextColor)
            let (_, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: title, backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))
            let itemLayout = ListViewItemNodeLayout(contentSize: CGSize(width: 116.0, height: 116.0), insets: UIEdgeInsets())
            return (itemLayout, { animated in
                guard let self else { return }
                self.item = item
                
                if updatedType {
                    self.containerNode.frame = CGRect(origin: .zero, size: itemLayout.contentSize)
                    self.previewNode.type = item.type
                }
                self.containerNode.isGestureEnabled = true
                
                if updatedTheme || updatedSelected {
                    self.overlayNode.image = generateBorderImage(theme: item.theme, bordered: false, selected: item.selected)
                    self.previewNode.updateTheme(item.theme)
                }
                
                self.containerNode.frame = CGRect(origin: .zero, size: itemLayout.contentSize)
                
                let _ = titleApply()
                
                let previewSize = CGSize(width: 91.0, height: 55.0)
                self.previewNode.frame.origin = CGPoint(x: 12.0, y: 17.0)
                self.previewNode.updateLayout(size: previewSize)
                
                self.overlayNode.frame = CGRect(origin: CGPoint(x: 8.0, y: 13.0), size: CGSize(width: 99.0, height: 63.0))
                self.titleNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 86.0), size: CGSize(width: itemLayout.contentSize.width, height: 16.0))
            })
        }
    }
    
    func prepareCrossfadeTransition() {
        guard self.snapshotView == nil else {
            return
        }
        
        if let snapshotView = self.containerNode.view.snapshotView(afterScreenUpdates: false) {
            self.view.insertSubview(snapshotView, aboveSubview: self.containerNode.view)
            self.snapshotView = snapshotView
        }
    }
    
    func animateCrossfadeTransition() {
        guard self.snapshotView?.layer.animationKeys()?.isEmpty ?? true else {
            return
        }
        
        self.snapshotView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak self] _ in
            self?.snapshotView?.removeFromSuperview()
            self?.snapshotView = nil
        })
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        super.animateInsertion(currentTimestamp, duration: duration, options: options)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        super.animateRemoved(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        super.animateAdded(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
}

final class DChatListStyleCarouselItem: ListViewItem, ItemListItem, ListItemComponentAdaptor.ItemGenerator {
    var sectionId: ItemListSectionId
    
    let context: AccountContext
    let theme: PresentationTheme
    let strings: PresentationStrings
    let types: [DChatListViewStyle]
    let currentType: DChatListViewStyle
    let updateType: (DChatListViewStyle) -> Void
    
    init(
        context: AccountContext,
        sectionId: ItemListSectionId,
        theme: PresentationTheme,
        strings: PresentationStrings,
        types: [DChatListViewStyle],
        currentType: DChatListViewStyle,
        updateType: @escaping (DChatListViewStyle) -> Void
    ) {
        self.context = context
        self.theme = theme
        self.strings = strings
        self.types = types
        self.sectionId = sectionId
        self.currentType = currentType
        self.updateType = updateType
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = DChatListStyleCarouselItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? DChatListStyleCarouselItemNode {
                let makeLayout = nodeValue.asyncLayout()

                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply()
                        })
                    }
                }
            }
        }
    }
    
    func item() -> ListViewItem {
        self
    }
    
    static func ==(lhs: DChatListStyleCarouselItem, rhs: DChatListStyleCarouselItem) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.currentType != rhs.currentType {
            return false
        }
        return true
    }
}

private struct DChatListViewStyleItemNodeTransition {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
    let crossfade: Bool
    let entries: [DChatListStyleEntry]
}

private func preparedTransition(context: AccountContext, action: @escaping (DChatListViewStyle) -> Void, from fromEntries: [DChatListStyleEntry], to toEntries: [DChatListStyleEntry], crossfade: Bool) -> DChatListViewStyleItemNodeTransition {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices.map {
        ListViewDeleteItem(index: $0, directionHint: nil)
    }
    let insertions = indicesAndItems.map {
        ListViewInsertItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(context: context, action: action), directionHint: .Down)
    }
    let updates = updateIndices.map {
        ListViewUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(context: context, action: action), directionHint: nil)
    }
    
    return DChatListViewStyleItemNodeTransition(deletions: deletions, insertions: insertions, updates: updates, crossfade: crossfade, entries: toEntries)
}

private func ensureTypeVisible(listNode: ListView, type: DChatListViewStyle, animated: Bool) -> Bool {
    var resultNode: DChatListStyleItemNode?
    listNode.forEachItemNode { node in
        if resultNode == nil, let node = node as? DChatListStyleItemNode {
            if node.item?.type == type {
                resultNode = node
            }
        }
    }
    
    if let resultNode = resultNode {
        listNode.ensureItemNodeVisible(resultNode, animated: animated, overflow: 57.0)
        return true
    } else {
        return false
    }
}

final class DChatListStyleCarouselItemNode: ListViewItemNode, ItemListItemNode {
    private let containerNode: ASDisplayNode
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private var snapshotView: UIView?
    
    private let listNode: ListView
    private var entries: [DChatListStyleEntry]?
    private var enqueuedTransitions: [DChatListViewStyleItemNodeTransition] = []
    private var initialized = false
    
    private var item: DChatListStyleCarouselItem?
    private var layoutParams: ListViewItemLayoutParams?
    
    var tag: ItemListItemTag?
    
    private var tapping = false
    
    init() {
        self.containerNode = ASDisplayNode()
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.maskNode = ASImageNode()
        
        self.listNode = ListView()
        self.listNode.transform = CATransform3DMakeRotation(-CGFloat.pi / 2.0, 0.0, 0.0, 1.0)
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.containerNode)
        self.addSubnode(self.listNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.listNode.view.disablesInteractiveTransitionGestureRecognizer = true
    }
    
    private func enqueueTransition(_ transition: DChatListViewStyleItemNodeTransition) {
        self.enqueuedTransitions.append(transition)
        
        if self.item != nil {
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
        }
    }
    
    private func dequeueTransition() {
        guard let item, let transition = self.enqueuedTransitions.first else {
            return
        }
        self.enqueuedTransitions.removeFirst()
        
        var options = ListViewDeleteAndInsertOptions()
        if self.initialized && transition.crossfade {
            options.insert(.AnimateCrossfade)
        }
        options.insert(.Synchronous)
        
        var scrollToItem: ListViewScrollToItem?
        if !self.initialized || !self.tapping {
            if let index = transition.entries.firstIndex(where: { entry in
                return entry.type == item.currentType
            }) {
                scrollToItem = ListViewScrollToItem(index: index, position: .bottom(-57.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Down)
                self.initialized = true
            }
        }
        
        self.listNode.transaction(deleteIndices: transition.deletions, insertIndicesAndItems: transition.insertions, updateIndicesAndItems: transition.updates, options: options, scrollToItem: scrollToItem, updateSizeAndInsets: nil, updateOpaqueState: nil, completion: { _ in
        })
    }
    
    func asyncLayout() -> (_ item: DChatListStyleCarouselItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { item, params, neighbors in
            let contentSize: CGSize
            let insets: UIEdgeInsets
            let separatorHeight = UIScreenPixel
            
            contentSize = CGSize(width: params.width, height: 115.0)
            insets = itemListNeighborsGroupedInsets(neighbors, params)
            
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (layout, { [weak self] in
                guard let self else { return }
                self.item = item
                self.layoutParams = params
                
                self.backgroundNode.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                self.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                self.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                
                if self.backgroundNode.supernode == nil {
                    self.containerNode.insertSubnode(self.backgroundNode, at: 0)
                }
                if self.topStripeNode.supernode == nil {
                    self.containerNode.insertSubnode(self.topStripeNode, at: 1)
                }
                if self.bottomStripeNode.supernode == nil {
                    self.containerNode.insertSubnode(self.bottomStripeNode, at: 2)
                }
                if self.maskNode.supernode == nil {
                    self.containerNode.insertSubnode(self.maskNode, at: 3)
                }
                
                if params.isStandalone {
                    self.topStripeNode.isHidden = true
                    self.bottomStripeNode.isHidden = true
                    self.maskNode.isHidden = true
                    self.backgroundNode.isHidden = true
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
                        bottomStripeInset = params.leftInset + 16.0
                        bottomStripeOffset = -separatorHeight
                            self.bottomStripeNode.isHidden = false
                    default:
                        bottomStripeInset = 0.0
                        bottomStripeOffset = 0.0
                        hasBottomCorners = true
                            self.bottomStripeNode.isHidden = hasCorners
                    }
                    
                    self.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(item.theme, top: hasTopCorners, bottom: hasBottomCorners) : nil
                    
                    self.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    self.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                }
                
                self.containerNode.frame = CGRect(x: 0.0, y: 0.0, width: contentSize.width, height: contentSize.height)
                self.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                self.maskNode.frame = self.backgroundNode.frame.insetBy(dx: params.leftInset, dy: 0.0)
                
                var listInsets = UIEdgeInsets()
                listInsets.top = params.leftInset + 8.0
                listInsets.bottom = params.rightInset + 8.0
                self.listNode.bounds = CGRect(x: 0.0, y: 0.0, width: contentSize.height, height: contentSize.width)
                self.listNode.position = CGPoint(x: contentSize.width / 2.0, y: contentSize.height / 2.0 + 2.0)
                self.listNode.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous], scrollToItem: nil, updateSizeAndInsets: ListViewUpdateSizeAndInsets(size: CGSize(width: contentSize.height, height: contentSize.width), insets: listInsets, duration: 0.0, curve: .Default(duration: nil)), stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
                
                var entries: [DChatListStyleEntry] = []
                let lang = item.strings.baseLanguageCode
                for type in item.types {
                    let title = switch type {
                        case .singleLine:
                            "DahlSettings.ChatsList.SingleLine".tp_loc(lang: lang)
                        case .doubleLine:
                            "DahlSettings.ChatsList.DoubleLine".tp_loc(lang: lang)
                        case .tripleLine:
                            "DahlSettings.ChatsList.TripleLine".tp_loc(lang: lang)
                    }
                    entries.append(
                        DChatListStyleEntry(
                            type: type,
                            title: title,
                            selected: item.currentType == type,
                            theme: item.theme
                        )
                    )
                }
                
                let action: (DChatListViewStyle) -> Void = { [weak self] type in
                    if let self {
                        self.tapping = true
                        self.item?.updateType(type)
                        let _ = ensureTypeVisible(listNode: self.listNode, type: type, animated: true)
                        Queue.mainQueue().after(0.4) {
                            self.tapping = false
                        }
                    }
                }
                let previousEntries = self.entries ?? []
                let crossfade = previousEntries.count != entries.count
                let transition = preparedTransition(context: item.context, action: action, from: previousEntries, to: entries, crossfade: crossfade)
                self.enqueueTransition(transition)
                
                self.entries = entries
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    func prepareCrossfadeTransition() {
        guard self.snapshotView == nil else {
            return
        }
        
        if let snapshotView = self.containerNode.view.snapshotView(afterScreenUpdates: false) {
            self.view.insertSubview(snapshotView, aboveSubview: self.containerNode.view)
            self.snapshotView = snapshotView
        }
        
        self.listNode.forEachVisibleItemNode { node in
            if let node = node as? DChatListStyleItemNode {
                node.prepareCrossfadeTransition()
            }
        }
    }
    
    func animateCrossfadeTransition() {
        guard self.snapshotView?.layer.animationKeys()?.isEmpty ?? true else {
            return
        }
        
        var views: [UIView] = []
        if let snapshotView = self.snapshotView {
            views.append(snapshotView)
            self.snapshotView = nil
        }
        
        self.listNode.forEachVisibleItemNode { node in
            if let node = node as? DChatListStyleItemNode {
                if let snapshotView = node.snapshotView {
                    views.append(snapshotView)
                    node.snapshotView = nil
                }
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            for view in views {
                view.alpha = 0.0
            }
        }, completion: { _ in
            for view in views {
                view.removeFromSuperview()
            }
        })
    }
}
