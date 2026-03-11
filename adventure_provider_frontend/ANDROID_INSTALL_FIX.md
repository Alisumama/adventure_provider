# Android: App not installing – what to do

If **"application is not getting installed"** or you see **"App not installed"** on the device, try these in order.

## 1. Uninstall the existing app (most common fix)

If the app was installed before (e.g. from another PC or build), Android may block reinstalling because of a different signing key.

- On the phone: **Settings → Apps → Adventure Providers** (or "adventure_provider_frontend") → **Uninstall**.
- Then run again: `flutter run -d cev8fm4tguz9hqxo` (or just `flutter run` with the device connected).

## 2. Xiaomi / Redmi (e.g. M2103K19G)

- Open **Settings → Additional settings → Developer options**.
- Turn on **USB debugging**.
- Turn on **Install via USB** (or **USB debugging (Security settings)**).
- If you use a cable, try a different USB port or cable.

## 3. Free space and retry

- Ensure the phone has at least **200–300 MB** free.
- Run again:
  ```bash
  cd adventure_provider_frontend
  flutter clean
  flutter pub get
  flutter run
  ```

## 4. Install the built APK manually (to see the real error)

1. Build the APK:
   ```bash
   flutter build apk --debug
   ```
2. APK path: `build\app\outputs\flutter-apk\app-debug.apk`
3. Copy it to the phone (USB or cloud) and open the file to install.
4. If it says **"App not installed"**, uninstall any existing **Adventure Providers** (or same package) and try again.
5. On Xiaomi, if it still fails, enable **Install via USB** and try installing from the PC with:
   ```bash
   "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
   ```
   (Replace the path if your Android SDK is elsewhere.)

## 5. Check what Flutter is doing

Run with verbose output to see where it fails (build vs install):

```bash
flutter run -d cev8fm4tguz9hqxo -v
```

Look for errors right after **"Installing build\app\outputs\flutter-apk\app-debug.apk"**.
