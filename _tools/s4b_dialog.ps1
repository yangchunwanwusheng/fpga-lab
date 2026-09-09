$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class S4D { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n); }
'@
[S4D]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

Invoke-Click 610 760
Start-Sleep -Milliseconds 400
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("{DEL}")
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.vwf")
Start-Sleep -Milliseconds 800
Invoke-Click 1022 802
Start-Sleep -Seconds 7

$w = [S4D]::GetSystemMetrics(0); $ht = [S4D]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\vwf_open2.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "DONE"
