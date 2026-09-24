<script setup>
import { Eye } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import { formatearFecha, formatearNumero } from '@/shared/utils/formato'

/**
 * Listado de planes en TABLA, no en tarjetas.
 *
 * `docs/PANELES.md` pide una rejilla de tarjetas, pero para las COMIDAS de un
 * plan (eso lo hace `HorarioDeComidas`). Aquí se comparan planes entre sí por
 * las mismas cinco dimensiones —quién, dónde, hasta cuándo, cuántas comidas y
 * cuánto se desvía de su objetivo—, y comparar valores homogéneos se hace
 * recorriendo una columna. Una rejilla de tarjetas obligaría a leer cada plan
 * entero para responder «cuál se pasa de calorías».
 */

const props = defineProps({
  items: { type: Array, required: true },
  paginacion: { type: Object, required: true },
  cargando: { type: Boolean, default: false },
})

defineEmits(['cambiar-pagina'])

const paginas = computed(() => {
  const total = props.paginacion.ultimaPagina
  const actual = props.paginacion.pagina
  if (total <= 5) return Array.from({ length: total }, (_, indice) => indice + 1)

  let inicio = Math.max(1, actual - 2)
  const fin = Math.min(total, inicio + 4)
  inicio = Math.max(1, fin - 4)
  return Array.from({ length: fin - inicio + 1 }, (_, indice) => inicio + indice)
})

/** Una fecha vacía se dice con un guion, no con «Fecha no disponible» dos veces. */
function dia(fecha) {
  return fecha ? formatearFecha(fecha) : '—'
}

/**
 * Cuánto se aparta lo que suman las comidas de lo que fijó el entrenador.
 *
 * Se muestra con signo y sin colorear: el panel no sabe cuánta desviación es
 * aceptable, así que no pinta de verde ni de ámbar un juicio que no le consta.
 */
function desviacion({ macros, objetivos }) {
  if (!objetivos.calorias) return ''
  const diferencia = Math.round(macros.calorias - objetivos.calorias)
  if (diferencia === 0) return 'Sin desvío'
  return `${diferencia > 0 ? '+' : '−'}${formatearNumero(Math.abs(diferencia))} kcal`
}
</script>

<template>
  <section
    class="tabla gb-tarjeta"
    aria-label="Listado de planes de alimentación"
    :aria-busy="cargando"
  >
    <div class="tabla__desplazamiento">
      <table>
        <caption class="visually-hidden">
          Planes de alimentación registrados en Gym Bros
        </caption>
        <thead>
          <tr>
            <th scope="col">Usuario</th>
            <th scope="col">Empresa</th>
            <th scope="col">Vigencia</th>
            <th scope="col">Situación</th>
            <th scope="col" class="tabla__numero">Comidas</th>
            <th scope="col">Calorías (real / objetivo)</th>
            <th scope="col" class="tabla__acciones-titulo">Acciones</th>
          </tr>
        </thead>
        <tbody v-if="cargando">
          <tr v-for="fila in 6" :key="fila" class="tabla__skeleton" aria-hidden="true">
            <td><span class="skeleton skeleton--usuario"></span></td>
            <td><span class="skeleton"></span></td>
            <td><span class="skeleton"></span></td>
            <td><span class="skeleton skeleton--corto"></span></td>
            <td><span class="skeleton skeleton--corto"></span></td>
            <td><span class="skeleton"></span></td>
            <td><span class="skeleton skeleton--acciones"></span></td>
          </tr>
        </tbody>
        <tbody v-else>
          <tr v-for="plan in items" :key="plan.id">
            <td>
              <RouterLink
                class="tabla__plan"
                :to="{ name: 'plan-alimentacion-detalle', params: { id: plan.id } }"
              >
                <strong>{{ plan.usuario?.nombre || 'Usuario sin nombre' }}</strong>
                <small>{{ plan.objetivo || 'Sin objetivo registrado' }}</small>
              </RouterLink>
            </td>
            <td>{{ plan.empresa?.nombre || '—' }}</td>
            <td class="tabla__fecha">{{ dia(plan.fechaInicio) }} – {{ dia(plan.fechaFin) }}</td>
            <td>
              <span
                class="tabla__situacion"
                :class="plan.activo ? 'tabla__situacion--activo' : 'tabla__situacion--inactivo'"
              >
                {{ plan.activo ? 'Activo' : 'Finalizado' }}
              </span>
            </td>
            <td class="tabla__numero tabla__tabular">{{ formatearNumero(plan.totalComidas) }}</td>
            <td>
              <div class="tabla__calorias">
                <strong class="tabla__tabular">
                  {{ formatearNumero(plan.macros.calorias) }} /
                  {{ plan.objetivos.calorias ? formatearNumero(plan.objetivos.calorias) : '—' }}
                </strong>
                <small v-if="desviacion(plan)">{{ desviacion(plan) }}</small>
                <small v-else>Sin objetivo fijado</small>
              </div>
            </td>
            <td>
              <div class="tabla__acciones">
                <RouterLink
                  class="gb-boton-icono"
                  :to="{ name: 'plan-alimentacion-detalle', params: { id: plan.id } }"
                  :aria-label="`Ver el plan de ${plan.usuario?.nombre || 'este usuario'}`"
                  title="Ver horario"
                >
                  <Eye :size="16" aria-hidden="true" />
                </RouterLink>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <footer v-if="!cargando && paginacion.total" class="tabla__paginacion">
      <p>
        Mostrando {{ formatearNumero(paginacion.desde) }}–{{ formatearNumero(paginacion.hasta) }} de
        {{ formatearNumero(paginacion.total) }} planes
      </p>
      <nav aria-label="Paginación de planes">
        <button
          type="button"
          class="btn btn-ghost"
          :disabled="paginacion.pagina <= 1"
          @click="$emit('cambiar-pagina', paginacion.pagina - 1)"
        >
          Anterior
        </button>
        <button
          v-for="pagina in paginas"
          :key="pagina"
          type="button"
          class="tabla__pagina"
          :class="{ 'tabla__pagina--activa': pagina === paginacion.pagina }"
          :aria-current="pagina === paginacion.pagina ? 'page' : null"
          :aria-label="`Página ${pagina}`"
          @click="$emit('cambiar-pagina', pagina)"
        >
          {{ pagina }}
        </button>
        <button
          type="button"
          class="btn btn-ghost"
          :disabled="paginacion.pagina >= paginacion.ultimaPagina"
          @click="$emit('cambiar-pagina', paginacion.pagina + 1)"
        >
          Siguiente
        </button>
      </nav>
    </footer>
  </section>
