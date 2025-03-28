import Foundation

public enum MessageHistorySelectionDirection {
    case olderMessages
    case newerMessages
}

public enum MessageHistorySelectionRange {
    case fromBeginning
    case fromEnd
}

public struct MessageHistorySelectionOptions {
    public let boundAnchor: MessageIndex?
    public let direction: MessageHistorySelectionDirection
    
    public let range: MessageHistorySelectionRange
    
    public init(
        boundAnchor: MessageIndex? = nil,
        direction: MessageHistorySelectionDirection = .newerMessages,
        range: MessageHistorySelectionRange = .fromBeginning
    ) {
        self.boundAnchor = boundAnchor
        self.direction = direction
        self.range = range
    }
}
