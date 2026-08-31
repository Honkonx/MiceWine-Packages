# Version 2026-08-30 (fecha real de esta sesion): usamos el HEAD real de la rama
# principal en vez de intentar reproducir el "2607" del .rat prebuilt ya publicado
# (built-pkgs/FEXCore/FEXCore-2607-aarch64.rat). "2607" NO es un tag/commit de
# FEX-Emu/FEX -- FEX-Emu no usa ese esquema de versionado (confirmado: `git describe`
# sobre este repo no encuentra tags, sin CHANGELOG/VERSION en la raiz, ver
# docs/auditoria/referencias/wine-forks/fex-emu.md). Es el `versionName` propio que
# le puso el tercero que armo ese build (The412Banner/Nightlies, ver profile.json real
# documentado en docs/investigacion/wine-arm64ec-fexcore-proton.md seccion 8:
# "FEXCore-2607", versionCode 4, sin ningun commit de FEX-Emu asociado al numero).
# Ese .rat existente NO fue compilado ni empaquetado por MiceWine-Packages -- fue
# descargado ya compilado (.wcp de The412Banner/Nightlies) y solo re-empaquetado a
# .rat con tools/wcp-tzst-to-rat.sh (modo "fexcore"). Esta version (20260830) es una
# compilacion nueva real desde el repo oficial, deliberadamente NO garantizada
# identica a la "2607" ya publicada -- verificar en un dispositivo real antes de
# reemplazar esa version en produccion.
PKG_VER=51c241d
PKG_CATEGORY="FEXCore"
PKG_PRETTY_NAME="FEXCore"

# Repo oficial real (confirmado con `curl https://api.github.com/repos/FEX-Emu/FEX`,
# no asumido): "FEX-Emu/FEX", descripcion real "A fast usermode x86 and x86-64
# emulator for Arm64 Linux". HEAD real de "main" al 2026-08-30 (confirmado con
# `curl https://api.github.com/repos/FEX-Emu/FEX/commits/main`):
#   51c241d1f884179736c898d9f07896d391c253cc
#   "Merge pull request #5881 from Sonicadvance1/222 -- UnixLib: Removes old
#   non-unixlib handling" -- nombre del PR es una senal positiva (toca justo el
#   mecanismo de unixlib que MiceWine ya depende, ver docs/arm-translation/fexcore.md),
#   no se investigo el diff completo de ese PR puntual en esta tarea (fuera de
#   alcance: solo se pidio dejar el build.sh listo, no auditar cada commit).
GIT_URL=https://github.com/FEX-Emu/FEX
GIT_COMMIT=51c241d1f884179736c898d9f07896d391c253cc

