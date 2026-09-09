param(
    [Parameter(Mandatory=$true)][string]$TitleRegex,
    [Parameter(Mandatory=$true)][string]$OutFile
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Cap2 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
[Cap2]::SetProcessDPIAware() | Out-Null

$script:found = [IntPtr]::Zero
$cb = [Cap2+EnumProc]{
    param($h, $lp)
    if ([Cap2]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [Cap2]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match $TitleRegex) {
            $script:found = $h
            return $false
        }
    }
    return $true
}
[Cap2]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null

if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR: no window matching [$TitleRegex]"; exit 1 }
[Cap2]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -Milliseconds 1200
$r = New-Object Cap2+RECT
[Cap2]::GetWindowRect($script:found, [ref]$r) | Out-Null
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
