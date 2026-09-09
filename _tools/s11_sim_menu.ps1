$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S11 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
$script:found = [IntPtr]::Zero
$cb = [S11+EnumProc]{
    param($h, $lp)
    if ([S11]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [S11]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "Simulation Waveform Editor") { $script:found = $h; return $false }
    }
    return $true
}
[S11]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR no vwf window"; exit 1 }
$r = New-Object S11+RECT
[S11]::GetWindowRect($script:found, [ref]$r) | Out-Null
Write-Output ("RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)
[S11]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -Milliseconds 1200
# Simulation menu at window-relative (192, 48) + 8px title bar already included in bitmap
$mx = $r.Left + 192
$my = $r.Top + 48
Invoke-Click $mx $my
Start-Sleep -Milliseconds 1200
Write-Output ("CLICKED " + $mx + " " + $my)
