param(
    [Parameter(Mandatory=$true)][string]$TitleRegex,
    [Parameter(Mandatory=$true)][string]$OutFile
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
[W]::SetProcessDPIAware() | Out-Null

$proc = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -match $TitleRegex } | Select-Object -First 1
if (-not $proc) {
    Write-Output "ERR: no window matching [$TitleRegex]"
    Get-Process | Where-Object { $_.MainWindowTitle } | ForEach-Object { Write-Output ("  TITLE: " + $_.MainWindowTitle) }
    exit 1
}
$h = $proc.MainWindowHandle
[W]::ShowWindow($h, 9) | Out-Null   # SW_RESTORE
[W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1200
$r = New-Object W+RECT
[W]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left
$ht = $r.Bottom - $r.Top
if ($w -le 0 -or $ht -le 0) { Write-Output "ERR: bad rect"; exit 1 }
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
$dir = Split-Path -Parent $OutFile
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "saved $OutFile ($w x $ht)"
