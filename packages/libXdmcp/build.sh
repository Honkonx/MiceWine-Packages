PKG_VER=1.1.5
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxdmcp/-/archive/libXdmcp-$PKG_VER/libxdmcp-libXdmcp-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE"
DEPENDENCIES="xorgproto xorg-utils-macros"
