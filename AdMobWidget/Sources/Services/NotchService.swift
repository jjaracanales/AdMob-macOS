import AppKit
import SwiftUI

/// Floating panel that expands from the notch area on hover.
/// Uses cached earnings data so it appears instantly.
@MainActor
class NotchService: ObservableObject {
    static let shared = NotchService()

    @Published var isEnabled: Bool = false {
        didSet {
            guard didFinishInit else { return }
            UserDefaults.standard.set(isEnabled, forKey: "notch_enabled")
            if isEnabled { startMonitoring() } else { stopMonitoring() }
        }
    }

    private var didFinishInit = false

    /// Cached earnings - updated by the app, used instantly by the notch
    var cachedEarnings: AdMobEarnings = .empty

    private var panel: NSPanel?
    private var hostingView: NSHostingView<NotchPanelView>?
    private var monitor: Any?
    private var isShowing = false
    private var hideTimer: Timer?
    /// Polling timer for mouse position (cheaper than global monitor)
    private var pollTimer: Timer?

    // Panel size
    private let panelWidth: CGFloat = 420
    private let panelHeight: CGFloat = 140

    /// The area where the notch physically is
    private var notchZone: NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let f = screen.frame
        return NSRect(x: f.midX - 120, y: f.maxY - 12, width: 240, height: 12)
    }

    /// Where the expanded panel sits (flush against top of screen)
    private var expandedFrame: NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let f = screen.frame
        return NSRect(
            x: f.midX - panelWidth / 2,
            y: f.maxY - panelHeight,
            width: panelWidth,
            height: panelHeight
        )
    }

    init() {
        let saved = UserDefaults.standard.bool(forKey: "notch_enabled")
        isEnabled = saved
        didFinishInit = true
        if saved { startMonitoring() }
    }

    /// Call this whenever earnings update - the notch will show fresh data next time
    func updateEarnings(_ earnings: AdMobEarnings) {
        cachedEarnings = earnings
        // If panel is showing, update it live
        hostingView?.rootView = NotchPanelView(earnings: earnings)
    }

    // MARK: - Mouse Monitoring

    private func startMonitoring() {
        stopMonitoring()
        // Use a polling timer instead of a global mouse-move monitor.
        // A global .mouseMoved monitor fires on every mouse movement system-wide,
        // which is expensive and can interfere with MenuBarExtra click handling.
        // Polling at ~10Hz is sufficient for notch hover detection and much cheaper.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkMouse() }
        }
    }

    private func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        pollTimer?.invalidate()
        pollTimer = nil
        hide()
    }

    private func checkMouse() {
        let mouse = NSEvent.mouseLocation

        if !isShowing && notchZone.contains(mouse) {
            show()
            return
        }

        if isShowing {
            // Keep open if mouse is over the panel or the notch zone
            let keepOpen = expandedFrame.insetBy(dx: -30, dy: -30)
            if keepOpen.contains(mouse) || notchZone.contains(mouse) {
                cancelHide()
            } else {
                scheduleHide()
            }
        }
    }

    private func scheduleHide() {
        guard hideTimer == nil else { return }
        hideTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.hide() }
        }
    }

    private func cancelHide() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    // MARK: - Show / Hide

    private func show() {
        guard !isShowing else { return }
        isShowing = true

        let frame = expandedFrame

        if panel == nil {
            let p = NSPanel(
                contentRect: frame,
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            p.isFloatingPanel = true
            p.level = .floating
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            p.titlebarAppearsTransparent = true
            p.titleVisibility = .hidden
            p.isMovableByWindowBackground = false
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel = p
        }

        // Use cached earnings (instant, no fetch needed)
        let view = NotchPanelView(earnings: cachedEarnings)
        let hv = NSHostingView(rootView: view)
        hv.wantsLayer = true
        hv.layer?.backgroundColor = .clear
        hostingView = hv
        panel?.contentView = hv

        // Start collapsed at notch position
        let collapsed = NSRect(
            x: frame.midX - 110,
            y: frame.maxY - 6,
            width: 220,
            height: 6
        )
        panel?.setFrame(collapsed, display: false)
        panel?.alphaValue = 0.3
        panel?.orderFront(nil)

        // Expand
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel?.animator().setFrame(frame, display: true)
            panel?.animator().alphaValue = 1
        }
    }

    private func hide() {
        cancelHide()
        guard isShowing, let panel else {
            isShowing = false
            return
        }

        let collapsed = NSRect(
            x: expandedFrame.midX - 110,
            y: expandedFrame.maxY - 6,
            width: 220,
            height: 6
        )

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(collapsed, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor [weak self] in
                self?.panel?.orderOut(nil)
                self?.isShowing = false
            }
        })
    }
}

// MARK: - Notch Panel View

struct NotchPanelView: View {
    let earnings: AdMobEarnings

    var body: some View {
        HStack(spacing: 0) {
            // Left: Today hero
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 11))
                    Text("AdMob")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Text(earnings.formatted(earnings.today))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Text(L10n.today)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))

                    if earnings.yesterday > 0 {
                        let diff = earnings.today - earnings.yesterday
                        let pct = (diff / earnings.yesterday) * 100
                        HStack(spacing: 2) {
                            Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 8, weight: .bold))
                            Text(String(format: "%+.0f%%", pct))
                                .font(.system(size: 10, weight: .bold).monospacedDigit())
                        }
                        .foregroundColor(diff >= 0 ? .green : .red)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 22)

            // Separator
            RoundedRectangle(cornerRadius: 1)
                .fill(.white.opacity(0.12))
                .frame(width: 1, height: 65)

            // Right: Other metrics
            VStack(alignment: .leading, spacing: 8) {
                metricRow("moon.fill", .indigo, L10n.yesterday, earnings.yesterday)
                metricRow("calendar", .cyan, L10n.last7Days, earnings.last7Days)
                metricRow("calendar.circle.fill", .green, L10n.thisMonth, earnings.thisMonth)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 18)
        }
        .padding(.top, 20)
        .padding(.bottom, 18)
        .padding(.trailing, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .mask(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
        )
    }

    private func metricRow(_ icon: String, _ color: Color, _ label: String, _ value: Double) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
                .frame(width: 14)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .frame(width: 60, alignment: .leading)
            Text(earnings.formatted(value))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
