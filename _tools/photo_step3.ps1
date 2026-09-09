$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class PP4 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
Add-Type -AssemblyName System.Drawing
$script:found = [IntPtr]::Zero
$cb = [PP4+EnumProc]{
    param($h, $lp)
    if ([PP4]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [PP4]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "^Quartus Prime Lite Edition") { $script:found = $h; return $false }
    }
    return $true
}
[PP4]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }

# restore if minimized
[PP4]::ShowWindow($script:found, 9) | Out-Null
Start-Sleep -Milliseconds 2000
$r = New-Object PP4+RECT
[PP4]::GetWindowRect($script:found, [ref]$r) | Out-Null
Write-Output ("QUARTUS_RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)
if ($r.Left -lt -30000) { Write-Output "ERR still minimized"; exit 1 }

# real click on title bar for focus
$cx = [int](($r.Left + $r.Right) / 2)
Invoke-Click $cx ($r.Top + 15)
Start-Sleep -Milliseconds 1000

# click Tools menu
Invoke-Click ($r.Left + 528) ($r.Top + 46)
Start-Sleep -Milliseconds 1500

$w = [PP4]::GetSystemMetrics(0); $ht = [PP4]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\tools_menu_v3.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "SHOT_SAVED"
