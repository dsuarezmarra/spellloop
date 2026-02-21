# LoopiaLike (Loopialike) ? Análisis Exhaustivo del Juego y Estrategia de Publicación en Steam

**Fecha**: 18 de febrero de 2026
**Versión actual**: 0.1.0-alpha
**Motor**: Godot 4.5 (GDScript)
**Género**: Arena Survival Roguelite (estilo Vampire Survivors / Brotato)

---

## PARTE 1: ANÁLISIS EXHAUSTIVO DEL ESTADO ACTUAL

---

### 1.1 Inventario de Contenido

| Contenido | Cantidad | Detalle |
|-----------|----------|---------|
| Personajes jugables | **10** | 3 desbloqueados + 7 desbloqueables |
| Armas base | **10** | 1 por cada elemento mágico |
| Armas fusionadas | **45** | Todas las combinaciones de 2 armas base |
| Total armas | **55** | Sistema completo de fusiones |
| Tipos de enemigos | **24** | T1(5) + T2(5) + T3(5) + T4(5) + Bosses(4) |
| Mejoras (upgrades) | **~160+** | Defensivas, ofensivas, utilidad, cursed, únicas |
| Biomas | **7** | Grassland, Forest, Desert, Snow, Lava, ArcaneWastes, Death |
| Logros Steam | **20** | 5 categorías |
| Idiomas | **10** | EN, ES, DE, FR, IT, PT, RU, JA, KO, ZH |
| Pistas de música | **6** | Boss, gameplay (4), intro/menú |
| Archivos SFX | **~88** | Armas, UI, ambiente, cofres, enemigos |
| Pantallas UI | **10** | Menú, selección, HUD, pausa, opciones, game over, ranking |
| Slots de guardado | **3** | Con meta-progresión persistente |

**Veredicto de contenido**: Para un Early Access, este volumen es **sólido y competitivo**. Vampire Survivors lanzó su EA con ~6 personajes y ~20 armas. LoopiaLike ya tiene más contenido que muchos roguelites al momento de su EA.

---

### 1.2 Estado Técnico

#### Rendimiento
- **0 spikes de frame** en más de 100 minutos de testing acumulado
- Estable con 10 armas activas + cientos de enemigos + efectos VFX masivos
- Runs de 94 minutos sin crashes ni degradación de rendimiento
- **Veredicto**: Rendimiento IMPECABLE ? no es un blocker para lanzamiento

#### Integración Steam
- **GodotSteam** implementado correctamente via GDExtension
- **20 logros** con tracking, sincronización offline?online, y persistencia local
- **Leaderboards mensuales** funcionales con serialización de datos de build
- **APP_ID** todavía en placeholder (=0) ? pendiente de asignar tras aprobación
- **Cloud Saves**: Datos en `user://`, depende de Steam Remote Storage habilitado en Steamworks
- **Soporte de mando**: Implementado (botones + sticks analógicos)
- **Steam Deck**: Marcado como "Verified" en la configuración

#### Plataformas de Export
- Windows (x64) ? Configurado
- Linux (x64) ? Configurado
- Steam Deck ? Soporte declarado

#### Localización
- 10 idiomas completos con ~781 claves de traducción cada uno
- Sistema de localización dinámico en runtime

---

### 1.3 Bugs Pendientes de Resolver

#### Críticos para Early Access
| Bug | Impacto | Dificultad de Fix |
|-----|---------|-------------------|
| **BAL-01**: `frozen_thunder` acapara 99%+ del DPS | Una sola fusión domina el juego completamente, eliminando diversidad de builds | Media ? Rebalanceo de multiplicadores |
| **BAL-02**: Dodge 60% + HP alto = invulnerabilidad | A partir del min ~56, el jugador es virtualmente inmortal | Media ? Revisión de caps o mecánicas anti-dodge |
| **BAL-03**: Enemigos T3/T4 completamente inofensivos | Miles de spawns con 0 hits ? mueren instantáneamente o no pueden alcanzar al jugador | Alta ? Requiere rediseño de IA enemiga |
| **Early game letal**: Enemigos T1 matan demasiado rápido | 4 de 4 runs cortas terminan en <3 min por T1 básicos (32 dmg por hit excesivo) | Baja ? Ajuste de números |
| **Falta de healing temprano** | 0 fuentes de curación en primeros minutos, hace el early game frustrante | Baja ? Añadir opciones early |

