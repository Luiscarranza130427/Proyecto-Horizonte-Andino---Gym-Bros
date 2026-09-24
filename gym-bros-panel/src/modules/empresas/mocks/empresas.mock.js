import { HttpError } from '@/core/api/http-error'

const LATENCIA_MINIMA = 250
const LATENCIA_MAXIMA = 600
const CORREO_VALIDO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const TELEFONO_VALIDO = /^\+?[0-9\s-]+$/
const COLOR_VALIDO = /^#[0-9a-f]{6}$/i
const MODELO_HORARIOS_MOCK = {
  ...Object.fromEntries(
    ['lunes', 'martes', 'miercoles', 'jueves', 'viernes'].flatMap((dia) => [
      [`horario_inicio_${dia}`, '06:00'],
      [`horario_fin_${dia}`, '22:00'],
    ]),
  ),
  horario_inicio_sabado: '08:00',
  horario_fin_sabado: '20:00',
  horario_inicio_domingo: '09:00',
  horario_fin_domingo: '13:00',
}

const DATOS_INICIALES = [
  ['Power Gym', 'Mariana Torres', 'Lima', 'Av. Arequipa 1840, Lince', 86, '2024-01-15'],
  ['Iron House', 'Diego Salazar', 'Arequipa', 'Calle Mercaderes 214, Cercado', 64, '2024-02-03'],
  [
    'Titan Fitness',
    'Valeria Campos',
    'La Libertad',
    'Av. España 1260, Trujillo',
    112,
    '2024-02-21',
  ],
  ['Apex Athletics', 'Rodrigo Peña', 'Lima', 'Av. La Marina 2350, San Miguel', 73, '2024-03-08'],
  ['Andes Training Club', 'Lucía Paredes', 'Cusco', 'Av. El Sol 742, Cusco', 58, '2024-03-19'],
  ['Norte Fit Center', 'Sebastián Ríos', 'Piura', 'Av. Grau 1185, Piura', 49, '2024-04-02'],
  [
    'Pacífico Wellness',
    'Camila Valdivia',
    'Lambayeque',
    'Av. Balta 930, Chiclayo',
    91,
    '2024-04-27',
  ],
  ['Fuerza Sur', 'Martín Cáceres', 'Tacna', 'Av. Bolognesi 1564, Tacna', 37, '2024-05-11'],
  ['Misti Performance', 'Adriana Lozano', 'Arequipa', 'Av. Ejército 706, Cayma', 68, '2024-05-29'],
  ['Costa Activa', 'Nicolás Vega', 'Ica', 'Av. San Martín 448, Ica', 42, '2024-06-07'],
  ['Selva Strong', 'Daniela Flores', 'Loreto', 'Jr. Próspero 1050, Iquitos', 55, '2024-06-22'],
  ['Altitude Box', 'Renzo Aguirre', 'Junín', 'Av. Ferrocarril 880, Huancayo', 61, '2024-07-04'],
  ['Core Studio', 'Gabriela Fuentes', 'Lima', 'Av. Primavera 1210, Surco', 44, '2024-07-18'],
  ['Impulso Fitness', 'Alejandro León', 'Áncash', 'Jr. José Olaya 635, Huaraz', 33, '2024-08-01'],
  ['Valle Training', 'Fernanda Ortiz', 'Lima', 'Av. Larco 980, Miraflores', 77, '2024-08-16'],
  ['Kallpa Gym', 'Mateo Navarro', 'Ayacucho', 'Jr. 28 de Julio 460, Ayacucho', 39, '2024-09-05'],
  ['Prime Movement', 'Ximena Castro', 'Lima', 'Av. Brasil 2740, Pueblo Libre', 83, '2024-09-23'],
  ['Roca Fitness', 'Santiago Medina', 'Cajamarca', 'Jr. Amazonas 712, Cajamarca', 46, '2024-10-09'],
  ['Energía Total', 'Paola Mendoza', 'San Martín', 'Jr. Lima 535, Tarapoto', 52, '2024-10-28'],
  ['Vértice Club', 'Joaquín Silva', 'Lima', 'Av. Angamos 1965, Surquillo', 69, '2024-11-12'],
  [
    'Arena Functional',
    'Claudia Espinoza',
    'Huánuco',
    'Jr. Dos de Mayo 840, Huánuco',
    31,
    '2024-11-30',
  ],
  ['Momentum Gym', 'Emilio Vargas', 'Ucayali', 'Jr. Tarapacá 620, Pucallpa', 48, '2024-12-14'],
  ['Inca Strength', 'Natalia Cabrera', 'Cusco', 'Av. de la Cultura 1520, Cusco', 57, '2025-01-06'],
  ['Balance 360', 'Bruno Herrera', 'Lima', 'Av. Universitaria 1045, Los Olivos', 41, '2025-01-24'],
]

