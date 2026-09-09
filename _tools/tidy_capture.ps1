$ErrorActionPreference = "Stop"
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class TIDY {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
}
'@
$script:titles = New-Object System.Collections.ArrayList
function Get-TopWindows([string]$regex) {
    $script:list = New-Object System.Collections.ArrayList
    $cb = [TIDY+EnumProc]{
        param($h, $lp)
        if ([TIDY]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [TIDY]::GetWindowText($h, $t, 512) | Out-Null
            $title = $t.ToString()
            if ($title -match $regex) { [void]$script:list.Add(@($h, $title)) }
        }
        return $true
    }
    [TIDY]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:list
}

Write-Output "--- windows matching 'drivers':"
(Get-TopWindows 'drivers') | ForEach-Object { Write-Output ("  hwnd=" + $_[0] + " title=[" + $_[1] + "]") }

Write-Output "--- minimizing Quartus windows:"
(Get-TopWindows 'Quartus Prime') | ForEach-Object {
    Write-Output ("  min hwnd=" + $_[0] + " title=[" + $_[1] + "]")
    [TIDY]::ShowWindow($_[0], 6) | Out-Null
}
Start-Sleep -Seconds 3
& D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex 'drivers' -OutFile 'D:\FPGA_Lab\exp1\class1_mux21a\shots\06_driver_folder.png'
