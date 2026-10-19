<script lang="ts">
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
				<div class="footer-actions">
					<a href="/downloads/ezku.link.dmg" download="ezku.link.dmg" class="btn btn-primary btn-sm">
						<span>Download .dmg</span>
						<span class="btn-arrow">→</span>
					</a>
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
					<li><a href="https://github.com/rinturajc/ezkuCasting" target="_blank" rel="noopener noreferrer">GitHub</a></li>
					<li><a href="https://github.com/rinturajc/ezkuCasting/releases" target="_blank" rel="noopener noreferrer">Releases</a></li>
					<li><a href="https://www.buymeacoffee.com/rin2" target="_blank" rel="noopener noreferrer">Buy Me a Coffee</a></li>
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

	.footer-actions {
		margin-top: 4px;
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
