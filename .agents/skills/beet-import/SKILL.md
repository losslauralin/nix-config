---
name: beet-import
description: Take a music URL or an audio file through yt-dlp and beets into ~/Music/Library on this nix-config. Use when the user hands over a YouTube/Bilibili/Bandcamp URL to download, says a track needs importing into the beets library, asks to fix tags on an already-imported track, or reports a `beet` error about a missing file or a bad match.
---

# Beet Import

Move one track from a URL to a finished entry in the beets library, with tags
that are correct in three places at once: the sqlite index, the file's own
tags, and the path on disk.

The pipeline is `yt-dlp` → `~/Music/incoming/` → `beet import` → `beet write` →
`beet move`. Each step has a trap that silently leaves the library in a state
that looks fine in `beet ls` and is wrong everywhere else. Read the traps
section before running anything.

## The library's shape

`modules/music.nix` owns this; read it before changing behaviour.

- `~/Music/incoming/` is the staging queue. Flat, one file per download.
- `~/Music/Library/` is beets-owned. Never `mv` files in by hand: beets will
  not know, and the index will point at a path that does not exist.
- `~/Music` is a symlink to an external disk. `find` will not follow it, so
  `find ~/Music ...` looks empty. Use `readlink -f ~/Music` when a tool needs
  the real path.
- `paths.default: $albumartist/$album%aunique{}/$track $title` for album
  tracks, `paths.singleton: $artist/$title` for standalone ones.

## Step 1 — Download

The user runs this, not you. `--cookies-from-browser` reaches into the browser
profile and can block on a keyring prompt, and an agent session has no tty.

```fish
yt-dlp -f bestaudio -x --audio-format best --embed-metadata --embed-thumbnail \
  --cookies-from-browser chrome "<URL>"
```

Why each flag:

- `--audio-format best` is required. `~/.config/yt-dlp/config` sets
  `--audio-format opus` globally, and command-line options layer on top of the
  config rather than replacing it. Without `best`, every download is re-encoded
  from whatever the site served to Opus, which is lossy-onto-lossy. `best`
  keeps the container as served.
- `-f bestaudio` picks the highest audio-only stream on any site, so the same
  command works for Bilibili, YouTube, and Bandcamp. `--cookies-from-browser`
  and `--embed-thumbnail` are likewise portable; drop the cookies flag for
  sites that do not need a login.
- Do not promise lossless audio. Sites label uploads "Hi-Res 无损" as a
  marketing line, and even the top audio-only stream is compressed. State the
  bitrate you actually got instead.

## Step 2 — Read the file, do not trust the title

Before importing, look at what is actually in the file:

```bash
exiftool -s -Title -Artist -Album -AlbumArtist -Track -Date -Genre <file>
```

Downloaded titles are SEO strings: `「Hi-Res音质」刘森《妖风过海》无损音质经典歌曲完整版`.
The uploader is frequently credited as the artist, and site keyword tags land
in `Genre`.

## Step 3 — Settle the album question

Ask the user which of these the track is, and do not guess:

1. A track on a known album
2. A standalone single
3. Part of a compilation

To make that answer easy, query the sources before asking. This is the part
worth automating: run both lookups, report what exists, and let the user
decide. Never infer an album from a filename or a search-result title.

```bash
# MusicBrainz
curl -s -A "beets-check/1.0 (local)" \
  "https://musicbrainz.org/ws/2/recording?query=recording:%22<TITLE>%22&fmt=json&limit=10"

# Deezer (no key needed, and the best Chinese-indie coverage of the two)
curl -s "https://api.deezer.com/search/album?q=artist:%22<ARTIST>%22&limit=20"
```

Then confirm the release's real tracklist before quoting a track number:

```bash
curl -s "https://api.deezer.com/album/<ALBUM_ID>/tracks?limit=50"
```

If the track is absent from every source, say so plainly. A Chinese indie or
doujin track is often on no streaming service at all, and that is a normal
outcome, not a failure to search hard enough. There is no NetEase source for
beets and no way to add one; do not offer it as an option.

Report findings as: what MusicBrainz has, what Deezer has, and what neither
has. Then ask which the user wants. If the user supplies an album name, use it
verbatim even when it does not appear in either source; they may be following
a private convention. Do not silently substitute a name you found elsewhere.

## Step 4 — Import

