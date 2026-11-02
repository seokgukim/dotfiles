# =============================================================================
# Bash Profile - seokgukim
# =============================================================================

export EDITOR="nvim"
export VISUAL="nvim"
export AGENT_WORKSPACE="$HOME/_agent"
export PYTHONUTF8=1

if [ -d "$HOME/.local/bin" ]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ]; then
	export PATH="$HOME/.cargo/bin:$PATH"
fi

# Ghost / Axis USB system
for shell_ghost in \
	"/media/KAWI" \
	"/media/$USER/KAWI" \
	"/run/media/$USER/KAWI" \
	"/media/AXIS" \
	"/media/$USER/AXIS" \
	"/run/media/$USER/AXIS" \
	"$HOME"
do
	export SHELL_GHOST="$shell_ghost"
	if [ -r "$SHELL_GHOST/scripts/sh/heart_env.sh" ]; then
		. "$SHELL_GHOST/scripts/sh/heart_env.sh"
		break
	fi
done

# Convenience aliases for distro-renamed tools.
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
	alias fd='fdfind'
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
	alias bat='batcat'
fi
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
	alias docker-compose='docker compose'
fi
