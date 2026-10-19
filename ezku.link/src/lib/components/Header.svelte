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

			<!-- GitHub Repository Link -->
			<a
				href="https://github.com/rinturaj/ezku.link"
				target="_blank"
				rel="noopener noreferrer"
				class="header-github-btn"
				aria-label="View ezku.link source code on GitHub"
			>
				<svg
					width="16"
					height="16"
					viewBox="0 0 24 24"
					fill="currentColor"
					aria-hidden="true"
				>
					<path
						fill-rule="evenodd"
						clip-rule="evenodd"
						d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
					/>
				</svg>
				<span class="github-label">GitHub</span>
				<span class="external-icon" aria-hidden="true">↗</span>
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

	.header-github-btn {
		display: inline-flex;
		align-items: center;
		gap: 7px;
		padding: 7px 15px;
		border-radius: var(--r-pill);
		background: var(--bg-card);
		border: 1px solid var(--line);
		color: var(--ink);
		font-size: var(--fs-xs);
		font-weight: 600;
		text-decoration: none;
		box-shadow: var(--shadow-sm);
		transition:
			transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
			border-color var(--dur-fast) var(--ease),
			background-color var(--dur-fast) var(--ease),
			color var(--dur-fast) var(--ease),
			box-shadow var(--dur-fast) var(--ease);
	}

	.header-github-btn:hover {
		border-color: var(--amber);
		color: var(--amber-hover);
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
		background: var(--bg-card-alt);
	}

	.header-github-btn:active {
		transform: scale(0.96);
	}

	.external-icon {
		font-size: 11px;
		color: var(--ink-3);
		transition: transform 0.2s ease, color 0.2s ease;
	}

	.header-github-btn:hover .external-icon {
		color: var(--amber-hover);
		transform: translate(1px, -1px);
	}

	@media (max-width: 860px) {
		.nav-links {
			display: none;
		}
	}
</style>
