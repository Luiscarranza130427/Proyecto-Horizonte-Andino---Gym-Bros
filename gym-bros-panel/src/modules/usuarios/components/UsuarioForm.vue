<script setup>
import { Building2, Camera, Trash2, User, UserRound } from 'lucide-vue-next'
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'

import { FOTO_USUARIO_LADO, normalizarFotoUsuario } from '@/shared/utils/fotoUsuario'
import { esCorreoValido, esTelefonoConLimite, limpiarTelefono } from '@/shared/utils/validaciones'

const props = defineProps({
  usuarioInicial: { type: Object, default: () => ({}) },
  // Alias usado por algunas vistas; se mantiene usuarioInicial por compatibilidad.
  valoresIniciales: { type: Object, default: null },
  empresas: { type: Array, default: () => [] },
  // Roles que la sesión puede asignar: los da el servicio (`obtenerRolesAsignables`).
  roles: {
    type: Array,
    default: () => [
      { valor: 'admin', etiqueta: 'Administrador' },
      { valor: 'manager', etiqueta: 'Empresa' },
      { valor: 'trainer', etiqueta: 'Entrenador' },
      { valor: 'member', etiqueta: 'Usuario' },
    ],
  },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
  modo: { type: String, default: 'create' },
})

const emit = defineEmits({
  submit: (payload) => Boolean(payload && typeof payload === 'object'),
  cancel: null,
})

const formulario = ref(crearEstadoInicial())
const erroresLocales = ref({})

const empresaInput = ref(null)
const rolInput = ref(null)
const nombreInput = ref(null)
const apellidoInput = ref(null)
const apodoInput = ref(null)
const correoInput = ref(null)
const telefonoInput = ref(null)
const tipoDocumentoInput = ref(null)
const numeroDocumentoInput = ref(null)
const fechaNacimientoInput = ref(null)
const inicioSuscripcionInput = ref(null)
const finSuscripcionInput = ref(null)
const generoInput = ref(null)
const estadoInput = ref(null)
const entradaFoto = ref(null)

const refsCampos = {
  empresaId: empresaInput,
  rol: rolInput,
  nombre: nombreInput,
  apellido: apellidoInput,
  apodo: apodoInput,
  correo: correoInput,
  telefono: telefonoInput,
  tipoDocumento: tipoDocumentoInput,
  numeroDocumento: numeroDocumentoInput,
  fechaNacimiento: fechaNacimientoInput,
  inicioSuscripcion: inicioSuscripcionInput,
  finSuscripcion: finSuscripcionInput,
  genero: generoInput,
  estado: estadoInput,
  fotoPerfil: entradaFoto,
}

/*
 * La foto viaja como texto en `foto_perfil`, igual que el logo de empresa: no
 * hay endpoint de subida de archivos. `vistaPrevia` guarda un objectURL sólo
 * para enseñarla mientras se edita, y se libera al salir para no dejar memoria
 * retenida.
 */
const errorFoto = ref('')
const procesandoFoto = ref(false)
const imagenFallida = ref(false)
let vistaPrevia = ''

function liberarVistaPrevia() {
  if (vistaPrevia) URL.revokeObjectURL(vistaPrevia)
  vistaPrevia = ''
}

const fotoVisible = computed(() => formulario.value.fotoPerfil || '')

watch(
  fotoVisible,
  () => {
    imagenFallida.value = false
  },
  { immediate: true },
)

async function elegirFoto(evento) {
  const archivo = evento.target.files?.[0]
  evento.target.value = ''
  if (!archivo) return

  errorFoto.value = ''
  procesandoFoto.value = true

  try {
    formulario.value.fotoPerfil = await normalizarFotoUsuario(archivo)
    limpiarError('fotoPerfil')
  } catch (error) {
    errorFoto.value = error.message
  } finally {
    procesandoFoto.value = false
  }
}

function quitarFoto() {
  liberarVistaPrevia()
  formulario.value.fotoPerfil = ''
  errorFoto.value = ''
  if (entradaFoto.value) entradaFoto.value.value = ''
  limpiarError('fotoPerfil')
}

