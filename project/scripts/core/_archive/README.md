# Core Scripts Archive

Este directorio contiene scripts obsoletos o deprecated de la arquitectura core del juego que han sido reemplazados por versiones mejoradas.

## Contenido

### AudioManagerSimple.gd
- **Estado**: OBSOLETO (deprecated)
- **Razón**: Reemplazado completamente por `AudioManager.gd`
- **Descripción**: Era un shim minimal que solo proporcionaba métodos noop
- **Cuándo se puede eliminar**: Seguro eliminar - nunca se referencia en código activo
- **Versión activa**: `scripts/core/AudioManager.gd`

### BiomeTextureGenerator.gd
- **Estado**: OBSOLETO (versión 1)
- **Razón**: Reemplazado por `BiomeTextureGeneratorV2.gd` (mejorada)
- **Descripción**: Generador de texturas procedurales v1
- **Cuándo se puede eliminar**: Seguro eliminar - V2 es completamente funcional
- **Versión activa**: `scripts/core/BiomeTextureGeneratorV2.gd`
- **Versiones alternativas**: BiomeTextureGeneratorEnhanced.gd, BiomeTextureGeneratorMosaic.gd (ambas deprecated)

### BiomeTextureGeneratorEnhanced.gd
- **Estado**: OBSOLETO (versión "enhanced")
- **Razón**: Reemplazado por `BiomeTextureGeneratorV2.gd`
- **Descripción**: Intento de mejora pero no fue la versión final seleccionada
- **Cuándo se puede eliminar**: Seguro eliminar - V2 es preferida
- **Versión activa**: `scripts/core/BiomeTextureGeneratorV2.gd`

### BiomeTextureGeneratorMosaic.gd
- **Estado**: OBSOLETO (versión "mosaic")
- **Razón**: Reemplazado por `BiomeTextureGeneratorV2.gd`
- **Descripción**: Generador especializado con patrón tipo mosaico
- **Cuándo se puede eliminar**: Seguro eliminar - V2 es preferida
- **Versión activa**: `scripts/core/BiomeTextureGeneratorV2.gd`

### TestHasNode.gd
- **Estado**: OBSOLETO (testing only)
- **Razón**: Script de prueba para validar funcionamiento de has_node()
- **Descripción**: Testing manual, nunca instanciado en el game loop
- **Cuándo se puede eliminar**: Seguro eliminar - no tiene dependencias
- **Impacto de eliminar**: NINGUNO

## Historial de Cambios

- **20 Oct 2025**: Archivos movidos a `_archive/` durante auditoría de código completa
- Ver `docs/audit_report.txt` para detalles completos de la auditoría

## Notas Importantes

⚠️ **Estos archivos están arquivados SOLO como referencia histórica.**

- NO se deben usar en nuevo código
- NO se cargan dinámicamente en el juego
- NO afectan el funcionamiento actual
- Pueden ser eliminados definitivamente en futuras versiones

Si necesitas recuperar funcionalidad de estos scripts, usa las versiones activas referenciadas en cada entrada.

## Versiones Activas Recomendadas

| Archivo Archivado | Reemplazado Por | Estado |
|---|---|---|
| AudioManagerSimple.gd | AudioManager.gd | ✅ Activo |
| BiomeTextureGenerator*.gd | BiomeTextureGeneratorV2.gd | ✅ Activo |
| TestHasNode.gd | - | 🗑️ Eliminar |

---

*Documentación generada: 20 de octubre de 2025*
*Auditoría: Spellloop Code Quality Audit*
