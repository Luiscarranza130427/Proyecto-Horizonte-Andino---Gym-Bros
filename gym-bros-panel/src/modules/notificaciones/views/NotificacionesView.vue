<script setup>
import { AlertTriangle, Bell, CheckCircle2, Clock, History, Plus, Search } from 'lucide-vue-next'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import { useAuthStore } from '@/core/auth/auth.store'
import { ROLES } from '@/core/permissions/roles'
import { useTenantStore } from '@/core/tenant/tenant.store'
import PageHeader from '@/shared/components/PageHeader.vue'
import { TIPOS_NOTIFICACION } from '@/modules/notificaciones/catalogos'
import NotificacionCard from '@/modules/notificaciones/components/NotificacionCard.vue'
import NotificacionForm from '@/modules/notificaciones/components/NotificacionForm.vue'
import {
  crearNotificacion,
  eliminarNotificacion,
  enviarNotificacionAhora,
  obtenerNotificacionesEnviadas,
  obtenerNotificacionesProgramadas,
  obtenerNotificacionesRecibidas,
} from '@/modules/notificaciones/services/notificaciones.service'
import { useDebounce } from '@/shared/composables/useDebounce'
import { formatearNumero } from '@/shared/utils/formato'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const tenant = useTenantStore()
const esAdministrador = computed(() => {
  const rol = String(auth.rol ?? '')
    .trim()
    .toLowerCase()
  return [ROLES.SUPER_ADMIN, ROLES.TENANT_ADMIN, ROLES.ADMIN, 'administrador'].includes(rol)
})
const nombreRemitente = computed(() => {
  if (esAdministrador.value) return 'GYM BROS'
  return tenant.tenant?.nombre || auth.usuario?.nombre || tenant.nombreTenant || 'Mi empresa'
})

const pestanaActiva = ref('recibidas')
const valoresFormulario = ref({})
const enviandoFormulario = ref(false)
const erroresServidor = ref({})

// Programadas
const programadas = ref([])
const cargandoProgramadas = ref(false)
const procesandoAccion = ref(false)

// Enviadas
const enviadas = ref([])
const paginacionEnviadas = ref({ pagina: 1, porPagina: 6, total: 0, ultimaPagina: 1 })
let solicitudEnviadas = 0
const cargandoEnviadas = ref(false)
const filtroTipo = ref('')
const busquedaTexto = ref('')
// Una petición por pausa al teclear, no una por tecla.
const busquedaAplicada = useDebounce(busquedaTexto, 300)

// Recibidas
const recibidas = ref([])
const cargandoRecibidas = ref(false)

// Avisos
const mensajeAviso = ref('')
const tipoAviso = ref('success') // 'success' | 'danger'

// Diálogo de confirmación
const dialogoEliminarAbierto = ref(false)
const notificacionAEliminar = ref(null)

const PESTANAS = [
  { id: 'recibidas', etiqueta: 'Recibidas', icono: Bell },
  { id: 'crear', etiqueta: 'Redactar', icono: Plus },
  { id: 'programadas', etiqueta: 'Programadas', icono: Clock },
  { id: 'enviadas', etiqueta: 'Historial enviadas', icono: History },
]

function cambiarPestana(id) {
  pestanaActiva.value = id
  router.replace({ query: { ...route.query, tab: id } }).catch(() => {})
}

watch(
  () => route.query.tab,
  (tab) => {
    if (tab && ['recibidas', 'crear', 'programadas', 'enviadas'].includes(tab)) {
      pestanaActiva.value = tab
    }
  },
  { immediate: true },
)

let temporizadorAviso = null

function mostrarAviso(texto, tipo = 'success') {
  mensajeAviso.value = texto
  tipoAviso.value = tipo
  clearTimeout(temporizadorAviso)
  temporizadorAviso = setTimeout(() => {
    mensajeAviso.value = ''
  }, 5000)
}

