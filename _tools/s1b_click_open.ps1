$ErrorActionPreference = "Stop"
. D:\FPGA_Lab\_tools\ua.ps1
Invoke-Click 1022 802
Start-Sleep -Seconds 6
& D:\FPGA_Lab\_tools\capture2.ps1 -TitleRegex "mux21a2223 - mux21a2223" -OutFile "D:\FPGA_Lab\exp1\class1_mux21a\shots\02_code_mux21a.png"
