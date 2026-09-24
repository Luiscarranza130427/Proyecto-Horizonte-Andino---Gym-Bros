import api from '@/core/api/api'
import {
  crearNormalizadorDeError,
  ejecutarPeticion as ejecutar,
  normalizarEstado,
  normalizarListado as normalizarListadoBase,
  seleccionarCamposEditables as seleccionarEditables,
} from '@/core/api/normalizacion'
import { HttpError } from '@/core/api/http-error'
import { leerSesion } from '@/core/storage/session.storage'
import { obtenerEmpresas } from '@/modules/empresas/services/empresas.service'
import { resolverUrlStorage } from '@/shared/utils/storage'

const CAMPOS_ERROR = {
  first_name: 'nombre',
  nombre: 'nombre',
  nombres: 'nombre',
  last_name: 'apellido',
  apellido: 'apellido',
  apellidos: 'apellido',
  apodo: 'apodo',
  apodos: 'apodo',
  email: 'correo',
  document_type: 'tipoDocumento',
  tipo_documento: 'tipoDocumento',
  document_number: 'numeroDocumento',
  numero_documento: 'numeroDocumento',
  phone: 'telefono',
  address: 'direccion',
  profile_photo: 'fotoPerfil',
  foto_perfil: 'fotoPerfil',
  birth_date: 'fechaNacimiento',
  fecha_nacimiento: 'fechaNacimiento',
  role: 'rol',
  tipo_usuario: 'rol',
  status: 'estado',
  company_id: 'empresaId',
  id_empresas: 'empresaId',
  'suscripcion.fecha_inicio': 'suscripcion.fechaInicio',
  'suscripcion.fecha_vencimiento': 'suscripcion.fechaVencimiento',
}

const CAMPOS_EDITABLES = [
  'nombre',
  'apellido',
  'apodo',
  'correo',
  'tipoDocumento',
  'numeroDocumento',
  'telefono',
  'direccion',
  'genero',
  'fotoPerfil',
  'fechaNacimiento',
  'inicioSuscripcion',
  'finSuscripcion',
  'rol',
  'estado',
  'empresaId',
  'suscripcion',
]

const SUSCRIPCION_VACIA = {
  estado: 'none',
  fechaInicio: '',
  fechaVencimiento: '',
  diasRestantes: 0,
  nombrePlan: '',
}

const ACTIVIDAD_VACIA = { rutinas: 0, asistenciasMes: 0, ultimaActividad: '' }

function normalizarEmpresa(datos = {}, empresaId) {
  if (typeof datos === 'string') return { id: Number(empresaId) || null, nombre: datos }
  return {
    id: Number(datos.id ?? datos.empresa_id ?? datos.id_empresas ?? empresaId) || null,
    nombre: datos.nombre ?? datos.name ?? datos.razon_social ?? '',
  }
}

const ROLES_API_A_FRONT = {
  administrador: 'admin',
  empresa: 'manager',
  entrenador: 'trainer',
  usuario: 'member',
  admin: 'admin',
  manager: 'manager',
  trainer: 'trainer',
  member: 'member',
}

const ROLES_FRONT_A_API = {
  admin: 'Administrador',
  manager: 'Empresa',
  trainer: 'Entrenador',
  member: 'Usuario',
}

const DOCUMENTOS_API_A_FRONT = {
  dni: 'dni',
  pasaporte: 'passport',
  passport: 'passport',
  otro: 'other',
  other: 'other',
}

const DOCUMENTOS_FRONT_A_API = { dni: 'DNI', passport: 'PASAPORTE', other: 'OTRO' }

function normalizarRol(rol) {
  const clave = String(rol ?? '')
    .trim()
    .toLowerCase()
  return ROLES_API_A_FRONT[clave] ?? (clave || 'member')
}

function normalizarTipoDocumento(tipo) {
  const clave = String(tipo ?? '')
    .trim()
    .toLowerCase()
  return DOCUMENTOS_API_A_FRONT[clave] ?? (clave || 'other')
}

