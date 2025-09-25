# generate_songs.ps1
# Scans the Music/ folder and writes a songs.json compatible with index.html
# Usage: Open PowerShell in this folder and run:
#   powershell -ExecutionPolicy Bypass -File .\generate_songs.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$musicDir = Join-Path $root 'Music'
if (-not (Test-Path $musicDir)) {
    Write-Error "Music folder not found at $musicDir"
    exit 1
}

$songs = @()

# Find all mp3 files under Music (including files directly in Music)
$mp3Files = Get-ChildItem -Path $musicDir -Recurse -File -Include *.mp3 2>$null

# Exclude list (case-insensitive substrings). Add any folder or filename fragments here to skip tracks.
$excludePatterns = @(
    'Just Keep Watching'
)
    # Also skip this specific track/folder
    $excludePatterns += 'Lose My Mind'
foreach ($mp3 in $mp3Files) {
    $dir = Split-Path $mp3.FullName -Parent
    $relativeDir = $dir.Substring($root.Length) -replace '^\\+','' -replace '\\','/'
    $skip = $false
    foreach ($pat in $excludePatterns) {
        if ($relativeDir -match [regex]::Escape($pat)) { $skip = $true; break }
        if ($mp3.Name -match [regex]::Escape($pat)) { $skip = $true; break }
    }
    if ($skip) { continue }
    # build a web-friendly relative path (forward slashes)
    $relative = $mp3.FullName.Substring($root.Length) -replace "^\\+",""
    $relative = $relative -replace '\\','/'
    $url = "./$relative"

    $title = [System.IO.Path]::GetFileNameWithoutExtension($mp3.Name)
    $artist = ""
    $album = ""
    $year = ""
    $genre = ""
    $track = ""
    $duration = $null
    $cover = $null

    $metaFileCandidates = @(
        (Join-Path $dir 'metadata.json'),
        (Join-Path $dir 'meta.json')
    )
    foreach ($mf in $metaFileCandidates) {
        if (Test-Path $mf) {
            try {
                $meta = Get-Content $mf -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($null -ne $meta) {
                    # Support common names for fields, be flexible with casing
                    if ($meta.title) { $title = $meta.title }
                    if ($meta.Title) { $title = $meta.Title }
                    if ($meta.artist) { $artist = $meta.artist }
                    if ($meta.Artist) { $artist = $meta.Artist }
                    if ($meta.album) { $album = $meta.album }
                    if ($meta.Album) { $album = $meta.Album }
                    if ($meta.year) { $year = $meta.year }
                    if ($meta.Year) { $year = $meta.Year }
                    if ($meta.genre) { $genre = $meta.genre }
                    if ($meta.Genre) { $genre = $meta.Genre }
                    if ($meta.track) { $track = $meta.track }
                    if ($meta.Track) { $track = $meta.Track }
                    if ($meta.duration) { $duration = $meta.duration }
                    if ($meta.Duration) { $duration = $meta.Duration }
                    # cover might be filename or URL
                    $maybeCover = $null
                    if ($meta.cover) { $maybeCover = $meta.cover }
                    if ($meta.coverUrl) { $maybeCover = $meta.coverUrl }
                    if ($meta.cover_image) { $maybeCover = $meta.cover_image }
                    if ($maybeCover) {
                        $maybe = $maybeCover.ToString()
                        $maybePath = Join-Path $dir $maybe
                        if (Test-Path $maybePath) {
                            $relCov = $maybePath.Substring($root.Length) -replace '^\\+','' -replace '\\','/'
                            $cover = "./$relCov"
                        } else {
                            # leave as-is (could be already a URL)
                            $cover = $maybe
                        }
                    }
                }
            } catch { }
            break
        }
    }

    # prefer cover.jpg / cover.png in same folder
    foreach ($name in @('cover.jpg','cover.jpeg','cover.png','art.jpg','art.png')) {
        $cf = Join-Path $dir $name
        if (Test-Path $cf) {
            $relCov = $cf.Substring($root.Length) -replace '^\\+','' -replace '\\','/'
            $cover = "./$relCov"
            break
        }
    }

    $songObj = [PSCustomObject]@{
        title = $title
        artist = $artist
        album = $album
        year = $year
        genre = $genre
        track = $track
        duration = $duration
        cover = if ($cover) { $cover } else { $null }
        url = $url
    }
    $songs += $songObj
}

$out = @{ songs = $songs }
$outJson = $out | ConvertTo-Json -Depth 6
$outPath = Join-Path $root 'songs.json'
Set-Content -Path $outPath -Value $outJson -Encoding UTF8
Write-Output "Wrote $($songs.Count) song(s) to $outPath"
