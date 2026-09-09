$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S21 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
Add-Type -AssemblyName System.Drawing
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S21+EnumProc]{
        param($h, $lp)
        if ([S21]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S21]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S21]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}
function Invoke-RightClick([int]$x, [int]$y) {
    [S21]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 200
    [S21]::mouse_event(0x0008, 0, 0, 0, [UIntPtr]::Zero)
    [S21]::mouse_event(0x0010, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 800
}

$h = Find-TopWindow "mux81a2223 - mux81a2223"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR project window"; exit 1 }
[S21]::ShowWindow($h, 9) | Out-Null
Start-Sleep -Milliseconds 1500
[S21]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1200
$r = New-Object S21+RECT
[S21]::GetWindowRect($h, [ref]$r) | Out-Null
Write-Output ("RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)

# Navigator dropdown -> Files view
Invoke-Click ($r.Left + 300) ($r.Top + 148)
Start-Sleep -Milliseconds 1200
Invoke-Click ($r.Left + 216) ($r.Top + 182)
Start-Sleep -Milliseconds 1200

# right-click .vwf row -> Open
Invoke-RightClick ($r.Left + 120) ($r.Top + 260)
Start-Sleep -Milliseconds 600
Invoke-Click ($r.Left + 187) ($r.Top + 277)
Start-Sleep -Seconds 8

$script:hit = [IntPtr]::Zero
$cb2 = [S21+EnumProc]{
    param($h, $lp)
    if ([S21]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [S21]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "Simulation Waveform Editor") { $script:hit = $h; return $false }
    }
    return $true
}
[S21]::EnumWindows($cb2, [IntPtr]::Zero) | Out-Null
if ($script:hit -ne [IntPtr]::Zero) { Write-Output "VWF_EDITOR_OPEN" } else { Write-Output "VWF_NOT_OPEN" }
