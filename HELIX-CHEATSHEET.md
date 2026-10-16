# Helix — Chuleta de comandos (día a día)

Comandos y atajos más usados para trabajar con Java (Spring Boot) y Angular.
Ayuda interna de Helix: `:tutor` (tutorial), `:help`, o https://docs.helix-editor.com/keymap.html

> Notación: `Espacio` = tecla espacio como líder. `gd` = presionar `g` y luego `d`.

> **Modelo mental de Helix (clave):** primero SELECCIONÁS, después aplicás el VERBO.
> En Vim es `d2w` (verbo→movimiento). En Helix es `2w` `d` (seleccionás 2 palabras, después borrás).
> Esto cambia toda la forma de editar — una vez que lo interiorizás, todo lo demás encaja.

---

## Modos

Helix es modal. Siempre estás en un modo:

| Tecla | Modo | Para qué |
|-------|------|----------|
| `Esc` | **Normal** (default) | moverse, comandos |
| `i` / `a` | Insert | escribir (antes / después del cursor) |
| `I` / `A` | Insert | al inicio / fin de línea |
| `o` / `O` | Insert | nueva línea abajo / arriba |
| `v` | Select | extiende la selección al moverte |
| `:` | Command | comandos tipo `:w`, `:q` |

---

## Archivos — el file picker

Helix trae un file picker integrado (fuzzy matching tipo fzf), sin plugins:

| Atajo | Qué hace |
|-------|----------|
| `Espacio` `f` | **File picker** — abre archivos del working dir (respeta `.gitignore`) |
| `Espacio` `F` | File picker desde el dir actual (sin filtrar gitignore) |
| `Espacio` `b` | Buffer picker — saltar entre archivos ya abiertos |
| `Espacio` `j` | Jumplist picker — volver a donde estuviste |
| `Espacio` `s` | Symbol picker del archivo actual (requiere LSP) |
| `Espacio` `S` | Symbol picker de todo el workspace (requiere LSP) |
| `Espacio` `/` | **Global search** — buscar texto en TODO el proyecto (ripgrep) |
| `Espacio` `e` | Explorador de archivos (árbol) — carpeta del archivo actual |
| `Espacio` `E` | Explorador en la raíz del proyecto |
| `Espacio` `'` | Reabrir el último picker |

### Tipo de coincidencia dentro del picker

Lo que escribís es **fuzzy** por defecto. Podés controlar el match:

| Escribís | Tipo de match |
|----------|---------------|
| `foo` | Fuzzy — aproximado (default) |
| `'foo` | Exacto — tiene que contener `foo` literal |
| `^foo` | Empieza con `foo` |
| `foo$` | Termina con `foo` |
| `!foo` | Invertido — que NO contenga `foo` |
| `|` | OR entre términos (ej: `'foo | 'bar`) |

### Moverse y abrir dentro del picker

| Tecla | Qué hace |
|-------|----------|
| `Ctrl+n` / `Ctrl+p` o flechas | Siguiente / anterior resultado |
| `Enter` | Abrir en la ventana actual |
| `Ctrl+s` | Abrir en split horizontal |
| `Ctrl+v` | Abrir en split vertical |
| `Ctrl+t` | Alternar preview |
| `Esc` | Cerrar el picker |

---

## Crear / guardar / cerrar archivos

| Comando | Qué hace |
|---------|----------|
| `:o ruta` | Abrir/crear archivo por ruta (crea carpetas si faltan) |
| `:w` | Guardar |
| `:w ruta` | Guardar en una ruta nueva (crea el archivo) |
| `:bc` | Cerrar el buffer actual (se queja si hay cambios sin guardar) |
| `:bc!` | Cerrar **forzado**, descartando cambios |
| `:bco` | Cerrar todos los buffers menos el actual |
| `:q` | Cerrar la ventana (si es la última, SALE de Helix) |
| `:q!` | Salir sin guardar |
| `:wq` | Guardar y salir |

> Diferencia clave: `:bc` cierra el **archivo**; `:q` cierra la **ventana** (puede salir de Helix).

---

## Navegación de código (LSP)

| Atajo | Qué hace | Equivalente VS Code |
|-------|----------|---------------------|
| `gd` | Ir a la definición | F12 |
| `gy` | Ir a la type-definition | — |
| `gr` | Ver referencias (dónde se usa) | Shift+F12 |
| `gi` | Ir a la implementación | — |
| `Espacio` `k` | Hover (ver tipo/documentación) | hover |
| `Espacio` `a` | **Code actions** (quick fix, imports, etc.) | Ctrl+. |
| `Espacio` `r` | Renombrar símbolo | F2 |
| `Espacio` `s` / `S` | Símbolos del archivo / del workspace | Ctrl+Shift+O / Ctrl+T |
| `]d` / `[d` | Siguiente / anterior diagnóstico (error) | F8 / Shift+F8 |

> El cursor debe estar **sobre** el símbolo para que `Espacio a` muestre sus acciones.

### Ir y volver — el jumplist (lo que MÁS vas a usar)

| Atajo | Qué hace |
|-------|----------|
| `Ctrl+o` | **Saltar atrás** (ej: volver después de un `gd`) |
| `Ctrl+i` | **Saltar adelante** |

> `Ctrl+o` / `Ctrl+i` son tu "undo/redo" de navegación. Hacés `gd` para ir a una definición,
> y `Ctrl+o` para volver exactamente a donde estabas. Imprescindible.

