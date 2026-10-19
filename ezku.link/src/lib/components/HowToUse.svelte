<script lang="ts">
	import { scrollReveal } from '$lib/actions/scrollAnimation';

	const steps = [
		{
			step: '01',
			title: 'Click Menu Bar',
			tag: '1-CLICK',
			description: 'Lives quietly in your top bar. No heavy windows or dock icons—always one click away.',
			icon: ''
		},
		{
			step: '02',
			title: 'Choose Screen or Video',
			tag: 'SCREEN & MOVIES',
			description: 'Mirror your full display or app window, or choose any local .mp4, .mov, or .mkv file.',
			icon: '🎛'
		},
		{
			step: '03',
			title: 'Stream to Any TV',
			tag: 'ZERO TV APPS',
			description: 'Streams directly to your TV\'s native player. Pause and seek with your physical TV remote.',
			icon: '📺'
		}
	];
</script>

<section id="how-to-use" class="how-section section-spacing-sm" use:scrollReveal>
	<div class="page-container">
		<!-- Section Header -->
		<div class="how-header-row">
			<div class="header-left">
				<span class="ui-badge is-accent">HOW TO USE</span>
				<span class="ui-badge">3 SIMPLE STEPS</span>
			</div>
			<div class="how-corner-mark" aria-hidden="true">⌟</div>
		</div>

		<div class="how-intro">
			<h2 class="h-2 how-headline">How It Works</h2>
			<p class="text-lead how-lead">
				Zero setup. No TV apps to install and no third-party media players.
			</p>
		</div>

		<!-- Step Cards Grid -->
		<div class="steps-grid">
			{#each steps as s}
				<div class="ui-card step-card">
					<div class="corner-bracket top-right"></div>
					<div class="corner-bracket bottom-left"></div>

					<div class="step-card-header">
						<span class="step-number text-mono">STEP {s.step}</span>
						<span class="step-tag">{s.tag}</span>
					</div>

					<div class="step-icon">{s.icon}</div>
					<h3 class="step-title">{s.title}</h3>
					<p class="step-desc">{s.description}</p>
				</div>
			{/each}
		</div>
	</div>
</section>

<style>
	.how-section {
		border-top: 1px solid var(--line);
		position: relative;
	}

	.how-header-row {
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

	.how-corner-mark {
		font-family: var(--mono);
		font-size: 22px;
		color: var(--amber);
		user-select: none;
		line-height: 1;
	}

	.how-intro {
		margin-bottom: 28px;
	}

	.how-headline {
		font-weight: 700;
		letter-spacing: -0.025em;
	}

	.how-lead {
		color: var(--ink-2);
		margin-top: 4px;
	}

	/* Steps Grid */
	.steps-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 20px;
	}

	.step-card {
		display: flex;
		flex-direction: column;
		border: 1px solid var(--line);
		background: var(--bg-card);
		padding: 24px;
		transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1),
		            border-color 0.25s ease,
		            box-shadow 0.25s ease;
		cursor: default;
	}

	.step-card:hover {
		transform: translateY(-6px) scale(1.015);
		border-color: var(--amber);
		box-shadow: 0 16px 36px -8px rgba(245, 158, 11, 0.22), var(--shadow-md);
	}

	.step-card-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: 14px;
	}

	.step-number {
		font-size: 12px;
		font-weight: 700;
		color: var(--amber-hover);
		transition: color 0.2s ease, transform 0.2s ease;
		display: inline-block;
	}

	.step-card:hover .step-number {
		color: var(--amber);
		transform: scale(1.08);
	}

	.step-tag {
		font-family: var(--mono);
		font-size: 9.5px;
		padding: 2px 6px;
		border-radius: var(--r-xs);
		background: var(--amber-bg);
		color: var(--amber-deep);
		border: 1px solid var(--amber-border);
		font-weight: 600;
		transition: transform 0.2s ease, background-color 0.2s ease;
	}

	.step-card:hover .step-tag {
		transform: scale(1.06);
		background: var(--amber);
		color: #000;
	}

	.step-icon {
		font-size: 28px;
		margin-bottom: 10px;
		line-height: 1;
		display: inline-block;
		transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
	}

	.step-card:hover .step-icon {
		transform: translateY(-5px) scale(1.2) rotate(4deg);
	}

	.step-title {
		font-size: 18px;
		font-weight: 700;
		color: var(--ink);
		letter-spacing: -0.015em;
		margin-bottom: 8px;
		transition: color 0.2s ease;
	}

	.step-card:hover .step-title {
		color: var(--amber-hover);
	}

	.step-desc {
		font-size: var(--fs-xs);
		color: var(--ink-2);
		line-height: 1.55;
	}

	@media (max-width: 768px) {
		.steps-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
