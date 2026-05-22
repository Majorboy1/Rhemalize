Add-Type -AssemblyName System.Drawing

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Base = Join-Path $Root 'store_assets\google_play'
$Logo = Join-Path $Root 'assets\images\rhema-logo.png'

$Sources = @(
    @{
        Name = '01-login'
        Title = 'Simple sign in'
        Subtitle = 'Continue with Google and start listening.'
        Path = 'c:\Users\ASUS\Pictures\Rhemalize\Mockup\1.PNG'
    },
    @{
        Name = '02-profile'
        Title = 'Track your growth'
        Subtitle = 'See heard messages, streaks, history, and account tools.'
        Path = 'c:\Users\ASUS\Pictures\Rhemalize\Mockup\localhost_52051_(iPhone 12 Pro) (1).png'
    },
    @{
        Name = '03-player-alt'
        Title = 'Focused audio player'
        Subtitle = 'Control playback, favorites, queue, and speed.'
        Path = 'c:\Users\ASUS\Pictures\Rhemalize\Mockup\localhost_52051_(iPhone 12 Pro) (2).png'
    },
    @{
        Name = '04-player'
        Title = 'Sermons that keep playing'
        Subtitle = 'Listen with progress, queue, and background controls.'
        Path = 'c:\Users\ASUS\Pictures\Rhemalize\Mockup\localhost_52051_(iPhone 12 Pro) (3).png'
    },
    @{
        Name = '05-up-next'
        Title = 'Manage what plays next'
        Subtitle = 'Browse the queue and jump into the next message.'
        Path = 'c:\Users\ASUS\Pictures\Rhemalize\Mockup\localhost_52051_(iPhone 12 Pro) (4).png'
    },
    @{
        Name = '06-home'
        Title = 'A calm daily feed'
        Subtitle = 'Continue listening and discover today''s spotlight.'
        Path = 'c:\Users\ASUS\Pictures\Rhemalize\Mockup\localhost_52051_(iPhone 12 Pro) (5).png'
    }
)

foreach ($Directory in @('tablet_7_inch', 'tablet_10_inch', 'chromebook', 'android_xr')) {
    $Path = Join-Path $Base $Directory
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in '.jpg', '.jpeg', '.png' } |
        Remove-Item -Force
}

function Save-Jpeg($Bitmap, $Path, [long]$Quality = 94) {
    $Codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.MimeType -eq 'image/jpeg' }
    $Params = [System.Drawing.Imaging.EncoderParameters]::new(1)
    $Params.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
        [System.Drawing.Imaging.Encoder]::Quality,
        $Quality
    )
    $Bitmap.Save($Path, $Codec, $Params)
    $Params.Dispose()
}

function New-Canvas($Width, $Height, $Color) {
    $Bitmap = [System.Drawing.Bitmap]::new(
        $Width,
        $Height,
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    )
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $Graphics.Clear([System.Drawing.ColorTranslator]::FromHtml($Color))
    return @($Bitmap, $Graphics)
}

function Draw-ImageCover($Graphics, $Image, $X, $Y, $Width, $Height) {
    $Scale = [Math]::Max($Width / $Image.Width, $Height / $Image.Height)
    $SourceWidth = $Width / $Scale
    $SourceHeight = $Height / $Scale
    $SourceX = ($Image.Width - $SourceWidth) / 2
    $SourceY = ($Image.Height - $SourceHeight) / 2
    $Graphics.DrawImage(
        $Image,
        [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height),
        [System.Drawing.RectangleF]::new($SourceX, $SourceY, $SourceWidth, $SourceHeight),
        [System.Drawing.GraphicsUnit]::Pixel
    )
}

function Draw-ImageContain($Graphics, $Image, $X, $Y, $Width, $Height) {
    $Scale = [Math]::Min($Width / $Image.Width, $Height / $Image.Height)
    $DrawWidth = $Image.Width * $Scale
    $DrawHeight = $Image.Height * $Scale
    $DrawX = $X + (($Width - $DrawWidth) / 2)
    $DrawY = $Y + (($Height - $DrawHeight) / 2)
    $Graphics.DrawImage($Image, [System.Drawing.RectangleF]::new($DrawX, $DrawY, $DrawWidth, $DrawHeight))
}

