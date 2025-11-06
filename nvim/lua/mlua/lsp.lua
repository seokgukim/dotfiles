-- lua/mlua-manager/init.lua
local M = {}

-- Track buffers per client for diagnostic and semantic token refresh logic.
local attached_buffers = {}

-- Cache expensive workspace snapshots per root-dir to avoid re-scanning on every attachment.
local document_cache = {}
local predefines_cache = {}
local node_platform_cache

local function trim(s)
  if type(s) ~= "string" then
    return s
  end

  if vim.trim then
    return vim.trim(s)
  end

  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function detect_node_platform()
  if node_platform_cache then
    return node_platform_cache
  end

  local output = vim.fn.system({ "node", "-p", "process.platform" })
  if vim.v.shell_error ~= 0 then
    node_platform_cache = "unknown"
  else
    node_platform_cache = trim(output)
  end

  return node_platform_cache
end

local function normalize_for_node(path)
  if not path or path == '' then
    return path
  end

  local platform = detect_node_platform()
  if platform ~= "win32" then
    return path
  end

  if path:match("^%a:[/\\]") then
    return path
  end

  if vim.fn.executable("wslpath") ~= 1 then
    return path
  end

  local converted = vim.fn.system({ "wslpath", "-w", path })
  if vim.v.shell_error ~= 0 then
    return path
  end

  return trim(converted)
end

local function json_decode(payload)
  if payload == nil or payload == '' then
    return nil
  end

  local ok, decoded = pcall(vim.fn.json_decode, payload)
  if not ok then
    return nil
  end

  return decoded
end

-- Convert server diagnostics into Neovim diagnostics by reusing the publish handler.
local function publish_diagnostics(client, uri, diagnostics)
  if not diagnostics then
    return
  end

  local handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
  if handler then
    handler(nil, { uri = uri, diagnostics = diagnostics }, { client_id = client.id })
  end
end

local function request_document_diagnostics(client, bufnr)
  if not client or not client.supports_method("textDocument/diagnostic") then
    return
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

  client.request("textDocument/diagnostic", params, function(err, result)
    if err then
      vim.notify_once(
        string.format("mLua diagnostics request failed: %s", err.message or tostring(err)),
        vim.log.levels.WARN
      )
      return
    end

    if not result then
      return
    end

    if result.kind == "full" then
      publish_diagnostics(client, params.textDocument.uri, result.items)
    end
  end, bufnr)
end

local function register_buffer_cleanup(client_id, bufnr)
  vim.api.nvim_create_autocmd("BufUnload", {
    buffer = bufnr,
    once = true,
    callback = function()
      local buckets = attached_buffers[client_id]
      if buckets then
        buckets[bufnr] = nil
      end
    end,
  })
end

local function load_predefines(installed_dir)
  if not installed_dir or installed_dir == '' then
    return nil
  end

  local cached = predefines_cache[installed_dir]
  if cached then
    return cached
  end

  local predefines_dir = vim.fn.fnamemodify(installed_dir .. "/extension/scripts/predefines", ':p')
  if vim.fn.isdirectory(predefines_dir) == 0 then
    return nil
  end

  local predefines_index = vim.fn.fnamemodify(predefines_dir .. "/out/index.js", ':p')
  if vim.fn.filereadable(predefines_index) == 0 then
    vim.notify_once("mLua predefines file missing: " .. predefines_index, vim.log.levels.WARN)
    return nil
  end

  local node_predefines_index = normalize_for_node(predefines_index)

  local script = table.concat({
    [[const path = require('path');]],
    string.format("const pre = require(path.resolve(%s));", vim.fn.json_encode(node_predefines_index)),
    [[const result = {]],
    [[  modules: pre.Predefines.modules(),]],
    [[  globalVariables: pre.Predefines.globalVariables(),]],
    [[  globalFunctions: pre.Predefines.globalFunctions()]],
    [[};]],
    [[process.stdout.write(JSON.stringify(result));]],
  }, '\n')

  local output = vim.fn.system({ "node", "-e", script })
  if vim.v.shell_error ~= 0 then
    vim.notify_once("Failed to load mLua predefines: " .. output, vim.log.levels.WARN)
    return nil
  end

  local decoded = json_decode(output)
  if not decoded then
    vim.notify_once("Failed to decode mLua predefines response", vim.log.levels.WARN)
    return nil
  end

  predefines_cache[installed_dir] = decoded
  return decoded
end

