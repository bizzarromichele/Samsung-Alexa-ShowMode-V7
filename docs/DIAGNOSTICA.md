# Diagnostica Alexa Show Mode V7

## Errore HTTP 400
Nei test:
```text
SPCH-SIM_SIMResponseObserver: onError Server returned status: 400 code: INVALID_REQUEST
{"error":{"code":"INVALID_REQUEST_EXCEPTION","message":"Bad Request"}}
```
La risposta HTTP dimostra che il server ha ricevuto la richiesta, **non** che il problema sia la connettività. La causa precisa non è stata accertata.

## Logcat
```powershell
$TAB = '<SERIALE_ADB>'
adb -s $TAB logcat -c
adb -s $TAB shell am force-stop amazon.speech.sim
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
# Dopo il test vocale:
adb -s $TAB logcat -d -v time | Select-String 'INVALID_REQUEST|status: 400|SIMResponseObserver|AndroidDsnProvider|SecurityException|AccountRegisteredCondition' | Select-Object -Last 60
```

## Lettura seriale
Nei log del Galaxy Tab S3 Android 9 è comparso:
```text
SecurityException: getSerial requires READ_PHONE_STATE or READ_PRIVILEGED_PHONE_STATE permission
AndroidDsnProvider: Failed to find new DSN retrieval method, falling back to deprecated method.
```
Il fallback può avere esito diverso; non è dimostrato che questa eccezione causi HTTP 400.

## Secure settings
È comparso anche:
```text
Permission denial: writing to settings requires:android.permission.WRITE_SECURE_SETTINGS
```
Non concedere privilegi di sistema indiscriminatamente. Prima identificare la funzione che tenta la scrittura.

## Registrazione
`SPCH-SIM_AccountRegisteredCondition: isMet` è stato osservato, ma non prova che ogni servizio Amazon abbia accettato l'identità dispositivo.

## Note
`pm check-permission` non è disponibile su alcune versioni Android: utilizzare `dumpsys package`.

Prima di condividere log: eliminare dati personali, credenziali, DSN, identificativi dispositivo e token.