$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S9O {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
Add-Type -AssemblyName System.Windows.Forms
function Find-TopWindows([string]$regex) {
    $script:hits = @()
    $cb = [S9O+EnumProc]{
        param($h, $lp)
        if ([S9O]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S9O]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:hits += @($h, $t.ToString()) }
        }
        return $true
    }
    [S9O]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:hits
}
$hits = Find-TopWindows "^Quartus Prime Lite Edition"
if ($hits.Count -lt 2) { Write-Output "ERR main"; exit 1 }
[S9O]::SetForegroundWindow($hits[0]) | Out-Null
Start-Sleep -Milliseconds 1500
[System.Windows.Forms.SendKeys]::SendWait("^o")
Start-Sleep -Milliseconds 2500
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.vwf")
Start-Sleep -Milliseconds 1000
# click Open
Invoke-Click 1022 802
Start-Sleep -Seconds 8
Write-Output "OPEN_CLICKED"
