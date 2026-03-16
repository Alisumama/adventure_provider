# Run troubleshooting: physical device + emulator

## Physical device (M2103K19G) – app not running

Do these in order:

### 1. Uninstall the app from the phone
- **Settings → Apps → Adventure Providers** (or "adventure_provider_frontend") → **Uninstall**
- This avoids "Activity does not exist" and install conflicts from old builds

### 2. Xiaomi: enable install over USB
- **Settings → Additional settings → Developer options**
- Turn **ON**: **USB debugging**
- Turn **ON**: **Install via USB** (or **USB debugging (Security settings)**)

### 3. Use a good USB connection
- Prefer a **USB 2.0 port** (not always USB 3)
- Try another **cable** (some charge-only cables don’t transfer data)
- On the phone, when you plug in, choose **File transfer / MTP** or **PTP**, not "Charge only"

### 4. Restart ADB and run again
In a terminal (PowerShell or CMD):

```bash
cd D:\FYP\PROJECT\adventure_provider\adventure_provider_frontend
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" kill-server
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" start-server
flutter devices
flutter run
```

Pick your phone (e.g. `cev8fm4tguz9hqxo`) when asked, or run:

```bash
flutter run -d cev8fm4tguz9hqxo
```

### 5. If it still fails: clean build and reinstall
```bash
flutter clean
flutter pub get
flutter run -d cev8fm4tguz9hqxo
```

---

## Emulator – "System UI not responding"

That message usually means the emulator is overloaded. Try:

### 1. Give the emulator more resources
- Open **Android Studio → Device Manager** (or Tools → AVD Manager)
- Edit your virtual device (pencil icon)
- **Advanced settings** (or "Show Advanced Settings"):
  - **RAM**: at least **2048 MB** (4096 MB if you can)
  - **VM heap**: 256 or 512
  - **Graphics**: **Hardware - GLES 2.0** (or try **Software** if it’s more stable on your PC)
- Save and **Cold Boot Now** the emulator

### 2. Use a lighter system image
- In AVD Manager, create a **new** AVD:
  - Device: e.g. **Pixel 4** or **Pixel 5**
  - System image: **API 30** or **API 33** (avoid the very latest if your PC is slow)
  - ABI: **x86_64** (faster than ARM on most PCs)
- Start this new emulator and run:

```bash
flutter run -d emulator-5554
```
(Use the device ID shown by `flutter devices`.)

### 3. Close other apps
- Close Chrome, other Android emulators, and heavy apps so the emulator gets more CPU and RAM.

### 4. Run on Chrome instead (no emulator)
If the emulator keeps freezing:

```bash
flutter run -d chrome
```

The app will open in Chrome so you can develop without the emulator.

---

## Summary of changes made in the project

- **AndroidManifest**: Activity name set to full class  
  `com.example.adventure_provider_frontend.MainActivity` so the device can resolve the launcher activity.
- **Splash screen**: Animation starts **after the first frame** (`addPostFrameCallback`) so the first paint is quick and the emulator is less likely to show "System UI not responding".