#### No-Críticos (para post-EA)
- Telemetría interna: audit.jsonl necesita eventos individuales
- Counters rolling en BalanceTelemetry son código muerto
- Solo se ha testeado con Storm Caller ? faltan datos de los otros 9 personajes

---

### 1.4 Qué Funciona Excelentemente

1. **Sistema de armas y fusiones** ? 55 armas con combinación completa es un gancho potente
2. **Meta-progresión** ? Desbloqueo de personajes, meta-shop, historial de runs
3. **Rendimiento** ? 0 problemas técnicos en testing extensivo
4. **Sistema de dificultad adaptativa** ? Escala según rendimiento del jugador
5. **Contenido para ~160+ upgrades** ? Variedad de builds significativa
6. **Localización en 10 idiomas** ? Listo para audiencia global desde día 1
7. **Soporte de mando + Steam Deck** ? Maximiza audiencia accesible
8. **Integración Steam completa** ? Logros, leaderboards, stats

---

### 1.5 Prioridades de Desarrollo Pre-EA

#### P0 ? Bloquers de Lanzamiento (hacer ANTES del EA)
1. **Rebalancear el early game** ? Reducir daño de T1 o dar healing inicial al jugador
2. **Rebalancear fusiones** ? `frozen_thunder` no puede dominar al 99%; todas las armas deben ser viables
3. **Asignar Steam APP_ID** ? Sin esto, la integración Steam no funciona online
4. **Configurar Steam Cloud Saves** ? Habilitar Remote Storage en Steamworks Dashboard
5. **Testear TODOS los personajes** ? 9 de 10 no tienen datos de testing

#### P1 ? Importantes para Primera Impresión
1. **Tutorial/onboarding in-game** ? Los roguelites necesitan un primer minuto claro
2. **Pantalla de estadísticas post-run más detallada** ? Los jugadores de roguelite adoran analizar sus runs
3. **Feedback visual de progresión** ? Hacer que el jugador SIENTA que se hace más fuerte
4. **Revisar los primeros 5 minutos** ? La primera impresión define reviews y refunds

#### P2 ? Mejoras para Retención
1. **Más bosses** ? 4 bosses es mínimo; apuntar a 8-10 para variedad
2. **Desafíos diarios/semanales** ? Usando los leaderboards mensuales como base
3. **Más variedad de builds viables** ? Que cada personaje tenga al menos 2-3 builds distintos
4. **Feedback de la comunidad** ? Sistema para reportar bugs in-game o enlace a Discord

---

## PARTE 2: ESTRATEGIA DE PUBLICACIÓN EN STEAM ? MÁXIMA VISIBILIDAD CON PRESUPUESTO CERO

---

### 2.1 Estrategia de Precio para Early Access

#### Recomendación: **4,99? en Early Access ? 7,99? en 1.0 ? 9,99? precio final estable**

**Razonamiento:**

| Precio | Ventajas | Desventajas |
|--------|----------|-------------|
| **4,99? (EA)** | Impulso compra, barrera baja, más reviews rápido, mejor ratio reviews/ventas | Menor ingreso por unidad |
| **7,99? (1.0)** | Precio justo para contenido completo, señala progreso | Algunos compradores tempranos se sienten traicionados si sube mucho |
| **9,99? (final)** | Tu objetivo, alcanzable con contenido maduro | Solo viable tras validación de mercado |

**Por qué NO lanzar a 9,99? directamente en EA:**
1. **Vampire Survivors lanzó a 2,99?** ? El precio bajo fue clave en su viralidad
2. **Brotato lanzó a 4,99?** ? Mismo patrón, éxito masivo
3. **4,99? es el "impulse buy" perfecto** para roguelites indie ? El jugador no lo piensa, lo compra
4. **A 9,99? en EA**, los jugadores esperan un juego más pulido; a 4,99? perdonan bugs y contenido limitado
5. **Más ventas = más reviews = más visibilidad algorítmica en Steam** ? El volumen es más importante que el margen

