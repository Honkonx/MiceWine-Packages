PKG_VER=2024.1
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/proto/xorgproto/-/archive/xorgproto-2024.1/xorgproto-xorgproto-2024.1.tar.gz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE"
DEPENDENCIES="xorg-utils-macros"
