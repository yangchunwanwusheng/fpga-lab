$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S3C {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
}
'@
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S3C+EnumProc]{
        param($h, $lp)
        if ([S3C]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S3C]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S3C]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

# close RTL Viewer window (screenshot already taken)
$rtl = Find-TopWindow "^RTL Viewer"
if ($rtl -ne [IntPtr]::Zero) { [S3C]::SendMessageW($rtl, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; Start-Sleep -Seconds 2; Write-Output "RTL_CLOSED" }

$h = Find-TopWindow "^Quartus Prime Lite Edition"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main window"; exit 1 }
[S3C]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500
[System.Windows.Forms.SendKeys]::SendWait("%s")
Start-Sleep -Milliseconds 1500
$w = [S3C]::GetSystemMetrics(0); $ht = [S3C]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\assign_menu3.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Write-Output "MENU_SHOT2_SAVED"
