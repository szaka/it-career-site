# Shahid Zaka — IT Support Portfolio

Hands-on IT support projects, troubleshooting notes, and lessons from my labs.

My experience includes home networks, Wi-Fi, servers, shared storage, and teaching basic computer classes at a Brooklyn nonprofit. This portfolio documents what I tried, what happened, and how I checked the result.

## Explore the site

- **Projects** — What I built and how I verified it.
- **Blog** — Problems I worked through and what I learned.
- **About** — My background, certification progress, and site resources.
- **Contact** — IT support opportunities and project questions.
- **Privacy** — Hosting, optional analytics, and browser preferences.

Blog and Projects include search, topic filters, and sorting. Entries show dates, reading times, and related topics.

## Run locally

Run these commands from the project folder.

Install dependencies when setting up the project:

```bash
npm ci
```

Start the local server:

```bash
npm run dev -- --port 4323
```

Open http://localhost:4323/ in your browser. Save edits to refresh the preview. Press **Control+C** in the server’s Terminal window to stop it.

Build and preview the production version:

```bash
npm run build
npm run preview -- --port 4324
```

Open http://localhost:4324/.

## Where to edit

| Content | File or folder |
| --- | --- |
| Blog posts | `src/content/blog/` |
| Blog content schema | `src/content.config.ts` |
| Projects and topic data | `src/data/topics.ts` |
| Home and selected work | `src/pages/index.astro` |
| About | `src/pages/about.astro` |
| Contact | `src/pages/contact.astro` |
| Privacy | `src/pages/privacy.astro` |
| Shared components | `src/components/` |
| Layouts | `src/layouts/` |
| Styles | `src/styles/` |
| Static files | `public/` |
| Pages CMS settings | `.pages.yml` |
| Deployment workflow | `.github/workflows/deploy.yml` |

Selected work is maintained in the Home page source. Update the title, link, summary, and matching content ID together when replacing a featured entry.

## Checks

Build the site before committing:

```bash
npm run build
```

Run the entry report for the existing portfolio project and related article:

```bash
bash scripts/report-entry.sh astro-portfolio setting-up-my-astro-blog
```

Also check the changed pages in a browser, open attachments, test links, and review the layout at a narrow width. Confirm that technical claims match the work performed.

## Pages CMS and local changes

Pages CMS saves content to the selected GitHub repository and branch. To bring those changes into a clean local working tree:

```bash
git fetch origin
git merge --ff-only origin/main
```

If Git reports diverging branches, review and combine the changes before continuing.

## Save and publish

Review local changes before staging and committing them:

```bash
git status --short
git diff
```

A local commit saves a checkpoint on your computer. When the outgoing work is ready to be public, confirm the remote and review the commits:

```bash
git remote -v
git fetch origin
git log --oneline origin/main..HEAD
```

Push the current branch to GitHub’s main branch:

```bash
git push origin HEAD:main
```

Deployment depends on the workflow configuration and whether it is enabled. Verify the intended commit in GitHub Actions, then check the published site.

## Tools and credits

Built with Astro and Markdown, edited through VS Code and Pages CMS, and deployed with GitHub Actions and GitHub Pages.

This project started from the Astro blog starter, whose styling was inspired by [Bear Blog](https://github.com/HermanMartinus/bearblog/). The About page lists additional tools and documentation used.

## Development assistance

ChatGPT assisted with site code, styling, documentation, and troubleshooting suggestions. I applied changes locally and ran builds and browser checks during development. This repository records the site’s development as I learn.
