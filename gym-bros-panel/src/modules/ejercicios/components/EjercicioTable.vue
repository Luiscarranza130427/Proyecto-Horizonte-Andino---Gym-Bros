<script setup>
import { Dumbbell, Eye } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import { CATEGORIAS, EQUIPOS, NIVELES, etiquetaDe } from '@/modules/ejercicios/catalogos'
import { formatearNumero } from '@/shared/utils/formato'

const props = defineProps({
  items: { type: Array, required: true },
  paginacion: { type: Object, required: true },
  cargando: { type: Boolean, default: false },
  empresaId: { type: [Number, String], default: null },
  ejercicioProcesandoId: { type: [Number, String], default: null },
})

defineEmits(['cambiar-pagina', 'desactivar', 'cambiar-estado-empresa'])

const paginas = computed(() => {
  const total = props.paginacion.ultimaPagina
  const actual = props.paginacion.pagina
  if (total <= 5) return Array.from({ length: total }, (_, indice) => indice + 1)
  let inicio = Math.max(1, actual - 2)
  const fin = Math.min(total, inicio + 4)
  inicio = Math.max(1, fin - 4)
  return Array.from({ length: fin - inicio + 1 }, (_, indice) => inicio + indice)
})

function etiquetaCategoria(ejercicio) {
  if (ejercicio.grupoMuscularTipo) {
    const tipo = ejercicio.grupoMuscularTipo
    return `${tipo.charAt(0).toUpperCase()}${tipo.slice(1)}`
  }
  return etiquetaDe(CATEGORIAS, ejercicio.categoria)
}

function etiquetaTipo(tipo) {
  return tipo ? String(tipo).replaceAll('_', ' ') : 'Ejercicio'
}

function etiquetaEquipo(equipo) {
  return EQUIPOS.find((opcion) => opcion.valor === equipo)?.etiqueta ?? equipo ?? 'Sin equipo'
}

function estadoEmpresaNoDisponible(ejercicio) {
  return ejercicio.estadoEmpresa === null || ejercicio.estadoEmpresa === undefined
}

function puedeCambiarEstadoEmpresa() {
  return Boolean(props.empresaId)
}

function ayudaEstadoEmpresa(ejercicio) {
  if (!props.empresaId) return 'No hay una empresa seleccionada.'
  if (estadoEmpresaNoDisponible(ejercicio)) return 'Activar para esta empresa.'
  return ejercicio.estadoEmpresa === 'active'
    ? 'Desactivar para esta empresa'
    : 'Activar para esta empresa'
}
</script>

