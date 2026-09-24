import { HttpError } from '@/core/api/http-error'

const LATENCIA_MINIMA = 220
const LATENCIA_MAXIMA = 520

const PLANES_INICIALES = [
  {
    id: 1,
    nombre: 'Impulso',
    descripcion: 'Las herramientas esenciales para gimnasios que están comenzando a digitalizarse.',
    precioOriginal: 249,
    precioInicial: 189,
    duracionDias: 30,
    limiteUsuarios: 100,
    activo: true,
    contenido:
      'Gestión de usuarios\nRutinas y ejercicios\nPlanes de alimentación\nSoporte por WhatsApp',
    enlaceWhatsapp: 'https://wa.me/51900000001',
  },
  {
    id: 2,
    nombre: 'Fuerza',
    descripcion: 'Mayor capacidad y seguimiento para centros deportivos en crecimiento.',
    precioOriginal: 449,
    precioInicial: 349,
    duracionDias: 30,
    limiteUsuarios: 300,
    activo: true,
    contenido:
      'Gestión de usuarios\nRutinas y ejercicios\nPlanes de alimentación\nReportes administrativos\nAtención prioritaria',
    enlaceWhatsapp: 'https://wa.me/51900000002',
  },
  {
    id: 3,
    nombre: 'Titanio',
    descripcion: 'Operación completa para cadenas y gimnasios con una comunidad consolidada.',
    precioOriginal: 899,
    precioInicial: 699,
    duracionDias: 30,
    limiteUsuarios: 1000,
    activo: true,
    contenido:
      'Gestión de usuarios\nRutinas y ejercicios\nPlanes de alimentación\nReportes administrativos\nAcompañamiento de implementación\nSoporte especializado',
    enlaceWhatsapp: 'https://wa.me/51900000003',
  },
  {
    id: 4,
    nombre: 'Anual Pro',
    descripcion: 'Cobertura anual para empresas que prefieren una sola renovación.',
    precioOriginal: 4990,
    precioInicial: 3990,
    duracionDias: 365,
    limiteUsuarios: 500,
    activo: true,
    contenido:
      'Gestión de usuarios\nRutinas y ejercicios\nPlanes de alimentación\nReportes administrativos\nAtención prioritaria',
    enlaceWhatsapp: 'https://wa.me/51900000004',
  },
  {
    id: 5,
    nombre: 'Piloto',
    descripcion: 'Configuración temporal para validaciones comerciales y demostraciones.',
    precioOriginal: 99,
    precioInicial: 49,
    duracionDias: 15,
    limiteUsuarios: 30,
    activo: false,
    contenido: 'Gestión de usuarios\nRutinas y ejercicios\nSoporte por WhatsApp',
    enlaceWhatsapp: 'https://wa.me/51900000005',
  },
]

let planes = structuredClone(PLANES_INICIALES)

const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function calcularLatencia() {
  return Math.floor(LATENCIA_MINIMA + Math.random() * (LATENCIA_MAXIMA - LATENCIA_MINIMA + 1))
}

function clonar(datos) {
  return structuredClone(datos)
}

function texto(valor) {
  return String(valor ?? '').trim()
}

function enteroPositivo(valor) {
  const numero = Number(valor)
  return Number.isInteger(numero) && numero > 0
}

function precioValido(valor) {
  const numero = Number(valor)
  return Number.isFinite(numero) && numero >= 0
}

function urlValida(valor) {
  try {
    return ['http:', 'https:'].includes(new URL(valor).protocol)
  } catch {
    return false
  }
}

