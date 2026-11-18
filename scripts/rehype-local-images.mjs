import { resolve, relative, isAbsolute } from 'node:path';
import sharp from 'sharp';

export default function localImages() {
  return async function transform(tree) {
    const publicRoot = resolve('public');
    async function visit(node) {
      if (node.type === 'element' && node.tagName === 'img') {
        const props = node.properties ??= {};
        props.loading ??= 'lazy';
        props.decoding ??= 'async';
        if (typeof props.src === 'string' && props.src.startsWith('/') && !props.src.startsWith('//')) {
          const path = resolve(publicRoot, '.' + decodeURIComponent(props.src.split(/[?#]/)[0]));
          const within = relative(publicRoot, path);
          if (within.startsWith('..') || isAbsolute(within)) throw new Error('Image path leaves public directory.');
          const metadata = await sharp(path).metadata();
          props.width ??= metadata.width;
          props.height ??= metadata.height;
        }
      }
      for (const child of node.children ?? []) await visit(child);
    }
    await visit(tree);
  };
}
