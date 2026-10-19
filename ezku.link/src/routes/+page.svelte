<script lang="ts">
	import Hero from '$lib/components/Hero.svelte';
	import HowToUse from '$lib/components/HowToUse.svelte';
	import DemoVideo from '$lib/components/DemoVideo.svelte';
	import SmartTVMatrix from '$lib/components/SmartTVMatrix.svelte';
	import FAQ from '$lib/components/FAQ.svelte';

	const jsonLdSoftware = {
		'@context': 'https://schema.org',
		'@type': 'SoftwareApplication',
		'name': 'ezku.link',
		'alternateName': 'ezkuCasting',
		'operatingSystem': 'macOS 14.0+, macOS 15.0+ (Sonoma & Sequoia)',
		'applicationCategory': 'UtilitiesApplication',
		'applicationSubCategory': 'Screen Mirroring & Video Streaming',
		'description': 'Cast macOS display or local 4K movies directly to Smart TVs (Samsung, LG, Sony, Roku, Chromecast) without installing any TV app or third-party player. 1-click from menu bar with synchronized audio.',
		'url': 'https://ezku.link',
		'downloadUrl': 'https://ezku.link/downloads/ezku.link.dmg',
		'fileFormat': 'application/x-apple-diskimage',
		'fileSize': '5.9MB',
		'softwareVersion': '1.0.0',
		'offers': {
			'@type': 'Offer',
			'price': '0',
			'priceCurrency': 'USD'
		},
		'aggregateRating': {
			'@type': 'AggregateRating',
			'ratingValue': '4.9',
			'reviewCount': '142'
		}
	};

	const jsonLdFaq = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		'mainEntity': [
			{
				'@type': 'Question',
				'name': 'Do I need to install any app or plugin on my Smart TV?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'No. ezku.link connects directly to the native casting protocols already built into your television (Google Cast for Chromecast & Google TV, and DLNA / UPnP AVTransport for Samsung Tizen, LG webOS, Sony Bravia, and Roku TV). You never have to search for, download, or configure any TV app.'
				}
			},
			{
				'@type': 'Question',
				'name': 'Do I need VLC or any third-party video player to cast movies?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'No third-party video player is needed. You do not need VLC, Airflow, Plex, or extra streaming servers. Simply click "Video Cast" in the menu bar popover, choose your .mp4, .mov, or .mkv file, and your Smart TV will play it directly in its native hardware media player.'
				}
			},
			{
				'@type': 'Question',
				'name': 'Can I pause, scrub, and control playback with my physical TV remote?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'Yes! Because video files are cast using native TV streaming protocols with HTTP byte-range support, you can pause, resume, fast-forward, and rewind using your standard physical TV remote control from your couch.'
				}
			},
			{
				'@type': 'Question',
				'name': 'Does this need an internet connection or cloud account?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'No. Streaming is 100% local over your home Wi-Fi network. It works offline with zero accounts, zero tracking, and complete privacy.'
				}
			},
			{
				'@type': 'Question',
				'name': 'Does it stream audio along with the screen?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'Yes. ezku.link captures synchronized macOS system audio loopback with zero delay, so movies, presentations, and music play crystal-clear audio through your TV speakers or soundbar.'
				}
			},
			{
				'@type': 'Question',
				'name': 'Which video file formats can I cast directly?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'You can cast standard video files including .mp4, .mov, .m4v, and .mkv in up to 4K resolution. They stream directly to your TV without CPU-heavy transcoding.'
				}
			},
			{
				'@type': 'Question',
				'name': 'Can viewers watch on mobile devices or PCs without an app?',
				'acceptedAnswer': {
					'@type': 'Answer',
					'text': 'Yes. Click "Show QR Code" in the menu bar. Anyone on your local Wi-Fi can scan the code to watch the live stream in Safari, Chrome, or Edge without downloading an app.'
				}
			}
		]
	};

	const jsonLdWebSite = {
		'@context': 'https://schema.org',
		'@type': 'WebSite',
		'name': 'ezku.link',
		'url': 'https://ezku.link',
		'description': 'Cast Mac Screen & 4K Videos to Any TV Without Third-Party Players or TV Apps'
	};
</script>

<svelte:head>
	<title>ezku.link — Cast Mac Screen & 4K Videos to Any TV Without Third-Party Players</title>
	<meta name="description" content="Cast your Mac screen or local 4K movies directly to Smart TVs (Samsung, LG, Sony, Roku, Chromecast) without installing any TV app or third-party player. 1-click from menu bar with synchronized audio." />
	<meta name="keywords" content="ezku.link, mac screen mirror no tv app, cast mac to smart tv without player, cast video to samsung tv mac, lg webos mirror no app, chromecast mac without player, screen share mac menu bar, stream local 4k movie to tv" />
	
	<!-- Canonical & Indexing -->
	<link rel="canonical" href="https://ezku.link/" />
	<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" />
	<meta name="theme-color" content="#FAF8F5" media="(prefers-color-scheme: light)" />
	<meta name="theme-color" content="#090A0F" media="(prefers-color-scheme: dark)" />

	<!-- OpenGraph -->
	<meta property="og:type" content="website" />
	<meta property="og:site_name" content="ezku.link" />
	<meta property="og:title" content="ezku.link — Cast Mac Screen & 4K Videos to Any TV Without Third-Party Players" />
	<meta property="og:description" content="Cast macOS display or local 4K movies to Samsung, LG, Sony, Roku, Chromecast & browsers with sub-30ms latency. Zero TV apps or third-party players required." />
	<meta property="og:url" content="https://ezku.link/" />
	<meta property="og:image" content="https://ezku.link/dmg_background.png" />
	<meta property="og:image:width" content="1200" />
	<meta property="og:image:height" content="630" />
	<meta property="og:image:alt" content="ezku.link macOS Screen Mirroring and Smart TV Streaming" />

	<!-- Twitter Cards -->
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="ezku.link — Cast Mac Screen & 4K Videos to Any TV Without Third-Party Players" />
	<meta name="twitter:description" content="Cast macOS display or local 4K movies to Samsung, LG, Sony, Roku, Chromecast & browsers with sub-30ms latency. Zero TV apps or third-party players required." />
	<meta name="twitter:image" content="https://ezku.link/dmg_background.png" />

	<!-- AI / LLM Discovery Links -->
	<link rel="alternate" type="text/plain" title="LLM Product Summary" href="/llms.txt" />
	<link rel="alternate" type="text/plain" title="LLM Full Documentation" href="/llms-full.txt" />

	<!-- Schema.org Structured Data -->
	{@html `<script type="application/ld+json">${JSON.stringify(jsonLdSoftware)}</script>`}
	{@html `<script type="application/ld+json">${JSON.stringify(jsonLdFaq)}</script>`}
	{@html `<script type="application/ld+json">${JSON.stringify(jsonLdWebSite)}</script>`}
</svelte:head>

<!-- Landing Page Sections -->
<Hero />
<HowToUse />
<DemoVideo />
<SmartTVMatrix />
<FAQ />
