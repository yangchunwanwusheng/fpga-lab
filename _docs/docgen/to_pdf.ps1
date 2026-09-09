$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.DisplayAlerts = 0
$word.Visible = $false
try {
    $doc = $word.Documents.Open("D:\FPGA_Lab\_docs\exp1_class1_bench_guide.docx", $false, $true)
    $doc.FieldsUpdate() | Out-Null
} catch { Write-Output "note: field update skipped - $($_.Exception.Message)" }
$doc.SaveAs([ref]"D:\FPGA_Lab\_docs\exp1_class1_bench_guide.pdf", [ref]17)
$doc.Close($false)
$word.Quit()
Write-Output "PDF_DONE"
