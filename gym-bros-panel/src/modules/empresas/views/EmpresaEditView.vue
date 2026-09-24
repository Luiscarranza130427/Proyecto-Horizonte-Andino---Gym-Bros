<script setup>
import { Building2, CheckCircle2 } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useTenantStore } from '@/core/tenant/tenant.store'
import PageHeader from '@/shared/components/PageHeader.vue'
import EmpresaBanners from '@/modules/empresas/components/EmpresaBanners.vue'
import EmpresaForm from '@/modules/empresas/components/EmpresaForm.vue'
import {
  actualizarEmpresa,
  guardarBannersEmpresa,
  obtenerBannersEmpresa,
  obtenerEmpresa,
} from '@/modules/empresas/services/empresas.service'

const route = useRoute()
const router = useRouter()
const tenant = useTenantStore()
const estado = ref('loading')
const empresa = ref(null)
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')
const banners = ref([])
const estadoBanners = ref('loading')
const guardandoBanners = ref(false)
const mensajeBanners = ref('')
const errorBanners = ref('')
let solicitudActual = 0

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  empresa.value = null
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    const respuesta = await obtenerEmpresa(route.params.id)
    if (idSolicitud !== solicitudActual) return
    empresa.value = respuesta
    estado.value = 'success'
    cargarBanners(respuesta.id, idSolicitud)
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar la empresa.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

async function cargarBanners(idEmpresa, idSolicitud = solicitudActual) {
  estadoBanners.value = 'loading'
  errorBanners.value = ''
  mensajeBanners.value = ''

  try {
    const respuesta = await obtenerBannersEmpresa(idEmpresa)
    if (idSolicitud !== solicitudActual) return
    banners.value = respuesta
    estadoBanners.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    banners.value = []
    estadoBanners.value = 'error'
    errorBanners.value = error?.message || 'No pudimos cargar los banners.'
  }
}

async function guardarBanners(valores) {
  if (!empresa.value || guardandoBanners.value) return
  guardandoBanners.value = true
  mensajeBanners.value = ''
  errorBanners.value = ''

  try {
    banners.value = await guardarBannersEmpresa(empresa.value.id, valores)
    mensajeBanners.value = 'Banners actualizados correctamente.'
  } catch (error) {
    errorBanners.value = error?.message || 'No pudimos guardar los banners.'
  } finally {
    guardandoBanners.value = false
  }
}

function cancelar() {
  router.push({ name: 'empresas-listado' }).catch(() => {})
}

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    const datosEditables = { ...datos }
    delete datosEditables.estado
    const actualizada = await actualizarEmpresa(route.params.id, datosEditables)
    // Si es la empresa de la sesión, el shell refleja nombre, logo y colores.
    tenant.actualizarDesdeEmpresa(actualizada)
    await router.push({
      name: 'empresas-listado',
      query: { notice: 'updated' },
    })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else if (error?.status === 404) {
      empresa.value = null
      mensajeError.value = error?.message || 'La empresa solicitada no existe.'
      estado.value = 'not-found'
    } else mensajeError.value = error?.message || 'No pudimos actualizar la empresa.'
  } finally {
    enviando.value = false
  }
}

watch(() => route.params.id, cargar, { immediate: true })
onBeforeUnmount(() => {
  solicitudActual += 1
})
</script>

<template>
  <section class="empresa-editor">
    <PageHeader
      titulo="Editar empresa"
      :descripcion="
        empresa
          ? `Actualiza la información de ${empresa.nombre}.`
          : 'Actualiza la información de la empresa.'
      "
      seccion="Empresas"
      :ruta-seccion="{ name: 'empresas-listado' }"
      etiqueta="Gestión empresarial"
      :migas="[empresa?.nombre ?? 'Empresa', 'Editar']"
    />

    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section v-if="estado === 'loading'" class="empresa-editor__estado gb-tarjeta" aria-busy="true">
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando información de la empresa…</p>
    </section>

    <EmpresaForm
      v-else-if="estado === 'success' && empresa"
      class="empresa-editor__formulario"
      modo="edit"
      mostrar-plan
      :mostrar-estado="false"
      :valores-iniciales="empresa"
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      @submit="guardar"
      @cancel="cancelar"
    />

    <template v-if="estado === 'success' && empresa">
      <p v-if="mensajeBanners" class="empresa-editor__exito" role="status">
        <CheckCircle2 :size="18" aria-hidden="true" />
        {{ mensajeBanners }}
      </p>
      <p v-if="errorBanners" class="alert alert-danger" role="alert">{{ errorBanners }}</p>

      <EmpresaBanners
        v-if="estadoBanners === 'success'"
        :banners="banners"
        :guardando="guardandoBanners"
        @guardar="guardarBanners"
      />
      <section
        v-else-if="estadoBanners === 'loading'"
        class="empresa-editor__banners-estado gb-tarjeta"
        aria-busy="true"
      >
        <span class="spinner-border" aria-hidden="true"></span>
        <p>Cargando banners de la aplicación móvil…</p>
      </section>
      <section v-else class="empresa-editor__banners-estado gb-tarjeta" role="alert">
        <p>No pudimos cargar los banners de la aplicación móvil.</p>
        <button type="button" class="btn btn-secondary" @click="cargarBanners(empresa.id)">
          Reintentar
        </button>
      </section>
    </template>

    <section
      v-if="estado !== 'loading' && estado !== 'success'"
      class="empresa-editor__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <Building2 :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Empresa no encontrada' : 'No pudimos cargar la empresa' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar">
          Reintentar
        </button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'empresas-listado' }"
          >Volver a empresas</RouterLink
        >
      </div>
    </section>
  </section>
</template>

<style scoped>
.empresa-editor__formulario {
  --empresa-aumento-ayudas-botones: 3px;
  --empresa-reduccion-texto: 3px;
  --empresa-columnas: 3;
  --empresa-campo-completo: auto;
}

.empresa-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}

.empresa-editor .alert {
  margin: 0;
}

.empresa-editor__exito {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin: 0;
  padding: 0.75rem 1rem;
  background-color: rgba(var(--gb-green-rgb), 0.08);
  border: 1px solid rgba(var(--gb-green-rgb), 0.28);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-green);
  font-size: var(--gb-tipo-sm);
}

.empresa-editor__banners-estado {
  display: grid;
  place-items: center;
  gap: 1rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.empresa-editor__banners-estado p {
  margin: 0;
  color: var(--gb-text-muted);
}

.empresa-editor__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.empresa-editor__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.empresa-editor__estado h2,
.empresa-editor__estado p {
  margin: 0;
}

.empresa-editor__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.empresa-editor__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.empresa-editor__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.empresa-editor__estado .btn {
  text-decoration: none;
}
</style>