onBeforeUnmount(() => {
  clearTimeout(temporizadorAviso)
  solicitudEnviadas += 1
})

async function cargarRecibidas() {
  cargandoRecibidas.value = true
  try {
    recibidas.value = await obtenerNotificacionesRecibidas()
  } catch (error) {
    mostrarAviso(error?.message || 'No pudimos cargar las notificaciones recibidas.', 'danger')
  } finally {
    cargandoRecibidas.value = false
  }
}

async function cargarProgramadas() {
  cargandoProgramadas.value = true
  try {
    programadas.value = await obtenerNotificacionesProgramadas()
  } catch (error) {
    mostrarAviso(error?.message || 'No pudimos cargar las notificaciones programadas.', 'danger')
  } finally {
    cargandoProgramadas.value = false
  }
}

async function cargarEnviadas(pagina = 1) {
  // Si llega antes la respuesta de un filtro anterior, se descarta: si no, el
  // historial podía quedar mostrando resultados de una búsqueda ya cambiada.
  const idSolicitud = ++solicitudEnviadas
  cargandoEnviadas.value = true
  try {
    const respuesta = await obtenerNotificacionesEnviadas({
      pagina,
      porPagina: 6,
      tipo: filtroTipo.value,
      busqueda: busquedaAplicada.value.trim(),
    })
    if (idSolicitud !== solicitudEnviadas) return
    enviadas.value = respuesta.items
    paginacionEnviadas.value = respuesta.paginacion
  } catch (error) {
    if (idSolicitud !== solicitudEnviadas) return
    mostrarAviso(error?.message || 'No pudimos cargar el historial de notificaciones.', 'danger')
  } finally {
    if (idSolicitud === solicitudEnviadas) cargandoEnviadas.value = false
  }
}

onMounted(() => {
  cargarRecibidas()
  cargarProgramadas()
  cargarEnviadas(1)
})

watch([filtroTipo, busquedaAplicada], () => {
  cargarEnviadas(1)
})

async function guardarNotificacion(datos) {
  if (enviandoFormulario.value) return
  enviandoFormulario.value = true
  erroresServidor.value = {}

  try {
    const creada = await crearNotificacion(datos)
    valoresFormulario.value = {}

    if (creada.enviada) {
      mostrarAviso('Notificación enviada correctamente a los destinatarios.')
      await cargarEnviadas(1)
      cambiarPestana('enviadas')
    } else {
      mostrarAviso('Notificación programada con éxito.')
      await cargarProgramadas()
      cambiarPestana('programadas')
    }
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
    } else {
      mostrarAviso(error?.message || 'No pudimos procesar la notificación.', 'danger')
    }
  } finally {
    enviandoFormulario.value = false
  }
}

async function ejecutarEnviarAhora(id) {
  if (procesandoAccion.value) return
  procesandoAccion.value = true

  try {
    await enviarNotificacionAhora(id)
    mostrarAviso('Notificación enviada inmediatamente.')
    await Promise.all([cargarProgramadas(), cargarEnviadas(1)])
  } catch (error) {
    mostrarAviso(error?.message || 'No se pudo enviar la notificación.', 'danger')
  } finally {
    procesandoAccion.value = false
  }
}

function abrirDialogoEliminar(notificacion) {
  notificacionAEliminar.value = notificacion
  dialogoEliminarAbierto.value = true
}

async function confirmarEliminar() {
  if (!notificacionAEliminar.value) return
  const { id } = notificacionAEliminar.value

  procesandoAccion.value = true
  dialogoEliminarAbierto.value = false

  try {
    await eliminarNotificacion(id)
    mostrarAviso('Notificación cancelada y eliminada.')
    await Promise.all([cargarProgramadas(), cargarEnviadas(paginacionEnviadas.value.pagina || 1)])
  } catch (error) {
    mostrarAviso(error?.message || 'No pudimos eliminar la notificación.', 'danger')
  } finally {
    notificacionAEliminar.value = null
    procesandoAccion.value = false
  }
}

