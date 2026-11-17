#!/usr/bin/env bash
# Put the binary of docker/scout-action where the action looks for it
# (dist/ directory of the action), before the action runs.
#
# The action downloads its binary from the GitHub API without authentication,
# this download is limited by runner IP and randomly fails with HTTP 403.
# Here it is downloaded with the workflow token (GH_TOKEN), the action then
# uses it. On failure nothing is left and the action downloads it itself.
#
# Usage: scout-binary.sh
# This script never fails.
set -uo pipefail

binary="docker-scout-action_linux_amd64"

if [ "${RUNNER_OS:-}" != "Linux" ] || [ "${RUNNER_ARCH:-}" != "X64" ]; then
  echo "Runner is not Linux X64, Docker Scout binary is left to the action"
  exit 0
fi

# Actions used by the job are downloaded in <runner work>/_actions/<owner>/<repo>/<ref>
base="$(dirname "${GITHUB_WORKSPACE:?}")/../_actions/docker/scout-action"
if [ ! -d "$base" ]; then
  echo "::warning::Docker Scout action not found, its binary is left to the action"
  exit 0
fi

for dir in "$base"/*/; do
  version=$(basename "$dir")
  if [ -f "${dir}dist/${binary}" ]; then
    echo "Docker Scout action ${version} binary already present"
    continue
  fi
  mkdir -p "${dir}dist"
  if gh release download "$version" --repo docker/scout-action --pattern "$binary" --dir "${dir}dist" --clobber; then
    chmod 755 "${dir}dist/${binary}"
    echo "Docker Scout action ${version} binary downloaded"
  else
    rm -f "${dir}dist/${binary}"
    echo "::warning::Docker Scout action ${version} binary not downloaded, the action will download it itself"
  fi
done

exit 0
