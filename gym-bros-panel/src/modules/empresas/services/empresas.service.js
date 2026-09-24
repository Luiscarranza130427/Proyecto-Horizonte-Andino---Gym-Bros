import api from '@/core/api/api'
import {
  crearNormalizadorDeError,
  ejecutarPeticion as ejecutar,
  normalizarEstado,
  normalizarListado as normalizarListadoBase,
  seleccionarCamposEditables as seleccionarEditables,
} from '@/core/api/normalizacion'
import { USE_MOCKS } from '@/core/config/env'
import { HttpError } from '@/core/api/http-error'
import { valorRegion } from '@/shared/constants/regionesPeru'
import { resolverUrlStorage } from '@/shared/utils/storage'

const cargarMock = () => import('@/modules/empresas/mocks/empresas.mock')

const DIAS = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo']
const CAMPOS_HORARIO = DIAS.flatMap((dia) => [`horario_inicio_${dia}`, `horario_fin_${dia}`])
const CAMPOS_BANNER = [1, 2, 3].flatMap((n) => [`banner_${n}`, `link_boton_${n}`])

const CAMPOS_ERROR = {
  name: 'nombre',
  manager_name: 'gerente',
  nombre_gerente: 'gerente',
  tax_id: 'ruc',
  email: 'correo',
  phone: 'telefono',
  address: 'direccion',
  status: 'estado',
  website: 'sitioWeb',
  sitio_web: 'sitioWeb',
  enlace_web: 'sitioWeb',
  logo_url: 'logoUrl',
  logo: 'logoUrl',
  color_primario: 'colorPrimario',
  color_secundario: 'colorSecundario',
  primary_color: 'colorPrimario',
  secondary_color: 'colorSecundario',
  color_1: 'colorPrimario',
  color_2: 'colorSecundario',
  ...Object.fromEntries(CAMPOS_HORARIO.map((campo) => [campo, campo])),
}

const CAMPOS_EDITABLES = [
  'nombre',
  'id_planes',
  'gerente',
  'ruc',
  'correo',
  'telefono',
  'region',
  'direccion',
  'sitioWeb',
  'estado',
  'logoUrl',
  'colorPrimario',
  'colorSecundario',
  ...CAMPOS_HORARIO,
  ...CAMPOS_BANNER,
]

function normalizarHora(valor) {
  if (valor === null || valor === undefined || valor === '') return ''
  const [hora = '', minutos = '00'] = String(valor).trim().replace('.', ':').split(':')
  if (!/^\d{1,2}$/.test(hora) || !/^\d{1,2}$/.test(minutos)) return ''
  return `${hora.padStart(2, '0')}:${minutos.padEnd(2, '0').slice(0, 2)}`
}

const normalizarHorarios = (datos) =>
  Object.fromEntries(CAMPOS_HORARIO.map((campo) => [campo, normalizarHora(datos[campo])]))

function normalizarEmpresa(datos = {}) {
  const usuarios = datos.cantidad_usuarios ?? datos.usuarios_count ?? datos.usuarios ?? null

  return {
    id: datos.id,
    suscripcion: datos.suscripcion ?? null,
    nombre: datos.nombre ?? datos.name ?? '',
    gerente: datos.gerente ?? datos.manager_name ?? datos.nombre_gerente ?? '',
    ruc: datos.ruc ?? datos.tax_id ?? '',
    correo: datos.correo ?? datos.email ?? '',
    telefono: datos.telefono ?? datos.phone ?? '',
    // Valor del catálogo de la API (sin tildes) aunque se haya guardado con ellas.
    region: valorRegion(datos.region),
    direccion: datos.direccion ?? '',
    sitioWeb: datos.enlace_web ?? datos.sitio_web ?? datos.sitioWeb ?? datos.website ?? '',
    estado: normalizarEstado(datos.estado ?? datos.status),
    estado_suscripcion: datos.estado_suscripcion ?? null,
    usuarios: usuarios === null ? null : Number(usuarios),
    fechaRegistro: datos.fecha_registro ?? datos.fechaRegistro ?? datos.created_at ?? '',
    logoUrl: resolverUrlStorage(datos.logo_url ?? datos.logoUrl ?? datos.logo ?? ''),
    colorPrimario:
      datos.color_primario ?? datos.colorPrimario ?? datos.color_1 ?? datos.color_fondo ?? '',
    colorSecundario:
      datos.color_secundario ?? datos.colorSecundario ?? datos.color_2 ?? datos.color_texto ?? '',
    ...normalizarHorarios(datos),
    ...Object.fromEntries(CAMPOS_BANNER.map((campo) => [campo, datos[campo] ?? ''])),
  }
}

