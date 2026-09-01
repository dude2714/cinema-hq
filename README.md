# Moovies2

Standalone Moovies2 APK repo.

Source policy: use the original Cinema HQ app on the Shield as the donor source package `com.app.mlounge`, then archive the pulled APK here as `Moovies2.apk`.

## Files

- `Moovies2.apk` - the downloadable standalone APK copied from Shield
- `index.html` - landing page for GitHub Pages
- `release.json` - current release metadata
- `Start Moovies2.cmd` - local launcher for Windows
- `scripts/Pull-Foreground-Apk-From-Shield.ps1` - pulls the pinned Shield source package `com.app.mlounge` into this repo as `Moovies2.apk`

## Shield pull flow

1. Keep the original Cinema HQ app installed on the Shield as package `com.app.mlounge`.
2. Run:

```powershell
.\scripts\Pull-Foreground-Apk-From-Shield.ps1
```

3. The script resolves `com.app.mlounge` directly and stores that APK here as `Moovies2.apk`.
4. If you explicitly want the newest downloaded `Cinema*.apk` copy from Shield storage instead of the installed source package, re-run with `-AllowFallbackDownloadCopy`.
5. Commit and push this repo to GitHub.

## Publish

- Repo: `https://github.com/dude2714/cinema-hq`
- Site: `https://dude2714.github.io/cinema-hq/`
- APK: `https://dude2714.github.io/cinema-hq/Moovies2.apk`

## Shield manual test

For a manual download test on Shield, open Downloader or a browser on the device and use:

- `https://dude2714.github.io/cinema-hq/Moovies2.apk`

If you want a landing page first, use:

- `https://dude2714.github.io/cinema-hq/`
