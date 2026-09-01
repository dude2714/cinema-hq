# Moovies2

Standalone Moovies2 APK repo.

Release policy: this repo publishes the separated Moovies2 fork built from the CinemaHQ donor app.

## Files

- `Moovies2.apk` - the downloadable standalone Moovies2 fork APK
- `index.html` - landing page for GitHub Pages
- `release.json` - current release metadata
- `Start Moovies2.cmd` - local launcher for Windows
- `scripts/Pull-Foreground-Apk-From-Shield.ps1` - refreshes the CinemaHQ donor APK from Shield
- `scripts/New-Moovies2Fork.ps1` - creates the decoded Moovies2 fork workspace from the donor APK
- `scripts/Build-Moovies2Fork.cmd` - rebuilds the Moovies2 fork APK
- `scripts/Sign-Moovies2Fork.cmd` - signs the rebuilt Moovies2 fork APK
- `scripts/Install-Moovies2Fork-On-Shield.cmd` - installs the forked APK on Shield for testing

## Current build

- App name: `Moovies2`
- Package: `com.dude2714.moovies2`
- Donor source: `CinemaHQ` on Shield

## Rebuild flow

1. Open the CinemaHQ donor app on the Shield and leave it in the foreground.
2. Refresh the donor APK:

```powershell
.\scripts\Pull-Foreground-Apk-From-Shield.ps1
```

3. Regenerate the fork workspace:

```cmd
.\scripts\Run-Moovies2Fork.cmd
```

4. Rebuild the fork:

```cmd
.\scripts\Build-Moovies2Fork.cmd
```

5. Sign the fork:

```cmd
.\scripts\Sign-Moovies2Fork.cmd
```

6. Install the fork on Shield for testing:

```cmd
.\scripts\Install-Moovies2Fork-On-Shield.cmd
```

7. Copy the tested fork to `Moovies2.apk`, then commit and push this repo.

## Publish

- Repo: `https://github.com/dude2714/cinema-hq`
- Site: `https://dude2714.github.io/cinema-hq/`
- APK: `https://dude2714.github.io/cinema-hq/Moovies2.apk`

## Shield manual test

For a manual download test on Shield, open Downloader or a browser on the device and use:

- `https://dude2714.github.io/cinema-hq/Moovies2.apk`

If you want a landing page first, use:

- `https://dude2714.github.io/cinema-hq/`
