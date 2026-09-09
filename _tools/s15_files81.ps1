$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class S15 {
    public delegate bool EnumProc(IntPtr h, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
}
'@
Add-Type -AssemblyName System.Drawing
function Find-TopWindow([string]$regex) {
    $script:found = [IntPtr]::Zero
    $cb = [S15+EnumProc]{
        param($h, $lp)
        if ([S15]::IsWindowVisible($h)) {
            $t = New-Object System.Text.StringBuilder 512
            [S15]::GetWindowText($h, $t, 512) | Out-Null
            if ($t.ToString() -match $regex) { $script:found = $h; return $false }
        }
        return $true
    }
    [S15]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:found
}
function Invoke-RightClick([int]$x, [int]$y) {
    [S15]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 200
    [S15]::mouse_event(0x0008, 0, 0, 0, [UIntPtr]::Zero)
    [S15]::mouse_event(0x0010, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 800
}

$h = Find-TopWindow "mux81a2223 - mux81a2223"
if ($h -eq [IntPtr]::Zero) { Write-Output "ERR main"; exit 1 }
[S15]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500

# switch Navigator to Files view
Invoke-Click 300 148
Start-Sleep -Milliseconds 1200
Invoke-Click 216 182
Start-Sleep -Milliseconds 1200

# right-click the .v row and Open
Invoke-RightClick 150 200
Start-Sleep -Milliseconds 500
Invoke-Click 217 265
Start-Sleep -Seconds 8
& D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex "mux81a2223 - mux81a2223" -OutFile "D:\FPGA_Lab\exp1\optional_81mux_verilog\shots\02_code_mux81a.png"
Write-Output "CODE81_DONE"
