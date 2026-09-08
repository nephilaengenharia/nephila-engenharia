param(
  [Parameter(Mandatory=$true)][string]$InPath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [byte]$InkR = 0x2b,
  [byte]$InkG = 0x2e,
  [byte]$InkB = 0x24
)
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile($InPath)
$w = $src.Width
$h = $src.Height
$rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$bmpData = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $bmpData.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($bmpData.Scan0, $bytes, 0, $bytes.Length)

for ($i = 0; $i -lt $bytes.Length; $i += 4) {
  $b = $bytes[$i]; $g = $bytes[$i+1]; $r = $bytes[$i+2]; $a = $bytes[$i+3]
  if ($a -gt 0) {
    $maxc = [Math]::Max($r, [Math]::Max($g,$b))
    $minc = [Math]::Min($r, [Math]::Min($g,$b))
    if (($maxc - $minc) -lt 25) {
      $bytes[$i]   = $InkB
      $bytes[$i+1] = $InkG
      $bytes[$i+2] = $InkR
    }
  }
}

[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $bmpData.Scan0, $bytes.Length)
$src.UnlockBits($bmpData)

$src.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$src.Dispose()
Write-Host "Saved $OutPath"