**Modelo de incremento gradual:**
- **EA Launch (Día 1)**: 4,99?
- **EA Update Mayor 1** (mes 2-3): Mantener 4,99?, sale de 15-20% para nuevos compradores
- **Salida de EA (1.0)**: Subir a 7,99? ? Los compradores de EA ya pagaron menos, contentos
- **6 meses post-1.0**: Considerar subir a 9,99? si el contenido lo justifica
- **NUNCA subir precio sin añadir contenido significativo** ? Steam lo castiga

**Descuento de lanzamiento**: Ofrecer **-10% la primera semana de EA** (queda en 4,49?). Esto activa la etiqueta "EN OFERTA" en Steam, que atrae clicks.

---

### 2.2 Estrategia de Early Access

#### Duración Recomendada: 6-12 meses

**Qué comunicar en la página de EA de Steam:**

1. **"¿Por qué acceso anticipado?"**
   > LoopiaLike tiene una base jugable sólida con 10 personajes, 55 armas, 7 biomas y cientos de mejoras. Queremos que la comunidad participe activamente en el desarrollo del juego: qué armas son divertidas, qué builds necesitan amor, y qué mecánicas añadir. El EA nos permite iterar rápido con feedback real.

2. **"¿Cuánto durará el acceso anticipado?"**
   > Estimamos 6-12 meses. Publicaremos un roadmap visible y actualizaciones regulares.

3. **"¿Cuál es el estado actual?"**
   > El juego es completamente jugable con partidas de 20 min a varias horas. Incluye 10 personajes desbloqueables, 55 armas con sistema de fusión, 24 tipos de enemigo, 160+ mejoras, 20 logros de Steam, soporte de mando, y localización en 10 idiomas.

4. **"¿Cambiará el precio?"**
   > El precio subirá cuando el juego salga de Early Access con más contenido. Los jugadores que compren en EA siempre tendrán el mejor precio.

#### Roadmap Público para EA (Ejemplo)

| Versión | Contenido | Estimado |
|---------|-----------|----------|
| **0.2** | Rebalanceo de armas, 2 nuevos bosses, tutorial, fix early game | Mes 1-2 |
| **0.3** | 2 nuevos personajes, desafíos diarios, ajustes por feedback | Mes 3-4 |
| **0.4** | Nuevo bioma, 10 armas nuevas, sistema de reliquias/artefactos | Mes 5-6 |
| **0.5** | Modo cooperativo local (si viable), más contenido endgame | Mes 7-9 |
| **1.0** | Rebalanceo final, cinemáticas, achievements completados, pulido | Mes 10-12 |

---

### 2.3 Estrategia de Visibilidad Gratuita en Steam

#### 2.3.1 Optimización de la Página de Steam (SEO de Steam)

**Tags obligatorios** (seleccionar en Steamworks):
- `Roguelite`, `Action Roguelike`, `Bullet Hell`, `Survivor`, `Arena Shooter`
- `Indie`, `Pixel Art`, `Action`, `RPG`, `Singleplayer`
- `Procedural Generation`, `Hack and Slash`, `Magic`, `Fantasy`
- `Controller Support`, `Steam Deck Verified`, `Early Access`
- `Atmospheric`, `Replay Value`, `Difficult`

**Nombre del juego**: "LoopiaLike" es corto, memorable, y busca bien. Mantenerlo.

**Descripción corta** (la que aparece en búsquedas):
> "Sobrevive oleadas infinitas de enemigos con 55 armas mágicas fusionables. 10 magos, 7 biomas, builds infinitas. ¿Cuánto puedes aguantar?"

**Descripción larga** (página del juego):
- Primer párrafo: GANCHO ? qué hace único al juego (sistema de fusión de 55 armas)
- Segundo párrafo: Sistema de juego (roguelite, arena, supervivencia)
- Bullets de features con emojis ? (lista clara de contenido)
- Comparaciones: "Si te gusta Vampire Survivors, Brotato o Magic Survival, LoopiaLike es para ti"
- Call to action: "Únete a la comunidad en Discord"
- Sección de EA bien redactada

