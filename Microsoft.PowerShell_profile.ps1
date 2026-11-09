Set-PSReadlineKeyHandler -Key ? -Function MenuComplete
Set-PSReadlineOption -PredictionSource None
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\robbyrussell.omp.json" | Invoke-Expression
$wcode = "C:\Users\Fredy.Diaz\Documents\Main\TwoDeg\Code\Services"
$pcode = "C:\Users\Fredy.Diaz\Documents\Main\Personal\Code"

# Setup Visual Studio Build Tools environment
$vsPath = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools"
$vcvarsPath = "$vsPath\VC\Auxiliary\Build\vcvarsall.bat"

if (Test-Path $vcvarsPath) {
    $output = & cmd /c "call `"$vcvarsPath`" x64 > nul 2>&1 && set"
    $output | ForEach-Object {
        if ($_ -match '=') {
            $parts = $_ -split '=', 2
            [Environment]::SetEnvironmentVariable($parts[0], $parts[1], "Process")
        }
    }
}
