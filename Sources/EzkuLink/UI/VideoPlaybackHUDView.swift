import SwiftUI

// MARK: - Video Playback HUD View
public struct VideoPlaybackHUDView: View {
    @ObservedObject var coordinator: CastingCoordinator
    public let meta: VideoMetadata
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isDraggingSeek = false
    @State private var localSeekValue = 0.0
    
    public init(coordinator: CastingCoordinator = .shared, meta: VideoMetadata) {
        self.coordinator = coordinator
        self.meta = meta
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Scrubber Slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: {
                            isDraggingSeek ? localSeekValue : coordinator.videoCurrentTime
                        },
                        set: { newValue in
                            localSeekValue = newValue
                            if !isDraggingSeek {
                                coordinator.seekVideo(to: newValue)
                            }
                        }
                    ),
                    in: 0...max(1.0, coordinator.videoDuration),
                    onEditingChanged: { editing in
                        isDraggingSeek = editing
                        if !editing {
                            coordinator.seekVideo(to: localSeekValue)
                        }
                    }
                )
                .accentColor(AppColors.brandOrange)
                .controlSize(.small)
                .accessibilityLabel("Video playback position")
                .accessibilityValue("\(VideoMetadataLoader.formatTime(isDraggingSeek ? localSeekValue : coordinator.videoCurrentTime)) of \(meta.durationFormatted)")
                
                // Timestamp labels
                HStack {
                    Text(VideoMetadataLoader.formatTime(isDraggingSeek ? localSeekValue : coordinator.videoCurrentTime))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(NSColor.labelColor))
                    Spacer()
                    Text(meta.durationFormatted)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }
            }
            .padding(.horizontal, 4)
            
            // Media Controls Row (Rewind 10, Play/Pause, Forward 10, Stop)
            HStack(spacing: 16) {
                // Skip -10s
                Button(action: {
                    let target = max(0, (isDraggingSeek ? localSeekValue : coordinator.videoCurrentTime) - 10)
                    localSeekValue = target
                    coordinator.seekVideo(to: target)
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(NSColor.labelColor))
                        .frame(width: 32, height: 32)
                        .background(
                            colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.06)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.12)
                                : Color.black.opacity(0.1),
                                lineWidth: 0.8
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rewind 10 seconds")
                .help("Rewind 10 seconds")
                
                // Play / Pause Circle
                Button(action: {
                    if coordinator.isVideoPlaying {
                        coordinator.pauseVideo()
                    } else {
                        coordinator.playVideo()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                        
                        Image(systemName: coordinator.isVideoPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: coordinator.isVideoPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(coordinator.isVideoPlaying ? "Pause video" : "Play video")
                
                // Skip +10s
                Button(action: {
                    let target = min(coordinator.videoDuration, (isDraggingSeek ? localSeekValue : coordinator.videoCurrentTime) + 10)
                    localSeekValue = target
                    coordinator.seekVideo(to: target)
                }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(NSColor.labelColor))
                        .frame(width: 32, height: 32)
                        .background(
                            colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.06)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.12)
                                : Color.black.opacity(0.1),
                                lineWidth: 0.8
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fast forward 10 seconds")
                .help("Fast forward 10 seconds")
                
                // Stop Cast Button (if connected to TV or playing)
                if coordinator.isVideoPlaying || coordinator.activeTV != nil {
                    Button(action: {
                        coordinator.stopVideoCast()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.red)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                            .shadow(color: Color.red.opacity(0.4), radius: 4, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stop video playback")
                    .help("Stop video casting")
                }
            }
            .padding(.top, 2)
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 14)
    }
}
