#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
image="${DOTFILES_TEST_IMAGE:-dotfiles-headless-test}"
docker build -f docker/Dockerfile.headless -t "$image" .
docker run --rm --network none "$image" tree-sitter --version
docker run --rm --network none "$image" nvim --headless \
  '+lua local ok, err = pcall(function() assert(vim.fn.has("nvim-0.12") == 1); assert(vim.uv.os_get_passwd().uid ~= 0); assert(vim.o.termguicolors); assert(vim.g.colors_name == "nordfox"); assert(package.loaded["conform"]); assert(#vim.api.nvim_get_runtime_file("parser/c_sharp.*", false) > 0, "C# parser not installed"); assert(vim.treesitter.get_string_parser("class C {}", "c_sharp"):parse()[1]) end); if not ok then print(err); vim.cmd.cquit(1) end' \
  '+qa!'
