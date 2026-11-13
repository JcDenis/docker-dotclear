#!/usr/bin/env bash
# Read a Dotclear release from versions.xml of Dotclear.
#
# Usage: dotclear-release.sh <canal>   (stable | testing | unstable)
# Prints three lines: version=, url= and md5= of the release archive.
# Values are empty if the release is not found or if they look wrong.
set -uo pipefail

canal="${1:?canal is required}"
file=$(mktemp)

curl -fsSL --retry 3 -o "$file" https://download.dotclear.org/versions.xml || true

# If several releases of the canal are listed, the highest version is used
function attribute {
  python3 -c '
import re, sys, xml.etree.ElementTree as ET
releases = [r for r in ET.parse(sys.argv[1]).getroot().iter("release") if r.get("name") == sys.argv[2]]
releases.sort(key=lambda r: [int(n) for n in re.findall("[0-9]+", r.get("version", ""))])
print(releases[-1].get(sys.argv[3], "") if releases else "")
' "$file" "$canal" "$1" 2> /dev/null || true
}

version=$(attribute version)
url=$(attribute href)
md5=$(attribute checksum)
rm -f "$file"

# Values are used in shell scripts and in the Dockerfile, check them
if ! echo "$version" | grep -Eq '^[A-Za-z0-9._-]+$'; then
  version=''
fi
if ! echo "$url" | grep -Eq '^https?://download\.dotclear\.org/[A-Za-z0-9._/-]+\.zip$' || ! echo "$md5" | grep -Eq '^[0-9a-f]{32}$'; then
  url=''
  md5=''
fi

echo "version=${version}"
echo "url=${url}"
echo "md5=${md5}"
