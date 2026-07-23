$dir = Join-Path $env:USERPROFILE 'Downloads'
$files = [System.IO.Directory]::GetFiles($dir)
Write-Output ('DIR=' + $dir)
Write-Output ('FILE_COUNT=' + $files.Length)
Write-Output 'ALL_TXT='
$txt = @()
foreach ($f in $files) {
    if ($f.ToLower().EndsWith('.txt')) {
        Write-Output $f
        $txt += $f
    }
}
if ($txt.Length -eq 0) {
    Write-Output 'NO_TXT_FILES'
    exit 1
}
# Prefer file whose name length matches TestWebhook-like Cyrillic name (~15 chars + .txt)
$preferred = $null
foreach ($f in $txt) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($f)
    if ($base.Length -ge 10 -and $base.Length -le 16) {
        $preferred = $f
        break
    }
}
if (-not $preferred) { $preferred = $txt[0] }
Write-Output ('READING=' + $preferred)
$bytes = [System.IO.File]::ReadAllBytes($preferred)
$enc1251 = [System.Text.Encoding]::GetEncoding(1251)
$encUtf8 = New-Object System.Text.UTF8Encoding $false
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $text = $encUtf8.GetString($bytes, 3, $bytes.Length - 3)
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $text = [System.Text.Encoding]::Unicode.GetString($bytes)
} else {
    $textUtf8 = $encUtf8.GetString($bytes)
    $text1251 = $enc1251.GetString($bytes)
    if ($textUtf8 -match '[\u0400-\u04FF]' -and $textUtf8 -notmatch '\uFFFD') {
        $text = $textUtf8
    } elseif ($text1251 -match '[\u0400-\u04FF]') {
        $text = $text1251
    } else {
        $text = $textUtf8
    }
}
Write-Output 'BEGIN_CONTENT'
Write-Output $text
Write-Output 'END_CONTENT'
