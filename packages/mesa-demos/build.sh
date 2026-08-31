PKG_VER=9.0.0
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/mesa/demos/-/archive/mesa-demos-$PKG_VER/demos-mesa-demos-$PKG_VER.tar.gz
MESON_ARGS="-Dlibdrm=disabled -Dvulkan=disabled -Dwayland=disabled -Dwith-system-data-files=true -Dglut=disabled -Degl=disabled"
DEPENDENCIES="Vulkan-Headers Vulkan-Loader xkbcommon libdrm libglvnd FreeGLUT GLU libX11"
