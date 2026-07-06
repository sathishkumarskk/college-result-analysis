# College Result Analyzer

Flutter app for parsing Anna University result PDFs, grouping students by department, analyzing subject performance, and exporting the analyzed result set to Excel.

## Windows Desktop Support

This project is prepared for Flutter Windows desktop support.

- Windows desktop support has been enabled with `flutter config --enable-windows-desktop`.
- The app already includes a `windows/` runner and now has Windows-friendly desktop behavior for:
  - PDF selection through `file_picker`
  - PDF text extraction through `syncfusion_flutter_pdf`
  - Excel export with a desktop save dialog
  - Larger desktop window layouts

## Run On Windows

Run these commands on a Windows machine with Flutter installed and Visual Studio 2022 configured with the `Desktop development with C++` workload:

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter run -d windows
```

## Build A Release Folder

On Windows, build the release output with:

```powershell
flutter build windows --release
```

On current Flutter stable, the runnable release output is typically generated in:

```text
build/windows/x64/runner/Release/
```

Important:

- Run the whole folder on the target PC, not just the `.exe`.
- The executable depends on the bundled `data/` folder and runtime DLLs next to it.

## Create An Installer

### Inno Setup

A starter Inno Setup script is included at [windows/packaging/college_result.iss](windows/packaging/college_result.iss).

Typical flow:

1. Build the app on Windows with `flutter build windows --release`.
2. Open `windows/packaging/college_result.iss` in Inno Setup.
3. Update the `AppId`, publisher, and version values.
4. Build the installer from Inno Setup.

The generated installer can be configured to land in:

```text
build/installers/
```

### MSIX

If you want Microsoft Store style packaging, use the Flutter Windows release output with MSIX packaging on Windows. Flutter's Windows deployment docs and the `msix` package are the usual route for generating `.msix` installers for store or enterprise deployment.

## Validation

Local verification completed in this workspace:

- `flutter analyze`
- `flutter test`

Windows-specific `flutter run -d windows` and `flutter build windows --release` still need to be executed on an actual Windows host because Flutter only supports Windows desktop run/build commands from Windows.

## Deploy The Web App

This project also builds successfully for Flutter Web.

Recommended hosting: Firebase Hosting, because this app uses client-side routing with `go_router` and Firebase can serve `index.html` for all routes.

### Build

```bash
flutter build web
```

The production-ready site will be generated in:

```text
build/web
```

### Publish With Firebase Hosting

1. Install the Firebase CLI:

   ```bash
   npm install -g firebase-tools
   ```

2. Sign in:

   ```bash
   firebase login
   ```

3. Create a Firebase project in the Firebase console if you do not already have one.

4. From this project folder, initialize hosting:

   ```bash
   firebase init hosting
   ```

   Use these choices:

   - Choose your Firebase project
   - Public directory: `build/web`
   - Single-page app: `Yes`
   - Overwrite `index.html`: `No`

5. Deploy:

   ```bash
   firebase deploy --only hosting
   ```

Firebase will print a public URL like `https://your-project-id.web.app` that you can send to your friends.
