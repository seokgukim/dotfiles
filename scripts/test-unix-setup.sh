#!/usr/bin/env bash
# Exercise the installer without touching the host's packages or home directory.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.config/nvim"
printf 'keep me\n' > "$tmp/home/.config/nvim/original"
printf 'existing setting\n' > "$tmp/home/.bashrc"
chmod 600 "$tmp/home/.bashrc"
export HOME="$tmp/home" PATH="$tmp/bin:$PATH" TEST_LOG="$tmp/commands"
# This exercises the apt branch and uses Linux stat; pacman takes precedence.
if [ "$(uname -s)" != Linux ] || command -v pacman >/dev/null 2>&1; then
    echo 'Skipping: test requires Linux without pacman' >&2
    exit 77
fi
for name in apt-get locale-gen groupadd usermod; do
    printf '#!/bin/sh\nprintf "%%s\\n" "%s $*" >> "$TEST_LOG"\n' "$name" > "$tmp/bin/$name"
done
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/apt-cache"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/getent"
printf '#!/bin/sh\nexec "$@"\n' > "$tmp/bin/sudo"
printf '#!/bin/sh\necho "NVIM v0.12.0"\n' > "$tmp/bin/nvim"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/tree-sitter"
chmod +x "$tmp/bin/"*

bash "$root/home/unix/setup.sh" 1
[ -L "$HOME/.config/nvim" ]
[ "$(readlink "$HOME/.config/nvim")" = "$root/config/nvim" ]
[ "$(find "$HOME/.config" -path '*/nvim.bak-*/original' -type f | wc -l)" -eq 1 ]
grep -q 'existing setting' "$HOME/.bashrc"
[ "$(stat -c %a "$HOME/.bashrc")" = 600 ]
grep -q '^apt-get install -y .*docker.io' "$TEST_LOG"
grep -q '^apt-get install -y .*neovim' "$TEST_LOG" && { echo 'Existing Neovim should be retained' >&2; exit 1; }
! grep -q '^usermod ' "$TEST_LOG"

ENABLE_DOCKER_GROUP=1 bash "$root/home/unix/setup.sh" 1
grep -q '^usermod -aG docker ' "$TEST_LOG"
[ "$(grep -c '^# >>> AXIS private setup >>>$' "$HOME/.bashrc")" -eq 1 ]

printf 'keep this\n# >>> AXIS private setup >>>\n' > "$HOME/.bashrc"
cp "$HOME/.bashrc" "$tmp/expected-bashrc"
if bash "$root/home/unix/setup.sh" 0 > "$tmp/failure-output" 2>&1; then
    echo 'Malformed managed block unexpectedly accepted' >&2
    exit 1
fi
cmp "$tmp/expected-bashrc" "$HOME/.bashrc"
grep -q 'unmatched managed profile marker' "$tmp/failure-output"
echo 'Unix setup integration checks passed.'