**Imágenes/Cápsulas**:
- **Cápsula principal** (header): Debe mostrar ACCIÓN ? el personaje con 6 armas disparando a hordas
- **Screenshots**: Mínimo 5, mostrando diferentes biomas, fusiones, bosses, UI de mejoras
- **Vídeo/Tráiler**: 30-60 segundos de gameplay puro con cortes rápidos. Sin cinemáticas largas
- **GIFs**: Steam soporta GIFs animados en la descripción ? USAR. Un GIF de una fusión de armas es hipnótico

#### 2.3.2 Eventos de Steam (GRATIS y MUY POTENTES)

Steam organiza eventos regulares donde puedes participar **gratis**:

| Evento | Frecuencia | Cómo Participar |
|--------|------------|-----------------|
| **Steam Next Fest** | 3 veces/año (Feb, Jun, Oct) | Subir una demo jugable. Es el MAYOR generador de wishlists gratis. Prioridad absoluta |
| **Daily Deals / Weeklong Deals** | Semanal | Poner el juego con descuento (15-25%) durante eventos temáticos |
| **Steam Sales** (Summer, Winter, Autumn, Spring) | 4 veces/año | Participar SIEMPRE con descuento. Visibilidad masiva gratuita |
| **Theme Sales** (Roguelike Sale, Indie Sale, etc.) | Varias al año | Aplicar a todas las que encajen con el género |
| **Launch Discount** | Una vez | Descuento del 10% la primera semana ? OBLIGATORIO hacerlo |

**PRIORIDAD MÁXIMA: Steam Next Fest**
- Si el juego aún no está en Steam, PREPARA UNA DEMO para el próximo Next Fest
- Next Fest de **Junio 2026** sería ideal ? da tiempo a pulir una demo
- Una demo de 15-20 minutos con 1 personaje y 10 armas es suficiente
- Los juegos que participan en Next Fest ganan entre 5,000 y 50,000 wishlists EN UNA SEMANA
- Es la herramienta de visibilidad GRATUITA más potente que existe para indies

#### 2.3.3 Wishlists: El Algoritmo Secreto de Steam

**El algoritmo de Steam funciona así:**
1. Cuantas más wishlists tenga tu juego ? más lo recomienda Steam a otros usuarios
2. Cuando lanzas el juego ? Steam envía email a TODOS los que lo tienen en wishlist
3. Más wishlists al lanzar = más ventas día 1 = más visibilidad = efecto bola de nieve

**Objetivo**: Acumular el MÁXIMO de wishlists ANTES de lanzar el EA
- **Meta mínima**: 2,000 wishlists antes de EA (para que Steam te tome en serio)
- **Meta ideal**: 7,000+ wishlists (para aparecer en el algoritmo "Popular Upcoming")
- **Meta viral**: 50,000+ (Next Fest + redes sociales + streamers)

**Cómo acumular wishlists gratis:**
1. **Publicar la página de Steam YA** ? Cada día sin página es wishlists que pierdes
2. **Participar en Steam Next Fest con demo** ? El mayor generador de wishlists
3. **"Coming Soon" activo** meses antes del lanzamiento
4. **Tráiler de 30-60 segundos** que intrigue
5. **Publicaciones regulares en Steam Community** ? Updates, devlogs, screenshots

---

### 2.4 Marketing Gratuito Fuera de Steam

#### 2.4.1 Reddit (ALTA PRIORIDAD ? GRATIS)

| Subreddit | Audiencia | Qué Publicar |
|-----------|-----------|---------------|
| r/roguelites | ~100K | Devlogs, GIFs de gameplay, anuncios |
| r/indiegaming | ~500K | Screenshots, tráilers, progress updates |
| r/gamedev | ~1.4M | Postmortem técnico, devlog con detalles de desarrollo |
| r/gaming | ~40M | GIFs de gameplay espectacular (fusiones, bosses) si se vuelve viral |
| r/vampiresurvivors | ~50K | "Si te gusta VS, mira esto" (con tacto, sin spam) |
| r/SteamDeck | ~300K | "Nuestro juego corre perfecto en Steam Deck" |
| r/godot | ~250K | Post técnico sobre el desarrollo con Godot |
| r/linux_gaming | ~300K | Soporte nativo de Linux, siempre bien recibido |

