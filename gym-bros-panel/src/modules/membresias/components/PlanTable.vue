<script setup>
import {
  Check,
  ChevronLeft,
  ChevronRight,
  Clock,
  ExternalLink,
  Inbox,
  Layers,
  Pencil,
  Trash2,
  Users,
} from 'lucide-vue-next'
import { RouterLink } from 'vue-router'

defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  paginacion: {
    type: Object,
    default: () => ({
      pagina: 1,
      ultimaPagina: 1,
      porPagina: 6,
      total: 0,
      desde: 0,
      hasta: 0,
    }),
  },
  cargando: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['eliminar', 'cambiarPagina'])

const formatearMonto = (monto) => {
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency: 'PEN',
    minimumFractionDigits: 2,
  }).format(monto || 0)
}

function parsearServicios(contenido = '') {
  if (!contenido) return []
  return contenido
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
}
</script>

<template>
  <div class="planes-tabla-contenedor gb-tarjeta">
    <div class="table-responsive">
      <table class="table planes-tabla" aria-label="Catálogo de planes comerciales">
        <thead>
          <tr>
            <th scope="col">Plan Comercial</th>
            <th scope="col" class="text-end">Precio</th>
            <th scope="col">Duración</th>
            <th scope="col">Capacidad</th>
            <th scope="col">Servicios Incluidos</th>
            <th scope="col" class="text-center">Estado</th>
            <th scope="col" class="text-end">Acciones</th>
          </tr>
        </thead>

        <!-- Skeletons en carga -->
        <tbody v-if="cargando">
          <tr v-for="n in 4" :key="`skeleton-${n}`" class="planes-tabla__skeleton-fila">
            <td><div class="planes-tabla__skeleton planes-tabla__skeleton--lg"></div></td>
            <td><div class="planes-tabla__skeleton planes-tabla__skeleton--sm ms-auto"></div></td>
            <td><div class="planes-tabla__skeleton planes-tabla__skeleton--sm"></div></td>
            <td><div class="planes-tabla__skeleton planes-tabla__skeleton--sm"></div></td>
            <td><div class="planes-tabla__skeleton planes-tabla__skeleton--md"></div></td>
            <td class="text-center">
              <div class="planes-tabla__skeleton planes-tabla__skeleton--badge mx-auto"></div>
            </td>
            <td class="text-end">
              <div class="planes-tabla__skeleton planes-tabla__skeleton--acciones ms-auto"></div>
            </td>
          </tr>
        </tbody>

        <!-- Sin resultados -->
        <tbody v-else-if="items.length === 0">
          <tr>
            <td colspan="7" class="planes-tabla__vacio">
              <div class="planes-tabla__vacio-contenido">
                <Inbox :size="40" class="planes-tabla__vacio-icono" aria-hidden="true" />
                <h3>No se encontraron planes</h3>
                <p>Intenta ajustar los filtros de búsqueda o registra un nuevo plan.</p>
              </div>
            </td>
          </tr>
        </tbody>

        <!-- Datos reales -->
        <tbody v-else>
          <tr v-for="plan in items" :key="plan.id" class="planes-tabla__fila">
            <!-- Plan e info -->
            <td class="planes-tabla__info">
              <div class="plan-header-info">
                <div class="plan-icono" aria-hidden="true">
                  <Layers :size="18" />
                </div>
                <div>
                  <strong class="plan-titulo">{{ plan.nombre }}</strong>
                  <p class="plan-desc">{{ plan.descripcion }}</p>
                </div>
              </div>
            </td>

            <!-- Precio -->
            <td class="planes-tabla__precio text-end">
              <span class="precio-inicial">{{ formatearMonto(plan.precioInicial) }}</span>
              <span
                v-if="plan.precioOriginal && plan.precioOriginal > plan.precioInicial"
                class="precio-original"
              >
                {{ formatearMonto(plan.precioOriginal) }}
              </span>
            </td>

            <!-- Duración -->
            <td class="planes-tabla__duracion">
              <div class="duracion-tag">
                <Clock :size="13" aria-hidden="true" />
                <span>{{ plan.duracionDias }} días</span>
              </div>
            </td>

            <!-- Capacidad -->
            <td class="planes-tabla__capacidad">
              <div class="capacidad-tag">
                <Users :size="13" aria-hidden="true" />
                <span>Hasta {{ plan.limiteUsuarios.toLocaleString('es-PE') }}</span>
              </div>
            </td>

            <!-- Servicios -->
            <td class="planes-tabla__servicios">
              <div class="servicios-lista">
                <span
                  v-for="(servicio, sIdx) in parsearServicios(plan.contenido).slice(0, 3)"
                  :key="sIdx"
                  class="servicio-chip"
                >
                  <Check :size="11" aria-hidden="true" />
                  {{ servicio }}
                </span>
                <span
                  v-if="parsearServicios(plan.contenido).length > 3"
                  class="servicio-chip servicio-chip--mas"
                >
                  +{{ parsearServicios(plan.contenido).length - 3 }} más
                </span>
              </div>
            </td>

            <!-- Estado -->
            <td class="text-center">
              <span
                class="badge-estado"
                :class="plan.activo ? 'badge-estado--activo' : 'badge-estado--inactivo'"
              >
                {{ plan.activo ? 'Disponible' : 'Inactivo' }}
              </span>
            </td>

            <!-- Acciones -->
            <td class="text-end">
              <div class="acciones-celda">
                <a
                  v-if="plan.enlaceWhatsapp"
                  :href="plan.enlaceWhatsapp"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-ghost btn-sm btn-icono-accion"
                  title="Abrir enlace de WhatsApp"
                  aria-label="Abrir enlace de WhatsApp"
                >
                  <ExternalLink :size="15" aria-hidden="true" />
                </a>

                <RouterLink
                  class="btn btn-ghost btn-sm btn-icono-accion"
                  :to="{ name: 'plan-editar', params: { id: plan.id } }"
                  title="Editar plan"
                  aria-label="Editar plan"
                >
                  <Pencil :size="15" aria-hidden="true" />
                </RouterLink>

                <button
                  type="button"
                  class="btn btn-ghost btn-sm btn-icono-accion btn-icono-accion--peligro"
                  title="Eliminar plan"
                  aria-label="Eliminar plan"
                  @click="emit('eliminar', plan)"
                >
                  <Trash2 :size="15" aria-hidden="true" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Paginador -->
    <div v-if="paginacion.total > 0" class="planes-tabla__paginacion">
      <p class="planes-tabla__conteo">
        Mostrando <strong>{{ paginacion.desde }}</strong> a
        <strong>{{ paginacion.hasta }}</strong> de <strong>{{ paginacion.total }}</strong> planes
      </p>

      <div class="planes-tabla__controles">
        <button
          type="button"
          class="btn btn-ghost btn-sm"
          :disabled="paginacion.pagina <= 1 || cargando"
          aria-label="Página anterior"
          @click="emit('cambiarPagina', paginacion.pagina - 1)"
        >
          <ChevronLeft :size="16" aria-hidden="true" />
          <span>Anterior</span>
        </button>

        <span class="planes-tabla__pagina-actual">
          Página {{ paginacion.pagina }} de {{ paginacion.ultimaPagina }}
        </span>

        <button
          type="button"
          class="btn btn-ghost btn-sm"
          :disabled="paginacion.pagina >= paginacion.ultimaPagina || cargando"
          aria-label="Página siguiente"
          @click="emit('cambiarPagina', paginacion.pagina + 1)"
        >
          <span>Siguiente</span>
          <ChevronRight :size="16" aria-hidden="true" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.planes-tabla-contenedor {
  border-radius: var(--gb-radius-lg);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
  overflow: hidden;
}

