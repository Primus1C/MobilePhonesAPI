$dir = Join-Path $env:USERPROFILE 'Desktop'
$rar = $null
foreach ($f in [IO.Directory]::GetFiles($dir, '*.rar')) { $rar = $f }
Write-Output ('RAR=' + $rar)
$out = Join-Path $env:USERPROFILE 'Documents\ConfigCursorNew\tools\web_rar_extract'
if (-not [IO.Directory]::Exists($out)) { [IO.Directory]::CreateDirectory($out) | Out-Null }

# Try tar (bsdtar sometimes opens rar)
$tar = Get-Command tar -ErrorAction SilentlyContinue
if ($tar) {
    Write-Output 'TRY_TAR'
    & tar -tf $rar 2>&1 | Select-Object -First 40
}

# Try Expand-Archive (won't work for rar usually)
# Look for unrar/7z in common paths
$candidates = @(
    'C:\Program Files\7-Zip\7z.exe',
    'C:\Program Files (x86)\7-Zip\7z.exe',
    'C:\Program Files\WinRAR\UnRAR.exe',
    'C:\Program Files\WinRAR\WinRAR.exe',
    'C:\Program Files (x86)\WinRAR\UnRAR.exe'
)
foreach ($c in $candidates) {
    if ([IO.File]::Exists($c)) { Write-Output ('FOUND_TOOL=' + $c) }
}

# Copy rar to ASCII path for easier tool usage
$copy = Join-Path $out 'webconfig.rar'
[IO.File]::Copy($rar, $copy, $true)
Write-Output ('COPIED=' + $copy + ' SIZE=' + (New-Object IO.FileInfo $copy).Length)
