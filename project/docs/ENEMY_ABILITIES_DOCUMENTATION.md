# 📜 DOCUMENTACIÓN COMPLETA DE HABILIDADES DE ENEMIGOS

## Índice
1. [Sistema de Habilidades](#sistema-de-habilidades)
2. [Enemigos Tier 1 (Normales)](#tier-1---enemigos-normales)
3. [Enemigos Tier 2 (Intermedios)](#tier-2---enemigos-intermedios)
4. [Enemigos Tier 3 (Avanzados)](#tier-3---enemigos-avanzados)
5. [Enemigos Tier 4 (Elite)](#tier-4---enemigos-elite)
6. [BOSSES](#bosses)
7. [Habilidades Élite Especiales](#habilidades-élite-especiales)
8. [Tipos de Proyectiles](#tipos-de-proyectiles)
9. [Efectos Visuales y Placeholders](#efectos-visuales-y-placeholders)

---

## Sistema de Habilidades

### Clases Base de Habilidades
Ubicación: `scripts/enemies/abilities/`

| Clase | Descripción |
|-------|-------------|
| `EnemyAbility.gd` | Clase base abstracta con cooldown, rango y telegraph |
| `EnemyAbility_Melee.gd` | Ataques cuerpo a cuerpo |
| `EnemyAbility_Ranged.gd` | Proyectiles a distancia |
| `EnemyAbility_Aoe.gd` | Ataques de área |
| `EnemyAbility_Nova.gd` | Explosión de proyectiles en círculo |
| `EnemyAbility_Dash.gd` | Embestidas y cargas |
| `EnemyAbility_Teleport.gd` | Teletransporte |
| `EnemyAbility_Summon.gd` | Invocación de minions |

### Parámetros Comunes
```gdscript
# Clase Base EnemyAbility
id: String = "base_ability"
cooldown: float = 2.0
range_min: float = 0.0
range_max: float = 100.0
telegraph_time: float = 0.5  # Tiempo de advertencia visual
```

---

## TIER 1 - ENEMIGOS NORMALES
**Tiempo de aparición:** Desde el minuto 0

### 1. Esqueleto Aprendiz
**ID:** `tier_1_esqueleto_aprendiz`
**Arquetipo:** `melee`
**Tema/Color:** Hueso, gris pálido

| Parámetro | Valor |
|-----------|-------|
| HP Base | 20 |
| Daño Base | 6 |
| Velocidad | 45.0 |
| Rango de Ataque | 32.0 |
| Cooldown de Ataque | 1.2s |
| Radio de Colisión | 14.0 |
| XP | 1 |

**Habilidades:**
| Habilidad | Tipo | Descripción |
|-----------|------|-------------|
| Ataque Melee | `melee` | Golpe directo cuerpo a cuerpo |

**Sprites:**
- Estático: `assets/sprites/enemies/tier_1/esqueleto_aprendiz.png`
- Animado: `assets/sprites/enemies/tier_1/esqueleto_aprendiz_spritesheet.png`

---

### 2. Duende Sombrío
**ID:** `tier_1_duende_sombrio`
**Arquetipo:** `agile`
**Tema/Color:** Verde oscuro, sombras

| Parámetro | Valor |
|-----------|-------|
| HP Base | 12 (modificador: 0.6x) |
| Daño Base | 5 (modificador: 0.8x) |
| Velocidad | 70.0 (modificador: 1.4x) |
| Rango de Ataque | 28.0 |
| Cooldown de Ataque | 0.8s |
| Radio de Colisión | 12.0 |
| XP | 1 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Zigzag Movement | `passive` | Movimiento en zigzag al perseguir | Intervalo: 0.3s |
| Hit and Run | `passive` | Ataca y se aleja rápidamente | - |
| Ataque Melee Rápido | `melee` | Golpes rápidos y ligeros | CD: 0.8s |

**Sprites:**
- Estático: `assets/sprites/enemies/tier_1/duende_sombrio.png`
- Animado: `assets/sprites/enemies/tier_1/duende_sombrio_spritesheet.png`

---

### 3. Slime Arcano
**ID:** `tier_1_slime_arcano`
**Arquetipo:** `tank`
**Tema/Color:** Púrpura/azul, gelatinoso

| Parámetro | Valor |
|-----------|-------|
| HP Base | 35 (modificador: 1.75x) |
| Daño Base | 5 (modificador: 0.7x) |
| Velocidad | 25.0 (modificador: 0.6x) |
| Rango de Ataque | 24.0 |
| Cooldown de Ataque | 1.3s |
| Radio de Colisión | 12.0 |
| XP | 2 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Split on Death | `passive` | Se divide en slimes menores al morir | (Por implementar) |
| Ataque Melee | `melee` | Golpe pesado pero lento | CD: 1.3s |

**Sprites:**
- Estático: `assets/sprites/enemies/tier_1/slime_arcano.png`
- Animado: `assets/sprites/enemies/tier_1/slime_arcano_spritesheet.png`

---

### 4. Murciélago Etéreo
**ID:** `tier_1_murcielago_etereo`
**Arquetipo:** `flying`
**Tema/Color:** Gris oscuro, translúcido

| Parámetro | Valor |
|-----------|-------|
| HP Base | 10 (modificador: 0.5x) |
| Daño Base | 4 |
| Velocidad | 55.0 (modificador: 1.3x) |
| Rango de Ataque | 20.0 |
| Cooldown de Ataque | 0.7s |
| Radio de Colisión | 10.0 |
| XP | 1 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Erratic Movement | `passive` | Movimiento impredecible ondulante | Basado en sin() |
| Evasion | `passive` | Probabilidad de esquivar ataques | Chance: 15% |
| Ataque Rápido | `melee` | Picotazos rápidos | CD: 0.7s |

**Sprites:**
- Estático: `assets/sprites/enemies/tier_1/murcielago_etereo.png`
- Animado: `assets/sprites/enemies/tier_1/murcielago_etereo_spritesheet.png`

---

### 5. Araña Venenosa
**ID:** `tier_1_arana_venenosa`
**Arquetipo:** `debuffer`
**Tema/Color:** Verde veneno, negro

| Parámetro | Valor |
|-----------|-------|
| HP Base | 18 |
| Daño Base | 5 |
| Velocidad | 40.0 |
| Rango de Ataque | 30.0 |
| Cooldown de Ataque | 1.3s |
| Radio de Colisión | 14.0 |
| XP | 2 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Poison Attack | `status` | Aplica veneno al atacar | DPS: 2, Duración: 3.0s |
| Slow Attack | `status` | Ralentiza al objetivo | Slow: 20%, Duración: 2.0s |
| Mordisco Venenoso | `melee` | Ataque con efectos de estado | CD: 1.3s |

**Sprites:**
- Estático: `assets/sprites/enemies/tier_1/arana_venenosa.png`
- Animado: `assets/sprites/enemies/tier_1/arana_venenosa_spritesheet.png`

---

## TIER 2 - ENEMIGOS INTERMEDIOS
**Tiempo de aparición:** Desde el minuto 5

### Escalado Tier 2
- HP: x2.5
- Daño: x1.6
- Velocidad: x1.25
- XP: x2.2

---

### 1. Guerrero Espectral
**ID:** `tier_2_guerrero_espectral`
**Arquetipo:** `blocker`
**Tema/Color:** Azul fantasmal, armadura etérea

| Parámetro | Valor |
|-----------|-------|
| HP Base | 50 |
| Daño Base | 12 |
| Velocidad | 38.0 |
| Rango de Ataque | 36.0 |
| Cooldown de Ataque | 1.4s |
| Radio de Colisión | 16.0 |
| XP | 4 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Block Chance | `passive` | Puede bloquear ataques | Chance: 25%, Reducción: 70% |
| Counter Attack | `reactive` | Contraataca tras bloquear | Daño: 150% |
| Ataque Espectral | `melee` | Golpe con espada fantasmal | CD: 1.4s |

**Sprites:** `assets/sprites/enemies/tier_2/guerrero_espectral.png`

---

### 2. Lobo de Cristal
**ID:** `tier_2_lobo_de_cristal`
**Arquetipo:** `pack`
**Tema/Color:** Azul cristalino, blanco hielo

| Parámetro | Valor |
|-----------|-------|
| HP Base | 35 |
| Daño Base | 10 |
| Velocidad | 55.0 |
| Rango de Ataque | 32.0 |
| Cooldown de Ataque | 1.0s |
| Radio de Colisión | 15.0 |
| XP | 3 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Pack Bonus | `passive` | Más fuerte con aliados cerca | Radio: 200, +15% daño/aliado, +5% velocidad/aliado, Máx: 3 |
| Mordisco Cristalino | `melee` | Aplica bleed (como burn menor) | Daño: 2 DPS por 2s |

**Sprites:** `assets/sprites/enemies/tier_2/lobo_de_cristal.png`

---

### 3. Gólem Rúnico
**ID:** `tier_2_golem_runico`
**Arquetipo:** `tank`
**Tema/Color:** Piedra gris con runas doradas

| Parámetro | Valor |
|-----------|-------|
| HP Base | 90 (modificador: 2.0x) |
| Daño Base | 18 |
| Velocidad | 22.0 (modificador: 0.5x) |
| Rango de Ataque | 40.0 |
| Cooldown de Ataque | 2.0s |
| Radio de Colisión | 15.0 |
| XP | 5 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Stomp Attack | `aoe` | Pisotón de área | Radio: 60, CD: 5.0s |
| Damage Reduction | `passive` | Reduce daño recibido | Reducción: 20% |
| Puño de Piedra | `melee` | Golpe lento pero devastador | CD: 2.0s |

**Sprites:** `assets/sprites/enemies/tier_2/golem_runico.png`

---

### 4. Hechicero Desgastado
**ID:** `tier_2_hechicero_desgastado`
**Arquetipo:** `ranged`
**Tema/Color:** Túnica púrpura raída, aura oscura

| Parámetro | Valor |
|-----------|-------|
| HP Base | 30 |
| Daño Base | 14 |
| Velocidad | 30.0 |
| Rango de Ataque | 250.0 |
| Cooldown de Ataque | 2.0s |
| Radio de Colisión | 14.0 |
| XP | 4 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Ranged Attack | `projectile` | Dispara proyectil mágico | Velocidad: 200, Daño: 14 |
| Keep Distance | `passive` | Intenta mantener distancia | Distancia preferida: 180 |

**Sprites:** `assets/sprites/enemies/tier_2/hechicero_desgastado.png`

---

### 5. Sombra Flotante
**ID:** `tier_2_sombra_flotante`
**Arquetipo:** `phase`
**Tema/Color:** Negro oscuro, translúcido

| Parámetro | Valor |
|-----------|-------|
| HP Base | 28 |
| Daño Base | 11 |
| Velocidad | 45.0 |
| Rango de Ataque | 28.0 |
| Cooldown de Ataque | 1.2s |
| Radio de Colisión | 13.0 |
| XP | 4 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Phase Shift | `active` | Se vuelve intangible | Duración: 1.5s, CD: 6.0s, Velocidad: +50% |
| Toque Oscuro | `melee` | Aplica curse | Reducción curación: 30%, Duración: 4s |

**Sprites:** `assets/sprites/enemies/tier_2/sombra_flotante.png`

---

## TIER 3 - ENEMIGOS AVANZADOS
**Tiempo de aparición:** Desde el minuto 10

### Escalado Tier 3
- HP: x5.0
- Daño: x2.5
- Velocidad: x1.45
- XP: x4.5

---

### 1. Caballero del Vacío
**ID:** `tier_3_caballero_del_vacio`
**Arquetipo:** `charger`
**Tema/Color:** Armadura negra con vetas púrpuras

| Parámetro | Valor |
|-----------|-------|
| HP Base | 85 |
| Daño Base | 22 |
| Velocidad | 42.0 |
| Rango de Ataque | 38.0 |
| Cooldown de Ataque | 1.5s |
| Radio de Colisión | 18.0 |
| XP | 8 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Charge Attack | `dash` | Carga devastadora hacia el jugador | Velocidad: 300, Daño: x2.0, CD: 4.0s, Distancia: 200, Windup: 0.5s |
| Ataque de Espada | `melee` | Corte con espada del vacío | CD: 1.5s |

**Sprites:** `assets/sprites/enemies/tier_3/caballero_del_vacio.png`

---

### 2. Serpiente de Fuego
**ID:** `tier_3_serpiente_de_fuego`
**Arquetipo:** `trail`
**Tema/Color:** Naranja/rojo, llamas

| Parámetro | Valor |
|-----------|-------|
| HP Base | 60 |
| Daño Base | 18 |
| Velocidad | 55.0 |
| Rango de Ataque | 30.0 |
| Cooldown de Ataque | 1.0s |
| Radio de Colisión | 14.0 |
| XP | 7 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Fire Trail | `passive/zone` | Deja rastro de fuego al moverse | DPS: 8, Duración: 3.0s, Intervalo: 0.2s, Radio: 20 |
| Mordisco Ardiente | `melee` | Aplica burn | CD: 1.0s |

**Sprites:** `assets/sprites/enemies/tier_3/serpiente_de_fuego.png`

---

### 3. Elemental de Hielo
**ID:** `tier_3_elemental_de_hielo`
**Arquetipo:** `ranged`
**Tema/Color:** Azul hielo, cristales blancos

| Parámetro | Valor |
|-----------|-------|
| HP Base | 70 |
| Daño Base | 20 |
| Velocidad | 35.0 |
| Rango de Ataque | 280.0 |
| Cooldown de Ataque | 1.5s |
| Radio de Colisión | 16.0 |
| XP | 8 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Ranged Attack | `projectile` | Proyectil de hielo | Velocidad: 180 |
| Freeze Projectile | `status` | Los proyectiles congelan | Slow: 40%, Duración: 2.5s, Freeze chance: 10% (1s) |
| Keep Distance | `passive` | Mantiene distancia óptima | Distancia: 200 |

**Sprites:** `assets/sprites/enemies/tier_3/elemental_de_hielo.png`

---

### 4. Mago Abismal
**ID:** `tier_3_mago_abismal`
**Arquetipo:** `teleporter`
**Tema/Color:** Púrpura oscuro, negro vacío

| Parámetro | Valor |
|-----------|-------|
| HP Base | 55 |
| Daño Base | 28 |
| Velocidad | 32.0 |
| Rango de Ataque | 300.0 |
| Cooldown de Ataque | 2.2s |
| Radio de Colisión | 14.0 |
| XP | 9 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Ranged Attack | `projectile` | Proyectil del vacío | Velocidad: 160 |
| Teleport | `movement` | Se teletransporta para evadir | CD: 5.0s, Rango: 150, Threshold HP: 40% |

**Sprites:** `assets/sprites/enemies/tier_3/mago_abismal.png`

---

### 5. Corruptor Alado
**ID:** `tier_3_corruptor_alado`
**Arquetipo:** `support`
**Tema/Color:** Verde corrupto, alas negras

| Parámetro | Valor |
|-----------|-------|
| HP Base | 65 |
| Daño Base | 15 |
| Velocidad | 48.0 |
| Rango de Ataque | 34.0 |
| Cooldown de Ataque | 1.3s |
| Radio de Colisión | 16.0 |
| XP | 10 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Flying | `passive` | Movimiento de vuelo | - |
| Buff Allies | `support` | Potencia aliados cercanos | Radio: 150, +25% daño, +15% velocidad, Duración: 5s, CD: 8s |
| Garra Corrupta | `melee` | Ataque con garras | CD: 1.3s |

**Sprites:** `assets/sprites/enemies/tier_3/corruptor_alado.png`

---

## TIER 4 - ENEMIGOS ELITE
**Tiempo de aparición:** Desde el minuto 15

### Escalado Tier 4
- HP: x9.0
- Daño: x4.0
- Velocidad: x1.65
- XP: x9.0

---

### 1. Titán Arcano
**ID:** `tier_4_titan_arcano`
**Arquetipo:** `tank`
**Tema/Color:** Púrpura arcano, piedra con runas brillantes

| Parámetro | Valor |
|-----------|-------|
| HP Base | 200 (modificador: 2.5x) |
| Daño Base | Profile "high" → 6 × 4.0 = 24 |
| Velocidad | 25.0 |
| Rango de Ataque | 50.0 |
| Cooldown de Ataque | 2.2s |
| Radio de Colisión | 22.0 |
| XP | 18 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Stomp Attack | `aoe` | Pisotón devastador | Radio: 100, Daño: 40, CD: 4.0s |
| AoE Slam | `aoe` | Golpe de área | Radio: 80, CD: 6.0s |
| Damage Reduction | `passive` | Reducción de daño constante | Reducción: 30% |

**Sprites:** `assets/sprites/enemies/tier_4/titan_arcano.png`

---

### 2. Señor de las Llamas
**ID:** `tier_4_senor_de_las_llamas`
**Arquetipo:** `aoe`
**Tema/Color:** Naranja/rojo fuego, llamas constantes

| Parámetro | Valor |
|-----------|-------|
| HP Base | 140 |
| Daño Base | Profile "medium" → 5 × 4.0 = 20 |
| Velocidad | 35.0 |
| Rango de Ataque | 200.0 |
| Cooldown de Ataque | 1.7s |
| Radio de Colisión | 20.0 |
| XP | 16 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Ranged Attack | `projectile` | Proyectil de fuego | Elemento: fire |
| Fire Zone | `zone` | Crea zona de fuego persistente | Radio: 80, DPS: 15, Duración: 5s, CD: 7s |
| Burn Aura | `aura` | Daño pasivo a enemigos cercanos | Radio: 50, DPS: 5 |

**Sprites:** `assets/sprites/enemies/tier_4/senor_de_las_llamas.png`

---

### 3. Reina del Hielo
**ID:** `tier_4_reina_del_hielo`
**Arquetipo:** `aoe`
**Tema/Color:** Azul hielo, cristales, corona de escarcha

| Parámetro | Valor |
|-----------|-------|
| HP Base | 130 |
| Daño Base | Profile "medium" → 5 × 4.0 = 20 |
| Velocidad | 32.0 |
| Rango de Ataque | 220.0 |
| Cooldown de Ataque | 1.8s |
| Radio de Colisión | 18.0 |
| XP | 16 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Ranged Attack | `projectile` | Proyectil de hielo | Elemento: ice |
| Freeze Zone | `zone` | Zona de congelación | Radio: 120, Slow: 50%, Duración: 4s, CD: 8s |
| Ice Armor | `passive` | Armadura de hielo | Reducción: 25% |
| Shatter Damage | `reactive` | Daño al romper congelación | Daño: 50 |

**Sprites:** `assets/sprites/enemies/tier_4/reina_del_hielo.png`

---

### 4. Archimago Perdido
**ID:** `tier_4_archimago_perdido`
**Arquetipo:** `multi`
**Tema/Color:** Múltiples colores elementales, túnica rasgada

| Parámetro | Valor |
|-----------|-------|
| HP Base | 110 |
| Daño Base | Profile "medium" → 5 × 4.0 = 20 |
| Velocidad | 30.0 |
| Rango de Ataque | 280.0 |
| Cooldown de Ataque | 1.8s |
| Radio de Colisión | 16.0 |
| XP | 20 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Ranged Attack | `projectile` | Proyectiles multi-elementales | - |
| Teleport | `movement` | Teletransporte evasivo | CD: 6.0s |
| Multi Element | `passive` | Cicla entre elementos | Ciclo: [fire, ice, void] |
| Fire Projectile | `projectile` | Proyectil de fuego | Burn: 3.0s |
| Ice Projectile | `projectile` | Proyectil de hielo | Slow: 35% |
| Void Projectile | `projectile` | Proyectil del vacío | Pull force: 50 |

**Sprites:** `assets/sprites/enemies/tier_4/archimago_perdido.png`

---

### 5. Dragón Etéreo
**ID:** `tier_4_dragon_etereo`
**Arquetipo:** `breath`
**Tema/Color:** Azul etéreo, semi-transparente, alas espectrales

| Parámetro | Valor |
|-----------|-------|
| HP Base | 180 |
| Daño Base | Profile "medium" → 5 × 4.0 = 20 |
| Velocidad | 40.0 |
| Rango de Ataque | 180.0 |
| Cooldown de Ataque | 2.5s |
| Radio de Colisión | 24.0 |
| XP | 22 |

**Habilidades:**
| Habilidad | Tipo | Descripción | Parámetros |
|-----------|------|-------------|------------|
| Flying | `passive` | Movimiento de vuelo | - |
| Breath Attack | `cone` | Aliento devastador | Ángulo: 45°, Rango: 200, DPS: 20, Duración: 2s, CD: 6s |
| Dive Attack | `dash` | Picada aérea | Daño: x2.5, CD: 8s |

**Sprites:** `assets/sprites/enemies/tier_4/dragon_etereo.png`

---

## BOSSES
**Tiempo de aparición:** Cada 5 minutos (minuto 5, 10, 15, 20...)

### Configuración General de Bosses
- **Tier:** 5
- **Arquetipo:** `boss`
- **Fases:** 3 (cambian según HP)
- **Escala visual:** 2.5x tamaño normal

---

## 🔥 BOSS 1: El Conjurador Primigenio
**ID:** `boss_el_conjurador`
**Tema/Color:** Púrpura arcano, dorado, runas brillantes

| Parámetro | Valor |
|-----------|-------|
| HP Base | 1200 |
| Daño Base | 22 |
| Velocidad | 50.0 |
| Rango de Ataque | 700.0 |
| Cooldown de Ataque | 0.9s |
| Radio de Colisión | 32.0 |
| XP | 150 |

### Habilidades del Conjurador

| Habilidad | Tipo | CD | Descripción |
|-----------|------|-----|-------------|
| **Arcane Barrage** | `projectile` | 2.0s | Ráfaga de proyectiles arcanos |
| **Summon Minions** | `summon` | 8.0s | Invoca enemigos menores |
| **Teleport Strike** | `dash` | 5.0s | Teleport + ataque inmediato |
| **Arcane Nova** | `aoe` | 6.0s | Explosión de daño arcano |
| **Curse Aura** | `debuff` | 10.0s | Reduce curación del jugador |

### Detalles de Habilidades

#### Arcane Barrage
```
Proyectiles: 6 (Fase 2: 9)
Daño: 15
Spread: 40°
Tipo: Proyectil arcano
Visual: Orbes púrpuras con estela
```

#### Summon Minions
```
Cantidad: 2 (Fase 2: 3)
Tier Invocados: 1 (Fase 3: 2)
Visual: Círculo mágico con runas giratorias
```

#### Teleport Strike
```
Rango: 250
Multiplicador Daño: x1.5
Visual: Efecto de desaparición/aparición púrpura
```

#### Arcane Nova
```
Radio: 140 (Fase 3: 180)
Daño: 35 (Fase 3: 55)
Visual: Explosión de ondas arcanas concentricas
```

#### Curse Aura
```
Radio: 150
Reducción Curación: 40%
Duración: 8s
Visual: Aura oscura púrpura pulsante
```

### Umbrales de Fase
- **Fase 2:** HP ≤ 65%
- **Fase 3:** HP ≤ 30%

**Sprites:**
- Estático: `assets/sprites/enemies/bosses/el_conjurador_primigenio.png`
- Animado: `assets/sprites/enemies/bosses/el_conjurador_primigenio_spritesheet.png`

---

## 💜 BOSS 2: El Corazón del Vacío
**ID:** `boss_el_corazon`
**Tema/Color:** Púrpura oscuro, negro vacío, energía distorsionada

| Parámetro | Valor |
|-----------|-------|
| HP Base | 1200 |
| Daño Base | 25 |
| Velocidad | 55.0 |
| Rango de Ataque | 800.0 |
| Cooldown de Ataque | 0.8s |
| Radio de Colisión | 45.0 |
| XP | 150 |

### Habilidades del Corazón del Vacío

| Habilidad | Tipo | CD | Descripción |
|-----------|------|-----|-------------|
| **Void Pull** | `control` | 4.0s | Atrae al jugador hacia el boss |
| **Void Explosion** | `aoe` | 6.0s | Explosión masiva de vacío |
| **Void Orbs** | `homing` | 3.0s | Orbes que persiguen al jugador |
| **Reality Tear** | `zone` | 8.0s | Crea zona de daño persistente |
| **Damage Aura** | `aura` | 0.0s | Aura de daño pasivo constante |
| **Void Beam** | `beam` | 10.0s | Rayo canalizado de alto daño |

### Detalles de Habilidades

#### Void Pull
```
Radio: 450
Fuerza: 130 (Fase 2: 180)
Duración: 2.0s
Visual: Espirales siendo absorbidas hacia el centro
```

#### Void Explosion
```
Radio: 180
Daño: 70 (Fase 3: 85)
Visual: Absorción → Explosión inversa con ondas púrpuras
Duración Animación: 0.9s
```

#### Void Orbs
```
Cantidad: 4 (Fase 2: 5)
Daño: 25
Velocidad: 110 (más lento que el jugador)
Duración: 5.0s
Homing Strength: 1.8
Visual: Orbes púrpuras pulsantes con estela
```

#### Reality Tear
```
Radio: 100
DPS: 18
Duración: 7.0s
Visual: Desgarro dimensional con bordes distorsionados
```

#### Damage Aura
```
Radio: 100 (Fase 3: 140)
DPS: 8
Visual: Aura oscura constante alrededor del boss
```

#### Void Beam
```
Daño: 30
Duración: 2.5s
Ancho: 40
Visual: Rayo púrpura oscuro con partículas
```

### Umbrales de Fase
- **Fase 2:** HP ≤ 60%
- **Fase 3:** HP ≤ 30%

**Sprites:**
- Estático: `assets/sprites/enemies/bosses/el_corazon_del_vacio.png`
- Animado: `assets/sprites/enemies/bosses/el_corazon_del_vacio_spritesheet.png`

---

## 🛡️ BOSS 3: El Guardián de Runas
**ID:** `boss_el_guardian`
**Tema/Color:** Dorado, piedra con runas brillantes, armadura ancestral

| Parámetro | Valor |
|-----------|-------|
| HP Base | 1200 |
| Daño Base | 20 |
| Velocidad | 50.0 |
| Rango de Ataque | 600.0 |
| Cooldown de Ataque | 1.0s |
| Radio de Colisión | 42.0 |
| XP | 150 |

### Habilidades del Guardián

| Habilidad | Tipo | CD | Descripción |
|-----------|------|-----|-------------|
| **Rune Shield** | `defense` | 18.0s | Escudo que absorbe hits |
| **Rune Blast** | `aoe` | 5.0s | Explosión de runas |
| **Rune Prison** | `control` | 12.0s | Atrapa al jugador brevemente |
| **Counter Stance** | `reactive` | 10.0s | Postura de contraataque |
| **Rune Barrage** | `projectile` | 7.0s | Múltiples runas disparadas |
| **Ground Slam** | `aoe` | 8.0s | Golpe de tierra con ondas |

### Detalles de Habilidades

#### Rune Shield
```
Cargas: 4 (Fase 2: 5)
Duración: 10.0s
Visual: Hexágono dorado con runas en vértices, pulsante
```

#### Rune Blast
```
Radio: 100
Daño: 30 (Fase 2: 40)
Visual: Círculos mágicos con runas expandiéndose
Efecto: Stun 0.5s
```

#### Rune Prison
```
Duración Root: 1.2s
Daño al Escapar: 12
Visual: Jaula de runas doradas
```

#### Counter Stance
```
Ventana: 1.5s
Multiplicador Daño: x2.0 (Fase 3: x2.8)
Visual: Postura defensiva con runas girando
```

#### Rune Barrage
```
Proyectiles: 5
Daño: 12
Spread: 40°
Visual: Runas doradas volando
```

#### Ground Slam
```
Radio: 120
Daño: 30 (Fase 3: 45)
Stun: 0.4s
Visual: Ondas expansivas con grietas de runas
```

### Umbrales de Fase
- **Fase 2:** HP ≤ 60%
- **Fase 3:** HP ≤ 25%

**Sprites:**
- Estático: `assets/sprites/enemies/bosses/el_guardian_de_runas.png`
- Animado: `assets/sprites/enemies/bosses/el_guardian_de_runas_spritesheet.png`

---

## 🔥 BOSS 4: Minotauro de Fuego
**ID:** `boss_minotauro`
**Tema/Color:** Rojo fuego, naranja, llamas constantes, cuernos ardientes

| Parámetro | Valor |
|-----------|-------|
| HP Base | 1400 |
| Daño Base | 28 |
| Velocidad | 55.0 |
| Rango de Ataque | 500.0 |
| Cooldown de Ataque | 0.8s |
| Radio de Colisión | 36.0 |
| XP | 150 |

### Habilidades del Minotauro

| Habilidad | Tipo | CD | Descripción |
|-----------|------|-----|-------------|
| **Charge Attack** | `dash` | 3.0s | Carga devastadora |
| **Fire Stomp** | `aoe` | 4.0s | Pisotón de fuego |
| **Flame Breath** | `cone` | 5.0s | Aliento de fuego |
| **Meteor Call** | `aoe` | 8.0s | Invocar meteoros del cielo |
| **Enrage** | `buff` | 0.0s | Modo furia al bajar HP |
| **Fire Trail** | `zone` | 0.0s | Deja rastro de fuego al caminar |

### Detalles de Habilidades

#### Charge Attack
```
Velocidad: 350 (Fase 2: +multiplicador)
Multiplicador Daño: x2.5 (Fase 2: x3.0)
Stun: 0.7s
Visual: Línea de advertencia + estela de fuego
```

#### Fire Stomp
```
Radio: 160
Daño: 50
Burn: 12 DPS por 4s
Stun: 0.3s
Visual: Ondas de fuego expansivas + llamas alrededor
```

#### Flame Breath
```
Ángulo: 55°
Rango: 200
Daño: 25 (Fase 3: 40)
Duración: 2.5s
Burn: 6 DPS por 2.5s
Visual: Cono de llamas con partículas
```

#### Meteor Call
```
Cantidad: 6 (Fase 3: 9)
Daño: 45
Radio Impacto: 70
Delay: 2.0s (tiempo para esquivar)
Visual: Círculos de advertencia rojos + impacto explosivo
```

#### Enrage
```
Umbral: HP ≤ 35%
Bonus Daño: +50%
Bonus Velocidad: +30%
Visual: Aura roja intensa + ojos brillantes
```

#### Fire Trail (Fase 3)
```
DPS: 10
Duración Trail: 3.0s
Radio: 25
Visual: Charcos de fuego en el suelo
```

### Umbrales de Fase
- **Fase 2:** HP ≤ 60%
- **Fase 3:** HP ≤ 25%

**Sprites:**
- Estático: `assets/sprites/enemies/bosses/minotauro_de_fuego.png`
- Animado: `assets/sprites/enemies/bosses/minotauro_de_fuego_spritesheet.png`

---

## Habilidades Élite Especiales

Cuando un enemigo normal se convierte en **Élite**, obtiene habilidades especiales adicionales:

### Configuración Élite
```gdscript
hp_multiplier: 15.0      # 15x HP
damage_multiplier: 4.0   # 4x daño
size_multiplier: 1.9     # 90% más grande
xp_multiplier: 12.0      # 12x XP
speed_multiplier: 1.7    # 70% más rápido
attack_speed_mult: 0.5   # Atacan 2x más rápido
```

### Habilidades Élite Disponibles

| Habilidad | CD | Descripción | Parámetros |
|-----------|-----|-------------|------------|
| **Elite Slam** | 3.0s | Golpe de área | Radio: 120, Daño: x2.5, Stun: 0.4s |
| **Elite Rage** | - | Modo furia al 60% HP | +100% daño, +60% velocidad |
| **Elite Shield** | 10.0s | Escudo de cargas | 8 cargas |
| **Elite Dash** | 2.5s | Embestida hacia jugador | Velocidad: 750, Daño: x2.0 |
| **Elite Nova** | 5.0s | Explosión de proyectiles | 16 proyectiles, Daño: x1.0 |
| **Elite Summon** | 8.0s | Invoca minions | 4 minions tier 1 |

### Visuales Élite
- **Aura:** Dorada pulsante (`aura_elite_floor.png`)
- **Shader Glow:** Resplandor estilo Dragon Ball
- **Colores:** Amarillo → Naranja → Rojo (según tier)

---

## Tipos de Proyectiles

### Atlas de Proyectiles
Ubicación: `assets/sprites/projectiles/enemy_projectiles.png`

| Frame | Elemento | Color |
|-------|----------|-------|
| 0 | Ice | Azul hielo |
| 1 | Fire | Naranja/rojo |
| 2 | Arcane | Púrpura |
| 3 | Lightning | Amarillo |
| 4 | Dark/Shadow/Void | Púrpura oscuro |
| 5 | Poison/Nature | Verde |

### Configuración de Proyectil
```gdscript
# EnemyProjectile.gd
direction: Vector2
speed: float = 200.0
damage: int = 10
lifetime: float = 5.0
element_type: String = "physical"
trail_positions: Array  # Para estela visual
max_trail_length: int = 18
collision_radius: float = 12.0
```

---

## Efectos Visuales y Placeholders

### Escenas VFX Existentes
- `scenes/vfx/vfx_aoe_impact.tscn` - Impacto de AOE
- `scenes/vfx/warning_indicator.tscn` - Indicador de advertencia

### Efectos Programáticos (Node2D.draw)

Los efectos visuales se generan dinámicamente con código en `EnemyAttackSystem.gd`:

| Efecto | Descripción | Elementos Visuales |
|--------|-------------|-------------------|
| Elite Slam | Ondas de choque doradas | Arcos, grietas, corona de puntas |
| Elite Rage | Aura roja + símbolo | Múltiples círculos, ojos, rayos |
| Elite Shield | Hexágono dorado | Polígono, runas en vértices, corona interior |
| Elite Dash | Estela + flecha | Rectángulo dorado, partículas |
| Elite Nova | Anillos contrayéndose | Círculos, centro brillante |
| Elite Summon | Círculo mágico | Runas giratorias, pentáculo |
| Void Explosion | Absorción → explosión | Espirales, ondas púrpuras, rayos oscuros |
| Rune Blast | Runas expandiéndose | Triángulos dorados, conexiones, rayos |
| Fire Stomp | Onda de fuego | Cráter, anillos de fuego, llamas, chispas |
| AOE Warning | Círculo pulsante | Arcos, símbolo de peligro |
| AOE Explosion | Ondas expansivas | Múltiples arcos, relleno, centro blanco |
| Boss Trail | Zona de daño temporal | Círculos con fade out |
| Orbitales | Esferas giratorias | Círculos concéntricos coloreados |

### Colores por Elemento
```gdscript
func _get_element_color(elem: String) -> Color:
    match elem:
        "fire": return Color(1.0, 0.4, 0.1)
        "ice": return Color(0.3, 0.7, 1.0)
        "arcane": return Color(0.7, 0.3, 1.0)
        "dark", "void": return Color(0.4, 0.1, 0.6)
        "poison": return Color(0.3, 0.8, 0.2)
        "lightning": return Color(1.0, 1.0, 0.3)
        _: return Color(0.9, 0.9, 0.9)
```

---

## Resumen de Arquetipos

| Arquetipo | Comportamiento | Enemigos |
|-----------|----------------|----------|
| `melee` | Persigue y ataca cuerpo a cuerpo | Esqueleto Aprendiz |
| `agile` | Rápido, zigzag, hit & run | Duende Sombrío |
| `tank` | Lento pero resistente | Slime Arcano, Gólem Rúnico, Titán Arcano |
| `flying` | Movimiento errático, evasión | Murciélago Etéreo |
| `debuffer` | Aplica efectos negativos | Araña Venenosa |
| `blocker` | Puede bloquear/contraatacar | Guerrero Espectral |
| `pack` | Bonus con aliados cercanos | Lobo de Cristal |
| `ranged` | Ataca a distancia | Hechicero Desgastado, Elemental de Hielo |
| `phase` | Puede volverse intangible | Sombra Flotante |
| `charger` | Hace dash/carga | Caballero del Vacío |
| `trail` | Deja rastro dañino | Serpiente de Fuego |
| `teleporter` | Se teletransporta | Mago Abismal |
| `support` | Buff a aliados | Corruptor Alado |
| `aoe` | Ataques de área | Señor de las Llamas, Reina del Hielo |
| `multi` | Múltiples tipos de ataque | Archimago Perdido |
| `breath` | Ataque en cono | Dragón Etéreo |
| `boss` | Múltiples fases y habilidades | Todos los bosses |

---

## Archivos Relacionados

### Scripts Principales
- `scripts/enemies/EnemyBase.gd` - Clase base de enemigos
- `scripts/enemies/EnemyAttackSystem.gd` - Sistema de ataques (4378 líneas)
- `scripts/enemies/EnemyProjectile.gd` - Proyectiles enemigos
- `scripts/data/EnemyDatabase.gd` - Base de datos de enemigos

### Habilidades Modulares
- `scripts/enemies/abilities/EnemyAbility.gd`
- `scripts/enemies/abilities/EnemyAbility_Melee.gd`
- `scripts/enemies/abilities/EnemyAbility_Ranged.gd`
- `scripts/enemies/abilities/EnemyAbility_Aoe.gd`
- `scripts/enemies/abilities/EnemyAbility_Nova.gd`
- `scripts/enemies/abilities/EnemyAbility_Dash.gd`
- `scripts/enemies/abilities/EnemyAbility_Teleport.gd`
- `scripts/enemies/abilities/EnemyAbility_Summon.gd`

### Assets de Sprites
- `assets/sprites/enemies/tier_1/` - 5 enemigos con estático + spritesheet
- `assets/sprites/enemies/tier_2/` - 5 enemigos
- `assets/sprites/enemies/tier_3/` - 5 enemigos
- `assets/sprites/enemies/tier_4/` - 5 enemigos
- `assets/sprites/enemies/bosses/` - 4 bosses con estático + spritesheet
- `assets/sprites/projectiles/enemy_projectiles.png` - Atlas 6x1
- `assets/vfx/aura_elite_floor.png` - Aura de élites

---

*Documento generado el 4 de febrero de 2026*
*Total de enemigos documentados: 24 (20 normales + 4 bosses)*
*Total de habilidades únicas documentadas: 60+*
