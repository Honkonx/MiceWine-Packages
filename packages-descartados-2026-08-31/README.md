# packages-descartados-2026-08-31/

Paquetes de Wine sacados de la cola de build por pedido explícito del usuario (2026-08-31): "quita eso lo importante son los wine oficiales de micewine y los adaptados de pipetto los proton 9 x86 y arm".

No son parte de las fuentes prioritarias del proyecto (Wine oficial de MiceWine: `wine-9.20`, `wine-9.20-aarch64`, `wine-10.10`, `proton-wine-10.0`; Proton 9 adaptado de Pipetto: `proton-wine-9.0-x86_64`, `proton-wine-9.0-arm64ec`) y venían bloqueando builds completos de `build-all.sh` con errores reales propios (no relacionados a los fixes de esta sesión):

- `wine-10.1-arm64ec-firetest`: error real de compilación en `dlls/acledit` — asm inline x86 (`int $0x29`, `__fastfail`) sin guardas `#ifdef` para target arm64ec, en `winnt.h:7336`.
- `wine-arm64ec-andrerh-hangover`: gap real de esync documentado en `.claude/rules/09-wine-esync-obligatorio.md` (el patch completo de wine-staging tiene 60+ archivos en conflicto contra esta base), pendiente de una ronda dedicada que nunca se priorizó.

No se borra el código fuente ni los patches (regla de no perder trabajo) — quedan acá por si se retoman más adelante. `build-all.sh` no los ve mientras estén en esta carpeta (fuera de `packages/`).
