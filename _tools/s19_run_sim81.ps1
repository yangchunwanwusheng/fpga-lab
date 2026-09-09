$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S19 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
function Close-TopWindow([string]$regex) {
    $script:hit = [IntPtr]::Zero
    $cb = [S19+EnumProc]{
        param($h, $lp)
        if ([S19]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S19]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:hit = $h; return $false }
        }
        return $true
    }
    [S19]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    if ($script:hit -ne [IntPtr]::Zero) { [S19]::SendMessageW($script:hit, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; Start-Sleep -Seconds 2; return $true }
    return $false
}
Close-TopWindow "^Open File$" | Out-Null
Close-TopWindow "^Settings" | Out-Null
Write-Output "STRAYS_CLOSED"

# find the vwf editor window and run simulation via its menu
$script:found = [IntPtr]::Zero
$cb2 = [S19+EnumProc]{
    param($h, $lp)
    if ([S19]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [S19]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "Simulation Waveform Editor.*mux81a2223\.vwf") { $script:found = $h; return $false }
    }
    return $true
}
[S19]::EnumWindows($cb2, [IntPtr]::Zero) | Out-Null
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR vwf window"; exit 1 }
$r = New-Object S19+RECT
[S19]::GetWindowRect($script:found, [ref]$r) | Out-Null
Write-Output ("RECT " + $r.Left + " " + $r.Top)
[S19]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -Milliseconds 1500
Invoke-Click ($r.Left + 192) ($r.Top + 48)
Start-Sleep -Milliseconds 1200
Invoke-Click ($r.Left + 314) ($r.Top + 126)
Write-Output "SIM81_STARTED"
