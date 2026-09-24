import { HttpError } from '@/core/api/http-error'

const LATENCIA_MINIMA = 250
const LATENCIA_MAXIMA = 600

export const CATEGORIAS = ['pecho', 'espalda', 'piernas', 'hombros', 'brazos', 'core', 'cardio']
export const NIVELES = ['principiante', 'intermedio', 'avanzado']
export const EQUIPOS = ['ninguno', 'mancuernas', 'barra', 'maquina', 'polea', 'kettlebell']

const CATALOGO_INICIAL = [
  ['Press de banca', 'pecho', 'intermedio', 'barra', 154],
  ['Press inclinado con mancuernas', 'pecho', 'intermedio', 'mancuernas', 88],
  ['Aperturas en polea', 'pecho', 'principiante', 'polea', 47],
  ['Flexiones', 'pecho', 'principiante', 'ninguno', 132],
  ['Jalón al pecho', 'espalda', 'principiante', 'polea', 94],
  ['Remo con barra', 'espalda', 'intermedio', 'barra', 76],
  ['Dominadas', 'espalda', 'avanzado', 'ninguno', 61],
  ['Remo en máquina', 'espalda', 'principiante', 'maquina', 53],
  ['Sentadilla', 'piernas', 'intermedio', 'barra', 142],
  ['Prensa de piernas', 'piernas', 'principiante', 'maquina', 105],
  ['Peso muerto', 'piernas', 'avanzado', 'barra', 119],
  ['Zancadas con mancuernas', 'piernas', 'intermedio', 'mancuernas', 64],
  ['Extensión de cuádriceps', 'piernas', 'principiante', 'maquina', 58],
  ['Curl femoral', 'piernas', 'principiante', 'maquina', 51],
  ['Press militar', 'hombros', 'intermedio', 'barra', 83],
  ['Elevaciones laterales', 'hombros', 'principiante', 'mancuernas', 97],
  ['Pájaros en polea', 'hombros', 'intermedio', 'polea', 39],
  ['Curl de bíceps con barra', 'brazos', 'principiante', 'barra', 91],
  ['Curl martillo', 'brazos', 'principiante', 'mancuernas', 72],
  ['Extensión de tríceps en polea', 'brazos', 'principiante', 'polea', 68],
  ['Fondos en paralelas', 'brazos', 'avanzado', 'ninguno', 44],
  ['Plancha abdominal', 'core', 'principiante', 'ninguno', 121],
  ['Rueda abdominal', 'core', 'avanzado', 'ninguno', 33],
  ['Elevaciones de piernas colgado', 'core', 'avanzado', 'ninguno', 28],
  ['Russian twist con kettlebell', 'core', 'intermedio', 'kettlebell', 41],
  ['Swing con kettlebell', 'cardio', 'intermedio', 'kettlebell', 79],
  ['Burpees', 'cardio', 'intermedio', 'ninguno', 86],
  ['Salto a cajón', 'cardio', 'avanzado', 'ninguno', 37],
  ['Cinta de correr', 'cardio', 'principiante', 'maquina', 110],
  ['Remo ergómetro', 'cardio', 'intermedio', 'maquina', 55],
]

const DESCRIPCIONES = {
  pecho: 'Trabajo de empuje horizontal para el pectoral mayor.',
  espalda: 'Trabajo de tracción para dorsal ancho y romboides.',
  piernas: 'Trabajo de tren inferior con énfasis en cuádriceps y glúteo.',
  hombros: 'Trabajo de deltoides con control escapular.',
  brazos: 'Trabajo aislado de bíceps o tríceps.',
  core: 'Estabilización del tronco y control lumbopélvico.',
  cardio: 'Trabajo metabólico de intensidad moderada a alta.',
}

function crearEjercicio([nombre, categoria, nivel, equipo, usos], indice) {
  const dia = String((indice % 27) + 1).padStart(2, '0')
  return {
    id: indice + 1,
    nombre,
    categoria,
    nivel,
    equipo,
    descripcion: DESCRIPCIONES[categoria],
    seriesSugeridas: categoria === 'cardio' ? 1 : 3 + (indice % 2),
    repeticionesSugeridas: categoria === 'cardio' ? 0 : 8 + (indice % 5) * 2,
    usos,
    estado: indice % 9 === 4 ? 'inactive' : 'active',
    fechaRegistro: `2026-0${(indice % 6) + 1}-${dia}`,
  }
}

let ejercicios = CATALOGO_INICIAL.map(crearEjercicio)
let secuencia = ejercicios.length
const estadosPorEmpresa = new Map()

const clonar = (valor) => structuredClone(valor)
const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function prepararRespuesta() {
  const rango = LATENCIA_MAXIMA - LATENCIA_MINIMA
  return esperar(LATENCIA_MINIMA + Math.floor(Math.random() * (rango + 1)))
}

const sinTildes = (valor) =>
  String(valor)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()

function buscarEjercicio(id) {
  const encontrado = ejercicios.find((ejercicio) => ejercicio.id === Number(id))
  if (!encontrado) {
    throw new HttpError(404, 'El ejercicio solicitado no existe.')
  }
  return encontrado
}

