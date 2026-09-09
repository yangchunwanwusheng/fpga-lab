$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class PP3 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
Add-Type -AssemblyName System.Drawing
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [PP3+EnumProc]{
        param($h, $lp)
        if ([PP3]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [PP3]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [PP3]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

# 1. minimize WPS windows (user is reading PDF there)
$wps = Get-Process | Where-Object { $_.ProcessName -match '^wps' -and $_.MainWindowHandle -ne 0 }
foreach ($p in $wps) {
    Write-Output ("minimizing wps pid=" + $p.Id)
    [PP3]::ShowWindow($p.MainWindowHandle, 6) | Out-Null
}
Start-Sleep -Milliseconds 1200

# 2. real click on Quartus title bar to take focus
$h = Find-TopWindow "^Quartus Prime Lite Edition"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }
$r = New-Object PP3+RECT
[PP3]::GetWindowRect($h, [ref]$r) | Out-Null
Write-Output ("QUARTUS_RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)
$cx = [int](($r.Left + $r.Right) / 2)
Invoke-Click $cx ($r.Top + 15)
Start-Sleep -Milliseconds 1000
[PP3]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 800

# 3. click Tools menu (window top-left at screen; menu y offset +46, x offset +528)
Invoke-Click ($r.Left + 528) ($r.Top + 46)
Start-Sleep -Milliseconds 1500

$w = [PP3]::GetSystemMetrics(0); $ht = [PP3]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\tools_menu_v2.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "SHOT_SAVED"
