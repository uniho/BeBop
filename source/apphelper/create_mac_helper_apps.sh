#!/bin/sh

BASEDIR=$(dirname "$0")
DEST=$1
SRC=$2

if [ "$SRC" = "" ];
then
  SRC=./AppHelper.app
fi

if [ "$DEST" = "" ];
then
  DEST=../../bin/x86_64-darwin/bebop.app
fi

SRCAPP=$(basename "$SRC")
SRCAPP="${SRCAPP%\.app}"
DESTAPP=$(basename "$DEST")
DESTAPP="${DESTAPP%\.app}"

SUB=""
rm -rf "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
cp -r "$SRC" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
mv "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$SRCAPP" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$DESTAPP Helper$SUB"
sed -i '' "s/$SRCAPP/$DESTAPP Helper$SUB/g" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/Info.plist"

SUB=" (GPU)"
rm -rf "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
cp -r "$SRC" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
mv "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$SRCAPP" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$DESTAPP Helper$SUB"
sed -i '' "s/$SRCAPP/$DESTAPP Helper$SUB/g" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/Info.plist"

SUB=" (Renderer)"
rm -rf "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
cp -r "$SRC" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
mv "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$SRCAPP" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$DESTAPP Helper$SUB"
sed -i '' "s/$SRCAPP/$DESTAPP Helper$SUB/g" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/Info.plist"

SUB=" (Plugin)"
rm -rf "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
cp -r "$SRC" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app"
mv "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$SRCAPP" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/MacOS/$DESTAPP Helper$SUB"
sed -i '' "s/$SRCAPP/$DESTAPP Helper$SUB/g" "$DEST/Contents/Frameworks/$DESTAPP Helper$SUB.app/Contents/Info.plist"

