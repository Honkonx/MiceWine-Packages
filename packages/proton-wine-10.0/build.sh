PKG_VER="10.0-1"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine Proton ($PKG_VER)"

BLACKLIST_ARCH=aarch64

# Fork used by MiceWine (KreitinnSoftware, same author/org as the wine-10.10 and
# wine-9.20 packages) of Valve's Proton-flavored Wine (LGPL, upstream tracks
# https://github.com/ValveSoftware/wine). Only the "proton_10.0" branch exists
# in this fork at the time of writing (no version tags) -- confirmed with
# `git -C referencia/proton-wine branch -a`, HEAD == e9f8068ea6b8431f05357e8d8d1a6fc01da47bfc.
GIT_URL=https://github.com/KreitinnSoftware/proton-wine
GIT_COMMIT=e9f8068ea6b8431f05357e8d8d1a6fc01da47bfc

# Bug real encontrado 2026-08-27: los parches the412banner 0007
# (dlls_ntdll_unix_esync_c.patch) y 0035 (server_esync_c.patch) agregan
# #include "android/shm_utils/shm_utils.h", pero ese header vive como archivo
# fuente suelto en wine/the412banner-ntdll-patches/android/shm_utils/ (NO es
# un patch, es un archivo nuevo que hay que copiar). build-all.sh solo copia
# el contenido de packages/$package/ al arbol fuente para paquetes SRC_URL/
# BUILD_IN_SRC (ver build-all.sh setupPackage(), rama GIT_URL no lo hace), asi
# que para este paquete (GIT_URL) el header nunca llegaba al arbol clonado.
# Esto rompia la compilacion de ntdll/esync.c y (como el build script generado
# no tiene "set -e") el fallo pasaba silencioso hasta "make install" y
# post-install.sh, produciendo un .rat que parecia exitoso pero sin ningun
# binario real de Wine adentro (solo Mono/Gecko). Mismo patron ya documentado
# para --disable-amd_ags_x64 mas abajo. Fix: copiar el header explicitamente
# despues de aplicar los parches, via el hook RUN_POST_APPLY_PATCH (corre con
# cwd = raiz del arbol fuente ya clonado, ver build-all.sh applyPatches()).
# NOTA: $RUN_POST_APPLY_PATCH se expande SIN comillas y se ejecuta como
# comando simple (build-all.sh applyPatches(), linea 115) -- no soporta "&&"
# ni ";" como operadores de shell (se pasarian como argv literal), por eso es
# un solo comando "cp -r" (no dos "install -D" separados). Copia TODA la
# carpeta android/ de este paquete (shm_utils/, android_sysvshm/) al arbol
# fuente ya clonado -- asi que cualquier header/fuente nuevo que algun parche
# the412banner necesite a futuro solo hace falta agregarlo a esta carpeta del
# paquete, sin tocar este build.sh de nuevo. Segundo header real encontrado
# 2026-08-30 (android_sysvshm/sys/shm.h, lo necesita el parche
# 0018-dlls_winex11_drv_bitblt_c.patch) con el mismo patron que shm_utils.h.
RUN_POST_APPLY_PATCH="cp -r $INIT_DIR/packages/$package/android ."

HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"

# Same flag set as packages/wine-10.10, plus one Proton-specific addition:
#   --without-piper : disables the "protontts" feature (dlls/protontts), a
#   Proton-only addition that links against libpiper (Piper TTS). It is not
#   part of upstream Wine, MiceWine has no libpiper dependency package, and
#   text-to-speech is not needed for this use case, so it is disabled
#   explicitly instead of silently falling back.
#   NOTE: confirmed via `referencia/proton-wine/configure.ac` (read directly,
#   not assumed) that this fork does NOT add any EasyAntiCheat/BattlEye/Steam
#   -specific ./configure flags -- grepping configure.ac for
#   eac/battleye/steam only matches unrelated symbols (HOST_ARCH cpu loop,
#   dlls/oleacc, protontts). Those runtime-shim pieces live in Valve's
#   separate `proton` launcher-scripts repo, not in proton-wine itself, so
#   there is nothing else to disable here.
#   --disable-amd_ags_x64 : dlls/amd_ags_x64/unixlib.c hardcodes
#   `#include <xf86drm.h>` (libdrm) sin guardarlo con el HAVE_XF86DRM_H que el
#   propio ./configure ya calcula -- MiceWine-Packages no tiene libdrm en las
#   DEPENDENCIES de este paquete (ni falta le hace: AMD AGS son extensiones
#   especificas de GPUs AMD GCN/RDNA, sin ningun uso en el hardware Adreno/Mali
#   real de Android). Sin este flag, el build entero fallaba silenciosamente
#   a mitad de "make" (fatal error: 'xf86drm.h' file not found) -- el script
#   generado por build-all.sh no tiene "set -e", asi que ese fallo NO detenia
#   la ejecucion, dejaba pasar a "make install" (que a su vez volvia a fallar
#   por lo mismo, sin instalar nada real) y despues a post-install.sh (que
#   solo baja Gecko/Mono), terminando en un .rat que parecia exitoso pero
#   solo tenia Gecko/Mono, sin ningun binario real de Wine adentro. Bug real
#   encontrado y corregido 2026-08-16, ver
#   docs/investigacion/wine-arm64ec-fexcore-proton.md seccion 17.
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
				--without-capi \
				--without-piper \
				--disable-amd_ags_x64"

# gstreamer/gst-plugins-* removidos de DEPENDENCIES 2026-08-30: causaban un
# loop infinito real en build-all.sh (el grafo de dependencias nunca resuelve
# si un paquete listado no existe como carpeta en packages/ -- gstreamer.org
# sigue caido, ver el mismo fix ya aplicado en wine-9.20-aarch64 2026-08-23 y
# docs/build/fix-freedesktop-org-caido-migracion-gitlab.md). Mismo motivo del
# --without-gstreamer de arriba.
DEPENDENCIES="libX11 libXext libXcomposite libXrender libXcursor libXrandr libXxf86vm libXinerama libXfixes libXi Vulkan-Headers Vulkan-Loader libglvnd pulseaudio freetype libgnutls"
