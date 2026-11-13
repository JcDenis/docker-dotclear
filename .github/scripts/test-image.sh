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
# Dotclear redirections do not keep a custom port, container must be on port 80
PORT=80
URL='http://127.0.0.1'

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
    echo "--- Response"
    curl -sS -i "${URL}$1" 2>&1 | head -n 30 || true
    echo "--- DEBUG database"
    docker exec "$NAME" sh -c '"$DC_DOCKER_PHP" -r "\$p=new PDO(\"sqlite:/var/www/dotclear/sqlite.db\"); foreach ([\"select blog_id,blog_url,blog_status from dc_blog\",\"select module,version from dc_version\",\"select setting_id,blog_id,setting_value from dc_setting where setting_id in (\\\"url_scan\\\",\\\"public_path\\\",\\\"themes_path\\\",\\\"public_url\\\")\"] as \$q) { foreach (\$p->query(\$q) as \$r) { echo implode(\" | \", array_unique(\$r)), PHP_EOL; } }"' 2>&1 | grep -v Deprecated | head -n 60 || true
    echo "--- Container logs"
    docker logs "$NAME" 2>&1 | grep -v Deprecated | tail -n 20 || true
    exit 1
  fi
}

function install {
  # Dotclear command line installation needs two runs (configuration, then database)
  for step in 1 2; do
    echo "Dotclear installation, step ${step}"
    # (installer prints only "1" in non interactive mode)
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

function login {
  # Log in to the administration: Dotclear upgrades its database and installs
  # the plugins of the image on the first administration page of a user.
  local jar auth code page
  jar=$(mktemp)
  auth=$(curl -sS -o /dev/null -L --max-redirs 5 -c "$jar" -w '%{url_effective}' "${URL}/admin/" || true)
  code=$(curl -sS -o /dev/null -L --max-redirs 5 -b "$jar" -c "$jar" -w '%{http_code}' \
    --data-urlencode 'user_id=tester' --data-urlencode 'user_pwd=Dotclear-test-1' "$auth" || true)
  page=$(curl -sS -o /dev/null -L --max-redirs 5 -b "$jar" -c "$jar" -w '%{http_code} %{url_effective}' "${URL}/admin/" || true)
  rm -f "$jar"
  echo "Login form: ${auth}"
  echo "Login => HTTP ${code}, administration => ${page}"
  if [ "$code" != "200" ] || [ "${page%% *}" != "200" ] || echo "$page" | grep -qi 'auth'; then
    echo "::error::Login to Dotclear administration failed"
    docker logs "$NAME" 2>&1 | tail -n 40 || true
    exit 1
  fi
}

function check_blog {
  expect_ok /admin/
  login
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