function duplicarNotificacion(notificacion) {
  valoresFormulario.value = {
    tipo: notificacion.tipo,
    titulo: notificacion.titulo,
    mensaje: notificacion.mensaje,
    idEmpresas: notificacion.idEmpresas ? String(notificacion.idEmpresas) : '',
    programar: false,
    fechaEnvio: '',
  }
  cambiarPestana('crear')
  mostrarAviso('Contenido cargado en el formulario de redacción.')
}

const paginasEnviadas = computed(() => {
  const total = paginacionEnviadas.value.ultimaPagina || 1
  const actual = paginacionEnviadas.value.pagina || 1
  if (total <= 5) return Array.from({ length: total }, (_, i) => i + 1)
  let inicio = Math.max(1, actual - 2)
  const fin = Math.min(total, inicio + 4)
  inicio = Math.max(1, fin - 4)
  return Array.from({ length: fin - inicio + 1 }, (_, i) => inicio + i)
})
</script>

<template>
  <section class="notificaciones">
    <PageHeader
      titulo="Notificaciones"
      descripcion="Emite comunicados masivos, gestiona envíos programados y consulta el historial."
      seccion="Notificaciones"
      :ruta-seccion="{ name: 'notificaciones' }"
      etiqueta="Centro de comunicaciones"
    />

    <!-- Alertas y avisos de estado -->
    <div
      v-if="mensajeAviso"
      class="notificaciones__aviso alert"
      :class="tipoAviso === 'danger' ? 'alert-danger' : 'notificaciones__aviso--exito'"
      role="status"
    >
      <component
        :is="tipoAviso === 'danger' ? AlertTriangle : CheckCircle2"
        :size="18"
        aria-hidden="true"
      />
      <span>{{ mensajeAviso }}</span>
    </div>

    <!-- Barra de pestañas -->
    <nav class="notificaciones__tabs" aria-label="Secciones de notificaciones">
      <button
        v-for="pestana in PESTANAS"
        :key="pestana.id"
        type="button"
        class="notificaciones__tab"
        :class="{ 'notificaciones__tab--activa': pestanaActiva === pestana.id }"
        :aria-current="pestanaActiva === pestana.id ? 'true' : null"
        @click="cambiarPestana(pestana.id)"
      >
        <component :is="pestana.icono" :size="16" aria-hidden="true" />
        <span>{{ pestana.etiqueta }}</span>

        <span
          v-if="pestana.id === 'recibidas' && recibidas.length > 0"
          class="notificaciones__tab-badge"
        >
          {{ recibidas.length }}
        </span>

        <span
          v-else-if="pestana.id === 'programadas' && programadas.length > 0"
          class="notificaciones__tab-badge"
        >
          {{ programadas.length }}
        </span>

        <span
          v-else-if="pestana.id === 'enviadas' && paginacionEnviadas.total > 0"
          class="notificaciones__tab-badge notificaciones__tab-badge--muted"
        >
          {{ paginacionEnviadas.total }}
        </span>
      </button>
    </nav>

    <!-- Contenido de las pestañas -->
    <div class="notificaciones__panel-contenido">
      <!-- 1. Pestaña Recibidas -->
      <section v-if="pestanaActiva === 'recibidas'" aria-label="Notificaciones recibidas">
        <div v-if="cargandoRecibidas" class="notificaciones__grid-cards" aria-busy="true">
          <div v-for="i in 3" :key="i" class="notificaciones__skeleton gb-tarjeta">
            <span></span><span></span><span></span>
          </div>
        </div>

        <div v-else-if="recibidas.length > 0" class="notificaciones__grid-cards">
          <NotificacionCard
            v-for="notif in recibidas"
            :key="notif.id"
            :notificacion="notif"
            modo="recibida"
          />
        </div>

        <div v-else class="notificaciones__estado-vacio gb-tarjeta" role="status">
          <span class="notificaciones__icono-vacio" aria-hidden="true">
            <Bell :size="32" />
          </span>
          <h3>No tienes notificaciones recibidas</h3>
          <p>Los avisos dirigidos a ti aparecerán aquí.</p>
        </div>
      </section>

      <!-- 2. Pestaña Crear / Redactar -->
      <section v-else-if="pestanaActiva === 'crear'" aria-label="Redactar nueva notificación">
        <NotificacionForm
          :valores-iniciales="valoresFormulario"
          :enviando="enviandoFormulario"
          :errores-servidor="erroresServidor"
          :es-administrador="esAdministrador"
          :nombre-remitente="nombreRemitente"
          @submit="guardarNotificacion"
          @cancel="valoresFormulario = {}"
        />
      </section>

      <!-- 3. Pestaña Programadas -->
      <section v-else-if="pestanaActiva === 'programadas'" aria-label="Notificaciones programadas">
        <div v-if="cargandoProgramadas" class="notificaciones__grid-cards" aria-busy="true">
          <div v-for="i in 3" :key="i" class="notificaciones__skeleton gb-tarjeta">
            <span></span><span></span><span></span>
          </div>
        </div>

        <div v-else-if="programadas.length > 0" class="notificaciones__grid-cards">
          <NotificacionCard
            v-for="notif in programadas"
            :key="notif.id"
            :notificacion="notif"
            modo="programada"
            :procesando="procesandoAccion"
            @enviar-ahora="ejecutarEnviarAhora"
            @eliminar="abrirDialogoEliminar"
          />
        </div>

        <div v-else class="notificaciones__estado-vacio gb-tarjeta" role="status">
          <span class="notificaciones__icono-vacio" aria-hidden="true">
            <Clock :size="32" />
          </span>
          <h3>No hay notificaciones programadas</h3>
          <p>Todas las comunicaciones han sido enviadas o no hay envíos en cola.</p>
          <button type="button" class="btn btn-primary" @click="cambiarPestana('crear')">
            <Plus :size="16" aria-hidden="true" />
            <span>Crear nueva notificación</span>
          </button>
        </div>
      </section>

      <!-- 4. Pestaña Enviadas (Historial) -->
      <section
        v-else-if="pestanaActiva === 'enviadas'"
        aria-label="Historial de notificaciones enviadas"
      >
        <!-- Toolbar con filtros -->
        <div class="notificaciones__filtros-toolbar gb-tarjeta">
          <div class="notificaciones__filtro-busqueda">
            <span class="notificaciones__icono-busqueda" aria-hidden="true">
              <Search :size="16" />
            </span>
            <label class="visually-hidden" for="busqueda-notif">Buscar en el historial</label>
            <input
              id="busqueda-notif"
              v-model="busquedaTexto"
              type="search"
              maxlength="150"
              class="form-control notificaciones__input-busqueda"
              placeholder="Buscar por título, mensaje o destinatario..."
            />
          </div>

          <div class="notificaciones__filtro-tipo">
            <label class="visually-hidden" for="filtro-tipo-notif">Filtrar por tipo</label>
            <select
              id="filtro-tipo-notif"
              v-model="filtroTipo"
              class="form-select notificaciones__select-tipo"
            >
              <option value="">Todos los tipos</option>
              <option v-for="t in TIPOS_NOTIFICACION" :key="t.valor" :value="t.valor">
                {{ t.etiqueta }}
              </option>
            </select>
          </div>
        </div>

        <div v-if="cargandoEnviadas" class="notificaciones__grid-cards" aria-busy="true">
          <div v-for="i in 3" :key="i" class="notificaciones__skeleton gb-tarjeta">
            <span></span><span></span><span></span>
          </div>
        </div>

        <div v-else-if="enviadas.length > 0" class="notificaciones__grid-cards">
          <NotificacionCard
            v-for="notif in enviadas"
            :key="notif.id"
            :notificacion="notif"
            modo="enviada"
            @duplicar="duplicarNotificacion"
          />

          <!-- Paginación -->
          <footer
            v-if="paginacionEnviadas.ultimaPagina > 1"
            class="notificaciones__paginacion gb-tarjeta"
          >
            <p>
              Página {{ formatearNumero(paginacionEnviadas.pagina) }} de
              {{ formatearNumero(paginacionEnviadas.ultimaPagina) }} ({{
                formatearNumero(paginacionEnviadas.total)
              }}
              notificaciones)
            </p>
            <nav class="notificaciones__paginas" aria-label="Paginación de historial">
              <button
                type="button"
                class="btn btn-ghost btn-sm"
                :disabled="paginacionEnviadas.pagina <= 1"
                @click="cargarEnviadas(paginacionEnviadas.pagina - 1)"
              >
                Anterior
              </button>
              <button
                v-for="p in paginasEnviadas"
                :key="p"
                type="button"
                class="notificaciones__btn-pagina"
                :class="{
                  'notificaciones__btn-pagina--activa': p === paginacionEnviadas.pagina,
                }"
                @click="cargarEnviadas(p)"
              >
                {{ p }}
              </button>
              <button
                type="button"
                class="btn btn-ghost btn-sm"
                :disabled="paginacionEnviadas.pagina >= paginacionEnviadas.ultimaPagina"
                @click="cargarEnviadas(paginacionEnviadas.pagina + 1)"
              >
                Siguiente
              </button>
            </nav>
          </footer>
        </div>

        <div v-else class="notificaciones__estado-vacio gb-tarjeta" role="status">
          <span class="notificaciones__icono-vacio" aria-hidden="true">
            <History :size="32" />
          </span>
          <h3>No se encontraron notificaciones enviadas</h3>
          <p>
            {{
              busquedaTexto || filtroTipo
                ? 'No hay registros que coincidan con los filtros aplicados.'
                : 'Aún no se ha realizado ningún envío.'
            }}
          </p>
        </div>
      </section>
    </div>

    <!-- ConfirmDialog para cancelar y eliminar notificación -->
    <ConfirmDialog
      :abierto="dialogoEliminarAbierto"
      titulo="¿Cancelar notificación programada?"
      :mensaje="`¿Seguro que deseas cancelar '${notificacionAEliminar?.titulo || 'esta notificación'}'? La notificación se eliminará definitivamente de la cola.`"
      etiqueta-confirmar="Sí, cancelar envío"
      :cargando="procesandoAccion"
      @confirmar="confirmarEliminar"
      @cancelar="dialogoEliminarAbierto = false"
    />
  </section>
