$roots = @(
    (Join-Path $env:USERPROFILE 'Downloads'),
    (Join-Path $env:USERPROFILE 'Desktop'),
    (Join-Path $env:USERPROFILE 'Documents'),
    (Join-Path $env:USERPROFILE 'OneDrive\Downloads'),
    (Join-Path $env:USERPROFILE 'OneDrive\Desktop'),
    'C:\Users\Public\Downloads'
)
foreach ($dir in $roots) {
    if (-not [System.IO.Directory]::Exists($dir)) {
        Write-Output ('MISSING=' + $dir)
        continue
    }
    Write-Output ('SCAN=' + $dir)
    $files = [System.IO.Directory]::GetFiles($dir)
    foreach ($f in $files) {
        $name = [System.IO.Path]::GetFileName($f)
        $ext = [System.IO.Path]::GetExtension($f).ToLower()
        if ($ext -eq '.txt' -or $ext -eq '.docx' -or $ext -eq '.md' -or $name.ToLower().Contains('web') -or $name.ToLower().Contains('hook')) {
            Write-Output ('FILE=' + $f + ' LEN=' + (New-Object IO.FileInfo $f).Length)
        }
    }
}
# Also search Documents\ConfigCursorNew for the file
$proj = Join-Path $env:USERPROFILE 'Documents\ConfigCursorNew'
if ([System.IO.Directory]::Exists($proj)) {
    $found = [System.IO.Directory]::GetFiles($proj, '*.txt', [IO.SearchOption]::AllDirectories) | Where-Object {
        $n = [IO.Path]::GetFileName($_)
        $n.Length -ge 8 -and $n.Length -le 30 -and $_.ToLower().EndsWith('.txt')
    } | Select-Object -First 30
    Write-Output 'PROJECT_TXT_CANDIDATES='
    foreach ($f in $found) { Write-Output $f }
}