**Flujo típico de navegación:**
1. `Espacio f` → escribís el nombre → `Enter` (abrir archivo).
2. `gd` sobre un símbolo → saltás a su definición.
3. `Ctrl+o` → volvés a donde estabas.
4. `Espacio b` → saltar entre archivos ya abiertos.

---

## Seleccionar

| Tecla | Qué selecciona |
|-------|----------------|
| `w` / `b` / `e` | Palabra siguiente / anterior / fin de palabra |
| `x` | Línea entera (repetir `x` extiende línea a línea) |
| `%` | Todo el archivo |
| `v` + movimiento | Extiende selección manualmente |
| `mi(` `mi"` `mi{` | Contenido **dentro** de `()`, `""`, `{}` (inner) |
| `ma(` `ma"` `ma{` | Incluyendo los delimitadores (around) |
| `C` | Agrega un cursor en la línea de abajo (multi-cursor) |
| `s` (en selección) | Filtra sub-selecciones por regex |

> Los `mi(` / `ma(` son **text objects**: `mi"` selecciona lo que hay dentro de las comillas,
> `ma(` incluye los paréntesis. Potentísimo combinado con un verbo: `mi"` `c` = cambiar
> lo que está dentro de las comillas.

---

## Copiar / pegar / cortar / borrar

| Tecla | Qué hace |
|-------|----------|
| `y` | Yank (copiar la selección) — al registro **interno** de Helix |
| `p` / `P` | Pegar después / antes del cursor |
| `d` | Borrar selección (va al registro, tipo "cortar") |
| `c` | Change: borra la selección y entra en insert |
| `u` / `U` | Undo / Redo |
| `R` | Reemplazar selección con lo copiado (yank) |

### Portapapeles del SISTEMA (Windows) — ojo con esto

`y` y `p` usan el registro **interno** de Helix, NO el portapapeles de Windows.
Para copiar/pegar con otras apps (Chrome, VS Code, etc.) usá:

| Tecla | Qué hace |
|-------|----------|
| `Espacio` `y` | Copiar al portapapeles del **sistema** |
| `Espacio` `p` | Pegar desde el portapapeles del **sistema** |
| `"+y` | (forma larga) copiar al clipboard del sistema |
| `"+p` | (forma larga) pegar desde el clipboard del sistema |

> Esto confunde a todos al principio: si copiás con `y` y querés pegar en el navegador, no va
> a estar. Usá `Espacio y` para que vaya al portapapeles de Windows.

---

## Buscar dentro del mismo archivo

| Tecla | Qué hace |
|-------|----------|
| `/` | Buscar hacia adelante (regex) |
| `?` | Buscar hacia atrás |
| `n` / `N` | Siguiente / anterior coincidencia |
| `*` | Buscar la palabra bajo el cursor |
| `Enter` | Confirmar la búsqueda |

---

## Moverse dentro del archivo

| Tecla | Qué hace |
|-------|----------|
| `h` `j` `k` `l` | Izq / abajo / arriba / der |
| `w` `b` `e` | Siguiente palabra / palabra atrás / fin de palabra |
| `gg` / `ge` | Inicio / fin del archivo |
| `gh` / `gl` | Inicio / fin de línea |
| `f<char>` / `t<char>` | Saltar a / antes de un carácter en la línea |
| `Ctrl+d` / `Ctrl+u` | Media página abajo / arriba |

---

## Edición extra

| Atajo | Qué hace |
|-------|----------|
| `>` / `<` | Indentar / des-indentar selección |
| `gc` | Comentar/descomentar línea o selección |
| `:format` o `:fmt` | Formatear (Java: jdtls; TS/HTML: Prettier) |

---

## Múltiples cursores (potente en Helix)

| Atajo | Qué hace |
|-------|----------|
| `C` | Añadir cursor en la línea de abajo |
| `%` | Seleccionar todo el archivo |
| `s` (en selección) | Seleccionar todas las coincidencias de un patrón |
| `,` | Colapsar a un solo cursor |

Flujo típico: `%` (todo) → `s` → escribir patrón → `Enter` → editás todas las coincidencias a la vez.

---

## Diagnóstico y ayuda

| Comando | Qué hace |
|---------|----------|
| `:log-open` | Ver el log de los language servers (útil si algo falla) |
| `:tutor` | Tutorial interactivo de Helix |
| `:config-open` | Abrir el config.toml |
| `:theme nombre` | Cambiar tema en vivo (temporal) |
| `Espacio` `?` | Buscar un comando (command palette) |

---

## Paneles dentro de Helix

| Atajo | Qué hace |
|-------|----------|
| `Ctrl+w` `v` | Dividir vertical |
| `Ctrl+w` `s` | Dividir horizontal |
| `Ctrl+w` `h/j/k/l` | Moverse entre paneles |
| `Ctrl+w` `q` | Cerrar panel |

> Para editor + terminal lado a lado, usar los splits de **Cmder** (`Ctrl+Shift+E` vertical,
> `Ctrl+Shift+O` horizontal) — ver HELIX-SETUP.md sección 7.

---

## Para arrancar — lo mínimo que te hace productivo

Si solo memorizás esto, ya navegás más rápido que con mouse:
1. `Espacio f` — abrir archivos.
2. `Espacio /` — buscar texto en el proyecto.
3. `gd` + `Ctrl+o` — ir a una definición y volver.
4. El modelo **selección → verbo** (`w` `d` = seleccionar palabra, borrar).
5. `Espacio y` / `Espacio p` — copiar/pegar con el portapapeles de Windows.

El resto entra solo con el uso y los menús contextuales (`Espacio` abre el menú líder).