</template>

<style scoped>
.notificaciones {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 78rem);
  margin: 0 auto;
  padding-bottom: var(--gb-espacio);
}

.notificaciones__aviso {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin: 0;
  padding: 0.875rem 1.25rem;
  border-radius: var(--gb-radius-lg);
  font-size: var(--gb-tipo-sm);
}

.notificaciones__aviso--exito {
  background-color: rgba(var(--gb-green-rgb), 0.12);
  border: 1px solid rgba(var(--gb-green-rgb), 0.32);
  color: var(--gb-green);
}

/* Tabs Bar */
.notificaciones__tabs {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.375rem;
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-xl);
  width: fit-content;
  max-width: 100%;
  overflow-x: auto;
}

.notificaciones__tab {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.625rem 1.125rem;
  background: transparent;
  border: none;
  border-radius: var(--gb-radius-lg);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition:
    background-color 0.18s ease,
    color 0.18s ease;
}

.notificaciones__tab:hover {
  background-color: var(--gb-surface-high);
  color: var(--gb-text);
}

.notificaciones__tab--activa {
  background-color: var(--gb-surface-high);
  color: #ffffff;
  box-shadow: var(--gb-relieve);
}

.notificaciones__tab-badge {
  display: grid;
  place-items: center;
  padding: 0.1rem 0.45rem;
  background-color: var(--gb-red);
  color: var(--gb-on-red);
  border-radius: var(--gb-radius-pill);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
}

