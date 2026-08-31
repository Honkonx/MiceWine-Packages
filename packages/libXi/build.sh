PKG_VER=1.8.1
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxi/-/archive/libXi-$PKG_VER/libxi-libXi-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
DEPENDENCIES="xorgproto xorg-utils-macros libX11 libXfixes libXext"
