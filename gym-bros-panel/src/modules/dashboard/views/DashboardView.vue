<script setup>
import { AlertTriangle, History, RotateCw } from 'lucide-vue-next'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

import { useAuthStore } from '@/core/auth/auth.store'
import DashboardBanner from '@/modules/dashboard/components/DashboardBanner.vue'
import DashboardSkeleton from '@/modules/dashboard/components/DashboardSkeleton.vue'
import MetricCard from '@/modules/dashboard/components/MetricCard.vue'
import EmpresaForm from '@/modules/empresas/components/EmpresaForm.vue'
import { actualizarEmpresa, obtenerEmpresa } from '@/modules/empresas/services/empresas.service'
import { obtenerBanners, obtenerDashboard } from '@/modules/dashboard/services/dashboard.service'
import { formatearTiempoRelativo } from '@/shared/utils/formato'

const auth = useAuthStore()
const estado = ref('idle')
const datos = ref(null)
const banners = ref([])
const empresa = ref(null)
const identidadEmpresa = ref(null)
const enviandoIdentidad = ref(false)
const erroresIdentidad = ref({})
const mensajeIdentidad = ref('')
const identidadGuardada = ref(false)
const claveIdentidad = ref(0)
const estadoEmpresa = ref('idle')
const enviandoEmpresa = ref(false)
const erroresEmpresa = ref({})
const mensajeEmpresa = ref('')
const claveFormularioEmpresa = ref(0)
const mensajeError = ref('')
const ahora = ref(new Date())
const actualizadoEn = ref(null)
let solicitudActual = 0
let reloj = null

const etiquetaActualizacion = computed(() =>
  actualizadoEn.value ? formatearTiempoRelativo(actualizadoEn.value, ahora.value) : '',
)
const nombreUsuario = computed(() => auth.usuario?.nombre || auth.usuario?.correo || 'Usuario')
const rolUsuario = computed(() => auth.usuario?.rol || 'Usuario')

async function cargarDashboard() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  mensajeError.value = ''
  actualizadoEn.value = null

  try {
    const respuesta = await obtenerDashboard()
    if (idSolicitud !== solicitudActual) return

    datos.value = respuesta
    if (respuesta.empresaId) cargarEmpresa(respuesta.empresaId, idSolicitud)
    actualizadoEn.value = new Date()
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return

    mensajeError.value =
      error?.message || 'No pudimos cargar la información del dashboard. Inténtalo de nuevo.'
    estado.value = 'error'
  }
}

async function cargarEmpresa(idEmpresa, idSolicitud = solicitudActual) {
  estadoEmpresa.value = 'loading'
  mensajeEmpresa.value = ''
  erroresEmpresa.value = {}

  try {
    const respuesta = await obtenerEmpresa(idEmpresa)
    if (idSolicitud !== solicitudActual) return
    empresa.value = respuesta
    identidadEmpresa.value = { ...respuesta }
    estadoEmpresa.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    empresa.value = null
    estadoEmpresa.value = 'error'
    mensajeEmpresa.value = error?.message || 'No pudimos cargar los datos de la empresa.'
  }
}

async function guardarEmpresa(valores) {
  if (!empresa.value || enviandoEmpresa.value) return
  enviandoEmpresa.value = true
  erroresEmpresa.value = {}
  mensajeEmpresa.value = ''

  try {
    const datosAdministrativos = { ...valores }
    delete datosAdministrativos.logoUrl
    delete datosAdministrativos.colorPrimario
    delete datosAdministrativos.colorSecundario
    delete datosAdministrativos.estado
    for (const n of [1, 2, 3]) {
      delete datosAdministrativos[`banner_${n}`]
      delete datosAdministrativos[`link_boton_${n}`]
    }
    empresa.value = await actualizarEmpresa(empresa.value.id, datosAdministrativos)
    claveFormularioEmpresa.value += 1
    mensajeEmpresa.value = 'Datos de la empresa actualizados correctamente.'
  } catch (error) {
    if (error?.status === 422) erroresEmpresa.value = error.errors ?? {}
    mensajeEmpresa.value = error?.message || 'No pudimos actualizar los datos de la empresa.'
  } finally {
    enviandoEmpresa.value = false
  }
}

function restablecerEmpresa() {
  claveFormularioEmpresa.value += 1
  erroresEmpresa.value = {}
  mensajeEmpresa.value = ''
}

async function guardarIdentidad(valores) {
  if (!identidadEmpresa.value || enviandoIdentidad.value) return
  enviandoIdentidad.value = true
  erroresIdentidad.value = {}
  mensajeIdentidad.value = ''
  identidadGuardada.value = false
  try {
    const guardada = await actualizarEmpresa(identidadEmpresa.value.id, valores)
    identidadEmpresa.value = {
      ...identidadEmpresa.value,
      ...valores,
      logoUrl: guardada.logoUrl,
      ...Object.fromEntries([1, 2, 3].map((n) => [`banner_${n}`, guardada[`banner_${n}`]])),
    }
    claveIdentidad.value += 1
    identidadGuardada.value = true
    mensajeIdentidad.value = 'Personalización guardada correctamente.'
  } catch (error) {
    if (error?.status === 422) erroresIdentidad.value = error.errors ?? {}
    mensajeIdentidad.value = error?.message || 'No pudimos guardar la personalización.'
  } finally {
    enviandoIdentidad.value = false
  }
}

