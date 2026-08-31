PKG_VER=2.4.124
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/mesa/libdrm/-/archive/libdrm-$PKG_VER/libdrm-libdrm-$PKG_VER.tar.gz

getDrmDrivers()
{
	if [ "$ARCHITECTURE" == "aarch64" ]; then
		echo "-Dfreedreno=enabled -Dfreedreno-kgsl=true"
	elif [ "$ARCHITECTURE" == "x86_64" ]; then
		echo "-Dradeon=enabled -Damdgpu=enabled"
	fi
}

MESON_ARGS="-Dintel=disabled $(getDrmDrivers) -Dvmwgfx=disabled -Dtests=false"
