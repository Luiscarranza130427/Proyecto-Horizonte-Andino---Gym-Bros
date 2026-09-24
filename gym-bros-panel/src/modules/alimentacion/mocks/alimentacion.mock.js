import { HttpError } from '@/core/api/http-error'

const LATENCIA_MINIMA = 250
const LATENCIA_MAXIMA = 600

const HOY = new Date('2026-08-27T12:00:00')

function comoDiaLocal(fecha) {
  const dosCifras = (valor) => String(valor).padStart(2, '0')
  return `${fecha.getFullYear()}-${dosCifras(fecha.getMonth() + 1)}-${dosCifras(fecha.getDate())}`
}

function desplazarDias(dias) {
  const fecha = new Date(HOY)
  fecha.setDate(fecha.getDate() + dias)
  return comoDiaLocal(fecha)
}

const CATALOGO = [
  ['Pechuga de pollo', 'proteina', 165, 31, 0, 3.6, 0],
  ['Huevo', 'proteina', 155, 13, 1.1, 11, 0],
  ['Atún en agua', 'proteina', 116, 26, 0, 1, 0],
  ['Lomo de res', 'proteina', 217, 26, 0, 12, 0],
  ['Trucha', 'proteina', 148, 21, 0, 7, 0],
  ['Arroz blanco cocido', 'carbohidrato', 130, 2.7, 28, 0.3, 0.4],
  ['Camote sancochado', 'carbohidrato', 90, 2, 21, 0.1, 3.3],
  ['Papa amarilla', 'carbohidrato', 87, 2, 20, 0.1, 1.8],
  ['Pan integral', 'cereal', 247, 13, 41, 3.4, 7],
  ['Avena', 'cereal', 389, 17, 66, 7, 11],
  ['Quinua cocida', 'cereal', 120, 4.4, 21, 1.9, 2.8],
  ['Palta', 'grasa', 160, 2, 9, 15, 7],
  ['Aceite de oliva', 'grasa', 884, 0, 0, 100, 0],
  ['Almendras', 'grasa', 579, 21, 22, 50, 12],
  ['Plátano', 'fruta', 89, 1.1, 23, 0.3, 2.6],
  ['Manzana', 'fruta', 52, 0.3, 14, 0.2, 2.4],
  ['Papaya', 'fruta', 43, 0.5, 11, 0.3, 1.7],
  ['Arándanos', 'fruta', 57, 0.7, 14, 0.3, 2.4],
  ['Brócoli', 'verdura', 34, 2.8, 7, 0.4, 2.6],
  ['Espinaca', 'verdura', 23, 2.9, 3.6, 0.4, 2.2],
  ['Zanahoria', 'verdura', 41, 0.9, 10, 0.2, 2.8],
  ['Yogur griego natural', 'lacteo', 59, 10, 3.6, 0.4, 0],
  ['Queso fresco', 'lacteo', 264, 18, 3.4, 21, 0],
  ['Leche descremada', 'lacteo', 34, 3.4, 5, 0.1, 0],
  ['Lentejas cocidas', 'legumbre', 116, 9, 20, 0.4, 8],
  ['Garbanzos cocidos', 'legumbre', 164, 9, 27, 2.6, 8],
  ['Frejol canario', 'legumbre', 127, 9, 23, 0.5, 6],
  ['Agua', 'bebida', 0, 0, 0, 0, 0],
  ['Infusión de manzanilla', 'bebida', 1, 0, 0.2, 0, 0],
  ['Proteína en polvo', 'otro', 375, 80, 8, 3, 1],
]

const USUARIOS = [
  { id: 1, nombre: 'Carlos Ramírez', empresa: { id: 1, nombre: 'Power Gym' } },
  { id: 2, nombre: 'Andrea Mendoza', empresa: { id: 1, nombre: 'Power Gym' } },
  { id: 3, nombre: 'Luis Paredes', empresa: { id: 2, nombre: 'Iron House' } },
  { id: 4, nombre: 'Valentina Torres', empresa: { id: 2, nombre: 'Iron House' } },
  { id: 5, nombre: 'Diego Salazar', empresa: { id: 3, nombre: 'Titan Fitness' } },
  { id: 6, nombre: 'Camila Vargas', empresa: { id: 3, nombre: 'Titan Fitness' } },
  { id: 7, nombre: 'Sebastián Ríos', empresa: { id: 4, nombre: 'Apex Athletics' } },
]

