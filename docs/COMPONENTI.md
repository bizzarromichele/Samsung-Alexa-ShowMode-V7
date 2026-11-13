# Confronto componenti Amazon

Su Galaxy A52s funzionante erano presenti, ma assenti sul Tab S3:
- `alexa.echo.app.all.one` — versione 2.0.0, minSdk 22, targetSdk 29
- `com.amazon.appmanager` — versione 1.0.200309.0, componente preinstallato Samsung in `/prism/app/`
- `com.amazon.mShop.android.shopping` — versione 32.10.0.100, minSdk 28, targetSdk 36

**La differenza non dimostra una dipendenza.** Installare singolarmente i componenti non permette di attribuire il successivo successo a uno specifico APK senza test controllati.

## Confronto in sola lettura
```powershell
$OK = '<SERIALE_ADB_DISPOSITIVO_FUNZIONANTE>'
$TAB = '<SERIALE_ADB_TABLET>'
adb -s $OK shell pm list packages | Where-Object { $_ -match 'amazon|alexa|speech' } | Sort-Object | Set-Content '.\apk_ok.txt'
adb -s $TAB shell pm list packages | Where-Object { $_ -match 'amazon|alexa|speech' } | Sort-Object | Set-Content '.\apk_tab.txt'
Compare-Object (Get-Content '.\apk_ok.txt') (Get-Content '.\apk_tab.txt')
```

## Ispezione di un pacchetto
```powershell
$PKG = 'alexa.echo.app.all.one'
adb -s $OK shell pm path $PKG
adb -s $OK shell dumpsys package $PKG | Select-String 'versionName=|versionCode=|targetSdk=|Activity|Service|Provider'
```

## Estrarre un APK dal proprio dispositivo
```powershell
$PKG = 'alexa.echo.app.all.one'
adb -s $OK shell pm path $PKG
# Copiare il percorso restituito da 'package:' nel comando seguente:
adb -s $OK pull '<PERCORSO_REMOTO_BASE_APK>' '.\base.apk'
```
Per pacchetti split, `pm path` può restituire più file: il solo base.apk può non bastare. Le app preinstallate come `com.amazon.appmanager` possono perdere privilegi se installate come app utente. Non redistribuire gli APK estratti.