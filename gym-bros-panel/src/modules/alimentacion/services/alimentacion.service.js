import api from '@/core/api/api'
import { HttpError } from '@/core/api/http-error'
import {
  crearNormalizadorDeError,
  ejecutarPeticion as ejecutar,
  normalizarListado as normalizarListadoBase,
  seleccionarCamposEditables as seleccionarEditables,
} from '@/core/api/normalizacion'
import { USE_MOCKS } from '@/core/config/env'

const cargarMock = () => import('@/modules/alimentacion/mocks/alimentacion.mock')

const CAMPOS_ERROR_ALIMENTO = {
  name: 'nombre',
  type: 'tipo',
  calories: 'calorias',
  protein: 'proteinas',
  proteina: 'proteinas',
  carbs: 'carbohidratos',
  carbohydrates: 'carbohidratos',
  fat: 'grasas',
  fats: 'grasas',
  fiber: 'fibra',
  activo: 'activo',
  base_unidad: 'unidadBase',
  estado_preparacion: 'estadoPreparacion',
  gramos_por_unidad: 'gramosPorUnidad',
  densidad_g_ml: 'densidadGml',
  fuente_nutricional: 'fuenteNutricional',
  nutricion_verificada: 'nutricionVerificada',
  restricciones_verificadas: 'restriccionesVerificadas',
  grupo_menu: 'grupoMenu',
  tipos_comida: 'tiposComida',
  'tipos_comida.*': 'tiposComida',
  porcion_min: 'porcionMin',
  porcion_max: 'porcionMax',
  paso_porcion: 'pasoPorcion',
}

const CAMPOS_ERROR_COMIDA = {
  meal_type: 'tipoComida',
  tipo_comida: 'tipoComida',
  suggested_time: 'horaSugerida',
  hora_sugerida: 'horaSugerida',
  order: 'orden',
  foods: 'alimentos',
  comida_alimentos: 'alimentos',
}

const CAMPOS_EDITABLES_ALIMENTO = [
  'nombre',
  'tipo',
  'calorias',
  'proteinas',
  'carbohidratos',
  'grasas',
  'fibra',
  'activo',
  'unidadBase',
  'estadoPreparacion',
  'gramosPorUnidad',
  'densidadGml',
  'fuenteNutricional',
  'nutricionVerificada',
  'restriccionesVerificadas',
  'grupoMenu',
  'tiposComida',
  'porcionMin',
  'porcionMax',
  'pasoPorcion',
]

const numero = (valor) => {
  const convertido = Number(valor)
  return Number.isFinite(convertido) ? convertido : 0
}

function normalizarMacros(datos = {}) {
  return {
    calorias: numero(datos.calorias ?? datos.calories),
    proteinas: numero(datos.proteinas ?? datos.protein),
    carbohidratos: numero(datos.carbohidratos ?? datos.carbs ?? datos.carbohydrates),
    grasas: numero(datos.grasas ?? datos.fat ?? datos.fats),
    fibra: numero(datos.fibra ?? datos.fiber),
  }
}

function normalizarRelacion(datos) {
  if (!datos) return null
  return {
    id: Number(datos.id) || null,
    nombre: datos.nombre ?? datos.name ?? '',
  }
}

function normalizarAlimento(datos = {}) {
  const camposAdicionales = {
    activo: datos.activo,
    estadoPreparacion: datos.estadoPreparacion ?? datos.estado_preparacion,
    gramosPorUnidad: datos.gramosPorUnidad ?? datos.gramos_por_unidad,
    densidadGml: datos.densidadGml ?? datos.densidad_g_ml,
    fuenteNutricional: datos.fuenteNutricional ?? datos.fuente_nutricional,
    nutricionVerificada: datos.nutricionVerificada ?? datos.nutricion_verificada,
    restriccionesVerificadas: datos.restriccionesVerificadas ?? datos.restricciones_verificadas,
    grupoMenu: datos.grupoMenu ?? datos.grupo_menu,
    tiposComida: datos.tiposComida ?? datos.tipos_comida,
    porcionMin: datos.porcionMin ?? datos.porcion_min,
    porcionMax: datos.porcionMax ?? datos.porcion_max,
    pasoPorcion: datos.pasoPorcion ?? datos.paso_porcion,
  }

  return {
    id: datos.id,
    nombre: datos.nombre ?? datos.name ?? '',
    tipo: datos.tipo ?? datos.type ?? '',
    ...normalizarMacros(datos),
    unidadBase: datos.unidadBase ?? datos.unidad_base ?? datos.base_unidad ?? 'gramos',
    usos: numero(datos.usos ?? datos.usos_count),
    ...Object.fromEntries(
      Object.entries(camposAdicionales).filter(([, valor]) => valor !== undefined),
    ),
  }
}

