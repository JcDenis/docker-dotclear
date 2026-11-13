#!/usr/bin/env bash
# Test a docker-dotclear image before it is published.
#
# Usage: test-image.sh <image> [previous image]
#
# 1. Fresh start: the image starts on an empty volume and web server answers.
# 2. Upgrade: Dotclear is installed (SQLite, command line) with the previous
#    image, then the image is started on the same volume and must serve the
#    blog and its administration. If the previous image is not given or not
#    available, Dotclear is installed with the tested image.
#
# Writes dotclear, alpine, nginx and php versions of the image to GITHUB_OUTPUT.
set -euo pipefail

IMAGE="${1:?image is required}"
PREVIOUS="${2:-}"
NAME='dotclear-test'
VOLUME='dotclear-test'
PORT=8080
URL="http://127.0.0.1:${PORT}"

function clean {
  docker rm -f "$NAME" > /dev/null 2>&1 || true
}

function start {
  # $1 = image, $2 = "volume" to use the test volume
  clean
  if [ "${2:-}" = "volume" ]; then
    docker run -d --name "$NAME" -p "${PORT}:80" -v "${VOLUME}:/var/www/dotclear" "$1" > /dev/null
  else
    docker run -d --name "$NAME" -p "${PORT}:80" "$1" > /dev/null
  fi
  local status=''
  for _ in $(seq 1 60); do
    status=$(docker inspect --format '{{.State.Health.Status}}' "$NAME")
    [ "$status" = "healthy" ] && break
    if [ "$(docker inspect --format '{{.State.Running}}' "$NAME")" != "true" ]; then
      break
    fi
    sleep 5
  done
  if [ "$status" != "healthy" ]; then
    echo "::error::Container of image $1 is not healthy (${status})"
    docker logs "$NAME" || true
    exit 1
  fi
  echo "Container of image $1 is healthy"
}

function stop {
  echo "::group::Container logs"
  docker logs "$NAME" 2>&1 || true
  echo "::endgroup::"
  clean
}

function http_code {
  # $1 = path, follows redirections
  curl -sS -o /dev/null -L --max-redirs 5 -w '%{http_code}' "${URL}$1" || true
}

function expect_ok {
  # $1 = path
  local code
  code=$(http_code "$1")
  echo "GET $1 => HTTP ${code}"
  if [ "$code" != "200" ]; then
    echo "::error::Unexpected HTTP code ${code} for $1"
    docker logs "$NAME" 2>&1 | tail -n 40 || true
    exit 1
  fi
}

function install {
  # Dotclear command line installation needs two runs (configuration, then database)
  for step in 1 2; do
    echo "Dotclear installation, step ${step}"
    docker exec -u www -w /var/www/dotclear/app "$NAME" sh -c "\"\$DC_DOCKER_PHP\" admin/install/index.php -n \
      --dbdriver=pdosqlite \
      --dbname=/var/www/dotclear/sqlite.db \
      --adminemail=test@example.com \
      --uemail=test@example.com \
      --ulogin=tester \
      --upassword=Dotclear-test-1 \
      --adminurl=${URL}/admin/ \
      --blogurl=${URL}/default \
      --urlscan=path_info"
  done
}

function check_blog {
  expect_ok /admin/
  expect_ok /default/
}

docker volume rm -f "$VOLUME" > /dev/null 2>&1 || true

echo "::group::Fresh start of ${IMAGE}"
start "$IMAGE"
code=$(curl -sS -o /dev/null -w '%{http_code}' "${URL}/" || true)
echo "GET / => HTTP ${code}"
if [ -z "$code" ] || [ "$code" = "000" ] || [ "$code" -ge 500 ]; then
  echo "::error::Unexpected HTTP code ${code} on fresh start"
  exit 1
fi
echo "::endgroup::"
stop

if [ -n "$PREVIOUS" ] && docker pull -q "$PREVIOUS" > /dev/null 2>&1; then
  echo "::group::Dotclear installation with previous image ${PREVIOUS}"
  start "$PREVIOUS" volume
  install
  check_blog
  echo "::endgroup::"
  stop
  echo "::group::Upgrade to ${IMAGE}"
  start "$IMAGE" volume
else
  echo "::group::Dotclear installation with ${IMAGE} (no previous image)"
  start "$IMAGE" volume
  install
fi
check_blog
echo "::endgroup::"

logs=$(docker logs "$NAME" 2>&1 || true)
function summary {
  echo "$logs" | sed -n "s/.*◦ $1 \(.*\)$/\1/p" | tail -n 1
}
dotclear=$(summary Dotclear)
alpine=$(summary Alpine)
nginx=$(summary Nginx)
php=$(summary PHP)
echo "Image ${IMAGE}: Dotclear ${dotclear}, Alpine ${alpine}, Nginx ${nginx}, PHP ${php}"
if [ -z "$dotclear" ]; then
  echo "::error::Dotclear version not found in container logs"
  exit 1
fi
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "dotclear=${dotclear}"
    echo "alpine=${alpine}"
    echo "nginx=${nginx}"
    echo "php=${php}"
  } >> "$GITHUB_OUTPUT"
fi

stop
docker volume rm -f "$VOLUME" > /dev/null 2>&1 || true
echo "Image ${IMAGE} passed the tests"