**Reglas de oro en Reddit:**
- NO spammear. 1 post por subreddit cada 2-4 semanas máximo
- Los GIFs y vídeos cortos funcionan 10x mejor que texto
- Engagement: Responder TODOS los comentarios
- Título atractivo: "I've been working on a roguelite with 55 fusable weapons" ? Mucho engagement
- Postear los **martes-jueves** entre las 14:00-18:00 UTC para máxima visibilidad

#### 2.4.2 Twitter/X (MEDIA PRIORIDAD)

- Publicar **3-5 veces por semana** durante desarrollo
- Contenido: GIFs de gameplay (15-30 seg), antes/después, devlog snippets
- Hashtags: #indiedev #gamedev #roguelite #godot #screenshotsaturday #wishlistwednesday
- **Screenshot Saturday**: Cada sábado, publicar una captura con el hashtag #screenshotsaturday
- **Wishlist Wednesday**: Cada miércoles, recordar que existe tu página de Steam
- Interactuar con otros devs indie ? la comunidad se apoya mutuamente
- Etiquetar @GodotEngine en posts relevantes (ellos retuitean juegos hechos con Godot)

#### 2.4.3 TikTok / YouTube Shorts / Instagram Reels (ALTA PRIORIDAD)

- **Clips de 15-30 segundos** de gameplay espectacular
- Momentos "wow": Una fusión que destruye la pantalla, un boss derrotado in extremis
- Estos vídeos tienen potencial VIRAL masivo ? un clip bueno puede generar millones de vistas
- **Formato**: Vertical, sin intro, acción inmediata, texto overlay descriptivo
- **Frecuencia**: 3-5 clips por semana
- **Costo**: 0? ? Solo necesitas OBS para grabar gameplay

#### 2.4.4 Discord (ESENCIAL para Comunidad)

- Crear un **servidor Discord del juego** ? Es tu canal directo con la comunidad
- Canales sugeridos: #anuncios, #bugs, #sugerencias, #builds, #screenshots, #feedback-ea
- Los jugadores de roguelites son MUY activos en Discord
- Dar roles especiales a los testers tempranos ("EA Pioneer", "Bug Hunter")
- Compartir el enlace en TODAS las redes sociales y en la página de Steam
- **Meta**: 500+ miembros para EA, 2000+ para 1.0

#### 2.4.5 YouTube (ESTRATEGIA A MEDIO PLAZO)

**Tipo 1 ? Devlogs (tú produces)**:
- Vídeos de 5-10 minutos mostrando el desarrollo
- "Cómo hice el sistema de 55 armas en Godot" ? Atrae devs Y jugadores
- Canales como Brackeys, Firebelley Games, y Jonas Tyroller demuestran que los devlogs generan comunidad

**Tipo 2 ? Influencers/Streamers (ellos producen)**:
- Buscar YouTubers/Streamers que juegan roguelites con 1K-50K suscriptores
- **NO PAGAR** ? Enviarles una key gratuita y un email conciso
- Los streamers pequeños/medianos ACEPTAN keys gratis porque necesitan contenido
- **Lista de targets** (buscar en YouTube "new roguelite 2026" y contactar a quienes aparecen):
  - Canales de 1K-10K subs: Mayor tasa de respuesta, engagement alto
  - Canales de 10K-50K subs: Menos probable que respondan, pero alto impacto
  - Canales de 50K+: Enviar key pero sin expectativas
- **Email template**:
  > Hi [Name], I'm [dev name], solo developer of LoopiaLike ? a roguelite with 55 fusable magic weapons, launching in Early Access on Steam. I'd love for you to try it! Here's a free Steam key: [KEY]. No obligations ? play it, stream it, review it, or pass if it's not your thing. Trailer: [link]. Thanks for your time!

#### 2.4.6 Prensa Indie (BAJA PRIORIDAD pero gratis)

- **Distribute()** (keystopress.com) ? Plataforma gratuita para enviar keys a prensa
- **PressKit()** ? Crear una página de presskit con assets descargables (logos, screenshots, tráiler)
- Contactar periodistas de **Rock Paper Shotgun, PC Gamer, Kotaku, IGN Indie** ? Baja probabilidad, alto impacto
- Mejor: Contactar sitios ESPECIALIZADOS en indie como **IndieGamesPlus, GamingOnLinux, Rogueliker**

