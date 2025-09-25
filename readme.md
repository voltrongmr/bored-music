BORED Music — GitHub Pages Hosting and Local Setup

What this repo contains
- `index.html` — the single-page music player UI.
- `songs.json` — the catalog the app loads on startup.
- `Music/` — your music files organized in subfolders; each track folder may contain `metadata.json` and `cover.jpg`.
- `generate_songs.ps1` — a PowerShell helper to regenerate `songs.json` from the `Music/` folder.

Will this work on GitHub Pages?
Yes. To make the player work smoothly on GitHub Pages:
- `songs.json`, audio files (in `Music/`), and cover images must be committed and pushed to the repository so they are served from the same origin (https://your-username.github.io/your-repo/).
- The app expects the `url` fields in `songs.json` to be correct relative paths (like `./Music/SomeAlbum/track.mp3`). The provided `generate_songs.ps1` creates those paths automatically.
- Embedding/extracting ID3 cover art with client-side libraries (jsmediatags, music-metadata-browser) requires files to be served over HTTP(S) from the same origin. GitHub Pages satisfies that.

How to regenerate `songs.json`
Open PowerShell in the repository root (where `generate_songs.ps1` lives) and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\generate_songs.ps1
```

This will scan `Music/` recursively and write `songs.json` with entries like:
{
  "title": "Song Title",
  "artist": "Artist Name",
  "album": "",
  "cover": "./Music/Folder/cover.jpg",
  "url": "./Music/Folder/Song.mp3"
}

Optional: run a local static server while testing
If you open `index.html` using the `file://` protocol, metadata extraction and some fetch calls may fail due to browser restrictions. To test locally over HTTP, run one of these from PowerShell:

- Python 3 (if installed):

```powershell
python -m http.server 8000
```

- Node (quick serve via npx):

```powershell
npx serve -s . -l 8000
```

Then open http://localhost:8000/ in the browser.

Cleanups applied
- Simplified the `tryLoadCover` function in `index.html` to remove an unreliable CORS proxy and noisy fallback logic. The function now tries the client-side parsers only when files are served from the same origin (works well on GitHub Pages).
- Added this `README.md` and `generate_songs.ps1` to make it easy to keep `songs.json` in sync with the `Music/` directory.

Next steps I can do for you
- Add a small GitHub Actions workflow to auto-generate `songs.json` before deploying (if you want automation on push).
- Add a cross-platform Node/Python script for people who don't use PowerShell.
- Create a one-click deploy guide for GitHub Pages (branch settings, publishing).

Tell me which you'd like and I’ll implement it.