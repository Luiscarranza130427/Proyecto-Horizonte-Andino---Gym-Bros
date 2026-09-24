<script setup>
import {
  CheckCircle2,
  CloudOff,
  ImagePlus,
  Pencil,
  Plus,
  RotateCw,
  Trash2,
  X,
} from 'lucide-vue-next'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import {
  actualizarBanner,
  crearBanner,
  eliminarBanner,
  obtenerBanners,
} from '@/modules/banners/services/banners.service'

const banners = ref([])
const estado = ref('idle')
const mensaje = ref('')
const tipoMensaje = ref('success')
const editando = ref(null)
const enviando = ref(false)
const eliminando = ref(false)
const bannerAEliminar = ref(null)
const archivoImagen = ref(null)
const vistaPrevia = ref('')
const errores = ref({})

const formulario = ref(crearFormulario())
const esEdicion = computed(() => Boolean(editando.value))

function crearFormulario(banner = {}) {
  return {
    contenido: banner.contenido ?? '',
    textoBoton: banner.textoBoton ?? '',
    enlaceBoton: banner.enlaceBoton ?? '',
  }
}

function mostrarMensaje(texto, tipo = 'success') {
  mensaje.value = texto
  tipoMensaje.value = tipo
}

async function cargarBanners() {
  estado.value = 'loading'
  try {
    banners.value = await obtenerBanners()
    estado.value = 'success'
  } catch (error) {
    estado.value = 'error'
    mostrarMensaje(error?.message || 'No pudimos cargar los banners.', 'error')
  }
}

function limpiarImagen() {
  if (vistaPrevia.value) URL.revokeObjectURL(vistaPrevia.value)
  vistaPrevia.value = ''
  archivoImagen.value = null
}

function cancelarFormulario() {
  limpiarImagen()
  editando.value = null
  formulario.value = crearFormulario()
  errores.value = {}
}

