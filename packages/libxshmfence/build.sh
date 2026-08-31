PKG_VER=1.3.2
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/lib/libxshmfence/-/archive/libxshmfence-$PKG_VER/libxshmfence-libxshmfence-$PKG_VER.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --disable-futex"
DEPENDENCIES="xorgproto xorg-utils-macros"
