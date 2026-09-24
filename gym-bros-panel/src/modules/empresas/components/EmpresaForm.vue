<script setup>
import {
  Building2,
  ChevronDown,
  Clock3,
  Image as ImageIcon,
  Link2,
  Palette,
  Power,
} from 'lucide-vue-next'
import { computed, onMounted, ref, useTemplateRef, watch } from 'vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import { obtenerPlanesAsignables } from '@/modules/empresas/services/empresas.service'

import { useFormulario } from '@/shared/composables/useFormulario'
import { useVistaPreviaArchivo } from '@/shared/composables/useVistaPreviaArchivo'
import { REGIONES_PERU } from '@/shared/constants/regionesPeru'
import { normalizarLogoEmpresa } from '@/shared/utils/logoEmpresa'
import { normalizarBannerEmpresa } from '@/shared/utils/bannerEmpresa'
import { resolverUrlStorage } from '@/shared/utils/storage'
import {
  esColorValido,
  esCorreoValido,
  esTelefonoConLimite,
  esUrlValida,
  limpiarTelefono,
} from '@/shared/utils/validaciones'

const props = defineProps({
  valoresIniciales: { type: Object, default: () => ({}) },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
  modo: { type: String, default: 'create' },
  mostrarSecundarias: { type: Boolean, default: true },
  mostrarEstado: { type: Boolean, default: true },
  soloIdentidad: { type: Boolean, default: false },
  mostrarPlan: { type: Boolean, default: false },
})

const emit = defineEmits(['submit', 'cancel'])
const planes = ref([])
const planSeleccionado = ref('')
const cargandoPlanes = ref(false)
const errorPlanes = ref('')
const pendientePlan = ref(null)
async function cargarPlanes() {
  if (cargandoPlanes.value) return
  cargandoPlanes.value = true
  errorPlanes.value = ''
  try {
    planes.value = await obtenerPlanesAsignables()
  } catch (error) {
    errorPlanes.value = error?.message || 'No pudimos cargar los planes.'
  } finally {
    cargandoPlanes.value = false
  }
}
onMounted(() => {
  if (props.mostrarPlan) cargarPlanes()
})
function confirmarPlan() {
  if (!pendientePlan.value || props.enviando) return
  const datos = pendientePlan.value
  pendientePlan.value = null
  emit('submit', datos)
}

const DIAS = [
  { valor: 'lunes', etiqueta: 'Lunes' },
  { valor: 'martes', etiqueta: 'Martes' },
  { valor: 'miercoles', etiqueta: 'Miércoles' },
  { valor: 'jueves', etiqueta: 'Jueves' },
  { valor: 'viernes', etiqueta: 'Viernes' },
  { valor: 'sabado', etiqueta: 'Sábado' },
  { valor: 'domingo', etiqueta: 'Domingo' },
]

const MODELO_HORARIOS = Object.fromEntries(
  DIAS.flatMap(({ valor }) => [
    [`horario_inicio_${valor}`, ''],
    [`horario_fin_${valor}`, ''],
  ]),
)

const MODELO_VACIO = {
  ...Object.fromEntries(
    [1, 2, 3].flatMap((n) => [
      [`banner_${n}`, ''],
      [`link_boton_${n}`, ''],
    ]),
  ),
  nombre: '',
  gerente: '',
  ruc: '',
  correo: '',
  telefono: '',
  region: '',
  direccion: '',
  sitioWeb: '',
  estado: 'active',
  logoUrl: '',
  colorPrimario: '#e50914',
  colorSecundario: '#1c1b1b',
  ...MODELO_HORARIOS,
}

const nombreInput = useTemplateRef('nombreInput')
const gerenteInput = useTemplateRef('gerenteInput')
const correoInput = useTemplateRef('correoInput')
const telefonoInput = useTemplateRef('telefonoInput')
const rucInput = useTemplateRef('rucInput')
const sitioWebInput = useTemplateRef('sitioWebInput')
const regionInput = useTemplateRef('regionInput')
const direccionInput = useTemplateRef('direccionInput')
const logoInput = useTemplateRef('logoInput')
const colorPrimarioInput = useTemplateRef('colorPrimarioInput')
const colorSecundarioInput = useTemplateRef('colorSecundarioInput')
const estadoInput = useTemplateRef('estadoInput')
const primerHorarioInput = ref(null)

function registrarPrimerHorario(elemento, indice) {
  if (indice === 0) primerHorarioInput.value = elemento
}

const logo = useVistaPreviaArchivo({ etiqueta: 'logo', procesarImagen: normalizarLogoEmpresa })
const { error: errorLogo, procesando: procesandoLogo } = logo
const logoImagenFallida = ref(false)
const logoRenderUrl = computed(() => logo.url.value || '')
const mensajeHorarios = ref('')
const procesandoBanners = ref(0)
const erroresBanners = ref({})
async function seleccionarBanner(evento, numero) {
  const archivo = evento.target.files?.[0]
  if (!archivo) return
  procesandoBanners.value += 1
  delete erroresBanners.value[numero]
  limpiarError(`banner_${numero}`)
  try {
    formulario[`banner_${numero}`] = await normalizarBannerEmpresa(archivo)
  } catch (error) {
    erroresBanners.value[numero] = error.message
  } finally {
    evento.target.value = ''
    procesandoBanners.value -= 1
  }
}
const horariosDesplegable = useTemplateRef('horariosDesplegable')

