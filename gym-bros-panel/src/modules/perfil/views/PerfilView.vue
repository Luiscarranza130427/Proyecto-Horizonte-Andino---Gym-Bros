<script setup>
import {
  AlertTriangle,
  Building2,
  CheckCircle2,
  Lock,
  RotateCw,
  Sliders,
  User,
} from 'lucide-vue-next'
import { onMounted, ref } from 'vue'

import { useAuthStore } from '@/core/auth/auth.store'
import { useTenantStore } from '@/core/tenant/tenant.store'
import PerfilDatosForm from '@/modules/perfil/components/PerfilDatosForm.vue'
import PerfilEmpresaCard from '@/modules/perfil/components/PerfilEmpresaCard.vue'
import PerfilHeader from '@/modules/perfil/components/PerfilHeader.vue'
import PerfilPreferenciasForm from '@/modules/perfil/components/PerfilPreferenciasForm.vue'
import PerfilSeguridadForm from '@/modules/perfil/components/PerfilSeguridadForm.vue'
import * as perfilService from '@/modules/perfil/services/perfil.service'
import PageHeader from '@/shared/components/PageHeader.vue'

const auth = useAuthStore()
const tenant = useTenantStore()

const PESTANAS = [
  { id: 'datos', etiqueta: 'Datos de la sede', icono: Building2 },
  { id: 'empresa', etiqueta: 'Identidad y horarios', icono: Sliders },
  { id: 'seguridad', etiqueta: 'Seguridad y claves', icono: Lock },
  { id: 'preferencias', etiqueta: 'Preferencias', icono: User },
]

const pestanaActiva = ref('datos')
const cargando = ref(true)
const guardando = ref(false)
const cambiandoClave = ref(false)
const cerrandoSesiones = ref(false)
const errorCarga = ref(null)

const perfil = ref({
  id: null,
  nombre: '',
  nombre_gerente: '',
  gerente: '',
  correo: '',
  telefono: '',
  ruc: '',
  region: '',
  direccion: '',
  enlace_web: '',
  logo: '',
  fotoPerfil: '',
  rol: '',
  rolEtiqueta: '',
  plan: null,
  empresa: null,
  estadisticas: null,
  sesiones: [],
  preferencias: null,
})

const mensajeAviso = ref(null)
const tipoAviso = ref('success')

function mostrarAviso(mensaje, tipo = 'success') {
  mensajeAviso.value = mensaje
  tipoAviso.value = tipo
  setTimeout(() => {
    if (mensajeAviso.value === mensaje) {
      mensajeAviso.value = null
    }
  }, 4500)
}

async function cargarDatos() {
  cargando.value = true
  errorCarga.value = null
  try {
    const data = await perfilService.obtenerPerfil()
    perfil.value = data
  } catch (err) {
    errorCarga.value = err.message || 'No se pudo cargar la información de la empresa.'
  } finally {
    cargando.value = false
  }
}

async function guardarDatosPersonales(datos) {
  guardando.value = true
  try {
    const actualizado = await perfilService.actualizarPerfil({ ...datos, id: perfil.value.id })
    perfil.value = { ...perfil.value, ...actualizado }

    // Sincronizar nombre en auth store para que AppHeader y UserMenu se actualicen
    if (auth.usuario) {
      auth.usuario = {
        ...auth.usuario,
        nombre: actualizado.nombre || auth.usuario.nombre,
      }
    }

    mostrarAviso('Datos de la sede guardados con éxito.', 'success')
  } catch (err) {
    mostrarAviso(err.message || 'Error al guardar la información.', 'danger')
  } finally {
    guardando.value = false
  }
}

async function cambiarClave(datos) {
  cambiandoClave.value = true
  try {
    const res = await perfilService.cambiarContrasena(datos)
    mostrarAviso(res.mensaje || 'Contraseña actualizada correctamente.', 'success')
  } catch (err) {
    mostrarAviso(err.message || 'Error al cambiar contraseña.', 'danger')
  } finally {
    cambiandoClave.value = false
  }
}

