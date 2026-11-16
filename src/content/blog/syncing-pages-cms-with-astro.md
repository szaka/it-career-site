---
title: 'Why my Pages CMS edit didn’t show up in Astro'
description: 'How I traced a stale local preview to the difference between a GitHub commit and the files on my Mac.'
pubDate: '2026-11-15'
---

I edited an Astro post in Pages CMS and confirmed that the editor had saved my changes. When I refreshed the post on `localhost`, it still showed the old text.

## Check which copy the preview is reading

Pages CMS saved the edit to the repository on GitHub. The Astro dev server was reading a separate copy on my Mac. I left the server running and opened another Terminal tab in the project folder.

## Pull the change and retest

From the folder the Astro server was using, I ran:

```sh
git pull --ff-only
```

Git updated the local Markdown file. After I refreshed the article, the new paragraph appeared. If I have two copies of the site open, I now check the project folder and preview port first.

<aside class="ai-note" aria-label="AI assistance">
  <p><strong>AI assistance.</strong> I used ChatGPT to identify the sync step and help draft this article. I ran the pull and confirmed that the edit appeared in my local preview.</p>
</aside>