/** Reglas propias de una empresa. Las de forma salen de `utils/validaciones`. */
function validar(datos, errores) {
  if (props.soloIdentidad || props.modo === 'create') {
    for (const n of [1, 2, 3]) {
      if (erroresBanners.value[n]) errores[`banner_${n}`] = erroresBanners.value[n]
      if (procesandoBanners.value)
        errores[`banner_${n}`] = 'Espera a que termine de procesarse la imagen.'
      if (!datos[`banner_${n}`].startsWith('data:image/') && datos[`banner_${n}`].length > 300)
        errores[`banner_${n}`] = 'La ruta admite hasta 300 caracteres.'
      const enlace = datos[`link_boton_${n}`].trim()
      if (enlace && (!esUrlValida(enlace) || enlace.length > 200))
        errores[`link_boton_${n}`] = 'Introduce una URL válida de hasta 200 caracteres.'
    }
    if (!esColorValido(datos.colorPrimario))
      errores.colorPrimario = 'Introduce un color hexadecimal válido.'
    if (!esColorValido(datos.colorSecundario))
      errores.colorSecundario = 'Introduce un color hexadecimal válido.'
    if (logo.error.value) errores.logoUrl = logo.error.value
    if (logo.procesando.value) errores.logoUrl = 'Espera a que termine de procesarse el logo.'
    if (props.soloIdentidad) return
  }
  const nombre = datos.nombre.trim()
  if (nombre.length < 3) errores.nombre = 'Introduce un nombre de al menos 3 caracteres.'
  else if (nombre.length > 80) errores.nombre = 'El nombre no puede superar 80 caracteres.'

  if (datos.gerente.trim().length < 3) errores.gerente = 'Introduce el nombre del gerente.'
  if (!esCorreoValido(datos.correo)) errores.correo = 'Introduce un correo válido.'
  // `empresas.telefono` es varchar(9): con más dígitos la API respondía 422.
  if (!esTelefonoConLimite(datos.telefono, 9)) {
    errores.telefono = 'Introduce un teléfono de 6 a 9 dígitos.'
  }

  if (datos.sitioWeb && !esUrlValida(datos.sitioWeb)) {
    errores.sitioWeb = 'Introduce una URL completa que empiece por http:// o https://.'
  }

  if (!esColorValido(datos.colorPrimario)) {
    errores.colorPrimario = 'Introduce un color hexadecimal válido.'
  }
  if (!esColorValido(datos.colorSecundario)) {
    errores.colorSecundario = 'Introduce un color hexadecimal válido.'
  }

  for (const { valor, etiqueta } of DIAS) {
    const inicio = datos[`horario_inicio_${valor}`]
    const fin = datos[`horario_fin_${valor}`]
    if (!inicio || !fin) {
      errores.horarios = `Completa el horario de ${etiqueta.toLowerCase()}.`
      break
    }
    if (inicio >= fin) {
      errores.horarios = `En ${etiqueta}, la hora de cierre debe ser posterior a la apertura.`
      break
    }
  }
}

const { formulario, erroresLocales, erroresRemotos, errorDe, limpiarError, validarParaEnviar } =
  useFormulario({
    modeloVacio: MODELO_VACIO,
    valoresIniciales: () => props.valoresIniciales,
    erroresServidor: () => props.erroresServidor,
    referencias: {
      nombre: nombreInput,
      gerente: gerenteInput,
      correo: correoInput,
      telefono: telefonoInput,
      ruc: rucInput,
      sitioWeb: sitioWebInput,
      region: regionInput,
      direccion: direccionInput,
      logoUrl: logoInput,
      colorPrimario: colorPrimarioInput,
      colorSecundario: colorSecundarioInput,
      estado: estadoInput,
      horarios: primerHorarioInput,
    },
    validar,
    alCargarValores: (_datos, valores) =>
      (() => {
        logoImagenFallida.value = false
        logo.reiniciar(valores.logoUrl || '')
      })(),
  })

const horarioLunesCompleto = computed(
  () => Boolean(formulario.horario_inicio_lunes) && Boolean(formulario.horario_fin_lunes),
)

watch(
  () => errorDe('horarios'),
  (error) => {
    if (error && horariosDesplegable.value) horariosDesplegable.value.open = true
  },
  { flush: 'sync' },
)

function copiarHorarioLunes() {
  if (!horarioLunesCompleto.value) return

  for (const { valor } of DIAS.slice(1)) {
    formulario[`horario_inicio_${valor}`] = formulario.horario_inicio_lunes
    formulario[`horario_fin_${valor}`] = formulario.horario_fin_lunes
  }
  limpiarError('horarios')
  mensajeHorarios.value = 'Horario del lunes aplicado de martes a domingo.'
}

async function enviar() {
  if (props.enviando) return
  if (!(await validarParaEnviar())) return

  if (props.soloIdentidad) {
    emit('submit', {
      ...Object.fromEntries(
        [1, 2, 3].flatMap((n) => [
          [`banner_${n}`, formulario[`banner_${n}`].trim() || null],
          [`link_boton_${n}`, formulario[`link_boton_${n}`].trim() || null],
        ]),
      ),
      logoUrl: formulario.logoUrl,
      colorPrimario: formulario.colorPrimario,
      colorSecundario: formulario.colorSecundario,
    })
    return
  }

  const datos = {
    ...formulario,
    ...(props.mostrarPlan && planSeleccionado.value !== ''
      ? { id_planes: planSeleccionado.value }
      : {}),
    nombre: formulario.nombre.trim(),
    gerente: formulario.gerente.trim(),
    ruc: formulario.ruc.trim(),
    correo: formulario.correo.trim().toLowerCase(),
    telefono: limpiarTelefono(formulario.telefono),
    direccion: formulario.direccion.trim(),
    sitioWeb: formulario.sitioWeb.trim(),
  }
  if (props.modo === 'edit' && datos.id_planes !== undefined) pendientePlan.value = datos
  else emit('submit', datos)
}

