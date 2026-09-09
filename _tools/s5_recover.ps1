$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S5R {
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
function Find-TopWindows([string]$regex) {
    $script:hits = @()
    $cb = [S5R+EnumProc]{
        param($h, $lp)
        if ([S5R]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S5R]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:hits += @($h, $t.ToString()) }
        }
        return $true
    }
    [S5R]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:hits
}
function Save-Shot([string]$path) {
    $w = [S5R]::GetSystemMetrics(0); $ht = [S5R]::GetSystemMetrics(1)
    $bmp = New-Object System.Drawing.Bitmap $w, $ht
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# 1. cancel the dialog (wait out the toast overlay)
Start-Sleep -Seconds 6
Invoke-Click 1174 802
Start-Sleep -Seconds 3
Write-Output "DIALOG_CANCEL_CLICKED"

# 2. close main window without saving
$hits = Find-TopWindows "^Quartus Prime Lite Edition"
if ($hits.Count -ge 2) {
    [S5R]::SendMessageW($hits[0], 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    Start-Sleep -Seconds 5
    Write-Output "MAIN_CLOSE_SENT"
}
# 3. screenshot to inspect any save prompt
Save-Shot "D:\FPGA_Lab\_tools\quit_prompt2.png"
Write-Output "PROMPT_SHOT_SAVED"
