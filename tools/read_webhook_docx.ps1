$docs = Join-Path $env:USERPROFILE 'Documents\ConfigCursorNew\docs'
$docx = $null
foreach ($f in [IO.Directory]::GetFiles($docs, '*.docx')) { $docx = $f }
Write-Output ('DOCX=' + $docx)
$tmp = Join-Path $env:TEMP ('webhook_docx_' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($tmp) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($docx, $tmp)
$xmlPath = Join-Path $tmp 'word\document.xml'
$xml = [IO.File]::ReadAllText($xmlPath, [Text.Encoding]::UTF8)
# Split on paragraph ends
$xml = $xml -replace '</w:p>', "`n"
$xml = $xml -replace '</w:tr>', "`n"
$xml = $xml -replace '<w:tab[^/]*/>', "`t"
$xml = $xml -replace '<w:br[^/]*/>', "`n"
$xml = [regex]::Replace($xml, '<[^>]+>', '')
$xml = [System.Net.WebUtility]::HtmlDecode($xml)
$lines = $xml -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
Write-Output 'BEGIN_CONTENT'
$lines -join "`n"
Write-Output 'END_CONTENT'
[IO.Directory]::Delete($tmp, $true)