function abrirSelectorFoto() {
  entradaFoto.value?.click()
}

onBeforeUnmount(liberarVistaPrevia)

function crearEstadoInicial() {
  const fuente = props.valoresIniciales ?? props.usuarioInicial ?? {}
  const datosEmpresa = fuente.empresa
  const idEmpresa =
    typeof datosEmpresa === 'object' && datosEmpresa !== null
      ? (datosEmpresa.id ?? '')
      : (fuente.empresaId ?? fuente.company_id ?? '')

  return {
    empresaId: idEmpresa !== '' && idEmpresa !== null ? String(idEmpresa) : '',
    rol: fuente.rol ?? fuente.role ?? 'member',
    nombre: fuente.nombre ?? fuente.nombres ?? fuente.name ?? '',
    apellido: fuente.apellido ?? fuente.last_name ?? '',
    apodo: fuente.apodo ?? fuente.apodos ?? fuente.nickname ?? '',
    correo: fuente.correo ?? fuente.email ?? '',
    telefono: fuente.telefono ?? fuente.phone ?? '',
    tipoDocumento: fuente.tipoDocumento ?? fuente.document_type ?? 'dni',
    numeroDocumento: fuente.numeroDocumento ?? fuente.document_number ?? '',
    fechaNacimiento: normalizarFecha(fuente.fechaNacimiento ?? fuente.birth_date),
    inicioSuscripcion: normalizarFecha(
      fuente.inicioSuscripcion ?? fuente.inicio_suscripcion ?? fuente.subscription_start,
    ),
    finSuscripcion: normalizarFecha(
      fuente.finSuscripcion ?? fuente.fin_suscripcion ?? fuente.subscription_end,
    ),
    direccion: fuente.direccion ?? fuente.address ?? '',
    genero: fuente.genero ?? '',
    fotoPerfil: fuente.fotoPerfil ?? fuente.foto_perfil ?? fuente.profile_photo ?? '',
    estado: normalizarEstado(fuente.estado ?? fuente.status),
  }
}

function normalizarEstado(valor) {
  if (valor === 'inactive' || valor === 'inactivo' || valor === 0 || valor === false) {
    return 'inactive'
  }
  return 'active'
}

function normalizarFecha(valor) {
  if (!valor) return ''
  const cadena = String(valor)
  return cadena.length >= 10 ? cadena.slice(0, 10) : ''
}

watch(
  () => [props.usuarioInicial, props.valoresIniciales],
  () => {
    formulario.value = crearEstadoInicial()
    erroresLocales.value = {}
  },
  { immediate: true },
)

const errores = computed(() => ({
  ...props.erroresServidor,
  ...erroresLocales.value,
}))

function errorDe(campo) {
  const err = errores.value[campo]
  if (!err) return ''
  return Array.isArray(err) ? err[0] : String(err)
}

function limpiarError(campo) {
  if (erroresLocales.value[campo]) {
    const copia = { ...erroresLocales.value }
    delete copia[campo]
    erroresLocales.value = copia
  }
}

/*
 * Campos que la API exige al crear (`UsuarioController::store`). Al editar son
 * `sometimes|required`: se pueden omitir pero no vaciar. Por eso en edición
 * sólo son obligatorios los que ya tenían valor, y los que siguen vacíos no se
 * envían (antes viajaban como '' o null y la API respondía 422).
 */
const CAMPOS_OBLIGATORIOS_API = [
  'apodo',
  'telefono',
  'numeroDocumento',
  'fechaNacimiento',
  'genero',
]

const valoresOriginales = computed(() => crearEstadoInicial())

function esObligatorio(campo) {
  if (props.modo === 'create') return true
  return Boolean(String(valoresOriginales.value[campo] ?? '').trim())
}