<template>
  <section class="catalogo" aria-label="Listado de ejercicios" :aria-busy="cargando">
    <div class="catalogo__rejilla">
      <article
        v-for="fila in cargando ? 20 : items"
        :key="cargando ? fila : fila.id"
        class="ejercicio"
        :class="{ 'ejercicio--cargando': cargando }"
      >
        <template v-if="cargando">
          <span class="skeleton ejercicio__skeleton-imagen"></span>
          <div class="ejercicio__contenido">
            <span class="skeleton skeleton--corto"></span>
            <span class="skeleton ejercicio__skeleton-titulo"></span>
            <span class="skeleton"></span>
            <span class="skeleton ejercicio__skeleton-equipo"></span>
          </div>
        </template>
        <template v-else>
          <RouterLink
            class="ejercicio__imagen"
            :to="{ name: 'ejercicio-detalle', params: { id: fila.id } }"
            :aria-label="`Ver ${fila.nombre}`"
          >
            <img v-if="fila.imagen" :src="fila.imagen" :alt="fila.nombre" />
            <span v-else class="ejercicio__sin-imagen" aria-label="Ejercicio sin imagen">
              <Dumbbell :size="38" aria-hidden="true" />
            </span>
            <span class="ejercicio__tipo">{{ etiquetaTipo(fila.tipo) }}</span>
          </RouterLink>

          <div class="ejercicio__contenido">
            <span class="ejercicio__nivel">{{ etiquetaDe(NIVELES, fila.nivel) }}</span>
            <RouterLink
              class="ejercicio__nombre"
              :to="{ name: 'ejercicio-detalle', params: { id: fila.id } }"
            >
              {{ fila.nombre }}
            </RouterLink>
            <p>{{ fila.descripcion || etiquetaCategoria(fila) }}</p>
            <span class="ejercicio__equipo">
              <Dumbbell :size="15" aria-hidden="true" />
              {{ etiquetaEquipo(fila.equipo) }}
            </span>
          </div>

          <footer class="ejercicio__acciones">
            <button
              type="button"
              class="btn ejercicio__empresa-accion"
              :class="
                fila.estadoEmpresa === 'active'
                  ? 'ejercicio__empresa-accion--desactivar'
                  : 'ejercicio__empresa-accion--activar'
              "
              :disabled="!puedeCambiarEstadoEmpresa(fila) || ejercicioProcesandoId === fila.id"
              :title="ayudaEstadoEmpresa(fila)"
              :aria-label="`Cambiar disponibilidad de ${fila.nombre} para esta empresa`"
              @click="
                $emit('cambiar-estado-empresa', {
                  ejercicio: fila,
                  estado: fila.estadoEmpresa !== 'active',
                })
              "
            >
              {{
                ejercicioProcesandoId === fila.id
                  ? 'Guardando…'
                  : fila.estadoEmpresa === 'active'
                    ? 'Desactivar'
                    : 'Activar'
              }}
            </button>
            <RouterLink
              class="btn ejercicio__ver-detalle"
              :to="{ name: 'ejercicio-detalle', params: { id: fila.id } }"
              :aria-label="`Ver detalle de ${fila.nombre}`"
            >
              <Eye :size="16" aria-hidden="true" />
              Ver detalle
            </RouterLink>
          </footer>
        </template>
      </article>
    </div>

    <footer v-if="!cargando && paginacion.total" class="catalogo__paginacion">
      <p>
        Mostrando {{ formatearNumero(paginacion.desde) }}–{{ formatearNumero(paginacion.hasta) }} de
        {{ formatearNumero(paginacion.total) }} ejercicios
      </p>
      <nav aria-label="Paginación de ejercicios">
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
          class="catalogo__pagina"
          :class="{ 'catalogo__pagina--activa': pagina === paginacion.pagina }"
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
.catalogo {
  display: grid;
  gap: 1rem;
}
.catalogo__rejilla {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(17rem, 1fr));
  gap: 1rem;
}
.ejercicio {
  display: grid;
  overflow: hidden;
  min-width: 0;
  background: var(--gb-surface);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  transition:
    border-color 0.18s ease,
    transform 0.18s ease;
}
.ejercicio:not(.ejercicio--cargando):hover {
  border-color: var(--gb-text-muted);
  transform: translateY(-2px);
}
.ejercicio__imagen {
  position: relative;
  display: block;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  background: var(--gb-surface-lowest);
  text-decoration: none;
}
.ejercicio__imagen img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.25s ease;
}
.ejercicio:hover .ejercicio__imagen img {
  transform: scale(1.03);
}
.ejercicio__sin-imagen {
  display: grid;
  width: 100%;
  height: 100%;
  place-items: center;
  color: var(--gb-text-muted);
}
.ejercicio__tipo {
  position: absolute;
  top: 0.75rem;
}
.ejercicio__tipo {
  left: 0.75rem;
  padding: 0.3rem 0.5rem;
  background: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: 5px;
  color: var(--gb-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 800;
  text-transform: uppercase;
}
.ejercicio__contenido {
  display: grid;
  align-content: start;
  gap: 0.55rem;
  padding: 1rem;
}
.ejercicio__nivel {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 800;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
.ejercicio__nombre {
  overflow: hidden;
  color: var(--gb-text);
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-md);
  font-weight: 800;
  line-height: 1.15;
  text-decoration: none;
  text-overflow: ellipsis;
  text-transform: uppercase;
  white-space: nowrap;
}
.ejercicio__nombre:hover {
  color: var(--gb-red-text);
}
.ejercicio__contenido p {
  display: -webkit-box;
  min-height: 2.6em;
  margin: 0;
  overflow: hidden;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  line-height: 1.3;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}
.ejercicio__equipo {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.5rem;
  padding: 0.5rem 0.625rem;
  overflow: hidden;
  background: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  text-overflow: ellipsis;
  white-space: nowrap;
}
.ejercicio__empresa-accion {
  flex: 1 1 50%;
  min-height: 1.9rem;
  padding: 0.25rem 0.6rem;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
}
.ejercicio__empresa-accion--activar {
  color: var(--gb-surface-lowest);
  background-color: var(--gb-tenant-secondary, var(--gb-green));
  border-color: var(--gb-tenant-secondary, var(--gb-green));
}
.ejercicio__empresa-accion--desactivar {
  color: var(--gb-surface-lowest);
  background-color: var(--gb-tenant-secondary, var(--gb-green));
  border-color: var(--gb-tenant-secondary, var(--gb-green));
}
.ejercicio__empresa-accion:disabled {
  cursor: not-allowed;
  opacity: 0.45;
}
.ejercicio__acciones {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.75rem 1rem;
  border-top: 1px solid var(--gb-border);
}
.ejercicio__ver-detalle {
  display: inline-flex;
  flex: 1 1 50%;
  justify-content: center;
  align-items: center;
  gap: 0.35rem;
  min-height: 2.25rem;
  padding: 0.375rem 0.65rem;
  color: var(--gb-text-muted);
  border: 1px solid var(--gb-text-soft);
  border-radius: 5px;
  font-size: var(--gb-tipo-xxs);
  text-decoration: none;
}
.ejercicio__ver-detalle:hover {
  color: var(--gb-text);
}
.ejercicio__skeleton-imagen {
  min-height: 10rem;
  border-radius: 0;
}
.ejercicio__skeleton-titulo {
  width: 70%;
  height: 1.25rem;
}
.ejercicio__skeleton-equipo {
  height: 2.5rem;
}
.catalogo__paginacion {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1rem;
  background: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
}
.catalogo__paginacion p {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}
.catalogo__paginacion nav {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}
.catalogo__paginacion .btn,
.catalogo__pagina {
  min-height: 2.125rem;
  padding: 0.375rem 0.75rem;
  font-size: var(--gb-tipo-xxs);
}
.catalogo__pagina {
  min-width: 2.125rem;
  color: var(--gb-text-muted);
  background: transparent;
  border: 1px solid transparent;
  border-radius: var(--gb-radius);
}
.catalogo__pagina--activa {
  color: var(--gb-text);
  background: var(--gb-surface-high);
  border-color: var(--gb-border);
}
@media (max-width: 42rem) {
  .catalogo__rejilla {
    grid-template-columns: 1fr;
  }
  .catalogo__paginacion {
    align-items: flex-start;
    flex-direction: column;
  }
  .catalogo__paginacion nav {
    flex-wrap: wrap;
  }
}
</style>
