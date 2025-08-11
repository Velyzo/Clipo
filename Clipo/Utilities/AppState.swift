import Foundation
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()
    private init() {}
    
    @Published var openSettingsFromPopover: Bool = false
}
