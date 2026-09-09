$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class PP2 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
}
'@
Add-Type -AssemblyName System.Drawing
$script:found = [IntPtr]::Zero
$cb = [PP2+EnumProc]{
    param($h, $lp)
    if ([PP2]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [PP2]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "^Quartus Prime Lite Edition") { $script:found = $h; return $false }
    }
    return $true
}
[PP2]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($script:found -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }
[PP2]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -Milliseconds 1500
Invoke-Click 528 46
Start-Sleep -Milliseconds 1500
$w = [PP2]::GetSystemMetrics(0); $ht = [PP2]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\tools_menu_now.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "MENU_SHOT"
