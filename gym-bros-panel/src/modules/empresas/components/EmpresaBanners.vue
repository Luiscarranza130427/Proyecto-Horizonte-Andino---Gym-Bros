<script setup>
import { Image as ImageIcon, Info, Link2, Trash2 } from 'lucide-vue-next'
import { computed, onBeforeUnmount, ref, watch } from 'vue'

import {
  BANNER_EMPRESA_ALTO,
  BANNER_EMPRESA_ANCHO,
  BANNER_EMPRESA_TAMANO_MAXIMO,
  normalizarBannerEmpresa,
} from '@/shared/utils/bannerEmpresa'
import { esUrlValida } from '@/shared/utils/validaciones'

const props = defineProps({
  /** `[{ numero, imagen, imagenUrl, enlace }]`, tal como lo entrega el servicio. */
  banners: { type: Array, default: () => [] },
  guardando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
})

const emit = defineEmits(['guardar'])

const MEGAS = Math.round(BANNER_EMPRESA_TAMANO_MAXIMO / 1024 / 1024)

const huecoVacio = (numero) => ({ numero, imagen: '', imagenUrl: '', enlace: '' })

const locales = ref([1, 2, 3].map(huecoVacio))
const errores = ref({})
const imagenesFallidas = ref({})
const procesando = ref(0)
const entradasArchivo = new Map()
const vistasPreviasLocales = new Map()

function liberarVistaPrevia(numero) {
  const url = vistasPreviasLocales.get(numero)
  if (url) URL.revokeObjectURL(url)
  vistasPreviasLocales.delete(numero)
}

function liberarVistasPrevias() {
  for (const numero of vistasPreviasLocales.keys()) liberarVistaPrevia(numero)
}

function registrarEntradaArchivo(elemento, numero) {
  if (elemento) entradasArchivo.set(numero, elemento)
  else entradasArchivo.delete(numero)
}

function abrirSelector(numero) {
  if (props.guardando || procesando.value > 0) return
  entradasArchivo.get(numero)?.click()
}

/*
 * `immediate: true`: la ficha monta este componente cuando los banners YA se
 * cargaron, así que sin él el formulario aparecería vacío sobre datos que
 * existen. Es el caso normal, no el excepcional.
 */
watch(
  () => props.banners,
  (valores) => {
    liberarVistasPrevias()
    locales.value = [1, 2, 3].map((numero) => {
      const encontrado = valores?.find((banner) => banner.numero === numero)
      return encontrado ? { ...encontrado } : huecoVacio(numero)
    })
    errores.value = {}
    imagenesFallidas.value = {}
  },
  { immediate: true, deep: true },
)

const hayCambios = computed(() =>
  locales.value.some((banner) => {
    const original =
      props.banners?.find((actual) => actual.numero === banner.numero) ?? huecoVacio(banner.numero)
    return banner.imagen !== original.imagen || banner.enlace !== (original.enlace ?? '')
  }),
)

async function elegirImagen(evento, numero) {
  const archivo = evento.target.files?.[0]
  evento.target.value = ''
  if (!archivo) return

  delete errores.value[`imagen-${numero}`]
  procesando.value += 1

  try {
    const dataUrl = await normalizarBannerEmpresa(archivo)
    liberarVistaPrevia(numero)
    const vistaPrevia = URL.createObjectURL(archivo)
    vistasPreviasLocales.set(numero, vistaPrevia)
    locales.value = locales.value.map((banner) =>
      banner.numero === numero ? { ...banner, imagen: dataUrl, imagenUrl: vistaPrevia } : banner,
    )
    imagenesFallidas.value = { ...imagenesFallidas.value, [numero]: false }
  } catch (error) {
    errores.value = { ...errores.value, [`imagen-${numero}`]: error.message }
  } finally {
    procesando.value -= 1
  }
}