local function read_file_state(path)
  local bufnr = vim.fn.bufnr(path, false)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return table.concat(lines, "\n"), true
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, false
  end

  return table.concat(lines, "\n"), false
end

local function collect_document_items(root_dir)
  if not root_dir or root_dir == '' then
    return {}
  end

  root_dir = vim.fn.fnamemodify(root_dir, ':p')

  local cached = document_cache[root_dir]
  if cached then
    return cached
  end

  local files = vim.fn.globpath(root_dir, "**/*.mlua", false, true)
  local items = {}

  for _, path in ipairs(files) do
    if vim.fn.filereadable(path) == 1 then
      local text = select(1, read_file_state(path))
      if text then
        table.insert(items, {
          uri = vim.uri_from_fname(path),
          languageId = "mlua",
          version = 0,
          text = text,
        })
      end
    end
  end

  document_cache[root_dir] = items
  return items
end

M.config = {
  install_dir = vim.fn.expand("~/.local/share/nvim/mlua-lsp"),
  publisher = "msw",
  extension = "mlua"
}

-- Helper function to check if Node.js is available
local function check_node_available()
  local handle = io.popen("node --version 2>&1")
  if not handle then
    return false
  end
  
  local result = handle:read("*a")
  handle:close()
  
  return result:match("v%d+%.%d+%.%d+") ~= nil
end

-- Helper function to find project root
local function find_root(fname)
  if vim.fs and vim.fs.root then
    local root = vim.fs.root(fname, {
      '.git',
      'package.json',
      '.mluarc.json',
      'mlua.config.json'
    })
    if root then return root end
  else
    local markers = { '.git', 'package.json', '.mluarc.json' }
    local path = vim.fn.fnamemodify(fname, ':p:h')
    local home = vim.loop.os_homedir()
    
    while path ~= home and path ~= '/' do
      for _, marker in ipairs(markers) do
        local marker_path = path .. '/' .. marker
        if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
          return path
        end
      end
      path = vim.fn.fnamemodify(path, ':h')
    end
  end
  
  return vim.fn.fnamemodify(fname, ':h')
end

-- [Keep all previous helper functions...]
function M.get_latest_version()
  local curl_cmd = string.format([[
    curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    -d '{"filters":[{"criteria":[{"filterType":7,"value":"%s.%s"}]}],"flags":914}' \
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
  ]], M.config.publisher, M.config.extension)
  
  local handle = io.popen(curl_cmd)
  local result = handle:read("*a")
  handle:close()
  
  local version = result:match('"version":"([^"]+)"')
  return version
end

