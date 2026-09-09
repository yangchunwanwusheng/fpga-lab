$ErrorActionPreference = "Stop"
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class CLUP {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
}
'@
$script:hits = @()
function Find-Windows([string]$regex) {
    $script:hits = @()
    $cb = [CLUP+EnumProc]{
        param($h, $lp)
        if ([CLUP]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [CLUP]::GetWindowText($h, $t, 512) | Out-Null
            $title = $t.ToString()
            if ($title -match $regex) { $script:hits += @($h, $title) }
        }
        return $true
    }
    [CLUP]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:hits
}

# close the mux21a Quartus instance main window (opened only for capture)
Find-Windows 'mux21a0709' | Out-Null
if ($script:hits.Count -ge 2) {
    Write-Output ("closing: " + $script:hits[1])
    [CLUP]::SendMessageW($script:hits[0], 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    Start-Sleep -Seconds 4
}
# close the Explorer 'drivers' window
Find-Windows '^drivers$' | Out-Null
if ($script:hits.Count -ge 2) {
    Write-Output ("closing: " + $script:hits[1])
    [CLUP]::SendMessageW($script:hits[0], 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    Start-Sleep -Seconds 2
}
# restore the original mux81a Quartus window
Find-Windows 'mux81a0709' | Out-Null
if ($script:hits.Count -ge 2) {
    Write-Output ("restoring: " + $script:hits[1])
    [CLUP]::ShowWindow($script:hits[0], 9) | Out-Null
}
Start-Sleep -Seconds 2
Write-Output "--- remaining quartus processes:"
Get-Process quartus -ErrorAction SilentlyContinue | ForEach-Object { Write-Output ("  pid=" + $_.Id + " title=[" + $_.MainWindowTitle + "]") }
