# CHOPPA V8 HOSTING — Phone-Only GitHub APK Build

This project is prepared so GitHub Actions can build the Android APK without Android Studio or a computer.

## What the workflow does

1. Starts a GitHub-hosted Ubuntu machine.
2. Installs Java 17.
3. Installs Gradle 8.10.
4. Builds the debug APK.
5. Builds an unsigned release APK.
6. Uploads both APK files as downloadable workflow artifacts.

## Phone-only method

### 1. Create a GitHub repository

On your phone, open GitHub in Chrome and create a new repository named:

`CHOPPA-V8-HOSTING`

### 2. Upload this project's files

Extract this ZIP on your phone first. Then upload the contents of the extracted `CHOPPA_V8_HOSTING_GITHUB_PHONE` folder into the repository. The `.github/workflows/build-apk.yml` file is important.

If your phone's file picker hides folders beginning with a dot, use GitHub's web interface to create the `.github/workflows/build-apk.yml` file manually, then paste the workflow from this ZIP.

### 3. Start the build

Open the repository → **Actions** → **Build CHOPPA V8 APK** → **Run workflow**.

Wait for the green check mark.

### 4. Download the APK

Open the completed workflow run. Scroll to **Artifacts**. Download:

- `CHOPPA-V8-HOSTING-debug-APK` — easiest APK for testing on your phone.
- `CHOPPA-V8-HOSTING-release-APK-unsigned` — release build, but it is not signed for normal distribution.

GitHub documents that workflow artifacts can store and later download build outputs. Gradle's official GitHub Actions documentation also supports installing a specified Gradle version directly on the runner.

## Important

The APK is the Android dashboard shell. For live MT5 data, the CHOPPA V8 EA still needs to send telemetry to a reachable CHOPPA V8 HOSTING server. The current local dashboard is demo/local data until a server URL is configured.

For a public app/product release, use HTTPS and a properly signed release APK. Do not put private API keys directly into the app source.