---

### 2.5 Estrategia de Lanzamiento EA ? Calendario

#### Pre-Lanzamiento (AHORA ? Día de EA)

| Semana | Acción |
|--------|--------|
| **Semana 0** (Ahora) | Crear Discord, empezar a publicar en Twitter con #indiedev |
| **Semana 1-2** | Página de Steam "Coming Soon" activa, tráiler de 30 seg |
| **Semana 3-4** | Post en r/roguelites y r/indiegaming con GIF de gameplay |
| **Semana 5-8** | Publicar devlogs semanales en redes + YouTube short clips |
| **Semana 8-10** | Preparar demo para Steam Next Fest (si coincide) |
| **Semana 10-12** | Email a streamers con keys, presskit listo |
| **Día -7** | Anuncio de fecha de lanzamiento en todas las redes |
| **Día -3** | Tráiler final de lanzamiento (60 seg) |
| **Día 0** | LANZAMIENTO EA con -10% launch discount |

#### Post-Lanzamiento EA

| Período | Acción |
|---------|--------|
| **Día 1-3** | Monitorear reviews, responder TODOS los bugs, hotfixes inmediatos |
| **Semana 1** | Primera actualización de comunidad: "Gracias + qué viene" |
| **Semana 2-3** | Primer parche con fixes basados en feedback |
| **Mes 1** | Update de contenido menor (balance, QoL) |
| **Mes 2-3** | Update mayor (nuevo contenido) ? Sale del 15-20% para atraer nuevos jugadores |
| **Cada 2-4 semanas** | Steam Community post con update de desarrollo |
| **Cada evento de Steam** | Participar con descuento |

---

### 2.6 Optimización de Reviews (CRUCIAL)

**El ratio de reviews en Steam determina la visibilidad:**
- **< 10 reviews**: El juego es casi invisible
- **10-49 reviews**: Aparece en búsquedas, pero sin puntuación visible
- **50+ reviews**: Score visible ("Muy positivo", etc.) ? visibilidad multiplicada
- **500+ reviews**: Algoritmo de Steam lo promociona activamente

**Cómo maximizar reviews:**
1. **Precio bajo** = más ventas = más reviews potenciales
2. **Al final de cada run**, mostrar un pop-up amable: "¿Disfrutaste la partida? ¡Déjanos una review en Steam! ??" (sin ser agresivo)
3. **Responder a TODAS las reviews negativas** de forma profesional y constructiva
4. **Arreglar bugs mencionados en reviews negativas RÁPIDO** ? Los usuarios a veces cambian su review
5. **Nunca pedir reviews positivas** ? Solo pedir "una review honesta"

**Meta de reviews para EA:**
- Semana 1: 10+ reviews (mínimo para aparecer en búsquedas)
- Mes 1: 50+ reviews (score visible)
- Mes 3: 100+ reviews (entrada en el algoritmo)

---

### 2.7 Monetización Adicional (Sin Gastar)

| Estrategia | Detalle | Prioridad |
|------------|---------|-----------|
| **DLC cosmético** (post-1.0) | Packs de skins para personajes a 1,99? | Baja ? Solo si hay demanda |
| **Soundtrack DLC** | Vender la OST como DLC separado a 2,99? | Media ? Coste 0, ingreso extra |
| **Bundle con otros roguelites** | Contactar otros devs indie para bundle en Steam | Alta ? Steam Bundles son gratis de crear |
| **Eventos estacionales** | Contenido temporal (Halloween, Navidad) que genere FOMO y streams | Media |
| **"Supporter Pack"** | DLC premium con wallpapers + OST + items cosméticos a 4,99? | Media ? Los fans pagan para apoyar |

---

### 2.8 Métricas de Éxito

| Métrica | Meta Mínima | Meta Buena | Meta Excelente |
|---------|-------------|------------|----------------|
| Wishlists pre-EA | 2,000 | 7,000 | 20,000+ |
| Ventas mes 1 EA | 500 | 2,000 | 10,000+ |
| Reviews mes 1 | 10 | 50 | 200+ |
| Score de reviews | Positivas (70%+) | Muy Positivas (80%+) | Abrumadoramente Positivas (95%+) |
| Mediana de juego | 1 hora | 3 horas | 8+ horas |
| Ingresos mes 1 | 2,500? | 10,000? | 50,000?+ |
| Discord members | 100 | 500 | 2,000+ |