const OBJETIVOS = [
  'Bajar grasa manteniendo masa muscular',
  'Ganar masa muscular',
  'Mantener el peso actual',
  'Recomposición corporal',
  'Preparación para competencia',
]

const PLANTILLAS_COMIDA = [
  {
    tipo: 'desayuno',
    hora: '07:00',
    partes: [
      [9, 60],
      [15, 120],
      [21, 150],
    ],
  },
  {
    tipo: 'media_manana',
    hora: '10:00',
    partes: [
      [13, 30],
      [16, 150],
    ],
  },
  {
    tipo: 'almuerzo',
    hora: '13:00',
    partes: [
      [0, 180],
      [5, 200],
      [18, 120],
    ],
  },
  {
    tipo: 'media_tarde',
    hora: '16:30',
    partes: [
      [29, 30],
      [27, 500],
    ],
  },
  {
    tipo: 'cena',
    hora: '19:30',
    partes: [
      [4, 150],
      [6, 150],
      [19, 100],
    ],
  },
  {
    tipo: 'snack',
    hora: '21:30',
    partes: [
      [23, 200],
      [17, 80],
    ],
  },
  {
    tipo: 'desayuno',
    hora: '06:30',
    partes: [
      [1, 120],
      [8, 50],
      [11, 70],
    ],
  },
  {
    tipo: 'almuerzo',
    hora: '12:30',
    partes: [
      [3, 160],
      [10, 180],
      [20, 100],
    ],
  },
  {
    tipo: 'cena',
    hora: '20:00',
    partes: [
      [2, 140],
      [24, 180],
      [19, 90],
    ],
  },
  {
    tipo: 'media_manana',
    hora: '09:30',
    partes: [
      [14, 120],
      [22, 60],
    ],
  },
  { tipo: 'otro', hora: '05:30', partes: [[27, 400]] },
  {
    tipo: 'media_tarde',
    hora: '17:00',
    partes: [
      [25, 150],
      [16, 100],
    ],
  },
]

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

const redondear = (valor) => Math.round(valor * 10) / 10

function unidadDe(tipo) {
  return tipo === 'bebida' ? 'mililitros' : 'gramos'
}

function construirAlimentos() {
  return CATALOGO.map(([nombre, tipo, calorias, proteinas, carbohidratos, grasas, fibra], i) => ({
    id: i + 1,
    nombre,
    tipo,
    calorias,
    proteinas,
    carbohidratos,
    grasas,
    fibra,
    unidadBase: unidadDe(tipo),
  }))
}

let alimentos = construirAlimentos()

function macrosDePorcion(alimento, cantidad) {
  const factor = cantidad / 100
  return {
    calorias: alimento.calorias * factor,
    proteinas: alimento.proteinas * factor,
    carbohidratos: alimento.carbohidratos * factor,
    grasas: alimento.grasas * factor,
    fibra: alimento.fibra * factor,
  }
}

function sumarMacros(porciones) {
  const total = porciones.reduce(
    (acumulado, { macros }) => ({
      calorias: acumulado.calorias + macros.calorias,
      proteinas: acumulado.proteinas + macros.proteinas,
      carbohidratos: acumulado.carbohidratos + macros.carbohidratos,
      grasas: acumulado.grasas + macros.grasas,
      fibra: acumulado.fibra + macros.fibra,
    }),
    { calorias: 0, proteinas: 0, carbohidratos: 0, grasas: 0, fibra: 0 },
  )
  return {
    calorias: Math.round(total.calorias),
    proteinas: redondear(total.proteinas),
    carbohidratos: redondear(total.carbohidratos),
    grasas: redondear(total.grasas),
    fibra: redondear(total.fibra),
  }
}

let secuenciaComida = 0
let secuenciaPorcion = 0

function construirComida(plantilla, orden) {
  secuenciaComida += 1
  const porciones = plantilla.partes.map(([indice, cantidad]) => {
    secuenciaPorcion += 1
    const alimento = alimentos[indice]
    return {
      id: secuenciaPorcion,
      alimento: { id: alimento.id, nombre: alimento.nombre, tipo: alimento.tipo },
      cantidad,
      unidad: alimento.unidadBase,
      macros: macrosDePorcion(alimento, cantidad),
    }
  })

  return {
    id: secuenciaComida,
    tipoComida: plantilla.tipo,
    horaSugerida: plantilla.hora,
    orden,
    alimentos: porciones.map((p) => ({
      ...p,
      macros: {
        calorias: Math.round(p.macros.calorias),
        proteinas: redondear(p.macros.proteinas),
        carbohidratos: redondear(p.macros.carbohidratos),
        grasas: redondear(p.macros.grasas),
        fibra: redondear(p.macros.fibra),
      },
    })),
    macros: sumarMacros(porciones),
  }
}