async function seleccionarLogo(evento) {
  limpiarError('logoUrl')
  await logo.seleccionar(evento, formulario.logoUrl)
  if (!logo.error.value) formulario.logoUrl = logo.url.value
}
</script>

<template>
  <form class="formulario" autocomplete="off" novalidate @submit.prevent="enviar">
    <p class="visually-hidden" aria-live="polite">
      {{
        Object.keys(erroresRemotos).length || Object.keys(erroresLocales).length
          ? 'Revisa los campos marcados en el formulario.'
          : ''
      }}
    </p>
    <section
      v-if="!soloIdentidad"
      class="formulario__seccion gb-tarjeta"
      aria-labelledby="titulo-informacion"
    >
      <header>
        <span aria-hidden="true"><Building2 :size="20" /></span>
        <div>
          <h2 id="titulo-informacion">Información principal</h2>
          <p>Datos administrativos y de contacto de la empresa.</p>
        </div>
      </header>

      <div class="formulario__rejilla">
        <div v-if="mostrarPlan" class="campo">
          <label class="form-label" for="empresa-plan">Plan (opcional)</label>
          <select
            id="empresa-plan"
            v-model="planSeleccionado"
            class="form-select"
            :disabled="cargandoPlanes || enviando"
            :aria-invalid="Boolean(errorDe('id_planes'))"
            :aria-describedby="errorDe('id_planes') ? 'error-plan' : null"
            @change="limpiarError('id_planes')"
          >
            <option value="">
              {{ modo === 'create' ? 'Sin asignar plan' : 'Mantener suscripción actual' }}
            </option>
            <option v-for="plan in planes" :key="plan.id" :value="plan.id">
              {{ plan.nombre }}
            </option>
          </select>
          <p v-if="errorDe('id_planes')" id="error-plan" class="campo__error">
            {{ errorDe('id_planes') }}
          </p>
          <p v-if="cargandoPlanes" role="status">Cargando planes…</p>
          <div v-if="errorPlanes" role="alert">
            <p class="campo__error">{{ errorPlanes }} Puedes guardar sin asignar un plan.</p>
            <button
              class="btn btn-secondary"
              type="button"
              :disabled="cargandoPlanes || enviando"
              @click="cargarPlanes"
            >
              Reintentar
            </button>
          </div>
        </div>
        <div class="campo">
          <label class="form-label" for="empresa-nombre">Nombre de empresa *</label>
          <input
            id="empresa-nombre"
            ref="nombreInput"
            v-model="formulario.nombre"
            class="form-control"
            :class="{ 'is-invalid': errorDe('nombre') }"
            type="text"
            name="nombre"
            maxlength="80"
            autocomplete="organization"
            required
            :aria-invalid="Boolean(errorDe('nombre'))"
            :aria-describedby="errorDe('nombre') ? 'error-nombre' : null"
            @input="limpiarError('nombre')"
          />
          <p v-if="errorDe('nombre')" id="error-nombre" class="campo__error">
            {{ errorDe('nombre') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="empresa-gerente">Nombre del gerente *</label>
          <input
            id="empresa-gerente"
            ref="gerenteInput"
            v-model="formulario.gerente"
            class="form-control"
            :class="{ 'is-invalid': errorDe('gerente') }"
            type="text"
            name="gerente"
            autocomplete="name"
            required
            :aria-invalid="Boolean(errorDe('gerente'))"
            :aria-describedby="errorDe('gerente') ? 'error-gerente' : null"
            @input="limpiarError('gerente')"
          />
          <p v-if="errorDe('gerente')" id="error-gerente" class="campo__error">
            {{ errorDe('gerente') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="empresa-correo">Correo *</label>
          <input
            id="empresa-correo"
            ref="correoInput"
            v-model="formulario.correo"
            class="form-control"
            :class="{ 'is-invalid': errorDe('correo') }"
            type="email"
            name="correo"
            autocomplete="off"
            spellcheck="false"
            required
            :aria-invalid="Boolean(errorDe('correo'))"
            :aria-describedby="errorDe('correo') ? 'error-correo' : null"
            @input="limpiarError('correo')"
          />
          <p v-if="errorDe('correo')" id="error-correo" class="campo__error">
            {{ errorDe('correo') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="empresa-telefono">Teléfono *</label>
          <input
            id="empresa-telefono"
            ref="telefonoInput"
            v-model="formulario.telefono"
            class="form-control"
            :class="{ 'is-invalid': errorDe('telefono') }"
            type="tel"
            name="telefono"
            autocomplete="tel"
            required
            :aria-invalid="Boolean(errorDe('telefono'))"
            :aria-describedby="errorDe('telefono') ? 'error-telefono' : null"
            @input="limpiarError('telefono')"
          />
          <p v-if="errorDe('telefono')" id="error-telefono" class="campo__error">
            {{ errorDe('telefono') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="empresa-ruc">RUC</label>
          <input
            id="empresa-ruc"
            ref="rucInput"
            v-model="formulario.ruc"
            class="form-control"
            :class="{ 'is-invalid': errorDe('ruc') }"
            type="text"
            name="ruc"
            maxlength="12"
            :aria-invalid="Boolean(errorDe('ruc'))"
            :aria-describedby="errorDe('ruc') ? 'error-ruc' : null"
            @input="limpiarError('ruc')"
          />
          <p v-if="errorDe('ruc')" id="error-ruc" class="campo__error">{{ errorDe('ruc') }}</p>
        </div>

        <div class="campo">
          <label class="form-label" for="empresa-region">Región</label>
          <select
            id="empresa-region"
            ref="regionInput"
            v-model="formulario.region"
            class="form-select"
            :class="{ 'is-invalid': errorDe('region') }"
            name="region"
            :aria-invalid="Boolean(errorDe('region'))"
            :aria-describedby="errorDe('region') ? 'error-region' : null"
            @change="limpiarError('region')"
          >
            <option value="">Selecciona una región</option>
            <option v-for="region in REGIONES_PERU" :key="region.valor" :value="region.valor">
              {{ region.etiqueta }}
            </option>
          </select>
          <p v-if="errorDe('region')" id="error-region" class="campo__error">
            {{ errorDe('region') }}
          </p>
        </div>

        <div class="campo campo--completo">
          <label class="form-label" for="empresa-direccion">Dirección</label>
          <textarea
            id="empresa-direccion"
            ref="direccionInput"
            v-model="formulario.direccion"
            class="form-control"
            :class="{ 'is-invalid': errorDe('direccion') }"
            name="direccion"
            rows="2"
            autocomplete="street-address"
            :aria-invalid="Boolean(errorDe('direccion'))"
            :aria-describedby="errorDe('direccion') ? 'error-direccion' : null"
            @input="limpiarError('direccion')"
          ></textarea>
          <p v-if="errorDe('direccion')" id="error-direccion" class="campo__error">
            {{ errorDe('direccion') }}
          </p>
        </div>

        <div class="campo campo--completo">
          <label class="form-label" for="empresa-web">Sitio web</label>
          <input
            id="empresa-web"
            ref="sitioWebInput"
            v-model="formulario.sitioWeb"
            class="form-control"
            :class="{ 'is-invalid': errorDe('sitioWeb') }"
            type="url"
            name="sitioWeb"
            placeholder="https://empresa.test"
            autocomplete="url"
            :aria-invalid="Boolean(errorDe('sitioWeb'))"
            :aria-describedby="errorDe('sitioWeb') ? 'error-sitio-web' : null"
            @input="limpiarError('sitioWeb')"
          />
          <p v-if="errorDe('sitioWeb')" id="error-sitio-web" class="campo__error">
            {{ errorDe('sitioWeb') }}
          </p>
        </div>
      </div>
    </section>

    <details
      v-if="!soloIdentidad"
      ref="horariosDesplegable"
      class="formulario__seccion gb-tarjeta horarios-desplegable"
    >
      <summary>Horarios de atención</summary>
      <header class="horarios-encabezado">
        <span aria-hidden="true"><Clock3 :size="20" /></span>
        <div class="horarios-encabezado__texto">
          <h2 id="titulo-horarios">Horarios de atención</h2>
          <p>Configura la apertura y el cierre que utilizará la aplicación móvil.</p>
        </div>
        <button
          type="button"
          class="btn btn-secondary btn-sm horarios-encabezado__accion"
          :disabled="!horarioLunesCompleto || enviando"
          @click="copiarHorarioLunes"
        >
          Copiar lunes al resto
        </button>
      </header>

      <div class="horarios" :class="{ 'horarios--invalidos': errorDe('horarios') }">
        <div class="horarios__cabecera" aria-hidden="true">
          <span>Día</span>
          <span>Apertura</span>
          <span>Cierre</span>
        </div>
        <div v-for="(dia, indice) in DIAS" :key="dia.valor" class="horario">
          <strong>{{ dia.etiqueta }}</strong>
          <div class="campo">
            <label class="visually-hidden" :for="`horario-inicio-${dia.valor}`">
              Apertura del {{ dia.etiqueta.toLowerCase() }}
            </label>
            <input
              :id="`horario-inicio-${dia.valor}`"
              :ref="(elemento) => registrarPrimerHorario(elemento, indice)"
              v-model="formulario[`horario_inicio_${dia.valor}`]"
              class="form-control"
              type="time"
              :name="`horario_inicio_${dia.valor}`"
              required
              :aria-invalid="Boolean(errorDe('horarios'))"
              :aria-describedby="errorDe('horarios') ? 'error-horarios' : null"
              @input="limpiarError('horarios')"
            />
          </div>
          <div class="campo">
            <label class="visually-hidden" :for="`horario-fin-${dia.valor}`">
              Cierre del {{ dia.etiqueta.toLowerCase() }}
            </label>
            <input
              :id="`horario-fin-${dia.valor}`"
              v-model="formulario[`horario_fin_${dia.valor}`]"
              class="form-control"
              type="time"
              :name="`horario_fin_${dia.valor}`"
              required
              :aria-invalid="Boolean(errorDe('horarios'))"
              :aria-describedby="errorDe('horarios') ? 'error-horarios' : null"
              @input="limpiarError('horarios')"
            />
          </div>
        </div>
      </div>
      <p v-if="errorDe('horarios')" id="error-horarios" class="campo__error" role="alert">
        {{ errorDe('horarios') }}
      </p>
      <p class="visually-hidden" aria-live="polite">{{ mensajeHorarios }}</p>
    </details>

    <div
      v-if="mostrarSecundarias"
      class="formulario__secundarias"
      :class="{
        'formulario__secundarias--identidad': soloIdentidad || modo === 'create' || !mostrarEstado,
      }"
    >
      <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-identidad">
        <header>
          <span aria-hidden="true"><Palette :size="20" /></span>
          <div>
            <h2 id="titulo-identidad">Identidad visual</h2>
            <p>Personaliza el logo y los colores de tu empresa.</p>
          </div>
        </header>

        <div class="identidad">
          <div class="identidad__logo" :class="{ 'identidad__logo--con-imagen': logoRenderUrl }">
            <img
              v-if="logoRenderUrl && !logoImagenFallida"
              :src="logoRenderUrl"
              alt="Logo actual de la empresa"
              @error="logoImagenFallida = true"
            />
            <Building2 v-if="!logoRenderUrl || logoImagenFallida" :size="24" />
          </div>
          <div class="campo">
            <label class="form-label" for="empresa-logo">Logo</label>
            <input
              id="empresa-logo"
              ref="logoInput"
              class="form-control"
              :class="{ 'is-invalid': errorLogo || errorDe('logoUrl') }"
              type="file"
              name="logo"
              accept="image/png,image/jpeg,image/webp"
              :disabled="procesandoLogo || enviando"
              :aria-invalid="Boolean(errorLogo || errorDe('logoUrl'))"
              :aria-describedby="errorLogo || errorDe('logoUrl') ? 'error-logo' : 'ayuda-logo'"
              @change="seleccionarLogo"
            />
            <p id="ayuda-logo" class="campo__ayuda">
              PNG, JPG o WebP. Máximo 2 MB. Se adapta automáticamente a
              <strong>400 × 180 px</strong>.
            </p>
            <p v-if="errorLogo || errorDe('logoUrl')" id="error-logo" class="campo__error">
              {{ errorLogo || errorDe('logoUrl') }}
            </p>
          </div>
        </div>

        <div class="colores">
          <div class="campo">
            <label class="form-label" for="color-primario">Color de fondo</label>
            <div class="campo-color">
              <input
                id="color-primario"
                v-model="formulario.colorPrimario"
                type="color"
                name="colorPrimario"
                @input="limpiarError('colorPrimario')"
              />
              <input
                ref="colorPrimarioInput"
                v-model="formulario.colorPrimario"
                class="form-control"
                :class="{ 'is-invalid': errorDe('colorPrimario') }"
                type="text"
                name="colorPrimarioHex"
                maxlength="7"
                aria-label="Código hexadecimal del color de fondo"
                :aria-invalid="Boolean(errorDe('colorPrimario'))"
                :aria-describedby="errorDe('colorPrimario') ? 'error-color-primario' : null"
                @input="limpiarError('colorPrimario')"
              />
            </div>
            <p v-if="errorDe('colorPrimario')" id="error-color-primario" class="campo__error">
              {{ errorDe('colorPrimario') }}
            </p>
          </div>
          <div class="campo">
            <label class="form-label" for="color-secundario">Color de texto</label>
            <div class="campo-color">
              <input
                id="color-secundario"
                v-model="formulario.colorSecundario"
                type="color"
                name="colorSecundario"
                @input="limpiarError('colorSecundario')"
              />
              <input
                ref="colorSecundarioInput"
                v-model="formulario.colorSecundario"
                class="form-control"
                :class="{ 'is-invalid': errorDe('colorSecundario') }"
                type="text"
                name="colorSecundarioHex"
                maxlength="7"
                aria-label="Código hexadecimal del color de texto"
                :aria-invalid="Boolean(errorDe('colorSecundario'))"
                :aria-describedby="errorDe('colorSecundario') ? 'error-color-secundario' : null"
                @input="limpiarError('colorSecundario')"
              />
            </div>
            <p v-if="errorDe('colorSecundario')" id="error-color-secundario" class="campo__error">
              {{ errorDe('colorSecundario') }}
            </p>
          </div>
        </div>
      </section>

      <section
        v-if="mostrarEstado && !soloIdentidad && modo !== 'create'"
        class="formulario__seccion gb-tarjeta"
        aria-labelledby="titulo-estado"
      >
        <header>
          <span aria-hidden="true"><Power :size="20" /></span>
          <div>
            <h2 id="titulo-estado">Estado de la empresa</h2>
            <p>Controla el acceso operativo dentro de Gym Bros.</p>
          </div>
        </header>

        <fieldset
          class="estado-opciones"
          :class="{ 'estado-opciones--invalido': errorDe('estado') }"
          aria-labelledby="titulo-estado"
          :aria-describedby="errorDe('estado') ? 'error-estado' : null"
        >
          <label>
            <input
              ref="estadoInput"
              v-model="formulario.estado"
              type="radio"
              name="estado"
              value="active"
              @change="limpiarError('estado')"
            />
            <span><b>Activa</b><small>La empresa puede operar normalmente.</small></span>
          </label>
          <label>
            <input
              v-model="formulario.estado"
              type="radio"
              name="estado"
              value="inactive"
              @change="limpiarError('estado')"
            />
            <span><b>Inactiva</b><small>El acceso de la empresa queda suspendido.</small></span>
          </label>
        </fieldset>
        <p v-if="errorDe('estado')" id="error-estado" class="campo__error">
          {{ errorDe('estado') }}
        </p>
      </section>
    </div>

    <details
      v-if="soloIdentidad || modo === 'create'"
      class="formulario__seccion gb-tarjeta"
      aria-labelledby="titulo-banners-personalizar"
    >
      <summary class="banners-empresa__cabecera">
        <span class="banners-empresa__icono" aria-hidden="true"><ImageIcon :size="20" /></span>
        <span class="banners-empresa__resumen">
          <span id="titulo-banners-personalizar">Banners de la empresa</span>
          <span>Configura las imágenes y enlaces de las promociones móviles.</span>
        </span>
        <span class="banners-empresa__indicador">
          <span>3 espacios</span>
          <ChevronDown :size="18" aria-hidden="true" />
        </span>
      </summary>
      <div class="banners-empresa__lista">
        <article v-for="numero in [1, 2, 3]" :key="numero" class="banner-pareja">
          <header class="banner-pareja__cabecera">
            <span>{{ String(numero).padStart(2, '0') }}</span>
            <h3>Banner {{ numero }}</h3>
          </header>
          <div class="banner-pareja__contenido">
            <div class="campo banner-pareja__media">
              <label class="visually-hidden" :for="`empresa-banner-${numero}`">
                Imagen para el banner {{ numero }}
              </label>
              <div
                class="banner-pareja__lienzo"
                :class="{ 'banner-pareja__lienzo--vacio': !formulario[`banner_${numero}`] }"
              >
                <img
                  v-if="formulario[`banner_${numero}`]"
                  :src="resolverUrlStorage(formulario[`banner_${numero}`])"
                  :alt="`Vista previa del banner ${numero}`"
                />
                <template v-else>
                  <ImageIcon :size="24" aria-hidden="true" />
                  <span>Sin imagen</span>
                </template>
              </div>
              <label
                class="btn btn-secondary banner-pareja__selector"
                :for="`empresa-banner-${numero}`"
              >
                {{ formulario[`banner_${numero}`] ? 'Cambiar imagen' : 'Seleccionar imagen' }}
              </label>
              <input
                :id="`empresa-banner-${numero}`"
                class="banner-pareja__archivo"
                type="file"
                accept="image/png,image/jpeg,image/webp"
                :disabled="enviando || procesandoBanners > 0"
                :aria-invalid="Boolean(errorDe(`banner_${numero}`))"
                :aria-describedby="errorDe(`banner_${numero}`) ? `error-banner-${numero}` : null"
                @change="seleccionarBanner($event, numero)"
              />
              <p class="campo__ayuda">PNG, JPG o WebP · máximo 3 MB · 500 × 380 px.</p>
              <p v-if="erroresBanners[numero]" class="campo__error">{{ erroresBanners[numero] }}</p>
              <p
                v-if="errorDe(`banner_${numero}`)"
                :id="`error-banner-${numero}`"
                class="campo__error"
              >
                {{ errorDe(`banner_${numero}`) }}
              </p>
            </div>
            <div class="campo banner-pareja__enlace">
              <label class="banner-pareja__enlace-label" :for="`empresa-link-${numero}`">
                <Link2 :size="15" aria-hidden="true" />
                Enlace del botón
              </label>
              <input
                :id="`empresa-link-${numero}`"
                v-model="formulario[`link_boton_${numero}`]"
                class="form-control"
                type="url"
                maxlength="200"
                placeholder="https://…"
                :disabled="enviando"
                :aria-invalid="Boolean(errorDe(`link_boton_${numero}`))"
                :aria-describedby="errorDe(`link_boton_${numero}`) ? `error-link-${numero}` : null"
                @input="limpiarError(`link_boton_${numero}`)"
              />
              <p class="banner-pareja__enlace-ayuda">
                Abre esta dirección al tocar el botón del banner.
              </p>
              <p
                v-if="errorDe(`link_boton_${numero}`)"
                :id="`error-link-${numero}`"
                class="campo__error"
              >
                {{ errorDe(`link_boton_${numero}`) }}
              </p>
            </div>
          </div>
        </article>
      </div>
    </details>

    <div class="formulario__acciones">
      <button type="button" class="btn btn-secondary" :disabled="enviando" @click="emit('cancel')">
        Cancelar
      </button>
      <button type="submit" class="btn btn-primary" :disabled="enviando">
        <span v-if="enviando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        {{ enviando ? 'Guardando…' : modo === 'edit' ? 'Guardar cambios' : 'Guardar empresa' }}
      </button>
    </div>
    <ConfirmDialog
      :abierto="Boolean(pendientePlan)"
      titulo="¿Asignar el plan seleccionado?"
      descripcion="Esta acción asignará el plan inmediatamente y reemplazará la suscripción activa anterior, conservando el historial."
      etiqueta-confirmar="Asignar plan y guardar"
      :confirmando="enviando"
      @cancelar="pendientePlan = null"
      @confirmar="confirmarPlan"
    />
  </form>
</template>

<style scoped>
.formulario {
  display: grid;
  gap: var(--gb-gutter, 1.25rem);
  font-size: calc(1rem - var(--empresa-reduccion-texto, 0px));
}

.formulario__seccion[aria-labelledby='titulo-banners-personalizar'] {
  padding: clamp(1rem, 2vw, 1.5rem);
}

.banners-empresa__cabecera {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
  list-style: none;
}

.banners-empresa__cabecera::-webkit-details-marker {
  display: none;
}

.banners-empresa__cabecera:focus-visible {
  outline: 2px solid var(--gb-red-text);
  outline-offset: 0.35rem;
  border-radius: var(--gb-radius);
}

.banners-empresa__icono {
  display: grid;
  width: 2.5rem;
  height: 2.5rem;
  place-items: center;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  background: var(--gb-surface-high);
  color: var(--gb-red-text);
}

.banners-empresa__resumen {
  display: grid;
  min-width: 0;
  gap: 0.16rem;
}

.banners-empresa__resumen > :first-child {
  color: var(--gb-text);
  font-size: calc(var(--gb-tipo-lg) - var(--empresa-reduccion-texto, 0px));
  font-weight: 800;
  letter-spacing: -0.02em;
}

.banners-empresa__resumen > :last-child {
  max-width: 38rem;
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-sm) - var(--empresa-reduccion-texto, 0px));
  line-height: 1.45;
}

.banners-empresa__indicador {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-xs) - var(--empresa-reduccion-texto, 0px));
  font-weight: 700;
}

.banners-empresa__indicador svg {
  transition: transform 160ms ease;
}

.formulario__seccion[open] .banners-empresa__indicador svg {
  transform: rotate(180deg);
}

.banners-empresa__lista {
  display: grid;
  gap: 0.75rem;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--gb-border);
}

.banner-pareja {
  padding: 1rem;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  background: var(--gb-surface-lowest);
}

.banner-pareja__cabecera {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-bottom: 0.85rem;
}

.banner-pareja__cabecera > span {
  display: grid;
  width: 1.75rem;
  height: 1.75rem;
  place-items: center;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-sm);
  color: var(--gb-text-muted);
  background: var(--gb-surface-high);
  font-size: var(--gb-tipo-xxs);
  font-weight: 800;
}

.banner-pareja__cabecera h3 {
  margin: 0;
  color: var(--gb-text);
  font-size: calc(var(--gb-tipo-sm) - var(--empresa-reduccion-texto, 0px));
  font-weight: 700;
}

.banner-pareja__contenido {
  display: grid;
  grid-template-columns: minmax(9rem, 11rem) minmax(0, 1fr);
  gap: 1rem;
  align-items: start;
}

.banner-pareja__media {
  display: grid;
  gap: 0.5rem;
}

.banner-pareja__lienzo {
  overflow: hidden;
  aspect-ratio: 500 / 380;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  background: var(--gb-surface-high);
}

.banner-pareja__lienzo--vacio {
  display: grid;
  place-items: center;
  align-content: center;
  gap: 0.35rem;
  border-style: dashed;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.banner-pareja__lienzo img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.banner-pareja__archivo {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  clip-path: inset(50%);
  white-space: nowrap;
}

.banner-pareja__selector {
  justify-self: start;
  min-height: 2.25rem;
  padding: 0.4rem 0.75rem;
}

.banner-pareja__enlace {
  align-content: center;
  min-height: 100%;
}

.banner-pareja__enlace-label {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-bottom: 0.45rem;
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-xs) - var(--empresa-reduccion-texto, 0px));
  font-weight: 700;
}