---

## PARTE 3: DECISIONES CLAVE Y RECOMENDACIONES FINALES

---

### 3.1 Precio: Recomendación Final

**Lanzar EA a 4,99? con descuento de lanzamiento del 10% (4,49?).**

Razones:
- El mercado de roguelites indie está saturado ? precio bajo diferencia
- Maximiza volumen de ventas ? más reviews ? más visibilidad algorítmica
- Los jugadores perdonan más bugs/contenido faltante a 4,99? que a 9,99?
- **Ingreso potencial**: 5,000 ventas × 3,50? (después de comisión Steam 30%) = 17,500? neto primer mes (meta buena)
- Tu precio objetivo de 9,99? es alcanzable en la versión 1.0 completa

### 3.2 Early Access: Qué Hacer

1. **Lanzar EA cuando los primeros 5 minutos sean divertidos** ? No antes
2. **Fix del early game es PRIORIDAD #1** ? Si los jugadores mueren en 2 minutos por un skeleton de T1, la review es negativa
3. **Updates regulares cada 2-4 semanas** ? Mantener la comunidad activa
4. **Roadmap público** ? Que los jugadores sepan que el juego va a mejorar
5. **Ser transparente** sobre qué está terminado y qué no
6. **Canal de feedback** ? Discord + foro de Steam

### 3.3 Las 5 Cosas que Hacer AHORA MISMO

| # | Acción | Por Qué |
|---|--------|---------|
| 1 | **Arreglar el early game** (daño T1, healing, onboarding) | Si los primeros 5 min son frustrantes, review negativa garantizada |
| 2 | **Rebalancear fusiones** (BAL-01, BAL-02, BAL-03) | Un juego donde solo hay 1 build viable no retiene jugadores |
| 3 | **Crear la página de Steam "Coming Soon"** | Cada día sin página son wishlists perdidas |
| 4 | **Crear Discord + empezar redes sociales** | La comunidad se construye ANTES del lanzamiento |
| 5 | **Preparar demo para Steam Next Fest** | El generador de wishlists gratis más potente del mundo |

### 3.4 Las 5 Cosas que NUNCA Hacer

1. **Nunca lanzar sin testear los 10 personajes** ? Un personaje roto = reviews negativas
2. **Nunca ignorar reviews negativas** ? Responder siempre con profesionalismo
3. **Nunca dejar de actualizar durante el EA** ? 1 mes sin updates y la comunidad se muere
4. **Nunca subir el precio sin contenido nuevo** ? Steam y los jugadores lo castigan
5. **Nunca pagar por marketing** que puedes hacer gratis ? Reddit, Discord, Twitter, YouTube son gratis y más efectivos que ads pagados para indies

---

### 3.5 Resumen Ejecutivo

**LoopiaLike está en una posición sólida para un lanzamiento en Early Access.** El juego tiene más contenido que muchos roguelites exitosos al momento de su EA (55 armas, 10 personajes, 160+ upgrades). El rendimiento es impecable, la integración Steam está lista, y soporta 10 idiomas.

**Los obstáculos principales son de balance**, no técnicos: el early game es demasiado letal, una fusión domina el juego, y falta testear 9 de 10 personajes. Estos son fixeables en 2-4 semanas de trabajo enfocado.

**La estrategia de precio óptima es 4,99? en EA** para maximizar volumen ? reviews ? visibilidad algorítmica, subiendo a 7,99-9,99? en 1.0.

**La herramienta de visibilidad gratuita más potente es Steam Next Fest** ? Apuntar a la edición de Junio u Octubre 2026 con una demo pulida.

**El camino hacia el éxito es: Fix balance ? Página Steam ? Demo Next Fest ? Comunidad Discord ? Lanzamiento EA ? Updates regulares ? 1.0.**

---

*Documento generado el 18 de febrero de 2026. Actualizar tras cada milestone de desarrollo.*
