$ErrorActionPreference = "Stop"
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class MNU {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
[MNU]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

function Find-WindowsByClass([string]$cls) {
    $script:out = @()
    $cb = [MNU+EnumProc]{
        param($h, $lp)
        if ([MNU]::IsWindowVisible($h)) {
            $c = New-Object System.Text.StringBuilder 256
            [MNU]::GetClassName($h, $c, 256) | Out-Null
            if ($c.ToString() -eq $cls) {
                $t = New-Object System.Text.StringBuilder 512
                [MNU]::GetWindowText($h, $t, 512) | Out-Null
                $script:out += @($h, $t.ToString())
            }
        }
        return $true
    }
    [MNU]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:out
}
function Find-WindowsByTitle([string]$regex) {
    $script:out2 = @()
    $cb = [MNU+EnumProc]{
        param($h, $lp)
        if ([MNU]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [MNU]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:out2 += @($h, $t.ToString()) }
        }
        return $true
    }
    [MNU]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:out2
}

# 1. ensure mux21a project window exists
$h = [IntPtr]::Zero
$hits = Find-WindowsByTitle "mux21a0709"
if ($hits.Count -ge 2) { $h = $hits[0] }
else {
    Start-Process "D:\QP\quartus\bin64\quartus.exe" -ArgumentList '"D:\FPGA_Lab\exp1\class1_mux21a\mux21a0709.qpf"'
    $deadline = (Get-Date).AddSeconds(150)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 4
        $hits = Find-WindowsByTitle "mux21a0709"
        if ($hits.Count -ge 2) { $h = $hits[0]; break }
    }
}
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR no project window"; exit 1 }
Write-Output "PROJECT_WINDOW_OK"
[MNU]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 2500

# 2. open Tools menu
[System.Windows.Forms.SendKeys]::SendWait("%t")
Start-Sleep -Milliseconds 1500

# 3. find popup menu windows (#32768), capture the largest
$menus = Find-WindowsByClass "#32768"
if ($menus.Count -lt 2) { Write-Output "ERR no popup menu found"; [System.Windows.Forms.SendKeys]::SendWait("{ESC}"); exit 1 }
$best = [IntPtr]::Zero; $bestArea = 0
for ($i = 0; $i -lt $menus.Count; $i += 2) {
    $r = New-Object MNU+RECT
    [MNU]::GetWindowRect($menus[$i], [ref]$r) | Out-Null
    $area = ($r.Right - $r.Left) * ($r.Bottom - $r.Top)
    Write-Output ("menu hwnd area=" + $area)
    if ($area -gt $bestArea) { $bestArea = $area; $best = $menus[$i] }
}
$r = New-Object MNU+RECT
[MNU]::GetWindowRect($best, [ref]$r) | Out-Null
$w = $r.Right - $r.Left; $ht = $r.Bottom - $r.Top
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
$bmp.Save("D:\FPGA_Lab\_tools\tools_menu_clean.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output ("SAVED tools_menu_clean.png " + $w + "x" + $ht)

# 4. close menu, then close this extra Quartus instance
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Start-Sleep -Milliseconds 800
$hits = Find-WindowsByTitle "mux21a0709"
if ($hits.Count -ge 2) { [MNU]::SendMessageW($hits[0], 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null }
Write-Output "CLEANUP_DONE"
