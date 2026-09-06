PKG_VER="9.0-arm64ec-1"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine Proton 9 ARM64EC ($PKG_VER)"

# Este paquete apunta a arm64ec (ARM nativo), NO x86_64 -- mismo patron que
# wine-10.1-arm64ec-firetest (BLACKLIST_ARCH=x86_64, al reves de
# proton-wine-10.0/wine-10.10 que tienen BLACKLIST_ARCH=aarch64). Sin esto el
# build x86_64 intentaria compilar este paquete y fallaria en configure
# ("arm64ec PE cross-compiler not found").
BLACKLIST_ARCH=x86_64

# Fuente real: Pipetto-crypto/wine (fork de wine-mirror/wine), rama
# "proton-9.0-arm64ec" (NO es la misma rama/historial que "proton-9.0-x86_64",
# son dos ramas separadas que divergen bastante entre si -- confirmado con
# `curl -s https://api.github.com/repos/Pipetto-crypto/wine/branches?per_page=100`,
# ver docs/investigacion/wine-proton9-pipetto-plan.md). HEAD pineado al commit
# exacto (no la rama, que sigue recibiendo commits) para reproducibilidad,
# mismo criterio que proton-wine-10.0.
GIT_URL=https://github.com/Pipetto-crypto/wine
GIT_COMMIT=b44ef85be4fbf48c186b7df823be6c59762009ec

# Regla del proyecto (2026-08-30, .claude/rules/09-wine-esync-obligatorio.md):
# TODO Wine/Proton debe traer esync siempre. Verificado 2026-08-30 clonando
# esta rama real y leyendo el arbol fuente (no asumido): esync viene NATIVO,
# no como patch -- dlls/ntdll/unix/esync.c (1376 lineas), dlls/ntdll/unix/esync.h,
# server/esync.c y README.esync propio ya estan en el arbol, do_esync() se usa
# en dlls/ntdll/unix/sync.c. Ademas trae 3 commits propios de esync mas alla del
# soporte base ("esync: workaround for android", "esync: do not exit when
# processes aren't running with esync but server is", "esync: set CLOEXEC flag
# on opened filedescriptors" -- este ultimo del 2026-08-24, mismo dia del HEAD
# pineado). A diferencia de wine-arm64ec-andrerh-hangover (gap real documentado
# en su propio build.sh, 60+ conflictos contra wine-staging), esta rama de
# Pipetto NO necesita ningun patch de esync -- ya viene resuelto en la fuente.

# Los 3 patches "pipetto_*" que proton-wine-10.0 porta a mano (0036/0037/0039:
# ntdll noexec fallback, disable writewatch, locale android) NO se agregan aca
# -- son commits propios de esta misma rama de Pipetto (confirmado leyendo
# dlls/ntdll/unix/virtual.c y dlls/ntdll/unix/env.c: `#ifdef __ANDROID__` ya
# presente en las 3 zonas), aplicarlos de nuevo fallaria por "already applied".
# Lo mismo para 0001 (ntdll lower addresses), 0002 (android_network/dnsapi),
# 0004 (amd_ags_x64 disable), 0012/0015 (clipboard android sync) y 0032/0033
# (winebrowser android) de proton-wine-10.0 -- los 7 ya estan cubiertos como
# commits nativos de Pipetto en esta rama (verificado con grep real sobre el
# arbol clonado en referencia/personas/pipetto-crypto-2026-08-30/wine-proton9-arm64ec,
# 2026-08-30), NO se portan.
#
# 0040 (include_winternl_h, union SameTebFlags/SafeThunkCall) tampoco se porta:
# ningun archivo del arbol de Pipetto usa SafeThunkCall/InDebugPrint/HasFiberData
# (grep vacio), es una estructura que otro codigo de Wine 10 necesita pero que
# esta base de Wine 9 no referencia -- no hace falta para compilar.
#
# Unico patch real portado: 0001-gamenative_server_token_machineid.patch, copia
# literal de proton-wine-10.0/0038-gamenative_server_token_machineid.patch
# (mismo contexto exacto en server/token.c, confirmado con dry-run real
# `patch -p1` sobre una copia scratch del arbol clonado, aplico limpio sin
# fuzz). server/token.c en esta rama sigue leyendo /etc/machine-id sin guardia
# __ANDROID__ (Android no tiene ese archivo) -- Pipetto no lo resolvio en su
# propia rama, asi que MiceWine si necesita este patch.

# No hace falta RUN_POST_APPLY_PATCH con carpeta android/ (a diferencia de
# proton-wine-10.0, que copia android/shm_utils y android_sysvshm porque sus
# patches the412banner de winex11_drv/bitblt.c los necesitan). Este paquete no
# aplica esos patches (ver arriba, area 0018 esta en la lista "NO portar sin
# verificar a fondo" de docs/investigacion/wine-proton9-pipetto-plan.md
# seccion 3.c -- Pipetto ya resuelve winex11_drv con su propio codigo) y ademas
# --without-xshm (mas abajo) deshabilita por completo la rama de codigo que
# usa sys/shm.h en dlls/winex11.drv/bitblt.c (confirmado: ese include esta
# guardeado por HAVE_X11_EXTENSIONS_XSHM_H, que nunca se define con --without-xshm).

HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"

# Mismo flag set que wine-10.1-arm64ec-firetest (paquete arm64ec real de
# referencia), con --disable-amd_ags_x64 y --without-piper agregados igual que
# proton-wine-10.0 (ambas dlls existen en este arbol -- dlls/amd_ags_x64 y
# dlls/protontts confirmados presentes -- y las mismas razones de proton-wine-10.0
# aplican: sin libdrm real en MiceWine-Packages para amd_ags_x64, y sin
# libpiper para protontts/TTS). Todas las flags de abajo confirmadas contra el
# configure.ac REAL de esta rama (2026-08-30, no copiadas a ciegas de
# proton-10 -- ver aclocal.m4 WINE_CONFIG_MAKEFILE para confirmar que
# --disable-<dll> es un mecanismo generico de Wine, no necesita AC_ARG_ENABLE
# explicito por modulo).
#
# --disable-wineandroid.drv: bug real corregido 2026-09-06. wineandroid.drv es el
# driver grafico propio de Wine para Android, y su Makefile construye un APK con
# gradle. En el WSL de build no hay gradle, asi que el target moria con:
#
#   /bin/sh: 1: gradle: not found
#   make: *** [Makefile:1468: dlls/wineandroid.drv/wine-debug.apk] Error 127
#
# MiceWine NO usa ese driver -- usa winex11.drv contra el X server (Xlorie/XDisplay),
# asi que el APK que Wine intenta construir nunca se usaria. Desactivarlo ademas
# hace que configure verifique de verdad las libs de X y habilite winex11_drv
# (configure ~17128: si wineandroid y winemac estan ambos en "no", exige X libs y
# setea enable_winex11_drv), que es exactamente lo que queremos.
#
# Nota historica: los otros paquetes de Wine (wine-10.10, proton-wine-10.0, etc.)
# NO tienen este flag y aun asi produjeron .rat validos -- porque antes del `set -e`
# que se agrego hoy a build-all.sh, el fallo de este target no abortaba el script:
# `make` fallaba, se seguia igual al `make install`, y se instalaba todo lo demas
# que si habia compilado. Con set -e el fallo pasa a ser fatal, que es lo correcto,
# pero obliga a desactivar explicitamente lo que antes fallaba en silencio.
#
# --with-mingw: RUTA EXPLICITA al clang de llvm-mingw, no "gcc" (bug real corregido
# 2026-09-06). Con "--with-mingw=gcc" el configure de Wine NO fuerza un compilador
# uniforme para las arquitecturas cruzadas -- solo lo hace si el valor es "clang" o
# "*/clang" (configure linea ~10563: `case "x$with_mingw" in xclang|x*/clang) eval
# "${wine_arch}_CC=\$with_mingw" ;;`). Sin eso, cada arch autodetecta por su cuenta y
# los objetos de arm64ec-windows terminaban compilandose con el GCC x86_64 del sistema:
#
#   x86_64-w64-mingw32-gcc -c -o dlls/ntdll/arm64ec-windows/signal_x86_64.o ...
#   /tmp/ccFZB8Uo.s:5159: Error: junk at end of line, first unrecognized character is ','
#   make: *** [Makefile:110827: dlls/ntdll/arm64ec-windows/signal_x86_64.o] Error 1
#
# (GNU as no puede ensamblar lo que ese GCC emite para un target arm64ec). Se usa la
# ruta absoluta y no "clang" pelado porque el PATH que arma build-all.sh pone el
# sistema y cache/mingw/bin ANTES que cache/llvm-mingw/bin -- un "clang" sin ruta
# resolveria al clang del sistema, que no tiene targets mingw/arm64ec.
#
# --enable-archs=aarch64,arm64ec: arm64ec es el modo WoW64 nativo de Wine (ARM
# corriendo codigo x86_64 traducido) -- requiere TOOLCHAIN_TRIPLE apuntando al
# target aarch64 del NDK (lo pone build-all.sh automaticamente segun el ARCH
# de la corrida, gracias a BLACKLIST_ARCH=x86_64 de arriba).
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
				--with-mingw=$INIT_DIR/cache/llvm-mingw/bin/clang \
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
				--disable-amd_ags_x64 \
				--disable-wineandroid.drv"

# --without-gstreamer: NO es porque el codigo de Pipetto sea incompatible --
# esta rama SI tiene commits activos de gstreamer (winegstreamer: make opengl
# conditional / port add-envvar-to-gate-media-converter from Proton-GE,
# 2026-08-19/24). Se deshabilita por el mismo motivo real que proton-wine-10.0
# y wine-10.1-arm64ec-firetest: MiceWine-Packages no tiene paquetes
# gstreamer/gst-plugins-* (gstreamer.org caido, ver
# docs/build/fix-freedesktop-org-caido-migracion-gitlab.md) -- si se agregan
# esos paquetes a futuro, este flag se puede sacar sin tocar el codigo fuente.
DEPENDENCIES="libX11 libXext libXcomposite libXrender libXcursor libXrandr libXxf86vm libXinerama libXfixes libXi Vulkan-Headers Vulkan-Loader libglvnd pulseaudio freetype libgnutls"
