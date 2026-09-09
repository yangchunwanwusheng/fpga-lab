$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S20 {
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
    $cb = [S20+EnumProc]{
        param($h, $lp)
        if ([S20]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S20]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S20]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}
function Invoke-RightClick([int]$x, [int]$y) {
    [S20]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 200
    [S20]::mouse_event(0x0008, 0, 0, 0, [UIntPtr]::Zero)
    [S20]::mouse_event(0x0010, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 800
}

# 1. open project (reuse existing instance if possible)
$hits = Find-TopWindow "mux81a2223 - mux81a2223"
if ($hits -eq [IntPtr]::Zero) {
    Start-Process "D:\QP\quartus\bin64\quartus.exe" -ArgumentList '"D:\FPGA_Lab\exp1\optional_81mux_verilog\mux81a2223.qpf"'
    $deadline = (Get-Date).AddSeconds(150)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 4
        $hits = Find-TopWindow "mux81a2223 - mux81a2223"
        if ($hits -ne [IntPtr]::Zero) { break }
    }
}
if ($hits -eq [IntPtr]::Zero) { Write-Output "ERR project"; exit 1 }
Write-Output "PROJECT_OPEN"
[S20]::ShowWindow($hits, 9) | Out-Null
Start-Sleep -Milliseconds 1500
[S20]::SetForegroundWindow($hits) | Out-Null
Start-Sleep -Milliseconds 1200
$r = New-Object S20+RECT
[S20]::GetWindowRect($hits, [ref]$r) | Out-Null
Write-Output ("RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)

# 2. Navigator dropdown -> Files (window-relative coords, maximized layout)
Invoke-Click ($r.Left + 300) ($r.Top + 148)
Start-Sleep -Milliseconds 1200
Invoke-Click ($r.Left + 216) ($r.Top + 182)
Start-Sleep -Milliseconds 1200

# 3. right-click the .vwf row -> Open (row ~y260 window-relative, maximized layout)
Invoke-RightClick ($r.Left + 120) ($r.Top + 260)
Start-Sleep -Milliseconds 600
Invoke-Click ($r.Left + 187) ($r.Top + 277)
Start-Sleep -Seconds 8

# 4. verify: list top windows
$script:hit2 = [IntPtr]::Zero
$cb2 = [S20+EnumProc]{
    param($h, $lp)
    if ([S20]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [S20]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "Simulation Waveform Editor") { $script:hit2 = $h; return $false }
    }
    return $true
}
[S20]::EnumWindows($cb2, [IntPtr]::Zero) | Out-Null
if ($script:hit2 -ne [IntPtr]::Zero) { Write-Output "VWF_EDITOR_OPEN" } else { Write-Output "VWF_NOT_OPEN" }
