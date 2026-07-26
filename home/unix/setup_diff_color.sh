#!/bin/sh
set -e

# ANSI color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "${CYAN}==========================================================${NC}"
echo "${CYAN}  Starting Lazygit & Difftastic Environment Setup for Unix${NC}"
echo "${CYAN}==========================================================${NC}"

# 1. Check if lazygit is in PATH
echo ""
echo "${CYAN}[1/3] Checking lazygit...${NC}"
if command -v lazygit >/dev/null 2>&1; then
    echo "${GREEN}✔ lazygit is already installed.${NC}"
else
    echo "${RED}✘ lazygit not found in PATH. Please install it first.${NC}"
    exit 1
fi

# 2. Check if difftastic (difft) is in PATH
echo ""
echo "${CYAN}[2/3] Checking difftastic...${NC}"
if command -v difft >/dev/null 2>&1; then
    echo "${GREEN}✔ difftastic (difft) is already installed.${NC}"
else
    echo "${RED}✘ difftastic (difft) not found in PATH. Please install it first.${NC}"
    exit 1
fi

# 3. Configuring lazygit
echo ""
echo "${CYAN}[3/3] Configuring lazygit to use difftastic as pager...${NC}"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
CONFIG_FILE="$CONFIG_DIR/config.yml"

# Ensure config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "Created directory: $CONFIG_DIR"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    # Create new file
    cat << 'EOF' > "$CONFIG_FILE"
git:
  pagers:
    - colorArg: always
      externalDiffCommand: difft --color always --override=*.mlua:lua --display inline --strip-cr on --parse-error-limit=1024
EOF
    echo "${GREEN}✔ Created a new config.yml with difftastic configuration.${NC}"
else
    # Config file exists, check if the actual command is already configured
    if grep -Eq '^[[:space:]]*externalDiffCommand:[[:space:]]*difft([[:space:]]|$)' "$CONFIG_FILE"; then
        echo "${GREEN}✔ Difftastic is already configured in lazygit config.yml.${NC}"
    else
        if grep -Eq '^[[:space:]]*(paging|pagers):' "$CONFIG_FILE"; then
            echo "${RED}✘ Existing lazygit paging configuration found without Difftastic. Update it manually to avoid duplicate YAML keys.${NC}" >&2
            exit 1
        fi

        DIFFT_COMMAND='difft --color always --override=*.mlua:lua --display inline --strip-cr on --parse-error-limit=1024'

        # Backup existing config
        cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
        echo "Created backup of existing config: config.yml.bak"
        
        # Inject or append
        if grep -q "^git:" "$CONFIG_FILE"; then
            # Inject right below git:
            if ! awk -v difft_command="$DIFFT_COMMAND" '
            /^git:/ {
                print
                print "  pagers:"
                print "    - colorArg: always"
                print "      externalDiffCommand: " difft_command
                next
            }
            { print }
            ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"; then
                rm -f "$CONFIG_FILE.tmp"
                echo "${RED}✘ Failed to update lazygit config.yml.${NC}" >&2
                exit 1
            fi
            if ! mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"; then
                rm -f "$CONFIG_FILE.tmp"
                echo "${RED}✘ Failed to replace lazygit config.yml.${NC}" >&2
                exit 1
            fi
            echo "${GREEN}✔ Successfully injected difftastic paging into your existing git section!${NC}"
        else
            # Append to end of file
            cat << EOF >> "$CONFIG_FILE"


git:
  pagers:
    - colorArg: always
      externalDiffCommand: $DIFFT_COMMAND
EOF
            echo "${GREEN}✔ Successfully appended difftastic configuration to config.yml!${NC}"
        fi
    fi
fi

echo ""
echo "${CYAN}==========================================================${NC}"
echo "${GREEN}  Setup process finished successfully!${NC}"
echo "${YELLOW}  Please restart your terminal/lazygit to apply changes.${NC}"
echo "${CYAN}==========================================================${NC}"
