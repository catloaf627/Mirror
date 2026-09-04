# App Store Preview Processing

Use this when converting simulator recordings for App Store Connect.

## English Source

- Source folder: `Videos_AppStore_Connect/0English`
- Output folder: `Videos_AppStore_Connect_Processed/0English`
- Current source video: `Videos_AppStore_Connect/0English/english.mov`
- Current output name: `Mirrorly-AppPreview-886x1920.mp4`

## Tooling

Use `ffprobe` first, then `ffmpeg`, then `ffprobe` again on the output.

If Homebrew `ffmpeg` is unavailable, a temporary static Apple Silicon build was used from:

- FFmpeg download page: `https://ffmpeg.org/download.html`
- OSXExperts Apple Silicon builds: `https://www.osxexperts.net/`

The downloaded binaries were placed under `/private/tmp/mirror-ffmpeg/`.

Published SHA-256 values verified for the extracted binaries:

- `ffmpeg`: `591260c945d0eef150e3bf82b0ef988bd36a9cecc18ff05d6679617159f0a95e`
- `ffprobe`: `e11c17e8200b3ee4c4c186d245e2b4053f01d56957336c1817fca0b997469106`

## Inspect Source

```sh
/private/tmp/mirror-ffmpeg/ffprobe \
  -hide_banner \
  -v error \
  -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,avg_frame_rate,pix_fmt,profile,level,bit_rate,duration \
  -show_entries format=duration,bit_rate \
  -of json \
  Videos_AppStore_Connect/0English/english.mov
```

Check:

- Duration is between 15 and 30 seconds.
- Whether an audio stream exists.
- Source dimensions and frame rate.

## Export 886 x 1920 Preview

This command preserves aspect ratio, scales to height `1920`, crops the extra width minimally to `886`, forces constant `30 fps`, writes H.264 High Profile Level 4.0, uses `yuv420p`, keeps progressive output, targets about `12 Mbps`, and enables fast start.

Important: do not export App Store previews with no audio stream. App Store Connect may reject those files with an "unsupported or corrupted audio" error. If the simulator recording has no audio, add a clean silent AAC stereo track.

### Source Has No Audio

```sh
mkdir -p Videos_AppStore_Connect_Processed/0English

/private/tmp/mirror-ffmpeg/ffmpeg \
  -hide_banner \
  -y \
  -i Videos_AppStore_Connect/0English/english.mov \
  -f lavfi \
  -i anullsrc=channel_layout=stereo:sample_rate=48000 \
  -map 0:v:0 \
  -map 1:a:0 \
  -shortest \
  -vf 'scale=-2:1920,crop=886:1920,setsar=1,fps=30,format=yuv420p' \
  -c:v libx264 \
  -profile:v high \
  -level:v 4.0 \
  -b:v 12M \
  -minrate 12M \
  -maxrate 12M \
  -bufsize 24M \
  -x264-params 'nal-hrd=cbr:filler=1:force-cfr=1' \
  -preset slow \
  -c:a aac \
  -b:a 256k \
  -ar 48000 \
  -ac 2 \
  -movflags +faststart \
  -fps_mode cfr \
  Videos_AppStore_Connect_Processed/0English/Mirrorly-AppPreview-886x1920.mp4
```

### Source Has Audio

```sh
mkdir -p Videos_AppStore_Connect_Processed/0English

/private/tmp/mirror-ffmpeg/ffmpeg \
  -hide_banner \
  -y \
  -i Videos_AppStore_Connect/0English/english.mov \
  -map 0:v:0 \
  -map 0:a:0 \
  -vf 'scale=-2:1920,crop=886:1920,setsar=1,fps=30,format=yuv420p' \
  -c:v libx264 \
  -profile:v high \
  -level:v 4.0 \
  -b:v 12M \
  -minrate 12M \
  -maxrate 12M \
  -bufsize 24M \
  -x264-params 'nal-hrd=cbr:filler=1:force-cfr=1' \
  -preset slow \
  -c:a aac \
  -b:a 256k \
  -ar 48000 \
  -ac 2 \
  -movflags +faststart \
  -fps_mode cfr \
  Videos_AppStore_Connect_Processed/0English/Mirrorly-AppPreview-886x1920.mp4
```

