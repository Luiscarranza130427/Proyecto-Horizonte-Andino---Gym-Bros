<script setup>
import {
  Building2,
  CheckCircle2,
  CreditCard,
  Download,
  FileText,
  Printer,
  X,
} from 'lucide-vue-next'
import { computed } from 'vue'

const props = defineProps({
  abierto: {
    type: Boolean,
    default: false,
  },
  pago: {
    type: Object,
    default: null,
  },
})

const emit = defineEmits(['cerrar'])

const formatearMonto = (monto) => {
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency: 'PEN',
    minimumFractionDigits: 2,
  }).format(monto || 0)
}

const formatearFecha = (fechaStr) => {
  if (!fechaStr) return '—'
  const [anio, mes, dia] = fechaStr.split('-')
  if (!anio || !mes || !dia) return fechaStr
  const meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ]
  return `${dia} de ${meses[Number(mes) - 1]} de ${anio}`
}

const subtotal = computed(() => {
  if (!props.pago?.precio) return 0
  return props.pago.precio / 1.18
})

const igv = computed(() => {
  if (!props.pago?.precio) return 0
  return props.pago.precio - subtotal.value
})

function imprimir() {
  window.print()
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="abierto && pago"
      class="pago-modal-telon"
      role="dialog"
      aria-modal="true"
      :aria-labelledby="'recibo-titulo'"
      @keydown.esc="emit('cerrar')"
    >
      <div class="pago-modal gb-tarjeta">
        <!-- Cabecera del modal -->
        <div class="pago-modal__cabecera">
          <div class="pago-modal__branding">
            <div class="pago-modal__icono-marca" aria-hidden="true">
              <FileText :size="22" />
            </div>
            <div>
              <h2 id="recibo-titulo" class="pago-modal__titulo">Comprobante de Pago</h2>
              <span class="pago-modal__codigo">{{ pago.codigo }}</span>
            </div>
          </div>

          <button
            type="button"
            class="btn btn-ghost btn-sm pago-modal__btn-cerrar"
            aria-label="Cerrar comprobante"
            @click="emit('cerrar')"
          >
            <X :size="20" aria-hidden="true" />
          </button>
        </div>

        <!-- Cuerpo del recibo -->
        <div class="pago-modal__cuerpo">
          <!-- Banner de estado -->
          <div class="pago-modal__estado-banner">
            <div class="estado-tag">
              <CheckCircle2 :size="16" aria-hidden="true" />
              <span>Pago completado con éxito</span>
            </div>
            <span class="estado-fecha">{{ formatearFecha(pago.fecha) }}</span>
          </div>

          <!-- Datos de la empresa cliente -->
          <div class="pago-modal__seccion-cliente">
            <span class="seccion-label">Facturado a:</span>
            <div class="cliente-tarjeta">
              <div class="cliente-icono" aria-hidden="true">
                <Building2 :size="18" />
              </div>
              <div>
                <h3 class="cliente-nombre">{{ pago.empresa.nombre }}</h3>
                <p class="cliente-ruc">RUC: 20{{ String(pago.empresa.id).padStart(8, '4') }}1</p>
                <p class="cliente-direccion">Lima, Perú · Cliente SaaS Gym Bros</p>
              </div>
            </div>
          </div>

          <!-- Detalle de conceptos -->
          <div class="pago-modal__tabla-contenedor">
            <table class="pago-modal__tabla">
              <thead>
                <tr>
                  <th>Concepto</th>
                  <th class="text-center">Periodo</th>
                  <th class="text-end">Importe</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>
                    <div class="concepto-info">
                      <span class="concepto-nombre"
                        >Suscripción SaaS Plan {{ pago.plan.nombre }}</span
                      >
                      <span class="concepto-desc"
                        >Acceso a plataforma web y panel de administración</span
                      >
                    </div>
                  </td>
                  <td class="text-center">
                    {{ pago.cantidadMeses }} {{ pago.cantidadMeses === 1 ? 'mes' : 'meses' }}
                  </td>
                  <td class="text-end font-monospace">{{ formatearMonto(subtotal) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Resumen de totales -->
          <div class="pago-modal__totales">
            <div class="pago-modal__metodo-pago">
              <span class="seccion-label">Método de pago:</span>
              <div class="metodo-info">
                <CreditCard :size="16" aria-hidden="true" />
                <span>{{ pago.metodoPago }}</span>
              </div>
            </div>

            <div class="pago-modal__desglose">
              <div class="desglose-fila">
                <span>Subtotal</span>
                <span class="font-monospace">{{ formatearMonto(subtotal) }}</span>
              </div>
              <div class="desglose-fila">
                <span>I.G.V. (18%)</span>
                <span class="font-monospace">{{ formatearMonto(igv) }}</span>
              </div>
              <div class="desglose-fila desglose-fila--total">
                <span>Total pagado</span>
                <span class="font-monospace total-resaltado">{{
                  formatearMonto(pago.precio)
                }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Acciones del modal -->
        <div class="pago-modal__acciones">
          <button type="button" class="btn btn-ghost" @click="emit('cerrar')">Cerrar</button>
          <button type="button" class="btn btn-secondary" @click="imprimir">
            <Printer :size="16" aria-hidden="true" />
            <span>Imprimir</span>
          </button>
          <button type="button" class="btn btn-primary" @click="imprimir">
            <Download :size="16" aria-hidden="true" />
            <span>Descargar Recibo</span>
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.pago-modal-telon {
  position: fixed;
  inset: 0;
  z-index: 1050;
  display: grid;
  place-items: center;
  padding: 1.5rem;
  background-color: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(5px);
}

.pago-modal {
  width: min(100%, 38rem);
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  border-radius: var(--gb-radius-xl);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
  box-shadow: var(--gb-sombra-elevada);
  overflow: hidden;
}

.pago-modal__cabecera {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--gb-border);
  background-color: var(--gb-surface-high);
}

.pago-modal__branding {
  display: flex;
  align-items: center;
  gap: 0.85rem;
}

.pago-modal__icono-marca {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--gb-radius-md);
  background-color: rgba(238, 255, 0, 0.15);
  color: var(--gb-accent);
}

.pago-modal__titulo {
  margin: 0;
  font-size: 1.15rem;
  font-weight: 800;
  color: var(--gb-text);
}

.pago-modal__codigo {
  font-family: monospace;
  font-size: 0.8rem;
  color: var(--gb-text-soft);
}

.pago-modal__btn-cerrar {
  padding: 0.4rem;
  border-radius: var(--gb-radius-full);
}

.pago-modal__cuerpo {
  padding: 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.pago-modal__estado-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  border-radius: var(--gb-radius-md);
  background-color: rgba(16, 185, 129, 0.1);
  border: 1px solid rgba(16, 185, 129, 0.2);
}

.estado-tag {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-weight: 700;
  font-size: 0.85rem;
  color: var(--gb-emerald, #10b981);
}

.estado-fecha {
  font-size: 0.75rem;
  color: var(--gb-text-soft);
}

.seccion-label {
  display: block;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gb-text-muted);
  margin-bottom: 0.5rem;
}

.cliente-tarjeta {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 1rem;
  border-radius: var(--gb-radius-md);
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
}

.cliente-icono {
  display: grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  border-radius: var(--gb-radius-sm);
  background-color: var(--gb-surface-highest);
  color: var(--gb-text-soft);
}

.cliente-nombre {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--gb-text);
}

.cliente-ruc,
.cliente-direccion {
  margin: 0.2rem 0 0;
  font-size: 0.75rem;
  color: var(--gb-text-muted);
}

.pago-modal__tabla-contenedor {
  border-radius: var(--gb-radius-md);
  border: 1px solid var(--gb-border);
  overflow: hidden;
}

.pago-modal__tabla {
  width: 100%;
  border-collapse: collapse;
}

.pago-modal__tabla th {
  padding: 0.75rem 1rem;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--gb-text-soft);
  background-color: var(--gb-surface-high);
  border-bottom: 1px solid var(--gb-border);
}

