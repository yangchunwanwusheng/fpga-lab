$ErrorActionPreference = "Stop"
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class CL3 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
}
'@
function Close-TopWindow([string]$regex) {
    $cb = [CL3+EnumProc]{
        param($h, $lp)
        if ([CL3]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [CL3]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { [CL3]::SendMessageW($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; return $false }
        }
        return $true
    }
    [CL3]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
}
Close-TopWindow '^Programmer'
Start-Sleep -Seconds 2
& D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex 'drivers' -OutFile 'D:\FPGA_Lab\exp1\class1_mux21a\shots\06_driver_folder.png'
