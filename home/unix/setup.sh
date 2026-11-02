#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
MIN_NEOVIM_VERSION="0.12.0"
LEVEL="${1:-1}"
case "$LEVEL" in
	0|1|2) ;;
	*)
		printf 'usage: %s [0|1|2]\n' "${0##*/}" >&2
		exit 2
		;;
esac

if [ -n "${SUDO_USER:-}" ]; then
	TARGET_USER="$SUDO_USER"
else
	TARGET_USER="$(id -un)"
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
	printf 'error: user does not exist: %s\n' "$TARGET_USER" >&2
	exit 1
fi

if [ "$TARGET_USER" = "$(id -un)" ] && [ -n "${HOME:-}" ]; then
	TARGET_HOME="$HOME"
elif command -v getent >/dev/null 2>&1; then
	TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
elif command -v dscl >/dev/null 2>&1; then
	TARGET_HOME="$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
else
	TARGET_HOME=""
fi
if [ -z "$TARGET_HOME" ]; then
	printf 'error: could not determine home directory for %s\n' "$TARGET_USER" >&2
	exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
SOURCE_BASHRC="$SCRIPT_DIR/.bashrc"
SOURCE_VIMRC="$SCRIPT_DIR/.vimrc"
TARGET_BASHRC="$TARGET_HOME/.bashrc"
START_MARKER='# >>> AXIS private setup >>>'
END_MARKER='# <<< AXIS private setup <<<'
OS_NAME="$(uname -s)"

log() {
	printf '[setup.sh] %s\n' "$*"
}

run_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo env DEBIAN_FRONTEND="$DEBIAN_FRONTEND" "$@"
	fi
}

run_as_target() {
	if [ "$(id -un)" = "$TARGET_USER" ]; then
		"$@"
	else
		sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" PATH="$TARGET_HOME/.cargo/bin:$PATH" "$@"
	fi
}

detect_pkg_manager() {
	if command -v pacman >/dev/null 2>&1; then
		printf '%s\n' pacman
	elif command -v apt-get >/dev/null 2>&1; then
		printf '%s\n' apt
	elif command -v brew >/dev/null 2>&1; then
		printf '%s\n' brew
	elif [ -x /opt/homebrew/bin/brew ] \
		|| [ -x /usr/local/bin/brew ] \
		|| [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
		printf '%s\n' brew
	else
		printf '%s\n' "error: expected apt-get, pacman, or brew" >&2
		exit 1
	fi
}

install_packages() {
	manager="$1"
	shift
	case "$manager" in
		pacman)
			run_root pacman -S --needed --noconfirm "$@"
			;;
		apt)
			run_root apt-get install -y "$@"
			;;
		brew)
			run_as_target "$BREW_BIN" install "$@"
			;;
	esac
}

version_ge() {
	awk -v current="$1" -v minimum="$2" 'BEGIN {
		current_len = split(current, current_parts, ".")
		minimum_len = split(minimum, minimum_parts, ".")
		max_parts = current_len > minimum_len ? current_len : minimum_len
		for (i = 1; i <= max_parts; i++) {
			current_part = current_parts[i] + 0
			minimum_part = minimum_parts[i] + 0
			if (current_part > minimum_part) exit 0
			if (current_part < minimum_part) exit 1
		}
		exit 0
	}'
}

current_nvim_version() {
	command -v nvim >/dev/null 2>&1 || return 1
	nvim --version 2>/dev/null | awk 'NR == 1 { sub(/^v/, "", $2); print $2; exit }'
}

nvim_version_ge_min() {
	version="$(current_nvim_version || true)"
	[ -n "$version" ] && version_ge "$version" "$MIN_NEOVIM_VERSION"
}

apt_is_ubuntu() {
	[ -r /etc/os-release ] || return 1
	# shellcheck disable=SC1091
	. /etc/os-release
	[ "${ID:-}" = ubuntu ]
}

