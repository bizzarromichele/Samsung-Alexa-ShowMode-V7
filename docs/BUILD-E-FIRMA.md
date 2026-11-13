# Build e firma APK — Alexa Show Mode V7 (Windows / Samsung)

> **Guida sperimentale.** Questa pagina documenta il workflow tecnico riproducibile per APK acquisiti legittimamente. Non fornisce APK Amazon, chiavi Amazon, token, DSN o una patch universale già validata. L'APK ricompilato viene firmato con **una chiave diversa** da quella originale: Android non permette un aggiornamento in-place se le firme non corrispondono.

## 0. Strumenti
- Java JDK (per `keytool` e apktool)
- [apktool](https://apktool.org/) per decodificare e ricostruire
- Android SDK Build Tools (`zipalign`, `apksigner`) e Platform Tools (`adb`)
- PowerShell su Windows

Verificare i comandi nel PATH:

```powershell
java -version
apktool --version
adb version
keytool -help
# Se zipalign e apksigner non sono nel PATH, usare i percorsi completi
Get-Command zipalign, apksigner -ErrorAction SilentlyContinue
```

## 1. Preparare il progetto

```powershell
$ROOT = 'C:\AlexaPort'
$APK = Join-Path $ROOT 'original\alexa_v7.apk'
$SRC = Join-Path $ROOT 'alexa_a52s'
$BUILD = Join-Path $ROOT 'build'
New-Item -ItemType Directory -Force -Path $BUILD | Out-Null
if (!(Test-Path $APK)) { throw "APK originale non trovato: $APK" }
Get-FileHash $APK -Algorithm SHA256
```

Il nome `alexa_a52s` riprende la cartella dei test originali, **non** implica che l'APK funzioni solo su A52s.

## 2. Decompilare e ispezionare

```powershell
apktool d -f $APK -o $SRC
Get-ChildItem $SRC -Recurse -Filter AmazonAccountUtils.smali | Select-Object FullName
Get-ChildItem $SRC -Recurse -Filter '*.smali' |
  Select-String -Pattern 'Device Serial Number|DeviceType' |
  Select-Object -First 40
```

Nella versione analizzata è stato individuato:

```text
smali/amazon/speech/sim/util/AmazonAccountUtils.smali
```

Il metodo `getStringByKey(String)` legge da `DeviceDataStore.getInstance(context).getValue(key)`; `getDeviceSerialNumber()` legge `"Device Serial Number"` e `getDeviceType()` legge `"DeviceType"`. **Questo è un riscontro del codice, non una patch da applicare.**

Nei log era presente anche `AndroidDsnProvider` con un errore di permesso su `Build.getSerial()`, seguito da un fallback. Il percorso Android seriale e il valore letto da `DeviceDataStore` non vanno confusi.

## 3. Modifiche Smali: stato delle prove

Non è ancora disponibile nel progetto il **diff esatto, testato e minimizzato** delle modifiche che hanno prodotto l'APK funzionante. Pertanto **non sostituire stringhe, valori DSN, device type, account o token sulla base di questa guida**.

Per contribuire con una patch riproducibile:
1. partire da una copia della stessa versione originale, con SHA256;
2. indicare file e metodo Smali modificati;
3. fornire un diff testuale che non contenga segreti o identificativi reali;
4. motivare ogni modifica e provarla su dispositivo proprio;
5. distinguere la compilazione riuscita dall'effettivo funzionamento cloud.

Esempio per ottenere un diff locale **solo se si possiede una copia originale già decompilata**:

```powershell
git diff --no-index -- 'C:\AlexaPort\alexa_originale\smali' 'C:\AlexaPort\alexa_a52s\smali'
```

`git diff --no-index` può restituire codice di uscita 1 quando rileva differenze: è normale.

## 4. Ricompilare

```powershell
$UNSIGNED = Join-Path $BUILD 'alexa-unsigned.apk'
apktool b $SRC -o $UNSIGNED
if (!(Test-Path $UNSIGNED)) { throw 'Build APK non riuscita' }
```

Un APK ricompilato può avere incompatibilità con risorse, protezioni o verifiche d'integrità. La sola build non dimostra che sia installabile o funzionante.

## 5. Allineare e firmare

Individuare `zipalign.exe` e `apksigner.bat` nella propria installazione degli Android SDK Build Tools. Esempio con i programmi già nel PATH:

```powershell
$ALIGNED = Join-Path $BUILD 'alexa-aligned.apk'
$SIGNED = Join-Path $BUILD 'alexa-signed.apk'
$KEYSTORE = Join-Path $ROOT 'private\alexa-test.jks'
New-Item -ItemType Directory -Force -Path (Split-Path $KEYSTORE) | Out-Null

# Crea una chiave personale di test (NON la chiave di Amazon)
keytool -genkeypair -v -keystore $KEYSTORE -alias alexa-test -keyalg RSA -keysize 3072 -validity 3650

zipalign -f -p 4 $UNSIGNED $ALIGNED
apksigner sign --ks $KEYSTORE --ks-key-alias alexa-test --out $SIGNED $ALIGNED
apksigner verify --verbose $SIGNED
Get-FileHash $SIGNED -Algorithm SHA256
```

Conservare la chiave privata al sicuro; **non caricarla su GitHub**. `keytool` e `apksigner` possono richiedere password in modo interattivo. Non inserire password in script condivisi.

## 6. Installazione Samsung

```powershell
adb devices -l
$TAB = '<SERIALE_ADB>'
adb -s $TAB shell getprop ro.product.model
adb -s $TAB shell getprop ro.build.version.release
adb -s $TAB shell pm path amazon.speech.sim
```

**Prima di installare:** se è presente `amazon.speech.sim` firmato con un'altra chiave, `adb install -r` può fallire con `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Non disinstallare automaticamente: l'operazione può cancellare dati, registrazione e configurazione. Valutare backup e compatibilità delle firme.

```powershell
adb -s $TAB install -r $SIGNED
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
```

Il launcher è quello osservato nella versione testata; altre build possono differire.

## 7. Permessi e diagnostica

```powershell
adb -s $TAB shell dumpsys package amazon.speech.sim |
  Select-String 'READ_PHONE_STATE' -Context 2,3
adb -s $TAB shell dumpsys package amazon.speech.sim |
  Select-String 'runtime permissions:' -Context 0,25
```

Se `READ_PHONE_STATE` è dichiarato e concedibile come permesso runtime, si può verificare il risultato di:

```powershell
adb -s $TAB shell pm grant amazon.speech.sim android.permission.READ_PHONE_STATE
```

Non è una correzione garantita per HTTP 400. Non concedere indiscriminatamente `WRITE_SECURE_SETTINGS` o permessi privilegiati.

```powershell
adb -s $TAB logcat -c
adb -s $TAB shell am force-stop amazon.speech.sim
adb -s $TAB shell am start -n amazon.speech.sim/com.amazon.paladin.app.MMLauncherActivity
# Eseguire una prova vocale, poi:
adb -s $TAB logcat -d -v time |
  Select-String 'INVALID_REQUEST|status: 400|SIMResponseObserver|AndroidDsnProvider|AccountRegisteredCondition' |
  Select-Object -Last 60
```

## 8. Attendere e ritestare

Durante i test alcuni dispositivi hanno inizialmente risposto «Si è verificato un problema» e successivamente hanno funzionato. **L'allineamento con i server Amazon è una possibile interpretazione, non verificata**; non è noto un intervallo temporale universale. Registrare timestamp, firmware, APK, rete e risultato, senza resettare ripetutamente l'app.

## 9. Contribuire

Aprire una Issue con modello Samsung, versione Android, SHA256 APK, procedura, log anonimizzati ed esito. Una Pull Request che aggiunge una patch deve includere il diff e i test: niente APK proprietari, chiavi private, DSN, credenziali o token.
