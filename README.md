# Samsung Alexa Show Mode V7 — guida sperimentale

Guida comunitaria **non ufficiale** per installazione, adattamento e diagnostica di Alexa Show Mode V7 (`amazon.speech.sim`) su Samsung Android. **Non affiliato ad Amazon o Samsung.**

> Esperienza riportata (novembre 2026): dopo configurazione e un periodo di attesa, Alexa ha iniziato a funzionare. Un possibile allineamento con i server Amazon è **un'ipotesi, non una causa dimostrata**. Non esiste un tempo di attesa garantito.

## Dispositivi testati

| Dispositivo | Stato riportato | Note |
|---|---|---|
| Galaxy A52s 5G | Funzionante | Senza root |
| Galaxy Tab S3 LTE SM-T825, Android 9 | Funzionante dopo test e attesa | Inizialmente HTTP 400 e risposta «Si è verificato un problema» |
| Altro Galaxy A52s 5G | HTTP 400 nei test | Esito finale non documentato |

## Requisiti
- PC Windows con PowerShell e Android Platform Tools (`adb`)
- Debug USB abilitato sul proprio dispositivo
- APK acquisito legittimamente e account Amazon personale
- Backup dei dati e connessione Internet

**Non distribuiamo APK Amazon, credenziali, token o file proprietari.**

## Installazione e avvio

```powershell
adb devices -l
$TAB = '<SERIALE_ADB>'
adb -s $TAB shell getprop ro.product.model
adb -s $TAB shell getprop ro.build.version.release
adb -s $TAB install -r 'C:\percorso\alexa_show_mode_v7.apk'
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
```

Il launcher indicato è quello osservato nei test; potrebbe variare fra versioni.

## Riavvio senza cancellare account e dati
```powershell
adb -s $TAB shell am force-stop amazon.speech.sim
Start-Sleep -Seconds 3
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
```

## Guide
- [Build, firma e installazione APK (PowerShell)](docs/BUILD-E-FIRMA.md)
- [Adattamento Samsung](docs/ADATTAMENTO.md)
- [Diagnostica HTTP 400 e permessi](docs/DIAGNOSTICA.md)
- [Componenti Amazon e confronto](docs/COMPONENTI.md)
- [Script di diagnostica](scripts/diagnostica.ps1)
- [Come contribuire](CONTRIBUTING.md)

## Collaborazioni
Apri una **Issue** per problemi e compatibilità, oppure una **Pull Request** per correzioni e nuovi test. L'accesso diretto come collaboratore è assegnato dal maintainer caso per caso.

## Privacy e limiti
Non pubblicare seriali, DSN, account, token, cookie o log integrali non anonimizzati. Evitare bypass dell'autenticazione o registrazioni con identità altrui. I risultati possono variare in base a versione Android, firmware, APK e servizi Amazon.