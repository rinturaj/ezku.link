import SwiftUI
import ScreenCaptureKit
import UniformTypeIdentifiers

public struct MenuBarPopoverView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @ObservedObject var coordinator = CastingCoordinator.shared
    @ObservedObject var permissionManager = PermissionManager.shared
    @ObservedObject var virtualDisplayManager = VirtualDisplayManager.shared
    
    @State private var showQRCode = false
    @State private var copiedURL = false
    @State private var copiedVideoURL = false
    @State private var isDropTargeted = false
    @State private var connectingDeviceId: String? = nil
    
    // Safety confirmation for virtual display deletion
    @State private var showDeleteExtendedConfirm = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            
            // Mode Segmented Capsule (Screen Mirror vs Video Cast)
            modeSegmentedPicker
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            // Scrollable Content Body
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Fullscreen Video Detected Alert (when in Screen Mode)
                    if let win = coordinator.detectedFullscreenWindow, coordinator.castingMode == .screen {
                        fullscreenVideoBanner(window: win)
                    }
                    
                    if coordinator.castingMode == .screen {
                        // Permission warning if unauthorized
                        if !permissionManager.hasScreenRecordingPermission {
                            permissionWarningCard
                        }
                        
                        // Active Streaming Hero Card (Only shown when live streaming)
                        if coordinator.isCasting {
                            activeScreenStreamHeroCard
                        }
                        
                        // Display Mode & Target Selector (Mirror Screen vs Extend to TV)
                        screenCastTypeSelectorCard
                        
                        // Direct 1-Click Destinations (Smart TVs & Web Browser)
                        destinationsDirectCastCard
                        
                        // Stream Quality & System Audio Settings
                        qualityAndAudioCard
                    } else {
                        // Dedicated Video Cast Mode Flow
                        videoCastingSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            Divider()
                .opacity(colorScheme == .dark ? 0.2 : 0.12)
            
            // Streamlined macOS-style Footer
            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
        }
        .frame(minWidth: 380, idealWidth: 388, maxWidth: 440)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .withinWindow)
                // Solid high-opacity backing fill for crystal-clear readability
                (colorScheme == .dark ? AppColors.brandDark : Color(NSColor.windowBackgroundColor))
                    .opacity(colorScheme == .dark ? 0.94 : 0.96)
            }
            .ignoresSafeArea()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    colorScheme == .dark
                    ? LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.08), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        colors: [Color.black.opacity(0.12), Color.black.opacity(0.05), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                    lineWidth: 1
                )
        )
        .confirmationDialog("Remove Extended Virtual Display?", isPresented: $showDeleteExtendedConfirm, titleVisibility: .visible) {
            Button("Remove Virtual Display", role: .destructive) {
                Task {
                    await coordinator.removeExtendedScreen()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will close your virtual second monitor and return any active windows to your main display.")
        }
        .onAppear {
            permissionManager.checkPermissions()
            coordinator.updateNetworkInfo()
            if permissionManager.hasScreenRecordingPermission {
                Task {
                    await coordinator.refreshTargets()
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 10) {
            // App Icon
            AppLogoView(size: 32)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("ezku.link")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? AppColors.brandLight : Color(NSColor.labelColor))
                        .tracking(-0.2)
                    
                    Text("PRO")
                        .font(.system(size: 11, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.07))
                        .foregroundColor(colorScheme == .dark ? AppColors.brandLight : Color(NSColor.labelColor))
                        .clipShape(Capsule())
                }
                
                Text(coordinator.statusMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("ezku.link PRO, \(coordinator.statusMessage)")
            
            Spacer()
            
            // Status Glowing Pill (Anthropic Green for Ready / Vibrant Red for Live)
            HStack(spacing: 5) {
                Circle()
                    .fill(isAnyCastingActive ? Color.red : AppColors.brandGreen)
                    .frame(width: 7, height: 7)
                    .shadow(
                        color: (isAnyCastingActive ? Color.red : AppColors.brandGreen).opacity(0.8),
                        radius: isAnyCastingActive ? 4 : 2
                    )
                
                Text(isAnyCastingActive ? "LIVE" : "READY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isAnyCastingActive ? .red : AppColors.brandGreen)
                    .tracking(0.3)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill((isAnyCastingActive ? Color.red : AppColors.brandGreen).opacity(colorScheme == .dark ? 0.18 : 0.12))
            )
            .overlay(
                Capsule()
                    .stroke((isAnyCastingActive ? Color.red : AppColors.brandGreen).opacity(0.35), lineWidth: 0.8)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("System status: \(isAnyCastingActive ? "Live casting" : "Ready")")
        }
    }
    
    private var isAnyCastingActive: Bool {
        coordinator.isCasting || coordinator.isVideoPlaying
    }
    
    // MARK: - Mode Segmented Picker
    private var modeSegmentedPicker: some View {
        HStack(spacing: 4) {
            modeTabButton(
                title: "Screen Mirror",
                icon: "rectangle.on.rectangle",
                isSelected: coordinator.castingMode == .screen
            ) {
                withAnimation(reduceMotion ? .default : .spring(response: 0.32, dampingFraction: 0.82)) {
                    coordinator.castingMode = .screen
                }
            }
            
            modeTabButton(
                title: "Video Cast",
                icon: "film.fill",
                isSelected: coordinator.castingMode == .videoFile
            ) {
                withAnimation(reduceMotion ? .default : .spring(response: 0.32, dampingFraction: 0.82)) {
                    coordinator.castingMode = .videoFile
                }
            }
        }
        .padding(3)
        .background(
            colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    colorScheme == .dark
                    ? Color.white.opacity(0.12)
                    : Color.black.opacity(0.08),
                    lineWidth: 0.8
                )
        )
    }
    
    private func modeTabButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                Text(title)
                    .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppColors.tabSelectedGradient)
                        .shadow(color: Color.black.opacity(0.35), radius: 4, y: 1)
                }
            }
            .foregroundColor(
                isSelected
                ? .white
                : AppColors.secondaryText
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Switches casting mode to \(title)")
    }
    
    // MARK: - Fullscreen Video Banner
    private func fullscreenVideoBanner(window: SCWindow) -> some View {
        let appName = window.owningApplication?.applicationName ?? "Video Player"
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.brandOrange.opacity(0.2))
                    .frame(width: 30, height: 30)
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.brandOrange)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Fullscreen Detected: \(appName)")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color(NSColor.labelColor))
                Text("Switch to dedicated 60 FPS capture")
                    .font(.system(size: 11))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
            }
            
            Spacer()
            
            Button(action: {
                coordinator.selectedTarget = .window(window)
                coordinator.performanceMode = .retina
                if !coordinator.isCasting {
                    Task { await coordinator.startCasting() }
                }
            }) {
                Text("Cast Window")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cast \(appName) window at 60 frames per second")
        }
        .padding(10)
        .liquidGlassCard(cornerRadius: 12)
    }
    
    // MARK: - Permission Warning Card
    private var permissionWarningCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(AppColors.brandOrange)
                    .font(.system(size: 14))
                Text("Screen Recording Permission Required")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(NSColor.labelColor))
            }
            
            Text("macOS requires system authorization to stream your screen.")
                .font(.system(size: 11))
                .foregroundColor(Color(NSColor.secondaryLabelColor))
            
            Button(action: {
                permissionManager.requestScreenRecordingPermission()
                permissionManager.openScreenRecordingSettings()
            }) {
                HStack {
                    Text("Open System Settings")
                    Image(systemName: "arrow.up.forward.app")
                }
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 28)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityLabel("Open System Settings to grant Screen Recording permission")
        }
        .padding(12)
        .background(AppColors.brandOrange.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.brandOrange.opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Active Screen Stream Hero Card
    private var activeScreenStreamHeroCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Glowing Pulse Beacon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.red.opacity(0.85), radius: 4)
                }
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(coordinator.activeTV != nil ? coordinator.activeTV!.name : "Web Browser Stream")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(NSColor.labelColor))
                            .lineLimit(1)
                        
                        Text("LIVE")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    
                    Text(activeStreamSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 1-Click Disconnect / Stop Streaming
                Button(action: {
                    coordinator.stopCasting()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(coordinator.activeTV != nil ? "Disconnect" : "Stop")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(AppColors.activeCastingGradient)
                    .clipShape(Capsule())
                    .shadow(color: Color.red.opacity(0.4), radius: 4, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(coordinator.activeTV != nil ? "Disconnect from \(coordinator.activeTV!.name)" : "Stop casting")
                .accessibilityHint("Stops active screen mirroring")
            }
            
            // Integrated Telemetry Badges (FPS, Latency, Bitrate, Viewers)
            HStack(spacing: 6) {
                telemetryItem(label: "FPS", value: "\(Int(coordinator.fps))")
                telemetryItem(label: "LATENCY", value: "\(Int(coordinator.latencyMs))ms")
                telemetryItem(label: "BITRATE", value: String(format: "%.1fM", coordinator.bitrateMbps))
                telemetryItem(label: "VIEWERS", value: "\(coordinator.activeViewers)")
            }
            .padding(.top, 2)
            
            // Extended display status pill & shortcut
            if coordinator.screenCastType == .extended || virtualDisplayManager.isExtendedDisplayActive {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.split.2x1.fill")
                        .foregroundColor(AppColors.brandBlue)
                        .font(.system(size: 11))
                    Text("Extended 2nd Monitor Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(NSColor.labelColor))
                    Spacer()
                    Button(action: {
                        coordinator.virtualDisplayManager.openDisplayPreferences()
                    }) {
                        HStack(spacing: 3) {
                            Text("Arrange")
                            Image(systemName: "arrow.up.forward.app")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.brandBlue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Arrange displays in macOS System Settings")
                    
                    Button(action: {
                        showDeleteExtendedConfirm = true
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Delete")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove Extended Virtual Display")
                    .accessibilityHint("Closes virtual second monitor")
                    .help("Delete extended virtual monitor from macOS")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AppColors.brandBlue.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    private var activeStreamSubtitle: String {
        let typeStr = coordinator.screenCastType == .extended ? "Extended Desktop" : "Mirror Mac"
        if let tv = coordinator.activeTV {
            let protocolStr = tv.type == .googlecast ? "Google Cast" : tv.type.rawValue
            return "\(typeStr) • \(protocolStr)"
        } else {
            return "\(typeStr) • Browser Stream"
        }
    }
    
    // MARK: - Display Mode & Target Selector Card (Mirror vs Extend)
    private var screenCastTypeSelectorCard: some View {
        VStack(spacing: 10) {
            // Mode Segment (Mirror Screen vs Extend to TV)
            HStack(spacing: 4) {
                screenCastTypeTabButton(
                    title: "Mirror Screen",
                    icon: "rectangle.on.rectangle",
                    type: .mirror
                )
                
                screenCastTypeTabButton(
                    title: "Extend to TV",
                    icon: "rectangle.split.2x1.fill",
                    type: .extended
                )
            }
            .padding(3)
            .background(
                colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.black.opacity(0.06)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                    colorScheme == .dark
                    ? Color.white.opacity(0.12)
                    : Color.black.opacity(0.08),
                    lineWidth: 0.8
                )
            )
            
            Divider().opacity(0.18)
            
            if coordinator.screenCastType == .extended {
                extendedDisplayControls
            } else {
                captureTargetPicker
            }
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    private func screenCastTypeTabButton(title: String, icon: String, type: ScreenCastType) -> some View {
        let isSelected = coordinator.screenCastType == type
        return Button(action: {
            Task {
                await coordinator.switchScreenCastType(to: type)
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppColors.tabSelectedGradient)
                        .shadow(color: Color.black.opacity(0.25), radius: 3, y: 1)
                }
            }
            .foregroundColor(
                isSelected
                ? Color.white
                : AppColors.secondaryText
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Sets cast display mode to \(title)")
    }

    private var captureTargetPicker: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                    Text("Target")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }
                
                Spacer()
                
                Menu {
                    Section("Displays") {
                        ForEach(coordinator.availableDisplays, id: \.displayID) { display in
                            Button("Display \(display.displayID) (\(display.width)×\(display.height))") {
                                coordinator.selectedTarget = .display(display)
                            }
                        }
                    }
                    
                    if !coordinator.availableWindows.isEmpty {
                        Section("Windows") {
                            ForEach(coordinator.availableWindows, id: \.windowID) { window in
                                let app = window.owningApplication?.applicationName ?? "App"
                                let title = window.title ?? "Untitled"
                                Button("\(app): \(title)") {
                                    coordinator.selectedTarget = .window(window)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isWindowTarget ? "macwindow" : "display")
                            .font(.system(size: 11))
                        Text(targetDisplayTitle)
                            .lineLimit(1)
                            .frame(maxWidth: 150, alignment: .trailing)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(NSColor.labelColor))
                }
                .menuStyle(.borderlessButton)
                .accessibilityLabel("Capture target: \(targetDisplayTitle)")
                
                Button(action: {
                    Task { await coordinator.refreshTargets() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh available screens and windows")
                .help("Refresh screens and windows")
            }
            
            // If an extended screen is active in background, give user an explicit 1-click Delete button
            if virtualDisplayManager.isExtendedDisplayActive {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.split.2x1.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.brandOrange)
                    Text("Extended display is active in macOS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(NSColor.labelColor))
                    Spacer()
                    Button(action: {
                        showDeleteExtendedConfirm = true
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Delete")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove Extended Virtual Display")
                    .accessibilityHint("Closes virtual second monitor")
                    .help("Delete extended virtual monitor from macOS")
                }
                .padding(7)
                .background(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.04))
                .cornerRadius(8)
            }
        }
    }

    private var extendedDisplayControls: some View {
        VStack(spacing: 10) {
            // Resolution Picker Row
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.2.square")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                    Text("Resolution")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }
                
                Spacer()
                
                Picker("", selection: $virtualDisplayManager.selectedResolution) {
                    ForEach(ExtendedDisplayResolution.allCases) { res in
                        Text(res.rawValue).tag(res)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .font(.system(size: 11, weight: .medium))
                .accessibilityLabel("Extended display resolution: \(virtualDisplayManager.selectedResolution.rawValue)")
                .onChange(of: virtualDisplayManager.selectedResolution) { _, newRes in
                    Task {
                        await coordinator.updateExtendedResolution(newRes)
                    }
                }
            }
            
            if virtualDisplayManager.isExtendedDisplayActive {
                // Active State: Shows active badge + Arrange button + Delete button
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .shadow(color: Color.green.opacity(0.6), radius: 2)
                        Text("Extended 2nd Monitor Active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(NSColor.labelColor))
                        Spacer()
                        Text(virtualDisplayManager.selectedResolution.shortTitle)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.12))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 8) {
                        // Arrange Displays in macOS Settings
                        Button(action: {
                            coordinator.virtualDisplayManager.openDisplayPreferences()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Arrange Displays")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.06))
                            .foregroundColor(Color(NSColor.labelColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Arrange Displays in macOS System Settings")
                        .help("Arrange display order in macOS System Settings")
                        
                        // Delete / Remove Extended Screen button
                        Button(action: {
                            showDeleteExtendedConfirm = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Delete Screen")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(Color.red.opacity(colorScheme == .dark ? 0.18 : 0.12))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove Extended Virtual Display")
                        .accessibilityHint("Closes virtual second monitor")
                        .help("Delete extended monitor and bring windows back to main screen")
                    }
                }
                .padding(10)
                .background(AppColors.brandBlue.opacity(colorScheme == .dark ? 0.09 : 0.05))
                .cornerRadius(10)
            } else {
                // Inactive State: Explicit "Create Extended Screen" button
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles.tv.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("Create a 2nd virtual monitor to extend windows onto your TV.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Button(action: {
                        Task {
                            await coordinator.createExtendedScreen()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.rectangle.on.rectangle")
                                .font(.system(size: 11, weight: .bold))
                            Text("Create Extended Screen")
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(
                            LinearGradient(
                                colors: [AppColors.brandBlue, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppColors.brandBlue.opacity(0.35), radius: 4, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Create Extended Screen virtual monitor")
                    .accessibilityHint("Creates virtual second monitor in macOS")
                }
                .padding(10)
                .background(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.03))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Direct 1-Click Destinations Card (Smart TVs & Browser)
    private var destinationsDirectCastCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.brandBlue)
                    Text("CAST DESTINATIONS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                        .tracking(0.5)
                }
                
                Spacer()
                
                Button(action: {
                    coordinator.startTVScan()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .rotationEffect(.degrees((coordinator.isScanningTVs && !reduceMotion) ? 360 : 0))
                            .animation(
                                (coordinator.isScanningTVs && !reduceMotion)
                                ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                                value: coordinator.isScanningTVs
                            )
                        Text(coordinator.isScanningTVs ? "Scanning..." : "Scan")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(NSColor.labelColor))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(coordinator.isScanningTVs ? "Scanning for Smart TVs on local network" : "Scan for Smart TVs")
            }
            
            // Discovered TVs List
            if coordinator.discoveredTVs.isEmpty && !coordinator.isScanningTVs {
                VStack(alignment: .leading, spacing: 3) {
                    Text("No Smart TVs discovered yet on this Wi-Fi network.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                    Text("Ensure your TV (Chromecast, Google TV, Samsung or LG) is powered on.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.03))
                .cornerRadius(10)
            } else {
                VStack(spacing: 5) {
                    ForEach(coordinator.discoveredTVs) { tv in
                        smartTVRow(tv: tv)
                    }
                }
            }
            
            Divider().opacity(0.18)
            
            // Web Browser & QR Code Row with Smooth Inline QR Expansion
            browserStreamRow
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    // MARK: - Smart TV 1-Click Row
    private func smartTVRow(tv: DiscoveredTV) -> some View {
        let isCurrentActive = coordinator.activeTV?.id == tv.id && coordinator.isCasting
        let isConnecting = connectingDeviceId == tv.id && !isCurrentActive
        
        return Button(action: {
            if isCurrentActive {
                Task { await coordinator.disconnectSmartTV() }
            } else {
                connectToSmartTV(tv)
            }
        }) {
            HStack(spacing: 10) {
                // TV Icon with subtle rounded background
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isCurrentActive ? Color.blue.opacity(0.2) : AppColors.brandBlue.opacity(0.14))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: tvIconName(for: tv))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isCurrentActive ? .blue : AppColors.brandBlue)
                }
                
                VStack(alignment: .leading, spacing: 1.5) {
                    Text(tv.name)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(NSColor.labelColor))
                        .lineLimit(1)
                    
                    Text(tvSubtitle(for: tv))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                // Right Action Pill
                if isCurrentActive {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 5, height: 5)
                        Text("Disconnect")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Color.red)
                    .clipShape(Capsule())
                } else if isConnecting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Connecting...")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                } else {
                    HStack(spacing: 4.5) {
                        Image(systemName: coordinator.screenCastType == .extended ? "rectangle.split.2x1.fill" : "rectangle.on.rectangle")
                            .font(.system(size: 11, weight: .semibold))
                        Text(coordinator.screenCastType == .extended ? "Extend" : "Mirror")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        coordinator.screenCastType == .extended
                        ? LinearGradient(colors: [AppColors.brandBlue, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : AppColors.primaryGradient
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(AppleDeviceRowButtonStyle(isSelected: isCurrentActive))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tv.name), \(tvSubtitle(for: tv))")
        .accessibilityAddTraits(isCurrentActive ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isCurrentActive ? "Disconnect from \(tv.name)" : "Cast screen to \(tv.name)")
    }
    
    // MARK: - Browser Stream Row (Unified with Inline Link & QR)
    private var browserStreamRow: some View {
        let isBrowserActive = coordinator.isCasting && coordinator.activeTV == nil
        
        return VStack(spacing: 8) {
            Button(action: {
                if isBrowserActive {
                    coordinator.stopCasting()
                } else {
                    startBrowserStreaming()
                }
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isBrowserActive ? AppColors.brandGreen.opacity(0.2) : AppColors.brandOrange.opacity(0.14))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "globe")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isBrowserActive ? AppColors.brandGreen : AppColors.brandOrange)
                    }
                    
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text("Web Browser & QR Code")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Color(NSColor.labelColor))
                        
                        Text("Any Phone, Tablet, PC or TV Browser")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Toggle QR Code Inline Preview
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            showQRCode.toggle()
                        }
                    }) {
                        Image(systemName: showQRCode ? "qrcode.viewfinder" : "qrcode")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(showQRCode ? AppColors.brandOrange : Color(NSColor.secondaryLabelColor))
                            .padding(5)
                            .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showQRCode ? "Hide QR Code" : "Show QR Code")
                    .help("Toggle QR Code")
                    
                    if isBrowserActive {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 5, height: 5)
                            Text("Stop")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(Color.red)
                        .clipShape(Capsule())
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                            Text("Stream")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color(NSColor.labelColor))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.1), lineWidth: 0.8)
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(AppleDeviceRowButtonStyle(isSelected: isBrowserActive))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Web Browser and QR Code streaming")
            .accessibilityHint(isBrowserActive ? "Stop streaming to browser" : "Start streaming to browser")
            .accessibilityAddTraits(isBrowserActive ? [.isButton, .isSelected] : .isButton)
            
            // Integrated Inline Share Link & QR Card (Appears seamlessly when toggled or streaming)
            if isBrowserActive || showQRCode {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LIVE SHARE LINK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.secondaryText)
                                .tracking(0.5)
                            
                            Text(coordinator.localURL.isEmpty ? "Generating link..." : coordinator.localURL)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(NSColor.labelColor))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Copy Link Button
                        Button(action: {
                            copyToClipboard(coordinator.localURL)
                            copiedURL = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                copiedURL = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: copiedURL ? "checkmark" : "doc.on.doc")
                                Text(copiedURL ? "Copied" : "Copy")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(copiedURL ? AppColors.brandGreen : Color(NSColor.labelColor))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.06))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(copiedURL ? "Stream link copied to clipboard" : "Copy stream link")
                    }
                    
                    if showQRCode || isBrowserActive {
                        VStack(spacing: 6) {
                            if let qrImg = coordinator.qrCodeImage {
                                Image(nsImage: qrImg)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 130, height: 130)
                                    .padding(6)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                                    .accessibilityLabel("QR code for streaming URL \(coordinator.localURL)")
                            }
                            
                            Text("Scan with iPhone, iPad, Android or TV Browser")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .padding(10)
                .background(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.035))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.06), lineWidth: 0.8)
                )
            }
        }
    }
    
    // MARK: - Quality Profile & Audio Settings Card
    private var qualityAndAudioCard: some View {
        VStack(spacing: 9) {
            // Quality Mode
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                    Text("Quality Profile")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }
                
                Spacer()
                
                Picker("", selection: $coordinator.performanceMode) {
                    ForEach(PerformanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .font(.system(size: 11, weight: .medium))
                .accessibilityLabel("Quality profile: \(coordinator.performanceMode.rawValue)")
            }
            
            Divider().opacity(0.18)
            
            // Audio Streaming Toggle
            Toggle(isOn: $coordinator.includeSystemAudio) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.brandBlue)
                    Text("Capture System Audio")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(NSColor.labelColor))
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .accessibilityLabel("Capture System Audio")
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    // MARK: - Dedicated Video Casting Section
    private var videoCastingSection: some View {
        VStack(spacing: 12) {
            if let meta = coordinator.videoMetadata {
                // Video Loaded Card
                videoLoadedCard(meta: meta)
                
                // Playback & Scrubber Controls HUD
                VideoPlaybackHUDView(coordinator: coordinator, meta: meta)
            } else {
                // Inviting Dropzone / File Picker Card
                videoDropZoneButton
            }
            
            // Smart TV Video Cast Targets
            smartTVVideoSection
            
            // Web Player Share Card
            videoWebPlayerCard
        }
    }
    
    // MARK: - Video Loaded Card
    private func videoLoadedCard(meta: VideoMetadata) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Video Thumbnail
                ZStack {
                    if let thumb = meta.thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: 84, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                colorScheme == .dark
                                ? Color.white.opacity(0.08)
                                : Color.black.opacity(0.06)
                            )
                            .frame(width: 84, height: 48)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            colorScheme == .dark
                            ? Color.white.opacity(0.2)
                            : Color.black.opacity(0.12),
                            lineWidth: 0.8
                        )
                )
                .accessibilityHidden(true)
                
                // Video Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(meta.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(NSColor.labelColor))
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Text(meta.resolution)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AppColors.brandOrange.opacity(colorScheme == .dark ? 0.22 : 0.16))
                            .foregroundColor(AppColors.brandOrange)
                            .clipShape(Capsule())
                        
                        Text(meta.durationFormatted)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                        
                        Text(meta.fileSizeFormatted)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            chooseVideoFile()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "folder")
                                    .font(.system(size: 11))
                                Text("Change...")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(NSColor.labelColor))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change video file")
                        
                        Text("|")
                            .font(.system(size: 11))
                            .foregroundColor(Color(NSColor.secondaryLabelColor).opacity(0.4))
                            .accessibilityHidden(true)
                        
                        Button(action: {
                            coordinator.clearVideoFile()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Remove")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove loaded video")
                    }
                    .padding(.top, 2)
                }
                Spacer()
            }
        }
        .padding(10)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    // MARK: - Video Drop Zone Button
    private var videoDropZoneButton: some View {
        Button(action: {
            chooseVideoFile()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.black.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 32
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .fill(
                            colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.black.opacity(0.06)
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.2)
                                : Color.black.opacity(0.15),
                                lineWidth: 1
                            )
                        )
                    
                    Image(systemName: "film.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.brandOrange)
                }
                
                VStack(spacing: 3) {
                    Text("Select Video File to Stream")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(NSColor.labelColor))
                    
                    Text("Direct 4K / 1080p with synchronized audio\nDrop MP4, MOV, MKV, M4V or WebM file here")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 11))
                    Text("Choose Video File...")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(AppColors.primaryGradient)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.3), radius: 5, y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isDropTargeted
                        ? AppColors.brandBlue.opacity(0.12)
                        : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.035))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isDropTargeted
                        ? AppColors.brandBlue
                        : (colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.15)),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Select or drop a video file to stream in 4K")
        .accessibilityHint("Opens file browser to select MP4, MOV, MKV, M4V or WebM file")
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let fileURL = url {
                    DispatchQueue.main.async {
                        coordinator.castingMode = .videoFile
                        coordinator.selectVideoFile(url: fileURL)
                    }
                }
            }
            return true
        }
    }
    
    // MARK: - Smart TV Video Section
    private var smartTVVideoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.brandBlue)
                    Text("CAST VIDEO TO SMART TV")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                        .tracking(0.5)
                }
                
                Spacer()
                
                Button(action: {
                    coordinator.startTVScan()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees((coordinator.isScanningTVs && !reduceMotion) ? 360 : 0))
                            .animation((coordinator.isScanningTVs && !reduceMotion) ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: coordinator.isScanningTVs)
                        Text(coordinator.isScanningTVs ? "Scanning..." : "Scan")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(NSColor.labelColor))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(coordinator.isScanningTVs ? "Scanning for Smart TVs on local network" : "Scan for Smart TVs")
            }
            
            if coordinator.discoveredTVs.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text(coordinator.isScanningTVs ? "Searching local Wi-Fi for Smart TVs..." : "No Smart TVs discovered. Open TV browser to play.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    colorScheme == .dark
                    ? Color.white.opacity(0.04)
                    : Color.black.opacity(0.035)
                )
                .cornerRadius(10)
            } else {
                VStack(spacing: 6) {
                    ForEach(coordinator.discoveredTVs) { tv in
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppColors.brandBlue.opacity(0.18))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "tv")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.brandBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tv.name)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color(NSColor.labelColor))
                                    .lineLimit(1)
                                Text(tv.type == .googlecast ? "Google Cast (4K/Audio)" : tv.type.rawValue)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            if coordinator.activeTV?.id == tv.id && coordinator.isVideoPlaying {
                                Button(action: {
                                    coordinator.stopVideoCast()
                                }) {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.red).frame(width: 5, height: 5)
                                        Text("Disconnect")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Disconnect video cast from \(tv.name)")
                            } else {
                                Button(action: {
                                    Task { await coordinator.castVideoToSmartTV(tv) }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 11))
                                        Text("Cast Video")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppColors.primaryGradient)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Cast video to \(tv.name)")
                            }
                        }
                        .padding(8)
                        .background(
                            colorScheme == .dark
                            ? Color.white.opacity(0.04)
                            : Color.black.opacity(0.035)
                        )
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    // MARK: - Video Web Player Card
    private var videoWebPlayerCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "safari.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(NSColor.labelColor))
            
            VStack(alignment: .leading, spacing: 1) {
                Text("TV / BROWSER PLAYER")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.secondaryText)
                    .tracking(0.5)
                
                Text(coordinator.videoWebURL.isEmpty ? "http://.../video" : coordinator.videoWebURL)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(NSColor.labelColor))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                copyToClipboard(coordinator.videoWebURL)
                copiedVideoURL = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    copiedVideoURL = false
                }
            }) {
                Image(systemName: copiedVideoURL ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(copiedVideoURL ? AppColors.brandGreen : Color(NSColor.labelColor))
                    .frame(width: 28, height: 28)
                    .background(
                        colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.06)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copiedVideoURL ? "Video URL copied to clipboard" : "Copy video web player URL")
            .help("Copy Video Player URL")
            
            Button(action: {
                if let url = URL(string: coordinator.videoWebURL) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(NSColor.labelColor))
                    .frame(width: 28, height: 28)
                    .background(
                        colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.06)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Video Player in default browser")
            .help("Open in Browser")
        }
        .padding(10)
        .liquidGlassCard(cornerRadius: 12)
    }
    
    // MARK: - Choose Video File (Unobstructed Modal Handling)
    private func chooseVideoFile() {
        MenuBarController.shared?.prepareForModal()
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType.movie,
            UTType.video,
            UTType.quickTimeMovie,
            UTType.mpeg4Movie,
            UTType(filenameExtension: "mkv") ?? UTType.movie,
            UTType(filenameExtension: "webm") ?? UTType.movie,
            UTType(filenameExtension: "m4v") ?? UTType.movie
        ]
        panel.prompt = "Select Video"
        panel.message = "Choose a video to cast directly to your Smart TV or Web Player"
        
        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            coordinator.castingMode = .videoFile
            coordinator.selectVideoFile(url: url)
        }
        
        MenuBarController.shared?.finishModal()
    }
    
    // MARK: - Telemetry Helpers
    private func telemetryItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(AppColors.secondaryText)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundColor(Color(NSColor.labelColor))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
    
    // MARK: - Actions & Helpers
    private func connectToSmartTV(_ tv: DiscoveredTV) {
        permissionManager.checkPermissions()
        guard permissionManager.hasScreenRecordingPermission else {
            permissionManager.requestScreenRecordingPermission()
            permissionManager.openScreenRecordingSettings()
            return
        }
        
        connectingDeviceId = tv.id
        Task {
            if coordinator.screenCastType == .extended && !virtualDisplayManager.isExtendedDisplayActive {
                await coordinator.createExtendedScreen()
            }
            await coordinator.castToSmartTV(tv)
            await MainActor.run {
                connectingDeviceId = nil
            }
        }
    }
    
    private func startBrowserStreaming() {
        permissionManager.checkPermissions()
        guard permissionManager.hasScreenRecordingPermission else {
            permissionManager.requestScreenRecordingPermission()
            permissionManager.openScreenRecordingSettings()
            return
        }
        
        Task {
            if coordinator.screenCastType == .extended && !virtualDisplayManager.isExtendedDisplayActive {
                await coordinator.createExtendedScreen()
            }
            await coordinator.startCasting()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    showQRCode = true
                }
            }
        }
    }
    
    private func tvIconName(for tv: DiscoveredTV) -> String {
        switch tv.type {
        case .googlecast:
            return "tv.badge.wifi"
        case .airplay:
            return "airplayvideo"
        case .dlna:
            return "tv"
        }
    }
    
    private func tvSubtitle(for tv: DiscoveredTV) -> String {
        switch tv.type {
        case .googlecast:
            return "Google Cast"
        case .airplay:
            return "AirPlay TV"
        case .dlna:
            return "DLNA Smart TV"
        }
    }
    
    // MARK: - Streamlined macOS-style Footer
    private var footerView: some View {
        HStack(spacing: 8) {
            // Left: Open in Browser
            Button(action: {
                let targetURL = coordinator.castingMode == .videoFile ? coordinator.videoWebURL : coordinator.localURL
                if let url = URL(string: targetURL) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "safari")
                        .font(.system(size: 11))
                    Text("Web Player")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .buttonStyle(FooterHoverButtonStyle())
            .foregroundColor(AppColors.secondaryText)
            .help("Open Web Player in your default browser")
            .accessibilityLabel("Open Web Player in default browser")
            
            // Guide shortcut
            Button(action: {
                WelcomeOnboardingWindow.show()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                    Text("Guide")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .buttonStyle(FooterHoverButtonStyle())
            .foregroundColor(AppColors.secondaryText)
            .help("Show Welcome & How-to-Use Guide")
            .accessibilityLabel("Open Welcome and How-to-Use Guide")
            
            Spacer()
            
            // Toolbar Icon Style selector menu
            Menu {
                ForEach(ToolbarIconStyle.allCases) { style in
                    Button(action: {
                        MenuBarController.toolbarIconStyle = style
                    }) {
                        HStack {
                            Text(style.displayName)
                            if MenuBarController.toolbarIconStyle == style {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: MenuBarController.currentToolbarSymbolName())
                        .font(.system(size: 11))
                    Text("Icon")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(FooterHoverButtonStyle())
            .foregroundColor(AppColors.secondaryText)
            .help("Select Menu Bar icon symbol")
            .accessibilityLabel("Select Menu Bar icon symbol")
            
            Text("•")
                .font(.system(size: 9))
                .foregroundColor(AppColors.tertiaryText)
                .accessibilityHidden(true)
            
            // Quit with standard macOS ⌘Q indicator
            Button(action: {
                coordinator.stopCasting()
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 4) {
                    Text("Quit")
                        .font(.system(size: 11, weight: .medium))
                    Text("⌘Q")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.tertiaryText)
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                }
            }
            .buttonStyle(FooterHoverButtonStyle())
            .foregroundColor(AppColors.secondaryText)
            .keyboardShortcut("q", modifiers: .command)
            .help("Quit ezku.link (⌘Q)")
            .accessibilityLabel("Quit ezku.link, keyboard shortcut Command Q")
        }
    }

    // MARK: - Helpers
    private var isWindowTarget: Bool {
        if case .window = coordinator.selectedTarget { return true }
        return false
    }
    
    private var targetDisplayTitle: String {
        switch coordinator.selectedTarget {
        case .display(let d):
            return "Display \(d.displayID)"
        case .window(let w):
            return w.owningApplication?.applicationName ?? "Window"
        case .none:
            return "Select Screen"
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
