PKG_VER="9.0-1"
PKG_CATEGORY="Wine"
PKG_PRETTY_NAME="Wine Proton 9 (Pipetto, $PKG_VER)"

BLACKLIST_ARCH=aarch64

# Fuente real: fork de Pipetto-crypto (Pipetto-crypto/wine) de Wine
# vainilla+Proton 9, rama "proton-9.0-x86_64" -- confirmado con
# `curl -s https://api.github.com/repos/Pipetto-crypto/wine/branches?per_page=100`
# (regla 08: se listaron las 8 ramas reales del repo, no solo la default
# "master") y clonado real en
# referencia/personas/pipetto-crypto-2026-08-30/wine-proton9-x86_64
# (--single-branch --branch proton-9.0-x86_64). A diferencia de
# packages/proton-wine-10.0 (KreitinnSoftware/proton-wine, patch-set
# numerado 0001..0040 aplicado sobre un fork con menos commits propios de
# Android), Pipetto commitea directo sobre su propio fork: cada fix Android
# es un commit individual (no hay carpeta patches/ en su repo). Investigacion
# completa en docs/investigacion/wine-proton9-pipetto-plan.md.
# HEAD real de esa rama al 2026-08-30: pinneado por commit, no por rama (la
# rama sigue recibiendo commits -- mismo criterio que proton-wine-10.0, para
# reproducibilidad del build).
GIT_URL=https://github.com/Pipetto-crypto/wine
GIT_COMMIT=5836d17499f1d32d9a66a4a3ae5de0be0c266279

