$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S14 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
'@
$script:found = [IntPtr]::Zero
$cb = [S14+EnumProc]{
    param($h, $lp)
    if ([S14]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [S14]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "mux81a2223 - mux81a2223") { $script:found = $h; return $false }
    }
    return $true
}
[S14]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }
[S14]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -Milliseconds 1500
[System.Windows.Forms.SendKeys]::SendWait("^o")
Start-Sleep -Milliseconds 2500
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\optional_81mux_verilog\mux81a2223.v")
Start-Sleep -Milliseconds 1000
Invoke-Click 1022 802
Start-Sleep -Seconds 7
& D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex "mux81a2223 - mux81a2223" -OutFile "D:\FPGA_Lab\exp1\optional_81mux_verilog\shots\02_code_mux81a.png"
