<script setup>
import {
  Building2,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Eye,
  FileText,
  Inbox,
} from 'lucide-vue-next'

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
      porPagina: 10,
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

const emit = defineEmits(['verDetalle', 'cambiarPagina'])

const formatearMonto = (monto) => {
  if (monto == null) return '—'
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency: 'PEN',
    minimumFractionDigits: 2,
  }).format(monto)
}

const formatearFecha = (fechaStr) => {
  if (!fechaStr) return '—'
  const [anio, mes, dia] = fechaStr.split('-')
  if (!anio || !mes || !dia) return fechaStr
  const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
  return `${dia} ${meses[Number(mes) - 1]}. ${anio}`
}
</script>

<template>
  <div class="pagos-tabla-contenedor gb-tarjeta">
    <div class="table-responsive">
      <table class="table pagos-tabla" aria-label="Historial de transacciones y pagos">
        <thead>
          <tr>
            <th scope="col">Comprobante</th>
            <th scope="col">Fecha</th>
            <th scope="col">Empresa</th>
            <th scope="col">Plan Contratado</th>
            <th scope="col" class="text-end">Monto</th>
            <th scope="col">Método</th>
            <th scope="col" class="text-center">Estado</th>
            <th scope="col" class="text-end">Acciones</th>
          </tr>
        </thead>

        <!-- Skeletons en carga -->
        <tbody v-if="cargando">
          <tr v-for="n in 5" :key="`skeleton-${n}`" class="pagos-tabla__skeleton-fila">
            <td><div class="pagos-tabla__skeleton pagos-tabla__skeleton--sm"></div></td>
            <td><div class="pagos-tabla__skeleton pagos-tabla__skeleton--sm"></div></td>
            <td><div class="pagos-tabla__skeleton pagos-tabla__skeleton--md"></div></td>
            <td><div class="pagos-tabla__skeleton pagos-tabla__skeleton--md"></div></td>
            <td><div class="pagos-tabla__skeleton pagos-tabla__skeleton--sm ms-auto"></div></td>
            <td><div class="pagos-tabla__skeleton pagos-tabla__skeleton--sm"></div></td>
            <td class="text-center">
              <div class="pagos-tabla__skeleton pagos-tabla__skeleton--badge mx-auto"></div>
            </td>
            <td class="text-end">
              <div class="pagos-tabla__skeleton pagos-tabla__skeleton--btn ms-auto"></div>
            </td>
          </tr>
        </tbody>

        <!-- Sin resultados -->
        <tbody v-else-if="items.length === 0">
          <tr>
            <td colspan="8" class="pagos-tabla__vacio">
              <div class="pagos-tabla__vacio-contenido">
                <Inbox :size="40" class="pagos-tabla__vacio-icono" aria-hidden="true" />
                <h3>No se encontraron pagos</h3>
                <p>Intenta ajustar los filtros de búsqueda o restablecer la consulta.</p>
              </div>
            </td>
          </tr>
        </tbody>

        <!-- Datos reales -->
        <tbody v-else>
          <tr v-for="pago in items" :key="pago.id" class="pagos-tabla__fila">
            <td class="pagos-tabla__codigo">
              <span class="badge-codigo">
                <FileText :size="13" aria-hidden="true" />
                {{ pago.codigo || '—' }}
              </span>
            </td>
            <td class="pagos-tabla__fecha">{{ formatearFecha(pago.fecha) }}</td>
            <td class="pagos-tabla__empresa">
              <div class="empresa-info">
                <div class="empresa-info__icono" aria-hidden="true">
                  <Building2 :size="14" />
                </div>
                <span class="empresa-info__nombre">{{ pago.empresa.nombre }}</span>
              </div>
            </td>
            <td class="pagos-tabla__plan">
              <span class="plan-nombre">{{ pago.plan.nombre }}</span>
              <span class="plan-meses"
                >({{
                  pago.cantidadMeses == null
                    ? 'Sin información'
                    : `${pago.cantidadMeses} ${pago.cantidadMeses === 1 ? 'mes' : 'meses'}`
                }})</span
              >
            </td>
            <td class="pagos-tabla__monto text-end font-monospace">
              {{ formatearMonto(pago.precio) }}
            </td>
            <td class="pagos-tabla__metodo">{{ pago.metodoPago || '—' }}</td>
            <td class="text-center">
              <span
                class="badge-estado"
                :class="{
                  'badge-estado--completado': ['completado', 'aprobado'].includes(pago.estado),
                }"
              >
                <CheckCircle2 :size="12" aria-hidden="true" />
                {{ pago.estado || 'Sin información' }}
              </span>
            </td>
            <td class="text-end">
              <button
                type="button"
                class="btn btn-ghost btn-sm pagos-tabla__btn-ver"
                title="Ver comprobante de pago"
                aria-label="Ver comprobante de pago"
                @click="emit('verDetalle', pago)"
              >
                <Eye :size="15" aria-hidden="true" />
                <span>Ver</span>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Paginador -->
    <div v-if="paginacion.total > 0" class="pagos-tabla__paginacion">
      <p class="pagos-tabla__conteo">
        Mostrando <strong>{{ paginacion.desde }}</strong> a
        <strong>{{ paginacion.hasta }}</strong> de
        <strong>{{ paginacion.total }}</strong> transacciones
      </p>

      <div class="pagos-tabla__controles">
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

        <span class="pagos-tabla__pagina-actual">
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
.pagos-tabla-contenedor {
  border-radius: var(--gb-radius-lg);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
  overflow: hidden;
}

