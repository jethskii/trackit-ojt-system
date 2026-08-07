# Convenience script: runs the Flutter app regardless of which directory
# you launch it from. Usage from the repo root: .\run-app.ps1
Set-Location -Path (Join-Path $PSScriptRoot 'trackit_app')
flutter run -d chrome
