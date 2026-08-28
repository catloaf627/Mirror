# App Preview Video Processing

This folder contains processed App Store Connect app preview videos.

The source videos are recorded from the same virtual machine each time and are placed in:

```sh
Videos_AppStore_Connect
```

The processed videos should be written to:

```sh
Videos_AppStore_Connect_Processed
```

## Required Output

For iPhone 6.5", 6.7", or 6.9" App Preview uploads, App Store Connect expects preview video dimensions of:

```text
886 x 1920 px
```

The screenshot dimensions shown by App Store Connect, such as `1320 x 2868`, `1290 x 2796`, `1260 x 2736`, or `1284 x 2778`, are for screenshots/device assets, not the final App Preview video accepted resolution.

Use this output format:

```text
Container: .mov
Video: H.264 High Profile
H.264 level: 4.0
Dimensions: 886 x 1920
Frame rate: constant 30 fps
Pixel format: yuv420p
Audio: AAC, 48 kHz, stereo
Duration: 15-30 seconds
Maximum file size: 500 MB
```

## Processing Command

The project has been processed with a temporary macOS arm64 ffmpeg binary at:

```sh
/private/tmp/mirror-ffmpeg/ffmpeg
/private/tmp/mirror-ffmpeg/ffprobe
```

If those binaries are missing, download them first:

```sh
mkdir -p /private/tmp/mirror-ffmpeg
curl -L --fail -o /private/tmp/mirror-ffmpeg/ffmpeg.zip https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip
curl -L --fail -o /private/tmp/mirror-ffmpeg/ffprobe.zip https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffprobe.zip
unzip -o /private/tmp/mirror-ffmpeg/ffmpeg.zip -d /private/tmp/mirror-ffmpeg
unzip -o /private/tmp/mirror-ffmpeg/ffprobe.zip -d /private/tmp/mirror-ffmpeg
chmod +x /private/tmp/mirror-ffmpeg/ffmpeg /private/tmp/mirror-ffmpeg/ffprobe
```

Run this from the repository root:

```sh
set -e
cd Videos_AppStore_Connect
find . -type f -name '*.mov' | sort | while IFS= read -r rel; do
  out="../Videos_AppStore_Connect_Processed/$rel"
  mkdir -p "$(dirname "$out")"
  echo "Processing $rel -> 886x1920"
  /private/tmp/mirror-ffmpeg/ffmpeg -nostdin -y -hide_banner -loglevel error \
    -i "$rel" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
    -map 0:v:0 -map 1:a:0 \
    -vf "fps=30,scale=-2:1920,crop=886:1920" -fps_mode cfr -r 30 \
    -c:v libx264 -profile:v high -level:v 4.0 -pix_fmt yuv420p -b:v 10M -maxrate 12M -bufsize 20M \
    -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -shortest -movflags +faststart "$out"
done
```

Important: keep `-nostdin`. Without it, ffmpeg can consume the `find` loop input and corrupt the batch paths.

## Verification Command

Run this from the repository root after processing:

```sh
printf 'processed count: '
find Videos_AppStore_Connect_Processed -type f -name '*.mov' | wc -l

bad=0
for f in Videos_AppStore_Connect_Processed/*/*.mov; do
  v=$(/private/tmp/mirror-ffmpeg/ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name,profile,level,width,height,r_frame_rate,avg_frame_rate,pix_fmt,duration \
    -of csv=p=0 "$f")
  a=$(/private/tmp/mirror-ffmpeg/ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name,sample_rate,channels \
    -of csv=p=0 "$f")
  bytes=$(stat -f%z "$f")
  printf '%s | %s | audio %s | bytes %s\n' "$f" "$v" "$a" "$bytes"
  case "$v" in *"886,1920"*"30/1,30/1"*) ;; *) bad=1 ;; esac
done
exit $bad
```

Expected result:

```text
processed count: 24
```

Every output video should show:

```text
h264,High,886,1920,yuv420p,40,30/1,30/1
audio aac,48000,2
```

## Current Folder Structure

The valid processed output folders are:

```text
0English
1Chinese
2Spanish
3French
4Japanese
5Korean
6German
7Russian
```

Do not keep stray folders such as `yuqingwang`, `lish`, or `_AppStore_Connect`; those were caused by an earlier bad batch command and are not valid output.