ensure_apt_neovim_repo() {
	candidate="$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
	stripped="${candidate#*:}"
	if [ -n "$stripped" ] && [ "$stripped" != "(none)" ] \
		&& dpkg --compare-versions "$stripped" ge "$MIN_NEOVIM_VERSION"; then
		return 0
	fi
	if ! apt_is_ubuntu; then
		log "error: distro Neovim ${candidate:-unknown} is below $MIN_NEOVIM_VERSION; use Nix or install a newer Neovim"
		exit 1
	fi
	if [ "${ALLOW_NEOVIM_PPA:-0}" != 1 ]; then
		log "error: distro Neovim ${candidate:-unknown} is below $MIN_NEOVIM_VERSION; rerun with ALLOW_NEOVIM_PPA=1 or use Nix"
		exit 1
	fi

	log "Adding ppa:neovim-ppa/unstable"
	run_root apt-get install -y software-properties-common
	run_root add-apt-repository ppa:neovim-ppa/unstable -y
	run_root apt-get update
	candidate="$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
	stripped="${candidate#*:}"
	if [ -z "$stripped" ] || [ "$stripped" = "(none)" ] \
		|| ! dpkg --compare-versions "$stripped" ge "$MIN_NEOVIM_VERSION"; then
		log "error: the Neovim PPA did not provide Neovim $MIN_NEOVIM_VERSION or newer"
		exit 1
	fi
}

require_supported_neovim() {
	version="$(current_nvim_version || true)"
	if [ -z "$version" ] || ! version_ge "$version" "$MIN_NEOVIM_VERSION"; then
		log "error: expected Neovim $MIN_NEOVIM_VERSION or newer, found ${version:-none}"
		exit 1
	fi
	log "Verified Neovim $version"
}

sync_managed_block() {
	target="$1"
	source="$2"
	tmp="$(mktemp "${target}.tmp.XXXXXX")"
	content="$(mktemp "${target}.content.XXXXXX")"

	if [ ! -f "$source" ]; then
		rm -f "$tmp" "$content"
		printf 'error: profile source not found: %s\n' "$source" >&2
		return 1
	fi

	if [ -f "$target" ]; then
		if ! awk -v start="$START_MARKER" -v end="$END_MARKER" '
			$0 == start {
				if (skip || seen_start) exit 1
				skip = 1
				seen_start = 1
				next
			}
			$0 == end {
				if (!skip) exit 1
				skip = 0
				next
			}
			!skip { print }
			END {
				if (skip) {
					exit 1
				}
			}
		' "$target" > "$content"; then
			rm -f "$tmp" "$content"
			printf 'error: unmatched managed profile marker in %s\n' "$target" >&2
			return 1
		fi
		cp -p "$target" "$tmp"
	else
		: > "$content"
		chmod 644 "$tmp"
	fi

	if [ -s "$content" ]; then
		printf '\n' >> "$content"
	fi
	{
		printf '%s\n' "$START_MARKER"
		cat "$source"
		printf '%s\n' "$END_MARKER"
	} >> "$content"

	cat "$content" > "$tmp"
	rm -f "$content"
	mv -f "$tmp" "$target"
}

link_config() {
	source="$1"
	target="$2"

	if [ -L "$target" ] && [ "$target" -ef "$source" ]; then
		return 0
	fi
	if [ -e "$target" ] || [ -L "$target" ]; then
		backup="${target}.bak-$(date +'%Y%m%d%H%M%S')"
		log "Moving existing path to $backup"
		run_as_target mv "$target" "$backup"
	fi
	run_as_target ln -s "$source" "$target"
}

ensure_rustup() {
	if run_as_target sh -c 'command -v rustup >/dev/null 2>&1'; then
		return 0
	fi

	log "Installing rustup via rustup.rs"
	rustup_script="$(mktemp)"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rustup_script"
	chmod a+r "$rustup_script"
	run_as_target sh "$rustup_script" -y
	rm -f "$rustup_script"
	export PATH="$TARGET_HOME/.cargo/bin:$PATH"
}

ensure_yazi() {
	if run_as_target sh -c 'command -v yazi >/dev/null 2>&1'; then
		return 0
	fi
	if ! run_as_target sh -c 'command -v cargo >/dev/null 2>&1'; then
		log "cargo is unavailable; skipping yazi install"
		return 0
	fi

	log "Installing yazi via cargo"
	run_as_target cargo install --locked yazi-fm
}

ensure_jujutsu() {
	if run_as_target sh -c 'command -v jj >/dev/null 2>&1'; then
		return
	fi
	if ! run_as_target sh -c 'command -v cargo >/dev/null 2>&1'; then
		log "error: cargo is required to install Jujutsu"
		exit 1
	fi

	log "Installing Jujutsu via cargo"
	run_as_target cargo install --locked jj-cli
}

manager="$(detect_pkg_manager)"
log "Using $manager"

if [ "$manager" = brew ]; then
	if command -v brew >/dev/null 2>&1; then
		BREW_BIN="$(command -v brew)"
	elif [ -x /opt/homebrew/bin/brew ]; then
		BREW_BIN=/opt/homebrew/bin/brew
	elif [ -x /usr/local/bin/brew ]; then
		BREW_BIN=/usr/local/bin/brew
	else
		BREW_BIN=/home/linuxbrew/.linuxbrew/bin/brew
	fi
	export PATH="$(dirname -- "$BREW_BIN"):$PATH"