.banner-pareja__enlace-label svg {
  color: var(--gb-red-text);
}

.banner-pareja__enlace-ayuda {
  margin-top: 0.45rem !important;
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-xxs) - var(--empresa-reduccion-texto, 0px));
  line-height: 1.4;
}

@media (max-width: 52rem) {
  .banners-empresa__cabecera {
    grid-template-columns: auto minmax(0, 1fr);
  }

  .banners-empresa__indicador {
    grid-column: 2;
  }

  .banner-pareja__contenido {
    grid-template-columns: 1fr;
  }

  .banner-pareja__media {
    max-width: 12rem;
  }
}

.formulario .form-control,
.formulario .form-select {
  font-size: calc(1rem - var(--empresa-reduccion-texto, 0px));
}

.formulario .btn {
  font-size: calc(
    var(--gb-tipo-xs) - var(--empresa-reduccion-texto, 0px) +
      var(--empresa-aumento-cabecera-botones, 0px) + var(--empresa-aumento-ayudas-botones, 0px)
  );
}

.formulario__seccion[aria-labelledby='titulo-informacion'] h2 {
  font-size: calc(
    var(--gb-tipo-md) - var(--empresa-reduccion-texto, 0px) +
      var(--empresa-aumento-cabecera-botones, 0px)
  );
}

