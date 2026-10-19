<script lang="ts">
	import { scrollReveal } from '$lib/actions/scrollAnimation';

	type CommandMode = 'install' | 'update' | 'uninstall';
	let activeCommand = $state<CommandMode>('install');
	let copied = $state(false);
	let showGatekeeperInfo = $state(false);
	let isOption2Open = $state(false);

	const commandDetails: Record<
		CommandMode,
		{ cmd: string; label: string; tip: string }
	> = {
		install: {
			cmd: 'brew install --cask ezku-link',
			label: 'Install',
			tip: 'Installs ezku.link to /Applications and registers menu bar casting utility'
		},
		update: {
			cmd: 'brew upgrade ezku-link',
			label: 'Update',
			tip: 'Upgrades to the latest release for Apple Silicon and Intel Macs'
		},
		uninstall: {
			cmd: 'brew uninstall ezku-link',
			label: 'Uninstall',
			tip: 'Cleanly uninstalls ezku.link and removes brew cask configuration'
		}
	};

	async function copyCurrentCommand() {
		try {
			await navigator.clipboard.writeText(commandDetails[activeCommand].cmd);
			copied = true;
			setTimeout(() => {
				copied = false;
			}, 2200);
		} catch (err) {
			console.error('Failed to copy', err);
		}
	}
</script>

