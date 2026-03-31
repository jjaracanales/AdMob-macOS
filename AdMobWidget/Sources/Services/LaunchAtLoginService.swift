import Foundation
import ServiceManagement

/// Manages "Launch at Login" using SMAppService (macOS 13+)
@MainActor
class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published var isEnabled: Bool = false {
        didSet {
            guard didFinishInit else { return }
            setLaunchAtLogin(isEnabled)
        }
    }

    private var didFinishInit = false

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
        didFinishInit = true
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[LaunchAtLogin] Error: \(error)")
            // Revert the published value if it failed
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
