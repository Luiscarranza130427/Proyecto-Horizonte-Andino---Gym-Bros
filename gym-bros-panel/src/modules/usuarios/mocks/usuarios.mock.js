import { HttpError } from '@/core/api/http-error'

const LATENCIA_MINIMA = 250
const LATENCIA_MAXIMA = 600
const CORREO_VALIDO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const TELEFONO_VALIDO = /^\+?[0-9\s-]+$/
const DOCUMENTO_VALIDO = /^[a-z0-9-]{4,20}$/i
const ESTADOS = ['active', 'inactive']
const ROLES = ['admin', 'manager', 'trainer', 'member']
const TIPOS_DOCUMENTO = ['dni', 'passport', 'other']
const ESTADOS_SUSCRIPCION = ['active', 'expiring', 'expired', 'none']

const EMPRESAS = [
  { id: 1, nombre: 'Power Gym' },
  { id: 2, nombre: 'Iron House' },
  { id: 3, nombre: 'Titan Fitness' },
  { id: 4, nombre: 'Apex Athletics' },
  { id: 5, nombre: 'Andes Training Club' },
  { id: 6, nombre: 'Norte Fit Center' },
  { id: 7, nombre: 'Pacífico Wellness' },
  { id: 8, nombre: 'Fuerza Sur' },
]

const PERSONAS = [
  ['Carlos', 'Ramírez'],
  ['Andrea', 'Mendoza'],
  ['Luis', 'Paredes'],
  ['Valentina', 'Torres'],
  ['Diego', 'Salazar'],
  ['Camila', 'Vargas'],
  ['Sebastián', 'Ríos'],
  ['Lucía', 'Campos'],
  ['Mateo', 'Navarro'],
  ['Daniela', 'Flores'],
  ['Joaquín', 'Silva'],
  ['Adriana', 'Lozano'],
  ['Nicolás', 'Vega'],
  ['Fernanda', 'Ortiz'],
  ['Martín', 'Cáceres'],
  ['Ximena', 'Castro'],
  ['Renzo', 'Aguirre'],
  ['Gabriela', 'Fuentes'],
  ['Alejandro', 'León'],
  ['Natalia', 'Cabrera'],
  ['Rodrigo', 'Peña'],
  ['Paola', 'Mendoza'],
  ['Santiago', 'Medina'],
  ['Claudia', 'Espinoza'],
  ['Emilio', 'Vargas'],
  ['Mariana', 'Torres'],
  ['Bruno', 'Herrera'],
  ['Valeria', 'Campos'],
  ['José', 'Gutiérrez'],
  ['Fiorella', 'Sánchez'],
]

const SIN_TILDES = (valor) =>
  String(valor)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()

function crearSuscripcion(indice) {
  const estado = ESTADOS_SUSCRIPCION[indice % ESTADOS_SUSCRIPCION.length]
  if (estado === 'none') {
    return {
      estado,
      fechaInicio: '',
      fechaVencimiento: '',
      diasRestantes: 0,
      nombrePlan: '',
    }
  }

  const diasRestantes = estado === 'active' ? 18 + (indice % 13) : estado === 'expiring' ? 3 : 0
  return {
    estado,
    fechaInicio: estado === 'expired' ? '2026-06-01' : '2026-08-01',
    fechaVencimiento:
      estado === 'expired' ? '2026-07-01' : `2026-09-${String(1 + (indice % 8)).padStart(2, '0')}`,
    diasRestantes,
    nombrePlan: indice % 3 === 0 ? 'Trimestral' : 'Mensual',
  }
}

