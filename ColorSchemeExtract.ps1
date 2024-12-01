param (
    [string]$MaterialThemeZipFilePath,
    [string]$OutputPath
)

# Validate the zip file path
if (-not (Test-Path -Path $MaterialThemeZipFilePath)) {
    Write-Host "Error: Zip file path '$MaterialThemeZipFilePath' does not exist." -ForegroundColor Red
    exit
}

# Get the name of the zip file without the extension
$ZipFileName = [System.IO.Path]::GetFileNameWithoutExtension($MaterialThemeZipFilePath)

# Create the folder path where the zip will be extracted
$ExtractionFolderPath = Join-Path -Path $OutputPath -ChildPath $ZipFileName

# Create the extraction folder if it does not exist
if (-not (Test-Path -Path $ExtractionFolderPath)) {
    New-Item -ItemType Directory -Path $ExtractionFolderPath | Out-Null
}

# Extract the zip file to the destination folder
try {
    Expand-Archive -Path $MaterialThemeZipFilePath -DestinationPath $ExtractionFolderPath -Force
    Write-Host "Zip file extracted to '$ExtractionFolderPath'" -ForegroundColor Green
} catch {
    Write-Host "Error extracting zip file: $_" -ForegroundColor Red
    exit
}

# Find the color.kt file inside the extracted folder
$colorKtFilePath = Get-ChildItem -Path $ExtractionFolderPath -Recurse -Filter "Color.kt" | Select-Object -First 1

if (-not $colorKtFilePath) {
    Write-Host "Error: color.kt file not found in the extracted zip archive." -ForegroundColor Red
    exit
}

# Read the content of color.kt
$inputCode = Get-Content -Path $colorKtFilePath.FullName -Raw

# Start the output code with the template
$imports = @"
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color


"@

# Extract colors based on contrast levels
$standardColors = $inputCode -split "`n" | Where-Object {
    ($_ -match "val .*Light = Color\(0x[0-9A-Fa-f]+\)") -or ($_ -match "val .*Dark = Color\(0x[0-9A-Fa-f]+\)")
}
$mediumContrastColors = $inputCode -split "`n" | Where-Object {
    ($_ -match "val .*LightMediumContrast = Color\(0x[0-9A-Fa-f]+\)") -or ($_ -match "val .*DarkMediumContrast = Color\(0x[0-9A-Fa-f]+\)")
}
$highContrastColors = $inputCode -split "`n" | Where-Object {
    ($_ -match "val .*LightHighContrast = Color\(0x[0-9A-Fa-f]+\)") -or ($_ -match "val .*DarkHighContrast = Color\(0x[0-9A-Fa-f]+\)")
}

# Separate light and dark colors
$standardLightColors = $standardColors | Where-Object { $_ -match "Light" }
$standardDarkColors = $standardColors | Where-Object { $_ -match "Dark" }
$mediumContrastLightColors = $mediumContrastColors | Where-Object { $_ -match "Light" }
$mediumContrastDarkColors = $mediumContrastColors | Where-Object { $_ -match "Dark" }
$highContrastLightColors = $highContrastColors | Where-Object { $_ -match "Light" }
$highContrastDarkColors = $highContrastColors | Where-Object { $_ -match "Dark" }

# Function to create color scheme
function New-ColorScheme {
    param (
        [string]$contrastLevel,
        [array]$lightColors,
        [array]$darkColors
    )

    $colorScheme = $imports + @"
val darkColorScheme = darkColorScheme(

"@

    $colorScheme += ($darkColors | ForEach-Object {
        if ($_ -match "val (\w+)Dark$contrastLevel = Color\((0x\w+)\)") {
            $propertyName = $matches[1]
            $colorValue = $matches[2]
            "    $propertyName = Color($colorValue),"
        }
    }) -join "`n"

    $colorScheme += @"

)

val lightColorScheme = lightColorScheme(

"@

    $colorScheme += ($lightColors | ForEach-Object {
        if ($_ -match "val (\w+)Light$contrastLevel = Color\((0x\w+)\)") {
            $propertyName = $matches[1]
            $colorValue = $matches[2]
            "    $propertyName = Color($colorValue),"
        }
    }) -join "`n"

    $colorScheme += @"

)
"@

    return $colorScheme
}

# Generate color schemes
$standardColorScheme = New-ColorScheme "" $standardLightColors $standardDarkColors
$mediumContrastColorScheme = New-ColorScheme "MediumContrast" $mediumContrastLightColors $mediumContrastDarkColors
$highContrastColorScheme = New-ColorScheme "HighContrast" $highContrastLightColors $highContrastDarkColors

# Write the output code to files
$standardColorScheme | Set-Content -Path "$OutputPath\StandardColorScheme.kt"
$mediumContrastColorScheme | Set-Content -Path "$OutputPath\MediumContrastColorScheme.kt"
$highContrastColorScheme | Set-Content -Path "$OutputPath\HighContrastColorScheme.kt"

Write-Host "Color schemes generated successfully." -ForegroundColor Green

# Delete the extraction folder
Remove-Item -Path $ExtractionFolderPath -Recurse -Force
Write-Host "Extraction folder deleted." -ForegroundColor Green

# Open the output folder
Invoke-Item -Path $OutputPath