.notificaciones__tab-badge--muted {
  background-color: var(--gb-surface-highest);
  color: var(--gb-text);
}

/* Grid de Tarjetas */
.notificaciones__grid-cards {
  display: grid;
  gap: 1rem;
}

/* Toolbar de filtros */
.notificaciones__filtros-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1.25rem;
  border-radius: var(--gb-radius-xl);
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.notificaciones__filtro-busqueda {
  position: relative;
  display: flex;
  align-items: center;
  flex: 1;
  min-width: 15rem;
}

.notificaciones__icono-busqueda {
  position: absolute;
  left: 0.875rem;
  top: 50%;
  transform: translateY(-50%);
  display: grid;
  place-items: center;
  color: var(--gb-text-muted);
  pointer-events: none;
  font-size: 0.9375rem;
  z-index: 2;
}

.notificaciones__input-busqueda {
  width: 100%;
  min-height: 2.75rem;
  padding: 0.5rem 0.875rem 0.5rem 2.5rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  font-size: var(--gb-tipo-sm);
  line-height: 1.5;
  border-radius: var(--gb-radius-lg);
}

.notificaciones__select-tipo {
  min-height: 2.75rem;
  min-width: 14rem;
  padding: 0.5rem 2.25rem 0.5rem 0.875rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  font-size: var(--gb-tipo-sm);
  line-height: 1.5;
  border-radius: var(--gb-radius-lg);
}

