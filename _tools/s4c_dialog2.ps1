$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class S4E { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
'@
[S4E]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Windows.Forms

# focus the filename field
Invoke-Click 500 760
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{END}")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("+{HOME}")
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("{DEL}")
Start-Sleep -Milliseconds 400
[System.Windows.Forms.SendKeys]::SendWait("D:\FPGA_Lab\exp1\class1_mux21a\mux21a2223.vwf")
Start-Sleep -Milliseconds 900
# click Open button
Invoke-Click 1022 802
Start-Sleep -Seconds 7
Write-Output "RETRY_DONE"