async function guardarPreferencias(preferencias) {
  guardando.value = true
  try {
    const res = await perfilService.actualizarPreferencias(preferencias)
    perfil.value.preferencias = res
    mostrarAviso('Preferencias actualizadas correctamente.', 'success')
  } catch (err) {
    mostrarAviso(err.message || 'Error al guardar preferencias.', 'danger')
  } finally {
    guardando.value = false
  }
}

async function cerrarOtrasSesiones() {
  cerrandoSesiones.value = true
  try {
    const res = await perfilService.cerrarOtrasSesiones()
    if (perfil.value.sesiones) {
      perfil.value.sesiones = perfil.value.sesiones.filter((s) => s.esActual)
    }
    mostrarAviso(res.mensaje || 'Se cerraron las demás sesiones activas.', 'success')
  } catch (err) {
    mostrarAviso(err.message || 'Error al cerrar sesiones.', 'danger')
  } finally {
    cerrandoSesiones.value = false
  }
}

async function cambiarFoto({ url }) {
  try {
    const actualizado = await perfilService.actualizarPerfil({
      ...perfil.value,
      logo: url,
      fotoPerfil: url,
    })
    perfil.value = { ...perfil.value, ...actualizado, logo: url, fotoPerfil: url }
    if (auth.usuario) {
      auth.usuario = {
        ...auth.usuario,
        foto: url,
      }
    }
    tenant.fijarTenant({
      ...(tenant.tenant || {}),
      id: perfil.value.id,
      nombre: perfil.value.nombre,
      logo: url,
    })
    mostrarAviso('Logo de la empresa actualizado con éxito.', 'success')
  } catch (err) {
    mostrarAviso(err.message || 'Error al actualizar logo.', 'danger')
  }
}

onMounted(() => {
  cargarDatos()
})
</script>

<template>
  <section class="perfil-vista" aria-labelledby="titulo-perfil">
    <!-- Encabezado de vista -->
    <PageHeader
      categoria="Configuración Corporativa"
      titulo="Perfil del Gimnasio"
      descripcion="Administra la información comercial, fiscal, horarios y accesos de tu sede."
    />

    <!-- Mensaje de aviso / Feedback -->
    <div
      v-if="mensajeAviso"
      class="perfil-aviso"
      :class="`perfil-aviso--${tipoAviso}`"
      role="status"
      aria-live="polite"
    >
      <CheckCircle2 v-if="tipoAviso === 'success'" :size="18" aria-hidden="true" />
      <AlertTriangle v-else :size="18" aria-hidden="true" />
      <span>{{ mensajeAviso }}</span>
    </div>

    <!-- Estado de Error -->
    <div v-if="errorCarga" class="perfil-error gb-tarjeta" role="alert">
      <AlertTriangle :size="32" class="perfil-error__icono" aria-hidden="true" />
      <h2 class="perfil-error__titulo">No se pudo cargar la información</h2>
      <p class="perfil-error__descripcion">{{ errorCarga }}</p>
      <button type="button" class="btn btn-primary" @click="cargarDatos">
        <RotateCw :size="16" aria-hidden="true" />
        <span>Reintentar</span>
      </button>
    </div>

    <!-- Contenido normal -->
    <div v-else class="perfil-contenido">
      <!-- Hero de cabecera de perfil -->
      <div v-if="cargando" class="perfil-hero-skeleton gb-tarjeta">
        <div class="skeleton-avatar"></div>
        <div class="skeleton-lineas">
          <span></span>
          <span></span>
        </div>
      </div>
      <PerfilHeader v-else :perfil="perfil" @cambiar-foto="cambiarFoto" />

      <!-- Navegación por pestañas -->
      <nav class="perfil-tabs" aria-label="Secciones del perfil">
        <button
          v-for="pestana in PESTANAS"
          :key="pestana.id"
          type="button"
          class="perfil-tab"
          :class="{ 'perfil-tab--activa': pestanaActiva === pestana.id }"
          :aria-pressed="pestanaActiva === pestana.id"
          @click="pestanaActiva = pestana.id"
        >
          <component :is="pestana.icono" :size="16" aria-hidden="true" />
          <span>{{ pestana.etiqueta }}</span>
        </button>
      </nav>

      <!-- Panel de la pestaña activa -->
      <div class="perfil-panel">
        <!-- 1. Datos de la Empresa / Sede -->
        <PerfilDatosForm
          v-if="pestanaActiva === 'datos'"
          :perfil="perfil"
          :guardando="guardando"
          @guardar="guardarDatosPersonales"
        />

        <!-- 2. Sede Corporativa, Identidad y Horarios -->
        <PerfilEmpresaCard
          v-else-if="pestanaActiva === 'empresa'"
          :empresa="perfil.empresa || perfil"
        />

        <!-- 3. Seguridad y Contraseña -->
        <PerfilSeguridadForm
          v-else-if="pestanaActiva === 'seguridad'"
          :sesiones="perfil.sesiones"
          :cambiando-clave="cambiandoClave"
          :cerrando-sesiones="cerrandoSesiones"
          @cambiar-clave="cambiarClave"
          @cerrar-otras-sesiones="cerrarOtrasSesiones"
        />

        <!-- 4. Preferencias -->
        <PerfilPreferenciasForm
          v-else-if="pestanaActiva === 'preferencias'"
          :preferencias="perfil.preferencias"
          :guardando="guardando"
          @guardar="guardarPreferencias"
        />
      </div>
    </div>
  </section>
