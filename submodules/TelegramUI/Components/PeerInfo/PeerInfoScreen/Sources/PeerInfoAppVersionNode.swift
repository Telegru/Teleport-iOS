import Foundation
import UIKit
import AsyncDisplayKit
import ContextUI
import TelegramPresentationData
import Display
import TelegramUIPreferences

final class PeerInfoAppVersionNode: ASDisplayNode {
    private let textNode: ASTextNode
    
    private var fontSize: PresentationFontSize?
    private var strings: PresentationStrings?
    private var currentParams: (width: CGFloat, safeInset: CGFloat)?
    private var currentMeasuredHeight: CGFloat?
    
    override init() {
        self.textNode = ASTextNode()
        self.textNode.clipsToBounds = false
        self.textNode.maximumNumberOfLines = 0
        self.textNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.addSubnode(self.textNode)
    }
    
    func update(width: CGFloat, safeInset: CGFloat, presentationData: PresentationData, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.currentParams = (width, safeInset)
        
        self.fontSize = presentationData.listsFontSize
        
        let font = Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize)
        
        let textColor = presentationData.theme.list.sectionHeaderTextColor
        let lang = presentationData.strings.baseLanguageCode
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let tgVersion = Bundle.main.infoDictionary?["TGAppVersion"] as? String ?? ""
        let attributedText = NSAttributedString(
            string: "Settings.AppVersion.Footer".tp_loc(lang: lang, with: appVersion, tgVersion),
            font: font,
            textColor: textColor,
            paragraphAlignment: .center
        )
        self.textNode.attributedText = attributedText
        
        let textWidth = width - safeInset * 2
        let calculatedRect = attributedText.boundingRect(
            with: CGSize(
                width: textWidth,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let textHeight = ceil(calculatedRect.size.height)
        
        transition.updateFrame(
            node: self.textNode,
            frame: CGRect(
                origin: CGPoint(x: safeInset, y: 0),
                size: CGSize(width: textWidth, height: textHeight)
            )
        )
        
        return textHeight
    }
}