const COLORES = [
  ['#e50914', '#111111'],
  ['#ff3b30', '#1c1c1e'],
  ['#d90429', '#2b2d42'],
  ['#ef233c', '#151515'],
]

const limpiarParaDominio = (nombre) =>
  nombre
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '')

const EMPRESAS_INICIALES = DATOS_INICIALES.map(
  ([nombre, gerente, region, direccion, usuarios, fechaRegistro], indice) => {
    const numero = indice + 1
    const dominio = limpiarParaDominio(nombre)
    const [colorPrimario, colorSecundario] = COLORES[indice % COLORES.length]

    return {
      id: numero,
      nombre,
      gerente,
      ruc: String(20100000000 + numero),
      correo: `contacto@${dominio}.test`,
      telefono: `+51 9${String(10000000 + numero).padStart(8, '0')}`,
      region,
      direccion,
      sitioWeb: `https://${dominio}.example`,
      estado: numero % 7 === 0 ? 'inactive' : 'active',
      estado_suscripcion: ['Activo', 'Inactivo', 'Por Vencer'][numero % 3],
      usuarios,
      fechaRegistro,
      logoUrl: '',
      colorPrimario,
      colorSecundario,
      ...MODELO_HORARIOS_MOCK,
    }
  },
)

let empresas = structuredClone(EMPRESAS_INICIALES)

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

function normalizarPagina(valor, porDefecto) {
  const numero = Number.parseInt(valor, 10)
  return Number.isFinite(numero) && numero > 0 ? numero : porDefecto
}

function validarEmpresa(payload, idIgnorado = null) {
  const errores = {}
  const requeridos = ['nombre', 'gerente', 'correo', 'telefono']

  requeridos.forEach((campo) => {
    if (!texto(payload[campo])) errores[campo] = ['Este campo es obligatorio.']
  })

  const correo = texto(payload.correo).toLowerCase()
  const ruc = texto(payload.ruc)
  const telefono = texto(payload.telefono)
  const digitosTelefono = telefono.replace(/\D/g, '')

  if (correo && !CORREO_VALIDO.test(correo)) {
    errores.correo = ['Ingresa un correo válido.']
  }

  if (ruc.length > 12) {
    errores.ruc = ['El RUC no puede superar 12 caracteres.']
  }

  if (
    telefono &&
    (!TELEFONO_VALIDO.test(telefono) || digitosTelefono.length < 7 || digitosTelefono.length > 15)
  ) {
    errores.telefono = ['Ingresa un teléfono válido.']
  }

  for (const campo of ['colorPrimario', 'colorSecundario']) {
    if (payload[campo] && !COLOR_VALIDO.test(texto(payload[campo]))) {
      errores[campo] = ['Ingresa un color hexadecimal válido.']
    }
  }

  if (
    correo &&
    empresas.some((empresa) => empresa.id !== idIgnorado && empresa.correo === correo)
  ) {
    errores.correo = ['Ya existe una empresa con este correo.']
  }

  if (ruc && empresas.some((empresa) => empresa.id !== idIgnorado && empresa.ruc === ruc)) {
    errores.ruc = ['Ya existe una empresa con este RUC.']
  }

  if (payload.estado && !['active', 'inactive'].includes(payload.estado)) {
    errores.estado = ['El estado seleccionado no es válido.']
  }

  if (Object.keys(errores).length) {
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  }
}

function buscarEmpresa(id) {
  const empresa = empresas.find((item) => item.id === Number(id))

  if (!empresa) {
    throw new HttpError(404, 'La empresa solicitada no existe.')
  }

  return empresa
}