function prepararPayload(payload) {
  const campos = {
    ...(payload.id_planes != null && payload.id_planes !== ''
      ? { id_planes: payload.id_planes }
      : {}),
    nombre: payload.nombre,
    nombre_gerente: payload.gerente,
    ruc: payload.ruc,
    correo: payload.correo,
    telefono: payload.telefono,
    region: payload.region,
    direccion: payload.direccion,
    enlace_web: payload.sitioWeb,
    estado: payload.estado === 'active' ? 1 : payload.estado === 'inactive' ? 0 : payload.estado,
    logo: payload.logoUrl,
    ...Object.fromEntries(CAMPOS_BANNER.map((campo) => [campo, payload[campo]])),
    color_1: payload.colorPrimario,
    color_2: payload.colorSecundario,
    ...Object.fromEntries(
      CAMPOS_HORARIO.map((campo) => [
        campo,
        typeof payload[campo] === 'string' ? payload[campo].replace(':', '.') : payload[campo],
      ]),
    ),
  }

  return Object.fromEntries(Object.entries(campos).filter(([, valor]) => valor !== undefined))
}

function prepararParametros({
  busqueda = '',
  estado = '',
  estado_suscripcion,
  pagina = 1,
  porPagina = 10,
} = {}) {
  return {
    search: busqueda,
    status: estado,
    page: pagina,
    per_page: porPagina,
    ...(estado_suscripcion && estado_suscripcion !== 'all' ? { estado_suscripcion } : {}),
  }
}

const normalizarError = crearNormalizadorDeError(CAMPOS_ERROR)
const ejecutarPeticion = (peticion) => ejecutar(peticion, normalizarError)
const normalizarListado = (datos) => normalizarListadoBase(datos, normalizarEmpresa)
const seleccionarCamposEditables = (payload) => seleccionarEditables(payload, CAMPOS_EDITABLES)

export async function obtenerEmpresas(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerEmpresasMock(params)

  return ejecutarPeticion(async () => {
    const { data } = await api.get('/empresas', { params: prepararParametros(params) })
    if (Array.isArray(data.data) && !data.meta && !data.current_page) {
      const normalizados = data.data.map(normalizarEmpresa)
      const texto = (params.busqueda ?? '').toLocaleLowerCase()
      const filtrados = normalizados.filter(
        (empresa) =>
          (!params.estado_suscripcion ||
            params.estado_suscripcion === 'all' ||
            empresa.estado_suscripcion === params.estado_suscripcion) &&
          (!texto ||
            [empresa.nombre, empresa.gerente, empresa.ruc].some((valor) =>
              valor.toLocaleLowerCase().includes(texto),
            )),
      )
      const pagina = Number(params.pagina ?? 1)
      const porPagina = Number(params.porPagina ?? 10)
      const inicio = (pagina - 1) * porPagina
      return {
        items: filtrados.slice(inicio, inicio + porPagina),
        paginacion: {
          pagina,
          porPagina,
          total: filtrados.length,
          ultimaPagina: Math.max(1, Math.ceil(filtrados.length / porPagina)),
          desde: filtrados.length ? inicio + 1 : 0,
          hasta: Math.min(inicio + porPagina, filtrados.length),
        },
      }
    }
    return normalizarListado(data)
  })
}

export async function obtenerEmpresa(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerEmpresaMock(id)

  // La API devolvía una empresa vacía por un binding mal nombrado y aquí se
  // descargaba el listado completo como rodeo. Corregido en la API: basta el detalle.
  return ejecutarPeticion(async () => {
    const { data } = await api.get(`/empresas/${id}`)
    const empresa = normalizarEmpresa(data?.data ?? data)
    if (empresa.id === null || empresa.id === undefined) {
      throw new HttpError(404, 'La empresa solicitada no existe.')
    }
    return empresa
  })
}

