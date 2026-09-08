param(
  [Parameter(Mandatory=$true)][string]$InPath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [double]$Gamma = 0.45,
  [float]$Brightness = 1.35
)
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile($InPath)
$bmp = New-Object System.Drawing.Bitmap $src.Width, $src.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)

$ia = New-Object System.Drawing.Imaging.ImageAttributes
$ia.SetGamma($Gamma)

$b = $Brightness
$matrix = New-Object System.Drawing.Imaging.ColorMatrix
$matrix.Matrix00 = $b
$matrix.Matrix11 = $b
$matrix.Matrix22 = $b
$matrix.Matrix33 = 1
$matrix.Matrix44 = 1
$ia.SetColorMatrix($matrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)

$rect = New-Object System.Drawing.Rectangle 0, 0, $src.Width, $src.Height
$g.DrawImage($src, $rect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 90

$bmp.Save($OutPath, $jpegCodec, $encParams)

$g.Dispose()
$bmp.Dispose()
$src.Dispose()
Write-Host "Saved $OutPath"