const USUARIOS_INICIALES = PERSONAS.map(([nombre, apellido], indice) => {
  const id = indice + 1
  const empresa = EMPRESAS[indice % EMPRESAS.length]
  const correoBase = `${SIN_TILDES(nombre)}.${SIN_TILDES(apellido)}`.replace(/[^a-z0-9.]/g, '')

  return {
    id,
    nombre,
    apellido,
    correo: `${correoBase}@gymbros.test`,
    tipoDocumento: 'dni',
    numeroDocumento: String(71000000 + id),
    telefono: `+51 9${String(20000000 + id).padStart(8, '0')}`,
    direccion: `Av. Principal ${100 + id}, Lima`,
    fotoPerfil: '',
    fechaNacimiento: `${1988 + (indice % 14)}-${String(1 + (indice % 12)).padStart(2, '0')}-${String(1 + (indice % 27)).padStart(2, '0')}`,
    fechaRegistro: `2026-${String(1 + (indice % 8)).padStart(2, '0')}-${String(1 + (indice % 24)).padStart(2, '0')}`,
    rol: ROLES[indice % ROLES.length],
    estado: indice % 7 === 0 ? 'inactive' : 'active',
    empresa: { ...empresa },
    suscripcion: crearSuscripcion(indice),
    actividad: {
      rutinas: 1 + (indice % 6),
      asistenciasMes: indice % 14,
      ultimaActividad:
        indice % 5 === 0 ? '' : `2026-08-${String(25 - (indice % 10)).padStart(2, '0')}T18:30:00Z`,
    },
  }
})

let usuarios = structuredClone(USUARIOS_INICIALES)
let siguienteError = null
let secuenciaHistorial = 100
let historiales = crearHistorialesIniciales()

const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function crearHistorialesIniciales() {
  return new Map(
    USUARIOS_INICIALES.map((usuario) => [
      usuario.id,
      [
        {
          id: usuario.id,
          fecha: `${usuario.fechaRegistro}T10:00:00Z`,
          accion: 'created',
          descripcion: 'Usuario registrado en Gym Bros.',
          autor: 'Administrador Demo',
        },
      ],
    ]),
  )
}

function calcularLatencia() {
  return Math.floor(LATENCIA_MINIMA + Math.random() * (LATENCIA_MAXIMA - LATENCIA_MINIMA + 1))
}

async function prepararRespuesta() {
  await esperar(calcularLatencia())
  if (siguienteError) {
    const error = siguienteError
    siguienteError = null
    throw error
  }
}

function clonar(datos) {
  return structuredClone(datos)
}

function texto(valor) {
  return String(valor ?? '').trim()
}

function normalizarPagina(valor, porDefecto) {
  const numero = Number.parseInt(valor, 10)
  return Number.isFinite(numero) && numero > 0 ? numero : porDefecto
}

function buscarUsuario(id) {
  const usuario = usuarios.find((item) => item.id === Number(id))
  if (!usuario) {
    throw new HttpError(404, 'El usuario solicitado no existe.')
  }
  return usuario
}

function normalizarEmpresa(empresa, empresaId) {
  const id = Number(empresaId ?? empresa?.id)
  const existente = EMPRESAS.find((item) => item.id === id)
  return existente ? { ...existente } : { id, nombre: texto(empresa?.nombre) }
}