.formulario__seccion[aria-labelledby='titulo-informacion'] header p {
  font-size: calc(
    var(--gb-tipo-xs) - var(--empresa-reduccion-texto, 0px) +
      var(--empresa-aumento-cabecera-botones, 0px) + var(--empresa-aumento-ayudas-botones, 0px)
  );
}

.formulario__seccion[aria-labelledby='titulo-identidad'] header p {
  font-size: calc(
    var(--gb-tipo-xs) - var(--empresa-reduccion-texto, 0px) +
      var(--empresa-aumento-ayudas-botones, 0px)
  );
}

#ayuda-logo {
  font-size: calc(
    var(--gb-tipo-xxs) - var(--empresa-reduccion-texto, 0px) +
      var(--empresa-aumento-ayudas-botones, 0px)
  );
}

.formulario__seccion {
  padding: 1.25rem 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.horarios-desplegable > summary {
  cursor: pointer;
  font-weight: 700;
  font-size: calc(var(--gb-tipo-md) - var(--empresa-reduccion-texto, 0px));
}

.horarios-desplegable[open] > summary {
  margin-bottom: 1.25rem;
}

.formulario__seccion > header {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}

.formulario__seccion > header > span {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
}

.formulario__seccion h2,
.formulario__seccion p {
  margin: 0;
}

.formulario__seccion h2 {
  font-size: calc(var(--gb-tipo-md) - var(--empresa-reduccion-texto, 0px));
  text-transform: uppercase;
}

.formulario__seccion header p {
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-xs) - var(--empresa-reduccion-texto, 0px));
}