function normalizarPorcion(datos = {}) {
  return {
    id: datos.id,
    alimento: {
      ...normalizarRelacion(datos.alimento ?? datos.food ?? {}),
      tipo: datos.alimento?.tipo ?? datos.food?.type ?? '',
    },
    cantidad: numero(datos.cantidad ?? datos.quantity ?? datos.amount),
    unidad: datos.unidad ?? datos.unit ?? 'gramos',
    macros: normalizarMacros(datos.macros ?? datos),
  }
}

function normalizarComida(datos = {}) {
  const alimentos = (datos.alimentos ?? datos.foods ?? []).map(normalizarPorcion)
  return {
    id: datos.id,
    tipoComida: datos.tipoComida ?? datos.tipo_comida ?? datos.meal_type ?? '',
    horaSugerida: datos.horaSugerida ?? datos.hora_sugerida ?? datos.suggested_time ?? '',
    orden: numero(datos.orden ?? datos.order),
    alimentos,
    macros: normalizarMacros(datos.macros ?? {}),
  }
}

function normalizarPlan(datos = {}) {
  return {
    id: datos.id,
    usuario: normalizarRelacion(datos.usuario ?? datos.user),
    empresa: normalizarRelacion(datos.empresa ?? datos.company),
    objetivo: datos.objetivo ?? datos.goal ?? '',
    fechaInicio: datos.fechaInicio ?? datos.fecha_inicio ?? datos.start_date ?? '',
    fechaFin: datos.fechaFin ?? datos.fecha_fin ?? datos.end_date ?? '',
    activo: Boolean(datos.activo ?? datos.active ?? false),
    objetivos: {
      calorias: numero(datos.caloriasObjetivo ?? datos.calorias_objetivo),
      proteinas: numero(datos.proteinasObjetivo ?? datos.proteinas_objetivo),
      carbohidratos: numero(datos.carbohidratosObjetivo ?? datos.carbohidratos_objetivo),
      grasas: numero(datos.grasasObjetivo ?? datos.grasas_objetivo),
    },
    totalComidas: numero(datos.totalComidas ?? datos.comidas_count),
    macros: normalizarMacros(datos.macros ?? {}),
  }
}

function normalizarPlanCompleto(datos = {}) {
  const comidas = (datos.comidas ?? datos.meals ?? []).map(normalizarComida)
  return { ...normalizarPlan(datos), comidas, totalComidas: comidas.length }
}

function prepararParametrosAlimento({ busqueda = '', tipo = '', pagina = 1, porPagina = 12 } = {}) {
  return { search: busqueda, type: tipo, page: pagina, per_page: porPagina }
}

