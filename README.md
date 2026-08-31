# CinemaHQ

Standalone CinemaHQ APK repo.

## Files

- `CinemaHQ.apk` - the downloadable standalone APK copied from Shield
- `index.html` - landing page for GitHub Pages
- `release.json` - current release metadata
- `Start CinemaHQ.cmd` - local launcher for Windows
- `scripts/Pull-Foreground-Apk-From-Shield.ps1` - pulls the currently open Shield app into this repo as `CinemaHQ.apk`

## Shield pull flow

1. Open Cinema HQ on the Shield and leave it in the foreground.
2. Run:

```powershell
.\scripts\Pull-Foreground-Apk-From-Shield.ps1
```

3. Commit and push this repo to GitHub.

## Publish

- Repo: `https://github.com/dude2714/cinema-hq`
- Site: `https://dude2714.github.io/cinema-hq/`
- APK: `https://dude2714.github.io/cinema-hq/CinemaHQ.apk`