function prepararCreacion() {
  cancelarFormulario()
  document
    .getElementById('formulario-banner')
    ?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function prepararEdicion(banner) {
  limpiarImagen()
  editando.value = banner
  formulario.value = crearFormulario(banner)
  errores.value = {}
  document
    .getElementById('formulario-banner')
    ?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function cambiarImagen(evento) {
  const [archivo] = evento.target.files ?? []
  if (!archivo) return
  if (
    !['image/jpeg', 'image/png', 'image/webp'].includes(archivo.type) ||
    archivo.size > 5 * 1024 * 1024
  ) {
    errores.value = {
      ...errores.value,
      imagen: ['Usa una imagen JPG, JPEG, PNG o WebP de hasta 5 MB.'],
    }
    evento.target.value = ''
    return
  }
  limpiarImagen()
  archivoImagen.value = archivo
  vistaPrevia.value = URL.createObjectURL(archivo)
  delete errores.value.imagen
}

function validar() {
  const nuevosErrores = {}
  if (!formulario.value.contenido.trim())
    nuevosErrores.contenido = ['Ingresa el contenido del banner.']
  if (!formulario.value.textoBoton.trim())
    nuevosErrores.textoBoton = ['Ingresa el texto del botón.']
  if (!formulario.value.enlaceBoton.trim())
    nuevosErrores.enlaceBoton = ['Ingresa el enlace del botón.']
  if (!esEdicion.value && !(archivoImagen.value instanceof File)) {
    nuevosErrores.imagen = ['Selecciona la imagen del banner.']
  }
  errores.value = nuevosErrores
  return Object.keys(nuevosErrores).length === 0
}

async function guardar() {
  if (enviando.value || !validar()) return
  enviando.value = true
  errores.value = {}
  try {
    const datos = { ...formulario.value, imagen: archivoImagen.value }
    const guardado = esEdicion.value
      ? await actualizarBanner(editando.value.id, datos)
      : await crearBanner(datos)
    banners.value = esEdicion.value
      ? banners.value.map((banner) => (banner.id === guardado.id ? guardado : banner))
      : [...banners.value, guardado]
    mostrarMensaje(
      esEdicion.value ? 'Banner actualizado correctamente.' : 'Banner creado correctamente.',
    )
    cancelarFormulario()
  } catch (error) {
    if (error?.status === 422) errores.value = error.errors ?? {}
    mostrarMensaje(error?.message || 'No pudimos guardar el banner.', 'error')
  } finally {
    enviando.value = false
  }
}

async function confirmarEliminacion() {
  if (!bannerAEliminar.value || eliminando.value) return
  eliminando.value = true
  try {
    const { id } = bannerAEliminar.value
    const respuesta = await eliminarBanner(id)
    banners.value = banners.value.filter((banner) => banner.id !== id)
    bannerAEliminar.value = null
    mostrarMensaje(respuesta?.message || 'Banner eliminado correctamente.')
  } catch (error) {
    mostrarMensaje(error?.message || 'No pudimos eliminar el banner.', 'error')
  } finally {
    eliminando.value = false
  }
}

onMounted(cargarBanners)
onBeforeUnmount(limpiarImagen)
</script>

<template>
  <section class="banners-view">
    <PageHeader
      titulo="Banners"
      descripcion="Administra los banners que se muestran en el dashboard."
      seccion="Banners"
      :ruta-seccion="{ name: 'banners' }"
      etiqueta="Comunicación visual"
    >
      <template #acciones>
        <button type="button" class="btn btn-primary" @click="prepararCreacion">
          <Plus :size="16" aria-hidden="true" />
          Nuevo banner
        </button>
      </template>
    </PageHeader>

    <p
      v-if="mensaje"
      class="banners__mensaje"
      :class="`banners__mensaje--${tipoMensaje}`"
      role="status"
    >
      <CheckCircle2 v-if="tipoMensaje === 'success'" :size="18" aria-hidden="true" />
      {{ mensaje }}
    </p>

    <form
      id="formulario-banner"
      class="banners__formulario gb-tarjeta"
      novalidate
      @submit.prevent="guardar"
    >
      <header>
        <span><ImagePlus :size="20" aria-hidden="true" /></span>
        <div>
          <h2>{{ esEdicion ? 'Editar banner' : 'Crear banner' }}</h2>
          <p>La medida recomendada para la imagen es 1920 × 550 px.</p>
        </div>
      </header>
      <div class="banners__campos">
        <!-- Los máximos son los de la API (StoreBannerRequest): 100, 20 y 300. -->
        <div class="campo campo--completo">
          <label for="banner-contenido">Contenido *</label>
          <textarea
            id="banner-contenido"
            v-model="formulario.contenido"
            class="form-control"
            rows="3"
            maxlength="100"
            :disabled="enviando"
            :aria-invalid="Boolean(errores.contenido)"
            :aria-describedby="errores.contenido ? 'error-banner-contenido' : null"
          />
          <small v-if="errores.contenido" id="error-banner-contenido" class="campo__error">{{
            errores.contenido[0]
          }}</small>
        </div>
        <div class="campo">
          <label for="banner-texto-boton">Texto del botón *</label>
          <input
            id="banner-texto-boton"
            v-model="formulario.textoBoton"
            class="form-control"
            type="text"
            maxlength="20"
            :disabled="enviando"
            :aria-invalid="Boolean(errores.textoBoton)"
            :aria-describedby="errores.textoBoton ? 'error-banner-texto-boton' : null"
          />
          <small v-if="errores.textoBoton" id="error-banner-texto-boton" class="campo__error">{{
            errores.textoBoton[0]
          }}</small>
        </div>
        <div class="campo">
          <label for="banner-enlace-boton">Enlace del botón *</label>
          <input
            id="banner-enlace-boton"
            v-model="formulario.enlaceBoton"
            class="form-control"
            type="text"
            maxlength="300"
            :disabled="enviando"
            :aria-invalid="Boolean(errores.enlaceBoton)"
            :aria-describedby="errores.enlaceBoton ? 'error-banner-enlace-boton' : null"
          />
          <small v-if="errores.enlaceBoton" id="error-banner-enlace-boton" class="campo__error">{{
            errores.enlaceBoton[0]
          }}</small>
        </div>
        <div class="campo campo--completo">
          <label for="banner-imagen">Imagen {{ esEdicion ? '(opcional)' : '*' }}</label>
          <div class="banners__imagen-control">
            <img
              v-if="vistaPrevia || (esEdicion && editando.imagen)"
              :src="vistaPrevia || editando.imagen"
              alt="Vista previa del banner"
            />
            <input
              id="banner-imagen"
              class="form-control"
              type="file"
              accept="image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp"
              :disabled="enviando"
              @change="cambiarImagen"
            />
            <button
              v-if="archivoImagen"
              type="button"
              class="btn btn-ghost"
              :disabled="enviando"
              @click="limpiarImagen"
            >
              Quitar imagen
            </button>
          </div>
          <small>JPG, JPEG, PNG o WebP. Máximo 5 MB. Recomendado: 1920 × 550 px.</small>
          <small v-if="errores.imagen" class="campo__error">{{ errores.imagen[0] }}</small>
        </div>
      </div>
      <footer>
        <button
          v-if="esEdicion"
          type="button"
          class="btn btn-ghost"
          :disabled="enviando"
          @click="cancelarFormulario"
        >
          <X :size="16" /> Cancelar
        </button>
        <button type="submit" class="btn btn-primary" :disabled="enviando">
          {{ enviando ? 'Guardando…' : esEdicion ? 'Guardar cambios' : 'Crear banner' }}
        </button>
      </footer>
    </form>

    <section v-if="estado === 'loading'" class="banners__estado gb-tarjeta" role="status">
      Cargando banners…
    </section>
    <section v-else-if="estado === 'error'" class="banners__estado gb-tarjeta" role="alert">
      <CloudOff :size="40" aria-hidden="true" />
      <p>{{ mensaje }}</p>
      <button type="button" class="btn btn-primary" @click="cargarBanners">
        <RotateCw :size="16" /> Reintentar
      </button>
    </section>
    <section v-else-if="banners.length" class="banners__rejilla" aria-label="Banners actuales">
      <article v-for="banner in banners" :key="banner.id" class="banner-card gb-tarjeta">
        <img :src="banner.imagen" :alt="banner.contenido" />
        <div class="banner-card__contenido">
          <p>{{ banner.contenido }}</p>
          <a :href="banner.enlaceBoton" target="_blank" rel="noopener noreferrer">{{
            banner.textoBoton
          }}</a>
        </div>
        <footer>
          <button type="button" class="btn btn-secondary" @click="prepararEdicion(banner)">
            <Pencil :size="16" /> Editar
          </button>
          <button type="button" class="btn btn-danger" @click="bannerAEliminar = banner">
            <Trash2 :size="16" /> Eliminar
          </button>
        </footer>
      </article>
    </section>
    <section v-else class="banners__estado gb-tarjeta" role="status">
      Aún no hay banners creados.
    </section>

    <ConfirmDialog
      :abierto="Boolean(bannerAEliminar)"
      titulo="¿Eliminar banner?"
      :descripcion="`Se eliminará el banner «${bannerAEliminar?.contenido ?? ''}». El archivo de imagen no será eliminado.`"
      etiqueta-confirmar="Eliminar banner"
      etiqueta-confirmando="Eliminando…"
      :confirmando="eliminando"
      @cancelar="bannerAEliminar = null"
      @confirmar="confirmarEliminacion"
    />
  </section>
</template>

<style scoped>
.banners-view {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}
.banners__mensaje {
  display: flex;
  gap: 0.5rem;
  align-items: center;
  margin: 0;
  padding: 0.75rem 1rem;
  border-radius: var(--gb-radius-lg);
}
.banners__mensaje--success {
  color: var(--gb-green);
  background: rgba(var(--gb-green-rgb), 0.08);
  border: 1px solid rgba(var(--gb-green-rgb), 0.28);
}
.banners__mensaje--error {
  color: var(--gb-error);
  background: rgba(var(--gb-red-rgb), 0.08);
  border: 1px solid rgba(var(--gb-red-rgb), 0.28);
}
.banners__formulario {
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}
.banners__formulario > header {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
  margin-bottom: 1.25rem;
}
.banners__formulario > header > span {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  color: var(--gb-red-text);
  background: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
}
.banners__formulario h2,
.banners__formulario p {
  margin: 0;
}
.banners__formulario h2 {
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}
.banners__formulario header p,
.banners__imagen-control + small {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}
.banners__campos {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}
.campo {
  display: grid;
  gap: 0.375rem;
  min-width: 0;
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
}
.campo--completo {
  grid-column: 1 / -1;
}
.campo__error {
  color: var(--gb-error);
  font-weight: 400;
}
.banners__imagen-control {
  display: grid;
  gap: 0.75rem;
  align-items: center;
  grid-template-columns: minmax(0, 1fr) auto;
}
.banners__imagen-control img {
  grid-column: 1 / -1;
  width: min(100%, 40rem);
  max-height: 16rem;
  border: 1px solid var(--gb-border);
  border-radius: 5px;
  object-fit: cover;
}
.banners__formulario footer,
.banner-card footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 1.25rem;
}
.banners__estado {
  display: grid;
  place-items: center;
  gap: 1rem;
  min-height: 12rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}
.banners__estado p {
  margin: 0;
  color: var(--gb-text-muted);
}
.banners__rejilla {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
  gap: var(--gb-gutter);
}
.banner-card {
  overflow: hidden;
  border-radius: var(--gb-radius-xl);
}
.banner-card > img {
  display: block;
  width: 100%;
  aspect-ratio: 1920 / 550;
  object-fit: cover;
}
.banner-card__contenido {
  padding: 1rem 1rem 0;
}
.banner-card__contenido p {
  min-height: 2.6rem;
  margin: 0;
  font-weight: 700;
}
.banner-card__contenido a {
  display: inline-block;
  margin-top: 0.5rem;
  color: var(--gb-red-text);
}
.banner-card footer {
  padding: 0 1rem 1rem;
}
@media (max-width: 48rem) {
  .banners__campos {
    grid-template-columns: 1fr;
  }
  .campo--completo {
    grid-column: auto;
  }
  .banners__imagen-control {
    grid-template-columns: 1fr;
  }
  .banners__formulario footer,
  .banner-card footer {
    flex-direction: column;
  }
  .banners__formulario footer .btn,
  .banner-card footer .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
