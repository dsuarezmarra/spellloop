# Balance Pass 2.5: Endurance Survival System

## Objetivo
Permitir runs ultra-largas (4-8+ horas) para jugadores excepcionales con builds muy optimizadas, sin crear un "death timer" matemático inevitable.

## Cambio de Filosofía

### Antes (Pass 2)
- Escalado exponencial puro: `mult = pow(1.06, t)`
- A 60 min: HP = 33x, DMG = 14x
- A 120 min: HP = 1088x, DMG = 192x ← **IMPOSIBLE**

### Ahora (Pass 2.5)
- Sistema de **3 fases** con transición suave
- Escalado se aplana gradualmente hacia asintótico
- Compensación via frecuencia de elites aumentada

## Sistema de 3 Fases

### Phase 1: Early/Mid (0-30 min)
| Parámetro | Rate | Valor @30min |
|-----------|------|--------------|
| HP        | 6%/min | 5.74x |
| Damage    | 4.5%/min | 3.75x |
| Spawn     | 3.5%/min | 2.81x |
| Speed     | 1.5%/min | 1.56x |
| Attack Spd| 2%/min | 1.81x |
| Elite Freq| - | 1.0x |

**Comportamiento:** Exponencial agresivo para ranking competitivo.

### Phase 2: Late Competitive (30-90 min)
| Parámetro | Rate | Valor @90min |
|-----------|------|--------------|
| HP        | 2%/min | ~19.8x |
| Damage    | 1.5%/min | ~9.2x |
| Spawn     | 2%/min | ~7.6x (cap 6.0) |
| Speed     | → cap | 1.8x |
| Attack Spd| → cap | 2.0x |
| Elite Freq| 2.5%/min | ~4.5x (cap 3.5) |

**Comportamiento:** Exponencial suave con transición smoothstep. Elites empiezan a aparecer más.

### Phase 3: Endurance (90+ min)
| Parámetro | Fórmula | Valor @240min | Valor @480min |
|-----------|---------|---------------|---------------|
| HP        | log | ~27x | ~32x |
| Damage    | log | ~12x | ~14x |
| Spawn     | 0.8%/min | ~6x (cap) | ~6x (cap) |
| Elite Freq| lineal | ~3.5x (cap) | ~3.5x (cap) |

**Fórmula logarítmica:**
```
mult = base_at_T2 * (1 + LOG_RATE * ln(1 + (t - T2) / LOG_SCALE))
```

**Comportamiento:** Crecimiento asintótico. La dificultad sigue subiendo pero nunca explota. La presión viene de:
- Más elites (hasta 3.5x frecuencia base)
- Más densidad de enemigos (cap 6x)
- Todas las velocidades al máximo
- El cansancio del jugador después de horas

## Tabla de Referencia Completa

| Minuto | Fase | HP Mult | DMG Mult | Spawn | Elite Freq |
|--------|------|---------|----------|-------|------------|
| 10     | Early | 1.79x | 1.55x | 1.41x | 1.0x |
| 20     | Early | 3.21x | 2.41x | 1.99x | 1.0x |
| 30     | Trans | 5.74x | 3.75x | 2.81x | 1.0x |
| 45     | Late | 9.2x | 5.4x | 4.0x | 1.45x |
| 60     | Late | 12.0x | 6.5x | 5.0x | 2.1x |
| 90     | Trans | 19.8x | 9.2x | 6.0x | 3.5x |
| 120    | Endur | 22.5x | 10.5x | 6.0x | 3.5x |
| 180    | Endur | 25.5x | 11.5x | 6.0x | 3.5x |
| 240    | Endur | 27.0x | 12.2x | 6.0x | 3.5x |
| 360    | Endur | 29.5x | 13.2x | 6.0x | 3.5x |
| 480    | Endur | 31.5x | 14.0x | 6.0x | 3.5x |

## Caps Globales

| Stat | Cap | Razón |
|------|-----|-------|
| Speed | 1.8x | Jugabilidad (que se puedan esquivar) |
| Attack Speed | 2.0x | Ventanas de reacción |
| Spawn | 6.0x | Performance + pantalla legible |
| Elite Freq | 3.5x | Balance de recompensas |
| HP | 80x | Soft cap (nunca se alcanza) |
| Damage | 40x | Soft cap (nunca se alcanza) |

## Smoothstep Transitions

Las transiciones entre fases usan interpolación Hermite suave:
```gdscript
func _smoothstep(t, edge0, edge1):
    x = (t - edge0) / (edge1 - edge0)
    return x * x * (3 - 2*x)
```

Esto evita "saltos" perceptibles cuando cambia la fase.

## Archivos Modificados

1. **DifficultyManager.gd** - Sistema de 3 fases completo
2. **EnemyDatabase.gd** - `should_spawn_elite()` acepta `elite_freq_mult`
3. **EnemyManager.gd** - Pasa `elite_freq_mult` al check de spawn
4. **BalanceDebugger.gd** - Muestra fase actual en logs

## Señales Nuevas

```gdscript
signal phase_changed(new_phase: int, phase_name: String)
```

Se emite cuando el juego transiciona entre fases.

## Verificación

Ejecutar con F10 (BalanceDebugger) activo. Los logs mostrarán:
```
[BALANCE DEBUG] 🎯 [Late] @ min 60: HP=12.00x DMG=6.50x SPAWN=5.00x ELITE=2.10x
```

## Expectativa de Gameplay

- **Run promedio:** 30-50 minutos (Phase 1)
- **Run buena:** 60-90 minutos (Phase 2)
- **Run excepcional:** 2-4 horas (Phase 3)
- **Run legendaria:** 4-8+ horas (posible con build perfecta y sin errores)

El sistema nunca hace la run matemáticamente imposible. La muerte viene por:
1. Acumulación de errores
2. Fatiga del jugador
3. Overwhelm por densidad + elites
4. Bad luck (combinación de elites difíciles)
