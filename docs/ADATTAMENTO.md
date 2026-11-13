# Adattamento ai Samsung

## Stato
Documentazione sperimentale: non è ancora disponibile una patch Smali verificata e generalizzabile. Non presentiamo modifiche non riproducibili come procedure confermate.

## Identificazione del dispositivo
```powershell
adb devices -l
$TAB = '<SERIALE_ADB>'
adb -s $TAB shell getprop ro.product.model
adb -s $TAB shell getprop ro.build.version.release
adb -s $TAB shell pm list packages | Select-String 'amazon|alexa|speech'
```

## Installazione del proprio APK
```powershell
adb -s $TAB install -r 'C:\percorso\alexa_show_mode_v7.apk'
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
```

## Permessi
```powershell
adb -s $TAB shell dumpsys package amazon.speech.sim | Select-String 'READ_PHONE_STATE' -Context 2,3
adb -s $TAB shell dumpsys package amazon.speech.sim | Select-String 'runtime permissions:' -Context 0,25
```

Se il permesso è dichiarato, è runtime e non è concesso, valutare:
```powershell
adb -s $TAB shell pm grant amazon.speech.sim android.permission.READ_PHONE_STATE
```
Non garantisce la soluzione del problema: il recupero del seriale può essere soggetto ad altre restrizioni.

## Riavvio app
```powershell
adb -s $TAB shell am force-stop amazon.speech.sim
Start-Sleep -Seconds 3
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
```

## Attesa dopo la registrazione
Nei test è stato osservato un funzionamento successivo a una fase iniziale di errore. È possibile che vi siano processi asincroni lato server, ma **non è stato verificato**. Non resettare continuamente i dati se l'account è già registrato. Annotare orari, errori e momento del primo successo.

## Ricerca Smali
Nell'APK esaminato, `AmazonAccountUtils` legge `DeviceType` e `Device Serial Number` tramite `DeviceDataStore`; `AndroidDsnProvider` tenta anche la lettura del seriale Android. Sono percorsi diversi: non sostituire DSN o token di un altro dispositivo.