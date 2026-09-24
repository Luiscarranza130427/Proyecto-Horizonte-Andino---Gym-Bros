<script setup>
import { CircleMinus, Clock, Pencil, Plus, Utensils } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import { TIPOS_COMIDA, UNIDADES, etiquetaDe, ordenDeComida } from '@/modules/alimentacion/catalogos'
import { formatearNumero } from '@/shared/utils/formato'

/**
 * El horario de comidas de un plan.
 *
 * `docs/PANELES.md` pide «rejilla de tarjetas de comidas: imagen, nombre y
 * texto». La tabla `comidas` del esquema NO tiene imagen, ni nombre, ni texto:
 * tiene `tipo_comida`, `orden` y `hora_sugerida`. Aquí no se inventan esos tres
 * campos. Cada tarjeta se construye con lo que el esquema sí sostiene —la hora,
 * el tipo de comida y los alimentos que la componen— y la discrepancia queda
 * anotada para documentarla.
 */

const props = defineProps({
  comidas: { type: Array, default: () => [] },
  /** Necesario para los enlaces de edición y alta, que cuelgan del plan. */
  idPlan: { type: [String, Number], required: true },
  /** Mientras hay una acción en curso los controles no vuelven a dispararse. */
  ocupado: { type: Boolean, default: false },
})

defineEmits(['eliminar'])

/**
 * Tramos del día. Salen de `hora_sugerida` y de nada más: no son un campo
 * inventado, sino la lectura de la hora que convierte la lista en un horario.
 * `hasta` es exclusivo y se compara como texto, que en 'HH:MM' ordena bien.
 */
const TRAMOS = [
  { clave: 'manana', etiqueta: 'Mañana', hasta: '12:00' },
  { clave: 'tarde', etiqueta: 'Tarde', hasta: '19:00' },
  { clave: 'noche', etiqueta: 'Noche', hasta: '24:00' },
]

const TRAMO_SIN_HORA = { clave: 'sin-hora', etiqueta: 'Sin hora asignada' }

function tramoDe(horaSugerida) {
  if (!horaSugerida) return TRAMO_SIN_HORA
  return TRAMOS.find((tramo) => horaSugerida < tramo.hasta) ?? TRAMOS[TRAMOS.length - 1]
}

/**
 * Ordenar es trabajo de esta pantalla, no del servicio: `ordenDeComida` existe
 * en `catalogos.js` justo para esto. Manda la hora; con la hora empatada, el
 * orden natural del día; y en último término el `orden` que fijó el entrenador.
 */
const comidasOrdenadas = computed(() =>
  [...props.comidas].sort(
    (a, b) =>
      String(a.horaSugerida).localeCompare(String(b.horaSugerida)) ||
      ordenDeComida(a.tipoComida) - ordenDeComida(b.tipoComida) ||
      a.orden - b.orden,
  ),
)

/** Sólo se dibujan los tramos que tienen algo dentro. */
const tramosConComidas = computed(() => {
  const agrupadas = new Map()

  comidasOrdenadas.value.forEach((comida) => {
    const tramo = tramoDe(comida.horaSugerida)
    if (!agrupadas.has(tramo.clave)) agrupadas.set(tramo.clave, { ...tramo, comidas: [] })
    agrupadas.get(tramo.clave).comidas.push(comida)
  })

  // Las comidas sin hora van al final: no se puede afirmar cuándo tocan.
  return [...TRAMOS, TRAMO_SIN_HORA].map((tramo) => agrupadas.get(tramo.clave)).filter(Boolean)
})

function nombreDeUnidad(unidad) {
  return UNIDADES.find((opcion) => opcion.valor === unidad)?.nombre ?? unidad
}
</script>

