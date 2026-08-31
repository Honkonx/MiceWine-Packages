PKG_VER=0.9.11
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxrender/-/archive/libXrender-$PKG_VER/libxrender-libXrender-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
DEPENDENCIES="xorgproto libX11"
