Set-PSReadlineKeyHandler -Key ? -Function MenuComplete
Set-PSReadlineOption -PredictionSource None
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\robbyrussell.omp.json" | Invoke-Expression
$wcode = "C:\Users\Fredy.Diaz\Documents\Main\TwoDeg\Code\Services"
$pcode = "C:\Users\Fredy.Diaz\Documents\Main\Personal\Code"
