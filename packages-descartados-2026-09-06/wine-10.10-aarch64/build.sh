PKG_VER="10.10-1"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine ($PKG_VER, aarch64 host)"

# Copia real de packages/wine-10.10/build.sh (mismo GIT_COMMIT, mismo Wine ya
# parcheado por KreitinnSoftware -- NO se tocaron los parches) con la misma
# diferencia real ya usada para wine-9.20-aarch64: sin BLACKLIST_ARCH=aarch64,
# para poder compilarlo targeteando un host Android aarch64 real (ej.
# Xclipse/Exynos) en vez de solo x86_64. El guest sigue siendo Wine normal
# corriendo x86/x86_64 vía Box64 (no es la vía arm64ec/WoW64 -- ver
# packages/wine-10.1-arm64ec-firetest, descartado, para esa vía distinta).
#
# Pedido explícito del usuario 2026-08-31: "si podemos compilar el wine 9.20
# arm lo podemos hacer con el 10.10 para probar?" -- mismo patrón ya probado
# y funcional (wine-9.20-aarch64 compiló limpio y produjo un .rat real de
# 389MB con Gecko/Mono incluidos, sesión del 2026-08-30/31).

GIT_URL=https://github.com/KreitinnSoftware/wine
GIT_COMMIT=ad2c2468a2cf3c39d8487bb3c08b3c4fb479d350
HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"
CONFIGURE_ARGS="--enable-archs=i386,x86_64 \
				--host=$TOOLCHAIN_TRIPLE \
				--with-wine-tools=$INIT_DIR/workdir/$package/wine-tools \
				--prefix=$OVERRIDE_PREFIX \
				--without-oss \
				--disable-winemenubuilder \
				--disable-win16 \
				--disable-tests \
				--with-x \
				--x-libraries=$PREFIX/lib \
				--x-includes=$PREFIX/include \
				--with-pulse \
				--without-gstreamer \
				--with-opengl \
				--with-gnutls \
				--with-mingw=gcc \
				--with-xinput \
				--with-xinput2 \
				--enable-nls \
				--without-xshm \
				--without-xxf86vm \
				--without-osmesa \
				--without-usb \
				--without-sdl \
				--without-cups \
				--without-netapi \
				--without-pcap \
				--without-gphoto \
				--without-v4l2 \
				--without-pcsclite \
				--without-wayland \
				--without-opencl \
				--without-dbus \
				--without-sane \
				--without-udev \
				--without-capi"

# gstreamer/gst-plugins-* fuera (mismo motivo que wine-9.20-aarch64 y
# wine-10.10: gstreamer.freedesktop.org caido, ver
# docs/build/fix-freedesktop-org-caido-migracion-gitlab.md)
DEPENDENCIES="libX11 libXext libXcomposite libXrender libXcursor libXrandr libXxf86vm libXinerama libXfixes libXi Vulkan-Headers Vulkan-Loader libglvnd pulseaudio freetype libgnutls"
