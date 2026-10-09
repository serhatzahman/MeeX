#!/bin/sh
# MeeX Nokia N9 Native App Installer
# Run this script on your Nokia N9 as root (devel-su)

echo "=========================================="
echo "    MeeX Nokia N9 Native App Installer    "
echo "=========================================="

APP_DIR="/opt/MeeX"
echo "[1/4] Kurulum dizini olusturuluyor: $APP_DIR"
mkdir -p "$APP_DIR"

echo "[2/4] Uygulama dosyalari kopyalaniyor..."
cp main.qml "$APP_DIR/"
cp run.py "$APP_DIR/"
chmod +x "$APP_DIR/run.py"

echo "[3/4] Uygulama ikonu yukleniyor..."
mkdir -p /usr/share/icons/hicolor/80x80/apps/
cp meex.png /usr/share/icons/hicolor/80x80/apps/meex.png

echo "[4/4] Masaustu baslatici (.desktop) kaydediliyor..."
cp meex.desktop /usr/share/applications/meex.desktop

echo ""
echo "✓ Kurulum basariyla tamamlandi!"
echo "MeeX artik Nokia N9 uygulama menunuzde yer aliyor."
echo "Menuden simgeye dokunarak hemen baslatabilirsiniz."
