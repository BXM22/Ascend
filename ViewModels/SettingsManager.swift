import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @Published var restTimerDuration: Int {
        didSet {
            UserDefaults.standard.set(restTimerDuration, forKey: "restTimerDuration")
        }
    }
    
    init() {
        // Load saved rest timer duration, default to 90 seconds
        self.restTimerDuration = UserDefaults.standard.object(forKey: "restTimerDuration") as? Int ?? 90
    }
}


