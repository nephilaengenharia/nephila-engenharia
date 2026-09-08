param(
  [Parameter(Mandatory=$true)][string]$InPath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [int]$MaxDim = 1600,
  [double]$Gamma = 1.0,
  [double]$Brightness = 1.0,
  [long]$Quality = 85
)
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile($InPath)

$scale = [Math]::Min(1.0, $MaxDim / [Math]::Max($src.Width, $src.Height))
$newW = [int]([Math]::Round($src.Width * $scale))
$newH = [int]([Math]::Round($src.Height * $scale))

$bmp = New-Object System.Drawing.Bitmap $newW, $newH
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$ia = New-Object System.Drawing.Imaging.ImageAttributes
if ($Gamma -ne 1.0) { $ia.SetGamma($Gamma) }
if ($Brightness -ne 1.0) {
  $b = $Brightness
  $matrix = New-Object System.Drawing.Imaging.ColorMatrix
  $matrix.Matrix00 = $b
  $matrix.Matrix11 = $b
  $matrix.Matrix22 = $b
  $matrix.Matrix33 = 1
  $matrix.Matrix44 = 1
  $ia.SetColorMatrix($matrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)
}

$rect = New-Object System.Drawing.Rectangle 0, 0, $newW, $newH
$g.DrawImage($src, $rect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), $Quality

$bmp.Save($OutPath, $jpegCodec, $encParams)

$g.Dispose()
$bmp.Dispose()
$src.Dispose()
Write-Host "Saved $OutPath ($newW x $newH)"
