# Bug real encontrado 2026-08-27: la SRC_URL anterior era un archive.tar.gz autogenerado de
# GitLab (snapshot de tag), que NO trae ./configure pre-generado -- necesita autoreconf real.
# El aclocal de este entorno WSL no logra escribir aclocal.m4 para ningun caso de prueba
# (confirmado con configure.ac minimos triviales), asi que autoreconf fallaba en seco con
# "must install xorg-macros 1.15 or later" aunque el .m4 correcto SI estaba presente en el
# prefix compartido -- causa raiz real de aclocal sin resolver, mientras tanto se evita el
# problema entero usando el tarball oficial de x.org (ya trae ./configure generado, no
# necesita autoreconf/aclocal en absoluto). Esto tambien es mas correcto en general: es la
# fuente de distribucion real del proyecto, no un snapshot de git.
PKG_VER=1.8.9
PKG_CATEGORY="Core"
SRC_URL=https://www.x.org/releases/individual/lib/libX11-$PKG_VER.tar.xz
CONFIGURE_ARGS="--host=$TOOLCHAIN_TRIPLE host_alias=$TOOLCHAIN_TRIPLE --enable-malloc0returnsnull"
LDFLAGS="-L$PREFIX/lib -landroid-shmem"
DEPENDENCIES="xorgproto libxcb xtrans xorg-utils-macros android-shmem"