fi

packages=()
INSTALL_JUJUTSU_WITH_CARGO=0
case "$manager" in
	pacman)
		packages+=(curl tar xz unzip wget vim busybox)
		if [ "$LEVEL" -ge 1 ]; then
			packages+=(git nodejs python python-pip docker docker-compose neovim tmux fzf fd ripgrep lazygit bat base-devel tree-sitter tree-sitter-cli)
		fi
		if [ "$LEVEL" -ge 2 ]; then
			packages+=(jujutsu yazi ruby cmake rustup)
		fi
		;;
	apt)
		packages+=(curl tar xz-utils unzip wget vim busybox)
		run_root apt-get update
		if [ "$LEVEL" -ge 1 ]; then
			packages+=(git nodejs npm python3 python3-pip python3-venv docker.io tmux fzf fd-find ripgrep bat build-essential locales fonts-noto-cjk)
			for compose_package in docker-compose-plugin docker-compose-v2 docker-compose; do
				if apt-cache show "$compose_package" >/dev/null 2>&1; then
					packages+=("$compose_package")
					break
				fi
			done
			if apt-cache show lazygit >/dev/null 2>&1; then
				packages+=(lazygit)
			else
				log "lazygit is unavailable from apt; install it separately"
			fi
			if nvim_version_ge_min; then
				log "Keeping existing Neovim $(current_nvim_version)"
			else
				ensure_apt_neovim_repo
				packages+=(neovim)
			fi
		fi
		if [ "$LEVEL" -ge 2 ]; then
			packages+=(ruby cmake cargo)
			if apt-cache show jujutsu >/dev/null 2>&1; then
				packages+=(jujutsu)
			else
				INSTALL_JUJUTSU_WITH_CARGO=1
			fi
		fi
		;;
	brew)
		packages+=(curl gnu-tar xz unzip wget vim)
		if [ "$LEVEL" -ge 1 ]; then
			packages+=(git node python docker docker-compose neovim tmux fzf fd ripgrep lazygit bat tree-sitter tree-sitter-cli)
		fi
		if [ "$LEVEL" -ge 2 ]; then
			packages+=(jj yazi ruby cmake rustup)
		fi
		;;
esac

install_packages "$manager" "${packages[@]}"

if [ "$manager" = apt ] && [ "$LEVEL" -ge 1 ]; then
	run_root locale-gen en_US.UTF-8 ko_KR.UTF-8 ja_JP.UTF-8
	if ! run_as_target sh -c 'command -v tree-sitter >/dev/null 2>&1 || test -x "$HOME/.local/bin/tree-sitter"'; then
		log "Installing tree-sitter-cli with npm for $TARGET_USER"
		run_as_target npm install --global --prefix "$TARGET_HOME/.local" tree-sitter-cli
	fi
fi

if [ "$manager" = brew ] && [ "$LEVEL" -ge 1 ] && [ "$OS_NAME" = Darwin ]; then
	run_as_target "$BREW_BIN" install --cask font-noto-sans-cjk
fi

if [ "$LEVEL" -ge 2 ]; then
	if [ "$manager" = apt ] && ! command -v rustup >/dev/null 2>&1; then
		ensure_rustup
	fi
	if [ "$INSTALL_JUJUTSU_WITH_CARGO" -eq 1 ]; then
		ensure_jujutsu
	fi
	ensure_yazi
fi

run_as_target mkdir -p "$TARGET_HOME/.config"
sync_managed_block "$TARGET_BASHRC" "$SOURCE_BASHRC"
link_config "$REPO_ROOT/config/nvim" "$TARGET_HOME/.config/nvim"
link_config "$SOURCE_VIMRC" "$TARGET_HOME/.vimrc"

# Access to a rootful Docker daemon is effectively root access; opt in explicitly.
if [ "$OS_NAME" = Linux ] && [ "$LEVEL" -ge 1 ] && [ "${ENABLE_DOCKER_GROUP:-0}" = 1 ]; then
	if ! getent group docker >/dev/null; then
		run_root groupadd docker
	fi
	run_root usermod -aG docker "$TARGET_USER"
fi

if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "$(id -un)" ]; then
	chown "$TARGET_USER" "$TARGET_BASHRC"
fi

if [ "$LEVEL" -ge 1 ]; then
	require_supported_neovim
fi

log "Updated shell and editor configuration for $TARGET_USER"