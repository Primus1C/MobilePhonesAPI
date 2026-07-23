$path = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-Documents-ConfigCursorNewNew\agent-transcripts\7ba35c0b-115d-4689-8974-629e3bd5ddbf\7ba35c0b-115d-4689-8974-629e3bd5ddbf.jsonl'
$out = Join-Path $env:USERPROFILE 'Documents\ConfigCursorNew\tools\webhook_plan_extract.txt'
$lines = Get-Content -LiteralPath $path -Encoding UTF8
$sb = New-Object System.Text.StringBuilder
# Known line numbers from earlier grep (1-based): 584, 586, 605, 624
$nums = @(584, 586, 605, 610, 624, 626)
foreach ($n in $nums) {
    if ($n -lt 1 -or $n -gt $lines.Count) { continue }
    $line = $lines[$n - 1]
    [void]$sb.AppendLine(('=== LINE ' + $n + ' ==='))
    $marker = '"text":"'
    $pos = $line.IndexOf($marker)
    if ($pos -ge 0) {
        $chunk = $line.Substring($pos + $marker.Length)
        $end2 = $chunk.IndexOf('"},{"')
        if ($end2 -lt 0) { $end2 = $chunk.IndexOf('"}]},') }
        if ($end2 -lt 0) { $end2 = [Math]::Min(15000, $chunk.Length) }
        $t = $chunk.Substring(0, $end2)
        $t = $t.Replace('\n', "`r`n").Replace('\"', '"').Replace('\t', ' ')
        [void]$sb.AppendLine($t)
    } else {
        [void]$sb.AppendLine($line.Substring(0, [Math]::Min(2000, $line.Length)))
    }
    [void]$sb.AppendLine('')
}
[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object System.Text.UTF8Encoding $true))
Write-Output ('WROTE=' + $out)