function Fill-RoundRect($Graphics, $X, $Y, $Width, $Height, $Radius, $Color) {
    $Brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Color))
    if ($Radius -le 0) {
        $Graphics.FillRectangle($Brush, $X, $Y, $Width, $Height)
    } else {
        $Path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $Diameter = $Radius * 2
        $Path.AddArc($X, $Y, $Diameter, $Diameter, 180, 90)
        $Path.AddArc($X + $Width - $Diameter, $Y, $Diameter, $Diameter, 270, 90)
        $Path.AddArc($X + $Width - $Diameter, $Y + $Height - $Diameter, $Diameter, $Diameter, 0, 90)
        $Path.AddArc($X, $Y + $Height - $Diameter, $Diameter, $Diameter, 90, 90)
        $Path.CloseFigure()
        $Graphics.FillPath($Brush, $Path)
        $Path.Dispose()
    }
    $Brush.Dispose()
}

function Draw-Text($Graphics, $Text, $X, $Y, $Width, $Height, $Size, $Color, $Bold = $false) {
    $Style = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $Font = [System.Drawing.Font]::new('Segoe UI', $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
    $Brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Color))
    $Format = [System.Drawing.StringFormat]::new()
    $Format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
    $Graphics.DrawString($Text, $Font, $Brush, [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height), $Format)
    $Format.Dispose()
    $Brush.Dispose()
    $Font.Dispose()
}

function New-PortraitAsset($Source, $TargetDirectory) {
    $Image = [System.Drawing.Image]::FromFile($Source.Path)
    $Pair = New-Canvas 1440 2560 '#F7F8FC'
    $Bitmap = $Pair[0]
    $Graphics = $Pair[1]

    Draw-ImageCover $Graphics $Image 0 0 1440 2560
    $Wash = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(208, 248, 249, 252))
    $Graphics.FillRectangle($Wash, 0, 0, 1440, 2560)
    $Wash.Dispose()

    Fill-RoundRect $Graphics 94 34 1252 2492 44 '#FFFFFF'
    Draw-ImageContain $Graphics $Image 118 58 1204 2444

    $Output = Join-Path $TargetDirectory "$($Source.Name).jpg"
    Save-Jpeg $Bitmap $Output
    $Graphics.Dispose()
    $Bitmap.Dispose()
    $Image.Dispose()
}

function New-LandscapeAsset($Source, $TargetDirectory, $Prefix) {
    $Image = [System.Drawing.Image]::FromFile($Source.Path)
    $LogoImage = [System.Drawing.Image]::FromFile($Logo)
    $Pair = New-Canvas 1920 1080 '#0A234F'
    $Bitmap = $Pair[0]
    $Graphics = $Pair[1]

    Draw-ImageCover $Graphics $Image 0 0 1920 1080
    $Overlay = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(232, 8, 35, 78))
    $Graphics.FillRectangle($Overlay, 0, 0, 1920, 1080)
    $Overlay.Dispose()

    Fill-RoundRect $Graphics 110 96 128 128 30 '#FFFFFF'
    Draw-ImageContain $Graphics $LogoImage 120 106 108 108
    Draw-Text $Graphics 'Rhemalize' 110 270 720 82 64 '#FFFFFF' $true
    Draw-Text $Graphics $Source.Title 110 372 780 60 42 '#DCEBFF' $true
    Draw-Text $Graphics $Source.Subtitle 110 452 790 100 30 '#DCEBFF'
    Fill-RoundRect $Graphics 110 620 286 62 31 '#FFFFFF'
    Draw-Text $Graphics 'Listen anywhere' 146 635 230 38 26 '#0B4EA2' $true

    Fill-RoundRect $Graphics 1054 56 642 968 48 '#FFFFFF'
    Draw-ImageContain $Graphics $Image 1088 92 574 896

    $Output = Join-Path $TargetDirectory "$Prefix-$($Source.Name).jpg"
    Save-Jpeg $Bitmap $Output
    $Graphics.Dispose()
    $Bitmap.Dispose()
    $Image.Dispose()
    $LogoImage.Dispose()
}

foreach ($Source in $Sources) {
    New-PortraitAsset $Source (Join-Path $Base 'tablet_7_inch')
    New-PortraitAsset $Source (Join-Path $Base 'tablet_10_inch')
    New-LandscapeAsset $Source (Join-Path $Base 'chromebook') 'chromebook'
    New-LandscapeAsset $Source (Join-Path $Base 'android_xr') 'xr'
}
