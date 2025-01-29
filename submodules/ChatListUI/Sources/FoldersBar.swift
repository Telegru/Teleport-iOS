//
//  FoldersBar.swift
//  Telegram
//
//  Created by Tagir Kuramshin on 24.01.2025.
//

import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ComponentFlow
import TelegramPresentationData

public final class FoldersBar: Component {
   
    public let tabsNode: ASDisplayNode?
    public let theme: PresentationTheme
    
    init(tabsNode: ASDisplayNode?,
         theme: PresentationTheme) {
        self.tabsNode = tabsNode
        self.theme = theme
    }
    
    public static func ==(lhs: FoldersBar, rhs: FoldersBar) -> Bool {
        if lhs.tabsNode !== rhs.tabsNode {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        return true
    }
    
    public func update(view: View, availableSize: CGSize, state: ComponentFlow.EmptyComponentState, environment: ComponentFlow.Environment<ComponentFlow.Empty>, transition: ComponentFlow.ComponentTransition) -> CGSize {
        view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    private struct CurrentLayout {
        var size: CGSize
        
        init(size: CGSize) {
            self.size = size
        }
    }

    public final class View: UIView {
        private let backgroundView: BlurredBackgroundView
        private var tabsNode: ASDisplayNode?
        
        private var component: FoldersBar?
        private var currentLayout: CurrentLayout?
        
        override public init(frame: CGRect) {
            self.backgroundView = BlurredBackgroundView(color: .clear, enableBlur: true)
            self.backgroundView.layer.anchorPoint = .zero
            super.init(frame: frame)
        
            self.addSubview(self.backgroundView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(component: FoldersBar, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
       
            let themeUpdated = self.component?.theme !== component.theme
         
            self.component = component
            
            if themeUpdated {
                self.backgroundView.updateColor(color: component.theme.rootController.navigationBar.blurredBackgroundColor, transition: .immediate)
            }
            
            let size = CGSize(width: availableSize.width, height: component.tabsNode == nil ? 0.0 : 46.0)
            self.currentLayout = CurrentLayout(size: size)
            
            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(), size: size))
            self.backgroundView.update(size: size, transition: transition.containedViewLayoutTransition)
            
            self.update(transition: transition)
           
            return size
        }
        
        public func update(transition: ComponentTransition) {
            guard let component = self.component, let currentLayout = self.currentLayout else {
                return
            }
            
            if let tabsNode = component.tabsNode {
                self.tabsNode = tabsNode
                var tabsNodeTransition = transition
                if tabsNode.view.superview !== self {
                    tabsNode.view.removeFromSuperview()
                    tabsNode.view.layer.anchorPoint = .zero
                    tabsNodeTransition = .immediate
                    tabsNode.view.alpha = 1.0
                    self.addSubview(tabsNode.view)
                }
                
                tabsNodeTransition.setFrameWithAdditivePosition(view: tabsNode.view, frame: CGRect(origin: CGPoint(), size: currentLayout.size))
            }else if self.tabsNode?.view.superview === self{
                self.tabsNode?.view.removeFromSuperview()
            }
        }
    }
}
