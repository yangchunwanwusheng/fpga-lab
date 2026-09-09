$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.DisplayAlerts = 0
$word.Visible = $false
$doc = $word.Documents.Open("D:\FPGA_Lab\_docs\exp1_class1_bench_guide.docx")
foreach ($toc in $doc.TablesOfContents) { $toc.Update() | Out-Null }
$doc.Fields.Update() | Out-Null
$doc.SaveAs([ref]"D:\FPGA_Lab\_docs\exp1_class1_bench_guide.pdf", [ref]17)
$doc.Save()
$doc.Close($false)
$word.Quit()
Write-Output "PDF_DONE_UPDATED"
