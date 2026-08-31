# Índice de MiceWine-Packages/

- `README.md`
- `build-all.sh` — build de todos los paquetes.
- `create-core-rat.sh` — genera el paquete core.
- `build_config/` — cross-files de Meson (aarch64, x86_64).
- `common/` — assets comunes (Addons, CoreFonts, DirectX, OpenAL, Start Menu).
- `packages/` — recetas/fuentes de cada paquete individual (93 paquetes: Box64 en varias versiones, Vulkan-*, GStreamer, libX*, etc.).
- `tools/` — scripts de empaquetado (`create-rat-pkg.sh`, `create-repository-index.sh`, `download-external-dependencies.sh`, `move-components-rat.sh`, `wcp-tzst-to-rat.sh`).
- `built-pkgs/` — salida de `.rat` generados manualmente fuera de `build-all.sh` (ver `built-pkgs/README.md`).
- `.github/workflows/build.yml` — CI.