/* Estados vacíos */
.notificaciones__estado-vacio {
  display: grid;
  place-items: center;
  text-align: center;
  gap: 0.5rem;
  padding: 3.5rem 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.notificaciones__icono-vacio {
  display: grid;
  place-items: center;
  width: 3.5rem;
  height: 3.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-xl);
  color: var(--gb-text-muted);
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
}

.notificaciones__estado-vacio h3 {
  margin: 0;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
  color: var(--gb-text);
}

.notificaciones__estado-vacio p {
  margin: 0 0 1rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  max-width: 28rem;
}

/* Paginación */
.notificaciones__paginacion {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1.25rem;
  border-radius: var(--gb-radius-xl);
  margin-top: 0.5rem;
  flex-wrap: wrap;
}

.notificaciones__paginacion p {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.notificaciones__paginas {
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.notificaciones__btn-pagina {
  display: grid;
  place-items: center;
  width: 2.125rem;
  height: 2.125rem;
  padding: 0;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-md);
  color: var(--gb-text);
  font-size: var(--gb-tipo-xs);
  cursor: pointer;
  transition:
    background-color 0.15s ease,
    border-color 0.15s ease;
}

.notificaciones__btn-pagina:hover {
  border-color: var(--gb-red);
}

.notificaciones__btn-pagina--activa {
  background-color: var(--gb-red);
  border-color: var(--gb-red);
  color: var(--gb-on-red);
  font-weight: 700;
}

/* Skeleton */
.notificaciones__skeleton {
  display: grid;
  gap: 0.875rem;
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
}

.notificaciones__skeleton span {
  display: block;
  height: 1.25rem;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
  animation: pulso 1.2s ease-in-out infinite alternate;
}

.notificaciones__skeleton span:nth-child(2) {
  height: 3rem;
  border-radius: var(--gb-radius-lg);
}

.notificaciones__skeleton span:nth-child(3) {
  height: 2rem;
  width: 40%;
}

@keyframes pulso {
  to {
    opacity: 0.4;
  }
}

@media (max-width: 48rem) {
  .notificaciones__filtros-toolbar {
    flex-direction: column;
    align-items: stretch;
  }

  .notificaciones__select-tipo {
    min-width: auto;
  }

  .notificaciones__paginacion {
    flex-direction: column;
    align-items: center;
  }
}
</style>
