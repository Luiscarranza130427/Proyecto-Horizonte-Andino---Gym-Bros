import api from '@/core/api/api'
import {
  crearNormalizadorDeError,
  ejecutarPeticion as ejecutar,
  normalizarEstado,
  normalizarListado as normalizarListadoBase,
  seleccionarCamposEditables as seleccionarEditables,
} from '@/core/api/normalizacion'
import { USE_MOCKS } from '@/core/config/env'
import { resolverUrlStorage } from '@/shared/utils/storage'

const cargarMock = () => import('@/modules/ejercicios/mocks/ejercicios.mock')

const CAMPOS_ERROR = {
  name: 'nombre',
  category: 'categoria',
  categoria_id: 'categoria',
  level: 'nivel',
  difficulty: 'nivel',
  equipment: 'equipo',
  equipamiento: 'equipo',
  description: 'descripcion',
  tipo: 'tipo',
  instrucciones: 'instrucciones',
  enlace_video: 'enlaceVideo',
  imagen_ejercicio: 'imagenEjercicio',
  id_grupos_musculares: 'idGruposMusculares',
  suggested_sets: 'seriesSugeridas',
  series_sugeridas: 'seriesSugeridas',
  suggested_reps: 'repeticionesSugeridas',
  repeticiones_sugeridas: 'repeticionesSugeridas',
  status: 'estado',
}

const CAMPOS_EDITABLES = [
  'nombre',
  'tipo',
  'instrucciones',
  'nivel',
  'equipamiento',
  'descripcion',
  'enlaceVideo',
  'imagenEjercicio',
  'idGruposMusculares',
  'estado',
]

function normalizarEjercicio(datos = {}) {
  const estadoEmpresa =
    datos.estado_empresa ?? datos.empresa_ejercicio?.estado ?? datos.pivot?.estado ?? null

  return {
    id: datos.id,
    nombre: datos.nombre ?? datos.name ?? '',
    categoria: datos.categoria ?? datos.category ?? '',
    grupoMuscular:
      datos.grupomuscular?.descripcion ??
      datos.grupo_muscular?.descripcion ??
      datos.grupoMuscular ??
      '',
    grupoMuscularTipo: datos.grupomuscular?.tipo ?? datos.grupo_muscular?.tipo ?? '',
    tipo: datos.tipo ?? datos.type ?? '',
    instrucciones: datos.instrucciones ?? datos.instructions ?? '',
    nivel: datos.nivel ?? datos.level ?? datos.difficulty ?? '',
    equipo: datos.equipo ?? datos.equipment ?? datos.equipamiento ?? '',
    imagen: resolverUrlStorage(
      datos.imagen_url ?? datos.imagen_ejercicio ?? datos.imagen ?? datos.image ?? '',
    ),
    enlaceVideo: datos.enlace_video ?? datos.enlaceVideo ?? datos.video_url ?? '',
    idGruposMusculares: datos.id_grupos_musculares ?? datos.idGruposMusculares ?? '',
    descripcion: datos.descripcion ?? datos.description ?? '',
    seriesSugeridas: Number(datos.series_sugeridas ?? datos.seriesSugeridas ?? 0),
    repeticionesSugeridas: Number(datos.repeticiones_sugeridas ?? datos.repeticionesSugeridas ?? 0),
    usos: Number(datos.usos_count ?? datos.usos ?? 0),
    estado: normalizarEstado(datos.estado ?? datos.status),
    // No se deriva de `estado`: es el estado independiente de empresa_ejercicio.
    estadoEmpresa: estadoEmpresa === null ? null : normalizarEstado(estadoEmpresa),
    fechaRegistro: datos.fecha_registro ?? datos.fechaRegistro ?? datos.created_at ?? '',
  }
}

function prepararPayload(payload) {
  const formulario = new FormData()
  const campos = {
    nombre: payload.nombre,
    descripcion: payload.descripcion || undefined,
    tipo: payload.tipo,
    instrucciones: payload.instrucciones,
    nivel: payload.nivel,
    equipamiento: payload.equipamiento,
    enlace_video: payload.enlaceVideo || undefined,
    // Sin estado en el formulario no se envía: antes salía '0' y desactivaba el ejercicio.
    estado:
      payload.estado === undefined
        ? undefined
        : payload.estado === 'active' || payload.estado === true || payload.estado === 1
          ? '1'
          : '0',
    id_grupos_musculares: payload.idGruposMusculares,
  }
  Object.entries(campos).forEach(([campo, valor]) => {
    if (valor !== undefined) formulario.append(campo, String(valor))
  })
  // En la edición la imagen es opcional: sin archivo nuevo no se envía el campo
  // (antes viajaba el texto "undefined").
  if (payload.imagenEjercicio instanceof Blob) {
    formulario.append('imagen_ejercicio', payload.imagenEjercicio)
  }
  return formulario
}

