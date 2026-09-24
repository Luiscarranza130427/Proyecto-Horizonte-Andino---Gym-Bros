# Modelo de datos — Gym Bros

Esquema de la base de datos que está construyendo Natan. **Es la referencia para
decidir los campos de cualquier módulo nuevo**: mientras la API no exista, lo que
aquí figure manda sobre cualquier suposición.

> Este documento describe la base de datos, no la API. Los nombres que viajen por
> HTTP los decide Laravel y pueden diferir; cuando se cierren, cada
> `normalizarXxx` de `src/services/` los traduce al vocabulario del dominio.

Convenciones observadas en todas las tablas: `id` autoincremental,
`created_at` / `updated_at`, y `estado` / `activo` como `BOOLEAN` (el frontend lo
normaliza a `'active'` / `'inactive'` en `services/normalizacion.js`).

---

## Mapa de relaciones

Lo que más condiciona a la interfaz no son los campos, sino de quién cuelga cada
cosa:

```text
empresas ──┬── usuarios ──┬── evaluaciones_fisicas
           │              ├── rutinas ── ejercicios_rutina ── ejercicios
           │              ├── planes_alimentacion ── comidas ── comida_alimentos ── alimentos
           │              ├── preferencias_alimentarias ── alimentos
           │              ├── progresos
           │              └── sensaciones
           ├── ejercicios (cada empresa tiene su catálogo)
           ├── suscripciones ── planes
           ├── pagos ── suscripciones
           ├── notificaciones
           └── historial_cambios

grupos_musculares ── ejercicios
```

**Dos consecuencias que hay que tener presentes:**

1. **Quien se suscribe a un plan es la EMPRESA, no el usuario.** `suscripciones`
   y `pagos` cuelgan de `empresas`. Un usuario no tiene plan propio.
2. **El catálogo de ejercicios es por empresa** (`ejercicios.id_empresas`). No
   hay un catálogo global compartido.

---

## Núcleo

### `empresas`

| Campo                               | Tipo         | Nulo | Notas                                                       |
| ----------------------------------- | ------------ | ---- | ----------------------------------------------------------- |
| `nombre`                            | VARCHAR(150) | no   |                                                             |
| `nombre_gerente`                    | VARCHAR(200) | no   |                                                             |
| `region`                            | ENUM         | sí   | Las 25 regiones del Perú (`src/constants/regionesPeru.js`)  |
| `ruc`                               | VARCHAR(12)  | sí   |                                                             |
| `enlace_web`                        | VARCHAR(300) | sí   |                                                             |
| `direccion`                         | VARCHAR(250) | sí   |                                                             |
| `telefono`                          | VARCHAR(9)   | no   | **9 caracteres**: número peruano sin prefijo                |
| `correo`                            | VARCHAR(150) | no   |                                                             |
| `estado`                            | BOOLEAN      | no   | por defecto `TRUE`                                          |
| `fecha_registro`                    | DATE         | no   |                                                             |
| `logo`                              | VARCHAR(300) | no   | ruta o URL de la imagen                                     |
| `color_1`, `color_2`                | VARCHAR(10)  | no   | color de marca, formato `#rrggbb`                           |
| `banner_1..3`                       | VARCHAR(300) | sí   | imágenes de portada                                         |
| `link_boton_1..3`                   | VARCHAR(200) | sí   | destino de cada banner                                      |
| `horario_inicio_*`, `horario_fin_*` | DECIMAL(3,2) | no   | uno por día: `lun mar mier juev vier sab dom` (14 columnas) |

**Pendiente de aclarar con Natan:** `DECIMAL(3,2)` sólo admite un dígito entero
(0,00 a 9,99), así que no puede representar las 19:30. Para una hora hacen falta
`TIME`, o `DECIMAL(4,2)` con formato 19.50, o dos enteros.

### `usuarios`

