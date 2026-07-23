$dir = Join-Path $env:USERPROFILE 'Desktop'
Write-Output ('DIR=' + $dir)
foreach ($f in [IO.Directory]::GetFiles($dir)) {
    $fi = New-Object IO.FileInfo $f
    Write-Output ($fi.Name + ' | ' + $fi.Length + ' | ' + $fi.Extension)
}
Write-Output 'DOWNLOADS='
$dir2 = Join-Path $env:USERPROFILE 'Downloads'
foreach ($f in [IO.Directory]::GetFiles($dir2)) {
    $fi = New-Object IO.FileInfo $f
    Write-Output ($fi.Name + ' | ' + $fi.Length + ' | ' + $fi.Extension)
}
