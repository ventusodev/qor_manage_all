#!/usr/bin/env bash
# Deploys the sandbox branch of one or more submodules straight to the
# server's sandbox dist dirs (/var/www/dcr/sandbox/<app>) and reloads the
# matching *-sandbox PM2 process. Runs locally on this host — no git push,
# no SSH, no GitHub Actions. Separate from the repo-level "Deploy Sandbox"
# GitHub Actions workflow (each submodule's .github/workflows/deploy-sandbox.yml),
# which deploys via CI when the submodule's sandbox branch is pushed to GitHub.
#
# Only ever touches /var/www/dcr/sandbox/** — never /var/www/dcr/<app> (prod).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SANDBOX_ROOT="/var/www/dcr/sandbox"
VALID_APPS="api merchant portal service website"

NODE24="/home/ubuntu/.nvm/versions/node/v24.15.0/bin"
NODE10="/home/ubuntu/.nvm/versions/node/v10.24.1/bin"

usage() {
  cat <<EOF
Usage: $0 [app]

Deploys submodules whose current branch is "sandbox" into
$SANDBOX_ROOT/<app>, then reloads the <app>-sandbox PM2 process.

  $0            # deploy every app currently on the sandbox branch
  $0 api        # deploy only api (skipped if api's branch isn't sandbox)

Apps: $VALID_APPS
EOF
  exit 1
}

validate_app() {
  local app="$1"
  for a in $VALID_APPS; do
    [ "$a" = "$app" ] && return 0
  done
  echo "Unknown app: $app. Valid apps: $VALID_APPS"
  exit 1
}

check_branch() {
  local app="$1"
  local branch
  branch="$(git -C "$ROOT_DIR/$app" branch --show-current)"
  if [ "$branch" != "sandbox" ]; then
    echo "[$app] SKIP — current branch is '$branch', not 'sandbox'"
    return 1
  fi
  return 0
}

reload_pm2() {
  local name="$1"
  if pm2 describe "$name" >/dev/null 2>&1; then
    pm2 reload "$name"
  else
    echo "[$name] pm2 process not found — start it manually first:"
    echo "  pm2 start /var/www/dcr/ecosystem.config.js --only $name"
  fi
  pm2 save
}

deploy_api() {
  local app=api src="$ROOT_DIR/api" dest="$SANDBOX_ROOT/api"
  echo "[$app] npm run build"
  (cd "$src" && PATH="$NODE24:$PATH" npm run build)
  echo "[$app] syncing dist/ + prisma/"
  rsync -a --delete "$src/dist/" "$dest/dist/"
  rsync -a "$src/prisma/" "$dest/prisma/"
  cp "$src/package.json" "$src/package-lock.json" "$dest/"
  echo "[$app] npm install --production"
  (cd "$dest" && PATH="$NODE24:$PATH" npm install --production)
  echo "[$app] prisma migrate deploy"
  (cd "$dest" && PATH="$NODE24:$PATH" npx prisma migrate deploy)
  reload_pm2 api-sandbox
}

deploy_merchant() {
  local app=merchant src="$ROOT_DIR/merchant" dest="$SANDBOX_ROOT/merchant"
  echo "[$app] npm run build"
  (cd "$src" && PATH="$NODE24:$PATH" npm run build)
  echo "[$app] syncing .next/ + public/"
  rsync -a --delete "$src/.next/" "$dest/.next/"
  rsync -a --delete "$src/public/" "$dest/public/"
  cp "$src/package.json" "$src/package-lock.json" "$dest/"
  echo "[$app] npm install --production"
  (cd "$dest" && PATH="$NODE24:$PATH" npm install --production)
  reload_pm2 merchant-sandbox
}

deploy_portal() {
  local app=portal src="$ROOT_DIR/portal" dest="$SANDBOX_ROOT/portal"
  echo "[$app] using setting.sandbox.ts (env-specific, gitignored)"
  cp "$src/src/app/configs/setting.sandbox.ts" "$src/src/app/configs/setting.ts"
  echo "[$app] npm run build:ssr (Node 10)"
  (cd "$src" && PATH="$NODE10:$PATH" npm run build:ssr)
  echo "[$app] syncing dist/"
  rsync -a --delete "$src/dist/" "$dest/dist/"
  cp "$src/package.json" "$src/package-lock.json" "$dest/"
  echo "[$app] npm install --production (Node 10)"
  (cd "$dest" && PATH="$NODE10:$PATH" npm install --production)
  reload_pm2 portal-sandbox
}

deploy_website() {
  local app=website src="$ROOT_DIR/website" dest="$SANDBOX_ROOT/website"
  echo "[$app] using setting.sandbox.ts (env-specific, gitignored)"
  cp "$src/src/app/configs/setting.sandbox.ts" "$src/src/app/configs/setting.ts"
  echo "[$app] npm run build:ssr (Node 10)"
  (cd "$src" && PATH="$NODE10:$PATH" npm run build:ssr)
  echo "[$app] syncing dist/"
  rsync -a --delete "$src/dist/" "$dest/dist/"
  cp "$src/package.json" "$src/package-lock.json" "$dest/"
  echo "[$app] npm install --production (Node 10)"
  (cd "$dest" && PATH="$NODE10:$PATH" npm install --production)
  reload_pm2 website-sandbox
}

deploy_service() {
  local app=service src="$ROOT_DIR/service" dest="$SANDBOX_ROOT/service"
  echo "[$app] npx gulp build"
  (cd "$src" && PATH="$NODE24:$PATH" npx gulp build)
  echo "[$app] syncing build/"
  rsync -a --delete "$src/build/" "$dest/build/"
  cp "$src/package.json" "$src/package-lock.json" "$dest/"
  echo "[$app] npm install --production"
  (cd "$dest" && PATH="$NODE24:$PATH" npm install --production)
  reload_pm2 service-sandbox
}

APP="${1:-}"
[ -n "$APP" ] && validate_app "$APP"
APPS_TO_RUN="${APP:-$VALID_APPS}"

FAILED_APPS=""
for app in $APPS_TO_RUN; do
  if check_branch "$app"; then
    echo "=== Deploying $app ==="
    if (set -e; "deploy_$app"); then
      echo "=== $app done ==="
    else
      echo "=== $app FAILED — continuing with remaining apps ==="
      FAILED_APPS="$FAILED_APPS $app"
    fi
  fi
done

if [ -n "$FAILED_APPS" ]; then
  echo
  echo "Failed apps:$FAILED_APPS"
  exit 1
fi
