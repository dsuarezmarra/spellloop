# Sistema de Spawn y Oleadas - SpellLoop

## 📋 Resumen

El sistema de spawn controla la progresión del juego a través de 5 fases, oleadas estructuradas, eventos especiales, bosses y élites. El juego base dura ~20 minutos, después del cual comienza el "modo infinito" con escalado exponencial.

---

## 🎯 Estructura de Fases

| Fase | Tiempo | Nombre | Tiers | Max Enemigos | Spawn Rate | Descripción |
|------|--------|--------|-------|--------------|------------|-------------|
| 1 | 0-5 min | Introducción | T1 | 25 | 0.8/s | Aprende mecánicas |
| 2 | 5-10 min | Escalada | T1-T2 | 40 | 1.2/s | Dificultad aumenta |
| 3 | 10-15 min | Desafío | T1-T3 | 55 | 1.6/s | Enemigos peligrosos |
| 4 | 15-20 min | Caos | T1-T4 | 70 | 2.0/s | Todos los enemigos |
| 5 | 20+ min | Infinito | T1-T4 | 100+ | 2.5+/s | Escalado exponencial |

### Distribución de Tiers por Fase

**Fase 1:**
- Tier 1: 100%

**Fase 2:**
- Tier 1: 70%
- Tier 2: 30%

**Fase 3:**
- Tier 1: 50%
- Tier 2: 35%
- Tier 3: 15%

**Fase 4:**
- Tier 1: 35%
- Tier 2: 30%
- Tier 3: 25%
- Tier 4: 10%

**Fase 5 (Infinito):**
- Tier 1: 25%
- Tier 2: 30%
- Tier 3: 30%
- Tier 4: 15%

---

## 🌊 Sistema de Oleadas

Las oleadas son micro-eventos que ocurren cada **30 segundos** dentro de cada fase.

### Tipos de Oleadas

| Tipo | Enemigos | Delay | Descripción |
|------|----------|-------|-------------|
| `normal` | 5 | 0.3s | Spawn estándar |
| `swarm` | 15 | 0.1s | Muchos T1 rápidos |
| `heavy` | 3 | 0.5s | Enemigos tier+1 |
| `mixed` | 8 | 0.2s | Variedad forzada |
| `ambush` | 10 | 0.05s | Rodean al jugador |

### Secuencias por Fase

**Fase 1:** `normal → normal → normal → mixed` (loop)

**Fase 2:** `normal → mixed → normal → swarm → heavy` (loop)

**Fase 3:** `mixed → heavy → swarm → normal → ambush → heavy` (loop)

**Fase 4:** `heavy → swarm → ambush → mixed → heavy → swarm → ambush` (loop)

**Fase 5:** `ambush → heavy → swarm → heavy → ambush → swarm → heavy → ambush` (loop)

---

## 👹 Sistema de Bosses

### Schedule de Bosses

| Minuto | Boss | Descripción |
|--------|------|-------------|
| 5 | El Conjurador Primigenio | Invoca esqueletos |
| 10 | El Corazón del Vacío | Atrae al jugador |
| 15 | El Guardián de Runas | Escudos rotativos |
| 20 | Minotauro de Fuego | Carga + Enrage |

### Después del Minuto 20
Los bosses rotan en orden cada 5 minutos con escalado aplicado.

### Comportamiento del Boss
- **Advertencia:** 5 segundos antes de aparecer
- **Spawn Rate:** Reducido al 30% durante pelea
- **Distancia:** 400 unidades (más cerca que enemigos normales)

---

## ⭐ Sistema de Élites

| Configuración | Valor |
|---------------|-------|
| Primer spawn | Minuto 2 |
| Intervalo base | 150 segundos |
| Varianza | ±30 segundos |
| Max activos | 1 |
| Max por partida (base) | 8 |
| En fase infinita | +2 cada 5 min |

### Stats de Élite
- HP: x3
- Daño: x2
- Tamaño: x1.5
- XP: x10
- Velocidad: x0.85 (más lento)
- Aura: Dorada

---

## 🎪 Eventos Especiales

### Eventos Programados

| Minuto | Evento | Efecto |
|--------|--------|--------|
| 3 | `breather` | Sin spawns, cura 10% HP |
| 7.5 | `swarm_event` | x3 spawns de T1 (20s) |
| 12 | `elite_surge` | 2 élites en 30s |
| 17 | `swarm_event` | x3 spawns de T1 (20s) |
| 19 | `breather` | Sin spawns, cura 10% HP |

### Tipos de Eventos

**swarm_event** (20s)
- Spawn x3
- Solo Tier 1
- "🐜 ¡ENJAMBRE!"

