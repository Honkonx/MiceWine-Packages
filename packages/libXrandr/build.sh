PKG_VER=1.5.4
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxrandr/-/archive/libXrandr-$PKG_VER/libxrandr-libXrandr-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
DEPENDENCIES="xorgproto xorg-utils-macros libX11 libXext libXrender"