function M.get_installed_version()
  local pattern = M.config.install_dir .. "/" .. M.config.publisher .. "." .. M.config.extension .. "-*"
  local dirs = vim.fn.glob(pattern, false, true)
  
  if #dirs == 0 then
    return nil
  end
  
  table.sort(dirs)
  local latest_dir = dirs[#dirs]
  local version = latest_dir:match("%-([%d%.]+)$")
  return version, latest_dir
end

function M.download(version)
  version = version or M.get_latest_version()
  
  if not version then
    vim.notify("Error: Could not fetch version", vim.log.levels.ERROR)
    return false
  end
  
  vim.notify("Downloading mLua v" .. version .. "...", vim.log.levels.INFO)
  
  local download_dir = M.config.install_dir
  local extension_name = M.config.publisher .. "." .. M.config.extension .. "-" .. version
  local vsix_file = download_dir .. "/" .. extension_name .. ".vsix"
  local zip_file = download_dir .. "/" .. extension_name .. ".zip"
  local extract_dir = download_dir .. "/" .. extension_name
  
  vim.fn.mkdir(download_dir, "p")
  
  local download_url = string.format(
    "https://%s.gallery.vsassets.io/_apis/public/gallery/publisher/%s/extension/%s/%s/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage",
    M.config.publisher, M.config.publisher, M.config.extension, version
  )
  
  local download_cmd = string.format('curl -L -o "%s" "%s"', vsix_file, download_url)
  local result = os.execute(download_cmd)
  
  if result ~= 0 then
    vim.notify("Error: Download failed", vim.log.levels.ERROR)
    return false
  end
  
  os.rename(vsix_file, zip_file)
  vim.fn.mkdir(extract_dir, "p")
  
  local extract_cmd
  if vim.fn.has("win32") == 1 then
    extract_cmd = string.format(
      'powershell -Command "Expand-Archive -Path \'%s\' -DestinationPath \'%s\' -Force"',
      zip_file:gsub("/", "\\"), extract_dir:gsub("/", "\\")
    )
  else
    extract_cmd = string.format('unzip -q -o "%s" -d "%s"', zip_file, extract_dir)
  end
  
  os.execute(extract_cmd)
  os.remove(zip_file)
  
  vim.notify("mLua v" .. version .. " installed successfully!", vim.log.levels.INFO)
  return true, extract_dir
end

function M.update()
  local latest_version = M.get_latest_version()
  local installed_version, installed_dir = M.get_installed_version()
  
  if not latest_version then
    vim.notify("Error: Could not fetch latest version", vim.log.levels.ERROR)
    return
  end
  
  if not installed_version then
    vim.notify("mLua not installed. Installing v" .. latest_version .. "...", vim.log.levels.INFO)
    M.download(latest_version)
    return
  end
  
  vim.notify("Installed: v" .. installed_version, vim.log.levels.INFO)
  vim.notify("Latest: v" .. latest_version, vim.log.levels.INFO)
  
  if installed_version == latest_version then
    vim.notify("Already up to date!", vim.log.levels.INFO)
    return
  end
  
  local confirm = vim.fn.confirm(
    string.format("Update mLua from v%s to v%s?", installed_version, latest_version),
    "&Yes\n&No",
    2
  )
  
  if confirm ~= 1 then
    vim.notify("Update cancelled", vim.log.levels.INFO)
    return
  end
  
  local success = M.download(latest_version)
  
  if success then
    vim.notify("Removing old version...", vim.log.levels.INFO)
    local rm_cmd
    if vim.fn.has("win32") == 1 then
      rm_cmd = string.format('rmdir /s /q "%s"', installed_dir:gsub("/", "\\"))
    else
      rm_cmd = string.format('rm -rf "%s"', installed_dir)
    end
    os.execute(rm_cmd)
    
    vim.notify("Update complete! Restart Neovim to use the new version.", vim.log.levels.WARN)
  end
end

function M.check_version()
  local latest_version = M.get_latest_version()
  local installed_version = M.get_installed_version()
  
  if not latest_version then
    vim.notify("Error: Could not fetch latest version", vim.log.levels.ERROR)
    return
  end
  
  if not installed_version then
    vim.notify("mLua is not installed", vim.log.levels.WARN)
    vim.notify("Latest available: v" .. latest_version, vim.log.levels.INFO)
    vim.notify("Run :MluaInstall to install", vim.log.levels.INFO)
    return
  end
  
  vim.notify("Installed: v" .. installed_version, vim.log.levels.INFO)
  vim.notify("Latest: v" .. latest_version, vim.log.levels.INFO)
  
  if installed_version ~= latest_version then
    vim.notify("Update available! Run :MluaUpdate to upgrade", vim.log.levels.WARN)
  else
    vim.notify("You have the latest version!", vim.log.levels.INFO)
  end
end

function M.uninstall()
  local installed_version, installed_dir = M.get_installed_version()
  
  if not installed_version then
    vim.notify("mLua is not installed", vim.log.levels.WARN)
    return
  end
  
  local confirm = vim.fn.confirm(
    string.format("Uninstall mLua v%s?", installed_version),
    "&Yes\n&No",
    2
  )
  
  if confirm ~= 1 then
    vim.notify("Uninstall cancelled", vim.log.levels.INFO)
    return
  end
  
  local rm_cmd
  if vim.fn.has("win32") == 1 then
    rm_cmd = string.format('rmdir /s /q "%s"', installed_dir:gsub("/", "\\"))
  else
    rm_cmd = string.format('rm -rf "%s"', installed_dir)
  end
  
  os.execute(rm_cmd)
  vim.notify("mLua v" .. installed_version .. " uninstalled", vim.log.levels.INFO)
end

-- Setup LSP with proper initialization (FIX for non-working features)
function M.setup(opts)
  opts = opts or {}
  
  if not check_node_available() then
    vim.notify("Node.js is not installed or not in PATH. Please install Node.js to use mLua LSP.", vim.log.levels.ERROR)
    return
  end
  
  local installed_version, installed_dir = M.get_installed_version()
  
  if not installed_version then
    vim.notify("mLua language server not found. Run :MluaInstall to install.", vim.log.levels.WARN)
    return
  end
  
  local server_path = installed_dir .. "/extension/scripts/server/out/languageServer.js"
  
  if vim.fn.filereadable(server_path) == 0 then
    vim.notify("Server file not found at: " .. server_path, vim.log.levels.ERROR)
    return
  end
  
  -- Setup autocmd to start LSP with proper initialization
  vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
    pattern = "*.mlua",
    callback = function(args)
      if not vim.api.nvim_buf_is_loaded(args.buf) then
        return
      end
      
      local bufname = vim.api.nvim_buf_get_name(args.buf)
  local root_dir = opts.root_dir or find_root(bufname)
      root_dir = root_dir and vim.fn.fnamemodify(root_dir, ':p') or nil
      if not root_dir or root_dir == '' then
        root_dir = vim.fn.getcwd()
      end

      -- Ensure we have proper capabilities advertised
      local client_capabilities = opts.capabilities or vim.lsp.protocol.make_client_capabilities()
      client_capabilities.workspace = client_capabilities.workspace or {}
      client_capabilities.workspace.diagnostic = client_capabilities.workspace.diagnostic or {
        refreshSupport = true,
      }
      client_capabilities.textDocument = client_capabilities.textDocument or {}
      client_capabilities.textDocument.diagnostic = client_capabilities.textDocument.diagnostic or {
        dynamicRegistration = false,
        relatedDocumentSupport = false,
      }

      local function refresh_attached_diagnostics(client)
        local tracked = attached_buffers[client.id]
        if not tracked then
          return
        end

        for bufnr in pairs(tracked) do
          request_document_diagnostics(client, bufnr)
        end
      end

      local handlers = vim.tbl_extend(
        "force",
        {
          ["workspace/diagnostic/refresh"] = function(_, _, ctx)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if client then
              refresh_attached_diagnostics(client)
            end
            return vim.NIL
          end,
        },
        opts.handlers or {}
      )

      local user_on_attach = opts.on_attach

      local function track_buffer(client, bufnr)
        attached_buffers[client.id] = attached_buffers[client.id] or {}
        attached_buffers[client.id][bufnr] = true
        register_buffer_cleanup(client.id, bufnr)
      end

      local function default_on_attach(client, bufnr)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to definition' })
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Hover' })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, desc = 'References' })
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = 'Rename' })
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })
      end

      local function combined_on_attach(client, bufnr)
        track_buffer(client, bufnr)
        request_document_diagnostics(client, bufnr)

        if user_on_attach then
          local ok, err = pcall(user_on_attach, client, bufnr)
          if not ok then
            vim.notify("mLua on_attach callback failed: " .. tostring(err), vim.log.levels.ERROR)
          end
        else
          default_on_attach(client, bufnr)
        end
      end
      
      -- Initialize options matching VSCode extension structure
      -- CRITICAL: VSCode extension uses JSON.stringify() on initializationOptions!
      local document_items = collect_document_items(root_dir)
      local current_uri = vim.uri_from_bufnr(args.buf)
      local has_current = false

      for _, item in ipairs(document_items) do
        if item.uri == current_uri then
          has_current = true
          break
        end
      end

      if not has_current then
        local text = table.concat(vim.api.nvim_buf_get_lines(args.buf, 0, -1, false), "\n")
        table.insert(document_items, {
          uri = current_uri,
          languageId = "mlua",
          version = 0,
          text = text,
        })
      end

      local predefines = load_predefines(installed_dir) or {}

      local init_options_table = {
        documentItems = document_items,
        entryItems = {},
        modules = predefines.modules or {},
        globalVariables = predefines.globalVariables or {},
        globalFunctions = predefines.globalFunctions or {},
        stopwatch = false,
        profileMode = 0,
        capabilities = {
          completionCapability = {
            codeBlockScriptSnippetCompletion = true,
            codeBlockBTNodeSnippetCompletion = true,
            codeBlockComponentSnippetCompletion = true,
            codeBlockEventSnippetCompletion = true,
            codeBlockMethodSnippetCompletion = true,
            codeBlockHandlerSnippetCompletion = true,
            codeBlockItemSnippetCompletion = true,
            codeBlockLogicSnippetCompletion = true,
            codeBlockPropertySnippetCompletion = true,
            codeBlockStateSnippetCompletion = true,
            codeBlockStructSnippetCompletion = true,
            attributeCompletion = true,
            eventMethodCompletion = true,
            overrideMethodCompletion = true,
            overridePropertyCompletion = true,
            annotationCompletion = true,
            keywordCompletion = true,
            luaCodeCompletion = true,
            commitCharacterSupport = true,
          },
          definitionCapability = {},
          diagnosticCapability = {
            needExtendsDiagnostic = true,
            notEqualsNameDiagnostic = true,
            duplicateLocalDiagnostic = true,
            introduceGlobalVariableDiagnostic = true,
            parseErrorDiagnostic = true,
            annotationParseErrorDiagnostic = true,
            unavailableAttributeDiagnostic = true,
            unavailableTypeDiagnostic = true,
            unresolvedMemberDiagnostic = true,
            unresolvedSymbolDiagnostic = true,
            assignTypeMismatchDiagnostic = true,
            parameterTypeMismatchDiagnostic = true,
            deprecatedDiagnostic = true,
            overrideMemberMismatchDiagnostic = true,
            unavailableOptionalParameterDiagnostic = true,
            unavailableParameterNameDiagnostic = true,
            invalidAttributeArgumentDiagnostic = true,
            notAllowPropertyDefaultValueDiagnostic = true,
            assignToReadonlyDiagnostic = true,
            needPropertyDefaultValueDiagnostic = true,
            notEnoughArgumentDiagnostic = true,
            tooManyArgumentDiagnostic = true,
            duplicateMemberDiagnostic = true,
            cannotOverrideMemberDiagnostic = true,
            tableKeyTypeMismatchDiagnostic = true,
            duplicateAttributeDiagnostic = true,
            invalidEventHandlerParameterDiagnostic = true,
            unavailablePropertyNameDiagnostic = true,
            annotationTypeNotFoundDiagnostic = true,
            annotationParamNotFoundDiagnostic = true,
            unbalancedAssignmentDiagnostic = true,
            unexpectedReturnDiagnostic = true,
            needReturnDiagnostic = true,
            duplicateParamDiagnostic = true,
            returnTypeMismatchDiagnostic = true,
            expectedReturnValueDiagnostic = true,
          },
          documentSymbolCapability = {},
          hoverCapability = {},
          referenceCapability = {},
          semanticTokensCapability = {},
          signatureHelpCapability = {},
          typeDefinitionCapability = {},
          renameCapability = {},
          inlayHintCapability = {},
          documentFormattingCapability = {},
          documentRangeFormattingCapability = {},
        },
      }
      
      -- Convert to JSON string like VSCode does: JSON.stringify(initializationOptions)
  local init_options_json = vim.fn.json_encode(init_options_table)
      
      -- Start LSP with JSON string initialization
      vim.lsp.start({
        name = 'mlua',
        cmd = { 'node', server_path, '--stdio' },
        root_dir = root_dir,
        init_options = init_options_json,
        settings = opts.settings or {},
        handlers = handlers,
        flags = {
          debounce_text_changes = 150,
          allow_incremental_sync = true,
        },
        on_init = function(client)
          vim.notify("mLua LSP initialized successfully", vim.log.levels.INFO)
        end,
        on_attach = combined_on_attach,
        on_error = function(code, err)
          vim.notify("mLua LSP error [" .. tostring(code) .. "]: " .. tostring(err), vim.log.levels.ERROR)
        end,
        capabilities = client_capabilities,
      }, {
        bufnr = args.buf,
      })
    end,
  })
  
  vim.notify("mLua LSP v" .. installed_version .. " configured", vim.log.levels.INFO)
end

-- Create user commands
vim.api.nvim_create_user_command('MluaInstall', M.download, { desc = 'Install mLua language server' })
vim.api.nvim_create_user_command('MluaUpdate', M.update, { desc = 'Update mLua language server' })
vim.api.nvim_create_user_command('MluaCheckVersion', M.check_version, { desc = 'Check mLua version' })
vim.api.nvim_create_user_command('MluaUninstall', M.uninstall, { desc = 'Uninstall mLua language server' })
vim.api.nvim_create_user_command('MluaRestart', function()
  vim.lsp.stop_client(vim.lsp.get_clients({ name = 'mlua' }))
  vim.defer_fn(function()
    vim.cmd('edit')
  end, 500)
end, { desc = 'Restart mLua language server' })
vim.api.nvim_create_user_command('MluaDebug', function()
  require('mlua.debug').check_status()
end, { desc = 'Show mLua LSP debug information' })
vim.api.nvim_create_user_command('MluaLogs', function()
  require('mlua.debug').show_logs()
end, { desc = 'Show LSP logs' })
vim.api.nvim_create_user_command('MluaCapabilities', function()
  require('mlua.debug').show_capabilities()
end, { desc = 'Show full server capabilities' })

return M