export async function obtenerEmpresasMock({
  busqueda = '',
  estado = '',
  estado_suscripcion = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  await esperar(calcularLatencia())

  const termino = texto(busqueda).toLocaleLowerCase('es')
  const paginaSolicitada = normalizarPagina(pagina, 1)
  const cantidadPorPagina = Math.min(normalizarPagina(porPagina, 10), 100)
  const coincidencias = empresas.filter((empresa) => {
    const coincideEstado = !estado || empresa.estado === estado
    const contenido = [empresa.nombre, empresa.gerente, empresa.ruc, empresa.correo, empresa.region]
      .join(' ')
      .toLocaleLowerCase('es')
    const coincideSuscripcion =
      !estado_suscripcion ||
      estado_suscripcion === 'all' ||
      empresa.estado_suscripcion === estado_suscripcion
    return coincideEstado && coincideSuscripcion && (!termino || contenido.includes(termino))
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

export async function obtenerEmpresaMock(id) {
  await esperar(calcularLatencia())
  return clonar(buscarEmpresa(id))
}

export async function crearEmpresaMock(payload) {
  await esperar(calcularLatencia())
  const datos = { ...payload, correo: texto(payload.correo).toLowerCase(), ruc: texto(payload.ruc) }
  validarEmpresa(datos)

  const nuevaEmpresa = {
    id: empresas.reduce((maximo, empresa) => Math.max(maximo, empresa.id), 0) + 1,
    nombre: texto(datos.nombre),
    gerente: texto(datos.gerente),
    ruc: datos.ruc,
    correo: datos.correo,
    telefono: texto(datos.telefono),
    region: texto(datos.region),
    direccion: texto(datos.direccion),
    sitioWeb: texto(datos.sitioWeb),
    estado: datos.estado || 'active',
    usuarios: 0,
    fechaRegistro: new Date().toISOString().slice(0, 10),
    logoUrl: texto(datos.logoUrl),
    colorPrimario: texto(datos.colorPrimario) || '#e50914',
    colorSecundario: texto(datos.colorSecundario) || '#111111',
    ...Object.fromEntries(
      Object.keys(MODELO_HORARIOS_MOCK).map((campo) => [campo, texto(datos[campo])]),
    ),
  }

  empresas = [nuevaEmpresa, ...empresas]
  return clonar(nuevaEmpresa)
}

export async function actualizarEmpresaMock(id, payload) {
  await esperar(calcularLatencia())
  const empresa = buscarEmpresa(id)
  const datos = {
    ...empresa,
    ...payload,
    correo: texto(payload.correo ?? empresa.correo).toLowerCase(),
    ruc: texto(payload.ruc ?? empresa.ruc),
  }
  validarEmpresa(datos, empresa.id)

  const actualizada = {
    ...datos,
    id: empresa.id,
    nombre: texto(datos.nombre),
    gerente: texto(datos.gerente),
    telefono: texto(datos.telefono),
    region: texto(datos.region),
    direccion: texto(datos.direccion),
    sitioWeb: texto(datos.sitioWeb),
    logoUrl: texto(datos.logoUrl),
    usuarios: Number(datos.usuarios) || 0,
  }
  empresas = empresas.map((item) => (item.id === empresa.id ? actualizada : item))

  return clonar(actualizada)
}

export async function desactivarEmpresaMock(id) {
  await esperar(calcularLatencia())
  const empresa = buscarEmpresa(id)
  const desactivada = { ...empresa, estado: 'inactive' }
  empresas = empresas.map((item) => (item.id === empresa.id ? desactivada : item))
  return clonar(desactivada)
}

/**
 * Banners de la empresa, en la misma forma que devuelve el backend.
 *
 * Se guardan como columnas planas —`banner_1..3` y `link_boton_1..3`— porque es
 * literalmente lo que hace `updateBanners` en Laravel, y el mock tiene que
 * hablar el mismo contrato que el servicio normaliza.
 */
const BANNERS_INICIALES = {
  1: {
    banner_1: 'banners/promo-verano.webp',
    banner_2: 'banners/nueva-sede.webp',
    banner_3: '',
    link_boton_1: 'https://gymbros.pe/promociones',
    link_boton_2: 'https://gymbros.pe/sedes',
    link_boton_3: '',
  },
}

let bannersPorEmpresa = structuredClone(BANNERS_INICIALES)

const bannersVacios = () => ({
  banner_1: '',
  banner_2: '',
  banner_3: '',
  link_boton_1: '',
  link_boton_2: '',
  link_boton_3: '',
})

const presentarBanners = (datos) =>
  [1, 2, 3].map((numero) => ({
    numero,
    imagen: datos[`banner_${numero}`] ?? '',
    imagenUrl: datos[`banner_${numero}`] ?? '',
    enlace: datos[`link_boton_${numero}`] ?? '',
  }))

/** Simula GET /empresa/banners/:id */
export async function obtenerBannersEmpresaMock(id) {
  await esperar(calcularLatencia())
  buscarEmpresa(id)
  return clonar(presentarBanners(bannersPorEmpresa[Number(id)] ?? bannersVacios()))
}

export async function eliminarEmpresaMock(id) {
  await esperar(calcularLatencia())
  buscarEmpresa(id)
  empresas = empresas.filter((empresa) => Number(empresa.id) !== Number(id))
  delete bannersPorEmpresa[Number(id)]
}

/**
 * Simula PUT /empresa/banners/:id
 *
 * Reemplaza el registro entero, igual que el controlador real: lo que no llega
 * se guarda como nulo. Que el mock no perdone esto es a propósito —si aquí
 * fuese indulgente, un envío parcial parecería correcto en desarrollo y borraría
 * datos en producción—.
 */
export async function guardarBannersEmpresaMock(id, payload) {
  await esperar(calcularLatencia())
  buscarEmpresa(id)

  const guardado = {
    banner_1: payload.banner_1 ?? null,
    banner_2: payload.banner_2 ?? null,
    banner_3: payload.banner_3 ?? null,
    link_boton_1: payload.link_boton_1 ?? null,
    link_boton_2: payload.link_boton_2 ?? null,
    link_boton_3: payload.link_boton_3 ?? null,
  }

  bannersPorEmpresa = { ...bannersPorEmpresa, [Number(id)]: guardado }
  return clonar(presentarBanners(guardado))
}