# esync -- regla obligatoria .claude/rules/09-wine-esync-obligatorio.md.
# Verificado leyendo la fuente real (no asumido): esync viene NATIVO en este
# fork, sin necesidad de ningun patch.
#   `git show 5836d17...:dlls/ntdll/unix/esync.c` -- existe, 1376 lineas,
#   implementacion completa basada en eventfd (mismo autor upstream, Zebediah
#   Figura). `server/esync.c` y `server/esync.h` tambien presentes.
#   Ademas Pipetto ya tiene, como commits propios sobre esa misma rama (`git
#   log --oneline | grep -i esync`): "esync: workaround for android",
#   "esync: do not exit when processes aren't running with esync but server
#   is", "esync: avoid leaking fds between processes" (este ultimo del mismo
#   2026-08-19, incluido en el HEAD pinneado arriba) -- es decir, esync no
#   solo esta presente, tiene ademas sus propios fixes de Android/fd-leak ya
#   integrados. No hace falta agregar ningun patch para cumplir la regla 09.
#
# Patches de proton-wine-10.0 evaluados y su resultado real (seccion 3 de
# wine-proton9-pipetto-plan.md), verificado con dry-run real
# (`git apply --check` y `patch -p1 --dry-run -ts`, mismo mecanismo que usa
# build-all.sh applyPatches()) contra el arbol clonado de Pipetto:
#
#   NO se portan (ya cubiertos por commits propios de Pipetto, el dry-run
#   confirma que el patch de proton-10 NO aplica porque el codigo ya es
#   distinto -- mismo terreno, otra implementacion):
#     0001-ntdll-lower-addresses-for-virtual-allocations.patch -- Pipetto ya
#       tiene su propio fix Android en virtual.c (guardas __ANDROID__ en
#       lineas 95/310/422/960, commit propio "ntdll: Android address fix").
#     0002-android_network.patch -- Pipetto ya tiene "dnsapi: rework Android
#       NDK dnsapi implementation" / "Support Android NDK networking".
#     0004-dlls_amd_ags_x64_unixlib_c.patch -- ver mas abajo (mismo bug real,
#       pero resuelto via --disable-amd_ags_x64 en vez de patch a unixlib.c).
#     0012-dlls_user32_clipboard_c.patch / 0015-dlls_win32u_clipboard_c.patch
#       -- Pipetto ya tiene "user32: synchronize Android and Wine clipboard".
#     0032/0033-programs_winebrowser_*.patch -- Pipetto ya tiene "winebrowser:
#       open http/https through Android browsers" (+"part2").
#     0036/0037/0039-pipetto_*.patch -- estos 3 son diffs literales de
#       commits del propio Pipetto (confirmado autor pipetto-crypto en
#       proton-wine-10.0), ya estan en esta fuente por definicion; el
#       dry-run confirma "patch does not apply" porque el codigo ya tiene
#       el cambio (hunk already present).
#     0040-include_winternl_h.patch -- especifico de arm64ec/FEX (agrega
#       ProcessFexHardwareTso, MemoryFexStatsShm, etc.), sin relacion con
#       esta build x86_64-only; no aplica limpio y no hace falta.
#
#   SI se porta (unico patch real sin equivalente en Pipetto, dry-run limpio
#   confirmado 2026-08-30):
#     0001-gamenative_server_token_machineid.patch (este paquete) -- puerto
#       directo de proton-wine-10.0/patches/0038-gamenative_server_token_
#       machineid.patch. Ver comentario propio dentro del .patch.
#
# No hace falta copiar shm_utils.h/shm.h como en proton-wine-10.0: Pipetto ya
# trae su propio workaround nativo de shm_open() en dlls/ntdll/unix/virtual.c
# (linea 96, `static int shm_open(...)` bajo #ifdef __ANDROID__), no depende
# de un header externo como el patch the412banner que si lo necesita en
# proton-wine-10.0.
#
# Bug real encontrado y corregido 2026-08-30: SI hace falta RUN_POST_APPLY_PATCH
# para restaurar archivos que faltan en el arbol de Pipetto. Confirmado
# leyendo el arbol real clonado (`git cat-file -e <pin>:<ruta>` ->
# "does not exist"): el commit "initial commit" (5ca0b2dd88d) con el que
# Pipetto crea la rama proton-9.0-x86_64 SI trae los Makefile.in/fuentes que
# referencian estos archivos, pero los archivos en si nunca quedaron
# commiteados en esa rama -- el repo tiene un .gitignore con el patron
# "build*" (confirmado con `git check-ignore -v dlls/wineandroid.drv/
# build.gradle.in` -> ".gitignore:1:build*") que coincide por nombre con
# archivos fuente reales cuyo nombre empieza con "build" y probablemente los
# excluyo sin querer del "git add -A" original al armar esa rama (el patron
# esta pensado para ignorar carpetas build/, no estos .in/.h). Se confirmo
# con un barrido completo (`git ls-tree -r <rama-hermana> | grep
# '/build[^/]*$'` + `git cat-file -e <pin>:<archivo>` por cada uno) que hay
# exactamente 2 archivos de este tipo que SI hacen falta para compilar
# (el resto -- tools/buildimage, tools/gitlab/build-*, tools/gitlab/build.yml
# -- son scripts sueltos de CI/imagenes que ningun Makefile.in referencia,
# confirmado con `grep -rl` sobre todos los Makefile.in del arbol, no hacen
# falta):
#   dlls/wineandroid.drv/build.gradle.in : rompe primero, con
#     "makedep: error: open build.gradle.in : No such file or directory" ->
#     "config.status: error: could not create Makefile" -> "make: *** No rule
#     to make target '__tooldeps__'." (el error real original visto en el log
#     de build-all.sh).
#   tools/winebuild/build.h : rompe despues de resolver el de arriba, con
#     "../tools/winebuild/import.c:31: error: build.h: No such file or
#     directory" durante la compilacion real de wine-tools (HOST_BUILD_MAKE).
# El propio Pipetto ya tiene evidencia de este mismo hueco: existe una rama
# separada `wine-9.4-android` (no la que usa este paquete) cuyo unico commit
# por encima de la base es "Add mock build script" -- agrega ambos archivos
# de una. Se verifico que en esa rama dlls/wineandroid.drv/Makefile.in y
# tools/winebuild/Makefile.in son byte-a-byte identicos a los de la rama
# proton-9.0-x86_64 pineada aca (`diff` vacio en los dos casos), asi que el
# contenido de esa rama es compatible con esta. Se copiaron ambos archivos
# (contenido real de Pipetto, no inventado) a packages/proton-wine-9.0-x86_64/
# android/, con la misma ruta relativa que tienen en el arbol fuente, y se
# restauran juntos con RUN_POST_APPLY_PATCH -- mismo mecanismo que
# proton-wine-10.0 (cwd = raiz del arbol fuente ya clonado, ver
# build-all.sh applyPatches()), un solo comando "cp -r ... ." (sin "&&" ni
# ";" porque $RUN_POST_APPLY_PATCH se expande sin comillas como argv literal)
# que fusiona el contenido de android/ sobre la raiz del arbol preservando
# las rutas relativas de cada archivo.
#
# Bug real encontrado y corregido 2026-08-30 (segunda vuelta, en el rebuild
# posterior al fix de arriba): el tools/winebuild/build.h restaurado desde
# la rama hermana wine-9.4-android NO era compatible con tools/winebuild/
# import.c de la rama proton-9.0-x86_64 pineada aca. Error real de compile
# (log completo en WSL ~/mw-build/logs/proton-wine-9.0-x86_64-error_log.txt):
#   import.c:526: error: 'DLLSPEC' has no member named 'base'/'limit'
#   import.c:528: error: 'DLLSPEC' has no member named 'ordinals'
#   import.c:786/1100/1328: error: 'thumb_mode' undeclared
#   import.c:796/797: error: implicit declaration of 'arm64_page'/'arm64_pageoff'
# Causa real (confirmada leyendo el codigo, no adivinada): el Makefile.in de
# wine-9.4-android es byte-a-byte identico al de esta rama (por eso el chequeo
# original no detecto nada raro), pero build.h SI diverge -- wine-9.4-android
# trae un build.h de una version de Wine POSTERIOR (con el refactor "winebuild:
# Introduce exports struct", que mete base/limit/ordinals dentro de un
# `struct exports exports;` anidado en vez de sueltos en DLLSPEC, y que en
# 2024 tambien removio el soporte ARM32 -- por eso ya no declara thumb_mode
# ni arm64_page()/arm64_pageoff()). El import.c real de proton-9.0-x86_64 es
# de ANTES de ese refactor (sigue usando spec->base/limit/ordinals sueltos y
# sigue llamando arm64_page/arm64_pageoff/thumb_mode), asi que necesitaba el
# build.h viejo, no el nuevo.
# Se ubico el build.h real y correcto asi (sin inventar nada): en el repo
# cacheado (WSL ~/mw-build/cache/proton-wine-9.0-x86_64, remoto origin =
# Pipetto-crypto/wine con `git fetch origin master wine-9.0` agregados), se
# comparo tools/winebuild/{import.c,main.c,utils.c,parser.c} del commit
# pineado (5836d17...) contra el mismo path en distintos puntos de la
# historia real de Wine (upstream, via `git log --all`). El commit
# 866f17c147e4d76b6dd14ad98030918c341cde38 (2024-01-10, justo al lado del tag
# real "wine-9.0" -- `git rev-parse wine-9.0` = a9cb627f1d67a24bfa4bce18281558
# dc6759c51a, `diff` de build.h entre ambos: vacio, son el mismo archivo) da
# import.c/main.c/utils.c/parser.c IDENTICOS byte-a-byte al pin de Pipetto
# (`diff` vacio en los 4; spec32.c difiere en una sola linea, el unico cambio
# real de Pipetto sobre wine-9.0 en ese directorio). O sea: el build.h correcto
# es literalmente el build.h de Wine 9.0 oficial (wine-mirror/wine, tag
# wine-9.0) -- Pipetto nunca lo toco, solo se perdio por el .gitignore
# "build*" ya documentado arriba. Se reemplazo el contenido de
# android/tools/winebuild/build.h por ese build.h real de wine-9.0 (392
# lineas, DLLSPEC con base/limit/ordinals sueltos + declaraciones de
# arm64_page/arm64_pageoff/thumb_mode/float_abi_option), misma ruta relativa,
# restaurado con el mismo RUN_POST_APPLY_PATCH de abajo (no hizo falta tocar
# el mecanismo, solo el contenido del archivo).
RUN_POST_APPLY_PATCH="cp -r $INIT_DIR/packages/$package/android/. ."

