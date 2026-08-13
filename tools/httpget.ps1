param([string]$Url)
Add-Type -AssemblyName System.Net.Http
$c = New-Object System.Net.Http.HttpClient
$c.Timeout = [TimeSpan]::FromSeconds(10)
try {
  $r = $c.GetAsync($Url).Result
  Write-Output ("STATUS=" + $r.StatusCode)
  $s = $r.Content.ReadAsStringAsync().Result
  if ($s.Length -gt 2000000) { $s = $s.Substring(0, 2000000) }
  Write-Output $s
} catch {
  Write-Output ("ERR: " + $_.Exception.Message)
}