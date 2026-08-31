PKG_VER=0.4.5-1
PKG_CATEGORY="Box64"
PKG_PRETTY_NAME="Box64"

GIT_URL=https://github.com/ptitSeb/box64
GIT_COMMIT=e99ca51299ec897e6a96da6d00983d90406a836f
# -DBIONIC=1 -DTERMUX=0 -DHAVE_TRACE=0 agregados 2026-08-30: confirmado contra el workflow
# oficial real de CI (The412Banner/Nightlies, Box64all-standalone-nightly.yml, matrix
# "Bionic") que compila box64 para Android/bionic -- usa estas 3 flags ademas de
# -DANDROID=1/-DARM_DYNAREC=1/-DBAD_SIGNAL=1 que ya teniamos. Ese mismo workflow NO usa
# "make install"/"cmake --install" -- copia el binario "box64" compilado directo, mismo
# mecanismo que el custom-make-install.sh ya aplicado a este paquete (confirma que el
# workaround era el enfoque correcto, no un parche improvisado).
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo -DANDROID=1 -DBAD_SIGNAL=1 -DARM_DYNAREC=1 -DBIONIC=1 -DTERMUX=0 -DHAVE_TRACE=0"
BLACKLIST_ARCH=x86_64
