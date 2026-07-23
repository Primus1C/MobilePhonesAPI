$d = Join-Path $env:USERPROFILE 'Documents\ConfigCursorNew\docs'
Write-Output ('DIR=' + $d)
Write-Output ('EXISTS=' + [IO.Directory]::Exists($d))
if (-not [IO.Directory]::Exists($d)) { exit 1 }
foreach ($f in [IO.Directory]::GetFiles($d)) {
    $fi = New-Object IO.FileInfo $f
    Write-Output ('FILE=' + $fi.FullName + ' LEN=' + $fi.Length + ' EXT=' + $fi.Extension)
}
# Read any txt that is not Заказы
foreach ($f in [IO.Directory]::GetFiles($d, '*.txt')) {
    Write-Output ('READING=' + $f)
    $bytes = [IO.File]::ReadAllBytes($f)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $text = $utf8.GetString($bytes, 3, $bytes.Length - 3)
    } else {
        $text = $utf8.GetString($bytes)
        if ($text -notmatch '[\u0400-\u04FF]' -and $text -notmatch 'http') {
            $text = [Text.Encoding]::GetEncoding(1251).GetString($bytes)
        }
    }
    Write-Output 'BEGIN_CONTENT'
    Write-Output $text
    Write-Output 'END_CONTENT'
}
