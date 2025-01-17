# Color Scheme Extract

A PowerShell script to extract color schemes from Material Theme files and generate Kotlin code for Jetpack Compose projects.

## Features

- Extracts color schemes from Material Theme zip files
- Generates Kotlin code for three contrast levels:
  - Standard
  - Medium contrast
  - High contrast
- Creates ready-to-use color scheme files for Jetpack Compose

## Installation

1. Clone this repository
2. Ensure you have PowerShell installed
3. No additional dependencies required

## Usage

Run the script using PowerShell:

```powershell
.\ColorSchemeBuilder.ps1 -MaterialThemeZipFilePath "<path-to-zip>" -OutputPath "<output-directory>"
```

The script will generate three files in your output directory:
- `StandardColorScheme.kt`
- `MediumContrastColorScheme.kt`
- `HighContrastColorScheme.kt`

## Output

The generated Kotlin files can be directly imported into your Jetpack Compose project. Each file contains color definitions matching the corresponding contrast level from the Material Theme.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.