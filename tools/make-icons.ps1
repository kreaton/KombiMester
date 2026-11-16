# Generates the app / home-screen icons for KombiMester: four shiny pegs from the game (red, blue, green
# and yellow) on a white board, with the green "right place" tick from the easy marks.
# Run with Windows PowerShell (System.Drawing):  powershell -File tools\make-icons.ps1
param(
    [string]$OutDir = (Join-Path $PSScriptRoot "..\src\KombiMester\wwwroot\icons"),
    # The front page (KidsGames) shows each game's 512 px icon. Pass its billeder folder once the game
    # is on the front page, e.g. -FrontPageDir ..\KidsGames\billeder
    [string]$FrontPageDir = ""
)

Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Brush([string]$hex) { New-Object System.Drawing.SolidBrush (Color $hex) }

function New-RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# A shiny bead like the pegs in the game: a darker rim at the bottom and a white glint top left.
function Draw-Peg($g, [float]$cx, [float]$cy, [float]$r, [string]$hex, [string]$darkHex) {
    $g.FillEllipse((Brush $darkHex), $cx - $r, $cy - $r, 2 * $r, 2 * $r)
    $g.FillEllipse((Brush $hex), $cx - $r, $cy - $r, 2 * $r, 2 * $r * 0.9)
    $gr = $r * 0.32
    $glint = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(215, 255, 255, 255))
    $g.FillEllipse($glint, $cx - $r * 0.5 - $gr, $cy - $r * 0.48 - $gr * 0.8, 2 * $gr, 1.6 * $gr)
}

# content: 1.0 = full size, 0.78 = keep inside the maskable safe zone
function Draw-Icon([int]$size, [string]$file, [float]$content = 1.0, [bool]$detail = $true) {
    $S = [float]$size
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'

    # Background: the game's lavender-to-pink gradient (full square, iOS applies its own rounded mask)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, 0), (New-Object System.Drawing.PointF 0, $S), (Color '#d0bfff'), (Color '#ffdeeb')
    $g.FillRectangle($bg, 0, 0, $S, $S)

    # The white board, with the game's chunky drop shadow
    $B = $S * 0.74 * $content
    $bx = ($S - $B) / 2
    $by = ($S - $B) / 2 - $S * 0.01 * $content
    $shadow = New-RoundRect $bx ($by + $S * 0.03 * $content) $B $B ($B * 0.2)
    $g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(64, 59, 42, 99))), $shadow)
    $g.FillPath((Brush '#ffffff'), (New-RoundRect $bx $by $B $B ($B * 0.2)))

    # Four pegs, two by two
    $r = $B * 0.19
    $step = $B * 0.25
    $cx = $bx + $B / 2
    $cy = $by + $B / 2
    Draw-Peg $g ($cx - $step) ($cy - $step) $r '#fa5252' '#c92a2a'
    Draw-Peg $g ($cx + $step) ($cy - $step) $r '#339af0' '#1971c2'
    Draw-Peg $g ($cx - $step) ($cy + $step) $r '#51cf66' '#2f9e44'
    Draw-Peg $g ($cx + $step) ($cy + $step) $r '#fcc419' '#e67700'

    if ($detail) {
        # The green tick badge on the yellow peg: "right place"
        $tr = $r * 0.55
        $tx = $cx + $step + $r * 0.72
        $ty = $cy + $step - $r * 0.72
        $g.FillEllipse((Brush '#ffffff'), $tx - $tr * 1.22, $ty - $tr * 1.22, 2.44 * $tr, 2.44 * $tr)
        $g.FillEllipse((Brush '#2f9e44'), $tx - $tr, $ty - $tr, 2 * $tr, 2 * $tr)
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ($tr * 0.32)
        $pen.StartCap = 'Round'
        $pen.EndCap = 'Round'
        $pen.LineJoin = 'Round'
        $tick = [System.Drawing.PointF[]]@(
            (New-Object System.Drawing.PointF ($tx - $tr * 0.48), ($ty + $tr * 0.02)),
            (New-Object System.Drawing.PointF ($tx - $tr * 0.12), ($ty + $tr * 0.4)),
            (New-Object System.Drawing.PointF ($tx + $tr * 0.52), ($ty - $tr * 0.36))
        )
        $g.DrawLines($pen, $tick)
    }

    $g.Dispose()
    $bmp.Save((Join-Path $OutDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $file"
}

Write-Host "Writing icons to $OutDir"
Draw-Icon 180  'apple-touch-icon.png'
Draw-Icon 167  'apple-touch-icon-167.png'
Draw-Icon 152  'apple-touch-icon-152.png'
Draw-Icon 192  'icon-192.png'
Draw-Icon 512  'icon-512.png'
Draw-Icon 1024 'icon-1024.png'
Draw-Icon 512  'icon-512-maskable.png' 0.78
Draw-Icon 32   'favicon-32.png' 1.0 $false

if ($FrontPageDir -and (Test-Path $FrontPageDir)) {
    Copy-Item (Join-Path $OutDir 'icon-512.png') (Join-Path $FrontPageDir 'kombimester.png')
    Write-Host "Copied icon-512.png to $FrontPageDir\kombimester.png"
}
