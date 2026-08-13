param([string]$Url, [string]$Method, [string]$Params)
Add-Type -AssemblyName System.Net.Http
$c = New-Object System.Net.Http.HttpClient
$c.Timeout = [TimeSpan]::FromSeconds(12)
$body = @{ jsonrpc = "2.0"; id = 1; method = $Method } | ConvertTo-Json
if ($Params) {
  $p = $Params | ConvertFrom-Json
  $b = @{ jsonrpc = "2.0"; id = 1; method = $Method; params = $p } | ConvertTo-Json -Depth 10
  $body = $b
}
$content = New-Object System.Net.Http.StringContent($body, [System.Text.Encoding]::UTF8, "application/json")
try {
  $r = $c.PostAsync($Url, $content).Result
  Write-Output ("STATUS=" + $r.StatusCode)
  $s = $r.Content.ReadAsStringAsync().Result
  if ($s.Length -gt 6000) { $s = $s.Substring(0, 6000) }
  Write-Output $s
} catch {
  Write-Output ("ERR: " + $_.Exception.Message)
}