export async function crearEmpresa(payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  if (USE_MOCKS) return (await cargarMock()).crearEmpresaMock(datosEditables)

  return ejecutarPeticion(async () => {
    const campos = {
      ...prepararPayload(datosEditables),
      estado: 1,
    }
    const hayArchivos = ['logo', 'banner_1', 'banner_2', 'banner_3'].some((campo) =>
      campos[campo]?.startsWith('data:image/'),
    )
    let respuesta
    if (hayArchivos) {
      const formulario = new FormData()
      for (const [campo, valor] of Object.entries(campos)) {
        if (
          ['logo', 'banner_1', 'banner_2', 'banner_3'].includes(campo) &&
          valor?.startsWith('data:image/')
        ) {
          const [cabecera, contenido] = valor.split(',')
          const tipo = cabecera.match(/^data:(image\/[\w.+-]+);base64$/)?.[1]
          if (!tipo || !contenido) throw new Error('La imagen no es válida.')
          const bytes = Uint8Array.from(atob(contenido), (caracter) => caracter.charCodeAt(0))
          formulario.append(campo, new Blob([bytes], { type: tipo }), `${campo}.webp`)
        } else formulario.append(campo, valor ?? '')
      }
      respuesta = await api.post('/empresas', formulario, {
        headers: { 'Content-Type': undefined },
      })
    } else respuesta = await api.post('/empresas', campos)
    const { data } = respuesta
    return normalizarEmpresa(data.data ?? data)
  })
}

export async function actualizarEmpresa(id, payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  if (USE_MOCKS) return (await cargarMock()).actualizarEmpresaMock(id, datosEditables)

  return ejecutarPeticion(async () => {
    const campos = prepararPayload(datosEditables)
    let respuesta
    const colores = {}
    for (const campo of ['color_1', 'color_2', ...CAMPOS_BANNER]) {
      if (Object.hasOwn(campos, campo)) {
        colores[campo] = campos[campo]
        delete campos[campo]
      }
    }
    if (Object.keys(colores).length) {
      const hayArchivos = Object.values(colores).some(
        (valor) => typeof valor === 'string' && valor.startsWith('data:image/'),
      )
      if (hayArchivos) {
        const multipart = new FormData()
        multipart.append('_method', 'PUT')
        for (const [campo, valor] of Object.entries(colores)) {
          if (typeof valor === 'string' && valor.startsWith('data:image/')) {
            const [cabecera, contenido] = valor.split(',')
            const tipo = cabecera.match(/^data:(image\/[\w.+-]+);base64$/)?.[1]
            if (!tipo || !contenido) throw new Error('La imagen del banner no es válida.')
            const bytes = Uint8Array.from(atob(contenido), (caracter) => caracter.charCodeAt(0))
            multipart.append(campo, new Blob([bytes], { type: tipo }), `${campo}.webp`)
          } else multipart.append(campo, valor ?? '')
        }
        respuesta = await api.post(`/empresas/${id}/personalizacion`, multipart, {
          headers: { 'Content-Type': undefined },
        })
      } else respuesta = await api.put(`/empresas/${id}/personalizacion`, colores)
    }
    if (typeof campos.logo === 'string' && campos.logo.startsWith('data:image/')) {
      const [cabecera, contenido] = campos.logo.split(',')
      const tipo = cabecera.match(/^data:(image\/[\w.+-]+);base64$/)?.[1]
      if (!tipo || !contenido) throw new Error('El logo no contiene una imagen válida.')
      const bytes = Uint8Array.from(atob(contenido), (caracter) => caracter.charCodeAt(0))
      const formulario = new FormData()
      formulario.append('logo', new Blob([bytes], { type: tipo }), 'logo.webp')
      delete campos.logo
      // Guardar primero los demás campos: si fallan, no se sube el archivo.
      if (Object.keys(campos).length) respuesta = await api.put(`/empresas/${id}`, campos)
      const personalizacion = respuesta?.data?.data ?? respuesta?.data ?? {}
      respuesta = await api.post(`/empresas/${id}/logo`, formulario, {
        headers: { 'Content-Type': undefined },
      })
      respuesta = { data: { ...personalizacion, ...(respuesta.data.data ?? respuesta.data), id } }
    } else {
      // Una URL existente es de lectura: no se reenvía como si fuera un archivo.
      delete campos.logo
      if (Object.keys(campos).length) respuesta = await api.put(`/empresas/${id}`, campos)
    }
    if (!respuesta) return normalizarEmpresa({ id, ...prepararPayload(datosEditables) })
    const { data } = respuesta
    return normalizarEmpresa(data.data ?? data)
  })
}

function dataUrlABlob(valor) {
  const [cabecera, contenido] = valor.split(',')
  const tipo = cabecera.match(/^data:(image\/[\w.+-]+);base64$/)?.[1]
  if (!tipo || !contenido) throw new HttpError(422, 'La imagen del banner no es válida.')
  const bytes = Uint8Array.from(atob(contenido), (caracter) => caracter.charCodeAt(0))
  return new Blob([bytes], { type: tipo })
}