function restablecerIdentidad() {
  claveIdentidad.value += 1
  erroresIdentidad.value = {}
  mensajeIdentidad.value = ''
}

async function cargarBanners() {
  try {
    banners.value = await obtenerBanners()
  } catch (error) {
    console.warn('[Gym Bros] No se pudieron cargar los banners del dashboard:', error)
    banners.value = []
  }
}

onMounted(() => {
  cargarBanners()
  cargarDashboard()
  reloj = window.setInterval(() => {
    ahora.value = new Date()
  }, 60_000)
})
onBeforeUnmount(() => {
  solicitudActual += 1
  window.clearInterval(reloj)
})
</script>

<template>
  <section class="dashboard" aria-labelledby="titulo-dashboard">
    <DashboardBanner v-if="banners.length" :banners="banners" />

    <header class="dashboard__contexto">
      <div>
        <p><span aria-hidden="true"></span> Centro de mando</p>
        <h1 id="titulo-dashboard">Resumen general</h1>
        <span>
          Sesión de <strong>{{ nombreUsuario }}</strong> · {{ rolUsuario }}. Supervisa la operación
          de Gym Bros desde un único lugar.
        </span>
      </div>
      <p v-if="estado === 'success'" class="dashboard__actualizacion">
        <History :size="16" aria-hidden="true" />
        Última actualización: {{ etiquetaActualizacion.toLowerCase() }}
      </p>
    </header>

    <DashboardSkeleton v-if="estado === 'idle' || estado === 'loading'" />

    <section
      v-else-if="estado === 'error'"
      class="dashboard__error gb-tarjeta"
      role="alert"
      aria-live="assertive"
    >
      <span class="dashboard__error-icono" aria-hidden="true">
        <AlertTriangle :size="24" aria-hidden="true" />
      </span>
      <h2>No pudimos cargar el dashboard</h2>
      <p>{{ mensajeError }}</p>
      <button type="button" class="btn btn-primary" @click="cargarDashboard">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </section>

    <template v-else-if="estado === 'success' && datos">
      <section class="dashboard__indicadores" aria-labelledby="titulo-indicadores">
        <header class="dashboard__seccion-cabecera">
          <div>
            <h2 id="titulo-indicadores">Indicadores principales</h2>
            <p>Estado consolidado de la plataforma.</p>
          </div>
          <span>Periodo actual</span>
        </header>

        <div v-if="datos.metricas.length" class="dashboard__metricas">
          <MetricCard v-for="metrica in datos.metricas" :key="metrica.id" :metrica="metrica" />
        </div>
        <p v-else class="dashboard__sin-indicadores gb-tarjeta" role="status">
          Aún no hay indicadores disponibles.
        </p>
      </section>

      <section
        v-if="datos.empresaId"
        class="dashboard__empresa dashboard__empresa--datos gb-tarjeta"
        aria-labelledby="titulo-empresa-dashboard"
      >
        <header class="dashboard__seccion-cabecera">
          <div>
            <h2 id="titulo-empresa-dashboard">Datos de la empresa</h2>
            <p>
              Empresa asociada a {{ nombreUsuario
              }}<template v-if="empresa?.nombre">
                : <strong>{{ empresa.nombre }}</strong></template
              >. Actualiza su información administrativa y de contacto.
            </p>
          </div>
        </header>

        <div v-if="estadoEmpresa === 'loading'" class="dashboard__empresa-estado gb-tarjeta">
          <span class="spinner-border" aria-hidden="true"></span>
          <p>Cargando datos de la empresa…</p>
        </div>

        <p v-else-if="estadoEmpresa === 'error'" class="alert alert-danger" role="alert">
          {{ mensajeEmpresa }}
        </p>

        <template v-else-if="estadoEmpresa === 'success' && empresa">
          <p
            v-if="mensajeEmpresa"
            class="alert"
            :class="Object.keys(erroresEmpresa).length ? 'alert-danger' : 'alert-success'"
            role="status"
          >
            {{ mensajeEmpresa }}
          </p>
          <EmpresaForm
            :key="claveFormularioEmpresa"
            class="dashboard__formulario-empresa"
            modo="edit"
            :mostrar-secundarias="false"
            :valores-iniciales="empresa"
            :enviando="enviandoEmpresa"
            :errores-servidor="erroresEmpresa"
            @submit="guardarEmpresa"
            @cancel="restablecerEmpresa"
          />
        </template>
      </section>
      <section
        v-if="estadoEmpresa === 'success' && identidadEmpresa"
        class="dashboard__empresa gb-tarjeta"
        aria-labelledby="titulo-personalizar-empresa"
      >
        <header class="dashboard__seccion-cabecera">
          <div>
            <h2 id="titulo-personalizar-empresa">Personalizar Empresa</h2>
            <p>Personaliza el logo y los colores de tu empresa.</p>
          </div>
        </header>
        <p
          v-if="mensajeIdentidad"
          class="alert"
          :class="identidadGuardada ? 'alert-success' : 'alert-danger'"
          role="status"
        >
          {{ mensajeIdentidad }}
        </p>
        <EmpresaForm
          :key="claveIdentidad"
          class="dashboard__formulario-empresa"
          modo="edit"
          solo-identidad
          :valores-iniciales="identidadEmpresa"
          :enviando="enviandoIdentidad"
          :errores-servidor="erroresIdentidad"
          @submit="guardarIdentidad"
          @cancel="restablecerIdentidad"
        />
      </section>
    </template>
  </section>