function construirPlan(indice) {
  const usuario = USUARIOS[indice % USUARIOS.length]
  const activo = indice % 3 !== 0
  const cuantasComidas = 3 + (indice % 4)
  const comidas = Array.from({ length: cuantasComidas }, (_, i) =>
    construirComida(PLANTILLAS_COMIDA[(indice * 2 + i) % PLANTILLAS_COMIDA.length], i + 1),
  )

  const totales = sumarMacros(
    comidas.flatMap((comida) => comida.alimentos.map((a) => ({ macros: a.macros }))),
  )

  return {
    id: indice + 1,
    usuario: { id: usuario.id, nombre: usuario.nombre },
    empresa: usuario.empresa,
    objetivo: OBJETIVOS[indice % OBJETIVOS.length],
    fechaInicio: desplazarDias(-30 - (indice % 40)),
    fechaFin: activo ? desplazarDias(30 + (indice % 25)) : desplazarDias(-1 - (indice % 12)),
    activo,
    objetivos: {
      calorias: 1800 + (indice % 8) * 150,
      proteinas: 120 + (indice % 6) * 15,
      carbohidratos: 180 + (indice % 7) * 20,
      grasas: 55 + (indice % 5) * 8,
    },
    comidas,
    macros: totales,
  }
}

function construirPlanes() {
  secuenciaComida = 0
  secuenciaPorcion = 0
  return Array.from({ length: 16 }, (_, indice) => construirPlan(indice))
}

let planes = construirPlanes()
let secuenciaAlimento = alimentos.length