function normalizarSuscripcion(datos) {
  if (!datos) return { ...SUSCRIPCION_VACIA }
  return {
    estado: datos.estado ?? datos.status ?? 'none',
    fechaInicio: datos.fecha_inicio ?? datos.fechaInicio ?? datos.started_at ?? '',
    fechaVencimiento: datos.fecha_vencimiento ?? datos.fechaVencimiento ?? datos.ends_at ?? '',
    diasRestantes: Number(datos.dias_restantes ?? datos.diasRestantes ?? datos.days_remaining ?? 0),
    nombrePlan:
      datos.nombre_plan ?? datos.nombrePlan ?? datos.plan_name ?? datos.plan?.nombre ?? '',
  }
}

function normalizarActividad(datos) {
  if (!datos) return { ...ACTIVIDAD_VACIA }
  return {
    rutinas: Number(datos.rutinas_count ?? datos.rutinas ?? 0),
    asistenciasMes: Number(datos.asistencias_mes ?? datos.asistenciasMes ?? 0),
    ultimaActividad:
      datos.ultima_actividad ?? datos.ultimaActividad ?? datos.last_activity_at ?? '',
  }
}

function normalizarUsuario(datos = {}, empresasPorId = new Map()) {
  const empresaId = datos.id_empresas ?? datos.company_id ?? datos.empresa_id
  const empresa = normalizarEmpresa(datos.empresa ?? datos.company, empresaId)
  if (!empresa.nombre && empresa.id) empresa.nombre = empresasPorId.get(empresa.id) ?? ''

  return {
    id: datos.id,
    // Laravel puede exponer el nombre como `nombre`, `nombres` o `first_name`.
    // No se infiere desde los apellidos: ese valor debe venir del API.
    nombre: datos.nombre ?? datos.nombres ?? datos.first_name ?? '',
    apellido: datos.apellidos ?? datos.apellido ?? datos.last_name ?? '',
    apodo: datos.apodo ?? datos.apodos ?? datos.nickname ?? '',
    correo: datos.correo ?? datos.email ?? '',
    tipoDocumento: normalizarTipoDocumento(
      datos.tipo_documento ?? datos.tipoDocumento ?? datos.document_type,
    ),
    numeroDocumento: datos.numero_documento ?? datos.numeroDocumento ?? datos.document_number ?? '',
    telefono: datos.telefono ?? datos.phone ?? '',
    direccion: datos.direccion ?? datos.address ?? '',
    genero: datos.genero ?? '',
    fotoPerfil: resolverUrlStorage(
      datos.foto_perfil ?? datos.fotoPerfil ?? datos.profile_photo ?? '',
    ),
    fechaNacimiento: datos.fecha_nacimiento ?? datos.fechaNacimiento ?? datos.birth_date ?? '',
    inicioSuscripcion:
      datos.inicio_suscripcion ?? datos.inicioSuscripcion ?? datos.subscription_start ?? '',
    finSuscripcion: datos.fin_suscripcion ?? datos.finSuscripcion ?? datos.subscription_end ?? '',
    fechaRegistro: datos.fecha_registro ?? datos.fechaRegistro ?? datos.created_at ?? '',
    rol: normalizarRol(datos.tipo_usuario ?? datos.rol ?? datos.role),
    estado: normalizarEstado(datos.estado ?? datos.status),
    empresa,
    suscripcion: normalizarSuscripcion(datos.suscripcion ?? datos.subscription),
    actividad: normalizarActividad(
      datos.actividad ?? datos.activity ?? { ultima_actividad: datos.asistencia_semanal },
    ),
  }
}

function normalizarEventoHistorial(datos = {}) {
  return {
    id: datos.id,
    fecha: datos.fecha ?? datos.created_at ?? '',
    accion: datos.accion ?? datos.action ?? 'updated',
    descripcion: datos.descripcion ?? datos.description ?? '',
    autor: datos.autor?.nombre ?? datos.autor?.name ?? datos.autor ?? datos.author?.name ?? '',
  }
}

function prepararSuscripcion(suscripcion) {
  if (!suscripcion) return undefined
  return {
    estado: suscripcion.estado,
    fecha_inicio: suscripcion.fechaInicio,
    fecha_vencimiento: suscripcion.fechaVencimiento,
    nombre_plan: suscripcion.nombrePlan,
  }
}

