# Windows Lazygit & Difftastic 설치 및 자동 설정 스크립트
# ---------------------------------------------------------------
# 이 스크립트는 winget을 사용해 lazygit과 difftastic이 없으면 설치하고,
# Windows의 lazygit 설정 파일(config.yml)에 difftastic을 페이저로 자동 추가합니다.

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting Lazygit & Difftastic Environment Setup for Windows" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Lazygit 존재 여부 확인 및 설치
Write-Host "`n[1/3] Checking lazygit..." -ForegroundColor Cyan
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Write-Host "✔ lazygit is already installed." -ForegroundColor Green
} else {
    Write-Host "⚠ lazygit not found. Installing JesseDuffield.lazygit via winget..." -ForegroundColor Yellow
    winget install -e --id JesseDuffield.lazygit --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install lazygit."
        exit $LASTEXITCODE
    }
    Write-Host "✔ lazygit installation completed." -ForegroundColor Green
}

# 2. Difftastic 존재 여부 확인 및 설치
Write-Host "`n[2/3] Checking difftastic..." -ForegroundColor Cyan
if (Get-Command difft -ErrorAction SilentlyContinue) {
    Write-Host "✔ difftastic (difft) is already installed." -ForegroundColor Green
} else {
    Write-Host "⚠ difftastic not found. Installing Wilfred.difftastic via winget..." -ForegroundColor Yellow
    winget install -e --id Wilfred.difftastic --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install difftastic."
        exit $LASTEXITCODE
    }
    Write-Host "✔ difftastic installation completed." -ForegroundColor Green
}

# 3. Lazygit config.yml 설정 추가
Write-Host "`n[3/3] Configuring lazygit to use difftastic as pager..." -ForegroundColor Cyan

$configDir = "$env:LOCALAPPDATA\lazygit"
$configFile = "$configDir\config.yml"

# 설정 디렉터리가 없으면 생성
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Created directory: $configDir" -ForegroundColor Gray
}

if (-not (Test-Path $configFile)) {
    # 설정 파일이 없는 경우: 신규 파일 작성
    $defaultConfig = @"
git:
  paging:
    colorArg: always
    externalDiffCommand: difft --color always --display inline --override=*.mlua:lua --parse-error-limit=1024 --strip-cr on
"@
    Set-Content -Path $configFile -Value $defaultConfig -Encoding utf8
    Write-Host "✔ Created a new config.yml with difftastic configuration." -ForegroundColor Green
} else {
    # 설정 파일이 존재하는 경우: 기존 설정 검사 및 백업 후 추가
    $content = Get-Content -Path $configFile -Raw
    
    if ($content -match "(?m)^\s*externalDiffCommand:\s*difft\b") {
        Write-Host "✔ Difftastic is already configured in lazygit config.yml." -ForegroundColor Green
    } else {
        if ($content -match "(?m)^\s*(paging|pagers):") {
            throw "Existing lazygit paging configuration found without Difftastic. Update it manually to avoid duplicate YAML keys."
        }

        $difftCommand = "difft --color always --display inline --override=*.mlua:lua --parse-error-limit=1024 --strip-cr on"

        # 백업 파일 생성
        Copy-Item -Path $configFile -Destination "$configFile.bak" -Force
        Write-Host "Created backup of existing config: config.yml.bak" -ForegroundColor Gray
        
        # 기존 파일에 'git:' 섹션 유무에 따라 삽입 또는 추가
        if ($content -match "(?m)^git:") {
            # git: 섹션 바로 밑에 pagers 삽입
            $newContent = $content -replace "(?m)^git:", "git:`r`n  paging:`r`n    colorArg: always`r`n    externalDiffCommand: $difftCommand"
            Set-Content -Path $configFile -Value $newContent -Encoding utf8
            Write-Host "✔ Successfully injected difftastic paging into your existing git section!" -ForegroundColor Green
        } else {
            # 파일 끝에 추가
            $appendConfig = @"


git:
  paging:
    colorArg: always
    externalDiffCommand: $difftCommand
"@
            Add-Content -Path $configFile -Value $appendConfig -Encoding utf8
            Write-Host "✔ Successfully appended difftastic configuration to config.yml!" -ForegroundColor Green
        }
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Setup process finished successfully!" -ForegroundColor Green
Write-Host "  Please restart your terminal/lazygit to apply changes." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
