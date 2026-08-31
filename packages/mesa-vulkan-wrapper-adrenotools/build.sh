PKG_VER=25.1.4-[gss]-adrenotools
PKG_CATEGORY="AdrenoTools"
PKG_PRETTY_NAME="Mesa Android Wrapper"
VK_DRIVER_LIB="libvulkan_wrapper.so"

BLACKLIST_ARCH=x86_64

# Bump 2026-08-30: incluye el fix "Correctly Fake EXT_map_memory_placed"
# (wrapper_device.c/wrapper_physical_device.c), que neutraliza de verdad la
# extension EXT_map_memory_placed al crear el VkDevice cuando se finge
# soportada -- el commit anterior la anunciaba pero no la deshabilitaba,
# riesgo de crash/corrupcion en DXVK sobre Adreno/Mali.
GIT_URL=https://github.com/KreitinnSoftware/mesa
GIT_COMMIT=104dce873df3710441474899b6cdb9d83dd32e98
LDFLAGS="-L$PREFIX/lib -landroid-shmem -ladrenotools -llinkernsbypass"
MESON_ARGS="-Dgallium-drivers= -Dvulkan-drivers=wrapper -Dglvnd=disabled -Dplatforms=x11 -Dxmlconfig=enabled -Dllvm=disabled -Dopengl=false -Degl=disabled -Dzstd=enabled"
DEPENDENCIES="xorgproto libdrm libX11 libxcb libxshmfence Vulkan-Headers Vulkan-Loader zlib zstd libexpat libglvnd libpng libXext libXrandr libXxf86vm libadrenotools"
