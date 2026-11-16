---
title: 'Fixing Astro links on GitHub Pages'
description: 'How I traced a broken blog link to the GitHub Pages base path and verified the fix in the generated HTML.'
pubDate: '2026-11-15'
---

I deployed my Astro portfolio as a GitHub Pages project site. The blog listing loaded under `/it-career-site/blog/`, but clicking a post sent the browser to `/blog/…` at the domain root.

## Check the generated HTML

I built the site and used `rg` (ripgrep) to extract the link for one post from the generated blog listing.

```sh
npm run build &&
rg -o 'href="[^"]*/blog/setting-up-my-astro-blog/?"' dist/blog/index.html
```

The first check showed `href="/blog/setting-up-my-astro-blog/"`. The missing `/it-career-site/` prefix explained why the browser left the project site.

## Build the link from Astro’s base path

In `src/pages/blog/index.astro`, I read the base path inside the frontmatter, then used it in the post link. I used the same approach in the shared header.

```astro
---
const base = import.meta.env.BASE_URL.replace(/\/$/, '');
---

<a href={`${base}/blog/${post.id}/`}>{post.data.title}</a>
```

The link sits inside the page’s existing `posts.map(...)` loop, where `post` is the current article.

## Verify the fix

I rebuilt and reran the same check. This time the output showed `href="/it-career-site/blog/setting-up-my-astro-blog/"`. After pushing, I opened the deployed blog listing and followed the link to the article.

[View the changes in commit `1096d83`](https://github.com/szaka/it-career-site/commit/1096d83).

<aside class="ai-note" aria-label="AI assistance">
  <p><strong>AI assistance.</strong> I used ChatGPT to suggest the base-path fix and help draft this write-up. I applied the change, ran the build, inspected the generated link, and tested it on GitHub Pages.</p>
</aside>
