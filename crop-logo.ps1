param(
  [Parameter(Mandatory=$true)][string]$InPath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [int]$MaxWidth = 900
)
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile($InPath)
$w = $src.Width
$h = $src.Height

$rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$bmpData = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $bmpData.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($bmpData.Scan0, $bytes, 0, $bytes.Length)
$src.UnlockBits($bmpData)

$minX = $w; $maxX = 0; $minY = $h; $maxY = 0
$stepY = [Math]::Max(1, [int]($h / 800))
$stepX = [Math]::Max(1, [int]($w / 800))

for ($y = 0; $y -lt $h; $y += $stepY) {
  $rowOffset = $y * $stride
  for ($x = 0; $x -lt $w; $x += $stepX) {
    $alpha = $bytes[$rowOffset + $x*4 + 3]
    if ($alpha -gt 10) {
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}

# refine with finer step near the found bounds
$pad = 20
$minX = [Math]::Max(0, $minX - $pad)
$minY = [Math]::Max(0, $minY - $pad)
$maxX = [Math]::Min($w-1, $maxX + $pad)
$maxY = [Math]::Min($h-1, $maxY + $pad)

Write-Host "Bounds: x=$minX-$maxX y=$minY-$maxY"

$cropW = $maxX - $minX
$cropH = $maxY - $minY
$cropRect = New-Object System.Drawing.Rectangle $minX, $minY, $cropW, $cropH
$cropped = $src.Clone($cropRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$src.Dispose()

$scale = [Math]::Min(1.0, $MaxWidth / $cropped.Width)
$newW = [int]([Math]::Round($cropped.Width * $scale))
$newH = [int]([Math]::Round($cropped.Height * $scale))

$out = New-Object System.Drawing.Bitmap $newW, $newH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($cropped, 0, 0, $newW, $newH)
$g.Dispose()
$cropped.Dispose()

$out.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
Write-Host "Saved $OutPath ($newW x $newH)"