**elite_surge** (30s)
- 2 élites con 10s entre ellos
- "⭐ ¡SURGIMIENTO ÉLITE!"

**death_wave** (15s)
- Spawn x5
- Todos los tiers
- "💀 ¡OLEADA DE MUERTE!"

**breather** (10s)
- Sin spawns
- Cura 10% HP
- "💚 Momento de respiro..."

---

## 📈 Escalado Infinito (Post-Minuto 20)

Cada 5 minutos después del minuto 20:

| Stat | Multiplicador | Cap |
|------|---------------|-----|
| HP | x1.5 | x10 |
| Daño | x1.3 | x5 |
| Spawn Rate | x1.2 | 8/s |
| XP | x1.4 | Sin cap |
| Max Enemies | +15 | 200 |

### Ejemplo de Escalado

| Minuto | HP Mult | Daño Mult | Spawn Rate |
|--------|---------|-----------|------------|
| 20 | x1.0 | x1.0 | 2.5/s |
| 25 | x1.5 | x1.3 | 3.0/s |
| 30 | x2.25 | x1.69 | 3.6/s |
| 35 | x3.38 | x2.20 | 4.3/s |
| 40 | x5.06 | x2.86 | 5.2/s |
| 45 | x7.59 | x3.71 | 6.2/s |
| 50 | x10.0 (cap) | x4.83 | 7.5/s |

---

## 🗺️ Patrones de Spawn

| Patrón | Uso | Descripción |
|--------|-----|-------------|
| `random` | Default | Aleatorio alrededor del jugador |
| `directional` | Oleadas | Desde una dirección (±22.5°) |
| `surround` | Emboscadas | Equidistantes en círculo |
| `cluster` | Packs | Grupo compacto |
| `line` | Cargas | En fila desde un punto |

### Distancias de Spawn

- **Mínima:** 500 unidades
- **Máxima:** 700 unidades
- **Boss:** 400 unidades

---

## 🎮 Integración

### Archivos Involucrados

```
project/scripts/
├── data/
│   ├── EnemyDatabase.gd    # Datos de 24 enemigos + 4 bosses
│   └── SpawnConfig.gd      # Configuración de spawn/fases/oleadas
├── managers/
│   └── WaveManager.gd      # Control de oleadas y eventos
└── core/
    └── EnemyManager.gd     # Spawn físico de enemigos
```

### Señales de WaveManager

```gdscript
signal phase_changed(phase_num: int, phase_config: Dictionary)
signal wave_started(wave_type: String, wave_config: Dictionary)
signal wave_completed(wave_type: String)
signal boss_incoming(boss_id: String, seconds_until: float)
signal boss_spawned(boss_id: String)
signal boss_defeated(boss_id: String)
signal elite_spawned(enemy_id: String)
signal special_event_started(event_name: String, event_config: Dictionary)
signal special_event_ended(event_name: String)
signal game_phase_infinite()
```

### API de Debug

```gdscript
# En WaveManager
force_spawn_wave("swarm")
force_spawn_boss("minotauro_de_fuego")
force_spawn_elite()
skip_to_phase(3)

# En EnemyManager
spawn_specific_enemy("lobo_de_cristal", position)
spawn_boss("el_guardian_de_runas", position)
spawn_elite("titan_arcano", position)
```

---

## 📊 Resumen de Progresión

```
MIN 0-5:   ████░░░░░░  Fase 1 - Solo T1, tranquilo
MIN 5:     ████████░░  ⚔️ BOSS: El Conjurador Primigenio
MIN 5-10:  ██████░░░░  Fase 2 - T1+T2, ritmo aumenta
MIN 10:    ████████░░  ⚔️ BOSS: El Corazón del Vacío
MIN 10-15: ████████░░  Fase 3 - T1-T3, intenso
MIN 15:    ██████████  ⚔️ BOSS: El Guardián de Runas
MIN 15-20: ██████████  Fase 4 - Todos los tiers, caos
MIN 20:    ██████████  ⚔️ BOSS: Minotauro de Fuego
MIN 20+:   ████████████████  Fase 5 - INFINITO ∞
```

---

## ✅ Checklist de Implementación

- [x] SpawnConfig.gd con toda la configuración
- [x] WaveManager.gd con lógica de oleadas
- [x] EnemyManager.gd actualizado con nuevos métodos
- [x] EnemyDatabase.gd con método get_enemies_by_tier
- [ ] Integrar WaveManager en escena principal
- [ ] Conectar señales a UI para anuncios
- [ ] Testing de cada fase
- [ ] Balanceo fino de números
