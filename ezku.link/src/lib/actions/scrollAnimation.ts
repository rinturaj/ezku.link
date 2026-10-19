/**
 * Svelte action for scroll-driven animations
 * Adds the 'is-visible' class when the node enters viewport
 */
export function scrollReveal(node: HTMLElement, options: { threshold?: number; rootMargin?: string } = {}) {
	const { threshold = 0.15, rootMargin = '0px 0px -50px 0px' } = options;

	// Respect user prefers-reduced-motion
	if (typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
		node.classList.add('is-visible');
		return {
			destroy() {}
		};
	}

	const observer = new IntersectionObserver(
		(entries) => {
			entries.forEach((entry) => {
				if (entry.isIntersecting) {
					node.classList.add('is-visible');
					observer.unobserve(node);
				}
			});
		},
		{
			threshold,
			rootMargin
		}
	);

	observer.observe(node);

	return {
		destroy() {
			observer.disconnect();
		}
	};
}