.formulario__rejilla,
.colores {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.campo {
  min-width: 0;
}

.formulario__rejilla {
  grid-template-columns: repeat(var(--empresa-columnas, 2), minmax(0, 1fr));
}

.campo--completo {
  grid-column: var(--empresa-campo-completo, 1 / -1);
}

.campo__ayuda,
.campo__error {
  margin: 0.375rem 0 0;
  font-size: calc(var(--gb-tipo-xxs) - var(--empresa-reduccion-texto, 0px));
}

.campo__ayuda {
  color: var(--gb-text-muted);
}

.campo__error {
  color: var(--gb-error);
}

.horarios {
  display: grid;
  gap: 0;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  overflow: hidden;
}

.horarios-encabezado__texto {
  flex: 1;
  min-width: 0;
}

.horarios-encabezado__accion {
  flex: none;
  align-self: center;
}

.horarios__cabecera,
.horario {
  display: grid;
  grid-template-columns: minmax(8rem, 1fr) repeat(2, minmax(8rem, 0.75fr));
  gap: 1rem;
}

.horarios__cabecera {
  padding: 0.625rem 1rem;
  background-color: var(--gb-surface-high);
  border-bottom: 1px solid var(--gb-border);
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-xxs) - var(--empresa-reduccion-texto, 0px));
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.horario {
  align-items: center;
  padding: 0.625rem 1rem;
  background-color: var(--gb-surface-lowest);
  border-bottom: 1px solid var(--gb-border);
}

