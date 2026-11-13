param([Parameter(Mandatory=$true)][string]$Serial)
$ErrorActionPreference = 'Stop'
Write-Host '== Device ==' -ForegroundColor Cyan
adb -s $Serial shell getprop ro.product.model
adb -s $Serial shell getprop ro.build.version.release
Write-Host '== Alexa package ==' -ForegroundColor Cyan
adb -s $Serial shell dumpsys package amazon.speech.sim | Select-String 'versionName=|versionCode=|targetSdk=|READ_PHONE_STATE' | Select-Object -First 20
Write-Host '== Amazon packages ==' -ForegroundColor Cyan
adb -s $Serial shell pm list packages | Select-String 'amazon|alexa|speech'
Write-Host '== Relevant recent logcat ==' -ForegroundColor Cyan
adb -s $Serial logcat -d -v time | Select-String 'INVALID_REQUEST|status: 400|SIMResponseObserver|AndroidDsnProvider|SecurityException|AccountRegisteredCondition' | Select-Object -Last 50
Write-Host 'Oscurare seriali, account, token e identificativi prima di condividere gli output.' -ForegroundColor Yellow