| Campo                                | Tipo            | Nulo | Notas                                                  |
| ------------------------------------ | --------------- | ---- | ------------------------------------------------------ |
| `nombre`, `apellido`                 | VARCHAR(100)    | no   |                                                        |
| `correo`                             | VARCHAR(100)    | no   |                                                        |
| `password_hash`                      | VARCHAR(150)    | no   | **nunca sale al frontend**                             |
| `tipo_documento`                     | ENUM            | no   | `DNI`, `Pasaporte`, `Otro` — **con mayúscula inicial** |
| `numero_documento`                   | VARCHAR(12)     | no   |                                                        |
| `telefono`                           | VARCHAR(12)     | no   |                                                        |
| `direccion`                          | VARCHAR(150)    | sí   |                                                        |
| `foto_perfil`                        | VARCHAR(250)    | sí   |                                                        |
| `fecha_registro`, `fecha_nacimiento` | DATE            | no   |                                                        |
| `asistencia_semanal`                 | DATETIME        | sí   |                                                        |
| `tipo_usuario`                       | ENUM            | no   | `Administrador`, `Empresa`, `Entrenador`, `Usuario`    |
| `estado`                             | BOOLEAN         | no   |                                                        |
| `id_empresas`                        | FK → `empresas` |      |                                                        |

**Ojo:** un usuario **no** tiene suscripción propia. Lo que hoy muestra el módulo
de Usuarios como «suscripción del usuario» pertenece en realidad a su empresa.

### `evaluaciones_fisicas`

Medidas y objetivos de partida. `nivel_experiencia`, `actividad_diaria`,
`objetivo` (ENUM), `edad`, `peso`, `altura`, `porcentaje_grasa`,
`masa_muscular`, y perímetros de `cintura`, `pecho`, `brazo`, `muslo`, `cadera`.
Más `dias_semana`, `eleccion_dias`, `tiempo_sesion_min`, `restricciones` (ENUM
largo de accesibilidad y lesiones) y `fecha_evaluacion`.

> `restricciones` es un ENUM de valor único, pero la lista sugiere que una
> persona puede tener varias a la vez. Confirmar si debe ser tabla aparte.

---

## Entrenamiento

### `grupos_musculares`

`tipo` ENUM: `pecho`, `espalda`, `hombros`, `biceps`, `triceps`, `cuadriceps`,
`isquiotibiales`, `gluteos`, `pantorrillas`, `abdomen`. Más `descripcion` y
`estado`.

### `ejercicios`

| Campo                  | Tipo         | Nulo | Notas                                    |
| ---------------------- | ------------ | ---- | ---------------------------------------- |
| `nombre`               | VARCHAR(100) | no   |                                          |
| `descripcion`          | TEXT         | sí   |                                          |
| `instrucciones`        | TEXT         | no   | cómo se ejecuta                          |
| `nivel`                | ENUM         | no   | `Principiante`, `Intermedio`, `Avanzado` |
| `equipamiento`         | VARCHAR(100) | no   | **texto libre, no lista cerrada**        |
| `estado`               | BOOLEAN      | no   | por defecto `FALSE`                      |
| `enlace_video`         | VARCHAR(350) | sí   |                                          |
| `imagen_ejercicio`     | VARCHAR(350) | no   |                                          |
| `id_grupos_musculares` | FK           |      | la «categoría» sale de aquí              |
| `id_empresas`          | FK           |      | catálogo por empresa                     |

**No lleva series ni repeticiones**: eso es propio de cada uso del ejercicio
dentro de una rutina, y vive en `ejercicios_rutina`.

### `rutinas` y `ejercicios_rutina`

`rutinas`: `id_usuarios`, `nombre`, `descripcion`, `objetivo`, `dias_semana`,
`duracion_estimada`, `fecha_inicio`, `fecha_fin`, `estado`.

`ejercicios_rutina`: `id_rutinas`, `id_ejercicios`, `dia`, `orden`, `series`,
`repeticiones`, `peso`, `descanso_segundos`, `tiempo_segundos`, `notas`, con
`UNIQUE (id_rutinas, dia, orden)`.

---

## Alimentación

No es un módulo, son cinco tablas encadenadas:

