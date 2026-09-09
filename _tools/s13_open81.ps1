$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S13 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
}
'@
function Close-TopWindow([string]$regex) {
    $script:hit = [IntPtr]::Zero
    $cb = [S13+EnumProc]{
        param($h, $lp)
        if ([S13]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S13]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:hit = $h; return $false }
        }
        return $true
    }
    [S13]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    if ($script:hit -ne [IntPtr]::Zero) { [S13]::SendMessageW($script:hit, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; Start-Sleep -Milliseconds 1500; return $true }
    return $false
}
Close-TopWindow "^Programmer" | Out-Null
Close-TopWindow "sim\.vwf \(Read-Only\)" | Out-Null
Close-TopWindow "Simulation Waveform Editor" | Out-Null
Close-TopWindow "^Quartus Prime Lite Edition" | Out-Null
Start-Sleep -Seconds 4
Get-Process quartus -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

Start-Process "D:\QP\quartus\bin64\quartus.exe" -ArgumentList '"D:\FPGA_Lab\exp1\optional_81mux_verilog\mux81a2223.qpf"'
$deadline = (Get-Date).AddSeconds(150)
$script:found = [IntPtr]::Zero
$cb = [S13+EnumProc]{
    param($h, $lp)
    if ([S13]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [S13]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "mux81a2223 - mux81a2223") { $script:found = $h; return $false }
    }
    return $true
}
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 4
    $script:found = [IntPtr]::Zero
    [S13]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    if ($script:found -ne [IntPtr]::Zero) { break }
}
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR 81 window"; exit 1 }
Write-Output "PROJECT81_OPEN"