.horario:last-child {
  border-bottom: 0;
}

.horario > strong {
  align-self: center;
  font-size: calc(
    var(--gb-tipo-sm) - var(--empresa-reduccion-texto, 0px) + var(--empresa-aumento-dias, 0px)
  );
}

.horario .form-control {
  width: 100%;
  min-width: 0;
}

.horarios--invalidos {
  border-color: var(--gb-error);
}

.formulario__secundarias {
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) minmax(20rem, 0.75fr);
  gap: var(--gb-gutter, 1.25rem);
  align-items: stretch;
}

.formulario__secundarias .formulario__seccion {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.formulario__secundarias--identidad {
  grid-template-columns: 1fr;
}

.formulario__secundarias--identidad > .formulario__seccion {
  display: grid;
  grid-template-columns: minmax(0, 2fr) repeat(2, minmax(0, 1fr));
  gap: 1rem;
  align-items: start;
}

.formulario__secundarias--identidad header {
  grid-column: 1 / -1;
}

.formulario__secundarias--identidad .colores {
  display: contents;
}

.formulario__secundarias--identidad .campo-color {
  grid-template-columns: 2rem minmax(0, 1fr);
  align-items: center;
}

.formulario__secundarias--identidad .campo-color input[type='color'] {
  width: 2rem;
  height: 2rem;
}

@media (max-width: 64rem) {
  .formulario__secundarias--identidad > .formulario__seccion {
    grid-template-columns: 1fr;
  }
}

.formulario__secundarias .formulario__seccion > header {
  min-height: 3.5rem;
  margin-bottom: 1rem;
}

.identidad {
  display: grid;
  grid-template-columns: 5rem minmax(0, 1fr);
  gap: 1rem;
  align-items: start;
}

.identidad__logo {
  display: grid;
  place-items: center;
  width: 5rem;
  height: 5rem;
  background-color: var(--gb-surface-lowest);
  background-position: center;
  background-size: contain;
  background-repeat: no-repeat;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-text-soft);
  font-size: calc(1.5rem - var(--empresa-reduccion-texto, 0px));
}