# MATIZ IMPORTANTE, distinto de Box64: FEXCore NO tiene ningun modo de build para
# Android/bionic -- lo que MiceWine necesita de este repo (libarm64ecfex.dll /
# libwow64fex.dll, la "unixlib" WoW64 que carga Wine arm64ec por nombre, ver
# docs/arm-translation/fexcore.md) es en realidad un build para **Windows** (PE,
# arquitectura arm64/arm64ec), no un binario ARM64-Linux/bionic como box64. Esto se
# confirmo leyendo el CMakeLists.txt real de este repo:
#   - Source/Windows/CMakeLists.txt: "if (ARCHITECTURE_arm64ec) add_subdirectory(ARM64EC)
#     elseif (ARCHITECTURE_arm64) add_subdirectory(WOW64)" -- son 2 sub-builds
#     mutuamente excluyentes segun el processor detectado.
#   - Source/Windows/ARM64EC/CMakeLists.txt linea 1: "add_library(arm64ecfex SHARED ...)"
#     -> produce libarm64ecfex.dll (prefijo "lib" es el default real de CMake para
#     shared libs en toolchains estilo MinGW, no hace falta forzarlo).
#   - Source/Windows/WOW64/CMakeLists.txt linea 1: "add_library(wow64fex SHARED ...)"
#     -> produce libwow64fex.dll.
#   - CMakeLists.txt raiz (top), deteccion de arquitectura via
#     CMAKE_SYSTEM_PROCESSOR (que el toolchain MinGW setea = MINGW_TRIPLE):
#     "arm64ec-w64-mingw32" matchea "^arm64ec" -> ARCHITECTURE_arm64ec=1 (build ARM64EC).
#     "aarch64-w64-mingw32" matchea "^aarch64" pero NO "^arm64ec" -> ARCHITECTURE_arm64
#     =1 solo, ARCHITECTURE_arm64ec sigue apagado (build WOW64).
# Es decir: hacen falta 2 compilaciones cruzadas distintas (2 MINGW_TRIPLE distintos)
# para los 2 archivos que ya trae el .rat existente -- build-all.sh/setupPackage()
# solo soportan UNA invocacion de cmake por paquete (ver build-all.sh, rama
# "elif [ -e CMakeLists.txt ]"). Se resuelve con este build.sh haciendo SOLO el build
# ARM64EC (el primario, el que setupPackage() genera automaticamente) y
# custom-make-install.sh haciendo el segundo build (WOW64) a mano, mismo patron que
# ya usa proton-wine-10.0/build.sh (RUN_POST_APPLY_PATCH) para trabajo fuera del
# flujo estandar. Ver custom-make-install.sh para el detalle completo del segundo build.
#
# Toolchain: wine/toolchain_mingw.cmake de box64 (usado arriba en WOWBox64) es
# GENERICO para cualquier triple MinGW -- pero FEX-Emu/FEX trae su PROPIO
# Data/CMake/toolchain_mingw.cmake (mismo nombre, contenido equivalente: setea
# CMAKE_SYSTEM_NAME Windows, CMAKE_C_COMPILER ${MINGW_TRIPLE}-clang, etc, tomando
# MINGW_TRIPLE como cache var) -- se usa el de este mismo repo clonado, no el de box64.
# El binario real "arm64ec-w64-mingw32-clang" (y "aarch64-w64-mingw32-clang" para el
# segundo build) lo aporta llvm-mingw (cache/llvm-mingw), ya descargado por
# build-all.sh setupBuildEnv() desde 2026-08-26 especificamente para arm64ec-windows
# (ver comentario real ahi: "Necesario para wine-10.1-arm64ec-firetest y
# wine-arm64ec-andrerh-hangover") -- no hace falta agregar ninguna DEPENDENCIES nueva
# ni tocar build-all.sh para esto.
#
# Flags de FEX desactivados explicitamente (todos opciones reales de su
# CMakeLists.txt raiz, confirmadas leyendo el archivo, no inventadas):
#   -DBUILD_TESTING=OFF, -DBUILD_THUNKS=OFF, -DBUILD_FEXCONFIG=OFF : componentes de
#   testing/thunking/config-UI que MiceWine no necesita para la unixlib WoW64 en si
#   (mismo criterio que --disable-tests en proton-wine-10.0/build.sh).
#   -DENABLE_LTO=OFF : LTO esta ON por default en upstream (mas lento, mayor uso de
#   RAM en build) -- se apaga para una primera compilacion de prueba mas rapida y
#   menos propensa a quedarse sin memoria en CI; reactivar si el build real confirma
#   que hay margen de recursos.
#   -DENABLE_OFFLINE_TELEMETRY=OFF : sin necesidad de telemetria en un build de
#   distribucion de terceros (MiceWine), mismo criterio que Box64 no manda telemetria.
CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=../Data/CMake/toolchain_mingw.cmake -DMINGW_TRIPLE=arm64ec-w64-mingw32 -DBUILD_TESTING=OFF -DBUILD_THUNKS=OFF -DBUILD_FEXCONFIG=OFF -DENABLE_LTO=OFF -DENABLE_OFFLINE_TELEMETRY=OFF"

# BLACKLIST_ARCH: a diferencia de box64 (BLACKLIST_ARCH=x86_64, porque box64 SI
# depende de $ARCH/$CC de build-all.sh -- compila un binario aarch64-linux-android
# real), este paquete no usa el toolchain NDK Android para nada (todo el compilador
# real es el MinGW/llvm-mingw de arriba, fijo, sin importar $ARCH) -- se deja sin
# BLACKLIST_ARCH para que corra en cualquier corrida de build-all.sh (aarch64 o
# x86_64 host build), ya que el resultado (DLLs PE arm64/arm64ec) es el mismo
# artefacto sin importar que arquitectura de $ARCH este compilando el resto de
# paquetes en esa corrida. NO VERIFICADO con un build real en esta tarea (pedido
# explicito del usuario: dejar listo, no lanzar el build completo todavia).