HOST_BUILD_CONFIGURE_ARGS="--enable-win64 --without-x"
HOST_BUILD_FOLDER="$INIT_DIR/workdir/$package/wine-tools"
HOST_BUILD_MAKE="make -j $(nproc) __tooldeps__ nls/all"
OVERRIDE_PREFIX="$(realpath $PREFIX/../wine)"

# Mismo set de flags que packages/proton-wine-10.0 (mismo motivo real en cada
# caso, confirmado contra el configure.ac REAL de este arbol, no copiado a
# ciegas -- ver seccion 4 del plan):
#   --disable-amd_ags_x64 : dlls/amd_ags_x64/unixlib.c en esta fuente tambien
#     hardcodea `#include <xf86drm.h>` sin guardarlo con HAVE_XF86DRM_H
#     (confirmado leyendo el archivo real), mismo bug que ya rompe
#     silenciosamente el build de proton-wine-10.0 sin este flag (ver ese
#     build.sh lineas 60-73 para el detalle completo del fallo). MiceWine-
#     Packages no tiene libdrm en las DEPENDENCIES de este paquete.
#   --without-piper : "protontts" (dlls/protontts) depende de libpiper, sin
#     paquete en MiceWine-Packages, no hace falta para este caso de uso.
#   --without-gstreamer : a diferencia de proton-wine-10.0 (donde el fork no
#     tenia trabajo activo en gstreamer), ESTA rama de Pipetto SI tiene
#     commits recientes y activos de winegstreamer ("winegstreamer: make
#     opengl conditional", "backport add-envvar-to-gate-media-converter from
#     GE-Proton", 2026-08-19) -- es decir, el codigo de Pipetto esta pensado
#     para compilar CON gstreamer. Se deja deshabilitado igual, mismo motivo
#     real que proton-wine-10.0 (no por incompatibilidad de codigo): no
#     existen paquetes gstreamer/gst-plugins-* en MiceWine-Packages
#     (gstreamer.org caido / migracion a GitLab, ver
#     docs/build/fix-freedesktop-org-caido-migracion-gitlab.md). Si en el
#     futuro se agregan esos paquetes, este flag es el primer candidato a
#     revertir para este paquete en particular (Pipetto ya lo soporta mejor
#     que proton-wine-10.0).
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

# gstreamer/gst-plugins-* removidos por el mismo motivo real ya documentado
# en proton-wine-10.0 (2026-08-30) y wine-9.20-aarch64 (2026-08-23): causaban
# un loop infinito en build-all.sh (paquete listado en DEPENDENCIES que no
# existe como carpeta en packages/ nunca resuelve), gstreamer.org sigue caido.
DEPENDENCIES="libX11 libXext libXcomposite libXrender libXcursor libXrandr libXxf86vm libXinerama libXfixes libXi Vulkan-Headers Vulkan-Loader libglvnd pulseaudio freetype libgnutls"
