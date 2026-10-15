#!/usr/bin/env bash
# Regenerates every launcher and notification icon from DogPainter.
# Needs flutter and ffmpeg. Run from the repo root: tool/generate_icons.sh
set -euo pipefail

OUT=build/icons
R=android/app/src/main/res
A=ios/Runner/Assets.xcassets

ICON_OUT=$OUT flutter test tool/icons/render_icons.dart

scale() { ffmpeg -v error -y -i "$1" -vf "scale=$3:$3:flags=lanczos${4:-}" "$2"; }

declare -A LEGACY=([mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192)
declare -A FG=([mdpi]=108 [hdpi]=162 [xhdpi]=216 [xxhdpi]=324 [xxxhdpi]=432)
declare -A STAT=([mdpi]=24 [hdpi]=36 [xhdpi]=48 [xxhdpi]=72 [xxxhdpi]=96)

for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  for v in happy sad feral; do
    suffix=$([ "$v" = happy ] && echo "" || echo "_$v")
    scale "$OUT/full_$v.png" "$R/mipmap-$d/ic_launcher$suffix.png" "${LEGACY[$d]}"
    scale "$OUT/fg_$v.png" "$R/mipmap-$d/ic_launcher_foreground$suffix.png" "${FG[$d]}"
  done
  # Notification icon: white silhouette with the face features cut out.
  mkdir -p "$R/drawable-$d"
  ffmpeg -v error -y -i "$OUT/fg_happy.png" -vf "crop=iw*0.8:ih*0.8,format=rgba,geq=r=255:g=255:b=255:a='if(gt(0.299*r(X\,Y)+0.587*g(X\,Y)+0.114*b(X\,Y)\,110)\,alpha(X\,Y)\,0)',scale=${STAT[$d]}:${STAT[$d]}:flags=lanczos" "$R/drawable-$d/ic_stat_remindya.png"
done

# iOS primary icon (happy): every size listed in Contents.json, no alpha.
python3 - "$A/AppIcon.appiconset/Contents.json" <<'PY' | while read -r f px; do
import json, sys
for i in json.load(open(sys.argv[1]))["images"]:
    s = float(i["size"].split("x")[0]); k = int(i["scale"][0])
    print(i["filename"], round(s * k))
PY
  scale "$OUT/full_happy.png" "$A/AppIcon.appiconset/$f" "$px" ",format=rgb24"
done
for v in sad feral; do
  set_name="AppIcon-${v^}"
  scale "$OUT/full_$v.png" "$A/$set_name.appiconset/icon-$v-1024.png" 1024 ",format=rgb24"
done

echo "Icons regenerated."
