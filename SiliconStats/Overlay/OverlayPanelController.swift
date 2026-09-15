import AppKit
import SwiftUI

/// Borderless, transparent, always-on-top floating HUD panel.
public final class OverlayPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<OverlayContentView>?
    private let settingsStore: SettingsStore

    public init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    public var isVisible: Bool { panel?.isVisible ?? false }

    public func show() {
        if panel == nil {
            createPanel()
        }
        reposition()
        panel?.orderFrontRegardless()
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    public func toggle() {
        if isVisible { hide() } else { show() }
    }

    public func update(snapshot: PerformanceSnapshot) {
        let settings = settingsStore.settings
        guard settings.showOverlay else {
            hide()
            return
        }
        if panel == nil { createPanel() }
        hostingView?.rootView = OverlayContentView(snapshot: snapshot, settings: settings)
        hostingView?.invalidateIntrinsicContentSize()
        if let hostingView, let panel {
            let size = hostingView.fittingSize
            var frame = panel.frame
            frame.size = size
            panel.setFrame(frame, display: true)
        }
        applyClickThrough(settings.clickThrough)
        if settings.showOverlay {
            panel?.orderFrontRegardless()
            reposition()
        }
    }

    public func applyAppearance() {
        let settings = settingsStore.settings
        applyClickThrough(settings.clickThrough)
        reposition()
        if settings.showOverlay {
            show()
        } else {
            hide()
        }
    }

    private func createPanel() {
        let style: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 40),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = settingsStore.settings.clickThrough
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = !settingsStore.settings.clickThrough

        let root = OverlayContentView(snapshot: .empty, settings: settingsStore.settings)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)
        panel.contentView = hosting

        self.panel = panel
        self.hostingView = hosting
    }

    private func applyClickThrough(_ enabled: Bool) {
        panel?.ignoresMouseEvents = enabled
        panel?.isMovableByWindowBackground = !enabled
    }

    private func reposition() {
        guard let panel, let screen = NSScreen.main else { return }
        let padding = settingsStore.settings.screenEdgePadding
        let size = panel.frame.size
        let visible = screen.visibleFrame
        let origin: NSPoint
        switch settingsStore.settings.overlayPosition {
        case .topLeading:
            origin = NSPoint(x: visible.minX + padding, y: visible.maxY - size.height - padding)
        case .topTrailing:
            origin = NSPoint(x: visible.maxX - size.width - padding, y: visible.maxY - size.height - padding)
        case .bottomLeading:
            origin = NSPoint(x: visible.minX + padding, y: visible.minY + padding)
        case .bottomTrailing:
            origin = NSPoint(x: visible.maxX - size.width - padding, y: visible.minY + padding)
        }
        panel.setFrameOrigin(origin)
    }
}
