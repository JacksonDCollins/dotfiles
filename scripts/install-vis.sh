#!/usr/bin/env bash
# Build a pinned vis with retained buffers; leave the distribution package untouched.
set -euo pipefail
(( EUID != 0 )) || { echo 'Build vis as your regular user, not root.' >&2; exit 1; }
[[ $# == 0 || ( $# == 2 && $1 == --build-only && -n $2 ) ]] || {
    echo 'Usage: scripts/install-vis.sh [--build-only NEW_INSTALL_DIRECTORY]' >&2; exit 1;
}
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
revision=254329d9f4f1df1158397080d403f3f112918aff
sha256=1b7e08360d40bfd287c33acf87986f64a09f16105882350e35a1b83fb9e8614e
for tool in curl tar sha256sum patch make cc pkg-config; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 1; }
done
pkg-config --exists lua ncursesw tre || {
    echo 'The vis build needs Lua, ncursesw and TRE development files.' >&2; exit 1;
}
root="$HOME/.local/lib/vis-dotfiles"
if (( $# )); then
    prefix=$(realpath -m -- "$2")
    [[ ! -e $prefix && ! -L $prefix ]] || { echo "Install directory already exists: $prefix" >&2; exit 1; }
    mkdir -p -- "$prefix"
else
    mkdir -p -- "$root"
    prefix=$(mktemp -d "$root/build.XXXXXXXX")
fi
work=$(mktemp -d)
installed=false
link=''
trap 'rm -rf -- "$work"; [[ -z $link ]] || rm -f -- "$link"; $installed || rm -rf -- "$prefix"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 15 --max-time 120 \
    "https://github.com/martanne/vis/archive/$revision.tar.gz" -o "$work/source.tar.gz"
printf '%s  %s\n' "$sha256" "$work/source.tar.gz" | sha256sum --check --status
tar -xzf "$work/source.tar.gz" --no-same-owner -C "$work"
source_dir="$work/vis-$revision"
patch --batch --forward --fuzz=0 -d "$source_dir" -p1 < "$repo/packages/vis/retained-buffers.patch"
(
    cd "$source_dir"
    ./configure --prefix="$prefix" --enable-curses --enable-lua --enable-tre
    make -j2 VERSION=v0.9-501-g254329d9-buffers API=3234
    make DESTDIR="$work/stage" VERSION=v0.9-501-g254329d9-buffers API=3234 install
)
cp -a -- "$work/stage$prefix/." "$prefix/"
"$prefix/bin/vis" -v
installed=true
if (( $# == 0 )); then
    link="$root/.current.$$"
    ln -s -- "$prefix" "$link"
    mv -Tf -- "$link" "$root/current"
fi
printf 'Built vis with retained buffers: %s/bin/vis\n' "$prefix"
