$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class SR {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int n);
}
'@
[SR]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Drawing
function Invoke-RightClick([int]$x, [int]$y) {
    [SR]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 200
    [SR]::mouse_event(0x0008, 0, 0, 0, [UIntPtr]::Zero)
    [SR]::mouse_event(0x0010, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 600
}
Invoke-RightClick 150 248
Start-Sleep -Milliseconds 800
$w = [SR]::GetSystemMetrics(0); $ht = [SR]::GetSystemMetrics(1)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\ctx_menu.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "CTX_SHOT"
