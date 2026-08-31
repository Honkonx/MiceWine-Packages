PKG_VER=1.17.0
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxcb/-/archive/libxcb-$PKG_VER/libxcb-libxcb-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE"
DEPENDENCIES="xorgproto libXau libXdmcp xcb-proto"