</template>

<style scoped>
.perfil-vista {
  display: grid;
  gap: 1.5rem;
  width: min(100%, 72rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen, 2rem);
}

.perfil-aviso {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1.25rem;
  border-radius: var(--gb-radius-lg);
  font-size: var(--gb-tipo-sm);
  font-weight: 600;
}

.perfil-aviso--success {
  background-color: rgba(34, 197, 94, 0.12);
  border: 1px solid rgba(34, 197, 94, 0.3);
  color: #22c55e;
}

.perfil-aviso--danger {
  background-color: rgba(225, 29, 20, 0.12);
  border: 1px solid rgba(225, 29, 20, 0.3);
  color: var(--gb-error);
}

.perfil-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 3rem 1.5rem;
  gap: 0.75rem;
}

.perfil-error__icono {
  color: var(--gb-error);
}

.perfil-error__titulo {
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  margin: 0;
}

.perfil-error__descripcion {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  max-width: 24rem;
  margin: 0 0 0.5rem;
}

.perfil-contenido {
  display: grid;
  gap: 1.5rem;
}

.perfil-hero-skeleton {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1.75rem;
  border-radius: var(--gb-radius-xl);
}

.skeleton-avatar {
  width: 5.75rem;
  height: 5.75rem;
  border-radius: var(--gb-radius-lg);
  background: linear-gradient(
    90deg,
    var(--gb-surface-high) 25%,
    var(--gb-surface-highest) 50%,
    var(--gb-surface-high) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s infinite;
}

.skeleton-lineas {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  flex: 1;
}

.skeleton-lineas span {
  display: block;
  height: 1.25rem;
  border-radius: var(--gb-radius);
  background: linear-gradient(
    90deg,
    var(--gb-surface-high) 25%,
    var(--gb-surface-highest) 50%,
    var(--gb-surface-high) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s infinite;
}

.skeleton-lineas span:first-child {
  width: 40%;
}

.skeleton-lineas span:last-child {
  width: 60%;
}

@keyframes skeleton-shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

.perfil-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  padding: 0.35rem;
  border-radius: var(--gb-radius-lg);
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
}

.perfil-tab {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.625rem 1.125rem;
  border-radius: var(--gb-radius-md);
  border: 0;
  background-color: transparent;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.perfil-tab:hover {
  color: var(--gb-text);
  background-color: var(--gb-surface-high);
}

.perfil-tab--activa {
  background-color: var(--gb-red);
  color: var(--gb-on-red);
  box-shadow: 0 2px 8px rgba(225, 29, 20, 0.3);
}

.perfil-tab--activa:hover {
  background-color: var(--gb-red-hover);
  color: var(--gb-on-red);
}

.perfil-panel {
  display: block;
}
</style>