function prepararParametros({
  busqueda = '',
  categoria = '',
  nivel = '',
  equipo = '',
  estado = '',
  empresaId = null,
  pagina = 1,
  porPagina = 10,
} = {}) {
  return {
    search: busqueda,
    category: categoria,
    level: nivel,
    equipment: equipo,
    status: estado,
    id_empresas: empresaId,
    page: pagina,
    per_page: porPagina,
  }
}

const normalizarError = crearNormalizadorDeError(CAMPOS_ERROR)
const ejecutarPeticion = (peticion) => ejecutar(peticion, normalizarError)
const normalizarListado = (datos) => normalizarListadoBase(datos, normalizarEjercicio)
const seleccionarCamposEditables = (payload) => seleccionarEditables(payload, CAMPOS_EDITABLES)

export async function obtenerEjercicios(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerEjerciciosMock(params)

  return ejecutarPeticion(async () => {
    const { data } = await api.get('/ejercicios', { params: prepararParametros(params) })
    return normalizarListado(data)
  })
}

export async function obtenerGruposMusculares() {
  if (USE_MOCKS) {
    return [
      { id: 1, descripcion: 'Pectoral', tipo: 'pecho', estado: true },
      { id: 2, descripcion: 'Dorsal', tipo: 'espalda', estado: true },
    ]
  }

  return ejecutarPeticion(async () => {
    const { data } = await api.get('/gruposmusculares/tipos')
    const grupos = Array.isArray(data?.data) ? data.data : []
    return grupos
      .filter(
        (grupo) =>
          grupo.estado === undefined ||
          grupo.estado === true ||
          grupo.estado === 1 ||
          grupo.estado === '1',
      )
      .map((grupo) => ({
        id: Number(grupo.id),
        descripcion: grupo.descripcion ?? '',
        tipo: grupo.tipo ?? '',
        estado: true,
      }))
  })
}

export async function obtenerEjercicio(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerEjercicioMock(id)

  return ejecutarPeticion(async () => {
    const { data } = await api.get(`/ejercicios/${id}`)
    return normalizarEjercicio(data.data ?? data)
  })
}

export async function crearEjercicio(payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  if (USE_MOCKS) return (await cargarMock()).crearEjercicioMock(datosEditables)

  return ejecutarPeticion(async () => {
    const { data } = await api.post('/ejercicios', prepararPayload(datosEditables))
    return normalizarEjercicio(data.data ?? data)
  })
}

export async function actualizarEjercicio(id, payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  if (USE_MOCKS) return (await cargarMock()).actualizarEjercicioMock(id, datosEditables)

  return ejecutarPeticion(async () => {
    // PHP no interpreta multipart/form-data en un PUT: se envía como POST y
    // Laravel lo enruta como PUT por `_method` (igual que la personalización de empresas).
    const formulario = prepararPayload(datosEditables)
    formulario.append('_method', 'PUT')
    const { data } = await api.post(`/ejercicios/${id}`, formulario)
    return normalizarEjercicio(data.data ?? data)
  })
}

export async function desactivarEjercicio(id) {
  if (USE_MOCKS) return (await cargarMock()).desactivarEjercicioMock(id)

  return ejecutarPeticion(async () => {
    const { data } = await api.delete(`/ejercicios/${id}`)
    const respuesta = data?.data ?? data
    return normalizarEjercicio(
      respuesta && typeof respuesta === 'object' ? respuesta : { id, estado: 'inactive' },
    )
  })
}

export async function actualizarEstadoEjercicioEmpresa(empresaId, ejercicioId, estado) {
  if (!empresaId || !ejercicioId) {
    throw new Error('Selecciona una empresa y un ejercicio válidos.')
  }

  if (USE_MOCKS) {
    return (await cargarMock()).actualizarEstadoEjercicioEmpresaMock(empresaId, ejercicioId, estado)
  }

  return ejecutarPeticion(async () => {
    const { data } = await api.put(`/empresas/${empresaId}/ejercicios/${ejercicioId}/estado`, {
      estado: estado ? 1 : 0,
    })
    const respuesta = data.data ?? data
    return {
      estadoEmpresa: normalizarEstado(respuesta.estado),
      message: respuesta.message ?? 'Estado del ejercicio actualizado para la empresa.',
    }
  })
}
