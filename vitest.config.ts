import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const sysprose = resolve(here, '../../sysprose');
const alias = (name: string) => ({ find: new RegExp(`^@${name}/`), replacement: `${sysprose}/src/${name}/` });

export default defineConfig({
  resolve: {
    alias: [
      { find: /^@sysprose\//, replacement: `${sysprose}/` },
      ...['core', 'text', 'api', 'validation', 'persistence', 'diagram', 'ui', 'semantics', 'library', 'collab', 'interop', 'server'].map(alias),
    ],
  },
  test: {
    environment: 'node',
    // One Sysprose/node process at a time on this host: parallel model loads
    // swap-thrash the disk. Serial files, serial tests.
    fileParallelism: false,
    pool: 'forks',
    testTimeout: 180_000,
    hookTimeout: 180_000,
    include: ['test/unit/**/*.test.ts', 'test/integration/**/*.test.ts'],
  },
});
