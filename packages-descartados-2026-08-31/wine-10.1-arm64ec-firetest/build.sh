PKG_VER="10.1-arm64ec-firetest"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine ARM64EC Fire Test (10.1 + 17 parches MiceWine)"

# Bug real encontrado 2026-08-25: faltaba este blacklist (mismo patron que
# wine-10.10/proton-wine-10.0 usan al reves, BLACKLIST_ARCH=aarch64) -- sin el,
# el build x86_64 intenta compilar este paquete arm64ec y falla en configure
# ("arm64ec PE cross-compiler not found", real, reproducido), cortando el resto
# de la cola de paquetes x86_64 (incluido wine-9.20, que va alfabeticamente
# despues) via el "exit 0" que build-all.sh hace ante cualquier fallo.
BLACKLIST_ARCH=x86_64

# A diferencia de packages/wine-10.10 y packages/proton-wine-10.0 (que tienen
# BLACKLIST_ARCH=aarch64 -- confirmado leyendo esos 2 build.sh reales, 2026-08-23),
# este paquete de prueba SI apunta a aarch64. Es la "prueba de fuego" pedida por
# el usuario: Wine vainilla 10.1 (mismo commit base real que usa
# KreitinnSoftware/wine rama wine-10.1, confirmado con `git log --reverse
# --author=pablolabs36`: a1dddd902f21e3a5057a40cb9848351f0cbcfd82) + los 17
# commits propios de KreitinnSoftware aplicados como parches reales (no
# reinventados), targeteando arm64ec en vez de x86_64 -- ver
# docs/wine/prueba-de-fuego-wine-vainilla-mas-parches.md para el proceso completo.
#
# NO se eligieron los 12 parches de la version Proton (KreitinnSoftware/proton-wine)
# porque esos estan escritos sobre la base de Proton (que ya difiere mucho de Wine
# vainilla), no aplicarian limpio sobre un Wine vainilla real -- los 17 de la
# rama wine-10.1 SI estan escritos sobre Wine vainilla 10.1 real (confirmado con
# el commit base de arriba), por eso son los que corresponden a este experimento.

GIT_URL=https://github.com/wine-mirror/wine
GIT_COMMIT=a1dddd902f21e3a5057a40cb9848351f0cbcfd82

# Regla del proyecto (2026-08-30, explicita del usuario): TODO Wine debe traer
# esync siempre. Auditado 2026-08-30: este paquete YA lo trae -- patches/0006
# ("Apply eventfd_synchronization from wine-staging") + patches/0007
# ("Implement shm_open and shm_unlink for Android", autocontenido, no necesita
# ningun header externo) son 2 de los 18 commits reales de KreitinnSoftware
# (wine-10.1) ya incluidos en este patch-set desde antes de esta sesion. No
# hacia falta agregar nada -- se habia intentado agregar los patches
# the412banner de esync por error (duplicados/redundantes), revertido.

HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"

# Cambio real vs wine-10.10/proton-wine-10.0: "--enable-archs=aarch64,arm64ec"
# en vez de "i386,x86_64" -- arm64ec es el modo WoW64 nativo de Wine (arm64
# corriendo codigo x86_64 traducido, complementario a FEXCore/WOWBox64 que ya
# usa MiceWine), soportado por Wine upstream desde la serie 9.x. Requiere que
# TOOLCHAIN_TRIPLE apunte al target aarch64 del NDK, no al x86_64/i686 que usan
# los otros 2 paquetes de Wine.
CONFIGURE_ARGS="--enable-archs=aarch64,arm64ec \
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

# gstreamer/gst-plugins-* removidos 2026-08-30: causaban loop infinito real
# en build-all.sh (ver wine-9.20-aarch64 y docs/build/fix-freedesktop-org-caido-migracion-gitlab.md)
DEPENDENCIES="libX11 libXext libXcomposite libXrender libXcursor libXrandr libXxf86vm libXinerama libXfixes libXi Vulkan-Headers Vulkan-Loader libglvnd pulseaudio freetype libgnutls"
