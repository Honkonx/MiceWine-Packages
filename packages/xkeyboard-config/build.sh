PKG_VER=2.41
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/archive/xkeyboard-config-$PKG_VER/xkeyboard-config-xkeyboard-config-$PKG_VER.tar.gz
MESON_ARGS="-Dxkb-base=$PREFIX/share/X11/xkb -Dcompat-rules=true -Dxorg-rules-symlinks=false"
