$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class OPW {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [OPW+EnumProc]{
        param($h, $lp)
        if ([OPW]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [OPW]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [OPW]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

$h = Find-TopWindow "mux21a0709"
if ($h -eq [IntPtr]::Zero) {
    Start-Process "D:\QP\quartus\bin64\quartus.exe" -ArgumentList '"D:\FPGA_Lab\exp1\class1_mux21a\mux21a0709.qpf"'
    $deadline = (Get-Date).AddSeconds(120)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        $h = Find-TopWindow "mux21a0709"
        if ($h -ne [IntPtr]::Zero) { break }
    }
}
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR project window not found"; exit 1 }
Write-Output "PROJECT_WINDOW_OK"
[OPW]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 2000

[System.Windows.Forms.SendKeys]::SendWait("%t")
Start-Sleep -Milliseconds 1000
[System.Windows.Forms.SendKeys]::SendWait("p")
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 5

$pw = Find-TopWindow "Programmer"
if ($pw -ne [IntPtr]::Zero) { Write-Output "PROGRAMMER_OPEN" } else { Write-Output "PROGRAMMER_NOT_OPEN" }
