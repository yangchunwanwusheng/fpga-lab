$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S7R {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
}
'@
function Find-TopWindows([string]$regex) {
    $script:hits = @()
    $cb = [S7R+EnumProc]{
        param($h, $lp)
        if ([S7R]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S7R]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:hits += @($h, $t.ToString()) }
        }
        return $true
    }
    [S7R]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:hits
}

# dismiss info dialog: OK at full (1532, 792)
Invoke-Click 1532 792
Start-Sleep -Seconds 2

# close this instance
$hits = Find-TopWindows "^Quartus Prime Lite Edition"
if ($hits.Count -ge 2) { [S7R]::SendMessageW($hits[0], 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null }
Start-Sleep -Seconds 6
Get-Process quartus -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

# relaunch with project only
Start-Process "D:\QP\quartus\bin64\quartus.exe" -ArgumentList '"D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.qpf"'
$deadline = (Get-Date).AddSeconds(150)
$script:found = [IntPtr]::Zero
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 4
    $hits = Find-TopWindows "mux21a2223 - mux21a2223"
    if ($hits.Count -ge 2) { $script:found = $hits[0]; break }
}
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR project window"; exit 1 }
Write-Output "PROJECT_REOPENED"
