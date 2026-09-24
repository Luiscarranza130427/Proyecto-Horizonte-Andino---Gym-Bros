<script setup>
import { Download, RotateCw } from 'lucide-vue-next'
import { onMounted, ref } from 'vue'

import PageHeader from '@/shared/components/PageHeader.vue'
import { useListadoFiltrable } from '@/shared/composables/useListadoFiltrable'
import PagosKpis from '@/modules/billing/components/PagosKpis.vue'
import PagosTable from '@/modules/billing/components/PagosTable.vue'
import PagoReceiptModal from '@/modules/billing/components/PagoReceiptModal.vue'
import {
  obtenerMetricasPagos,
  obtenerReportePagos,
} from '@/modules/billing/services/billing.service'

const metricas = ref({
  totalIngresos: 0,
  totalTransacciones: 0,
  moneda: 'PEN',
})
const cargandoMetricas = ref(false)

const pagoSeleccionado = ref(null)
const modalDetalleAbierto = ref(false)

const { estadoVista, items, paginacion, cargarListado, cambiarPagina } = useListadoFiltrable({
  nombreRuta: 'pagos',
  cargar: obtenerReportePagos,
  mensajeDeError: 'No pudimos cargar los reportes de pagos.',
})

async function cargarMetricas() {
  cargandoMetricas.value = true
  try {
    const res = await obtenerMetricasPagos()
    metricas.value = res
  } catch {
    // Si fallan métricas se mantienen en 0
  } finally {
    cargandoMetricas.value = false
  }
}

async function recargarTodo() {
  await Promise.all([cargarListado(), cargarMetricas()])
}

function abrirDetalle(pago) {
  pagoSeleccionado.value = pago
  modalDetalleAbierto.value = true
}

function exportarCsv() {
  if (!items.value.length) return

  const encabezados = [
    'ID',
    'Comprobante',
    'Fecha',
    'Empresa',
    'Plan',
    'Meses',
    'Monto (PEN)',
    'Método',
    'Estado',
  ]
  const filas = items.value.map((p) => [
    p.id,
    p.codigo,
    p.fecha,
    `"${p.empresa.nombre}"`,
    `"${p.plan.nombre}"`,
    p.cantidadMeses,
    p.precio,
    `"${p.metodoPago}"`,
    p.estado,
  ])

  const contenidoCsv = [encabezados.join(','), ...filas.map((f) => f.join(','))].join('\n')
  const blob = new Blob([contenidoCsv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const enlace = document.createElement('a')
  enlace.href = url
  enlace.setAttribute(
    'download',
    `reporte_pagos_gym_bros_${new Date().toISOString().slice(0, 10)}.csv`,
  )
  document.body.appendChild(enlace)
  enlace.click()
  document.body.removeChild(enlace)
  URL.revokeObjectURL(url)
}

onMounted(() => {
  cargarMetricas()
})
</script>

<template>
  <section class="pagos-view">
    <PageHeader
      titulo="Reportes de pagos"
      descripcion="Monitorea la facturación de suscripciones SaaS, transacciones y cobros procesados."
      seccion="Reportes de pagos"
      :ruta-seccion="{ name: 'pagos' }"
      etiqueta="Administración Financiera SaaS"
    >
      <template #acciones>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="estadoVista === 'loading' || cargandoMetricas"
          title="Actualizar datos"
          @click="recargarTodo"
        >
          <RotateCw
            :size="16"
            :class="{ 'icono-girando': estadoVista === 'loading' || cargandoMetricas }"
            aria-hidden="true"
          />
          <span>Actualizar</span>
        </button>

        <button
          type="button"
          class="btn btn-primary"
          :disabled="items.length === 0 || estadoVista === 'loading'"
          title="Exportar listado a archivo CSV"
          @click="exportarCsv"
        >
          <Download :size="16" aria-hidden="true" />
          <span>Exportar CSV</span>
        </button>
      </template>
    </PageHeader>

    <!-- Métricas financieras -->
    <PagosKpis :metricas="metricas" :cargando="cargandoMetricas" />

    <!-- Tabla de transacciones -->
    <PagosTable
      :items="items"
      :paginacion="paginacion"
      :cargando="estadoVista === 'loading'"
      @ver-detalle="abrirDetalle"
      @cambiar-pagina="cambiarPagina"
    />

    <!-- Modal de comprobante / recibo -->
    <PagoReceiptModal
      :abierto="modalDetalleAbierto"
      :pago="pagoSeleccionado"
      @cerrar="modalDetalleAbierto = false"
    />
  </section>
</template>

<style scoped>
.pagos-view {
  display: grid;
  gap: var(--gb-dashboard-gap, 1.5rem);
  width: min(100%, 86rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen, 2rem);
}

.icono-girando {
  animation: girar 1s linear infinite;
}

@keyframes girar {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
