PKG_VER="andrerh-arm64ec-3ea3a14"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine ARM64EC (AndreRH/wine, base de Hangover, no-Proton)"

# Bug real encontrado 2026-08-25 (misma familia que wine-10.1-arm64ec-firetest): faltaba este
# blacklist -- el build x86_64 lo intentaba compilar (targetea arm64ec/aarch64) y fallaba,
# cortando el resto de la cola de paquetes x86_64 via el "exit 0" que build-all.sh hace ante
# cualquier fallo.
BLACKLIST_ARCH=x86_64

# Preparado 2026-08-23 a pedido del usuario: "dejar todo listo solo para compilar" un Wine ARM
# via Hangover/arm64ec, en paralelo al build oficial de Wine 9.20/9.0/10 con prefix.
#
# Se investigaron 2 caminos reales (ver docs/wine/plan-hangover-arm64ec-completo.md e
# intento-compilacion-hangover-arm64ec.md):
#   1. AndreRH/hangover (el wrapper real, con Box64/QEMU/FEX embebidos como motor de traduccion
#      x86->ARM) -- su propio COMPILE.md pide bylaws-llvm-mingw + "sudo make install" contra un
#      host Linux glibc generico, NO contra un sysroot NDK Android/Bionic. Cross-compilar eso a
#      Android es un problema aparte que su documentacion no cubre.
#   2. AndreRH/wine, rama arm64ec (el Wine base que Hangover usa como submodulo, PERO tambien
#      compilable solo, sin el wrapper Box64/QEMU/FEX de Hangover -- MiceWine ya tiene su propio
#      WOWBox64/FEXCore como paquetes separados, asi que el motor de traduccion embebido de
#      Hangover es redundante para este proyecto).
# Se eligio la opcion 2: mismo pipeline de build-all.sh que ya demostro compilar Wine con
# --enable-archs=aarch64,arm64ec contra el NDK (ver packages/wine-10.1-arm64ec-firetest), sin
# necesitar el toolchain bylaws-llvm-mingw ni el build system propio de Hangover.
#
# GIT_COMMIT = tip real de AndreRH/wine rama arm64ec al 2026-08-23 (referencia/wine-forks/andrerh-wine-arm64ec).
GIT_URL=https://github.com/AndreRH/wine
GIT_COMMIT=3ea3a14941b6a122b892c84141ce9662c008081e

# IMPORTANTE -- estado real de los parches de MiceWine (18 commits reales de
# KreitinnSoftware/wine rama wine-10.1, extraidos via git format-patch, no simulados):
# Solo 2/18 aplican limpio contra esta base (git am -3, verificado real en WSL):
#   - 0002 (Create Disk D:/Z:) -- estructuralmente igual en AndreRH/wine, aplico sin tocar nada.
#   - 0010 (bcrypt warn-once) -- cambio aislado y chico, aplico limpio.
# Los otros 16 tienen conflictos reales de merge (no solo desfasaje de lineas de contexto):
#   - 0001, 0003, 0004, 0005: tocan codigo que diverge estructuralmente en AndreRH/wine.
#   - 0006 (eventfd_synchronization) : conflicto en 60+ archivos (server/*, ntdll/unix/*) --
#     AndreRH/wine ya tiene su propio mecanismo de sync distinto, no es un simple parche encima.
#   - 0007 (shm_open/shm_unlink para esync): depende de 0006, tambien en conflicto.
#   - 0008,0009,0011 al 0018 (cadena de joystick XInput/DInput + win32u focus fix): AndreRH/wine
#     tiene una base de dlls/xinput1_3/main.c y dlls/dinput/* distinta a la que estos 7+ commits
#     iterativos de KreitinnSoftware fueron escribiendo encima -- necesitan re-escribirse a mano
#     contra la base real de AndreRH, no son aplicables como diff directo.
# Documentado con detalle real (log de conflicto por archivo) en
# docs/wine/hangover-listo-para-compilar-2026-08-23.md. Este build.sh compila la base +
# los 2 parches que si aplican -- NO tiene paridad completa con el Wine Proton/normal de
# MiceWine todavia. Portar los 16 parches restantes es trabajo pendiente de una ronda dedicada.
PATCHES="patches/0002-ntdll-Create-Disk-D-as-Android-Internal-Storage-and-.patch patches/0010-bcrypt-Warn-only-one-time-BCryptCreateHash-and-BCryp.patch"

# Regla del proyecto (2026-08-30, explicita del usuario): TODO Wine debe traer
# esync siempre. Auditado 2026-08-30: este paquete es el UNICO de los 6 de Wine
# de MiceWine que NO tiene esync (confirmado, sin esync.c en la base AndreRH/wine
# ni en los 2 patches ya aplicados). Se intento cerrar el gap con los patches
# the412banner (dlls_ntdll_unix_esync_c.patch/server_esync_c.patch, los mismos
# usados en proton-wine-10.0) -- FALLARON en dry-run real ("No file to patch"):
# esos patches son modificaciones incrementales sobre un esync.c YA EXISTENTE
# (que KreitinnSoftware si trae nativo), no una implementacion completa. El
# patch real que hace falta es el completo "eventfd_synchronization from
# wine-staging" (como el que SI usa wine-10.1-arm64ec-firetest en su
# patches/0006), pero ese mismo patch de KreitinnSoftware ya esta documentado
# arriba como con 60+ archivos en conflicto contra la base de AndreRH/wine (su
# propio mecanismo de sync diverge estructuralmente). Cerrar este gap requiere
# adaptar a mano el patch de wine-staging contra la base real de AndreRH, o
# buscar un port de esync ya hecho para AndreRH/wine especificamente -- trabajo
# real pendiente de una ronda dedicada, no forzado aca para no dejar un build
# roto.

HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"

# Mismos flags que packages/wine-10.1-arm64ec-firetest (probado real: la fase de configure de
# ese paquete resolvio el toolchain NDK sin errores) -- arm64ec es el modo WoW64 nativo de Wine,
# no necesita el runtime Box64/QEMU/FEX de Hangover porque MiceWine ya trae WOWBox64/FEXCore
# como paquetes separados para la traduccion x86->ARM real.
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
