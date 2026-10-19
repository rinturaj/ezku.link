<script lang="ts">
	let copied = $state(false);
	const brewCmd = 'brew install --cask ezku-link';

	async function copyBrew() {
		try {
			await navigator.clipboard.writeText(brewCmd);
			copied = true;
			setTimeout(() => {
				copied = false;
			}, 2000);
		} catch (err) {
			console.error('Failed to copy', err);
		}
	}
</script>

<footer class="footer-main">
	<div class="page-container">
		<div class="footer-columns">
			<!-- Brand Column -->
			<div class="footer-col brand-col">
				<div class="footer-brand">
					<span class="brand-icon">
						<img src="/MenuBarIcon@2x.png" alt="ezku.link icon" width="16" height="16" />
					</span>
					<span class="brand-text">ezku.link</span>
				</div>
				<p class="footer-brand-desc">
					Mirror your Mac display and cast 4K videos directly to Smart TVs without TV apps or extra players.
				</p>
				<div class="footer-brew-widget">
					<div class="footer-brew-label">
						<span class="brew-icon">🍺</span>
						<span>INSTALL VIA HOMEBREW</span>
					</div>
					<div class="footer-brew-box">
						<code class="footer-brew-code">{brewCmd}</code>
						<button
							type="button"
							class="footer-copy-btn"
							class:is-copied={copied}
							onclick={copyBrew}
							aria-label="Copy brew install command"
							title="Copy to clipboard"
						>
							{#if copied}
								<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
									<polyline points="20 6 9 17 4 12" />
								</svg>
								<span>Copied</span>
							{:else}
								<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
									<rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
									<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
								</svg>
								<span>Copy</span>
							{/if}
						</button>
					</div>
				</div>
				<div class="footer-support-row">
					<a
						href="https://www.buymeacoffee.com/rin2"
						target="_blank"
						rel="noopener noreferrer"
						class="footer-coffee-btn"
					>
						<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
							<path d="M18 8h1a4 4 0 0 1 0 8h-1" />
							<path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" />
							<line x1="6" y1="1" x2="6" y2="4" />
							<line x1="10" y1="1" x2="10" y2="4" />
							<line x1="14" y1="1" x2="14" y2="4" />
						</svg>
						<span>Buy Me a Coffee</span>
						<span class="coffee-arrow" aria-hidden="true">↗</span>
					</a>
					<span class="footer-support-note">Free &amp; open-source</span>
				</div>
			</div>

			<!-- Navigation Links -->
			<div class="footer-col">
				<span class="col-title text-mono">SECTIONS</span>
				<ul class="col-links">
					<li><a href="#how-to-use">How to Use</a></li>
					<li><a href="#demo">Demo Video</a></li>
					<li><a href="#smart-tvs">Smart TVs</a></li>
					<li><a href="#faq">FAQ</a></li>
				</ul>
			</div>

			<!-- AI & Machine Readability -->
			<div class="footer-col">
				<span class="col-title text-mono">AI & LLM</span>
				<ul class="col-links">
					<li><a href="/llms.txt">/llms.txt</a></li>
					<li><a href="/llms-full.txt">/llms-full.txt</a></li>
					<li><a href="/sitemap.xml">sitemap.xml</a></li>
				</ul>
			</div>

			<!-- Community & Project -->
			<div class="footer-col">
				<span class="col-title text-mono">PROJECT</span>
				<ul class="col-links">
					<li><a href="https://github.com/rinturaj/ezku.link" target="_blank" rel="noopener noreferrer">GitHub</a></li>
					<li><a href="https://github.com/rinturaj/ezku.link/releases" target="_blank" rel="noopener noreferrer">Releases</a></li>
					<li>
						<a href="https://www.buymeacoffee.com/rin2" target="_blank" rel="noopener noreferrer" class="coffee-project-link">
							<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
								<path d="M18 8h1a4 4 0 0 1 0 8h-1" />
								<path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" />
								<line x1="6" y1="1" x2="6" y2="4" />
								<line x1="10" y1="1" x2="10" y2="4" />
								<line x1="14" y1="1" x2="14" y2="4" />
							</svg>
							<span>Buy Me a Coffee</span>
							<span class="ext-arrow" aria-hidden="true">↗</span>
						</a>
					</li>
				</ul>
			</div>
		</div>

		<!-- Bottom Copyright & Rule -->
		<div class="footer-bottom-bar">
			<div class="copyright-text">
				© 2026 <strong>ezku.link</strong>. 100% Free &amp; Private on macOS.
			</div>
			<div class="footer-badges text-mono">
				<span>NO TV APPS</span>
				<span>NO 3RD-PARTY PLAYER</span>
				<span>LOCAL WI-FI</span>
			</div>
		</div>
	</div>
</footer>

<style>
	.footer-main {
		border-top: 1px solid var(--line);
		padding: clamp(48px, 6vw, 64px) 0 32px;
		background: var(--bg-subtle);
	}

	.footer-columns {
		display: grid;
		grid-template-columns: 2fr 1fr 1fr 1fr;
		gap: clamp(32px, 4vw, 48px);
		margin-bottom: 40px;
	}

	.brand-col {
		display: flex;
		flex-direction: column;
		gap: 14px;
	}

	.footer-brand {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.brand-icon {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 28px;
		height: 28px;
		border-radius: var(--r-xs);
		background: var(--ink);
	}

	:global([data-theme='dark']) .brand-icon img {
		filter: invert(1);
	}

	.brand-text {
		font-size: 18px;
		font-weight: 700;
		color: var(--ink);
	}

	.footer-brand-desc {
		font-size: var(--fs-xs);
		color: var(--ink-2);
		line-height: 1.55;
		max-width: 320px;
	}

	.footer-brew-widget {
		display: flex;
		flex-direction: column;
		gap: 6px;
		margin-top: 4px;
		max-width: 380px;
	}

	.footer-brew-label {
		display: flex;
		align-items: center;
		gap: 6px;
		font-family: var(--mono);
		font-size: 10px;
		font-weight: 700;
		letter-spacing: 0.06em;
		color: var(--amber-hover);
		text-transform: uppercase;
	}

	.brew-icon {
		font-size: 12px;
	}

	.footer-brew-box {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
		background: var(--bg-card);
		border: 1px solid var(--line);
		border-radius: var(--r-sm);
		padding: 5px 6px 5px 12px;
		transition: border-color 0.15s ease, box-shadow 0.15s ease;
	}

	.footer-brew-box:hover {
		border-color: var(--line-strong, #3a3a3c);
	}

	.footer-brew-code {
		font-family: var(--mono);
		font-size: 11.5px;
		color: var(--ink);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		user-select: all;
	}

	.footer-copy-btn {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		padding: 4px 9px;
		border-radius: var(--r-xs);
		background: var(--bg-subtle);
		border: 1px solid var(--line);
		color: var(--ink-2);
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		cursor: pointer;
		flex-shrink: 0;
		transition: all 0.15s ease;
	}

	.footer-copy-btn:hover {
		color: var(--amber-hover);
		border-color: var(--amber);
		background: var(--amber-bg);
	}

	.footer-copy-btn.is-copied {
		background: var(--live-green-bg);
		border-color: var(--live-green);
		color: var(--live-green);
		font-weight: 700;
	}

	.footer-support-row {
		display: flex;
		align-items: center;
		gap: 10px;
		flex-wrap: wrap;
		margin-top: 2px;
	}

	.footer-coffee-btn {
		display: inline-flex;
		align-items: center;
		gap: 7px;
		padding: 5px 11px;
		border-radius: var(--r-xs);
		background: var(--amber-bg);
		border: 1px solid var(--amber-border);
		color: var(--amber-hover);
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		text-decoration: none;
		letter-spacing: 0.02em;
		transition: transform 0.15s ease, background-color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
	}

	.footer-coffee-btn:hover {
		transform: translateY(-1px);
		border-color: var(--amber);
		background: rgba(245, 158, 11, 0.22);
		color: var(--amber-deep);
		box-shadow: 0 2px 8px rgba(245, 158, 11, 0.15);
	}

	.coffee-arrow {
		font-size: 11px;
		opacity: 0.8;
		transition: transform 0.15s ease;
	}

	.footer-coffee-btn:hover .coffee-arrow {
		transform: translate(1px, -1px);
		opacity: 1;
	}

	.footer-support-note {
		font-size: 11px;
		color: var(--ink-3);
		line-height: 1.3;
	}

	.coffee-project-link {
		display: inline-flex;
		align-items: center;
		gap: 6px;
	}

	.ext-arrow {
		font-size: 10px;
		opacity: 0.6;
		transition: opacity 0.15s ease, transform 0.15s ease;
	}

	.coffee-project-link:hover .ext-arrow {
		opacity: 1;
		transform: translate(1px, -1px);
	}

	.col-title {
		display: block;
		font-size: 11px;
		font-weight: 700;
		letter-spacing: 0.08em;
		color: var(--ink-2);
		margin-bottom: 14px;
	}

	.col-links {
		list-style: none;
		display: flex;
		flex-direction: column;
		gap: 10px;
	}

	.col-links a {
		font-size: var(--fs-xs);
		color: var(--ink-3);
		transition: color var(--dur-fast);
	}

	.col-links a:hover {
		color: var(--ink);
	}

	.footer-bottom-bar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding-top: 24px;
		border-top: 1px solid var(--line);
		font-size: var(--fs-xs);
		color: var(--ink-3);
		flex-wrap: wrap;
		gap: 16px;
	}

	.footer-badges {
		display: flex;
		align-items: center;
		gap: 12px;
		font-size: 10.5px;
	}

	@media (max-width: 860px) {
		.footer-columns {
			grid-template-columns: 1fr 1fr;
		}

		.brand-col {
			grid-column: 1 / -1;
		}
	}

	@media (max-width: 540px) {
		.footer-columns {
			grid-template-columns: 1fr;
		}
	}
</style>
