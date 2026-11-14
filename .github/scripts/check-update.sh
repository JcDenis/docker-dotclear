#!/usr/bin/env bash
# Tell if a daily image (dev, testing) must be built.
#
# Usage: check-update.sh <canal> <image tag> <source revision> <force>
#
# The published image keeps in its labels the checksum of its Dotclear archive
# and the commit of this repository it was built from. Image is built if:
# - build is forced,
# - it is monday (weekly build for Alpine packages updates),
# - Dotclear archive or source revision has changed, or can not be compared.
#
# Writes "build" (true | false) and "checksum" to GITHUB_OUTPUT.
set -uo pipefail

canal="${1:?canal is required}"
tag="${2:?image tag is required}"
revision="${3:-}"
force="${4:-false}"
image="docker.io/jcpd/docker-dotclear:${tag}"
label_checksum='io.github.jcdenis.docker-dotclear.archive-checksum'
label_revision='org.opencontainers.image.revision'

release=$("$(dirname "$0")/dotclear-release.sh" "$canal")
version=$(echo "$release" | sed -n 's/^version=//p')
checksum=$(echo "$release" | sed -n 's/^md5=//p')

labels=$(skopeo inspect --override-os linux --override-arch amd64 "docker://${image}" 2> /dev/null | jq -c '.Labels // {}' 2> /dev/null || true)
[ -z "$labels" ] && labels='{}'
image_checksum=$(echo "$labels" | jq -r --arg k "$label_checksum" '.[$k] // ""')
image_revision=$(echo "$labels" | jq -r --arg k "$label_revision" '.[$k] // ""')

build=true
if [ "$force" = "true" ]; then
  reason='build is forced'
elif [ "${GITHUB_EVENT_NAME:-}" = "schedule" ] && [ "$(date -u +%u)" = "1" ]; then
  reason='weekly build'
elif [ -z "$checksum" ]; then
  reason='Dotclear release not found in versions.xml'
elif [ -z "$image_checksum" ] || [ -z "$image_revision" ]; then
  reason='published image has no build information'
elif [ "$checksum" != "$image_checksum" ]; then
  reason="Dotclear ${canal} release has changed (${version})"
elif [ "$revision" != "$image_revision" ]; then
  reason='sources of the image have changed'
else
  build=false
  reason="Dotclear ${canal} release (${version}) and sources of the image have not changed"
fi

if [ "$build" = "true" ]; then
  echo "Image ${tag} is built: ${reason}."
else
  echo "Image ${tag} is not built: ${reason}."
fi
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "build=${build}"
    echo "checksum=${checksum}"
  } >> "$GITHUB_OUTPUT"
fi
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  if [ "$build" = "true" ]; then
    echo "Image ${tag} is built: ${reason}." >> "$GITHUB_STEP_SUMMARY"
  else
    echo "Image ${tag} is not built: ${reason}." >> "$GITHUB_STEP_SUMMARY"
  fi
fi
