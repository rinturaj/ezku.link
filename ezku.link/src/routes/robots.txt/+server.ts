import type { RequestHandler } from '@sveltejs/kit';

export const prerender = true;

export const GET: RequestHandler = async () => {
	const robots = `User-agent: *
Allow: /

# LLM Documentation
Allow: /llms.txt
Allow: /llms-full.txt
Allow: /.well-known/llms.txt

Sitemap: https://ezku.link/sitemap.xml
`;

	return new Response(robots, {
		headers: {
			'content-type': 'text/plain; charset=utf-8',
			'cache-control': 'public, max-age=86400'
		}
	});
};