/**
 * Los tres banners que la app móvil muestra para la empresa.
 *
 * Son columnas de `empresas` (`banner_1..3` y `link_boton_1..3`), no una tabla
 * aparte, aunque el endpoint viva en su propia ruta.
 */
function normalizarBanners(datos = {}) {
  return [1, 2, 3].map((n) => ({
    numero: n,
    imagen: datos[`banner_${n}`] ?? '',
    imagenUrl: resolverUrlStorage(datos[`banner_${n}`] ?? ''),
    enlace: datos[`link_boton_${n}`] ?? '',
  }))
}

/** CONTRATO REAL: GET /empresa/banners/:id */
export async function obtenerBannersEmpresa(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerBannersEmpresaMock(id)

  return ejecutarPeticion(async () => {
    const { data } = await api.get(`/empresa/banners/${id}`)
    return normalizarBanners(data?.data ?? data ?? {})
  })
}

/**
 * CONTRATO REAL: PUT /empresa/banners/:id
 *
 * Manda SIEMPRE los seis campos, aunque sólo cambie uno.
 *
 * El controlador de Laravel asigna `$request->banner_1` y sus cinco hermanos sin
 * comprobar si vinieron: lo que no se envía se guarda como `null`. Un envío
 * parcial no actualiza un banner, borra los otros dos y sus tres enlaces.
 */
export async function guardarBannersEmpresa(id, banners) {
  // Un hueco sin usar viaja como `null`, no como cadena vacía: es lo que guarda
  // la base de datos para «no hay banner», y así ambos campos se comportan
  // igual en lugar de que la imagen quede en '' y el enlace en null.
  const oNulo = (valor) => (typeof valor === 'string' && valor.trim() ? valor.trim() : null)

  const payload = {}
  for (let n = 1; n <= 3; n += 1) {
    const banner = banners.find((actual) => actual.numero === n) ?? {}
    payload[`banner_${n}`] = oNulo(banner.imagen)
    payload[`link_boton_${n}`] = oNulo(banner.enlace)
  }

  if (USE_MOCKS) return (await cargarMock()).guardarBannersEmpresaMock(id, payload)

  return ejecutarPeticion(async () => {
    const hayImagenesNuevas = Object.values(payload).some(
      (valor) => typeof valor === 'string' && valor.startsWith('data:image/'),
    )
    if (!hayImagenesNuevas) {
      const { data } = await api.put(`/empresa/banners/${id}`, payload)
      return normalizarBanners(data?.data ?? data ?? payload)
    }

    // Una imagen nueva viaja como archivo a /personalizacion, que la guarda en
    // storage y persiste su ruta. Antes se enviaba la cadena `data:` (cientos de
    // KB) a /empresa/banners, que la metía en una columna varchar(300).
    const multipart = new FormData()
    multipart.append('_method', 'PUT')
    for (const [campo, valor] of Object.entries(payload)) {
      if (typeof valor === 'string' && valor.startsWith('data:image/')) {
        multipart.append(campo, dataUrlABlob(valor), `${campo}.webp`)
      } else {
        // '' llega a Laravel como null (ConvertEmptyStringsToNull): hueco vacío.
        multipart.append(campo, valor ?? '')
      }
    }
    const { data } = await api.post(`/empresas/${id}/personalizacion`, multipart, {
      headers: { 'Content-Type': undefined },
    })
    return normalizarBanners(data?.data ?? data)
  })
}

export async function desactivarEmpresa(id) {
  if (USE_MOCKS) return (await cargarMock()).desactivarEmpresaMock(id)

  return ejecutarPeticion(async () => {
    const { data } = await api.put(`/empresas/${id}`, { estado: 0 })
    const respuesta = data?.data ?? data
    const empresa =
      respuesta && typeof respuesta === 'object' ? respuesta : { id, estado: 'inactive' }
    return normalizarEmpresa(empresa)
  })
}

export async function eliminarEmpresa(id) {
  if (USE_MOCKS) return (await cargarMock()).eliminarEmpresaMock(id)
  return ejecutarPeticion(async () => {
    const { data } = await api.delete(`/empresas/${id}`, {
      data: { confirmar_eliminacion: true },
    })
    return data
  })
}

export async function obtenerPlanesAsignables() {
  return ejecutarPeticion(async () => {
    const { data } = await api.get('/planes')
    return (Array.isArray(data.data) ? data.data : [])
      .filter((plan) => [true, 1, '1'].includes(plan.activo))
      .map((plan) => ({ id: plan.id, nombre: plan.nombre }))
  })
}
