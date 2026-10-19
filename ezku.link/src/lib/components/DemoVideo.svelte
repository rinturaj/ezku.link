<script lang="ts">
	import { scrollReveal } from '$lib/actions/scrollAnimation';

	type DemoMode = 'screen' | 'video' | 'diagram';
	let currentMode = $state<DemoMode>('screen');
	let isPlaying = $state(true);
	let isMuted = $state(true); // muted by default for clean autoplay
	let currentTime = $state(0);
	let duration = $state(32);
	let videoElement: HTMLVideoElement | null = $state(null);

	function togglePlay() {
		if (!videoElement) {
			isPlaying = !isPlaying;
			return;
		}
		if (videoElement.paused) {
			videoElement.play().catch(() => {});
			isPlaying = true;
		} else {
			videoElement.pause();
			isPlaying = false;
		}
	}

	function toggleMute() {
		if (!videoElement) {
			isMuted = !isMuted;
			return;
		}
		videoElement.muted = !videoElement.muted;
		isMuted = videoElement.muted;
	}

	function scrubTimeline(e: MouseEvent) {
		if (!videoElement) return;
		const track = e.currentTarget as HTMLElement;
		const rect = track.getBoundingClientRect();
		const percent = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
		const targetTime = percent * (videoElement.duration || duration);
		videoElement.currentTime = targetTime;
		currentTime = Math.round(targetTime);
	}

	function selectMode(mode: DemoMode) {
		currentMode = mode;
		if (mode === 'screen') {
			if (videoElement) {
				videoElement.currentTime = 0;
				if (videoElement.paused) videoElement.play().catch(() => {});
			}
		} else if (mode === 'video') {
			if (videoElement) {
				videoElement.currentTime = 20; // 0:20 is Video Cast in demo
				if (videoElement.paused) videoElement.play().catch(() => {});
			}
		}
	}

	function handleTimeUpdate() {
		if (!videoElement) return;
		currentTime = Math.floor(videoElement.currentTime);
		if (videoElement.duration && duration !== Math.floor(videoElement.duration)) {
			duration = Math.floor(videoElement.duration);
		}
		// Synchronize active mode with demo timeline chapters if not in diagram view
		if (currentMode !== 'diagram') {
			if (currentTime >= 20 && currentMode !== 'video') {
				currentMode = 'video';
			} else if (currentTime < 20 && currentMode !== 'screen') {
				currentMode = 'screen';
			}
		}
	}

	function handleLoadedMetadata() {
		if (videoElement && videoElement.duration) {
			duration = Math.floor(videoElement.duration);
		}
	}

	function toggleFullscreen() {
		if (!videoElement) return;
		if (!document.fullscreenElement) {
			videoElement.requestFullscreen?.().catch(() => {});
		} else {
			document.exitFullscreen?.().catch(() => {});
		}
	}
</script>