function quitarImagen(numero) {
  liberarVistaPrevia(numero)
  locales.value = locales.value.map((banner) =>
    banner.numero === numero ? { ...banner, imagen: '', imagenUrl: '' } : banner,
  )
  delete errores.value[`imagen-${numero}`]
  imagenesFallidas.value = { ...imagenesFallidas.value, [numero]: false }
}

function marcarImagenFallida(numero) {
  imagenesFallidas.value = { ...imagenesFallidas.value, [numero]: true }
}

function cambiarEnlace(numero, valor) {
  locales.value = locales.value.map((banner) =>
    banner.numero === numero ? { ...banner, enlace: valor } : banner,
  )
  delete errores.value[`enlace-${numero}`]
}

function validar() {
  const encontrados = {}

  locales.value.forEach(({ numero, imagen, enlace }) => {
    const texto = enlace?.trim() ?? ''

    if (texto && !esUrlValida(texto)) {
      encontrados[`enlace-${numero}`] = 'Introduce una URL completa, con http:// o https://'
    }
    // Un botón sin imagen no se ve en el móvil: el enlace no llevaría a ningún
    // sitio pulsable. Es mejor decirlo aquí que dejar un banner invisible.
    if (texto && !imagen) {
      encontrados[`imagen-${numero}`] = 'Añade la imagen o quita el enlace: sin imagen no se ve.'
    }
  })

  errores.value = encontrados
  return Object.keys(encontrados).length === 0
}

function guardar() {
  if (props.guardando || procesando.value > 0) return
  if (!validar()) return
  emit(
    'guardar',
    locales.value.map((banner) => ({ ...banner })),
  )
}

const errorDe = (clave) => errores.value[clave] || props.erroresServidor?.[clave] || ''

onBeforeUnmount(liberarVistasPrevias)
</script>

<template>
  <section class="banners gb-tarjeta" aria-labelledby="titulo-banners">
    <header class="banners__cabecera">
      <span class="banners__icono" aria-hidden="true"><ImageIcon :size="20" /></span>
      <div>
        <h2 id="titulo-banners">Banners de la aplicación móvil</h2>
        <p>Los tres carteles que verán los socios al abrir la app de este gimnasio.</p>
      </div>
    </header>

    <p class="campo__ayuda banners__aviso">
      <Info :size="13" aria-hidden="true" />
      <span>
        PNG, JPG o WebP. Máximo {{ MEGAS }} MB. Se recortan y centran automáticamente a
        <strong>{{ BANNER_EMPRESA_ANCHO }} × {{ BANNER_EMPRESA_ALTO }} px</strong>, que es la medida
        que usa la aplicación móvil.
      </span>
    </p>

    <ul class="banners__lista">
      <li v-for="banner in locales" :key="banner.numero" class="banner">
        <p class="banner__titulo">Banner {{ banner.numero }}</p>

        <div
          class="banner__lienzo"
          :class="{ 'banner__lienzo--vacio': !banner.imagenUrl || imagenesFallidas[banner.numero] }"
        >
          <img
            v-if="banner.imagenUrl && !imagenesFallidas[banner.numero]"
            :src="banner.imagenUrl"
            alt=""
            @error="marcarImagenFallida(banner.numero)"
          />
          <span v-else-if="imagenesFallidas[banner.numero]">Imagen no disponible en storage</span>
          <span v-else>Sin imagen</span>
        </div>

        <div class="banner__acciones">
          <button
            type="button"
            class="btn btn-secondary banner__elegir"
            :disabled="guardando || procesando > 0"
            @click="abrirSelector(banner.numero)"
          >
            {{ banner.imagenUrl ? 'Cambiar' : 'Subir imagen' }}
          </button>
          <input
            :id="`banner-archivo-${banner.numero}`"
            :ref="(elemento) => registrarEntradaArchivo(elemento, banner.numero)"
            class="banner__archivo"
            type="file"
            accept="image/png,image/jpeg,image/webp"
            :disabled="guardando || procesando > 0"
            tabindex="-1"
            @change="(evento) => elegirImagen(evento, banner.numero)"
          />
          <button
            v-if="banner.imagenUrl"
            type="button"
            class="btn btn-ghost banner__quitar"
            :disabled="guardando"
            @click="quitarImagen(banner.numero)"
          >
            <Trash2 :size="15" aria-hidden="true" />
            <span>Quitar</span>
          </button>
        </div>

        <p v-if="errorDe(`imagen-${banner.numero}`)" class="campo__error" role="alert">
          {{ errorDe(`imagen-${banner.numero}`) }}
        </p>

        <label class="form-label" :for="`banner-enlace-${banner.numero}`"> Enlace del botón </label>
        <div class="banner__control">
          <Link2 class="banner__control-icono" :size="15" aria-hidden="true" />
          <input
            :id="`banner-enlace-${banner.numero}`"
            class="form-control"
            :class="{ 'is-invalid': errorDe(`enlace-${banner.numero}`) }"
            type="url"
            inputmode="url"
            placeholder="https://gymbros.pe/promociones"
            :value="banner.enlace"
            :disabled="guardando"
            :aria-invalid="Boolean(errorDe(`enlace-${banner.numero}`))"
            @input="(evento) => cambiarEnlace(banner.numero, evento.target.value)"
          />
        </div>
        <p v-if="errorDe(`enlace-${banner.numero}`)" class="campo__error" role="alert">
          {{ errorDe(`enlace-${banner.numero}`) }}
        </p>
      </li>
    </ul>

    <footer class="banners__pie">
      <p v-if="procesando > 0" class="banners__estado" role="status">Preparando la imagen…</p>
      <button
        type="button"
        class="btn btn-primary"
        :disabled="guardando || procesando > 0 || !hayCambios"
        @click="guardar"
      >
        {{ guardando ? 'Guardando…' : 'Guardar banners' }}
      </button>
    </footer>
  </section>