function validarUsuario(payload, idIgnorado = null) {
  const errores = {}
  const requeridos = [
    'nombre',
    'apellido',
    'correo',
    'tipoDocumento',
    'numeroDocumento',
    'telefono',
    'empresaId',
    'rol',
  ]

  requeridos.forEach((campo) => {
    if (!texto(payload[campo])) errores[campo] = ['Este campo es obligatorio.']
  })

  const correo = texto(payload.correo).toLowerCase()
  const documento = texto(payload.numeroDocumento)
  const telefono = texto(payload.telefono)
  const digitosTelefono = telefono.replace(/\D/g, '')

  if (correo && !CORREO_VALIDO.test(correo)) errores.correo = ['Ingresa un correo válido.']
  if (payload.tipoDocumento && !TIPOS_DOCUMENTO.includes(payload.tipoDocumento)) {
    errores.tipoDocumento = ['El tipo de documento seleccionado no es válido.']
  }
  if (documento && payload.tipoDocumento === 'dni' && !/^\d{8}$/.test(documento)) {
    errores.numeroDocumento = ['El DNI debe contener 8 dígitos.']
  } else if (documento && !DOCUMENTO_VALIDO.test(documento)) {
    errores.numeroDocumento = ['El documento debe contener entre 4 y 20 caracteres válidos.']
  }
  if (
    telefono &&
    (!TELEFONO_VALIDO.test(telefono) || digitosTelefono.length < 7 || digitosTelefono.length > 15)
  ) {
    errores.telefono = ['Ingresa un teléfono válido.']
  }
  if (payload.fechaNacimiento && payload.fechaNacimiento > new Date().toISOString().slice(0, 10)) {
    errores.fechaNacimiento = ['La fecha de nacimiento no puede ser futura.']
  }
  if (payload.estado && !ESTADOS.includes(payload.estado)) {
    errores.estado = ['El estado seleccionado no es válido.']
  }
  if (payload.rol && !ROLES.includes(payload.rol)) {
    errores.rol = ['El rol seleccionado no es válido.']
  }
  if (payload.empresaId && !EMPRESAS.some(({ id }) => id === Number(payload.empresaId))) {
    errores.empresaId = ['La empresa seleccionada no existe.']
  }
  if (
    correo &&
    usuarios.some((usuario) => usuario.id !== idIgnorado && usuario.correo === correo)
  ) {
    errores.correo = ['El correo ya se encuentra registrado.']
  }
  if (
    documento &&
    usuarios.some((usuario) => usuario.id !== idIgnorado && usuario.numeroDocumento === documento)
  ) {
    errores.numeroDocumento = ['El documento ya se encuentra registrado.']
  }

  if (Object.keys(errores).length) {
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  }
}

function agregarHistorial(usuarioId, accion, descripcion) {
  secuenciaHistorial += 1
  const evento = {
    id: secuenciaHistorial,
    fecha: new Date().toISOString(),
    accion,
    descripcion,
    autor: 'Administrador Demo',
  }
  historiales.set(usuarioId, [evento, ...(historiales.get(usuarioId) ?? [])])
}

export function simularSiguienteErrorUsuariosMock(status = 500) {
  siguienteError = new HttpError(
    status,
    status === 500
      ? 'No pudimos procesar la solicitud de usuarios.'
      : 'Solicitud simulada fallida.',
  )
}

export function restablecerUsuariosMock() {
  usuarios = structuredClone(USUARIOS_INICIALES)
  historiales = crearHistorialesIniciales()
  secuenciaHistorial = 100
  siguienteError = null
}

