PKG_VER=1.1.5
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/archive/libXinerama-$PKG_VER/libxinerama-libXinerama-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
DEPENDENCIES="xorgproto xorg-utils-macros libX11 libXext"