Notes:

- Do not overwrite the original `.mov`.
- Do not use `-an` for App Store preview exports.
- For silent audio, `ffprobe` may report a very low actual audio bitrate because AAC compresses silence efficiently. That is acceptable as long as the stream is `aac`, profile `LC`, stereo, and `48000 Hz`.

## Validate Output

```sh
/private/tmp/mirror-ffmpeg/ffprobe \
  -hide_banner \
  -v error \
  -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,avg_frame_rate,pix_fmt,profile,level,bit_rate,duration,field_order,sample_rate,channels,channel_layout \
  -show_entries format=duration,bit_rate,filename,size \
  -of json \
  Videos_AppStore_Connect_Processed/0English/Mirrorly-AppPreview-886x1920.mp4
```

Expected output values:

- Resolution: `886x1920`
- Codec: `h264`
- Frame rate: `30/1`
- Duration: between `15` and `30` seconds
- Pixel format: `yuv420p`
- Profile: `High`
- Level: `40` in ffprobe, meaning H.264 Level 4.0
- Field order: `progressive`
- Bitrate: close to `12 Mbps`
- Audio stream: `aac`, profile `LC`, `48000 Hz`, `2` channels, `stereo`

## Screenshot Diagonal Merges

Use this when creating the three App Store screenshots from the six English simulator screenshots.

Expected timestamp order:

1. `lightstart`
2. `lighttoday`
3. `lightrecords`
4. `darkstart`
5. `darktoday`
6. `darkrecords`

Current English source files in that order:

1. `Simulator Screenshot - iPhone 13 Pro Max - 2026-09-03 at 00.00.09.png`
2. `Simulator Screenshot - iPhone 13 Pro Max - 2026-09-03 at 00.00.11.png`
3. `Simulator Screenshot - iPhone 13 Pro Max - 2026-09-03 at 00.00.13.png`
4. `Simulator Screenshot - iPhone 13 Pro Max - 2026-09-03 at 00.00.22.png`
5. `Simulator Screenshot - iPhone 13 Pro Max - 2026-09-03 at 00.00.24.png`
6. `Simulator Screenshot - iPhone 13 Pro Max - 2026-09-03 at 00.00.27.png`

Always verify the order before generating outputs:

```sh
find Videos_AppStore_Connect/0English -maxdepth 1 -type f -iname '*.png' -print | sort
sips -g pixelWidth -g pixelHeight Videos_AppStore_Connect/0English/*.png
```

All six screenshots should have the same dimensions. Current English screenshots are `1284x2778`.

Merge rules:

- `image1`: start screenshots, diagonal from top-right to bottom-left, light on the left and dark on the right.
- `image2`: today screenshots, diagonal from top-right to bottom-left, dark on the left and light on the right.
- `image3`: records screenshots, diagonal from top-right to bottom-left, light on the left and dark on the right.

Output files:

- `Videos_AppStore_Connect_Processed/0English/01_start_light-left_dark-right.png`
- `Videos_AppStore_Connect_Processed/0English/02_today_dark-left_light-right.png`
- `Videos_AppStore_Connect_Processed/0English/03_records_light-left_dark-right.png`

The helper used for this was compiled to `/private/tmp/mirror_merge_screenshots`. If it is gone, rebuild and run it from the command history or recreate an Objective-C/CoreGraphics helper with this behavior:

- Load the six PNGs with `CGImageSource`.
- Draw the right-side image first.
- Clip a triangular left-side path using points `(0, 0)`, `(width, height)`, `(0, height)`.
- Draw the left-side image into that clipped triangle.
- Save each merged image as PNG with `CGImageDestination`.
- Validate output dimensions with `sips`.
