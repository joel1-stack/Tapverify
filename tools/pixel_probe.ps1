param(
  [string]$Image,
  [string]$Points
)
Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile($Image)
Write-Output "size=$($bmp.Width)x$($bmp.Height)"
foreach ($p in $Points -split ';') {
  $xy = $p -split ','
  $x = [int]$xy[0]; $y = [int]$xy[1]
  $c = $bmp.GetPixel($x, $y)
  Write-Output "$x,$y = #$('{0:X2}{1:X2}{2:X2}' -f $c.R,$c.G,$c.B)"
}
$bmp.Dispose()