</template>

<style scoped>
.dashboard__formulario-empresa {
  --empresa-reduccion-texto: 3px;
  --empresa-aumento-cabecera-botones: 3px;
  --empresa-aumento-dias: 2px;
  --empresa-columnas: 3;
  --empresa-campo-completo: auto;
}

.dashboard__formulario-empresa :deep(.formulario__acciones) {
  position: static;
  z-index: auto;
  background-color: transparent;
  padding-bottom: 0;
  border-top: 0;
}

.dashboard__formulario-empresa :deep(.formulario__acciones::after) {
  content: none;
}

.dashboard__formulario-empresa :deep(.campo__error) {
  font-size: var(--gb-tipo-base);
  line-height: 1.5;
}

.dashboard__formulario-empresa :deep(#titulo-identidad) {
  font-size: var(--gb-tipo-md);
}

.dashboard__formulario-empresa :deep([aria-labelledby='titulo-identidad'] header p) {
  font-size: var(--gb-tipo-xs);
}

.dashboard__formulario-empresa :deep(#ayuda-logo) {
  font-size: calc(var(--gb-tipo-xxs) - 1px);
}

.dashboard {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.dashboard__contexto {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 1.5rem;
  margin-top: 30px;
}

.dashboard__contexto p,
.dashboard__contexto h1,
.dashboard__contexto span {
  margin: 0;
}

.dashboard__contexto > div > p {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.dashboard__contexto > div > p span {
  width: 0.5rem;
  height: 0.5rem;
  background-color: var(--gb-green);
  border-radius: var(--gb-radius-pill);
}

.dashboard__contexto h1 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-xl);
  font-weight: 900;
  line-height: 1.1;
  text-transform: uppercase;
}

.dashboard__contexto > div > span,
.dashboard__actualizacion {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.dashboard__contexto > div > span {
  display: block;
  margin-top: 0.375rem;
}

.dashboard__actualizacion {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  white-space: nowrap;
}

.dashboard__actualizacion :deep(svg) {
  color: var(--gb-text-soft);
}

.dashboard__indicadores {
  display: grid;
  gap: 0.875rem;
}

.dashboard__empresa {
  display: grid;
  gap: 0.875rem;
  min-width: 0;
  padding: var(--gb-gutter, 1.25rem);
  border-radius: var(--gb-radius-xl);
}

.dashboard__empresa--datos {
  margin-top: 40px;
}

.dashboard__empresa > .alert {
  margin: 0;
  font-size: calc(1rem - 3px);
}

.dashboard__empresa-estado {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  min-height: 8rem;
  padding: 1.5rem;
}

.dashboard__empresa-estado p {
  margin: 0;
  color: var(--gb-text-muted);
}

.dashboard__seccion-cabecera {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 1rem;
}

.dashboard__seccion-cabecera h2,
.dashboard__seccion-cabecera p {
  margin: 0;
}

.dashboard__seccion-cabecera h2 {
  font-size: var(--gb-tipo-md);
  font-weight: 800;
  text-transform: uppercase;
}

.dashboard__seccion-cabecera p,
.dashboard__seccion-cabecera > span {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.dashboard__seccion-cabecera p {
  margin-top: 0.25rem;
}

.dashboard__metricas {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr));
  gap: var(--gb-gutter);
}

.dashboard__sin-indicadores {
  margin: 0;
  padding: 1.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  text-align: center;
}

.dashboard__error {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 3rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.dashboard__error-icono {
  display: grid;
  place-items: center;
  width: 3rem;
  height: 3rem;
  background-color: rgba(var(--gb-red-rgb), 0.12);
  border: 1px solid rgba(var(--gb-red-rgb), 0.5);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-error);
  font-size: 1.25rem;
}

.dashboard__error h2 {
  margin: 1rem 0 0;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.dashboard__error p {
  max-width: 32rem;
  margin: 0.5rem 0 1.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-base);
}

.dashboard__error .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding-inline: 1.25rem;
}

@media (max-width: 78rem) {
  .dashboard__metricas {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 52rem) {
  .dashboard__contexto {
    align-items: flex-start;
  }

  .dashboard__actualizacion {
    display: none;
  }
}

@media (max-width: 44rem) {
  .dashboard__metricas {
    grid-template-columns: 1fr;
  }

  .dashboard__seccion-cabecera > span {
    display: none;
  }
}
</style>
