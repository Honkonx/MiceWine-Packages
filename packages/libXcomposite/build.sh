PKG_VER=0.4.6
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxcomposite/-/archive/libXcomposite-$PKG_VER/libxcomposite-libXcomposite-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE"
DEPENDENCIES="xorgproto xorg-utils-macros libX11 libXfixes"
