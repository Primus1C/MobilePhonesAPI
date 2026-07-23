$rar = Join-Path $env:USERPROFILE 'Desktop\1C config + web.rar'
Write-Output ('RAR=' + $rar)
Write-Output ('EXISTS=' + [IO.File]::Exists($rar))
$seven = 'C:\Program Files\7-Zip\7z.exe'
if ([IO.File]::Exists($seven)) {
    & $seven l $rar
} else {
    Write-Output 'NO_7ZIP'
}
# Try WinRAR
$winrar = 'C:\Program Files\WinRAR\UnRAR.exe'
if ([IO.File]::Exists($winrar)) {
    & $winrar l $rar
}