function validar(payload, idActual = null) {
  const errores = {}
  const nombre = String(payload.nombre ?? '').trim()

  if (nombre.length < 3) {
    errores.nombre = ['El nombre debe tener al menos 3 caracteres.']
  } else if (
    ejercicios.some(
      (ejercicio) => ejercicio.id !== idActual && sinTildes(ejercicio.nombre) === sinTildes(nombre),
    )
  ) {
    errores.nombre = ['Ya existe un ejercicio con este nombre.']
  }

  if (!NIVELES.includes(payload.nivel)) {
    errores.nivel = ['Selecciona un nivel válido.']
  }
  if (!String(payload.equipamiento ?? payload.equipo ?? '').trim()) {
    errores.equipamiento = ['Selecciona un equipamiento válido.']
  }

  if (Object.keys(errores).length > 0) {
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  }
}

export async function obtenerEjerciciosMock({
  busqueda = '',
  categoria = '',
  nivel = '',
  equipo = '',
  estado = '',
  empresaId = null,
  pagina = 1,
  porPagina = 10,
} = {}) {
  await prepararRespuesta()

  const termino = sinTildes(busqueda).trim()
  const filtrados = ejercicios.filter((ejercicio) => {
    const coincideTexto =
      !termino ||
      sinTildes(ejercicio.nombre).includes(termino) ||
      sinTildes(ejercicio.categoria).includes(termino)
    return (
      coincideTexto &&
      (!categoria || ejercicio.categoria === categoria) &&
      (!nivel || ejercicio.nivel === nivel) &&
      (!equipo || ejercicio.equipo === equipo) &&
      (!estado || ejercicio.estado === estado)
    )
  })

  const total = filtrados.length
  const ultimaPagina = Math.max(1, Math.ceil(total / porPagina))
  const paginaActual = Math.min(Math.max(1, Number(pagina) || 1), ultimaPagina)
  const desde = (paginaActual - 1) * porPagina
  const items = filtrados.slice(desde, desde + porPagina).map((ejercicio) => {
    const estadoEmpresa = empresaId
      ? estadosPorEmpresa.get(`${empresaId}:${ejercicio.id}`)
      : undefined
    return {
      ...ejercicio,
      estadoEmpresa: estadoEmpresa === undefined ? null : estadoEmpresa ? 'active' : 'inactive',
    }
  })

  return {
    items: clonar(items),
    paginacion: {
      pagina: paginaActual,
      ultimaPagina,
      porPagina,
      total,
      desde: total ? desde + 1 : 0,
      hasta: total ? desde + items.length : 0,
    },
  }
}

export async function obtenerEjercicioMock(id) {
  await prepararRespuesta()
  return clonar(buscarEjercicio(id))
}

export async function crearEjercicioMock(payload) {
  await prepararRespuesta()
  validar(payload)

  secuencia += 1
  const nuevo = {
    id: secuencia,
    nombre: String(payload.nombre).trim(),
    categoria: payload.categoria ?? '',
    tipo: payload.tipo ?? '',
    instrucciones: payload.instrucciones ?? '',
    nivel: payload.nivel,
    equipo: payload.equipamiento ?? payload.equipo,
    equipamiento: payload.equipamiento ?? payload.equipo,
    enlaceVideo: payload.enlaceVideo ?? '',
    imagenEjercicio: payload.imagenEjercicio ?? '',
    idGruposMusculares: payload.idGruposMusculares ?? '',
    descripcion: String(payload.descripcion ?? '').trim(),
    seriesSugeridas: Number(payload.seriesSugeridas) || 0,
    repeticionesSugeridas: Number(payload.repeticionesSugeridas) || 0,
    usos: 0,
    estado: payload.estado === 'inactive' ? 'inactive' : 'active',
    fechaRegistro: new Date().toISOString().slice(0, 10),
  }
  ejercicios = [nuevo, ...ejercicios]
  return clonar(nuevo)
}

export async function actualizarEjercicioMock(id, payload) {
  await prepararRespuesta()
  const ejercicio = buscarEjercicio(id)
  validar({ ...ejercicio, ...payload }, ejercicio.id)

  Object.assign(ejercicio, {
    nombre: String(payload.nombre ?? ejercicio.nombre).trim(),
    categoria: payload.categoria ?? ejercicio.categoria,
    nivel: payload.nivel ?? ejercicio.nivel,
    equipo: payload.equipo ?? ejercicio.equipo,
    descripcion: String(payload.descripcion ?? ejercicio.descripcion).trim(),
    seriesSugeridas: Number(payload.seriesSugeridas ?? ejercicio.seriesSugeridas),
    repeticionesSugeridas: Number(payload.repeticionesSugeridas ?? ejercicio.repeticionesSugeridas),
    estado: payload.estado ?? ejercicio.estado,
  })
  return clonar(ejercicio)
}

export async function desactivarEjercicioMock(id) {
  await prepararRespuesta()
  const ejercicio = buscarEjercicio(id)
  ejercicio.estado = 'inactive'
  return clonar(ejercicio)
}

export async function actualizarEstadoEjercicioEmpresaMock(empresaId, ejercicioId, estado) {
  await prepararRespuesta()
  buscarEjercicio(ejercicioId)
  const clave = `${empresaId}:${ejercicioId}`
  estadosPorEmpresa.set(clave, Boolean(estado))
  return {
    estadoEmpresa: estadosPorEmpresa.get(clave) ? 'active' : 'inactive',
    message: 'Estado del ejercicio actualizado para la empresa.',
  }
}

export function restablecerEjerciciosMock() {
  ejercicios = CATALOGO_INICIAL.map(crearEjercicio)
  secuencia = ejercicios.length
  estadosPorEmpresa.clear()
}
