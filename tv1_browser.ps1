<#
SonyTVRemote
Version 0.2

Description: Remote Control Sony TV with the powershell scripts.

Pavel Satin (c) 2016
pslater.ru@gmail.com
#>


$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

if ( Test-Path "tvip.cfg" ) {
    $tv_ip = Get-Content "tvip.cfg"
} else {
    $returnState = $returnStateCritical
#    [System.Environment]::Exit($returnState)
    Write-Host $returnState
    Break
}

if ( Test-Path "auth_cookie" ) {

} else {
    $returnState = $returnStateWarning
    Write-Host "Файл с куками не найден! Работа скрипта завершена."
#    [System.Environment]::Exit($returnState)

    Write-Host $returnState
    Break
}


$url = "http://${tv_ip}/sony/browser"

#$status = "true"
$status = $args[0]

$cookie_auth = Get-Content "auth_cookie"

$data = @"
{
    "id" : 10,
    "version" : "1.0",
    "method" : "setTextUrl",
    "params" : [{
        "url" : "${status}"
    }]
    
}
"@

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    
$cookie = New-Object System.Net.Cookie 
$cookie.Name = "auth"
$cookie.Value = $cookie_auth.Split("=")[1]
$cookie.Domain = $tv_ip

$session.Cookies.Add($cookie);

$Request = Invoke-WebRequest -Method Post -Uri $url -Body $data -WebSession $session
