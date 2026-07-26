# =============================================================================
# PowerShell Profile - seokgukim
# =============================================================================

# -----------------------------------------------------------------------------
# 환경변수
# -----------------------------------------------------------------------------
$env:EDITOR = "nvim"
$env:VISUAL = "nvim"
$env:AGENT_WORKSPACE = "$HOME\_agent"
$env:LLAMA_LOCAL_ENDPOINT = ""

# Ghost / Axis USB system
$env:SHELL_GHOST = "D:\"
$heartEnv = [System.IO.Path]::Combine($env:SHELL_GHOST, "scripts\pwsh\heart_env.ps1")
if (Test-Path -LiteralPath $heartEnv -PathType Leaf) {
	Invoke-Expression ((& $heartEnv -Format powershell) -join "`n")
}
# -----------------------------------------------------------------------------
# 별칭
# -----------------------------------------------------------------------------
# Set-Alias vim nvim
# Set-Alias ll Get-ChildItem

# -----------------------------------------------------------------------------
# 유틸 함수
# -----------------------------------------------------------------------------

# which: 명령어 경로 출력
function which($cmd) {
    (Get-Command $cmd -ErrorAction SilentlyContinue).Source
}

# mkcd: 디렉터리 만들고 바로 이동
function mkcd($dir) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    Set-Location $dir
}
# UTF-8 설정
$env:PYTHONUTF8 = '1'
# -----------------------------------------------------------------------------
# 프롬프트 / 테마
# -----------------------------------------------------------------------------
# oh-my-posh 사용 시 아래 주석 해제 (테마 파일 경로는 본인 것으로 변경)
# oh-my-posh init pwsh --config "$HOME\.omp.json" | Invoke-Expression

# posh-git 사용 시
# Import-Module posh-git

# -----------------------------------------------------------------------------
# 모듈
# -----------------------------------------------------------------------------
# Import-Module PSReadLine
# Set-PSReadLineOption -EditMode Emacs   # Vi 모드: Vi

# -----------------------------------------------------------------------------
# 경로 추가
# -----------------------------------------------------------------------------
# $env:PATH += ";$HOME\.local\bin"
# =============================================================================

# -----------------------------------------------------------------------------
# IME 시작 시 영어로 기본 설정 (한글/일어 상태에서 영어 모드로 전환)
# -----------------------------------------------------------------------------
if (-not ([System.Management.Automation.PSTypeName]"IMEControl").Type) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class IMEControl {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("imm32.dll")]
        public static extern IntPtr ImmGetContext(IntPtr hWnd);

        [DllImport("imm32.dll")]
        public static extern bool ImmSetOpenStatus(IntPtr hIMC, bool fOpen);

        [DllImport("imm32.dll")]
        public static extern bool ImmSetConversionStatus(IntPtr hIMC, int fdwConversion, int fdwSentence);

        [DllImport("imm32.dll")]
        public static extern bool ImmReleaseContext(IntPtr hWnd, IntPtr hIMC);
    }
"@
}

function Set-IMEEnglish {
    # 1. Console Window (conhost)
    $hwnd = [IMEControl]::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) {
        $himc = [IMEControl]::ImmGetContext($hwnd)
        if ($himc -ne [IntPtr]::Zero) {
            [IMEControl]::ImmSetOpenStatus($himc, $false) | Out-Null
            [IMEControl]::ImmSetConversionStatus($himc, 0, 0) | Out-Null
            [IMEControl]::ImmReleaseContext($hwnd, $himc) | Out-Null
        }
    }
    
    # 2. Foreground Window (Windows Terminal, VS Code, etc.)
    $hwndFg = [IMEControl]::GetForegroundWindow()
    if ($hwndFg -ne [IntPtr]::Zero -and $hwndFg -ne $hwnd) {
        $himcFg = [IMEControl]::ImmGetContext($hwndFg)
        if ($himcFg -ne [IntPtr]::Zero) {
            [IMEControl]::ImmSetOpenStatus($himcFg, $false) | Out-Null
            [IMEControl]::ImmSetConversionStatus($himcFg, 0, 0) | Out-Null
            [IMEControl]::ImmReleaseContext($hwndFg, $himcFg) | Out-Null
        }
    }
}

# 파워셸 시작 시 영어 모드 적용
Set-IMEEnglish