function prepararParametrosPlan({
  busqueda = '',
  situacion = '',
  empresaId = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  return {
    search: busqueda,
    activo: situacion === '' ? undefined : situacion === 'activo',
    id_empresas: empresaId,
    page: pagina,
    per_page: porPagina,
  }
}

function prepararPayloadAlimento(payload) {
  const camposBase = {
    nombre: payload.nombre,
    tipo: payload.tipo,
    calorias: payload.calorias,
    proteinas: payload.proteinas,
    carbohidratos: payload.carbohidratos,
    grasas: payload.grasas,
    fibra: payload.fibra,
  }
  const camposAdicionales = {
    activo: payload.activo,
    base_unidad: payload.unidadBase,
    estado_preparacion: payload.estadoPreparacion,
    gramos_por_unidad: payload.gramosPorUnidad,
    densidad_g_ml: payload.densidadGml,
    fuente_nutricional: payload.fuenteNutricional,
    nutricion_verificada: payload.nutricionVerificada,
    restricciones_verificadas: payload.restriccionesVerificadas,
    grupo_menu: payload.grupoMenu,
    tipos_comida: payload.tiposComida,
    porcion_min: payload.porcionMin,
    porcion_max: payload.porcionMax,
    paso_porcion: payload.pasoPorcion,
  }

  return {
    ...camposBase,
    ...Object.fromEntries(
      Object.entries(camposAdicionales).filter(([, valor]) => valor !== undefined),
    ),
  }
}

function prepararPayloadComida(payload) {
  return {
    tipo_comida: payload.tipoComida,
    hora_sugerida: payload.horaSugerida,
    alimentos: (payload.alimentos ?? []).map((porcion) => ({
      id_alimentos: porcion.alimentoId,
      cantidad: porcion.cantidad,
      unidad: porcion.unidad,
    })),
  }
}

const errorDeAlimento = crearNormalizadorDeError(CAMPOS_ERROR_ALIMENTO)
const errorDeComida = crearNormalizadorDeError(CAMPOS_ERROR_COMIDA)
const peticionDeAlimento = (peticion) => ejecutar(peticion, errorDeAlimento)
const peticionDeComida = (peticion) => ejecutar(peticion, errorDeComida)
const camposEditablesDeAlimento = (payload) =>
  seleccionarEditables(payload, CAMPOS_EDITABLES_ALIMENTO)

export async function obtenerAlimentos(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerAlimentosMock(params)

  return peticionDeAlimento(async () => {
    const { data } = await api.get('/alimentos', { params: prepararParametrosAlimento(params) })
    return normalizarListadoBase(data, normalizarAlimento)
  })
}

export async function obtenerAlimento(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerAlimentoMock(id)

  return peticionDeAlimento(async () => {
    const { data } = await api.get('/alimentos')
    const { items } = normalizarListadoBase(data, normalizarAlimento)
    const alimento = items.find((item) => String(item.id) === String(id))

    if (!alimento) {
      throw new HttpError(404, 'El alimento solicitado no existe.')
    }

    return alimento
  })
}

export async function crearAlimento(payload) {
  const datosEditables = camposEditablesDeAlimento(payload)
  if (USE_MOCKS) return (await cargarMock()).crearAlimentoMock(datosEditables)

  return peticionDeAlimento(async () => {
    const { data } = await api.post('/alimentos', prepararPayloadAlimento(datosEditables))
    return normalizarAlimento(data.data ?? data)
  })
}

export async function actualizarAlimento(id, payload) {
  const datosEditables = camposEditablesDeAlimento(payload)
  if (USE_MOCKS) return (await cargarMock()).actualizarAlimentoMock(id, datosEditables)

  return peticionDeAlimento(async () => {
    const { data } = await api.put(`/alimentos/${id}`, prepararPayloadAlimento(datosEditables))
    return normalizarAlimento(data.data ?? data)
  })
}

export async function eliminarAlimento(id) {
  if (USE_MOCKS) return (await cargarMock()).eliminarAlimentoMock(id)

  return peticionDeAlimento(async () => {
    const { data } = await api.delete(`/alimentos/${id}`)
    return normalizarAlimento(data?.data ?? data ?? { id })
  })
}

export async function obtenerPlanes(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerPlanesMock(params)

  return peticionDeAlimento(async () => {
    const { data } = await api.get('/planes-alimentacion', {
      params: prepararParametrosPlan(params),
    })
    return normalizarListadoBase(data, normalizarPlan)
  })
}

export async function obtenerPlan(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerPlanMock(id)

  return peticionDeAlimento(async () => {
    const { data } = await api.get(`/planes-alimentacion/${id}`)
    return normalizarPlanCompleto(data.data ?? data)
  })
}

export async function crearComida(idPlan, payload) {
  if (USE_MOCKS) return (await cargarMock()).crearComidaMock(idPlan, payload)

  return peticionDeComida(async () => {
    const { data } = await api.post(
      `/planes-alimentacion/${idPlan}/comidas`,
      prepararPayloadComida(payload),
    )
    return normalizarComida(data.data ?? data)
  })
}

export async function actualizarComida(idPlan, idComida, payload) {
  if (USE_MOCKS) return (await cargarMock()).actualizarComidaMock(idPlan, idComida, payload)

  return peticionDeComida(async () => {
    const { data } = await api.put(
      `/planes-alimentacion/${idPlan}/comidas/${idComida}`,
      prepararPayloadComida(payload),
    )
    return normalizarComida(data.data ?? data)
  })
}

export async function eliminarComida(idPlan, idComida) {
  if (USE_MOCKS) return (await cargarMock()).eliminarComidaMock(idPlan, idComida)

  return peticionDeComida(async () => {
    const { data } = await api.delete(`/planes-alimentacion/${idPlan}/comidas/${idComida}`)
    return normalizarComida(data?.data ?? data ?? { id: idComida })
  })
}

export async function obtenerAlimentosParaElegir() {
  if (USE_MOCKS) return (await cargarMock()).obtenerAlimentosParaElegirMock()

  const { data } = await api.get('/alimentos/para-elegir')
  const lista = data.data ?? data
  return Array.isArray(lista) ? lista.map(normalizarAlimento) : []
}

export async function obtenerEmpresasConPlanes() {
  if (USE_MOCKS) return (await cargarMock()).obtenerEmpresasConPlanesMock()

  const { data } = await api.get('/planes-alimentacion/empresas')
  const lista = data.data ?? data
  return Array.isArray(lista) ? lista.map(normalizarRelacion) : []
}