<section id="demo" class="demo-section section-spacing-sm" use:scrollReveal>
	<div class="page-container">
		<!-- Section Header -->
		<div class="demo-header-row">
			<div class="header-left">
				<span class="ui-badge is-accent">DEMO</span>
				<span class="ui-badge">REAL MACOS APP DEMO</span>
			</div>
			<div class="demo-corner-mark" aria-hidden="true">⌟</div>
		</div>

		<div class="demo-intro">
			<h2 class="h-2 demo-headline">See It in Action</h2>
			<p class="text-lead demo-lead">
				Watch ezku.link stream macOS displays to any browser or TV in real time with zero viewer apps.
			</p>
		</div>

		<!-- Mode Switcher -->
		<div class="demo-tabs-bar">
			<button
				type="button"
				class="demo-tab-btn"
				class:is-active={currentMode === 'screen'}
				onclick={() => selectMode('screen')}
			>
				<span class="tab-icon">🖥</span>
				<span class="tab-label">Screen Mirroring (0:00)</span>
			</button>
			<button
				type="button"
				class="demo-tab-btn"
				class:is-active={currentMode === 'video'}
				onclick={() => selectMode('video')}
			>
				<span class="tab-icon">🎬</span>
				<span class="tab-label">4K Video Cast (0:20)</span>
			</button>
			<button
				type="button"
				class="demo-tab-btn"
				class:is-active={currentMode === 'diagram'}
				onclick={() => selectMode('diagram')}
			>
				<span class="tab-icon">📐</span>
				<span class="tab-label">Architecture Flow</span>
			</button>
		</div>

		<!-- Video Showcase Area (Seamless & Borderless) -->
		<div class="demo-showcase-wrap">
			<!-- Subtle Meta Row -->
			<div class="demo-meta-row">
				<div class="meta-status">
					<span class="live-dot"></span>
					<span class="meta-title">
						{#if currentMode === 'screen'}
							Screen Mirroring • Instant Browser &amp; Smart TV Stream
						{:else if currentMode === 'video'}
							4K Movie Direct Cast • Hardware-Accelerated Playback
						{:else}
							Architecture • Local Zero-Cloud Peer-to-Peer Stream
						{/if}
					</span>
				</div>
				<div class="meta-badges">
					<span class="badge-res">4K 60FPS</span>
					<span class="badge-tag">macOS Menu Bar</span>
					<span class="badge-tag">No TV App</span>
				</div>
			</div>

			<!-- Stage -->
			<div class="demo-stage">
				<div class="ambient-glow" aria-hidden="true"></div>

				{#if currentMode === 'diagram'}
					<!-- Clean Topology Diagram (seamlessly floating) -->
					<div class="demo-mock-screen">
						<!-- Left: Host Mac -->
						<div class="stream-device host-mac">
							<div class="device-label">
								<span class="device-name">MacBook Pro</span>
								<span class="device-tag">HOST</span>
							</div>
							<div class="screen-preview-box">
								<div class="mock-desktop">
									<div class="mock-menubar">
										<span class="mock-apple"></span>
										<span class="mock-app-name">Finder</span>
										<span class="mock-cast-active">ezku.link ●</span>
									</div>
									<div class="mock-window">
										<div class="mock-window-header">
											<span class="dot-win red"></span>
											<span class="dot-win yellow"></span>
											<span class="dot-win green"></span>
											<span class="mock-win-title">Presentation Slides</span>
										</div>
										<div class="mock-win-body">
											<div class="slide-block">
												<div class="slide-title">Quarterly Launch</div>
												<div class="slide-bar"></div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Center: Wireless Flow -->
						<div class="stream-bridge">
							<div class="bridge-arrow" class:is-animating={isPlaying}>
								<span></span>
								<span></span>
								<span></span>
							</div>
							<span class="bridge-label">Local Wi-Fi</span>
							<span class="bridge-metric">&lt; 20ms</span>
						</div>

						<!-- Right: Target Smart TV -->
						<div class="stream-device target-tv">
							<div class="device-label">
								<span class="device-name">Smart TV / Browser</span>
								<span class="device-tag">NATIVE PLAYER</span>
							</div>
							<div class="screen-preview-box tv-preview">
								<div class="tv-screen-content">
									<div class="tv-status-badge">
										<span class="pulse-indicator"></span>
										<span>Live Mirror (No TV App)</span>
									</div>
									<div class="tv-mirrored-slide">
										<div class="slide-title">Quarterly Launch</div>
										<div class="slide-bar"></div>
									</div>
								</div>
							</div>
						</div>
					</div>
				{:else}
					<!-- Real macOS App Demo Video & GIF (Border-free, blends directly with background) -->
					<div class="demo-media-wrapper">
						<video
							bind:this={videoElement}
							class="embedded-video"
							playsinline
							autoplay
							loop
							muted={isMuted}
							poster="/assets/demo-poster.jpg"
							onplay={() => (isPlaying = true)}
							onpause={() => (isPlaying = false)}
							ontimeupdate={handleTimeUpdate}
							onloadedmetadata={handleLoadedMetadata}
							onclick={togglePlay}
						>
							<source src="/assets/demo.mp4" type="video/mp4" />
							<source src="/assets/demo.webm" type="video/webm" />
							<img
								src="/assets/demo-poster.jpg"
								alt="ezku.link macOS App Demo"
								class="embedded-video"
							/>
							<track kind="captions" />
						</video>

						{#if !isPlaying}
							<button
								type="button"
								class="play-overlay-btn"
								onclick={togglePlay}
								aria-label="Play demo video"
							>
								<svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
									<polygon points="6 4 20 12 6 20 6 4" />
								</svg>
							</button>
						{/if}

						<div class="demo-floating-caption">
							<span class="caption-dot"></span>
							<span class="caption-text">
								{currentTime < 20
									? 'Live macOS App • Menu Bar Quick Mirror & QR Code'
									: 'Live macOS App • 4K Movie Direct Cast to TV'}
							</span>
						</div>
					</div>
				{/if}
			</div>

			<!-- Sleek Floating Controls Pill (Seamless & Tactile) -->
			<div class="floating-controls-bar">
				<div class="controls-left">
					<button
						type="button"
						class="ctrl-btn"
						onclick={togglePlay}
						aria-label={isPlaying ? 'Pause' : 'Play'}
					>
						{#if isPlaying}
							<svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
								<rect x="6" y="4" width="4" height="16" rx="1" />
								<rect x="14" y="4" width="4" height="16" rx="1" />
							</svg>
						{:else}
							<svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
								<polygon points="6 4 20 12 6 20 6 4" />
							</svg>
						{/if}
					</button>

					<button
						type="button"
						class="ctrl-btn"
						onclick={toggleMute}
						aria-label={isMuted ? 'Unmute' : 'Mute'}
					>
						{#if isMuted}
							<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
								<line x1="1" y1="1" x2="23" y2="23" />
								<path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6" />
							</svg>
						{:else}
							<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
								<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
								<path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" />
							</svg>
						{/if}
					</button>

					<span class="audio-tag">
						00:{currentTime < 10 ? '0' + currentTime : currentTime} / 00:{duration < 10 ? '0' + duration : duration}
					</span>
				</div>

				<div class="timeline-wrapper">
					<div
						class="timeline-track"
						onclick={scrubTimeline}
						onkeydown={(e) => {
							if (e.key === 'ArrowRight' && videoElement) videoElement.currentTime = Math.min(duration, currentTime + 2);
							if (e.key === 'ArrowLeft' && videoElement) videoElement.currentTime = Math.max(0, currentTime - 2);
						}}
						role="slider"
						tabindex="0"
						aria-valuenow={currentTime}
						aria-valuemin={0}
						aria-valuemax={duration}
						aria-label="Demo timeline scrubber"
					>
						<div
							class="timeline-fill"
							style="width: {duration ? (currentTime / duration) * 100 : 0}%"
						>
							<span class="timeline-thumb"></span>
						</div>
						<div class="chapter-mark at-mirror" title="Screen Mirroring (0:00)"></div>
						<div class="chapter-mark at-video" title="4K Video Cast (0:20)"></div>
					</div>
				</div>

				<div class="controls-right">
					<span class="control-note">Click tabs to jump</span>
					<button
						type="button"
						class="ctrl-btn fullscreen-btn"
						onclick={toggleFullscreen}
						aria-label="Toggle Fullscreen"
						title="Fullscreen"
					>
						<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
							<path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3" />
						</svg>
					</button>
				</div>
			</div>
		</div>
	</div>
</section>

<style>
	.demo-section {
		border-top: 1px solid var(--line);
		position: relative;
	}

	.demo-header-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 20px;
		padding-bottom: 14px;
		border-bottom: 1px solid var(--line);
	}

	.header-left {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.demo-corner-mark {
		font-family: var(--mono);
		font-size: 22px;
		color: var(--amber);
		user-select: none;
		line-height: 1;
	}

	.demo-intro {
		margin-bottom: 24px;
	}

	.demo-headline {
		font-weight: 700;
	}

	.demo-lead {
		color: var(--ink-2);
		margin-top: 4px;
	}

	/* Tabs Bar */
	.demo-tabs-bar {
		display: flex;
		align-items: center;
		gap: 10px;
		margin-bottom: 20px;
		flex-wrap: wrap;
	}

	.demo-tab-btn {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 16px;
		border-radius: var(--r-pill);
		background: var(--bg-card);
		border: 1px solid var(--line);
		font-size: var(--fs-xs);
		font-weight: 600;
		color: var(--ink-2);
		cursor: pointer;
		transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
		            border-color var(--dur-fast) var(--ease),
		            background-color var(--dur-fast) var(--ease),
		            color var(--dur-fast) var(--ease);
	}

	.demo-tab-btn:hover {
		border-color: var(--amber);
		color: var(--ink);
		transform: translateY(-2px);
	}

	.demo-tab-btn:active {
		transform: scale(0.96);
	}

	.demo-tab-btn.is-active {
		background: var(--amber-bg);
		border-color: var(--amber);
		color: var(--amber-deep);
		box-shadow: 0 2px 8px rgba(245, 158, 11, 0.2);
	}

	/* Video Showcase (Seamless & Borderless) */
	.demo-showcase-wrap {
		position: relative;
		width: 100%;
		max-width: 1020px;
		margin: 0 auto;
		background: transparent;
	}

	.demo-meta-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0 4px;
		margin-bottom: 16px;
		gap: 12px;
		flex-wrap: wrap;
	}

	.meta-status {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 13px;
	}

	.meta-title {
		font-weight: 500;
		color: var(--ink);
	}

	.meta-badges {
		display: flex;
		align-items: center;
		gap: 8px;
		font-family: var(--mono);
		font-size: 10px;
	}

	.badge-res {
		background: var(--amber);
		color: #000;
		font-weight: 700;
		padding: 2px 6px;
		border-radius: var(--r-xs);
	}

	.badge-tag {
		background: var(--bg-card);
		border: 1px solid var(--line-subtle);
		color: var(--ink-3);
		padding: 2px 6px;
		border-radius: var(--r-xs);
	}

	/* Stage */
	.demo-stage {
		position: relative;
		display: flex;
		align-items: center;
		justify-content: center;
		background: transparent;
		padding: 0;
		overflow: visible;
	}

	.ambient-glow {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		width: 85%;
		height: 85%;
		background: radial-gradient(ellipse at center, rgba(245, 158, 11, 0.12) 0%, rgba(245, 158, 11, 0.02) 50%, transparent 75%);
		filter: blur(50px);
		pointer-events: none;
		z-index: 1;
		transition: opacity 0.4s ease;
	}

	.demo-media-wrapper {
		position: relative;
		width: 100%;
		max-width: 980px;
		display: flex;
		align-items: center;
		justify-content: center;
		border-radius: var(--r-xl);
		overflow: hidden;
		border: none;
		background: transparent;
		box-shadow: 0 20px 60px -15px rgba(22, 20, 14, 0.14), 0 8px 24px -8px rgba(22, 20, 14, 0.08);
		transition: box-shadow 0.3s var(--ease), transform 0.3s var(--ease);
		z-index: 2;
	}

	:global([data-theme='dark']) .demo-media-wrapper {
		box-shadow: 0 28px 80px -15px rgba(0, 0, 0, 0.8), 0 0 40px rgba(245, 158, 11, 0.08);
	}

	.demo-media-wrapper:hover {
		box-shadow: 0 28px 75px -16px rgba(22, 20, 14, 0.2), 0 10px 28px -8px rgba(245, 158, 11, 0.15);
	}

	.embedded-video {
		width: 100%;
		height: auto;
		max-height: 560px;
		aspect-ratio: 16 / 10;
		object-fit: contain;
		display: block;
		border-radius: var(--r-xl);
		background: transparent;
		border: none;
		outline: none;
		cursor: pointer;
	}

	.play-overlay-btn {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		width: 64px;
		height: 64px;
		border-radius: 50%;
		background: var(--amber);
		border: none;
		color: #000;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		box-shadow: 0 8px 30px rgba(245, 158, 11, 0.6);
		transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1), background-color 0.2s ease;
		z-index: 5;
	}

	.play-overlay-btn:hover {
		transform: translate(-50%, -50%) scale(1.12);
		background: #FBBF24;
	}

	.play-overlay-btn:active {
		transform: translate(-50%, -50%) scale(0.95);
	}

	.demo-floating-caption {
		position: absolute;
		bottom: 12px;
		left: 12px;
		background: rgba(13, 15, 23, 0.85);
		backdrop-filter: blur(10px);
		-webkit-backdrop-filter: blur(10px);
		border: 1px solid rgba(255, 255, 255, 0.12);
		border-radius: var(--r-pill);
		padding: 4px 12px;
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 11px;
		font-family: var(--mono);
		color: #FAF8F5;
		pointer-events: none;
		z-index: 4;
	}

	.caption-dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: var(--amber);
		box-shadow: 0 0 6px rgba(245, 158, 11, 0.8);
		animation: pulse-dot 1.4s infinite ease-in-out;
	}

	.chapter-mark {
		position: absolute;
		top: 0;
		bottom: 0;
		width: 2px;
		background: rgba(255, 255, 255, 0.45);
		z-index: 2;
		pointer-events: none;
		border-radius: 1px;
	}

	.chapter-mark.at-mirror {
		left: 0%;
	}

	.chapter-mark.at-video {
		left: 62.5%;
	}

	.fullscreen-btn {
		margin-left: 4px;
	}


	.demo-mock-screen {
		display: grid;
		grid-template-columns: 1fr 100px 1fr;
		gap: 20px;
		align-items: center;
		width: 100%;
		max-width: 960px;
		position: relative;
		z-index: 2;
	}

	.ambient-glow {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		width: 70%;
		height: 70%;
		background: radial-gradient(circle, rgba(245, 158, 11, 0.12) 0%, transparent 65%);
		pointer-events: none;
		filter: blur(40px);
		transition: opacity 0.4s ease, transform 0.4s ease;
	}

	.demo-showcase-wrap:hover .ambient-glow {
		opacity: 0.25;
		transform: translate(-50%, -50%) scale(1.1);
	}

	.stream-device {
		background: var(--bg-card);
		border: 1px solid var(--line);
		border-radius: var(--r-md);
		padding: 14px;
		display: flex;
		flex-direction: column;
		gap: 10px;
		transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1),
		            border-color 0.25s ease,
		            box-shadow 0.25s ease;
		cursor: default;
	}

	.stream-device:hover {
		transform: translateY(-3px) scale(1.015);
		border-color: var(--amber);
		box-shadow: var(--shadow-md);
	}

	.device-label {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.device-name {
		font-size: 11.5px;
		font-weight: 600;
		color: var(--ink);
	}

	.device-tag {
		font-family: var(--mono);
		font-size: 9px;
		color: var(--ink-3);
	}

	.screen-preview-box {
		background: var(--bg-subtle);
		border: 1px solid var(--line-subtle);
		border-radius: var(--r-sm);
		height: 180px;
		padding: 12px;
		position: relative;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}

	/* Mock Desktop */
	.mock-desktop {
		display: flex;
		flex-direction: column;
		height: 100%;
		gap: 8px;
	}

	.mock-menubar {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 10px;
		color: #94A3B8;
		border-bottom: 1px solid rgba(255, 255, 255, 0.08);
		padding-bottom: 4px;
	}

	.mock-cast-active {
		margin-left: auto;
		color: var(--amber);
		font-weight: 600;
		font-family: var(--mono);
		font-size: 9.5px;
	}

	.mock-window {
		background: #1E2333;
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: var(--r-xs);
		flex: 1;
		display: flex;
		flex-direction: column;
	}

	.mock-window-header {
		display: flex;
		align-items: center;
		gap: 5px;
		padding: 6px 8px;
		background: rgba(0, 0, 0, 0.2);
		border-bottom: 1px solid rgba(255, 255, 255, 0.06);
	}

	.dot-win {
		width: 6px;
		height: 6px;
		border-radius: 50%;
	}

	.dot-win.red { background: #EF4444; }
	.dot-win.yellow { background: #F59E0B; }
	.dot-win.green { background: #10B981; }

	.mock-win-title {
		font-size: 9px;
		color: #94A3B8;
		margin-left: 4px;
	}

	.mock-win-body {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 10px;
	}

	.slide-block {
		text-align: center;
	}

	.slide-title {
		font-size: 12px;
		font-weight: 700;
		color: #FAF8F5;
		margin-bottom: 6px;
	}

	.slide-bar {
		width: 80px;
		height: 4px;
		background: var(--amber);
		border-radius: 2px;
		margin: 0 auto;
	}

	/* Center Bridge */
	.stream-bridge {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		text-align: center;
	}

	.bridge-arrow {
		display: flex;
		gap: 4px;
	}

	.bridge-arrow span {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: var(--amber);
		opacity: 0.3;
	}

	.bridge-arrow.is-animating span {
		animation: pulse-dot 1.2s infinite ease-in-out;
	}

	.bridge-arrow.is-animating span:nth-child(2) { animation-delay: 0.2s; }
	.bridge-arrow.is-animating span:nth-child(3) { animation-delay: 0.4s; }

	@keyframes pulse-dot {
		0%, 100% { opacity: 0.2; transform: scale(0.8); }
		50% { opacity: 1; transform: scale(1.2); }
	}

	.bridge-label {
		font-family: var(--mono);
		font-size: 9px;
		color: #94A3B8;
	}

	.bridge-metric {
		font-family: var(--mono);
		font-size: 10px;
		font-weight: 700;
		color: var(--amber);
	}

	/* Target TV View */
	.tv-screen-content {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: space-between;
		height: 100%;
		padding: 8px 0;
	}

	.tv-status-badge {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: 10px;
		color: #A7F3D0;
		background: rgba(16, 185, 129, 0.15);
		padding: 4px 8px;
		border-radius: var(--r-xs);
		border: 1px solid rgba(16, 185, 129, 0.25);
	}

	.pulse-indicator {
		width: 5px;
		height: 5px;
		border-radius: 50%;
		background: #10B981;
	}

	.tv-mirrored-slide {
		text-align: center;
		padding: 10px 0;
	}

	/* Floating Controls Bar (Seamless & Tactile) */
	.floating-controls-bar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin: 20px auto 0;
		max-width: 820px;
		padding: 8px 18px;
		background: var(--bg-surface);
		backdrop-filter: blur(16px);
		-webkit-backdrop-filter: blur(16px);
		border: 1px solid var(--line-subtle);
		border-radius: var(--r-pill);
		box-shadow: var(--shadow-sm);
		gap: 16px;
		flex-wrap: wrap;
		z-index: 3;
		position: relative;
		transition: border-color var(--dur-fast) var(--ease), box-shadow var(--dur-fast) var(--ease);
	}

	.floating-controls-bar:hover {
		border-color: var(--line);
		box-shadow: var(--shadow-md);
	}

	.controls-left {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.ctrl-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: var(--bg-subtle);
		border: 1px solid var(--line-subtle);
		color: var(--ink);
		cursor: pointer;
		transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
		            background-color var(--dur-fast) var(--ease),
		            border-color var(--dur-fast) var(--ease),
		            box-shadow 0.2s ease;
	}

	.ctrl-btn:hover {
		background: var(--bg-card);
		border-color: var(--amber);
		transform: scale(1.15);
		box-shadow: 0 0 12px rgba(245, 158, 11, 0.35);
		color: var(--amber-hover);
	}

	.ctrl-btn:active {
		transform: scale(0.92);
	}

	.audio-tag {
		font-size: 11px;
		font-family: var(--mono);
		color: var(--ink-3);
	}

	.timeline-wrapper {
		flex: 1;
		display: flex;
		align-items: center;
		gap: 10px;
		max-width: 400px;
	}

	.timeline-track {
		flex: 1;
		height: 6px;
		background: var(--line-subtle);
		border-radius: 3px;
		position: relative;
		cursor: pointer;
		transition: height 0.2s ease;
	}

	.timeline-track:hover {
		height: 8px;
	}

	.timeline-fill {
		position: relative;
		height: 100%;
		background: var(--amber);
		border-radius: 3px;
		transition: width 0.15s ease-out;
	}

	.timeline-thumb {
		position: absolute;
		right: -4px;
		top: 50%;
		transform: translateY(-50%) scale(0);
		width: 10px;
		height: 10px;
		border-radius: 50%;
		background: #FFFFFF;
		box-shadow: 0 0 8px rgba(245, 158, 11, 0.8);
		transition: transform 0.2s ease;
	}

	.timeline-track:hover .timeline-thumb {
		transform: translateY(-50%) scale(1);
	}

	.controls-right {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 11px;
		color: var(--ink-3);
	}

	.control-note {
		font-family: var(--mono);
	}

	@media (max-width: 768px) {
		.demo-mock-screen {
			grid-template-columns: 1fr;
		}

		.stream-bridge {
			transform: rotate(90deg);
			margin: 8px 0;
		}

		.floating-controls-bar {
			border-radius: var(--r-md);
			padding: 10px 14px;
		}

		.control-note {
			display: none;
		}
	}
</style>
