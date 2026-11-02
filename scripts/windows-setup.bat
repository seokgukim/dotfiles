@echo off
REM windows-setup.bat — Install Neovim and Nushell
REM Run as Administrator for best results.

echo Installing Neovim and Nushell via winget (if available)...
where winget >nul 2>&1
if %ERRORLEVEL%==0 (
  winget install --id Neovim.Neovim -e --silent || echo Neovim install failed or already installed
  winget install --id NuShell.NuShell -e --silent || echo Nushell install failed or already installed
  REM Link the canonical dotfiles Neovim config directory.
  set "SCRIPT_DIR=%~dp0"
  set "REPO_ROOT=%SCRIPT_DIR%.."
  set "NVIM_DIR=%REPO_ROOT%\config\nvim"
  set "LOCAL_NVIM_DIR=%LOCALAPPDATA%\nvim"
  if exist "%NVIM_DIR%" (
    if exist "%LOCAL_NVIM_DIR%" (
      echo Backing up existing Neovim config to "%LOCAL_NVIM_DIR%.bak"
      move "%LOCAL_NVIM_DIR%" "%LOCAL_NVIM_DIR%.bak" 2>nul || rmdir /S /Q "%LOCAL_NVIM_DIR%" 2>nul
    )
    mklink /J "%LOCAL_NVIM_DIR%" "%NVIM_DIR%" >nul 2>&1 || (
      echo Failed to create junction; attempting to set XDG_CONFIG_HOME for current user
      setx XDG_CONFIG_HOME "%REPO_ROOT%\config" >nul || echo Failed to set XDG_CONFIG_HOME
    )
  ) else (
    echo "%NVIM_DIR%" not found; skipping Neovim config link
  )
) else (
  echo winget not found; please install Neovim and Nushell manually or install winget.
)

echo Done.
pause
