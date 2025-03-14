import UIKit

public final class TPIconManager {
    public static let shared = TPIconManager()

    private var currentIconSet: IconSet

    private init() {
        self.currentIconSet = TGIconSet()
    }

    public func switchIconSet(use iconSet: IconSet) {
        self.currentIconSet = iconSet
    }

    public func icon(_ type: IconType) -> UIImage? {
        currentIconSet.icon(type)
    }
}
