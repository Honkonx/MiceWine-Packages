PKG_VER=1.3.6
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxext/-/archive/libXext-$PKG_VER/libxext-libXext-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
DEPENDENCIES="xorgproto xorg-utils-macros libX11"
