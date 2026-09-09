$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S2W {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S2W+EnumProc]{
        param($h, $lp)
        if ([S2W]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S2W]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S2W]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

$h = Find-TopWindow "mux21a2223 - mux21a2223"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main window"; exit 1 }
[S2W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500

[System.Windows.Forms.SendKeys]::SendWait("%t")
Start-Sleep -Milliseconds 1200
[System.Windows.Forms.SendKeys]::SendWait("v")
Start-Sleep -Milliseconds 1000
[System.Windows.Forms.SendKeys]::SendWait("r")
Start-Sleep -Seconds 6

$rtl = Find-TopWindow "RTL Viewer"
if ($rtl -ne [IntPtr]::Zero) {
    Write-Output "RTL_OPEN"
    Start-Sleep -Seconds 3
    & D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex "RTL Viewer" -OutFile "D:\FPGA_Lab\exp1\class1_mux21a\shots\01_rtl_mux21a.png"
} else {
    Write-Output "RTL_NOT_OPEN"
}