.pagos-tabla {
  margin-bottom: 0;
  width: 100%;
  border-collapse: collapse;
}

.pagos-tabla th {
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

.pagos-tabla td {
  padding: 0.85rem 1rem;
  font-size: var(--gb-tipo-sm, 0.875rem);
  vertical-align: middle;
  border-bottom: 1px solid var(--gb-border);
}

.pagos-tabla__fila:hover td {
  background-color: rgba(255, 255, 255, 0.02);
}

.badge-codigo {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-family: monospace;
  font-size: 0.8rem;
  padding: 0.2rem 0.5rem;
  border-radius: var(--gb-radius-sm);
  background-color: var(--gb-surface-highest);
  color: var(--gb-text);
}

.empresa-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.empresa-info__icono {
  display: grid;
  place-items: center;
  width: 1.6rem;
  height: 1.6rem;
  border-radius: var(--gb-radius-sm);
  background-color: var(--gb-surface-highest);
  color: var(--gb-text-soft);
}

.empresa-info__nombre {
  font-weight: 600;
  color: var(--gb-text);
}

.plan-nombre {
  font-weight: 600;
}

.plan-meses {
  margin-left: 0.35rem;
  font-size: 0.75rem;
  color: var(--gb-text-muted);
}

.pagos-tabla__monto {
  font-weight: 700;
  color: var(--gb-accent, #eeff00);
}

.badge-estado {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.75rem;
  font-weight: 700;
  padding: 0.25rem 0.6rem;
  border-radius: var(--gb-radius-full);
}

.badge-estado--completado {
  background-color: rgba(16, 185, 129, 0.15);
  color: var(--gb-emerald, #10b981);
}

.pagos-tabla__btn-ver {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.3rem 0.6rem;
  font-size: 0.75rem;
}

.pagos-tabla__paginacion {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.85rem 1.25rem;
  background-color: var(--gb-surface-high);
}

.pagos-tabla__conteo {
  margin: 0;
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-muted);
}

.pagos-tabla__controles {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.pagos-tabla__pagina-actual {
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-soft);
}

.pagos-tabla__vacio {
  padding: 3.5rem 1rem !important;
  text-align: center;
}

.pagos-tabla__vacio-contenido {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.pagos-tabla__vacio-icono {
  color: var(--gb-text-muted);
  margin-bottom: 0.5rem;
}

.pagos-tabla__vacio h3 {
  font-size: 1rem;
  font-weight: 700;
  margin: 0;
  color: var(--gb-text);
}

.pagos-tabla__vacio p {
  font-size: 0.8rem;
  margin: 0;
  color: var(--gb-text-muted);
}

/* Skeletons */
.pagos-tabla__skeleton {
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

.pagos-tabla__skeleton--sm {
  width: 5rem;
}
.pagos-tabla__skeleton--md {
  width: 8rem;
}
.pagos-tabla__skeleton--badge {
  width: 4.5rem;
  height: 1.4rem;
  border-radius: var(--gb-radius-full);
}
.pagos-tabla__skeleton--btn {
  width: 3.5rem;
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
