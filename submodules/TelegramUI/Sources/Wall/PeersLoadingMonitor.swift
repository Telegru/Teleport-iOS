import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext

public class PeersLoadingMonitor {
    private var checkDisposable: Disposable?
    private var timerDisposable: Disposable?
    private let postbox: Postbox
    private let timeout: Double
    private let queue: Queue
    private let loadedPromise = Promise<Bool>()
    private var timer: SwiftSignalKit.Timer? = nil
    
    public init(postbox: Postbox, timeout: Double = 15.0, queue: Queue = Queue.mainQueue()) {
        self.postbox = postbox
        self.timeout = timeout
        self.queue = queue
    }
    
    public func start() {
        self.checkWallPeersLoading()
        timer?.invalidate()
        timer = Timer(timeout: self.timeout, repeat: true, completion: { [weak self] in
            self?.checkWallPeersLoading()
        }, queue: self.queue)
        
        timer?.start()
        
        self.timerDisposable = ActionDisposable { [weak self] in
            self?.timer?.invalidate()
        }
    }
    
    public func stop() {
        self.checkDisposable?.dispose()
        self.timerDisposable?.dispose()
        self.checkDisposable = nil
        self.timerDisposable = nil
    }
    
    public func checkWallPeersLoading() {
        self.checkDisposable?.dispose()
        self.checkDisposable = self.areWallPeersLoaded().start(next: { [weak self] loaded in
            #if DEBUG

            let status = loaded ? "LOADED" : "NOT LOADED"
            print("Wall: peers loading status: \(status) - \(Date())")
            #endif

            if loaded {
                self?.stop()
                self?.loadedPromise.set(.single(true))
            }
        })
    }
    
    public func areWallPeersLoaded() -> Signal<Bool, NoError> {
        return self.postbox.transaction { transaction -> Bool in
            let root = transaction.allChatListHoles(groupId: .root)
            let archive = transaction.allChatListHoles(groupId: Namespaces.PeerGroup.archive)

            #if DEBUG

            if !root.isEmpty || !archive.isEmpty {
                print("Wall: Found \(root.count) chat list holes")
            }
            
            #endif
            
            return root.isEmpty && archive.isEmpty
        }
    }
    
    public var loadedSignal: Signal<Bool, NoError> {
        return self.loadedPromise.get()
    }
}
