PKG_VER=1.1.5
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxxf86vm/-/archive/libXxf86vm-$PKG_VER/libxxf86vm-libXxf86vm-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
DEPENDENCIES="xorgproto libX11 libXext"
