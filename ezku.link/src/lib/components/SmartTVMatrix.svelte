<script lang="ts">
	import { scrollReveal } from '$lib/actions/scrollAnimation';

	const tvList = [
		{
			brand: 'Samsung Smart TVs',
			platform: 'Tizen OS',
			badge: 'NO TV APP',
			desc: 'Plays directly via Samsung DLNA. Full remote control support.',
			icon: '📺'
		},
		{
			brand: 'LG OLED & NanoCell',
			platform: 'webOS',
			badge: 'NO TV APP',
			desc: 'Instant wireless streaming. Magic Remote pause and seek.',
			icon: '📺'
		},
		{
			brand: 'Chromecast & Google TV',
			platform: 'Google Cast',
			badge: 'NO TV APP',
			desc: 'Direct stream to Chromecast 4K, HD, and Google TV devices.',
			icon: '📡'
		},
		{
			brand: 'Sony Bravia',
			platform: 'Google TV / Android',
			badge: 'NO TV APP',
			desc: 'Auto-discovery on local Wi-Fi with synchronized sound.',
			icon: '📺'
		},
		{
			brand: 'Roku TV & Players',
			platform: 'Roku OS',
			badge: 'NO TV APP',
			desc: 'Supports TCL, Hisense, and standalone Roku streaming sticks.',
			icon: '📺'
		},
		{
			brand: 'Phones & Browsers',
			platform: 'iOS, Android & PC',
			badge: 'QR CODE',
			desc: 'Scan QR code to watch instantly in Safari, Chrome, or Edge.',
			icon: '📱'
		}
	];
</script>

<section id="smart-tvs" class="tv-section section-spacing-sm" use:scrollReveal>
	<div class="page-container">
		<!-- Section Header -->
		<div class="tv-header-row">
			<div class="header-left">
				<span class="ui-badge is-accent">COMPATIBILITY</span>
				<span class="ui-badge">NO APP STORE NEEDED</span>
			</div>
			<div class="tv-corner-mark" aria-hidden="true">⌟</div>
		</div>

		<div class="tv-intro">
			<h2 class="h-2 tv-headline">Works with Your TV</h2>
			<p class="text-lead tv-lead">
				Speaks native television protocols over local Wi-Fi. No TV apps to install.
			</p>
		</div>

		<!-- Clean Brand Cards Grid -->
		<div class="tv-grid">
			{#each tvList as item}
				<div class="ui-card tv-card">
					<div class="corner-bracket top-right"></div>
					<div class="corner-bracket bottom-left"></div>

					<div class="tv-card-top">
						<span class="tv-icon">{item.icon}</span>
						<span class="tv-badge">{item.badge}</span>
					</div>

					<h3 class="tv-brand-name">{item.brand}</h3>
					<div class="tv-platform text-mono">{item.platform}</div>
					<p class="tv-desc">{item.desc}</p>
				</div>
			{/each}
		</div>
	</div>
</section>

<style>
	.tv-section {
		border-top: 1px solid var(--line);
		position: relative;
	}

	.tv-header-row {
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

	.tv-corner-mark {
		font-family: var(--mono);
		font-size: 22px;
		color: var(--amber);
		user-select: none;
		line-height: 1;
	}

	.tv-intro {
		margin-bottom: 28px;
	}

	.tv-headline {
		font-weight: 700;
		letter-spacing: -0.025em;
	}

	.tv-lead {
		color: var(--ink-2);
		margin-top: 4px;
	}

	/* Grid */
	.tv-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 18px;
	}

	.tv-card {
		display: flex;
		flex-direction: column;
		border: 1px solid var(--line);
		background: var(--bg-card);
		padding: 20px;
		transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1),
		            border-color 0.25s ease,
		            box-shadow 0.25s ease;
		cursor: default;
	}

	.tv-card:hover {
		transform: translateY(-5px) scale(1.02);
		border-color: var(--amber);
		box-shadow: 0 14px 32px -6px rgba(245, 158, 11, 0.18);
	}

	.tv-card-top {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 12px;
	}

	.tv-icon {
		font-size: 24px;
		line-height: 1;
		display: inline-block;
		transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
	}

	.tv-card:hover .tv-icon {
		transform: scale(1.25) rotate(-6deg);
	}

	.tv-badge {
		font-family: var(--mono);
		font-size: 9px;
		padding: 2px 6px;
		border-radius: var(--r-xs);
		background: var(--live-green-bg);
		color: var(--live-green);
		border: 1px solid rgba(16, 185, 129, 0.3);
		font-weight: 600;
		transition: transform 0.2s ease, background-color 0.2s ease, box-shadow 0.2s ease;
	}

	.tv-card:hover .tv-badge {
		transform: scale(1.05);
		background: var(--live-green);
		color: #000;
		box-shadow: 0 0 10px rgba(16, 185, 129, 0.4);
	}

	.tv-brand-name {
		font-size: 16px;
		font-weight: 700;
		color: var(--ink);
		letter-spacing: -0.015em;
		margin-bottom: 2px;
	}

	.tv-platform {
		font-size: 10.5px;
		color: var(--amber-deep);
		background: var(--amber-bg);
		padding: 1px 5px;
		border-radius: 3px;
		width: fit-content;
		margin-bottom: 8px;
		font-family: var(--mono);
	}

	.tv-desc {
		font-size: var(--fs-xs);
		color: var(--ink-2);
		line-height: 1.5;
	}

	@media (max-width: 960px) {
		.tv-grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}

	@media (max-width: 640px) {
		.tv-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
