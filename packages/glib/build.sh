PKG_VER=2.82.4
PKG_CATEGORY="Core"
SRC_URL=https://download.gnome.org/sources/glib/${PKG_VER%.*}/glib-$PKG_VER.tar.xz
# -Dsysprof=disabled agregado 2026-08-30: sin este flag, meson auto-detecta
# libsysprof-capture-4.a del SISTEMA (Debian/WSL x86_64, /usr/lib/x86_64-linux-gnu/) y lo
# linkea contra el build cross-compilado -- "is incompatible with aarch64linux". No es
# opcional deshabilitarlo a mano, meson lo habilita automaticamente si detecta la lib
# instalada en el host, sin considerar cross-compile.
MESON_ARGS="-Dintrospection=disabled -Druntime_dir=$PREFIX/var/run -Dlibmount=disabled -Dman-pages=enabled -Dtests=false -Dselinux=disabled -Dlibelf=disabled -Dsysprof=disabled"
CFLAGS="-I$PREFIX/include"
LDFLAGS="-L$PREFIX/lib -l:libiconv.a"
DEPENDENCIES="zlib libiconv pcre2 libffi"