- **`alimentos`** — catálogo: `nombre`, `tipo` (ENUM: proteina, carbohidrato,
  grasa, fruta, verdura, lacteo, cereal, legumbre, bebida, otro), `calorias`,
  `proteinas`, `carbohidratos`, `grasas`, `fibra`.
- **`planes_alimentacion`** — por usuario: objetivo y macros objetivo, fechas,
  `activo`.
- **`comidas`** — dentro de un plan: `tipo_comida` (desayuno, media_manana,
  almuerzo, media_tarde, cena, snack, otro), `orden`, `hora_sugerida`.
- **`comida_alimentos`** — qué alimento y cuánto: `cantidad` + `unidad`
  (gramos, mililitros, unidad).
- **`preferencias_alimentarias`** — alimentos no deseados o alérgenos por
  usuario. El esquema anota que debería ser multiselección.

---

## Seguimiento

- **`progresos`** — mismas medidas que `evaluaciones_fisicas`, con `fecha` y
  `notas`. Todas nulas: se registra lo que se mida ese día.
- **`sensaciones`** — por rutina y fecha: `energia`, `dificultad`, `fatiga`,
  `dolor` (enteros) y `comentario`.
- **`historial_cambios`** — auditoría: `tabla_afectada`, `id_registros`,
  `accion` (crear, actualizar, eliminar, activar, desactivar),
  `datos_anteriores` y `datos_nuevos` en JSON, `descripcion`.

---

## Comercial

### `planes`

| Campo             | Tipo          | Notas                              |
| ----------------- | ------------- | ---------------------------------- |
| `nombre`          | VARCHAR(100)  |                                    |
| `descripcion`     | TEXT          |                                    |
| `precio_original` | DECIMAL(15,2) | precio de tarifa                   |
| `precio_inicial`  | DECIMAL(15,2) | precio de captación                |
| `duracion_dias`   | INT           | **días, no meses**                 |
| `limite_usuarios` | INT           | cuántos usuarios admite la empresa |
| `activo`          | BOOLEAN       | por defecto `FALSE`                |
| `contenido`       | TEXT          | qué incluye, como texto            |
| `enlace_whatsapp` | VARCHAR(300)  | contacto de contratación           |

### `suscripciones`

`id_empresas`, `id_planes`, `fecha_inicio`, `fecha_fin`,
`estado` ENUM (`pendiente`, `activa`, `vencida`, `cancelada`, `suspendida`),
`renovacion_automatica`.

### `pagos`

`id_empresas`, `id_suscripciones`, `monto`, `moneda` (por defecto `PEN`),
`metodo_pago`, `referencia`, `estado` ENUM (`pendiente`, `aprobado`,
`rechazado`, `reembolsado`), `fecha_pago`.

---

## Comunicación

### `notificaciones`

`id_empresas` y `id_usuarios` (ambos nulos: puede ir a una empresa, a un usuario
o ser del sistema), `tipo` ENUM (`recordatorio`, `rutina`, `alimentacion`,
`suscripcion`, `sistema`, `otro`), `titulo`, `mensaje`, `fecha_envio`, `leida`,
`enviada`.

### `banners`

`imagen`, `contenido_text`, `texto_boton`, `enlace_boton`. **Le falta `id`** en
el esquema recibido.

---

## Cosas a confirmar con Natan

Anotadas aquí para no perderlas; ninguna bloquea el trabajo del frontend hoy.

1. **Horarios de `empresas`**: `DECIMAL(3,2)` no puede representar las 19:30.
2. **`ejercicios_grupo_muscular`** sólo declara la clave hacia `ejercicios`; si
   la intención es que un ejercicio tenga varios grupos musculares, le falta la
   clave hacia `grupos_musculares` — y entonces `ejercicios.id_grupos_musculares`
   sobra.
3. **`rutinas.nombre`** está declarado `DATE`; parece que debería ser VARCHAR.
4. **`restricciones`** de `evaluaciones_fisicas`: ENUM único frente a lista de
   valores que suelen darse combinados.
5. **`banners`** sin clave primaria.
6. **Nomenclatura de las claves foráneas**: unas apuntan a `empresas(id)` y
   otras a `empresas(id_empresas)`.
