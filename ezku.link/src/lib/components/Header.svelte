<script lang="ts">
	import { onMount } from "svelte";

	let currentTheme = $state("light");
	let isScrolled = $state(false);

	onMount(() => {
		const docTheme = document.documentElement.getAttribute("data-theme");
		currentTheme = docTheme === "dark" ? "dark" : "light";

		const handleScroll = () => {
			isScrolled = window.scrollY > 20;
		};

		window.addEventListener("scroll", handleScroll, { passive: true });
		return () => window.removeEventListener("scroll", handleScroll);
	});

	function toggleTheme() {
		currentTheme = currentTheme === "light" ? "dark" : "light";
		document.documentElement.setAttribute("data-theme", currentTheme);
		try {
			localStorage.setItem("ezku-theme", currentTheme);
		} catch (e) {}
	}
</script>

<header class="header" class:is-scrolled={isScrolled}>
	<div class="page-container header-inner">
		<!-- Brand Logo -->
		<a href="/" class="brand-link" aria-label="ezku.link home">
			<span class="brand-icon">
				<img
					src="/MenuBarIcon@2x.png"
					alt="ezku.link icon"
					width="18"
					height="18"
				/>
			</span>
			<span class="brand-name">ezku.link</span>
			<span class="brand-badge">
				<span class="live-dot"></span>
				macOS
			</span>
		</a>

		<!-- Desktop Navigation -->
		<nav class="nav-links" aria-label="Main Navigation">
			<a href="#how-to-use" class="nav-link">How to Use</a>
			<a href="#demo" class="nav-link">Demo</a>
			<a href="#smart-tvs" class="nav-link">Smart TVs</a>
			<a href="#faq" class="nav-link">FAQ</a>
		</nav>

		<!-- Right Action Controls -->
		<div class="header-actions">
			<!-- Theme Toggle (Pleurat.com style half-circle) -->
			<button
				type="button"
				class="theme-toggle-btn"
				onclick={toggleTheme}
				aria-label="Toggle theme between warm paper light and dark"
				title="Toggle theme (Light / Dark)"
			>
				<svg
					width="18"
					height="18"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
				>
					<circle cx="12" cy="12" r="9" />
					<path d="M12 3a9 9 0 0 1 0 18z" fill="currentColor" />
				</svg>
			</button>

			<!-- Direct DMG Download CTA -->
			<a
				href="/downloads/ezku.link.dmg"
				download="ezku.link.dmg"
				class="btn btn-primary btn-sm header-cta"
			>
				<span>Download .dmg</span>
				<span class="btn-arrow">→</span>
			</a>
		</div>
	</div>
</header>

<style>
	.header {
		position: sticky;
		top: 0;
		left: 0;
		right: 0;
		z-index: 100;
		background: transparent;
		transition:
			background-color var(--dur-normal) var(--ease),
			border-color var(--dur-normal) var(--ease),
			backdrop-filter var(--dur-normal) var(--ease);
		border-bottom: 1px solid transparent;
	}

	.header.is-scrolled {
		background: var(--bg-surface);
		backdrop-filter: blur(18px) saturate(180%);
		-webkit-backdrop-filter: blur(18px) saturate(180%);
		border-bottom: 1px solid var(--line);
	}

	.header-inner {
		display: flex;
		align-items: center;
		justify-content: space-between;
		height: 72px;
		gap: 20px;
	}

	.brand-link {
		display: flex;
		align-items: center;
		gap: 10px;
		font-weight: 700;
		font-size: 20px;
		letter-spacing: -0.03em;
		color: var(--ink);
	}

	.brand-icon {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 32px;
		height: 32px;
		border-radius: var(--r-sm);
		background: var(--amber);
		color: var(--bg);
		transition:
			transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1),
			background-color 0.25s ease,
			box-shadow 0.25s ease;
	}

	.brand-link:hover .brand-icon {
		transform: scale(1.12) rotate(6deg);
		background: var(--amber);
		box-shadow: 0 0 12px rgba(245, 158, 11, 0.4);
	}

	:global([data-theme="dark"]) .brand-icon img {
		filter: invert(1);
	}

	:global([data-theme="dark"]) .brand-link:hover .brand-icon img {
		filter: invert(0);
	}

	.brand-name {
		font-size: 19px;
		font-weight: 700;
	}

	.brand-badge {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		font-family: var(--mono);
		font-size: 10.5px;
		padding: 2px 7px;
		border-radius: var(--r-pill);
		background: var(--bg-card-alt);
		border: 1px solid var(--line);
		color: var(--ink-3);
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.nav-links {
		display: flex;
		align-items: center;
		gap: 28px;
	}

	.nav-link {
		position: relative;
		font-size: var(--fs-xs);
		font-weight: 500;
		color: var(--ink-2);
		transition:
			color var(--dur-fast) var(--ease),
			transform 0.2s ease;
		padding: 6px 0;
	}

	.nav-link:hover {
		color: var(--ink);
		transform: translateY(-1px);
	}

	.nav-link:hover::after {
		content: "";
		position: absolute;
		bottom: -2px;
		left: 50%;
		transform: translateX(-50%);
		width: 4px;
		height: 4px;
		border-radius: 50%;
		background: var(--amber);
	}

	.header-actions {
		display: flex;
		align-items: center;
		gap: 14px;
	}

	.theme-toggle-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 36px;
		height: 36px;
		border-radius: 50%;
		color: var(--ink-2);
		background: var(--bg-card-alt);
		border: 1px solid var(--line);
		transition:
			transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1),
			color 0.2s ease,
			border-color 0.2s ease,
			box-shadow 0.2s ease;
	}

	.theme-toggle-btn:hover {
		color: var(--amber-deep);
		border-color: var(--amber);
		transform: rotate(180deg) scale(1.12);
		box-shadow: 0 0 12px rgba(245, 158, 11, 0.25);
	}

	.theme-toggle-btn:active {
		transform: rotate(180deg) scale(0.92);
	}

	.header-cta {
		box-shadow: 0 4px 14px -2px rgba(245, 158, 11, 0.35);
	}

	@media (max-width: 860px) {
		.nav-links {
			display: none;
		}
	}
</style>
