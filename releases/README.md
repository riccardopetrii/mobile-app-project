# Release dell'app

Per compilare l'APK di un progetto Flutter, eseguire nel terminale:
```bash
flutter build apk --release
```

Per copiare l'APK nella cartella `releases`:
```bash
cp build/app/outputs/flutter-apk/app-release.apk releases/app-vX.Y.Z-release.apk
```

## Convenzione di naming
```
app-v<major>.<minor>.<patch>-release.apk
```