<template>
  <section class="horario gb-tarjeta" aria-labelledby="titulo-horario">
    <header class="horario__cabecera">
      <span class="horario__icono" aria-hidden="true"><Utensils :size="20" /></span>
      <div>
        <p>Plan del día</p>
        <h2 id="titulo-horario">Horario de comidas</h2>
      </div>
      <RouterLink
        class="btn btn-primary horario__nueva"
        :to="{ name: 'comida-nueva', params: { idPlan } }"
      >
        <Plus :size="16" aria-hidden="true" />
        Añadir comida
      </RouterLink>
    </header>

    <div v-if="!comidasOrdenadas.length" class="horario__vacio" role="status">
      <Clock :size="32" aria-hidden="true" />
      <div>
        <h3>Este plan todavía no tiene comidas</h3>
        <p>Añade la primera para que el horario diga algo.</p>
      </div>
    </div>

    <div v-else class="horario__cuerpo">
      <section v-for="tramo in tramosConComidas" :key="tramo.clave" class="tramo">
        <h3 class="tramo__titulo">{{ tramo.etiqueta }}</h3>

        <ol class="tramo__comidas">
          <li v-for="comida in tramo.comidas" :key="comida.id">
            <article class="comida">
              <div class="comida__hora">
                <time v-if="comida.horaSugerida" :datetime="comida.horaSugerida">
                  {{ comida.horaSugerida }}
                </time>
                <span v-else>--:--</span>
              </div>

              <div class="comida__cuerpo">
                <header class="comida__cabecera">
                  <h4>{{ etiquetaDe(TIPOS_COMIDA, comida.tipoComida) }}</h4>
                  <div class="comida__acciones">
                    <RouterLink
                      class="gb-boton-icono"
                      :to="{
                        name: 'comida-editar',
                        params: { idPlan, idComida: comida.id },
                      }"
                      :aria-label="`Editar la comida de las ${comida.horaSugerida || 'sin hora'}`"
                      title="Editar comida"
                    >
                      <Pencil :size="16" aria-hidden="true" />
                    </RouterLink>
                    <button
                      type="button"
                      class="gb-boton-icono comida__retirar"
                      :disabled="ocupado"
                      :aria-label="`Retirar la comida de las ${comida.horaSugerida || 'sin hora'}`"
                      title="Retirar comida"
                      @click="$emit('eliminar', comida)"
                    >
                      <CircleMinus :size="16" aria-hidden="true" />
                    </button>
                  </div>
                </header>

                <p class="comida__macros">
                  <strong>{{ formatearNumero(comida.macros.calorias) }} kcal</strong>
                  <span>
                    P {{ formatearNumero(comida.macros.proteinas) }} g · C
                    {{ formatearNumero(comida.macros.carbohidratos) }} g · G
                    {{ formatearNumero(comida.macros.grasas) }} g · Fibra
                    {{ formatearNumero(comida.macros.fibra) }} g
                  </span>
                </p>

                <ul v-if="comida.alimentos.length" class="comida__alimentos">
                  <li v-for="porcion in comida.alimentos" :key="porcion.id">
                    <span class="porcion__nombre">{{ porcion.alimento.nombre }}</span>
                    <span class="porcion__cantidad">
                      {{ formatearNumero(porcion.cantidad) }}
                      <abbr :title="nombreDeUnidad(porcion.unidad)">
                        {{ etiquetaDe(UNIDADES, porcion.unidad) }}
                      </abbr>
                    </span>
                    <span class="porcion__kcal">
                      {{ formatearNumero(porcion.macros.calorias) }} kcal
                    </span>
                  </li>
                </ul>
                <p v-else class="comida__sin-alimentos">Esta comida no tiene alimentos.</p>
              </div>
            </article>
          </li>
        </ol>
      </section>
    </div>
  </section>
</template>

<style scoped>
.horario {
  min-width: 0;
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
}

.horario__cabecera {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding-bottom: 0.875rem;
  border-bottom: 1px solid var(--gb-border);
}

.horario__icono {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
}

.horario__cabecera > div {
  flex: 1 1 auto;
  min-width: 0;
}

.horario__cabecera p,
.horario__cabecera h2 {
  margin: 0;
}