function validar() {
  const nuevos = {}
  const f = formulario.value

  if (!f.nombre.trim()) nuevos.nombre = ['Introduce un nombre.']
  if (!f.apellido.trim()) nuevos.apellido = ['Introduce un apellido.']
  if (!f.apodo.trim() && esObligatorio('apodo')) nuevos.apodo = ['Introduce un apodo.']

  if (!esCorreoValido(f.correo)) nuevos.correo = ['Introduce un correo válido.']

  // `usuarios.telefono` y `usuarios.numero_documento` son varchar(12).
  if ((f.telefono.trim() || esObligatorio('telefono')) && !esTelefonoConLimite(f.telefono, 12)) {
    nuevos.telefono = ['Introduce un teléfono de 6 a 12 dígitos.']
  }

  const numDoc = f.numeroDocumento.trim()
  if (!numDoc) {
    if (esObligatorio('numeroDocumento')) {
      nuevos.numeroDocumento = ['Introduce el número de documento.']
    }
  } else if (f.tipoDocumento === 'dni') {
    if (!/^\d{8}$/.test(numDoc)) {
      nuevos.numeroDocumento = ['El DNI debe tener exactamente 8 dígitos.']
    }
  } else if (numDoc.length < 5 || numDoc.length > 12) {
    nuevos.numeroDocumento = ['El documento debe tener entre 5 y 12 caracteres.']
  }

  if (f.fechaNacimiento) {
    const hoy = new Date().toISOString().slice(0, 10)
    if (f.fechaNacimiento > hoy) {
      nuevos.fechaNacimiento = ['La fecha de nacimiento no puede ser futura.']
    } else if (f.fechaNacimiento < '1900-01-01') {
      nuevos.fechaNacimiento = ['Introduce una fecha de nacimiento válida.']
    }
  } else if (esObligatorio('fechaNacimiento')) {
    nuevos.fechaNacimiento = ['Introduce la fecha de nacimiento.']
  }

  if (!f.genero && esObligatorio('genero')) nuevos.genero = ['Selecciona el género.']

  if (props.modo === 'create') {
    if (!f.empresaId) nuevos.empresaId = ['Selecciona una empresa.']
    if (!f.rol) nuevos.rol = ['Selecciona un rol.']
  }

  erroresLocales.value = nuevos
  return Object.keys(nuevos).length === 0
}

async function enviar() {
  if (!validar()) {
    await nextTick()
    enfocarPrimerError()
    return
  }

  const f = formulario.value
  const obligatorios = {
    apodo: f.apodo.trim(),
    telefono: limpiarTelefono(f.telefono.trim()),
    numeroDocumento: f.numeroDocumento.trim(),
    fechaNacimiento: f.fechaNacimiento,
    genero: f.genero,
  }
  const payload = {
    nombre: f.nombre.trim(),
    apellido: f.apellido.trim(),
    correo: f.correo.trim().toLowerCase(),
    tipoDocumento: f.tipoDocumento,
    ...Object.fromEntries(
      CAMPOS_OBLIGATORIOS_API.filter((campo) => obligatorios[campo]).map((campo) => [
        campo,
        obligatorios[campo],
      ]),
    ),
    ...(props.modo === 'edit'
      ? {
          ...(f.inicioSuscripcion ? { inicioSuscripcion: f.inicioSuscripcion } : {}),
          ...(f.finSuscripcion ? { finSuscripcion: f.finSuscripcion } : {}),
        }
      : {}),
    direccion: f.direccion.trim(),
    fotoPerfil: f.fotoPerfil,
  }

  if (props.modo === 'create' || f.empresaId) {
    payload.empresaId = isNaN(Number(f.empresaId)) ? f.empresaId : Number(f.empresaId)
  }
  if (props.modo === 'create' || f.rol) {
    payload.rol = f.rol
  }
  if (props.modo === 'create' || f.estado) {
    payload.estado = f.estado
  }

  emit('submit', payload)
}

function enfocarPrimerError() {
  const primerCampoConError = Object.keys(errores.value)[0]
  if (primerCampoConError && refsCampos[primerCampoConError]?.value) {
    refsCampos[primerCampoConError].value.focus()
  }
}
</script>

