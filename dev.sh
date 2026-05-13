#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ECOSYSTEM="$ROOT_DIR/ecosystem.config.js"
VALID_APPS="api merchant service website portal"

usage() {
  cat <<EOF
Usage: $0 {start|stop|delete|restart} [app]

Commands:
  start    [app]  Start all apps or a specific app
  stop     [app]  Stop + delete all apps or a specific app from PM2
  delete   [app]  Delete all apps or a specific app from PM2
  restart  [app]  Restart all apps or a specific app

Apps: $VALID_APPS

Examples:
  $0 start              # start all
  $0 start api          # start api only
  $0 stop merchant      # stop + delete merchant
  $0 delete             # delete all from PM2
  $0 restart            # restart all
  $0 restart api        # restart api only
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

CMD="${1:-}"
APP="${2:-}"

[ -z "$CMD" ] && usage

if [ -n "$APP" ]; then
  validate_app "$APP"
fi

case "$CMD" in
  start)
    if [ -z "$APP" ]; then
      pm2 start "$ECOSYSTEM"
    else
      pm2 start "$ECOSYSTEM" --only "$APP"
    fi
    pm2 save
    ;;

  stop)
    if [ -z "$APP" ]; then
      pm2 stop "$ECOSYSTEM"
      pm2 delete "$ECOSYSTEM"
    else
      pm2 stop "$APP"
      pm2 delete "$APP"
    fi
    pm2 save
    ;;

  delete)
    if [ -z "$APP" ]; then
      pm2 delete "$ECOSYSTEM"
    else
      pm2 delete "$APP"
    fi
    pm2 save
    ;;

  restart)
    if [ -z "$APP" ]; then
      pm2 restart "$ECOSYSTEM"
    else
      pm2 restart "$APP"
    fi
    ;;

  *)
    usage
    ;;
esac