.planes-tabla {
  margin-bottom: 0;
  width: 100%;
  border-collapse: collapse;
}

.planes-tabla th {
  padding: 0.85rem 1rem;
  font-size: var(--gb-tipo-xs, 0.75rem);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gb-text-soft);
  background-color: var(--gb-surface-high);
  border-bottom: 1px solid var(--gb-border);
  white-space: nowrap;
}

.planes-tabla td {
  padding: 0.85rem 1rem;
  font-size: var(--gb-tipo-sm, 0.875rem);
  vertical-align: middle;
  border-bottom: 1px solid var(--gb-border);
}

.planes-tabla__fila:hover td {
  background-color: rgba(255, 255, 255, 0.02);
}

.plan-header-info {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
}

.plan-icono {
  display: grid;
  place-items: center;
  width: 2.2rem;
  height: 2.2rem;
  border-radius: var(--gb-radius-md);
  background-color: rgba(238, 255, 0, 0.1);
  color: var(--gb-accent);
  flex-shrink: 0;
}

.plan-titulo {
  display: block;
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--gb-text);
}

.plan-desc {
  margin: 0.15rem 0 0;
  font-size: 0.75rem;
  color: var(--gb-text-muted);
  max-width: 22rem;
  line-height: 1.35;
}

.precio-inicial {
  display: block;
  font-weight: 800;
  font-family: monospace;
  font-size: 1rem;
  color: var(--gb-accent);
}

