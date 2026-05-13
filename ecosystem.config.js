// Ports:
//   api      → 3001  (PORT env overrides to 3011 — 3001 taken by runner-api)
//   merchant → 3000  (Next.js)
//   service  → 3002  (configuration.yaml)
//   website  → 4000  (angular.json) — Node 10 (Angular 7, http_parser removed in Node 12+)
//   portal   → 4200  (angular.json) — Node 10 (Angular 7, same reason)

const NODE10 = '/Users/trandang/.nvm/versions/node/v10.16.0/bin/node'

module.exports = {
  apps: [
    {
      name: 'api',
      cwd: './api',
      script: './node_modules/.bin/ts-node-dev',
      args: '--respawn --transpile-only src/index.ts',
      watch: false,
      env: {
        NODE_ENV: 'development',
        PORT: 3011,
      },
    },
    {
      name: 'merchant',
      cwd: './merchant',
      script: './node_modules/.bin/next',
      args: 'dev',
      watch: false,
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
      },
    },
    {
      name: 'service',
      cwd: './service',
      script: './node_modules/.bin/gulp',
      watch: false,
      env: {
        NODE_ENV: 'development',
      },
    },
    {
      name: 'website',
      cwd: './website',
      script: './node_modules/.bin/ng',
      args: 'serve --host 0.0.0.0 --port 4000',
      interpreter: NODE10,
      watch: false,
      env: {
        NODE_ENV: 'development',
      },
    },
    {
      name: 'portal',
      cwd: './portal',
      script: './node_modules/.bin/ng',
      args: 'serve --host 0.0.0.0 --port 4200',
      interpreter: NODE10,
      watch: false,
      env: {
        NODE_ENV: 'development',
      },
    },
  ],
}