<section class="hero-section" use:scrollReveal>
	<div class="page-container">
		<!-- Badges & Sponsor -->
		<div class="hero-header-row">
			<div class="badge-wrapper">
				<span class="ui-badge is-accent">NO TV APPS</span>
				<span class="ui-badge">NO VLC OR 3RD-PARTY PLAYER</span>
				<span class="ui-badge is-live">
					<span class="live-dot"></span>
					1-CLICK MENU BAR
				</span>
			</div>
			<div class="hero-header-actions">
				<a
					href="https://www.buymeacoffee.com/rin2"
					target="_blank"
					rel="noopener noreferrer"
					class="hero-coffee-chip"
					title="Support ezku.link on Buy Me a Coffee"
				>
					<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
						<path d="M18 8h1a4 4 0 0 1 0 8h-1" />
						<path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" />
						<line x1="6" y1="1" x2="6" y2="4" />
						<line x1="10" y1="1" x2="10" y2="4" />
						<line x1="14" y1="1" x2="14" y2="4" />
					</svg>
					<span>Buy Me a Coffee</span>
					<span class="coffee-arrow" aria-hidden="true">↗</span>
				</a>
				<div class="hero-corner-mark" aria-hidden="true">⌟</div>
			</div>
		</div>

		<!-- Main Headline -->
		<div class="hero-content">
			<h1 class="hero-headline h-1">
				Cast your Mac screen &amp; 4K movies to any TV.
			</h1>
			<p class="text-lead hero-lead">
				Mirror your display or stream 4K videos directly to <strong>Samsung, LG, Sony, Roku &amp; Chromecast</strong>. Your TV plays the stream in its native hardware player—no TV apps to install, no third-party players, and zero setup.
			</p>
			
			<!-- Installation & Quick Start -->
			<div class="hero-install-widget">
				<!-- Option 1: Homebrew (Recommended) -->
				<div class="ui-card install-card">
					<div class="corner-bracket top-right"></div>
					<div class="corner-bracket bottom-left"></div>

					<div class="install-card-header">
						<div class="install-header-left">
							<span class="ui-badge is-accent">OPTION 1</span>
							<span class="install-title">Homebrew</span>
							<span class="ui-badge is-live recommended-tag">
								<span class="live-dot"></span>
								RECOMMENDED
							</span>
						</div>

						<div class="cmd-pill-tabs" role="tablist" aria-label="Homebrew command options">
							{#each (['install', 'update', 'uninstall'] as const) as mode}
								<button
									type="button"
									role="tab"
									aria-selected={activeCommand === mode}
									class="cmd-pill-tab"
									class:is-active={activeCommand === mode}
									onclick={() => {
										activeCommand = mode;
										copied = false;
									}}
								>
									{commandDetails[mode].label}
								</button>
							{/each}
						</div>
					</div>

					<!-- Monospace Terminal Snippet -->
					<div
						class="terminal-box"
						role="button"
						tabindex="0"
						onclick={copyCurrentCommand}
						onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && copyCurrentCommand()}
						title="Click to copy command"
					>
						<div class="terminal-command-wrap">
							<span class="terminal-prompt" aria-hidden="true">$</span>
							<code class="terminal-code">
								<span class="code-kw">brew</span>
								{#if activeCommand === 'install'}
									<span class="code-arg">install --cask</span>
									<span class="code-pkg">ezku-link</span>
								{:else if activeCommand === 'update'}
									<span class="code-arg">upgrade</span>
									<span class="code-pkg">ezku-link</span>
								{:else}
									<span class="code-arg">uninstall</span>
									<span class="code-pkg">ezku-link</span>
								{/if}
							</code>
						</div>

						<button
							type="button"
							class="copy-btn"
							class:is-copied={copied}
							onclick={(e) => {
								e.stopPropagation();
								copyCurrentCommand();
							}}
							aria-label="Copy command to clipboard"
						>
							{#if copied}
								<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
									<polyline points="20 6 9 17 4 12" />
								</svg>
								<span>Copied!</span>
							{:else}
								<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
									<rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
									<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
								</svg>
								<span>Copy</span>
							{/if}
						</button>
					</div>

					<div class="install-card-footer">
						<span class="cmd-tip">{commandDetails[activeCommand].tip}</span>
						<div class="cmd-quick-links">
							{#if activeCommand !== 'update'}
								<button
									type="button"
									class="quick-cmd-btn"
									onclick={() => { activeCommand = 'update'; copyCurrentCommand(); }}
								>
									<span>To update:</span>
									<code class="mono-inline">brew upgrade ezku-link</code>
								</button>
							{/if}
							{#if activeCommand !== 'uninstall'}
								<button
									type="button"
									class="quick-cmd-btn"
									onclick={() => { activeCommand = 'uninstall'; copyCurrentCommand(); }}
								>
									<span>To uninstall:</span>
									<code class="mono-inline">brew uninstall ezku-link</code>
								</button>
							{/if}
						</div>
					</div>
				</div>

				<!-- Option 2: Direct .dmg Download & Watch Demo (Collapsible) -->
				<div class="alt-install-box" class:is-expanded={isOption2Open}>
					<button
						type="button"
						class="alt-install-header-btn"
						onclick={() => (isOption2Open = !isOption2Open)}
						aria-expanded={isOption2Open}
						aria-controls="option2-details-content"
					>
						<div class="alt-header-left">
							<span class="ui-badge">OPTION 2</span>
							<span class="alt-label">Direct .dmg Installer</span>
							<span class="alt-subtext">Manual offline package</span>
						</div>
						<div class="alt-header-right">
							<span class="alt-toggle-hint">{isOption2Open ? 'Collapse' : 'Show download'}</span>
							<span class="alt-chevron" class:is-open={isOption2Open}>▾</span>
						</div>
					</button>

					{#if isOption2Open}
						<div id="option2-details-content" class="alt-install-body">
							<div class="alt-actions-row">
								<div class="hero-cta-group">
									<a href="/downloads/ezku.link.dmg" download="ezku.link.dmg" class="btn btn-secondary">
										<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
											<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
											<polyline points="7 10 12 15 17 10" />
											<line x1="12" y1="15" x2="12" y2="3" />
										</svg>
										<span>Download .dmg</span>
										<span class="cta-subtag">v1.0 (5.9 MB)</span>
										<span class="btn-arrow">→</span>
									</a>
									<a href="#demo" class="btn btn-secondary">
										<span>Watch Demo</span>
										<span class="btn-arrow">↓</span>
									</a>
								</div>

								<button
									type="button"
									class="gatekeeper-pill-btn"
									onclick={() => (showGatekeeperInfo = !showGatekeeperInfo)}
									title="Click to view macOS Gatekeeper / unnotarized app instructions"
								>
									<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
										<circle cx="12" cy="12" r="10" />
										<line x1="12" y1="16" x2="12" y2="12" />
										<line x1="12" y1="8" x2="12.01" y2="8" />
									</svg>
									<span>Unnotarized App Info</span>
									<span class="caret-icon" class:is-open={showGatekeeperInfo}>▾</span>
								</button>
							</div>

							<!-- Unnotarized Gatekeeper Notice Strip -->
							<div class="dmg-notice-strip">
								<span class="notice-bullet">⚠️</span>
								<span class="notice-text">
									<strong>Not notarized by Apple:</strong> On first launch, macOS may prompt an unverified developer warning.
									<button type="button" class="notice-link-btn" onclick={() => (showGatekeeperInfo = !showGatekeeperInfo)}>
										{showGatekeeperInfo ? 'Hide instructions' : 'How to open (Right-click → Open)'}
									</button>
								</span>
							</div>

							{#if showGatekeeperInfo}
								<div class="gatekeeper-guide-card">
									<div class="guide-header">
										<div class="guide-title-wrap">
											<span class="guide-shield-icon">🛡️</span>
											<div>
												<h4 class="guide-title">Opening Unnotarized Apps on macOS</h4>
												<p class="guide-subtitle">ezku.link is free &amp; open-source without an annual Apple Developer certificate.</p>
											</div>
										</div>
										<button
											type="button"
											class="guide-close-btn"
											onclick={() => (showGatekeeperInfo = false)}
											aria-label="Close Guide"
										>×</button>
									</div>

									<div class="guide-steps-grid">
										<div class="guide-step-card">
											<div class="step-badge">Step 1</div>
											<div class="step-content">
												<p class="step-action">Drag into Applications</p>
												<p class="step-desc">Open the downloaded DMG and drag <code>ezku.link.app</code> into your <strong>Applications</strong> folder.</p>
											</div>
										</div>

										<div class="guide-step-card is-highlighted">
											<div class="step-badge">Step 2</div>
											<div class="step-content">
												<p class="step-action">Right-Click → Open</p>
												<p class="step-desc"><strong>Right-click</strong> (or Control-click) <code>ezku.link.app</code> and select <strong>Open</strong> from the context menu.</p>
											</div>
										</div>

										<div class="guide-step-card">
											<div class="step-badge">Step 3</div>
											<div class="step-content">
												<p class="step-action">Confirm Open</p>
												<p class="step-desc">Click <strong>Open</strong> in the dialog. (Or open <em>System Settings → Privacy &amp; Security → Open Anyway</em>).</p>
											</div>
										</div>
									</div>

									<div class="guide-homebrew-tip">
										<span class="tip-icon">💡</span>
										<span>
											<strong>Prefer zero warnings?</strong> Option 1 (Homebrew) automatically bypasses Gatekeeper on install.
										</span>
									</div>
								</div>
							{/if}
						</div>
					{/if}
				</div>
			</div>

			<div class="hero-specs-row">
				<span>macOS 14+ (Sonoma &amp; Sequoia)</span>
				<span class="dot-sep">•</span>
				<span>Apple Silicon M1/M2/M3/M4</span>
				<span class="dot-sep">•</span>
				<span>100% Free &amp; Private</span>
				<span class="dot-sep">•</span>
				<a
					href="https://www.buymeacoffee.com/rin2"
					target="_blank"
					rel="noopener noreferrer"
					class="hero-specs-coffee"
				>
					<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
						<path d="M18 8h1a4 4 0 0 1 0 8h-1" />
						<path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" />
						<line x1="6" y1="1" x2="6" y2="4" />
						<line x1="10" y1="1" x2="10" y2="4" />
						<line x1="14" y1="1" x2="14" y2="4" />
					</svg>
					<span>Support on Buy Me a Coffee</span>
					<span class="coffee-arrow" aria-hidden="true">↗</span>
				</a>
			</div>
		</div>

		<!-- 4 Minimal Stat Badges -->
		<div class="metrics-strip">
			<div class="metric-block">
				<div class="metric-num">0 Apps</div>
				<div class="metric-label">On your TV</div>
			</div>
			<div class="metric-sep"></div>
			<div class="metric-block">
				<div class="metric-num">0 Players</div>
				<div class="metric-label">No VLC needed</div>
			</div>
			<div class="metric-sep"></div>
			<div class="metric-block">
				<div class="metric-num">1 Click</div>
				<div class="metric-label">Mac menu bar</div>
			</div>
			<div class="metric-sep"></div>
			<div class="metric-block">
				<div class="metric-num">&lt; 25ms</div>
				<div class="metric-label">Real-time sync</div>
			</div>
		</div>
	</div>
</section>

<style>
	.hero-section {
		padding-top: clamp(32px, 5vw, 60px);
		padding-bottom: clamp(40px, 5vw, 64px);
		position: relative;
	}

	.hero-header-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 24px;
		border-bottom: 1px solid var(--line);
		padding-bottom: 16px;
		gap: 14px;
		flex-wrap: wrap;
	}

	.badge-wrapper {
		display: flex;
		align-items: center;
		gap: 10px;
		flex-wrap: wrap;
	}

	.hero-header-actions {
		display: inline-flex;
		align-items: center;
		gap: 14px;
	}

	.hero-coffee-chip {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		padding: 4px 11px;
		border-radius: var(--r-pill);
		background: var(--amber-bg);
		border: 1px solid var(--amber-border);
		color: var(--amber-hover);
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		text-decoration: none;
		letter-spacing: 0.03em;
		transition: transform 0.15s ease, background-color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
	}

	.hero-coffee-chip:hover {
		transform: translateY(-1px);
		border-color: var(--amber);
		background: rgba(245, 158, 11, 0.22);
		color: var(--amber-deep);
		box-shadow: 0 2px 10px rgba(245, 158, 11, 0.2);
	}

	.hero-coffee-chip .coffee-arrow {
		font-size: 10px;
		opacity: 0.75;
		transition: transform 0.15s ease, opacity 0.15s ease;
	}

	.hero-coffee-chip:hover .coffee-arrow {
		transform: translate(1px, -1px);
		opacity: 1;
	}

	.hero-corner-mark {
		font-family: var(--mono);
		font-size: 24px;
		color: var(--amber);
		user-select: none;
		line-height: 1;
	}

	.hero-content {
		max-width: 860px;
		display: flex;
		flex-direction: column;
		gap: 18px;
		margin-bottom: clamp(36px, 5vw, 48px);
	}

	.hero-headline {
		color: var(--ink);
		font-weight: 700;
		letter-spacing: -0.035em;
	}

	.hero-lead {
		color: var(--ink-2);
		font-weight: 400;
		max-width: 700px;
		line-height: 1.6;
	}

	/* Hero Installation & Quick Start Widget */
	.hero-install-widget {
		display: flex;
		flex-direction: column;
		gap: 14px;
		margin: 6px 0 4px 0;
		max-width: 780px;
	}

	.install-card {
		position: relative;
		background: var(--bg-card);
		border: 1px solid var(--line);
		border-radius: var(--r-lg);
		padding: 16px 20px;
		box-shadow: var(--shadow-sm);
		transition: border-color 0.25s ease, box-shadow 0.25s ease;
	}

	.install-card:hover {
		border-color: var(--line-strong);
		box-shadow: var(--shadow-md);
	}

	.install-card-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		flex-wrap: wrap;
		margin-bottom: 12px;
	}

	.install-header-left {
		display: flex;
		align-items: center;
		gap: 8px;
		flex-wrap: wrap;
	}

	.install-title {
		font-size: var(--fs-base);
		font-weight: 700;
		color: var(--ink);
		letter-spacing: -0.015em;
	}

	.recommended-tag {
		font-size: 10px;
		padding: 3px 8px;
	}

	.cmd-pill-tabs {
		display: inline-flex;
		align-items: center;
		background: var(--bg-card-alt);
		padding: 3px;
		border-radius: var(--r-pill);
		border: 1px solid var(--line);
		gap: 2px;
	}

	.cmd-pill-tab {
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		padding: 4px 11px;
		border-radius: var(--r-pill);
		color: var(--ink-3);
		transition: all 0.2s ease;
		cursor: pointer;
		border: 1px solid transparent;
		background: transparent;
	}

	.cmd-pill-tab:hover {
		color: var(--ink);
	}

	.cmd-pill-tab.is-active {
		background: var(--bg-card);
		color: var(--ink);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
		border-color: var(--line);
	}

	:global([data-theme="dark"]) .cmd-pill-tab.is-active {
		background: var(--bg-subtle);
		border-color: var(--line-strong);
	}

	/* Monospace Terminal Box */
	.terminal-box {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		background: var(--bg-subtle);
		border: 1px solid var(--line);
		border-radius: var(--r-md);
		padding: 12px 16px;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.terminal-box:hover {
		border-color: var(--amber);
		background: var(--bg-card-alt);
		box-shadow: 0 4px 16px rgba(245, 158, 11, 0.12);
	}

	.terminal-box:active {
		transform: scale(0.995);
	}

	.terminal-command-wrap {
		display: flex;
		align-items: center;
		gap: 10px;
		overflow-x: auto;
		white-space: nowrap;
		scrollbar-width: none;
		-webkit-overflow-scrolling: touch;
	}

	.terminal-command-wrap::-webkit-scrollbar {
		display: none;
	}

	.terminal-prompt {
		font-family: var(--mono);
		font-weight: 700;
		color: var(--amber);
		user-select: none;
		font-size: 15px;
	}

	.terminal-code {
		font-family: var(--mono);
		font-size: clamp(13px, 1.3vw, 15px);
		font-weight: 500;
		display: inline-flex;
		align-items: center;
		gap: 7px;
		user-select: all;
	}

	.code-kw {
		color: var(--amber-hover);
		font-weight: 700;
	}

	.code-arg {
		color: var(--ink-2);
	}

	.code-pkg {
		color: var(--ink);
		font-weight: 700;
		background: var(--amber-tint);
		padding: 2px 7px;
		border-radius: var(--r-xs);
		border: 1px solid var(--amber-border);
	}

	.copy-btn {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		font-family: var(--mono);
		font-size: 11.5px;
		font-weight: 600;
		padding: 6px 14px;
		border-radius: var(--r-pill);
		background: var(--bg-card);
		border: 1px solid var(--line);
		color: var(--ink);
		transition: all 0.2s ease;
		cursor: pointer;
		flex-shrink: 0;
		box-shadow: var(--shadow-sm);
	}

	.copy-btn:hover {
		border-color: var(--amber);
		background: var(--amber-bg);
		color: var(--amber-deep);
		transform: translateY(-1px);
	}

	.copy-btn.is-copied {
		background: var(--live-green-bg);
		border-color: var(--live-green);
		color: var(--live-green);
		font-weight: 700;
	}

	.install-card-footer {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		flex-wrap: wrap;
		margin-top: 10px;
		font-family: var(--mono);
		font-size: var(--fs-micro);
		color: var(--ink-3);
	}

	.cmd-tip {
		color: var(--ink-3);
		font-size: 11.5px;
	}

	.cmd-quick-links {
		display: flex;
		align-items: center;
		gap: 8px;
		flex-wrap: wrap;
	}

	.quick-cmd-btn {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink-3);
		padding: 3px 8px;
		border-radius: var(--r-xs);
		transition: all 0.15s ease;
		cursor: pointer;
		background: transparent;
		border: 1px dashed var(--line);
	}

	.quick-cmd-btn:hover {
		color: var(--ink);
		border-color: var(--amber);
		background: var(--bg-card-alt);
	}

	.mono-inline {
		color: var(--amber-hover);
		font-weight: 600;
	}

	/* Option 2 Collapsible Container */
	.alt-install-box {
		background: var(--bg-card-alt);
		border: 1px solid var(--line);
		border-radius: var(--r-md);
		overflow: hidden;
		transition: border-color 0.2s ease, background 0.2s ease, box-shadow 0.2s ease;
	}

	.alt-install-box:hover {
		border-color: var(--line-strong, #3a3a3c);
	}

	.alt-install-box.is-expanded {
		border-color: var(--line-strong, #3a3a3c);
		box-shadow: var(--shadow-sm);
	}

	.alt-install-header-btn {
		width: 100%;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
		padding: 10px 16px;
		background: transparent;
		border: none;
		cursor: pointer;
		text-align: left;
		transition: background-color 0.15s ease;
	}

	.alt-install-header-btn:hover {
		background: rgba(255, 255, 255, 0.03);
	}

	.alt-header-left {
		display: flex;
		align-items: center;
		gap: 10px;
		flex-wrap: wrap;
	}

	.alt-label {
		font-size: 12px;
		font-family: var(--mono);
		font-weight: 600;
		color: var(--ink);
		letter-spacing: 0.02em;
	}

	.alt-subtext {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink-3);
	}

	.alt-header-right {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		flex-shrink: 0;
	}

	.alt-toggle-hint {
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 600;
		color: var(--amber-hover);
		letter-spacing: 0.04em;
		text-transform: uppercase;
	}

	.alt-chevron {
		font-size: 11px;
		color: var(--ink-2);
		transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
		display: inline-block;
	}

	.alt-chevron.is-open {
		transform: rotate(180deg);
	}

	.alt-install-body {
		padding: 14px 16px 16px;
		border-top: 1px dashed var(--line);
		display: flex;
		flex-direction: column;
		gap: 12px;
		animation: fadeInSlide 0.2s cubic-bezier(0.16, 1, 0.3, 1);
	}

	@keyframes fadeInSlide {
		from {
			opacity: 0;
			transform: translateY(-4px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.alt-actions-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 14px;
		flex-wrap: wrap;
	}

	.hero-cta-group {
		display: flex;
		align-items: center;
		gap: 10px;
		flex-wrap: wrap;
	}

	.cta-subtag {
		font-family: var(--mono);
		font-size: 11px;
		opacity: 0.85;
		padding: 2px 6px;
		background: rgba(0, 0, 0, 0.08);
		border-radius: var(--r-xs);
	}

	/* Gatekeeper Notice & First Open Guide */
	.gatekeeper-pill-btn {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		padding: 3px 9px;
		border-radius: var(--r-pill);
		background: var(--amber-bg);
		border: 1px solid var(--amber-border);
		color: var(--amber-hover);
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		cursor: pointer;
		transition: transform 0.15s ease, background-color 0.15s ease, border-color 0.15s ease;
	}

	.gatekeeper-pill-btn:hover {
		transform: translateY(-1px);
		border-color: var(--amber);
		background: rgba(245, 158, 11, 0.22);
	}

	.caret-icon {
		font-size: 10px;
		transition: transform 0.2s ease;
		display: inline-block;
	}

	.caret-icon.is-open {
		transform: rotate(180deg);
	}

	.dmg-notice-strip {
		display: flex;
		align-items: center;
		gap: 8px;
		margin-top: 8px;
		padding: 7px 14px;
		font-size: 12px;
		color: var(--ink-2);
		background: var(--bg-card);
		border: 1px dashed var(--line);
		border-radius: var(--r-sm);
	}

	.notice-bullet {
		font-size: 13px;
	}

	.notice-text {
		display: flex;
		align-items: center;
		gap: 6px;
		flex-wrap: wrap;
	}

	.notice-link-btn {
		background: none;
		border: none;
		padding: 0;
		color: var(--amber-hover);
		font-weight: 600;
		text-decoration: underline;
		cursor: pointer;
		font-size: inherit;
		font-family: inherit;
	}

	.notice-link-btn:hover {
		color: var(--amber);
	}

	/* Gatekeeper Guide Card */
	.gatekeeper-guide-card {
		margin-top: 12px;
		padding: 16px 20px;
		background: var(--bg-card);
		border: 1px solid var(--amber-border);
		border-radius: var(--r-md);
		box-shadow: var(--shadow-md);
		position: relative;
		animation: fadeInSlide 0.25s var(--ease);
	}

	@keyframes fadeInSlide {
		from { opacity: 0; transform: translateY(-6px); }
		to { opacity: 1; transform: translateY(0); }
	}

	.guide-header {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		margin-bottom: 12px;
		gap: 12px;
	}

	.guide-title-wrap {
		display: flex;
		align-items: flex-start;
		gap: 10px;
	}

	.guide-shield-icon {
		font-size: 20px;
		line-height: 1;
	}

	.guide-title {
		font-size: 14.5px;
		font-weight: 700;
		color: var(--ink);
		margin: 0;
	}

	.guide-subtitle {
		font-size: 12px;
		color: var(--ink-3);
		margin: 2px 0 0;
	}

	.guide-close-btn {
		background: transparent;
		border: none;
		font-size: 20px;
		line-height: 1;
		color: var(--ink-3);
		cursor: pointer;
		padding: 2px 6px;
		border-radius: var(--r-xs);
		transition: color 0.15s ease, background 0.15s ease;
	}

	.guide-close-btn:hover {
		color: var(--ink);
		background: var(--bg-subtle);
	}

	.guide-steps-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
		gap: 12px;
		margin: 14px 0;
	}

	.guide-step-card {
		padding: 12px 14px;
		background: var(--bg-subtle);
		border: 1px solid var(--line-subtle);
		border-radius: var(--r-sm);
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.guide-step-card.is-highlighted {
		border-color: var(--amber);
		background: var(--amber-bg);
	}

	.step-badge {
		font-family: var(--mono);
		font-size: 10px;
		font-weight: 700;
		color: var(--amber-hover);
		letter-spacing: 0.05em;
		text-transform: uppercase;
	}

	.step-action {
		font-size: 12.5px;
		font-weight: 700;
		color: var(--ink);
		margin: 0;
	}

	.step-desc {
		font-size: 11.5px;
		color: var(--ink-2);
		margin: 0;
		line-height: 1.45;
	}

	.step-desc code {
		font-family: var(--mono);
		font-size: 10.5px;
		background: rgba(0, 0, 0, 0.06);
		padding: 1px 4px;
		border-radius: 3px;
	}

	.guide-homebrew-tip {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 12px;
		background: var(--bg-card-alt);
		border-radius: var(--r-xs);
		font-size: 12px;
		color: var(--ink-2);
	}

	.tip-icon {
		font-size: 14px;
	}

	.badge-wrapper :global(.ui-badge) {
		transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
		            box-shadow 0.2s ease,
		            border-color 0.2s ease;
		cursor: default;
	}

	.badge-wrapper :global(.ui-badge:hover) {
		transform: translateY(-2px) scale(1.03);
		border-color: var(--amber);
		box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
	}

	.hero-specs-row {
		display: flex;
		align-items: center;
		gap: 10px;
		font-size: var(--fs-xs);
		color: var(--ink-3);
		font-family: var(--mono);
		flex-wrap: wrap;
	}

	.dot-sep {
		opacity: 0.4;
	}

	.hero-specs-coffee {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		color: var(--amber-hover);
		text-decoration: none;
		font-weight: 600;
		transition: color 0.15s ease, transform 0.15s ease;
	}

	.hero-specs-coffee:hover {
		color: var(--amber-deep);
		transform: translateY(-1px);
	}

	.hero-specs-coffee .coffee-arrow {
		font-size: 10px;
		transition: transform 0.15s ease;
	}

	.hero-specs-coffee:hover .coffee-arrow {
		transform: translate(1px, -1px);
	}

	/* Minimal Metrics Strip */
	.metrics-strip {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		background: var(--bg-card);
		border: 1px solid var(--line);
		border-radius: var(--r-lg);
		padding: 14px 20px;
		box-shadow: var(--shadow-sm);
		transition: border-color 0.25s ease, box-shadow 0.25s ease;
	}

	.metrics-strip:hover {
		border-color: var(--line-strong);
		box-shadow: var(--shadow-md);
	}

	.metric-block {
		text-align: center;
		padding: 8px 6px;
		border-radius: var(--r-md);
		transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
		            background-color 0.2s ease;
		cursor: default;
	}

	.metric-block:hover {
		transform: translateY(-3px) scale(1.05);
		background: var(--amber-bg);
	}

	.metric-num {
		font-size: clamp(24px, 2.6vw, 30px);
		font-weight: 700;
		letter-spacing: -0.02em;
		color: var(--ink);
		line-height: 1.1;
		font-family: var(--mono);
		transition: color 0.2s ease, transform 0.2s ease;
		display: inline-block;
	}

	.metric-block:hover .metric-num {
		color: var(--amber-hover);
	}

	.metric-label {
		font-size: var(--fs-xs);
		color: var(--ink-3);
		margin-top: 4px;
		font-weight: 500;
		transition: color 0.2s ease;
	}

	.metric-block:hover .metric-label {
		color: var(--amber-deep);
	}

	.metric-sep {
		width: 1px;
		background: var(--line);
		margin: 4px auto;
	}

	@media (max-width: 860px) {
		.metrics-strip {
			grid-template-columns: repeat(2, 1fr);
			gap: 16px;
		}

		.metric-sep {
			display: none;
		}
	}
</style>