<template>
  <form class="formulario" novalidate @submit.prevent="enviar">
    <!-- Datos personales -->
    <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-personales">
      <header>
        <span aria-hidden="true"><User :size="20" /></span>
        <div>
          <h2 id="titulo-personales">Datos personales</h2>
          <p>Información de identificación y contacto del usuario.</p>
        </div>
      </header>

      <!-- Bloque de Foto de Perfil & Identidad -->
      <div class="usuario-avatar-bloque">
        <div class="usuario-avatar-marco">
          <div
            class="usuario-avatar-vista"
            :class="{ 'usuario-avatar-vista--con-imagen': fotoVisible && !imagenFallida }"
            role="button"
            tabindex="0"
            title="Haz clic para seleccionar o cambiar foto"
            @click="abrirSelectorFoto"
            @keydown.enter="abrirSelectorFoto"
            @keydown.space.prevent="abrirSelectorFoto"
          >
            <img
              v-if="fotoVisible && !imagenFallida"
              :src="fotoVisible"
              :alt="formulario.nombre ? `Foto de perfil de ${formulario.nombre}` : 'Foto de perfil'"
              class="usuario-avatar-img"
              @error="imagenFallida = true"
            />
            <UserRound v-else :size="40" class="usuario-avatar-icono" aria-hidden="true" />
          </div>

          <button
            type="button"
            class="usuario-avatar-camara"
            title="Seleccionar foto de perfil"
            aria-label="Seleccionar foto de perfil"
            :disabled="procesandoFoto"
            @click="abrirSelectorFoto"
          >
            <Camera :size="15" aria-hidden="true" />
          </button>

          <label class="visually-hidden" for="usuario-foto">Foto de perfil</label>
          <input
            id="usuario-foto"
            ref="entradaFoto"
            type="file"
            name="fotoPerfil"
            accept="image/png,image/jpeg,image/webp"
            class="visually-hidden"
            :disabled="procesandoFoto"
            :aria-invalid="Boolean(errorFoto || errorDe('fotoPerfil'))"
            :aria-describedby="errorFoto || errorDe('fotoPerfil') ? 'error-foto' : 'ayuda-foto'"
            @change="elegirFoto"
          />
        </div>

        <div class="usuario-avatar-info">
          <div class="usuario-avatar-cabecera">
            <span class="usuario-avatar-titulo">Foto de perfil</span>
            <span
              v-if="formulario.nombre || formulario.apellido"
              class="usuario-avatar-nombre-vista"
            >
              {{ [formulario.nombre, formulario.apellido].filter(Boolean).join(' ') }}
            </span>
          </div>

          <div class="usuario-avatar-acciones">
            <button
              type="button"
              class="btn btn-secondary btn-sm"
              :disabled="procesandoFoto"
              @click="abrirSelectorFoto"
            >
              <Camera :size="14" aria-hidden="true" />
              <span>{{ fotoVisible ? 'Cambiar foto' : 'Subir foto' }}</span>
            </button>

            <button
              v-if="fotoVisible"
              type="button"
              class="btn btn-outline-danger btn-sm foto__btn-quitar"
              title="Quitar foto de perfil"
              aria-label="Quitar foto de perfil"
              :disabled="procesandoFoto"
              @click="quitarFoto"
            >
              <Trash2 :size="14" aria-hidden="true" />
              <span>Quitar foto</span>
            </button>
          </div>

          <p id="ayuda-foto" class="usuario-avatar-ayuda">
            PNG, JPG o WebP. Máximo 3 MB. Se optimiza y recorta automáticamente a
            {{ FOTO_USUARIO_LADO }} × {{ FOTO_USUARIO_LADO }} px.
          </p>
          <p v-if="errorFoto || errorDe('fotoPerfil')" id="error-foto" class="campo__error">
            {{ errorFoto || errorDe('fotoPerfil') }}
          </p>
          <p v-if="procesandoFoto" class="usuario-avatar-estado">
            <span class="spinner-border spinner-border-sm" aria-hidden="true"></span>
            <span>Optimizando imagen…</span>
          </p>
        </div>
      </div>

      <div class="formulario__rejilla">
        <div class="campo">
          <label class="form-label" for="usuario-nombre">Nombre *</label>
          <input
            id="usuario-nombre"
            ref="nombreInput"
            v-model="formulario.nombre"
            class="form-control"
            :class="{ 'is-invalid': errorDe('nombre') }"
            type="text"
            name="nombre"
            maxlength="80"
            autocomplete="given-name"
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
          <label class="form-label" for="usuario-apellido">Apellido *</label>
          <input
            id="usuario-apellido"
            ref="apellidoInput"
            v-model="formulario.apellido"
            class="form-control"
            :class="{ 'is-invalid': errorDe('apellido') }"
            type="text"
            name="apellido"
            maxlength="80"
            autocomplete="family-name"
            required
            :aria-invalid="Boolean(errorDe('apellido'))"
            :aria-describedby="errorDe('apellido') ? 'error-apellido' : null"
            @input="limpiarError('apellido')"
          />
          <p v-if="errorDe('apellido')" id="error-apellido" class="campo__error">
            {{ errorDe('apellido') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="usuario-apodo">
            Apodo{{ esObligatorio('apodo') ? ' *' : '' }}
          </label>
          <input
            id="usuario-apodo"
            ref="apodoInput"
            v-model="formulario.apodo"
            class="form-control"
            :class="{ 'is-invalid': errorDe('apodo') }"
            type="text"
            name="apodo"
            maxlength="80"
            autocomplete="nickname"
            :required="esObligatorio('apodo')"
            :aria-invalid="Boolean(errorDe('apodo'))"
            :aria-describedby="errorDe('apodo') ? 'error-apodo' : null"
            @input="limpiarError('apodo')"
          />
          <p v-if="errorDe('apodo')" id="error-apodo" class="campo__error">
            {{ errorDe('apodo') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="usuario-correo">Correo *</label>
          <input
            id="usuario-correo"
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
          <label class="form-label" for="usuario-telefono">
            Teléfono{{ esObligatorio('telefono') ? ' *' : '' }}
          </label>
          <input
            id="usuario-telefono"
            ref="telefonoInput"
            v-model="formulario.telefono"
            class="form-control"
            :class="{ 'is-invalid': errorDe('telefono') }"
            type="tel"
            name="telefono"
            maxlength="15"
            autocomplete="tel"
            :required="esObligatorio('telefono')"
            :aria-invalid="Boolean(errorDe('telefono'))"
            :aria-describedby="errorDe('telefono') ? 'error-telefono' : null"
            @input="limpiarError('telefono')"
          />
          <p v-if="errorDe('telefono')" id="error-telefono" class="campo__error">
            {{ errorDe('telefono') }}
          </p>
        </div>

        <div class="campo campo--documento">
          <div>
            <label class="form-label" for="usuario-tipo-documento">Tipo de documento *</label>
            <select
              id="usuario-tipo-documento"
              ref="tipoDocumentoInput"
              v-model="formulario.tipoDocumento"
              class="form-select"
              name="tipoDocumento"
              @change="limpiarError('tipoDocumento')"
            >
              <option value="dni">DNI</option>
              <option value="passport">Pasaporte</option>
              <option value="other">Otro</option>
            </select>
            <p v-if="errorDe('tipoDocumento')" class="campo__error">
              {{ errorDe('tipoDocumento') }}
            </p>
          </div>
          <div>
            <label class="form-label" for="usuario-documento">
              Número de documento{{ esObligatorio('numeroDocumento') ? ' *' : '' }}
            </label>
            <input
              id="usuario-documento"
              ref="numeroDocumentoInput"
              v-model="formulario.numeroDocumento"
              class="form-control"
              :class="{ 'is-invalid': errorDe('numeroDocumento') }"
              type="text"
              name="numeroDocumento"
              maxlength="12"
              :required="esObligatorio('numeroDocumento')"
              :aria-invalid="Boolean(errorDe('numeroDocumento'))"
              :aria-describedby="errorDe('numeroDocumento') ? 'error-documento' : null"
              @input="limpiarError('numeroDocumento')"
            />
            <p v-if="errorDe('numeroDocumento')" id="error-documento" class="campo__error">
              {{ errorDe('numeroDocumento') }}
            </p>
          </div>
        </div>

        <div class="campo">
          <label class="form-label" for="usuario-nacimiento">
            Fecha de nacimiento{{ esObligatorio('fechaNacimiento') ? ' *' : '' }}
          </label>
          <input
            id="usuario-nacimiento"
            ref="fechaNacimientoInput"
            v-model="formulario.fechaNacimiento"
            class="form-control"
            :class="{ 'is-invalid': errorDe('fechaNacimiento') }"
            type="date"
            name="fechaNacimiento"
            min="1900-01-01"
            :required="esObligatorio('fechaNacimiento')"
            :aria-invalid="Boolean(errorDe('fechaNacimiento'))"
            :aria-describedby="errorDe('fechaNacimiento') ? 'error-nacimiento' : null"
            @input="limpiarError('fechaNacimiento')"
          />
          <p v-if="errorDe('fechaNacimiento')" id="error-nacimiento" class="campo__error">
            {{ errorDe('fechaNacimiento') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="usuario-genero">
            Género{{ esObligatorio('genero') ? ' *' : '' }}
          </label>
          <select
            id="usuario-genero"
            ref="generoInput"
            v-model="formulario.genero"
            class="form-select"
            :class="{ 'is-invalid': errorDe('genero') }"
            name="genero"
            :disabled="enviando"
            :required="esObligatorio('genero')"
            :aria-invalid="Boolean(errorDe('genero'))"
            :aria-describedby="errorDe('genero') ? 'error-genero' : null"
            @change="limpiarError('genero')"
          >
            <option value="" :disabled="esObligatorio('genero')">
              {{ esObligatorio('genero') ? 'Selecciona el género' : 'Sin especificar' }}
            </option>
            <option value="Varon">Varón</option>
            <option value="Mujer">Mujer</option>
          </select>
          <p v-if="errorDe('genero')" id="error-genero" class="campo__error">
            {{ errorDe('genero') }}
          </p>
        </div>
        <template v-if="modo === 'edit'">
          <div class="campo">
            <label class="form-label" for="usuario-inicio-suscripcion">Inicio de suscripción</label>
            <input
              id="usuario-inicio-suscripcion"
              ref="inicioSuscripcionInput"
              v-model="formulario.inicioSuscripcion"
              class="form-control"
              type="date"
              name="inicioSuscripcion"
              :class="{ 'is-invalid': errorDe('inicioSuscripcion') }"
              :aria-invalid="Boolean(errorDe('inicioSuscripcion'))"
              @input="limpiarError('inicioSuscripcion')"
            />
            <p v-if="errorDe('inicioSuscripcion')" class="campo__error">
              {{ errorDe('inicioSuscripcion') }}
            </p>
          </div>
          <div class="campo">
            <label class="form-label" for="usuario-fin-suscripcion">Fin de suscripción</label>
            <input
              id="usuario-fin-suscripcion"
              ref="finSuscripcionInput"
              v-model="formulario.finSuscripcion"
              class="form-control"
              type="date"
              name="finSuscripcion"
              :class="{ 'is-invalid': errorDe('finSuscripcion') }"
              :aria-invalid="Boolean(errorDe('finSuscripcion'))"
              @input="limpiarError('finSuscripcion')"
            />
            <p v-if="errorDe('finSuscripcion')" class="campo__error">
              {{ errorDe('finSuscripcion') }}
            </p>
          </div>
        </template>
        <div class="campo campo--completo">
          <label class="form-label" for="usuario-direccion">Dirección</label>
          <textarea
            id="usuario-direccion"
            v-model="formulario.direccion"
            class="form-control"
            rows="2"
            maxlength="150"
            autocomplete="street-address"
          ></textarea>
        </div>
      </div>
    </section>

    <!-- Organización y acceso (solo en modo creación) -->
    <section
      v-if="modo === 'create'"
      class="formulario__seccion gb-tarjeta"
      aria-labelledby="titulo-organizacion"
    >
      <header>
        <span aria-hidden="true"><Building2 :size="20" /></span>
        <div>
          <h2 id="titulo-organizacion">Organización y acceso</h2>
          <p>Empresa, rol administrativo y estado operativo.</p>
        </div>
      </header>

      <div class="formulario__rejilla formulario__rejilla--organizacion">
        <div class="campo">
          <label class="form-label" for="usuario-empresa">Empresa *</label>
          <select
            id="usuario-empresa"
            ref="empresaInput"
            v-model="formulario.empresaId"
            class="form-select"
            :class="{ 'is-invalid': errorDe('empresaId') }"
            required
            :aria-invalid="Boolean(errorDe('empresaId'))"
            :aria-describedby="errorDe('empresaId') ? 'error-empresa' : null"
            @change="limpiarError('empresaId')"
          >
            <option value="">Selecciona una empresa</option>
            <option v-for="empresa in empresas" :key="empresa.id" :value="empresa.id">
              {{ empresa.nombre }}
            </option>
          </select>
          <p v-if="errorDe('empresaId')" id="error-empresa" class="campo__error">
            {{ errorDe('empresaId') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="usuario-rol">Rol *</label>
          <select
            id="usuario-rol"
            ref="rolInput"
            v-model="formulario.rol"
            class="form-select"
            :class="{ 'is-invalid': errorDe('rol') }"
            required
            :aria-invalid="Boolean(errorDe('rol'))"
            :aria-describedby="errorDe('rol') ? 'error-rol' : 'ayuda-rol'"
            @change="limpiarError('rol')"
          >
            <option v-for="opcion in roles" :key="opcion.valor" :value="opcion.valor">
              {{ opcion.etiqueta }}
            </option>
          </select>
          <p id="ayuda-rol" class="campo__ayuda">
            Define qué puede hacer la persona en el panel y en la app.
          </p>
          <p v-if="errorDe('rol')" id="error-rol" class="campo__error">{{ errorDe('rol') }}</p>
        </div>
      </div>

      <fieldset
        class="estado-opciones"
        aria-labelledby="titulo-estado"
        :aria-describedby="errorDe('estado') ? 'error-estado' : null"
      >
        <span id="titulo-estado" class="form-label">Estado *</span>
        <div>
          <label
            ><input
              ref="estadoInput"
              v-model="formulario.estado"
              type="radio"
              name="estado"
              value="active"
              @change="limpiarError('estado')"
            /><span><b>Activo</b><small>Puede acceder normalmente.</small></span></label
          >
          <label
            ><input
              v-model="formulario.estado"
              type="radio"
              name="estado"
              value="inactive"
              @change="limpiarError('estado')"
            /><span><b>Inactivo</b><small>Acceso suspendido.</small></span></label
          >
        </div>
      </fieldset>
      <p v-if="errorDe('estado')" id="error-estado" class="campo__error">
        {{ errorDe('estado') }}
      </p>
    </section>

    <div class="formulario__acciones">
      <button type="button" class="btn btn-secondary" :disabled="enviando" @click="emit('cancel')">
        Cancelar
      </button>
      <button type="submit" class="btn btn-primary" :disabled="enviando">
        <span v-if="enviando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        {{ enviando ? 'Guardando…' : modo === 'edit' ? 'Guardar cambios' : 'Guardar usuario' }}
      </button>
    </div>
  </form>
</template>

<style scoped>
.formulario {
  display: grid;
  gap: var(--gb-gutter, 1.25rem);
}
.formulario__seccion {
  padding: 1.25rem 1.5rem;
  border-radius: var(--gb-radius-xl);
}
.formulario__seccion > header {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
  min-height: 3.5rem;
  padding-bottom: 0.875rem;
  border-bottom: 1px solid var(--gb-border);
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
  flex-shrink: 0;
}
.formulario__seccion h2,
.formulario__seccion p {
  margin: 0;
}
.formulario__seccion h2 {
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}
.formulario__seccion header p {
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}
.formulario__rejilla {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}
.campo {
  min-width: 0;
}
.campo--completo {
  grid-column: 1 / -1;
}
.campo--documento {
  display: grid;
  grid-template-columns: minmax(9rem, 0.7fr) minmax(0, 1.3fr);
  gap: 0.75rem;
}
.campo__ayuda,
.campo__error {
  margin: 0.375rem 0 0 !important;
  font-size: var(--gb-tipo-xxs);
}
.campo__ayuda {
  color: var(--gb-text-muted);
}
.campo__error {
  color: var(--gb-error);
}
.estado-opciones {
  margin: 1rem 0 0;
  padding: 0;
  border: 0;
}
.estado-opciones > div {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.75rem;
  margin-top: 0.375rem;
}
.estado-opciones label {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 0.875rem;
  background: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  cursor: pointer;
}
.estado-opciones label:has(input:checked) {
  border-color: var(--gb-red);
  box-shadow: var(--gb-relieve);
}
.estado-opciones input {
  margin-top: 0.2rem;
  accent-color: var(--gb-red);
}
.estado-opciones label span {
  display: grid;
}
.estado-opciones b {
  font-size: var(--gb-tipo-sm);
}
.estado-opciones small {
  margin-top: 0.125rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
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
  background: var(--gb-bg);
  border-top: 1px solid var(--gb-border);
}
.formulario__acciones::after {
  position: absolute;
  top: 100%;
  right: 0;
  left: 0;
  height: var(--gb-margen);
  background: var(--gb-bg);
  content: '';
  pointer-events: none;
}
.formulario__acciones .btn {
  min-height: 2.6rem;
  padding-inline: 1.25rem;
}
.usuario-avatar-bloque {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1.25rem 1.5rem;
  margin-bottom: 1.5rem;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.03) 0%, rgba(255, 255, 255, 0.01) 100%);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-xl);
}
.usuario-avatar-marco {
  position: relative;
  flex-shrink: 0;
}
.usuario-avatar-vista {
  display: grid;
  place-items: center;
  width: 5.5rem;
  height: 5.5rem;
  border-radius: var(--gb-radius-full, 9999px);
  border: 2px dashed var(--gb-border);
  background-color: var(--gb-surface-lowest);
  color: var(--gb-text-soft);
  overflow: hidden;
  cursor: pointer;
  transition: all var(--gb-transicion, 0.2s ease);
}
.usuario-avatar-vista:hover {
  border-color: var(--gb-red);
  transform: scale(1.02);
}
.usuario-avatar-vista--con-imagen {
  border: 2px solid var(--gb-red);
  box-shadow: 0 0 20px rgba(var(--gb-red-rgb), 0.25);
}
.usuario-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.usuario-avatar-icono {
  color: var(--gb-text-soft);
}
.usuario-avatar-camara {
  position: absolute;
  bottom: -0.15rem;
  right: -0.15rem;
  display: grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  border-radius: var(--gb-radius-full, 9999px);
  border: 2px solid var(--gb-surface-highest, #1a1a1a);
  background-color: var(--gb-red);
  color: var(--gb-on-red, #ffffff);
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.6);
  transition: all var(--gb-transicion, 0.2s ease);
}
.usuario-avatar-camara:hover {
  transform: scale(1.1);
  background-color: var(--gb-red-hover, #ff1a26);
}
.usuario-avatar-info {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  min-width: 0;
}
.usuario-avatar-cabecera {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.usuario-avatar-titulo {
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gb-text-soft);
}
.usuario-avatar-nombre-vista {
  font-size: var(--gb-tipo-xs);
  font-weight: 600;
  color: var(--gb-text);
}
.usuario-avatar-acciones {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.625rem;
}
.usuario-avatar-acciones .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-weight: 600;
  font-size: var(--gb-tipo-xs);
  padding: 0.375rem 0.875rem;
  border-radius: var(--gb-radius-md);
}
.usuario-avatar-ayuda {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  line-height: 1.4;
}
.usuario-avatar-estado {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  margin: 0;
  color: var(--gb-red-text, #ff6b72);
  font-size: var(--gb-tipo-xs);
}
@media (max-width: 64rem) {
  .formulario__acciones::after {
    height: var(--gb-gutter);
  }
}
@media (max-width: 52rem) {
  .formulario__rejilla,
  .estado-opciones > div {
    grid-template-columns: 1fr;
  }
  .campo--completo {
    grid-column: auto;
  }
}
@media (max-width: 36rem) {
  .usuario-avatar-bloque {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
    padding: 1rem;
  }
  .campo--documento {
    grid-template-columns: 1fr;
  }
}
</style>