export async function obtenerUsuariosMock({
  busqueda = '',
  empresaId = '',
  estado = '',
  rol = '',
  suscripcion = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  await prepararRespuesta()

  const termino = SIN_TILDES(texto(busqueda))
  const paginaSolicitada = normalizarPagina(pagina, 1)
  const cantidadPorPagina = Math.min(normalizarPagina(porPagina, 10), 100)
  const coincidencias = usuarios.filter((usuario) => {
    const contenido = SIN_TILDES(
      [usuario.nombre, usuario.apellido, usuario.correo, usuario.numeroDocumento].join(' '),
    )
    return (
      (!termino || contenido.includes(termino)) &&
      (!empresaId || usuario.empresa.id === Number(empresaId)) &&
      (!estado || usuario.estado === estado) &&
      (!rol || usuario.rol === rol) &&
      (!suscripcion || usuario.suscripcion.estado === suscripcion)
    )
  })
  const total = coincidencias.length
  const ultimaPagina = Math.max(1, Math.ceil(total / cantidadPorPagina))
  const paginaActual = Math.min(paginaSolicitada, ultimaPagina)
  const inicio = (paginaActual - 1) * cantidadPorPagina
  const items = coincidencias.slice(inicio, inicio + cantidadPorPagina)

  return clonar({
    items,
    paginacion: {
      pagina: paginaActual,
      ultimaPagina,
      porPagina: cantidadPorPagina,
      total,
      desde: total ? inicio + 1 : 0,
      hasta: total ? inicio + items.length : 0,
    },
  })
}

export async function obtenerUsuarioMock(id) {
  await prepararRespuesta()
  return clonar(buscarUsuario(id))
}

export async function crearUsuarioMock(payload) {
  await prepararRespuesta()
  const empresaId = payload.empresaId ?? payload.empresa?.id
  const datos = {
    ...payload,
    correo: texto(payload.correo).toLowerCase(),
    numeroDocumento: texto(payload.numeroDocumento),
    empresaId: empresaId === undefined || empresaId === null ? '' : Number(empresaId),
  }
  validarUsuario(datos)

  const id = usuarios.reduce((maximo, usuario) => Math.max(maximo, usuario.id), 0) + 1
  const nuevoUsuario = {
    id,
    nombre: texto(datos.nombre),
    apellido: texto(datos.apellido),
    correo: datos.correo,
    tipoDocumento: datos.tipoDocumento,
    numeroDocumento: datos.numeroDocumento,
    telefono: texto(datos.telefono),
    direccion: texto(datos.direccion),
    fotoPerfil: texto(datos.fotoPerfil),
    fechaNacimiento: texto(datos.fechaNacimiento),
    fechaRegistro: new Date().toISOString().slice(0, 10),
    rol: datos.rol,
    estado: datos.estado || 'active',
    empresa: normalizarEmpresa(datos.empresa, datos.empresaId),
    suscripcion: datos.suscripcion
      ? clonar(datos.suscripcion)
      : {
          estado: 'none',
          fechaInicio: '',
          fechaVencimiento: '',
          diasRestantes: 0,
          nombrePlan: '',
        },
    actividad: { rutinas: 0, asistenciasMes: 0, ultimaActividad: '' },
  }
  usuarios = [nuevoUsuario, ...usuarios]
  historiales.set(id, [])
  agregarHistorial(id, 'created', 'Usuario registrado en Gym Bros.')
  return clonar(nuevoUsuario)
}

export async function actualizarUsuarioMock(id, payload) {
  await prepararRespuesta()
  const usuario = buscarUsuario(id)
  const datos = {
    ...usuario,
    ...payload,
    correo: texto(payload.correo ?? usuario.correo).toLowerCase(),
    numeroDocumento: texto(payload.numeroDocumento ?? usuario.numeroDocumento),
    empresaId: Number(payload.empresaId ?? payload.empresa?.id ?? usuario.empresa.id),
  }
  validarUsuario(datos, usuario.id)

  const actualizado = {
    ...usuario,
    ...payload,
    id: usuario.id,
    nombre: texto(datos.nombre),
    apellido: texto(datos.apellido),
    correo: datos.correo,
    numeroDocumento: datos.numeroDocumento,
    telefono: texto(datos.telefono),
    direccion: texto(datos.direccion),
    fotoPerfil: texto(datos.fotoPerfil),
    fechaNacimiento: texto(datos.fechaNacimiento),
    empresa: normalizarEmpresa(datos.empresa, datos.empresaId),
  }
  delete actualizado.empresaId
  usuarios = usuarios.map((item) => (item.id === usuario.id ? actualizado : item))
  agregarHistorial(usuario.id, 'updated', 'Se actualizaron los datos del usuario.')
  return clonar(actualizado)
}

export async function desactivarUsuarioMock(id) {
  await prepararRespuesta()
  const usuario = buscarUsuario(id)
  const desactivado = { ...usuario, estado: 'inactive' }
  usuarios = usuarios.map((item) => (item.id === usuario.id ? desactivado : item))
  agregarHistorial(usuario.id, 'deactivated', 'El usuario fue desactivado.')
  return clonar(desactivado)
}

export async function obtenerHistorialUsuarioMock(id) {
  await prepararRespuesta()
  const usuario = buscarUsuario(id)
  return clonar(historiales.get(usuario.id) ?? [])
}