`beet import` prompts for input on any ambiguous match, and a prompt without a
tty ends the run. Pass `-A` to skip autotagging entirely, and `-q` with
`--quiet-fallback asis` so it never stops to ask:

```bash
# Album track
beet import -A -q --quiet-fallback asis \
  --set artist=<ARTIST> --set albumartist=<ARTIST> --set album=<ALBUM> \
  --set title=<TITLE> --set track=<N> --set year=<YEAR> <file>

# Standalone single
beet import -s -A -q --quiet-fallback asis \
  --set artist=<ARTIST> --set albumartist=<ARTIST> --set title=<TITLE> \
  --set year=<YEAR> <file>
```

`-s` marks the track as a singleton. That is a decision, not a flag to add by
habit: a singleton uses `paths.singleton` and lands at `$artist/$title`, while
an album track gets the album directory and a track number.

`--set` accepts a bare `key=value` and rejects an empty value, so it cannot
clear a field. Use `beet modify -y` afterwards for that.

## Step 5 — Write the tags into the file

`--set` writes only the sqlite index. The file keeps its old tags, and g4music
reads the file rather than the index, so the library looks fixed while the
player still shows the download title.

```bash
beet write '<query>'
```

Expect it to read the old values from the file and write the index values
back. Confirm afterwards with `exiftool`.

## Step 6 — Move, if needed

`beet write` does not relocate anything. After a `modify` that changes album or
artist, and after an import that was interrupted before the move step, run:

```bash
beet move -p '<query>'   # -p previews the destination
beet move    '<query>'
```

## Step 7 — Verify

Check all three layers agree, then report the result:

```bash
beet ls -f 'id=$id artist=$artist album=$album title=$title path=$path' <query>
exiftool -s -Title -Artist -Album -AlbumArtist -Track -Date <file>
beet ls -f '$path' | while IFS= read -r p; do
  [ -f "$p" ] && echo "OK      $p" || echo "MISSING $p"
done
```

A `MISSING` line means the index points somewhere the file is not. Fix that
before reporting success; it is the failure mode that hides longest.

To read cover art on an m4a, use `exiftool -CoverArt`. The `PictureMIMEType`
and `PictureType` fields belong to Ogg/Opus containers and report nothing on an
m4a even when a cover is embedded.

## Traps

**`--set` does not touch the file.** Always follow an import with `beet write`.
This is the single most common way a run reports success while the player
still shows the old title.

**Every mutating beet command prompts.** `import`, `modify`, `remove`, and
`write` all stop for confirmation. Without a tty that is an immediate
`stdin stream ended while input required`. Each has its own bypass:

| Command | Flag |
|---|---|
| `beet import` | `-q --quiet-fallback asis` (add `-A` to skip matching) |
| `beet modify` | `-y` / `--yes` |
| `beet remove` | `-f` / `--force` |

Prefer these over piping `printf 'y\n'`; the flags suppress the prompt instead
of feeding it.

**`singleton` cannot be cleared with `modify`.** It is derived from `album_id`,
and only an import creates an album record. To promote a singleton to an album
track, remove the index entry and re-import without `-s`.

**Pinning a release with `-S` beats searching.** When MusicBrainz has the right
release but the search ranks a pseudo-release above it, pass the release id
directly: `beet import -S <release-id> <file>`. This is what makes the album
and track fields arrive populated.

**`mbpseudo` is deliberately disabled.** Pseudo-release candidates outrank real
releases, so matches land on an entry with no album and no track number. If a
user re-enables it, expect that symptom.

**`discogs` is deliberately disabled.** With no token file it launches an OAuth
flow on startup and blocks on `input()`, which breaks every non-interactive
invocation.

**Stale index entries look like crashes.** `file not found at ...` and
`Moving: file not found` mean the index points at a path that no longer
exists, usually because someone moved the file by hand. Remove the entry with
`beet remove -f '<query>'` (without `-d`, so the file is left alone) and
re-import.

**Genre from a download is not genre.** Video-site tags are SEO keywords. The
user has chosen to keep them as-is; do not clear `Genre` on your own, but do
mention the value when reporting, since it is what the player will show.

## Reporting

End with the final path, the fields that landed, and anything the user still
has to decide. Name the source each field came from when it differs from the
file's own tags, so a later correction is easy to trace.
