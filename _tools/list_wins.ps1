$ErrorActionPreference = "Stop"
Add-Type @'
using System;
using System.Text;
using System.Collections;
using System.Runtime.InteropServices;
public class LW4 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
'@
$list = New-Object System.Collections.ArrayList
$cb = [LW4+EnumProc]{
    param($h, $lp)
    if ([LW4]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [LW4]::GetWindowText($h, $t, 512) | Out-Null
        $s = $t.ToString()
        if ($s.Trim().Length -gt 3) { [void]$list.Add($s) }
    }
    return $true
}
[LW4]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
$list | Sort-Object -Unique
