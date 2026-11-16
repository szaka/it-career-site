export function topicSlug(label: string) {
  return label.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

interface Project {
  id: string;
  title: string;
  tags: string[];
  summary: string;
  verification: string;
  verifiedDate?: string;
  fix?: string;
  lesson?: string;
  article?: { slug: string; label: string };
  evidence?: { url: string; label: string };
  ai?: string;
}

export const projectTopics: Project[] = [
  {
    id: 'astro-portfolio',
    verifiedDate: '2026-11-15',
    title: 'Deploying the Astro portfolio',
    tags: ['Troubleshooting', 'GitHub Pages'],
    summary: 'I set up an Astro portfolio and configured GitHub Actions to build and publish it from the main branch.',
    fix: 'The blog listing pointed to the domain root. On the GitHub Pages test address, the site was served under /it-career-site/, so I updated the links to use Astro’s configured base path.',
    verification: 'I checked the generated HTML after rebuilding, then opened the article from the deployed blog listing.',
    article: {
      slug: 'setting-up-my-astro-blog',
      label: 'Read the Astro link troubleshooting article',
    },
    evidence: {
      url: 'https://github.com/szaka/it-career-site/commit/1096d83',
      label: 'View the fix on GitHub',
    },
    ai: 'I used ChatGPT to draft the theme code and suggest the base-path fix. I applied the changes, built the site, and tested the deployed link.',
  },
  {
    id: 'browser-editing',
    verifiedDate: '2026-11-15',
    title: 'Setting up browser-based editing',
    tags: ['Troubleshooting', 'Pages CMS'],
    summary: 'I configured Pages CMS to edit Astro posts in a browser, with fields for the title, description, date, and body.',
    lesson: 'A Pages CMS save updates GitHub first. To see that edit in the local Astro preview, pull the commit into the folder the dev server is using.',
    verification: 'I pulled the updated post, refreshed the local preview, and checked that my edit appeared.',
    article: {
      slug: 'syncing-pages-cms-with-astro',
      label: 'Read the Pages CMS sync walkthrough',
    },
    ai: 'I used ChatGPT to draft the CMS configuration and help diagnose the stale preview. I saved the edit and verified it locally after pulling.',
  },
];

export function projectReadingBody(project: Project) {
  return [project.summary, project.fix, project.verification, project.lesson]
    .filter(Boolean)
    .join(' ');
}
