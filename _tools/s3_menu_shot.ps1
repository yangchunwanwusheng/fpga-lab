$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S3W {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
}
'@
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S3W+EnumProc]{
        param($h, $lp)
        if ([S3W]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S3W]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S3W]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}
$h = Find-TopWindow "mux21a2223 - mux21a2223"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main window"; exit 1 }
[S3W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500
[System.Windows.Forms.SendKeys]::SendWait("%s")
Start-Sleep -Milliseconds 1500
$w = [S3W]::GetSystemMetrics(0); $ht = [S3W]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\assign_menu2.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Write-Output "MENU_SHOT_SAVED"