.pago-modal__tabla td {
  padding: 1rem;
  font-size: 0.85rem;
  border-bottom: 1px solid var(--gb-border);
}

.concepto-nombre {
  display: block;
  font-weight: 600;
  color: var(--gb-text);
}

.concepto-desc {
  display: block;
  font-size: 0.75rem;
  color: var(--gb-text-muted);
}

.pago-modal__totales {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 1.5rem;
  padding-top: 0.5rem;
}

.metodo-info {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--gb-text);
}

.pago-modal__desglose {
  min-width: 14rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.desglose-fila {
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
  color: var(--gb-text-soft);
}

.desglose-fila--total {
  padding-top: 0.5rem;
  margin-top: 0.25rem;
  border-top: 1px solid var(--gb-border);
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--gb-text);
}

.total-resaltado {
  font-size: 1.1rem;
  color: var(--gb-accent);
}

.pago-modal__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  border-top: 1px solid var(--gb-border);
  background-color: var(--gb-surface-high);
}

.pago-modal__acciones .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

@media (max-width: 36rem) {
  .pago-modal-telon {
    padding: 0.5rem;
  }

  .pago-modal {
    max-height: 96vh;
    width: 100%;
  }

  .pago-modal__cuerpo {
    padding: 1rem;
  }

  .pago-modal__cabecera {
    padding: 1rem;
  }

  .pago-modal__totales {
    flex-direction: column;
    gap: 1rem;
  }

  .pago-modal__desglose {
    min-width: 100%;
  }

  .pago-modal__acciones {
    flex-direction: column;
    padding: 1rem;
  }

  .pago-modal__acciones .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
