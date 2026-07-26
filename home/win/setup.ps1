param(
    [ValidateRange(0, 2)]
    [int]$Level = 1
)

$ErrorActionPreference = 'Stop'

$StartMarker = '# >>> AXIS private setup >>>'
$EndMarker = '# <<< AXIS private setup <<<'

function Read-Utf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $reader = New-Object System.IO.StreamReader(
        $Path,
        [System.Text.Encoding]::UTF8,
        $true
    )
    try {
        return $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

function Invoke-WingetInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    & winget list --id $Id -e --accept-source-agreements --disable-interactivity *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[setup.ps1] Already installed: $Id"
        return
    }

    Write-Host "[setup.ps1] Installing $Id"
    & winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed while installing $Id"
    }
}

function Sync-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    $source = Read-Utf8Text -Path $SourcePath
    $managedBlock = "$StartMarker`n$source`n$EndMarker"

    if (Test-Path -LiteralPath $TargetPath) {
        $existing = Read-Utf8Text -Path $TargetPath
    }
    else {
        $existing = ''
    }

    $pattern = [regex]::Escape($StartMarker) + '.*?' + [regex]::Escape($EndMarker)
    $startMatches = [regex]::Matches($existing, [regex]::Escape($StartMarker))
    $endMatches = [regex]::Matches($existing, [regex]::Escape($EndMarker))
    if (
        $startMatches.Count -ne $endMatches.Count -or
        $startMatches.Count -gt 1 -or
        (
            $startMatches.Count -eq 1 -and
            $startMatches[0].Index -gt $endMatches[0].Index
        )
    ) {
        throw "unmatched managed profile marker in $TargetPath"
    }

    if ([regex]::IsMatch(
        $existing,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )) {
        $updated = [regex]::Replace(
            $existing,
            $pattern,
            { param($match) $managedBlock },
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
    }
    else {
        if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) {
            $existing += "`n"
        }
        $updated = $existing + $managedBlock + "`n"
    }

    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($TargetPath, $updated, $utf8WithBom)
}

function Set-DirectoryJunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
        throw "junction source not found: $SourcePath"
    }

    $parent = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    if (Test-Path -LiteralPath $TargetPath) {
        $existing = Get-Item -Force -LiteralPath $TargetPath
        if (
            ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and
            ([string]$existing.Target -eq $SourcePath)
        ) {
            return
        }

        $backupPath = '{0}.bak-{1}' -f $TargetPath, (Get-Date -Format 'yyyyMMddHHmmss')
        Write-Host "[setup.ps1] Moving existing path to $backupPath"
        Move-Item -LiteralPath $TargetPath -Destination $backupPath
    }

    New-Item -ItemType Junction -Path $TargetPath -Target $SourcePath | Out-Null
}

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)
$SourceProfile = Join-Path $ScriptRoot 'Microsoft.PowerShell_profile.ps1'
$TargetProfile = $PROFILE.CurrentUserCurrentHost
$SourceNvim = Join-Path $RepoRoot 'config\nvim'
$TargetNvim = Join-Path $env:LOCALAPPDATA 'nvim'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required for setup.ps1'
}

$profileDir = Split-Path -Parent $TargetProfile
if (-not (Test-Path -LiteralPath $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

$packages = @()
switch ($Level) {
    0 {
        $packages = @(
            'cURL.cURL',
            'GnuWin32.Tar',
            '7zip.7zip',
            'GnuWin32.UnZip',
            'JernejSimoncic.Wget',
            'vim.vim',
            'frippery.busybox-w32'
        )
    }
    1 {
        $packages = @(
            'cURL.cURL',
            'GnuWin32.Tar',
            '7zip.7zip',
            'GnuWin32.UnZip',
            'JernejSimoncic.Wget',
            'vim.vim',
            'frippery.busybox-w32',
            'Git.Git',
            'OpenJS.NodeJS',
            'Python.Python.3.13',
            'Docker.DockerDesktop',
            'Neovim.Neovim',
            'arndawg.tmux-windows',
            'junegunn.fzf',
            'sharkdp.fd',
            'BurntSushi.ripgrep.MSVC',
            'JesseDuffield.lazygit',
            'sharkdp.bat',
            'Microsoft.VisualStudio.2022.BuildTools'
        )
    }
    2 {
        $packages = @(
            'cURL.cURL',
            'GnuWin32.Tar',
            '7zip.7zip',
            'GnuWin32.UnZip',
            'JernejSimoncic.Wget',
            'vim.vim',
            'frippery.busybox-w32',
            'Git.Git',
            'OpenJS.NodeJS',
            'Python.Python.3.13',
            'Docker.DockerDesktop',
            'Neovim.Neovim',
            'arndawg.tmux-windows',
            'junegunn.fzf',
            'sharkdp.fd',
            'BurntSushi.ripgrep.MSVC',
            'JesseDuffield.lazygit',
            'sharkdp.bat',
            'Microsoft.VisualStudio.2022.BuildTools',
            'jj-vcs.jj',
            'sxyazi.yazi',
            'RubyInstallerTeam.Ruby.3.4',
            'Kitware.CMake',
            'Rustlang.Rustup'
        )
    }
}

foreach ($package in $packages) {
    Invoke-WingetInstall -Id $package
}

Sync-ManagedBlock -TargetPath $TargetProfile -SourcePath $SourceProfile
Set-DirectoryJunction -TargetPath $TargetNvim -SourcePath $SourceNvim

Write-Host "[setup.ps1] Updated $TargetProfile and $TargetNvim"