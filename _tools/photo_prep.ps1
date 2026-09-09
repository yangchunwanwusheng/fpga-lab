$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class PP1 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [PP1+EnumProc]{
        param($h, $lp)
        if ([PP1]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [PP1]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [PP1]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

# 1. launch project (fresh after reboot)
Start-Process "D:\QP\quartus\bin64\quartus.exe" -ArgumentList '"D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.qpf"'
$deadline = (Get-Date).AddSeconds(150)
$h = [IntPtr]::Zero
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 4
    $h = Find-TopWindow "mux21a2223 - mux21a2223"
    if ($h -ne [IntPtr]::Zero) { break }
}
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR project window"; exit 1 }
Write-Output "PROJECT_OPEN"
[PP1]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 2000

# 2. Tools > Programmer
[System.Windows.Forms.SendKeys]::SendWait("%t")
Start-Sleep -Milliseconds 1200
[System.Windows.Forms.SendKeys]::SendWait("p")
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 6
$pw = Find-TopWindow "^Programmer"
if ($pw -eq [IntPtr]::Zero) { Write-Output "ERR programmer"; exit 1 }
Write-Output "PROGRAMMER_OPEN"

# 3. click Start (Start button at window-relative ~(130, 272), physical pixels)
$r = New-Object PP1+RECT
[PP1]::GetWindowRect($pw, [ref]$r) | Out-Null
Write-Output ("PROG_RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)
Invoke-Click ($r.Left + 130) ($r.Top + 272)
Write-Output "START_CLICKED"
Start-Sleep -Seconds 12
Write-Output "DONE"
