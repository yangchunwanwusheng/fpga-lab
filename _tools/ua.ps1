# ua.ps1 - minimal UI automation helpers (physical pixels, DPI aware)
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class UA {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
    [DllImport("user32.dll")] public static extern IntPtr FindWindowW(string cls, string title);
    public struct RECT { public int Left, Top, Right, Bottom; }
    public const uint LEFTDOWN = 0x0002;
    public const uint LEFTUP = 0x0004;
}
'@
Add-Type -AssemblyName System.Windows.Forms
[UA]::SetProcessDPIAware() | Out-Null

function Get-ProcWindow([string]$TitleRegex) {
    $p = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -match $TitleRegex } | Select-Object -First 1
    return $p
}

function Invoke-Activate([string]$TitleRegex) {
    $p = Get-ProcWindow $TitleRegex
    if (-not $p) { Write-Output "ERR no window $TitleRegex"; return $false }
    [UA]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 500
    return $true
}

function Get-Rect([string]$TitleRegex) {
    $p = Get-ProcWindow $TitleRegex
    if (-not $p) { Write-Output "ERR no window $TitleRegex"; return }
    $r = New-Object UA+RECT
    [UA]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
    Write-Output ("RECT " + $r.Left + " " + $r.Top + " " + $r.Right + " " + $r.Bottom)
}

function Invoke-Click([int]$x, [int]$y, [int]$double = 0) {
    [UA]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 120
    [UA]::mouse_event([UA]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
    [UA]::mouse_event([UA]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
    if ($double -eq 1) {
        Start-Sleep -Milliseconds 90
        [UA]::mouse_event([UA]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
        [UA]::mouse_event([UA]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
    }
    Start-Sleep -Milliseconds 250
}

function Invoke-SendKeys([string]$text) {
    [System.Windows.Forms.SendKeys]::SendWait($text)
    Start-Sleep -Milliseconds 250
}