.precio-original {
  display: block;
  font-size: 0.75rem;
  font-family: monospace;
  color: var(--gb-text-muted);
  text-decoration: line-through;
}

.duracion-tag,
.capacidad-tag {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--gb-text-soft);
}

.servicios-lista {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
  max-width: 20rem;
}

.servicio-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.15rem 0.45rem;
  font-size: 0.7rem;
  border-radius: var(--gb-radius-sm);
  background-color: var(--gb-surface-highest);
  color: var(--gb-text-soft);
}

.servicio-chip svg {
  color: var(--gb-green, #22c55e);
}

.servicio-chip--mas {
  font-weight: 700;
  color: var(--gb-text-muted);
}

.badge-estado {
  display: inline-flex;
  align-items: center;
  font-size: 0.75rem;
  font-weight: 700;
  padding: 0.25rem 0.6rem;
  border-radius: var(--gb-radius-full);
}

.badge-estado--activo {
  background-color: rgba(34, 197, 94, 0.15);
  color: var(--gb-green, #22c55e);
}

.badge-estado--inactivo {
  background-color: var(--gb-surface-highest);
  color: var(--gb-text-muted);
}

.acciones-celda {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.btn-icono-accion {
  display: grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  padding: 0;
  border-radius: var(--gb-radius-sm);
}

.btn-icono-accion--peligro:hover {
  color: var(--gb-red);
  background-color: rgba(220, 38, 38, 0.15);
}

.planes-tabla__paginacion {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.85rem 1.25rem;
  background-color: var(--gb-surface-high);
}

.planes-tabla__conteo {
  margin: 0;
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-muted);
}

.planes-tabla__controles {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.planes-tabla__pagina-actual {
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-soft);
}

.planes-tabla__vacio {
  padding: 3.5rem 1rem !important;
  text-align: center;
}

.planes-tabla__vacio-contenido {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.planes-tabla__vacio-icono {
  color: var(--gb-text-muted);
  margin-bottom: 0.5rem;
}

.planes-tabla__vacio h3 {
  font-size: 1rem;
  font-weight: 700;
  margin: 0;
  color: var(--gb-text);
}

.planes-tabla__vacio p {
  font-size: 0.8rem;
  margin: 0;
  color: var(--gb-text-muted);
}

/* Skeletons */
.planes-tabla__skeleton {
  height: 1.25rem;
  border-radius: var(--gb-radius-sm);
  background: linear-gradient(
    90deg,
    var(--gb-surface-high) 25%,
    var(--gb-surface-highest) 50%,
    var(--gb-surface-high) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shine 1.5s infinite;
}

.planes-tabla__skeleton--sm {
  width: 4.5rem;
}
.planes-tabla__skeleton--md {
  width: 7.5rem;
}
.planes-tabla__skeleton--lg {
  width: 12rem;
  height: 2rem;
}
.planes-tabla__skeleton--badge {
  width: 5rem;
  height: 1.4rem;
  border-radius: var(--gb-radius-full);
}
.planes-tabla__skeleton--acciones {
  width: 4.5rem;
  height: 1.8rem;
  border-radius: var(--gb-radius-md);
}

@keyframes skeleton-shine {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
</style>
