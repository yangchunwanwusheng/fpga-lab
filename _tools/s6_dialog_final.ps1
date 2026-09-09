$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class S6D { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n); }
'@
[S6D]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
function Save-Shot([string]$path) {
    $w = [S6D]::GetSystemMetrics(0); $ht = [S6D]::GetSystemMetrics(1)
    $bmp = New-Object System.Drawing.Bitmap $w, $ht
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# click the filename field and type
Invoke-Click 500 760
Start-Sleep -Milliseconds 600
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.vwf")
Start-Sleep -Milliseconds 900
Save-Shot "D:\FPGA_Lab\_tools\dlg_typed.png"
Write-Output "TYPED_SHOT_SAVED"
