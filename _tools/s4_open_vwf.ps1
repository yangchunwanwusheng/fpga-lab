$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S4V {
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
    $cb = [S4V+EnumProc]{
        param($h, $lp)
        if ([S4V]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S4V]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S4V]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}

# close Pin Planner
$pp = Find-TopWindow "^Pin Planner"
if ($pp -ne [IntPtr]::Zero) { [S4V]::SendMessageW($pp, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; Start-Sleep -Seconds 2; Write-Output "PP_CLOSED" }

$h = Find-TopWindow "^Quartus Prime Lite Edition"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }
[S4V]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500

# open vwf via dialog (alt+o activates 打开(O))
[System.Windows.Forms.SendKeys]::SendWait("^o")
Start-Sleep -Milliseconds 2000
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.vwf")
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait("%o")
Start-Sleep -Seconds 6

# capture main window menubar region to locate Simulation menu
$w = [S4V]::GetSystemMetrics(0); $ht = [S4V]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\vwf_open.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "VWF_OPEN_SHOT"
