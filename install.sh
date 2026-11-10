#!/usr/bin/env bash
# CouchMPV installer — installs dependencies and installs CouchMPV system-wide.
set -euo pipefail

RED=$'\033[1;31m'
GRN=$'\033[1;32m'
YLW=$'\033[1;33m'
CYN=$'\033[1;36m'
RST=$'\033[0m'

info() { printf '%s%s%s\n' "$CYN" "$*" "$RST"; }
ok()   { printf '%s%s%s\n' "$GRN" "$*" "$RST"; }
warn() { printf '%s%s%s\n' "$YLW" "$*" "$RST"; }
err()  { printf '%s%s%s\n' "$RED" "$*" "$RST" >&2; }

need_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO=(sudo)
        else
            err "This step needs root privileges, but sudo was not found."
            exit 1
        fi
    else
        SUDO=()
    fi
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_SRC="${SCRIPT_DIR}/couchmpv.py"
DESKTOP_SRC="${SCRIPT_DIR}/couchmpv.desktop"
ICON_SRC="${SCRIPT_DIR}/couchmpv.png"

# Make sure all application files are alongside this installer.
for file in "$APP_SRC" "$DESKTOP_SRC" "$ICON_SRC"; do
    if [[ ! -f "$file" ]]; then
        err "Required file not found: $file"
        err "Place install.sh, couchmpv.py, couchmpv.desktop, and couchmpv.png in the same directory."
        exit 1
    fi
done

echo
info "CouchMPV installer"
echo
echo "Which distro are you on?"
echo "  1) Arch Linux"
echo "  2) Debian / Ubuntu (and derivatives)"
echo "  3) Fedora"
echo "  4) Other"
echo
read -r -p "Choice [1-4]: " DISTRO_CHOICE
echo

case "$DISTRO_CHOICE" in
    1)
        need_root
        info "Installing dependencies for Arch Linux..."
        "${SUDO[@]}" pacman -S --needed --noconfirm \
            python python-gobject gtk3 mpv python-mpv python-cairo ffmpeg
        ;;
    2)
        need_root
        info "Installing dependencies for Debian / Ubuntu..."
        "${SUDO[@]}" apt-get update
        "${SUDO[@]}" apt-get install -y \
            python3 python3-gi gir1.2-gtk-3.0 gir1.2-gdkpixbuf-2.0 \
            python3-cairo python3-gi-cairo mpv libmpv2 python3-mpv ffmpeg
        ;;
    3)
        need_root
        info "Installing dependencies for Fedora..."
        "${SUDO[@]}" dnf install -y \
            python3 python3-gobject gtk3 python3-cairo \
            gobject-introspection mpv libmpv python3-mpv ffmpeg
        ;;
    4)
        warn "Your distro is not supported by this installer."
        echo
        echo "Please install these dependencies using your distro's package manager:"
        echo
        echo "  Python 3"
        echo "  PyGObject / python-gobject"
        echo "  GTK 3"
        echo "  GDK Pixbuf introspection bindings"
        echo "  Cairo and Python Cairo bindings"
        echo "  GObject Introspection"
        echo "  mpv"
        echo "  libmpv"
        echo "  python-mpv"
        echo "  FFmpeg"
        echo
        echo "Package names vary between distributions. Install the equivalents"
        echo "provided by your distro, then continue with the application installation."
        echo
        need_root
        ;;
    *)
        err "Invalid choice. Please run the installer again and choose 1, 2, 3, or 4."
        exit 1
        ;;
esac

echo
info "Installing CouchMPV..."

# Install the application launcher, desktop entry, and icon.
"${SUDO[@]}" install -D -m 755 "$APP_SRC" /usr/local/bin/couchmpv
"${SUDO[@]}" install -D -m 644 "$DESKTOP_SRC" /usr/share/applications/couchmpv.desktop
"${SUDO[@]}" install -D -m 644 "$ICON_SRC" /usr/share/icons/hicolor/256x256/apps/couchmpv.png

# Refresh the icon cache when the utility is available.
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    "${SUDO[@]}" gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi

echo
ok "CouchMPV installation completed!"
echo "You can launch it by running: couchmpv"
echo "It should also appear in your desktop application menu."
echo
