#!/usr/bin/env bash
# Build the latest stable nnn release without replacing the distribution package.
set -euo pipefail
(( EUID != 0 )) || { echo 'Build nnn as your regular user, not root.' >&2; exit 1; }
[[ $# == 0 || ( $# == 2 && $1 == --build-only && -n $2 ) ]] || {
    echo 'Usage: install-nnn.sh [--build-only OUTPUT_DIRECTORY]' >&2; exit 1;
}
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
output="$HOME/.local/bin/nnn-dotfiles"
if (( $# )); then output="$2/nnn-dotfiles"; fi
[[ $output == /* ]] || output="$PWD/$output"
[[ ! -L $output ]] || { echo "Refusing to replace a symlink: $output" >&2; exit 1; }
for tool in curl tar gpg awk patch make cc pkg-config; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 1; }
done
pkg-config --exists ncursesw readline || {
    echo 'The nnn build needs ncursesw and readline development files.' >&2; exit 1;
}
work=$(mktemp -d)
pending=''
trap 'rm -rf -- "$work"; [[ -z $pending ]] || rm -f -- "$pending"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
fetch=(curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https'
    --connect-timeout 15 --max-time 120)
release_url=$("${fetch[@]}" --head --output /dev/null --write-out '%{url_effective}' \
    https://github.com/jarun/nnn/releases/latest)
[[ $release_url =~ ^https://github\.com/jarun/nnn/releases/tag/v([0-9]+(\.[0-9]+)*)$ ]] || {
    echo "Unsupported latest-release URL: $release_url" >&2; exit 1;
}
version=${BASH_REMATCH[1]}
printf 'Latest stable nnn release: %s\n' "$version"
release="https://github.com/jarun/nnn/releases/download/v$version"
"${fetch[@]}" --output "$work/source.tar.gz" "$release/nnn-v$version.tar.gz"
"${fetch[@]}" --output "$work/source.sig" "$release/nnn-$version.tar.gz.sig"

# Trust a reviewed signing identity, not a fixed version or a freshly fetched checksum.
mkdir -m 700 "$work/gnupg"
gpg_command=(gpg --batch --no-options --no-autostart --no-auto-key-retrieve --homedir "$work/gnupg")
signer=E0B84447CD884CBB13E3266E4A865183AF6C5631
key="$work/release-key.asc"
"${fetch[@]}" --output "$key" "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x$signer"
fingerprint=$("${gpg_command[@]}" --with-colons --show-keys "$key" |
    awk -F: '$1 == "pub" { primary = 1 } primary && $1 == "fpr" { print $10; primary = 0 }')
[[ $fingerprint == "$signer" ]] || {
    echo 'Unexpected nnn release signing key; review the key before building.' >&2; exit 1;
}
"${gpg_command[@]}" --import "$key"
"${gpg_command[@]}" --verify "$work/source.sig" "$work/source.tar.gz"
tar -xzf "$work/source.tar.gz" --no-same-owner -C "$work"
source_dir="$work/nnn-$version"
patch --batch --forward --fuzz=0 -d "$source_dir" -p1 < "$repo/packages/nnn/plain-o.patch"
make -C "$source_dir" O_NORL=0
# Upstream -K reports collisions on stderr but still exits successfully.
if ! NNN_OPTS='' "$source_dir/nnn" -K > "$work/key-check.log" 2>&1 || [[ -s $work/key-check.log ]]; then
    cat "$work/key-check.log" >&2
    echo 'nnn key collision check failed.' >&2
    exit 1
fi
mkdir -p -- "$(dirname -- "$output")"
pending=$(mktemp "$(dirname -- "$output")/.nnn-dotfiles.XXXXXX")
install -m 0755 -- "$source_dir/nnn" "$pending"
mv -fT -- "$pending" "$output"
printf 'Built nnn %s with plain-o application picker: %s\n' "$version" "$output"