</template>

<style scoped>
.tabla {
  overflow: hidden;
  border-radius: var(--gb-radius-lg);
}

.tabla__desplazamiento {
  max-width: 100%;
  overflow-x: auto;
}

table {
  width: 100%;
  min-width: 62rem;
  border-collapse: collapse;
}

th,
td {
  padding: 0.875rem 1rem;
  border-bottom: 1px solid var(--gb-border);
  text-align: left;
  vertical-align: middle;
}

th {
  background-color: var(--gb-surface-lowest);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  white-space: nowrap;
}

td {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

tbody tr {
  background-color: var(--gb-surface);
  transition: background-color 0.18s ease;
}

tbody tr:hover {
  background-color: var(--gb-surface-high-50);
}

tbody tr:last-child td {
  border-bottom: 0;
}

.tabla__plan {
  display: grid;
  min-width: 13rem;
  color: var(--gb-text);
  text-decoration: none;
}

.tabla__plan:hover strong {
  color: var(--gb-red-text);
}

.tabla__plan strong {
  overflow: hidden;
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-sm);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tabla__plan small {
  max-width: 20rem;
  overflow: hidden;
  margin-top: 0.125rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tabla__situacion {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  white-space: nowrap;
}

.tabla__situacion--activo {
  color: var(--gb-green);
}

.tabla__situacion--inactivo {
  color: var(--gb-text-muted);
}

.tabla__calorias {
  display: grid;
  min-width: 9rem;
}

.tabla__calorias strong {
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
}

.tabla__calorias small {
  margin-top: 0.125rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-variant-numeric: tabular-nums;
}

.tabla__numero {
  text-align: right;
}

.tabla__tabular {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.tabla__fecha {
  white-space: nowrap;
}

.tabla__acciones-titulo {
  text-align: right;
}

.tabla__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.25rem;
}

.tabla__acciones .gb-boton-icono {
  width: 2.125rem;
  height: 2.125rem;
  color: var(--gb-text-muted);
  text-decoration: none;
}

.tabla__paginacion {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1rem;
  background-color: var(--gb-surface-lowest);
  border-top: 1px solid var(--gb-border);
}

.tabla__paginacion p {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.tabla__paginacion nav {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.tabla__paginacion .btn {
  min-height: 2.125rem;
  padding: 0.375rem 0.75rem;
  font-size: var(--gb-tipo-xxs);
}

.tabla__pagina {
  display: grid;
  place-items: center;
  width: 2.125rem;
  height: 2.125rem;
  background-color: transparent;
  border: 1px solid transparent;
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.tabla__pagina:hover {
  background-color: var(--gb-surface-high);
  color: var(--gb-text);
}

.tabla__pagina--activa {
  background-color: var(--gb-red);
  color: var(--gb-on-red);
}

.tabla__skeleton:hover {
  background-color: var(--gb-surface);
}

.skeleton {
  display: block;
  width: 7rem;
  height: 0.75rem;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
  animation: pulso 1.2s ease-in-out infinite alternate;
}

.skeleton--usuario {
  width: 12rem;
  height: 2rem;
  border-radius: var(--gb-radius);
}

.skeleton--corto {
  width: 4rem;
}

.skeleton--acciones {
  width: 2.5rem;
  margin-left: auto;
}

@keyframes pulso {
  to {
    opacity: 0.45;
  }
}

@media (max-width: 90rem) {
  th:nth-child(2),
  td:nth-child(2) {
    display: none;
  }

  table {
    min-width: 54rem;
  }
}

@media (max-width: 58rem) {
  .tabla__paginacion {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