</template>

<style scoped>
.banners {
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.banners__cabecera {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  margin-bottom: 1rem;
}

.banners__icono {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
}

.banners__cabecera h2 {
  margin: 0;
  font-size: calc(var(--gb-tipo-lg) - 3px);
  text-transform: uppercase;
}

.banners__cabecera p {
  margin: 0.25rem 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.banners__aviso {
  font-size: calc(1rem - 3px);
  display: flex;
  align-items: flex-start;
  gap: 0.4rem;
  margin-bottom: 1.25rem;
}

/*
 * Las columnas tienen tope, no `1fr`.
 *
 * Con `1fr` cada hueco crecía hasta llenar el ancho disponible, y como la vista
 * previa mantiene la proporción 500/380, en cuanto la rejilla se quedaba en una
 * o dos columnas cada marco pasaba de 500 px de alto: tres cajas oscuras y
 * vacías apiladas que, al bajar, se leen como una pantalla en negro. La sección
 * llegó a medir 1524 px.
 */
.banners__lista {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(12rem, 17rem));
  justify-content: start;
  gap: 1.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.banner__titulo {
  margin: 0 0 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

/* 500 × 380: la misma proporción que verá el móvil, para que la vista previa
   no engañe sobre cómo va a quedar el recorte. */
.banner__lienzo {
  display: grid;
  place-items: center;
  aspect-ratio: 500 / 380;
  overflow: hidden;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
}

.banner__lienzo > img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.banner__lienzo--vacio {
  border-style: dashed;
  color: var(--gb-text-soft);
  font-size: var(--gb-tipo-sm);
}

.banner__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 0.75rem 0 0.875rem;
}

.banner__archivo {
  display: none;
}

.banner__elegir {
  margin: 0;
  cursor: pointer;
}

.banner__quitar {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
}

.banner__control {
  position: relative;
}

.banner__control-icono {
  position: absolute;
  top: 50%;
  left: 0.75rem;
  z-index: 1;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
  pointer-events: none;
}

.banner__control .form-control {
  font-size: calc(1rem - 3px);
  padding-left: 2.25rem;
}

.banners__pie {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1.5rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--gb-border);
}

.banners__estado {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}
</style>
