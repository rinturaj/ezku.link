<script lang="ts">
	import { scrollReveal } from '$lib/actions/scrollAnimation';

	let openItem = $state<number | null>(0);

	const faqs = [
		{
			question: 'Do I need to install any app on my Smart TV?',
			answer: 'No. ezku.link connects directly to the native casting receiver already built into your television (Google Cast & DLNA). You never have to search for, download, or install any TV app.'
		},
		{
			question: 'Do I need VLC or any third-party video player to cast movies?',
			answer: 'No. Your TV plays videos directly in its native hardware media player. You do not need VLC, Plex, or any extra media players installed on your Mac.'
		},
		{
			question: 'Can I control playback with my physical TV remote?',
			answer: 'Yes. Play, pause, rewind, and seek work directly with your standard TV remote control from your couch.'
		},
		{
			question: 'Does this need an internet connection or cloud account?',
			answer: 'No. Streaming is 100% local over your home Wi-Fi network. It works offline with zero accounts, zero tracking, and complete privacy.'
		},
		{
			question: 'Does it stream audio along with the screen?',
			answer: 'Yes. ezku.link captures synchronized macOS system audio with zero delay, so movies, presentations, and music play crystal-clear audio through your TV speakers or soundbar.'
		},
		{
			question: 'Which video file formats can I cast directly?',
			answer: 'You can cast standard video files including .mp4, .mov, .m4v, and .mkv in up to 4K resolution. They stream directly to your TV without CPU-heavy transcoding.'
		},
		{
			question: 'Can viewers watch on mobile devices or PCs without an app?',
			answer: 'Yes. Click "Show QR Code" in the menu bar. Anyone on your local Wi-Fi can scan the code to watch the live stream in Safari, Chrome, or Edge without downloading an app.'
		},
		{
			question: 'Why does macOS say "cannot be opened because Apple cannot check it for malicious software"?',
			answer: 'ezku.link is a free and open-source utility that is not signed with an annual $99 Apple Developer certificate. On first launch of the direct .dmg download, macOS Gatekeeper blocks unidentified developers by default. To open it: Right-click (or Control-click) ezku.link.app in your Applications folder and select "Open", or go to System Settings → Privacy & Security and click "Open Anyway". Alternatively, installing via Homebrew automatically handles this.'
		}
	];

	function toggle(index: number) {
		openItem = openItem === index ? null : index;
	}
</script>

<section id="faq" class="faq-section section-spacing-sm" use:scrollReveal>
	<div class="page-container">
		<!-- Header -->
		<div class="faq-header-row">
			<div class="header-left">
				<span class="ui-badge is-accent">FAQ</span>
				<span class="ui-badge">COMMON QUESTIONS</span>
			</div>
			<div class="faq-corner-mark" aria-hidden="true">⌟</div>
		</div>

		<div class="faq-intro">
			<h2 class="h-2 faq-headline">
				Frequently Asked Questions
			</h2>
			<p class="text-lead faq-lead">
				Quick answers about Smart TV support, video formats, and controls.
			</p>
		</div>

		<!-- Accordion List -->
		<div class="faq-list">
			{#each faqs as item, index}
				<div class="ui-card faq-item-card" class:is-open={openItem === index}>
					<button
						type="button"
						class="faq-trigger"
						onclick={() => toggle(index)}
						aria-expanded={openItem === index}
					>
						<span class="faq-q-num text-mono">0{index + 1}</span>
						<span class="faq-question">{item.question}</span>
						<span class="faq-icon" aria-hidden="true">+</span>
					</button>
					<div class="faq-collapse" class:is-open={openItem === index}>
						<div class="faq-collapse-inner">
							<div class="faq-answer">
								<p>{item.answer}</p>
							</div>
						</div>
					</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<style>
	.faq-section {
		border-top: 1px solid var(--line);
		position: relative;
	}

	.faq-header-row {
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

	.faq-corner-mark {
		font-family: var(--mono);
		font-size: 22px;
		color: var(--amber);
		user-select: none;
		line-height: 1;
	}

	.faq-intro {
		margin-bottom: 28px;
	}

	.faq-headline {
		font-weight: 700;
	}

	.faq-lead {
		color: var(--ink-2);
		margin-top: 4px;
	}

	.faq-list {
		display: flex;
		flex-direction: column;
		gap: 12px;
		max-width: 860px;
	}

	.faq-item-card {
		padding: 0;
		overflow: hidden;
		transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1),
		            border-color 0.25s ease,
		            box-shadow 0.25s ease;
	}

	.faq-item-card:hover {
		transform: translateX(4px);
		border-color: var(--line-strong);
		box-shadow: var(--shadow-sm);
	}

	.faq-item-card.is-open {
		border-color: var(--amber);
		box-shadow: 0 4px 20px -4px rgba(245, 158, 11, 0.15);
	}

	.faq-trigger {
		width: 100%;
		display: flex;
		align-items: center;
		padding: 18px 22px;
		text-align: left;
		background: none;
		border: none;
		cursor: pointer;
		gap: 14px;
		transition: background-color 0.2s ease;
	}

	.faq-trigger:hover {
		background: var(--bg-card-alt);
	}

	.faq-q-num {
		font-size: 11px;
		font-weight: 700;
		color: var(--amber-hover);
		transition: transform 0.2s ease;
	}

	.faq-item-card:hover .faq-q-num {
		transform: scale(1.1);
	}

	.faq-question {
		flex: 1;
		font-size: 15.5px;
		font-weight: 600;
		color: var(--ink);
		letter-spacing: -0.015em;
		transition: color 0.2s ease;
	}

	.faq-trigger:hover .faq-question {
		color: var(--amber-hover);
	}

	.faq-icon {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 28px;
		height: 28px;
		border-radius: 50%;
		background: var(--bg-subtle);
		border: 1px solid var(--line);
		font-family: var(--mono);
		font-size: 16px;
		line-height: 1;
		color: var(--ink-2);
		user-select: none;
		transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1),
		            background-color 0.25s ease,
		            color 0.25s ease,
		            border-color 0.25s ease;
	}

	.faq-item-card.is-open .faq-icon {
		transform: rotate(45deg);
		background: var(--amber);
		color: #000000;
		border-color: var(--amber);
	}

	.faq-collapse {
		display: grid;
		grid-template-rows: 0fr;
		transition: grid-template-rows 0.35s cubic-bezier(0.16, 1, 0.3, 1),
		            opacity 0.25s ease;
		opacity: 0;
	}

	.faq-collapse.is-open {
		grid-template-rows: 1fr;
		opacity: 1;
	}

	.faq-collapse-inner {
		overflow: hidden;
	}

	.faq-answer {
		padding: 0 22px 18px 47px;
		font-size: var(--fs-xs);
		color: var(--ink-2);
		line-height: 1.6;
		border-top: 1px solid var(--line-subtle);
		padding-top: 14px;
	}

	@media (max-width: 768px) {
		.faq-answer {
			padding-left: 22px;
		}
	}
</style>