function validarPlan(payload) {
  const errores = {}
  const nombre = texto(payload.nombre)

  if (!nombre) errores.nombre = ['Este campo es obligatorio.']
  else if (nombre.length > 100) errores.nombre = ['El nombre no puede superar 100 caracteres.']

  if (!texto(payload.descripcion)) errores.descripcion = ['Este campo es obligatorio.']
  if (!precioValido(payload.precioOriginal)) {
    errores.precioOriginal = ['Introduce un precio igual o mayor que cero.']
  }
  if (!precioValido(payload.precioInicial)) {
    errores.precioInicial = ['Introduce un precio igual o mayor que cero.']
  }
  if (!enteroPositivo(payload.duracionDias)) {
    errores.duracionDias = ['Introduce una duración entera mayor que cero.']
  }
  if (!enteroPositivo(payload.limiteUsuarios)) {
    errores.limiteUsuarios = ['Introduce un límite entero mayor que cero.']
  }
  if (!texto(payload.contenido)) errores.servicios = ['Selecciona al menos un servicio.']
  if (!urlValida(texto(payload.enlaceWhatsapp))) {
    errores.enlaceWhatsapp = ['Introduce un enlace http o https válido.']
  }

  if (Object.keys(errores).length) {
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  }
}

function buscarPlan(id) {
  const plan = planes.find((item) => item.id === Number(id))
  if (!plan) throw new HttpError(404, 'El plan solicitado no existe.')
  return plan
}

function normalizarPagina(valor, porDefecto) {
  const numero = Number.parseInt(valor, 10)
  return Number.isFinite(numero) && numero > 0 ? numero : porDefecto
}

export function restablecerPlanesMock() {
  planes = structuredClone(PLANES_INICIALES)
}

export async function obtenerPlanesComercialesMock({
  busqueda = '',
  estado = '',
  pagina = 1,
  porPagina = 6,
} = {}) {
  await esperar(calcularLatencia())

  const termino = texto(busqueda).toLocaleLowerCase('es')
  const coincidencias = planes.filter((plan) => {
    const coincideTexto =
      !termino ||
      [plan.nombre, plan.descripcion, plan.contenido]
        .join(' ')
        .toLocaleLowerCase('es')
        .includes(termino)
    const coincideEstado =
      !estado ||
      estado === 'all' ||
      (estado === 'active' && plan.activo) ||
      (estado === 'inactive' && !plan.activo)

    return coincideTexto && coincideEstado
  })
  const cantidadPorPagina = Math.min(normalizarPagina(porPagina, 6), 100)
  const total = coincidencias.length
  const ultimaPagina = Math.max(1, Math.ceil(total / cantidadPorPagina))
  const paginaActual = Math.min(normalizarPagina(pagina, 1), ultimaPagina)
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

export async function obtenerPlanComercialMock(id) {
  await esperar(calcularLatencia())
  return clonar(buscarPlan(id))
}

export async function crearPlanComercialMock(payload) {
  await esperar(calcularLatencia())
  validarPlan(payload)

  const plan = {
    id: planes.reduce((maximo, item) => Math.max(maximo, item.id), 0) + 1,
    nombre: texto(payload.nombre),
    descripcion: texto(payload.descripcion),
    precioOriginal: Number(payload.precioOriginal),
    precioInicial: Number(payload.precioInicial),
    duracionDias: Number(payload.duracionDias),
    limiteUsuarios: Number(payload.limiteUsuarios),
    activo: payload.activo === true,
    contenido: texto(payload.contenido),
    enlaceWhatsapp: texto(payload.enlaceWhatsapp),
  }

  planes = [plan, ...planes]
  return clonar(plan)
}

export async function actualizarPlanComercialMock(id, payload) {
  await esperar(calcularLatencia())
  const existente = buscarPlan(id)
  const datos = { ...existente, ...payload }
  validarPlan(datos)

  const actualizado = {
    ...datos,
    id: existente.id,
    nombre: texto(datos.nombre),
    descripcion: texto(datos.descripcion),
    precioOriginal: Number(datos.precioOriginal),
    precioInicial: Number(datos.precioInicial),
    duracionDias: Number(datos.duracionDias),
    limiteUsuarios: Number(datos.limiteUsuarios),
    activo: datos.activo === true,
    contenido: texto(datos.contenido),
    enlaceWhatsapp: texto(datos.enlaceWhatsapp),
  }
  planes = planes.map((plan) => (plan.id === existente.id ? actualizado : plan))
  return clonar(actualizado)
}

export async function eliminarPlanComercialMock(id) {
  await esperar(calcularLatencia())
  const existente = buscarPlan(id)
  planes = planes.filter((plan) => plan.id !== existente.id)
  return clonar(existente)
}