.horario__cabecera p {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.horario__cabecera h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.horario__nueva {
  flex: none;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.5rem;
  padding-inline: 1rem;
  font-size: var(--gb-tipo-xs);
  text-decoration: none;
}

.horario__vacio {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  padding: 2rem 0.5rem;
  color: var(--gb-text-muted);
}

.horario__vacio > svg {
  color: var(--gb-text-soft);
  font-size: 1.75rem;
}

.horario__vacio h3 {
  margin: 0;
  font-size: var(--gb-tipo-sm);
  text-transform: uppercase;
}

.horario__vacio p {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
}

.horario__cuerpo {
  display: grid;
  gap: 1.5rem;
  margin-top: 1.25rem;
}

.tramo__titulo {
  margin: 0 0 0.75rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.tramo__comidas {
  display: grid;
  gap: 0.75rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

/* La línea del tiempo: un raíl de 1px que recorre el tramo por la izquierda. */
.tramo__comidas > li {
  position: relative;
  padding-left: 1.25rem;
}

.tramo__comidas > li::before {
  position: absolute;
  top: 1.5rem;
  bottom: -0.75rem;
  left: 0.3125rem;
  width: 1px;
  background-color: var(--gb-border);
  content: '';
}

.tramo__comidas > li:last-child::before {
  display: none;
}

.tramo__comidas > li::after {
  position: absolute;
  top: 1.0625rem;
  left: 0;
  width: 0.6875rem;
  height: 0.6875rem;
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-red);
  border-radius: var(--gb-radius-pill);
  content: '';
}

.comida {
  display: grid;
  grid-template-columns: 4.5rem minmax(0, 1fr);
  gap: 1rem;
  padding: 0.875rem 1rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
}

.comida__hora {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-md);
  font-variant-numeric: tabular-nums;
  font-weight: 800;
  letter-spacing: 0.02em;
}

.comida__cuerpo {
  min-width: 0;
}

.comida__cabecera {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}

.comida__cabecera h4 {
  margin: 0;
  font-size: var(--gb-tipo-sm);
  text-transform: uppercase;
}

.comida__acciones {
  flex: none;
  display: flex;
  gap: 0.25rem;
}

.comida__acciones .gb-boton-icono {
  width: 2rem;
  height: 2rem;
  color: var(--gb-text-muted);
  text-decoration: none;
}

.comida__retirar:not(:disabled):hover {
  color: var(--gb-error);
}

.comida__retirar:disabled {
  cursor: not-allowed;
  opacity: 0.35;
}

.comida__macros {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 0.375rem 0 0;
  font-variant-numeric: tabular-nums;
}

.comida__macros strong {
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
}

.comida__macros span {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.comida__alimentos {
  display: grid;
  gap: 0.25rem;
  margin: 0.75rem 0 0;
  padding: 0;
  list-style: none;
}

.comida__alimentos > li {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto auto;
  align-items: baseline;
  gap: 0.75rem;
  padding-top: 0.375rem;
  border-top: 1px solid var(--gb-border);
  font-size: var(--gb-tipo-xs);
}

.porcion__nombre {
  overflow: hidden;
  color: var(--gb-text);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.porcion__cantidad,
.porcion__kcal {
  color: var(--gb-text-muted);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.porcion__cantidad abbr {
  text-decoration: none;
}

.porcion__kcal {
  min-width: 5rem;
  text-align: right;
}

.comida__sin-alimentos {
  margin: 0.75rem 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

@media (max-width: 48rem) {
  .horario__cabecera {
    align-items: flex-start;
    flex-wrap: wrap;
  }

  .horario__nueva {
    width: 100%;
    justify-content: center;
  }

  .comida {
    grid-template-columns: 1fr;
    gap: 0.5rem;
  }

  .comida__alimentos > li {
    grid-template-columns: minmax(0, 1fr) auto;
  }

  .porcion__kcal {
    grid-column: 2;
    min-width: 0;
  }
}
</style>
