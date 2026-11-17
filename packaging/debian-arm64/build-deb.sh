#!/usr/bin/env bash
#
# Assembles the Debian ARM64 (.deb) package for the Z.ai ZCode CLI.
#
# The payload is the upstream-supported Node.js SEA single executable produced
# by `apps/zcode-cli/packages/cli/scripts/build-sea.mjs --target linux-arm64`
# (Node.js runtime, TUI, agent runtime, official plugins, bundled skills and
# native search tools are all embedded — no system Node.js required).
#
# Usage:
#   build-deb.sh --binary <path-to-zcode-linux-arm64> --version <x.y.z> \
#                [--revision <n>] [--arch arm64] [--out-dir <dir>] \
#                [--source-commit <sha>] [--maintainer "<Name> <email>"]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BINARY=""
VERSION=""
REVISION="1"
ARCH="arm64"
OUT_DIR="$REPO_ROOT/dist-deb"
SOURCE_COMMIT=""
MAINTAINER="Agono0 <Agono0@users.noreply.github.com>"

while [ $# -gt 0 ]; do
  case "$1" in
    --binary) BINARY="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --revision) REVISION="$2"; shift 2 ;;
    --arch) ARCH="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --source-commit) SOURCE_COMMIT="$2"; shift 2 ;;
    --maintainer) MAINTAINER="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BINARY" ] || { echo "Missing --binary" >&2; exit 2; }
[ -n "$VERSION" ] || { echo "Missing --version" >&2; exit 2; }
[ -f "$BINARY" ] || { echo "Binary not found: $BINARY" >&2; exit 2; }
[ -x "$BINARY" ] || chmod 755 "$BINARY"

# dpkg version sanity: upstream digits first, allowed characters only.
printf '%s' "$VERSION" | grep -Eq '^[0-9][A-Za-z0-9.+:~-]*$' || {
  echo "Invalid dpkg version: $VERSION" >&2; exit 2;
}
printf '%s' "$REVISION" | grep -Eq '^[A-Za-z0-9.+-~]+$' || {
  echo "Invalid Debian revision: $REVISION" >&2; exit 2;
}

# Anchor the output directory so later `cd`/relative paths cannot break it.
case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$PWD/$OUT_DIR" ;;
esac

DEB_VERSION="${VERSION}-${REVISION}"
PACKAGE="zcode-cli"
STAGE="$OUT_DIR/stage"

rm -rf "$STAGE"
mkdir -p \
  "$STAGE/DEBIAN" \
  "$STAGE/opt/zcode/bin" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/share/doc/$PACKAGE"

# --- payload -----------------------------------------------------------------
install -m 0755 "$BINARY" "$STAGE/opt/zcode/bin/zcode"
ln -s /opt/zcode/bin/zcode "$STAGE/usr/bin/zcode"

# --- docs --------------------------------------------------------------------
install -m 0644 "$SCRIPT_DIR/README.md" "$STAGE/usr/share/doc/$PACKAGE/README.Debian"

{
  cat "$REPO_ROOT/LICENSE"
  echo
  echo "ZCode CLI for Debian ARM64 packaging (workflow files in .github/workflows and"
  echo "packaging/debian-arm64) is distributed under the same Apache License 2.0."
} > "$STAGE/usr/share/doc/$PACKAGE/copyright"

THIRD_PARTY="$REPO_ROOT/apps/zcode-cli/packages/cli/dist/THIRD-PARTY-NOTICES.md"
if [ -f "$THIRD_PARTY" ]; then
  install -m 0644 "$THIRD_PARTY" "$STAGE/usr/share/doc/$PACKAGE/THIRD-PARTY-NOTICES.md"
fi

CHANGELOG="$STAGE/usr/share/doc/$PACKAGE/changelog"
{
  echo "$PACKAGE ($DEB_VERSION) stable; urgency=medium"
  echo
  echo "  * Z.ai ZCode CLI $VERSION, built from the official upstream source"
  if [ -n "$SOURCE_COMMIT" ]; then
    echo "    https://github.com/zai-org/ZCode (commit $SOURCE_COMMIT)"
  else
    echo "    https://github.com/zai-org/ZCode"
  fi
  echo "    Node.js SEA single executable for linux-arm64; CLI/TUI only."
  echo
  echo " -- $MAINTAINER  $(date -u -R)"
} > "$CHANGELOG"
gzip -9n "$CHANGELOG"

# --- control -----------------------------------------------------------------
INSTALLED_SIZE_KIB="$(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)"

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PACKAGE
Version: $DEB_VERSION
Architecture: $ARCH
Maintainer: $MAINTAINER
Installed-Size: $INSTALLED_SIZE_KIB
Depends: libc6 (>= 2.28), libstdc++6 (>= 12), libgcc-s1
Recommends: git
Suggests: ripgrep
Section: utils
Priority: optional
Homepage: https://zcode.z.ai/
Built-Using: nodejs (= 24.14.0, Node.js SEA single executable)
Description: Z.ai ZCode CLI — AI coding agent for the terminal (ARM64)
 ZCode is Z.ai's coding agent harness. This package installs the official
 upstream CLI (terminal UI + agent runtime; the desktop application is not
 included) as a self-contained Node.js SEA single executable for Linux
 ARM64 (aarch64).
 .
 Account login uses the official Z.ai OAuth device flow ("zcode login",
 "/login") with Coding Plan support; credentials are stored under
 ~/.zcode/ and encrypted with the upstream credential pipeline.
 .
 Upstream source: https://github.com/zai-org/ZCode
EOF

# --- build -------------------------------------------------------------------
mkdir -p "$OUT_DIR"
DEB_FILE="$OUT_DIR/${PACKAGE}_${DEB_VERSION}_${ARCH}.deb"
rm -f "$DEB_FILE"
dpkg-deb --build --root-owner-group -Zxz "$STAGE" "$DEB_FILE"

dpkg-deb --info "$DEB_FILE"
dpkg-deb --contents "$DEB_FILE" | head -20

# Record the bare file name so `sha256sum -c SHA256SUMS.txt` works wherever
# the package is downloaded, not just on the build machine.
sha256sum "$DEB_FILE" | sed "s|  $DEB_FILE\$|  $(basename "$DEB_FILE")|" > "$OUT_DIR/SHA256SUMS.txt"
rm -rf "$STAGE"

echo
echo "Built: $DEB_FILE"
cat "$OUT_DIR/SHA256SUMS.txt"
