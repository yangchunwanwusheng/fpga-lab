$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S12 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S12+EnumProc]{
        param($h, $lp)
        if ([S12]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S12]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S12]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}
$h = Find-TopWindow "^Quartus Prime Lite Edition"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }
[S12]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500
[System.Windows.Forms.SendKeys]::SendWait("%t")
Start-Sleep -Milliseconds 1200
[System.Windows.Forms.SendKeys]::SendWait("p")
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 6
$pw = Find-TopWindow "^Programmer"
if ($pw -ne [IntPtr]::Zero) {
    Write-Output "PROGRAMMER_OPEN"
    & D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex "^Programmer" -OutFile "D:\FPGA_Lab\exp1\class1_mux21a\shots\05_programmer_mux21a.png"
} else {
    Write-Output "PROGRAMMER_NOT_OPEN"
}
