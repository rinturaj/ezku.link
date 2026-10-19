<script lang="ts">
	import { scrollReveal } from '$lib/actions/scrollAnimation';

	type CommandMode = 'install' | 'update' | 'uninstall';
	let activeCommand = $state<CommandMode>('install');
	let copied = $state(false);

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
			tip: 'Upgrades to the latest release with notarized Apple Silicon/Intel binaries'
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
		<!-- Badges -->
		<div class="hero-header-row">
			<div class="badge-wrapper">
				<span class="ui-badge is-accent">NO TV APPS</span>
				<span class="ui-badge">NO VLC OR 3RD-PARTY PLAYER</span>
				<span class="ui-badge is-live">
					<span class="live-dot"></span>
					1-CLICK MENU BAR
				</span>
			</div>
			<div class="hero-corner-mark" aria-hidden="true">⌟</div>
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

				<!-- Option 2: Direct .dmg Download & Watch Demo -->
				<div class="alt-install-row">
					<div class="alt-meta">
						<span class="ui-badge">OPTION 2</span>
						<span class="alt-label">Direct .dmg Installer</span>
					</div>

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
				</div>
			</div>

			<div class="hero-specs-row">
				<span>macOS 14+ (Sonoma &amp; Sequoia)</span>
				<span class="dot-sep">•</span>
				<span>Apple Silicon M1/M2/M3/M4</span>
				<span class="dot-sep">•</span>
				<span>100% Free &amp; Private</span>
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
	}

	.badge-wrapper {
		display: flex;
		align-items: center;
		gap: 10px;
		flex-wrap: wrap;
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

	/* Option 2 Alternative Strip */
	.alt-install-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 14px;
		flex-wrap: wrap;
		padding: 10px 16px;
		background: var(--bg-card-alt);
		border: 1px solid var(--line);
		border-radius: var(--r-md);
	}

	.alt-meta {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.alt-label {
		font-size: 12px;
		font-family: var(--mono);
		font-weight: 600;
		color: var(--ink-2);
		letter-spacing: 0.02em;
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