function prepararPayload(payload) {
  const campos = {
    // La columna y el contrato de Laravel se llaman `nombres` (no `nombre`).
    nombres: payload.nombre ?? payload.nombres,
    apellidos: payload.apellido,
    apodo: payload.apodo,
    correo: payload.correo,
    tipo_documento: DOCUMENTOS_FRONT_A_API[payload.tipoDocumento] ?? payload.tipoDocumento,
    numero_documento: payload.numeroDocumento,
    telefono: payload.telefono,
    direccion: payload.direccion,
    genero: payload.genero,
    foto_perfil: payload.fotoPerfil,
    fecha_nacimiento: payload.fechaNacimiento,
    inicio_suscripcion: payload.inicioSuscripcion,
    fin_suscripcion: payload.finSuscripcion,
    tipo_usuario: ROLES_FRONT_A_API[payload.rol] ?? payload.rol,
    estado: payload.estado === 'active' ? 1 : payload.estado === 'inactive' ? 0 : payload.estado,
    id_empresas: payload.empresaId,
    suscripcion: prepararSuscripcion(payload.suscripcion),
  }
  return Object.fromEntries(Object.entries(campos).filter(([, valor]) => valor !== undefined))
}

function prepararParametros({
  busqueda = '',
  empresaId = '',
  estado = '',
  rol = '',
  suscripcion = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  return {
    search: busqueda,
    id_empresas: empresaId,
    estado,
    tipo_usuario: rol,
    estado_suscripcion: suscripcion,
    page: pagina,
    per_page: porPagina,
  }
}

const normalizarError = crearNormalizadorDeError(CAMPOS_ERROR)
const ejecutarPeticion = (peticion) => ejecutar(peticion, normalizarError)
const seleccionarCamposEditables = (payload) => seleccionarEditables(payload, CAMPOS_EDITABLES)

function normalizarTexto(valor) {
  return String(valor ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
}

function obtenerAlcanceEmpresa() {
  const usuario = leerSesion()?.usuario
  const rol = String(usuario?.rol ?? usuario?.role ?? '')
    .trim()
    .toLowerCase()
  const esAdministradorGlobal = ['admin', 'administrador', 'super_admin', 'superadmin'].includes(
    rol,
  )
  if (esAdministradorGlobal) return null

  const idEmpresa = usuario?.tenantId ?? usuario?.id_empresas ?? usuario?.empresa_id
  const idNormalizado = Number(idEmpresa)
  return Number.isFinite(idNormalizado) && idNormalizado > 0 ? idNormalizado : null
}

function tienePaginacionServidor(datos) {
  const fuente = datos?.meta ?? datos
  return Boolean(
    fuente?.current_page ||
    fuente?.last_page ||
    fuente?.per_page ||
    fuente?.total_pages ||
    datos?.links,
  )
}

function filtrarYPaginar(items, params = {}) {
  const busqueda = normalizarTexto(params.busqueda)
  const empresaId = params.empresaId === '' ? null : Number(params.empresaId)
  const estado = params.estado && params.estado !== 'all' ? params.estado : ''
  const rol = params.rol && params.rol !== 'all' ? params.rol : ''
  const suscripcion = params.suscripcion && params.suscripcion !== 'all' ? params.suscripcion : ''

  const filtrados = items.filter((usuario) => {
    const coincideBusqueda =
      !busqueda ||
      [
        usuario.nombre,
        usuario.apellido,
        usuario.apodo,
        usuario.correo,
        usuario.numeroDocumento,
        usuario.telefono,
      ].some((valor) => normalizarTexto(valor).includes(busqueda))
    const coincideEmpresa = !empresaId || usuario.empresa?.id === empresaId
    const coincideEstado = !estado || usuario.estado === estado
    const coincideRol = !rol || usuario.rol === rol
    const coincideSuscripcion = !suscripcion || usuario.suscripcion?.estado === suscripcion
    return (
      coincideBusqueda && coincideEmpresa && coincideEstado && coincideRol && coincideSuscripcion
    )
  })

  const paginaSolicitada = Math.max(1, Number(params.pagina) || 1)
  const porPagina = Math.max(1, Number(params.porPagina) || 10)
  const ultimaPagina = Math.max(1, Math.ceil(filtrados.length / porPagina))
  const pagina = Math.min(paginaSolicitada, ultimaPagina)
  const inicio = (pagina - 1) * porPagina
  const itemsPagina = filtrados.slice(inicio, inicio + porPagina)

  return {
    items: itemsPagina,
    paginacion: {
      pagina,
      ultimaPagina,
      porPagina,
      total: filtrados.length,
      desde: filtrados.length ? inicio + 1 : 0,
      hasta: filtrados.length ? inicio + itemsPagina.length : 0,
    },
  }
}

async function obtenerMapaEmpresas() {
  try {
    const { items } = await obtenerEmpresas({ pagina: 1, porPagina: 500 })
    return new Map(items.map((empresa) => [Number(empresa.id), empresa.nombre]))
  } catch {
    return new Map()
  }
}

function endpointNoDisponible(error, accion) {
  if (error?.status !== 404 && error?.status !== 405) return error
  return new HttpError(
    501,
    `El API de Laravel aún no permite ${accion} usuarios. Falta publicar el endpoint correspondiente.`,
  )
}

export async function obtenerUsuarios(params = {}) {
  return ejecutarPeticion(async () => {
    const empresaSesion = obtenerAlcanceEmpresa()
    const parametrosAlcance = empresaSesion ? { ...params, empresaId: empresaSesion } : params
    const [{ data }, empresasPorId] = await Promise.all([
      api.get('/usuarios', { params: prepararParametros(parametrosAlcance) }),
      obtenerMapaEmpresas(),
    ])

    if (tienePaginacionServidor(data)) {
      return normalizarListadoBase(data, (item) => normalizarUsuario(item, empresasPorId))
    }

    const crudos = Array.isArray(data?.data) ? data.data : Array.isArray(data) ? data : []
    return filtrarYPaginar(
      crudos.map((item) => normalizarUsuario(item, empresasPorId)),
      parametrosAlcance,
    )
  })
}

export async function obtenerUsuario(id) {
  return ejecutarPeticion(async () => {
    const { items } = await obtenerUsuarios({ pagina: 1, porPagina: 10000 })
    const usuario = items.find((item) => Number(item.id) === Number(id))
    if (!usuario) throw new HttpError(404, 'El usuario solicitado no existe.')
    return usuario
  })
}

export async function obtenerPlanAlimentacionUsuario(id) {
  return ejecutarPeticion(async () => {
    const { data } = await api.get(`/usuarios/${id}/plan-alimentacion`)
    return data.data ?? data
  })
}

export async function crearUsuario(payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  const empresaSesion = obtenerAlcanceEmpresa()
  if (empresaSesion) datosEditables.empresaId = empresaSesion
  try {
    return await ejecutarPeticion(async () => {
      const campos = prepararPayload(datosEditables)
      // La foto no viaja en el alta (la API la ignoraba y se perdía): se sube
      // como archivo al endpoint de foto una vez creada la cuenta.
      const foto = campos.foto_perfil
      delete campos.foto_perfil
      const { data } = await api.post('/usuarios', campos)
      const creado = data.data ?? data
      if (typeof foto !== 'string' || !foto.startsWith('data:image/') || !creado?.id) {
        return normalizarUsuario(creado)
      }
      const archivo = new FormData()
      archivo.append('foto_perfil', dataUrlABlob(foto), 'foto.webp')
      const respuestaFoto = await api.post(`/usuarios/${creado.id}/foto-perfil`, archivo, {
        headers: { 'Content-Type': undefined },
      })
      const guardada = respuestaFoto.data.data ?? respuestaFoto.data
      return normalizarUsuario({ ...creado, foto_perfil: guardada.foto_url ?? guardada.foto_perfil })
    })
  } catch (error) {
    throw endpointNoDisponible(error, 'crear')
  }
}

function dataUrlABlob(valor) {
  const [cabecera, contenido] = valor.split(',')
  const tipo = cabecera.match(/^data:(image\/[\w.+-]+);base64$/)?.[1]
  if (!tipo || !contenido) throw new Error('La foto seleccionada no es válida.')
  const bytes = Uint8Array.from(atob(contenido), (caracter) => caracter.charCodeAt(0))
  return new Blob([bytes], { type: tipo })
}

export async function actualizarUsuario(id, payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  const empresaSesion = obtenerAlcanceEmpresa()
  if (empresaSesion) datosEditables.empresaId = empresaSesion
  try {
    return await ejecutarPeticion(async () => {
      const campos = prepararPayload(datosEditables)
      const foto = campos.foto_perfil
      const nuevaFoto = typeof foto === 'string' && foto.startsWith('data:image/')
      let archivo
      if (nuevaFoto) {
        const [cabecera, contenido] = foto.split(',')
        const tipo = cabecera.match(/^data:(image\/[\w.+-]+);base64$/)?.[1]
        if (!tipo || !contenido) throw new Error('La foto seleccionada no es válida.')
        const bytes = Uint8Array.from(atob(contenido), (caracter) => caracter.charCodeAt(0))
        archivo = new FormData()
        archivo.append('foto_perfil', new Blob([bytes], { type: tipo }), 'foto.webp')
        delete campos.foto_perfil
      }
      let usuario = { id }
      if (Object.keys(campos).length) {
        const { data } = await api.put(`/usuarios/${id}`, campos)
        usuario = data.data ?? data
      }
      if (!archivo) return normalizarUsuario(usuario)
      const respuestaFoto = await api.post(`/usuarios/${id}/foto-perfil`, archivo, {
        headers: { 'Content-Type': undefined },
      })
      const guardada = respuestaFoto.data.data ?? respuestaFoto.data
      return normalizarUsuario({
        ...usuario,
        id,
        foto_perfil: guardada.foto_url ?? guardada.foto_perfil,
      })
    })
  } catch (error) {
    throw endpointNoDisponible(error, 'editar')
  }
}

export async function desactivarUsuario(id) {
  try {
    return await ejecutarPeticion(async () => {
      const { data } = await api.put(`/usuarios/${id}/estado`, { estado: 0 })
      const respuesta = data?.data ?? data
      return normalizarUsuario(
        respuesta && typeof respuesta === 'object' ? respuesta : { id, estado: 'inactive' },
      )
    })
  } catch (error) {
    throw endpointNoDisponible(error, 'desactivar')
  }
}

/** Descarga el archivo CSV que Laravel genera según el alcance de la sesión. */
export function exportarUsuarios() {
  return api.get('/usuarios/exportar', { responseType: 'blob' })
}

/**
 * Historial de cambios del usuario (tabla `historial_cambios` del esquema).
 *
 * Devuelve `null` cuando el endpoint NO EXISTE todavía, y un array —vacío o
 * no— cuando sí existe. La diferencia importa: devolviendo `[]` en ambos casos,
 * la ficha mostraba «Sin cambios registrados» de forma permanente, como si el
 * usuario no tuviera actividad, cuando en realidad no hay a quién preguntarle.
 * Con `null`, la vista puede ocultar la sección en lugar de mentir.
 */
export async function obtenerHistorialUsuario(id) {
  try {
    return await ejecutarPeticion(async () => {
      const { data } = await api.get(`/usuarios/${id}/historial`)
      const eventos = data.data ?? data
      return Array.isArray(eventos) ? eventos.map(normalizarEventoHistorial) : []
    })
  } catch (error) {
    if (error?.status === 404 || error?.status === 405) return null
    throw error
  }
}

export async function obtenerOpcionesEmpresas() {
  const { items } = await obtenerEmpresas({ pagina: 1, porPagina: 100 })
  const empresaSesion = obtenerAlcanceEmpresa()
  return items
    .filter((empresa) => !empresaSesion || Number(empresa.id) === empresaSesion)
    .map(({ id, nombre, estado }) => ({ id, nombre, estado }))
}
