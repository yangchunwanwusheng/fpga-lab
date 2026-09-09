$ErrorActionPreference = "Stop"
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class FSC {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
}
'@
[FSC]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$script:hw = [IntPtr]::Zero
$cb = [FSC+EnumProc]{
    param($h, $lp)
    if ([FSC]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 512
        [FSC]::GetWindowText($h, $t, 512) | Out-Null
        if ($t.ToString() -match "mux21a0709") { $script:hw = $h; return $false }
    }
    return $true
}
[FSC]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($script:hw -eq [IntPtr]::Zero) { Write-Output "ERR no project window"; exit 1 }
[FSC]::SetForegroundWindow($script:hw) | Out-Null
Start-Sleep -Milliseconds 2500

[System.Windows.Forms.SendKeys]::SendWait("%t")
Start-Sleep -Milliseconds 1500

$w = [FSC]::GetSystemMetrics(0); $ht = [FSC]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\menu_fullscreen.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output ("FULLSHOT " + $w + "x" + $ht)

[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Write-Output "DONE"
