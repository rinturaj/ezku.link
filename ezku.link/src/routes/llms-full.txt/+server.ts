import type { RequestHandler } from '@sveltejs/kit';
import { readFileSync } from 'fs';
import { resolve } from 'path';

export const prerender = true;

export const GET: RequestHandler = async () => {
	try {
		const content = readFileSync(resolve('static/llms-full.txt'), 'utf-8');
		return new Response(content, {
			headers: {
				'content-type': 'text/plain; charset=utf-8',
				'cache-control': 'public, max-age=3600'
			}
		});
	} catch (e) {
		return new Response('Not found', { status: 404 });
	}
};
