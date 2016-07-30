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

#Проверяем существует ли файл с ip адресом телевизора и читаем его
if ( Test-Path "tvip.cfg" ) {
    $tv_ip = Get-Content "tvip.cfg"
} else {
    $returnState = $returnStateCritical
#    [System.Environment]::Exit($returnState)
    Write-Host $returnState
    Break
}

#Задаем названия и guid нащего устройства управления
$my_device = "openhab"
$my_nick = "HomeControl"
$my_uuid = [guid]::NewGuid()

#Проверяем были ли уже получены куки и если да завершаем работу
if ( Test-Path "auth_cookie" ) {
    $returnState = $returnStateWarning
    Write-Host "Файл auth_cookie уже существует, сначала удалите его."
#    [System.Environment]::Exit($returnState)
    Write-Host $returnState
    Break
}

#Проверяем все параметры
if ( $tv_ip -eq "" -Or $my_nick -eq "" -Or $my_device -eq "" ) {
    $returnState = $returnStateWarning
    Write-Host "Отсутсвуют параметры для продолжения работы."
#    [System.Environment]::Exit($returnState)
    Write-Host $returnState
    Break
}

#Формируем JSON запрос для регистрации устройства управления
$data = @"
{
    "method" : "actRegister",
    "params" : [{
        "clientid" : "${my_nick}:${my_uuid}",
        "nickname" : "${my_nick} ( ${my_device} )",
        "level" : "private"
    },[
    {
            "value" : "yes",
            "function" :"WOL"
        }]],
    
    "id" : 8,
    "version" : "1.0"
}
"@


$url = "http://${tv_ip}/sony/accessControl"

#Отправляем запрос на регистрацию
Invoke-WebRequest -Method Post -Uri $url -Body $data

#Запрашиваем ПИН код отобразившийся на телевизоре у пользователя
$tv_challenge = Read-Host "Enter PIN code"

#Формируем заголовок с ПИН кодом в base64
$encodedpin = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":${tv_challenge}"))
$basicAuthValue = "Basic $encodedpin"

$Headers = @{
    Authorization = $basicAuthValue
}

#Формируем JSON запрос с отправкой ПИН кода
$data2 = @"
{
    "method" : "actRegister",
    "params" : [{
        "clientid" : "${my_nick}:${my_uuid}",
        "nickname" : "${my_nick} ( ${my_device} )"
    },[
    {
        "clientid" : "${my_nick}:${my_uuid}",
        "nickname" : "${my_nick} ( ${my_device} )",
        "value" : "yes",
        "function" :"WOL"
        }]],
    
    "id" : 8,
    "version" : "1.0"
}
"@

#Отправляем запрос с ПИН кодом
$Request = Invoke-WebRequest -Method Post -Headers $Headers -Uri $url -Body $data2

#Забираем куки из ответа и записываем в файл
$cookie = $Request.Headers["Set-Cookie"].Split(";")[0]
$cookie | Out-File "auth_cookie"

