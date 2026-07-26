# Setup Script for Global Ctrl+Alt+T Hotkey to Launch Windows Terminal
# Run this script to install or update the global hotkey.

$ErrorActionPreference = "Stop"

$installDir = "$env:LOCALAPPDATA\wt-hotkey"
$csFile = Join-Path $installDir "wt-hotkey.cs"
$exeFile = Join-Path $installDir "wt-hotkey.exe"

Write-Host "Creating installation directory: $installDir..."
$null = New-Item -ItemType Directory -Force -Path $installDir

Write-Host "Writing C# source code..."
$csCode = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

public class Program
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll")]
    private static extern int GetMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax);

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pt_x;
        public int pt_y;
    }

    private const uint MOD_ALT = 0x0001;
    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_NOREPEAT = 0x4000;
    private const uint VK_T = 0x54;
    private const int HOTKEY_ID = 9123;
    private const uint WM_HOTKEY = 0x0312;

    private static Mutex mutex = new Mutex(true, "{B7A98A94-FBC3-43C0-B775-E385DBF8CDA0}");

    [STAThread]
    public static void Main()
    {
        if (!mutex.WaitOne(TimeSpan.Zero, true))
        {
                Environment.Exit(1);
        }

        bool registered = RegisterHotKey(IntPtr.Zero, HOTKEY_ID, MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, VK_T);
        if (!registered)
        {
            registered = RegisterHotKey(IntPtr.Zero, HOTKEY_ID, MOD_CONTROL | MOD_ALT, VK_T);
        }

        if (!registered)
        {
                LogError("Unable to register Ctrl+Alt+T.");
                Environment.Exit(2);
        }

            MSG msg;
            int messageResult;
            while ((messageResult = GetMessage(out msg, IntPtr.Zero, 0, 0)) > 0)
            {
                if (msg.message == WM_HOTKEY && msg.wParam.ToInt32() == HOTKEY_ID)
                {
                    LaunchWindowsTerminal();
                }
            }

            UnregisterHotKey(IntPtr.Zero, HOTKEY_ID);
            if (messageResult < 0)
            {
                LogError("GetMessage failed.");
                Environment.Exit(3);
            }
    }

    private static void LaunchWindowsTerminal()
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "wt.exe",
                UseShellExecute = true
            });
        }
        catch
        {
            try
            {
                string localAppPath = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string wtPath = System.IO.Path.Combine(localAppPath, @"Microsoft\WindowsApps\wt.exe");
                Process.Start(new ProcessStartInfo
                {
                    FileName = wtPath,
                    UseShellExecute = true
                });
            }
            catch
            {
                LogError("Unable to launch Windows Terminal.");
            }
        }
    }

    private static void LogError(string message)
    {
        try
        {
            string logPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "wt-hotkey.log");
            System.IO.File.AppendAllText(logPath, DateTime.UtcNow.ToString("o") + " " + message + Environment.NewLine);
        }
        catch
        {
        }
    }
}
'@

Set-Content -Path $csFile -Value $csCode -Encoding UTF8

Write-Host "Stopping any running instances of wt-hotkey..."
$oldProcesses = Get-Process -Name "wt-hotkey" -ErrorAction SilentlyContinue
foreach ($p in $oldProcesses) {
    Write-Host "Stopping process with PID: $($p.Id)..."
    Stop-Process -Id $p.Id -Force
}

# Allow a moment for processes to unlock files
Start-Sleep -Seconds 1

Write-Host "Compiling background executable..."
$cscCommand = Get-Command csc.exe -ErrorAction SilentlyContinue
$cscCandidates = @(
    if ($cscCommand) { $cscCommand.Source }
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$cscPath = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $cscPath) {
    throw "C# compiler not found."
}

& $cscPath /target:winexe /out:$exeFile $csFile
if ($LASTEXITCODE -ne 0) {
    throw "C# compilation failed with exit code $LASTEXITCODE."
}

Write-Host "Creating startup shortcut..."
$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\wt-hotkey.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exeFile
$shortcut.WorkingDirectory = $installDir
$shortcut.Description = "Global Ctrl+Alt+T Hotkey Daemon for Windows Terminal"
$shortcut.Save()

Write-Host "Starting background hotkey daemon..."
Start-Process -FilePath $exeFile
Start-Sleep -Seconds 1
if (-not (Get-Process -Name "wt-hotkey" -ErrorAction SilentlyContinue)) {
    throw "Hotkey daemon exited during startup. See $installDir\wt-hotkey.log."
}

Write-Host "Setup completed successfully! Press Ctrl+Alt+T to launch Windows Terminal."
