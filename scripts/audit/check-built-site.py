from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit
from xml.etree import ElementTree as ET

root = Path('dist').resolve()
errors = []
class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.ids, self.refs = set(), []
        self.feed(path.read_text())
    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if attrs.get('id'):
            if attrs['id'] in self.ids:
                errors.append(f'Duplicate ID {attrs["id"]}')
            self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if attrs.get(key):
                self.refs.append(attrs[key])
        if tag == 'img' and ('alt' not in attrs or not attrs.get('width') or not attrs.get('height')):
            errors.append(f'Image requires alt and dimensions: {attrs.get("src")}')
        if tag == 'a' and attrs.get('href', '').startswith(('javascript:', 'http://')):
            errors.append(f'Unsafe/insecure link: {attrs["href"]}')

pages = {path: Page(path) for path in root.rglob('*.html')}
for path, page in pages.items():
    route = '/' + path.relative_to(root).as_posix()
    for ref in page.refs:
        url = urlsplit(urljoin('https://szaka.co' + route, ref))
        if url.scheme != 'https' or url.netloc != 'szaka.co':
            continue
        target = (root / unquote(url.path).lstrip('/')).resolve()
        if not target.is_relative_to(root):
            errors.append(f'{route}: path leaves build directory {ref}')
            continue
        if target.is_dir():
            target /= 'index.html'
        if not target.is_file():
            errors.append(f'{route}: missing {ref}')
        elif url.fragment and target.suffix == '.html':
            destination = pages.get(target)
            if destination and unquote(url.fragment) not in destination.ids:
                errors.append(f'{route}: missing fragment {ref}')
for filename in ('rss.xml', 'sitemap-index.xml'):
    try:
        ET.parse(root / filename)
    except (OSError, ET.ParseError) as error:
        errors.append(str(error))
if errors:
    raise SystemExit('\n'.join('FAIL ' + error for error in errors))
print(f'PASS references, image attributes, duplicate IDs, RSS and sitemap across {len(pages)} pages.')
