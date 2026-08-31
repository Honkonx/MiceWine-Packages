PKG_VER=1.17.0
PKG_CATEGORY="Core"
SRC_URL=https://gitlab.freedesktop.org/xorg/proto/xcbproto/-/archive/xcb-proto-$PKG_VER/xcbproto-xcb-proto-$PKG_VER.tar.gz
CONFIGURE_ARGS=" "

# Bug real corregido 2026-08-30: el autogen.sh del propio tarball de xcb-proto
# termina con "exec configure" si no esta seteado NOCONFIGURE (confirmado
# leyendo el autogen.sh real bajado) -- eso configura el source dir en el
# lugar, y despues build-all.sh corre "../configure" de nuevo desde build_dir
# sobre el mismo source dir, lo que autoconf rechaza con "source directory
# already configured; run make distclean there first". Exportado acá (se
# propaga como env var al build.sh generado que se ejecuta despues, ya que
# setupPackage() hace "source" de este archivo) para que autogen.sh NO
# autoconfigure y deje que sea build-all.sh el unico que corre configure.
export NOCONFIGURE=1
