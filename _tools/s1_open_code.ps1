$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S1W {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S1W+EnumProc]{
        param($h, $lp)
        if ([S1W]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S1W]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S1W]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

# launch project
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
Start-Sleep -Seconds 5
[S1W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 2000

# open the VHD file via File > Open dialog
[System.Windows.Forms.SendKeys]::SendWait("^o")
Start-Sleep -Milliseconds 2000
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.vhd")
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 6

# capture the editor window
& D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex "mux21a2223\.vhd" -OutFile "D:\FPGA_Lab\exp1\class1_mux21a\shots\02_code_mux21a.png"
