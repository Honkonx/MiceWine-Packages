PKG_VER=0.4.5-1
PKG_CATEGORY="WOWBox64"
PKG_PRETTY_NAME="WOWBox64"

# WOWBox64 NO es un proyecto separado -- es un sub-target del propio repo oficial de
# Box64 (ptitSeb/box64), confirmado leyendo su CMakeLists.txt real (no asumido):
#   option(WOW64 "Set to ON if you want a WOW64 PE build in addition")
#   if(WOW64 AND ARM_DYNAREC)
#       ExternalProject_Add(wowbox64 SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/wine/wow64"
#           CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=.../wine/toolchain_mingw.cmake ...)
# El target "wowbox64" compila wine/wow64/ (wowbox64.c + partes del propio dynarec
# ARM64 de box64, ver wine/wow64/CMakeLists.txt real) con un toolchain MinGW cruzado
# (aarch64-w64-mingw32-clang, via wine/toolchain_mingw.cmake), produciendo un PE DLL
# real: OUTPUT_NAME "wowbox64", SUFFIX ".dll" (confirmado en wine/wow64/CMakeLists.txt
# lineas 165-168). Es la misma fuente/commit que ya usa packages/box64-0.4.5-1 --
# mismo GIT_URL/GIT_COMMIT, se agrega solo -DWOW64=1 al CMAKE_ARGS existente.
#
# Coincide con el built-pkg ya existente (built-pkgs/WOWBox64/WOWBox64-0.3.6-aarch64.rat,
# pkg-header version=0.3.6): ese .rat corresponde exactamente al tag v0.3.6 de este mismo
# repo (commit 03d220b1d297a9e5be81760833b014edf9dfe7ab, verificado via GitHub API
# refs/tags/v0.3.6) -- confirma que la fuente real de ese .rat prebuilt ya era
# ptitSeb/box64 con WOW64=1, no un binario de The412Banner/Nightlies como se
# sospechaba antes de verificar (aunque Nightlies tambien redistribuye WOWBox64
# empaquetado por su cuenta, ver docs/auditoria/referencias/wine-forks/the412banner-nightlies.md).
# Este paquete actualiza esa version a la ultima real de box64-0.4.5-1 (commit
# e99ca51299ec897e6a96da6d00983d90406a836f, mismo que ya usa MiceWine-Packages hoy),
# en vez de quedarse en v0.3.6.
GIT_URL=https://github.com/ptitSeb/box64
GIT_COMMIT=e99ca51299ec897e6a96da6d00983d90406a836f
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo -DANDROID=1 -DBAD_SIGNAL=1 -DARM_DYNAREC=1 -DWOW64=1"
BLACKLIST_ARCH=x86_64

# El toolchain aarch64-w64-mingw32-clang que pide wine/toolchain_mingw.cmake ya esta
# disponible en este proyecto via cache/llvm-mingw (build-all.sh setupBuildEnv(), agregado
# 2026-08-26 para wine-10.1-arm64ec-firetest/wine-arm64ec-andrerh-hangover) -- no hace
# falta ninguna DEPENDENCIES nueva para esto, solo que el PATH ya lo incluya (build-all.sh
# ya lo hace incondicionalmente para toda la corrida, no por-paquete).
