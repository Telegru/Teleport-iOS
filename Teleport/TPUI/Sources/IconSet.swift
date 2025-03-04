import UIKit

public protocol IconSet {
    
    init()
    
    func icon(_ type: IconType) -> UIImage?
}