function paginar(lista, pagina, porPagina) {
  const total = lista.length
  const ultimaPagina = Math.max(1, Math.ceil(total / porPagina))
  const paginaActual = Math.min(Math.max(1, Number(pagina) || 1), ultimaPagina)
  const desde = (paginaActual - 1) * porPagina
  const items = lista.slice(desde, desde + porPagina)

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

export async function obtenerAlimentosMock({
  busqueda = '',
  tipo = '',
  pagina = 1,
  porPagina = 12,
} = {}) {
  await prepararRespuesta()

  const termino = sinTildes(busqueda).trim()
  const filtrados = alimentos.filter(
    (alimento) =>
      (!termino || sinTildes(alimento.nombre).includes(termino)) &&
      (!tipo || alimento.tipo === tipo),
  )

  return paginar(
    filtrados.map((alimento) => ({ ...alimento, usos: contarUsos(alimento.id) })),
    pagina,
    porPagina,
  )
}

export async function obtenerAlimentoMock(id) {
  await prepararRespuesta()
  const encontrado = alimentos.find((alimento) => alimento.id === Number(id))
  if (!encontrado) {
    throw new HttpError(404, 'El alimento solicitado no existe.')
  }
  return clonar({ ...encontrado, usos: contarUsos(encontrado.id) })
}

function contarUsos(idAlimento) {
  return planes.reduce(
    (total, plan) =>
      total +
      plan.comidas.filter((comida) =>
        comida.alimentos.some((porcion) => porcion.alimento.id === idAlimento),
      ).length,
    0,
  )
}

const NUMERICOS = ['calorias', 'proteinas', 'carbohidratos', 'grasas', 'fibra']

function validarAlimento(payload, idActual = null) {
  const errores = {}

  const nombre = String(payload.nombre ?? '').trim()
  if (nombre.length < 3) {
    errores.nombre = ['El nombre debe tener al menos 3 caracteres.']
  } else if (
    alimentos.some(
      (alimento) => alimento.id !== idActual && sinTildes(alimento.nombre) === sinTildes(nombre),
    )
  ) {
    errores.nombre = ['Ya existe un alimento con ese nombre.']
  }

  if (!CATALOGO.some(([, tipo]) => tipo === payload.tipo)) {
    errores.tipo = ['Selecciona un tipo válido.']
  }

  NUMERICOS.forEach((campo) => {
    const valor = Number(payload[campo])
    if (!Number.isFinite(valor) || valor < 0) {
      errores[campo] = ['Introduce un número igual o mayor que cero.']
    }
  })

  if (Object.keys(errores).length > 0) {
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  }
}

function desdePayload(payload) {
  return {
    nombre: String(payload.nombre).trim(),
    tipo: payload.tipo,
    calorias: Number(payload.calorias),
    proteinas: Number(payload.proteinas),
    carbohidratos: Number(payload.carbohidratos),
    grasas: Number(payload.grasas),
    fibra: Number(payload.fibra),
    unidadBase: unidadDe(payload.tipo),
  }
}

export async function crearAlimentoMock(payload) {
  await prepararRespuesta()
  validarAlimento(payload)

  secuenciaAlimento += 1
  const creado = { id: secuenciaAlimento, ...desdePayload(payload) }
  alimentos = [creado, ...alimentos]
  return clonar(creado)
}

export async function actualizarAlimentoMock(id, payload) {
  await prepararRespuesta()
  const indice = alimentos.findIndex((alimento) => alimento.id === Number(id))
  if (indice === -1) {
    throw new HttpError(404, 'El alimento solicitado no existe.')
  }
  validarAlimento(payload, Number(id))

  const actualizado = { ...alimentos[indice], ...desdePayload(payload) }
  alimentos = alimentos.map((alimento, i) => (i === indice ? actualizado : alimento))
  return clonar(actualizado)
}

export async function eliminarAlimentoMock(id) {
  await prepararRespuesta()
  const encontrado = alimentos.find((alimento) => alimento.id === Number(id))
  if (!encontrado) {
    throw new HttpError(404, 'El alimento solicitado no existe.')
  }

  const usos = contarUsos(encontrado.id)
  if (usos > 0) {
    throw new HttpError(
      422,
      `«${encontrado.nombre}» se usa en ${usos} ${usos === 1 ? 'comida' : 'comidas'} y no puede retirarse del catálogo.`,
    )
  }

  alimentos = alimentos.filter((alimento) => alimento.id !== encontrado.id)
  return clonar(encontrado)
}

function resumirPlan(plan) {
  const { comidas, ...resto } = plan
  return { ...resto, totalComidas: comidas.length }
}

export async function obtenerPlanesMock({
  busqueda = '',
  situacion = '',
  empresaId = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  await prepararRespuesta()

  const termino = sinTildes(busqueda).trim()
  const filtrados = planes.filter((plan) => {
    const coincideTexto =
      !termino ||
      sinTildes(plan.usuario.nombre).includes(termino) ||
      sinTildes(plan.objetivo).includes(termino)
    const coincideSituacion =
      !situacion ||
      (situacion === 'activo' && plan.activo) ||
      (situacion === 'inactivo' && !plan.activo)
    return (
      coincideTexto && coincideSituacion && (!empresaId || plan.empresa.id === Number(empresaId))
    )
  })

  const ordenados = [...filtrados].sort(
    (a, b) => Number(b.activo) - Number(a.activo) || b.fechaInicio.localeCompare(a.fechaInicio),
  )

  return paginar(ordenados.map(resumirPlan), pagina, porPagina)
}

function buscarPlan(id) {
  const encontrado = planes.find((plan) => plan.id === Number(id))
  if (!encontrado) {
    throw new HttpError(404, 'El plan solicitado no existe.')
  }
  return encontrado
}

export async function obtenerPlanMock(id) {
  await prepararRespuesta()
  const plan = buscarPlan(id)
  return clonar({
    ...plan,
    comidas: ordenarComidas(plan.comidas),
    totalComidas: plan.comidas.length,
  })
}

const ORDEN_DEL_DIA = [
  'desayuno',
  'media_manana',
  'almuerzo',
  'media_tarde',
  'cena',
  'snack',
  'otro',
]

function ordenarComidas(comidas) {
  return [...comidas].sort(
    (a, b) =>
      a.horaSugerida.localeCompare(b.horaSugerida) ||
      ORDEN_DEL_DIA.indexOf(a.tipoComida) - ORDEN_DEL_DIA.indexOf(b.tipoComida) ||
      a.orden - b.orden,
  )
}

function validarComida(payload) {
  const errores = {}

  if (!ORDEN_DEL_DIA.includes(payload.tipoComida)) {
    errores.tipoComida = ['Selecciona un tipo de comida válido.']
  }
  if (!/^\d{2}:\d{2}$/.test(String(payload.horaSugerida ?? ''))) {
    errores.horaSugerida = ['Indica la hora en formato HH:MM.']
  }

  const porciones = Array.isArray(payload.alimentos) ? payload.alimentos : []
  if (porciones.length === 0) {
    errores.alimentos = ['Añade al menos un alimento.']
  } else if (porciones.some((p) => !alimentos.some((a) => a.id === Number(p.alimentoId)))) {
    errores.alimentos = ['Alguno de los alimentos elegidos ya no existe.']
  } else if (
    porciones.some((p) => !Number.isFinite(Number(p.cantidad)) || Number(p.cantidad) <= 0)
  ) {
    errores.alimentos = ['Las cantidades tienen que ser mayores que cero.']
  }

  if (Object.keys(errores).length > 0) {
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  }
}

function componerComida(payload, id, orden) {
  const porciones = payload.alimentos.map((parte, i) => {
    const alimento = alimentos.find((a) => a.id === Number(parte.alimentoId))
    const cantidad = Number(parte.cantidad)
    const macros = macrosDePorcion(alimento, cantidad)
    return {
      id: secuenciaPorcion + i + 1,
      alimento: { id: alimento.id, nombre: alimento.nombre, tipo: alimento.tipo },
      cantidad,
      unidad: parte.unidad ?? alimento.unidadBase,
      macros: {
        calorias: Math.round(macros.calorias),
        proteinas: redondear(macros.proteinas),
        carbohidratos: redondear(macros.carbohidratos),
        grasas: redondear(macros.grasas),
        fibra: redondear(macros.fibra),
      },
    }
  })
  secuenciaPorcion += porciones.length

  return {
    id,
    tipoComida: payload.tipoComida,
    horaSugerida: payload.horaSugerida,
    orden,
    alimentos: porciones,
    macros: sumarMacros(porciones),
  }
}

function refrescarMacrosDelPlan(plan) {
  plan.macros = sumarMacros(
    plan.comidas.flatMap((comida) => comida.alimentos.map((a) => ({ macros: a.macros }))),
  )
}

export async function crearComidaMock(idPlan, payload) {
  await prepararRespuesta()
  const plan = buscarPlan(idPlan)
  validarComida(payload)

  secuenciaComida += 1
  const comida = componerComida(payload, secuenciaComida, plan.comidas.length + 1)
  plan.comidas = [...plan.comidas, comida]
  refrescarMacrosDelPlan(plan)
  return clonar(comida)
}

export async function actualizarComidaMock(idPlan, idComida, payload) {
  await prepararRespuesta()
  const plan = buscarPlan(idPlan)
  const anterior = plan.comidas.find((comida) => comida.id === Number(idComida))
  if (!anterior) {
    throw new HttpError(404, 'La comida solicitada no existe.')
  }
  validarComida(payload)

  const comida = componerComida(payload, anterior.id, anterior.orden)
  plan.comidas = plan.comidas.map((actual) => (actual.id === anterior.id ? comida : actual))
  refrescarMacrosDelPlan(plan)
  return clonar(comida)
}

export async function eliminarComidaMock(idPlan, idComida) {
  await prepararRespuesta()
  const plan = buscarPlan(idPlan)
  const comida = plan.comidas.find((actual) => actual.id === Number(idComida))
  if (!comida) {
    throw new HttpError(404, 'La comida solicitada no existe.')
  }
  if (plan.comidas.length === 1) {
    throw new HttpError(
      422,
      'Un plan necesita al menos una comida. Añade otra antes de retirar ésta.',
    )
  }

  plan.comidas = plan.comidas.filter((actual) => actual.id !== comida.id)
  refrescarMacrosDelPlan(plan)
  return clonar(comida)
}

export async function obtenerAlimentosParaElegirMock() {
  await esperar(150)
  return clonar(
    alimentos.map(({ id, nombre, tipo, unidadBase, calorias }) => ({
      id,
      nombre,
      tipo,
      unidadBase,
      calorias,
    })),
  )
}

export async function obtenerEmpresasConPlanesMock() {
  await esperar(150)
  const vistas = new Map()
  planes.forEach((plan) => vistas.set(plan.empresa.id, plan.empresa))
  return clonar([...vistas.values()].sort((a, b) => a.nombre.localeCompare(b.nombre)))
}

export function restablecerAlimentacionMock() {
  alimentos = construirAlimentos()
  planes = construirPlanes()
  secuenciaAlimento = alimentos.length
}
