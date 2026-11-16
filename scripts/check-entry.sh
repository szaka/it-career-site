#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: bash scripts/check-entry.sh PROJECT-ID POST-SLUG" >&2
  exit 2
fi

cd "$(dirname "$0")/.."
npm run build

python3 - "$1" "$2" <<'PY'
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit
from xml.etree import ElementTree as ET

project_id, post_slug = sys.argv[1:]
for slug in (project_id, post_slug):
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug):
        raise SystemExit(f"Invalid ID or slug: {slug}")

root = Path("dist").resolve()
site = "https://szaka.co"
project_url = f"/projects/{project_id}/"
post_url = f"/blog/{post_slug}/"
errors = []


class Page(HTMLParser):
    def __init__(self, file):
        super().__init__()
        self.links = []
        self.images = []
        self.ids = set()
        self.text = []
        self.feed(file.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get("id"):
            self.ids.add(attrs["id"])
        if tag == "a" and "href" in attrs:
            self.links.append(attrs["href"])
        if tag == "img":
            self.images.append(attrs)

    def handle_data(self, text):
        self.text.append(text)


def lookup(path):
    target = (root / unquote(path).lstrip("/")).resolve()
    if not target.is_relative_to(root):
        return None
    return next(
        (p for p in (target, target / "index.html") if p.is_file()),
        None,
    )


def load(url):
    file = lookup(url)
    if file is None:
        raise SystemExit(f"FAIL: missing generated page {url}")
    return Page(file)


def check(condition, message):
    if not condition:
        errors.append(message)


def check_reference(page_url, reference):
    url = urlsplit(urljoin(site + page_url, reference))
    if url.scheme not in {"http", "https"} or url.hostname != "szaka.co":
        return
    file = lookup(url.path)
    check(file is not None, f"{page_url}: missing {reference}")
    if file and url.fragment and file.suffix == ".html":
        check(
            unquote(url.fragment) in Page(file).ids,
            f"{page_url}: missing anchor {reference}",
        )


projects = load("/projects/")
blog = load("/blog/")
project = load(project_url)
post = load(post_url)

check(project_url in projects.links, "Projects index must link to the project.")
check(post_url in blog.links, "Blog index must link to the article.")
check("/projects/" in project.links, "Project needs a link back to Projects.")
check(post_url in project.links, "Project needs its related article link.")
check("/blog/" in post.links, "Article needs a link back to Blog.")
check(
    "How I verified it." in " ".join(project.text),
    "Project is missing the verification section.",
)

for url, page in ((project_url, project), (post_url, post)):
    check("min read" in " ".join(page.text), f"{url}: missing reading time")
    topics = {link for link in page.links if link.startswith("/topics/")}
    check(bool(topics), f"{url}: add at least one topic tag")
    for topic in topics:
        file = lookup(topic)
        check(file is not None, f"{url}: missing topic page {topic}")
        if file:
            check(url in Page(file).links, f"{topic}: missing backlink to {url}")
    for link in page.links:
        check_reference(url, link)
    for image in page.images:
        check("alt" in image, f"{url}: image needs an alt attribute")
        check(bool(image.get("src")), f"{url}: image needs a source")
        if image.get("src"):
            check_reference(url, image["src"])

try:
    items = ET.parse(root / "rss.xml").findall("./channel/item")
    feed_links = {item.findtext("link", "").rstrip("/") for item in items}
    check((site + post_url).rstrip("/") in feed_links, "Article is missing from RSS.")
except (OSError, ET.ParseError) as error:
    errors.append(f"Could not read RSS: {error}")

if errors:
    raise SystemExit("\n".join(f"FAIL: {error}" for error in errors))

print("PASS: project, article, topic backlinks, local assets, and RSS.")
PY
