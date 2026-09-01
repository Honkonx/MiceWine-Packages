PKG_VER=v17.0
PKG_CATEGORY="Core"
SRC_URL=https://github.com/pulseaudio/pulseaudio/archive/refs/tags/$PKG_VER.tar.gz
MESON_ARGS="-Dalsa=disabled -Dx11=disabled -Dgtk=disabled -Dopenssl=disabled -Dgsettings=disabled -Ddoxygen=false -Ddatabase=simple -Dsystemd=disabled -Dudev=disabled -Dgstreamer=disabled -Dglib=disabled -Dman=false -Dbashcompletiondir=false -Dzshcompletiondir=false -Dtests=false"
CFLAGS="-I$PREFIX/include"
CPPFLAGS="-I$PREFIX/include"
LDFLAGS="-L$PREFIX/lib -Wl,--undefined-version -lintl"
# Bug real corregido 2026-08-30: pulseaudio incluye libintl.h (instalado por el
# subproject "proxy-libintl" del propio build de glib, que pisa el header de
# fakeintl con uno que remapea dgettext/bindtextdomain/etc a simbolos
# "g_libintl_*") pero nunca declaraba "-lintl" -- el .so real que SI exporta
# esos simbolos (confirmado con nm -D, 9 simbolos g_libintl_* reales) ya
# estaba instalado en $PREFIX/lib/libintl.so(.8), pulseaudio simplemente
# nunca lo linkeaba. Error real: "ld.lld: error: undefined symbol:
# g_libintl_dgettext" (y 2 mas) al linkear libpulsecommon-17.0.so.
# glib agregado 2026-08-30 (gap real encontrado en auditoria de grafo de dependencias):
# pulseaudio SI necesita glib de verdad para sus modulos (libgio-2.0.so/libglib-2.0.so
# se linkean directo, confirmado en el log real de build), pero no estaba declarado --
# sin esto, el orden topologico de build-all.sh no garantiza que glib ya este compilado
# antes de intentar pulseaudio.
DEPENDENCIES="libtool libsndfile glib"
