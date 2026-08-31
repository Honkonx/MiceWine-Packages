PKG_VER=6.0.1
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxfixes/-/archive/libXfixes-$PKG_VER/libxfixes-libXfixes-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE"
DEPENDENCIES="xorgproto xorg-utils-macros libX11"