.identidad__logo--con-imagen {
  padding: 0.25rem;
}

.identidad__logo img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.colores {
  margin-top: 1rem;
}

.campo-color {
  display: grid;
  grid-template-columns: 3rem minmax(0, 1fr);
  gap: 0.5rem;
}

.campo-color input[type='color'] {
  width: 3rem;
  height: 3rem;
  padding: 0.25rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
}

.estado-opciones {
  flex: 1;
  display: grid;
  gap: 0.75rem;
  align-content: space-around;
  margin: 0;
  padding: 0;
  border: 0;
}

.estado-opciones label {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 0.875rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  cursor: pointer;
}

.estado-opciones label:has(input:checked) {
  border-color: var(--gb-red);
  box-shadow: var(--gb-relieve);
}

.estado-opciones--invalido label {
  border-color: var(--gb-error);
}

.estado-opciones input {
  margin-top: 0.2rem;
  accent-color: var(--gb-red);
}

.estado-opciones span {
  display: grid;
}

.estado-opciones b {
  font-size: calc(var(--gb-tipo-sm) - var(--empresa-reduccion-texto, 0px));
}

.estado-opciones small {
  margin-top: 0.125rem;
  color: var(--gb-text-muted);
  font-size: calc(var(--gb-tipo-xxs) - var(--empresa-reduccion-texto, 0px));
}

.formulario__acciones {
  position: sticky;
  bottom: 0;
  z-index: 5;
  isolation: isolate;
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1rem 0;
  background-color: var(--gb-bg);
  border-top: 1px solid var(--gb-border);
}

/* El contenido principal conserva un margen inferior. Al quedar pegada la
   barra, este fondo sólido prolonga su superficie hasta el borde visible y
   evita que el formulario que pasa por debajo aparezca como una franja. */
.formulario__acciones::after {
  position: absolute;
  top: 100%;
  right: 0;
  left: 0;
  height: var(--gb-margen);
  background-color: var(--gb-bg);
  content: '';
  pointer-events: none;
}

.formulario__acciones .btn {
  min-height: 2.75rem;
  padding-inline: 1.25rem;
}

@media (max-width: 78rem) {
  .formulario__secundarias {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 64rem) {
  .formulario__rejilla {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .formulario__acciones::after {
    height: var(--gb-gutter);
  }
}

@media (max-width: 52rem) {
  .formulario__rejilla,
  .colores {
    grid-template-columns: 1fr;
  }

  .campo--completo {
    grid-column: auto;
  }

  .horarios-encabezado {
    flex-wrap: wrap;
  }

  .horarios-encabezado__accion {
    width: 100%;
  }

  .horarios__cabecera,
  .horario {
    grid-template-columns: minmax(5rem, 0.65fr) repeat(2, minmax(0, 1fr));
    gap: 0.625rem;
  }
}
</style>
