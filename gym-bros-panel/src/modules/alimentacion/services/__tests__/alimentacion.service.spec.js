import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const ALIMENTO_NUEVO = {
  nombre: 'Kiwicha cocida',
  tipo: 'cereal',
  calorias: 120,
  proteinas: 4,
  carbohidratos: 22,
  grasas: 1.8,
  fibra: 2.5,
}

async function cargarServicioMock() {
  vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
  vi.doMock('@/core/api/api', () => ({
    default: { get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() },
  }))
  vi.useFakeTimers()
  vi.spyOn(Math, 'random').mockReturnValue(0)
  const servicio = await import('@/modules/alimentacion/services/alimentacion.service')
  await import('@/modules/alimentacion/mocks/alimentacion.mock')
  return servicio
}

async function completarPeticion(peticion, latencia = 250) {
  await vi.advanceTimersByTimeAsync(0)
  await vi.advanceTimersByTimeAsync(latencia)
  return peticion
}

async function esperarRechazo(peticion, forma) {
  const rechazo = expect(peticion).rejects.toMatchObject(forma)
  await vi.advanceTimersByTimeAsync(0)
  await vi.advanceTimersByTimeAsync(250)
  await rechazo
}

async function capturarFallo(peticion, latencia = 250) {
  const capturado = peticion.catch((error) => error)
  await vi.advanceTimersByTimeAsync(0)
  await vi.advanceTimersByTimeAsync(latencia)
  return capturado
}

const sumar = (lista, campo) =>
  Math.round(lista.reduce((total, item) => total + item.macros[campo], 0))

describe('alimentacion.service en modo mock', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('entrega el catálogo paginado con la forma que promete', async () => {
    const servicio = await cargarServicioMock()

    const { items, paginacion } = await completarPeticion(servicio.obtenerAlimentos())

    expect(items.length).toBeGreaterThan(0)
    expect(paginacion.total).toBeGreaterThan(items.length)
    expect(items[0]).toMatchObject({
      id: expect.any(Number),
      nombre: expect.any(String),
      tipo: expect.any(String),
      calorias: expect.any(Number),
      unidadBase: expect.any(String),
    })
  })

  it('el listado trae `usos`, no sólo la ficha', async () => {
    const servicio = await cargarServicioMock()

    const { items } = await completarPeticion(servicio.obtenerAlimentos({ porPagina: 50 }))

    expect(items.every((alimento) => typeof alimento.usos === 'number')).toBe(true)
    expect(items.some((alimento) => alimento.usos > 0)).toBe(true)

    const enUso = items.find((alimento) => alimento.usos > 0)
    const ficha = await completarPeticion(servicio.obtenerAlimento(enUso.id))
    expect(ficha.usos).toBe(enUso.usos)
  })

  it('busca sin distinguir tildes ni mayúsculas', async () => {
    const servicio = await cargarServicioMock()

    const { items } = await completarPeticion(servicio.obtenerAlimentos({ busqueda: 'platano' }))

    expect(items.map((a) => a.nombre)).toContain('Plátano')
  })

  it('filtra por tipo de alimento', async () => {
    const servicio = await cargarServicioMock()

    const { items } = await completarPeticion(
      servicio.obtenerAlimentos({ tipo: 'legumbre', porPagina: 50 }),
    )

    expect(items.length).toBeGreaterThan(0)
    expect(items.every((a) => a.tipo === 'legumbre')).toBe(true)
  })

  it('escala los macros de una porción por su cantidad', async () => {
    const servicio = await cargarServicioMock()

    const plan = await completarPeticion(servicio.obtenerPlan(1))
    const porciones = plan.comidas.flatMap((comida) => comida.alimentos)
    const catalogo = await completarPeticion(servicio.obtenerAlimentosParaElegir(), 150)

    porciones.forEach((porcion) => {
      const base = catalogo.find((a) => a.id === porcion.alimento.id)
      const esperado = Math.round((base.calorias * porcion.cantidad) / 100)
      expect(porcion.macros.calorias).toBe(esperado)
    })
  })

  it('los macros de cada comida son la suma de sus alimentos', async () => {
    const servicio = await cargarServicioMock()

    const plan = await completarPeticion(servicio.obtenerPlan(2))

    expect(plan.comidas.length).toBeGreaterThan(0)
    plan.comidas.forEach((comida) => {
      expect(comida.macros.calorias).toBe(sumar(comida.alimentos, 'calorias'))
    })
  })

  it('ordena las comidas por hora, no por el orden en que se añadieron', async () => {
    const servicio = await cargarServicioMock()

    const antes = await completarPeticion(servicio.obtenerPlan(3))
    expect(antes.comidas[0].horaSugerida > '05:00').toBe(true)

    await completarPeticion(
      servicio.crearComida(3, {
        tipoComida: 'desayuno',
        horaSugerida: '05:00',
        alimentos: [{ alimentoId: 10, cantidad: 40, unidad: 'gramos' }],
      }),
    )

    const despues = await completarPeticion(servicio.obtenerPlan(3))
    const horas = despues.comidas.map((comida) => comida.horaSugerida)

    expect(horas[0]).toBe('05:00')
    expect(horas).toEqual([...horas].sort())
    expect(despues.comidas[0].orden).toBe(Math.max(...despues.comidas.map((c) => c.orden)))
  })

  it('separa los planes vigentes de los finalizados', async () => {
    const servicio = await cargarServicioMock()

    const activos = await completarPeticion(
      servicio.obtenerPlanes({ situacion: 'activo', porPagina: 50 }),
    )
    expect(activos.items.every((plan) => plan.activo)).toBe(true)

    const finalizados = await completarPeticion(
      servicio.obtenerPlanes({ situacion: 'inactivo', porPagina: 50 }),
    )
    expect(finalizados.items.every((plan) => !plan.activo)).toBe(true)
    expect(finalizados.items.length).toBeGreaterThan(0)
  })

  it('el mock entrega la forma que el servicio garantiza', async () => {
    const servicio = await cargarServicioMock()

    const { items } = await completarPeticion(servicio.obtenerPlanes())

    expect(items[0]).toMatchObject({
      id: expect.any(Number),
      usuario: { id: expect.any(Number), nombre: expect.any(String) },
      empresa: { id: expect.any(Number), nombre: expect.any(String) },
      objetivo: expect.any(String),
      fechaInicio: expect.any(String),
      activo: expect.any(Boolean),
      objetivos: {
        calorias: expect.any(Number),
        proteinas: expect.any(Number),
        carbohidratos: expect.any(Number),
        grasas: expect.any(Number),
      },
      macros: {
        calorias: expect.any(Number),
        proteinas: expect.any(Number),
        carbohidratos: expect.any(Number),
        grasas: expect.any(Number),
        fibra: expect.any(Number),
      },
    })

    expect(items[0].caloriasObjetivo).toBeUndefined()

    const ficha = await completarPeticion(servicio.obtenerPlan(items[0].id))
    expect(ficha.objetivos.calorias).toBe(items[0].objetivos.calorias)
    expect(ficha.totalComidas).toBe(ficha.comidas.length)
    expect(ficha.totalComidas).toBeGreaterThan(0)
  })

  it('el listado de planes no arrastra las comidas, que sólo usa la ficha', async () => {
    const servicio = await cargarServicioMock()

    const { items } = await completarPeticion(servicio.obtenerPlanes())

    expect(items[0].comidas).toBeUndefined()
    expect(items[0].totalComidas).toBeGreaterThan(0)
  })

  it('crea un alimento y lo deja disponible en el catálogo', async () => {
    const servicio = await cargarServicioMock()

    const creado = await completarPeticion(servicio.crearAlimento(ALIMENTO_NUEVO))
    expect(creado).toMatchObject({ nombre: 'Kiwicha cocida', tipo: 'cereal' })

    const { items } = await completarPeticion(servicio.obtenerAlimentos({ busqueda: 'kiwicha' }))
    expect(items).toHaveLength(1)
  })

  it('rechaza un nombre repetido y un macro negativo', async () => {
    const servicio = await cargarServicioMock()

    await esperarRechazo(servicio.crearAlimento({ ...ALIMENTO_NUEVO, nombre: 'Palta' }), {
      status: 422,
      errors: expect.objectContaining({ nombre: expect.any(Array) }),
    })

    await esperarRechazo(servicio.crearAlimento({ ...ALIMENTO_NUEVO, proteinas: -5 }), {
      status: 422,
      errors: expect.objectContaining({ proteinas: expect.any(Array) }),
    })
  })

  it('impide retirar un alimento que ya se usa en alguna comida', async () => {
    const servicio = await cargarServicioMock()

    const avena = await completarPeticion(servicio.obtenerAlimento(10))
    expect(avena.nombre).toBe('Avena')
    expect(avena.usos).toBeGreaterThan(0)

    const error = await capturarFallo(servicio.eliminarAlimento(10))

    expect(error.status).toBe(422)
    expect(error.message).toContain('no puede retirarse')
    expect(error.errors).toBeNull()
  })

  it('sí retira un alimento que no usa nadie', async () => {
    const servicio = await cargarServicioMock()

    const creado = await completarPeticion(servicio.crearAlimento(ALIMENTO_NUEVO))
    const retirado = await completarPeticion(servicio.eliminarAlimento(creado.id))

    expect(retirado.id).toBe(creado.id)

    const { items } = await completarPeticion(servicio.obtenerAlimentos({ busqueda: 'kiwicha' }))
    expect(items).toHaveLength(0)
  })

  it('añadir una comida recalcula los totales del plan', async () => {
    const servicio = await cargarServicioMock()

    const antes = await completarPeticion(servicio.obtenerPlan(4))

    await completarPeticion(
      servicio.crearComida(4, {
        tipoComida: 'snack',
        horaSugerida: '22:30',
        alimentos: [{ alimentoId: 1, cantidad: 100, unidad: 'gramos' }],
      }),
    )

    const despues = await completarPeticion(servicio.obtenerPlan(4))

    expect(despues.comidas).toHaveLength(antes.comidas.length + 1)
    expect(despues.macros.calorias).toBe(antes.macros.calorias + 165)
  })

  it('rechaza una comida sin alimentos o con hora mal escrita', async () => {
    const servicio = await cargarServicioMock()

    await esperarRechazo(
      servicio.crearComida(1, { tipoComida: 'cena', horaSugerida: '20:00', alimentos: [] }),
      { status: 422, errors: expect.objectContaining({ alimentos: expect.any(Array) }) },
    )

    await esperarRechazo(
      servicio.crearComida(1, {
        tipoComida: 'cena',
        horaSugerida: '8pm',
        alimentos: [{ alimentoId: 1, cantidad: 100 }],
      }),
      { status: 422, errors: expect.objectContaining({ horaSugerida: expect.any(Array) }) },
    )
  })

  it('no deja al plan sin ninguna comida', async () => {
    const servicio = await cargarServicioMock()

    const plan = await completarPeticion(servicio.obtenerPlan(1))

    for (const comida of plan.comidas.slice(1)) {
      await completarPeticion(servicio.eliminarComida(1, comida.id))
    }

    await esperarRechazo(servicio.eliminarComida(1, plan.comidas[0].id), {
      status: 422,
      message: expect.stringContaining('al menos una comida'),
    })
  })
})

describe('alimentacion.service con API Laravel', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('traduce la situación del plan al booleano que espera el backend', async () => {
    const get = vi.fn().mockResolvedValue({ data: { data: [], total: 0 } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerPlanes } = await import('@/modules/alimentacion/services/alimentacion.service')

    await obtenerPlanes({ situacion: 'activo', empresaId: 2 })
    expect(get).toHaveBeenCalledWith('/planes-alimentacion', {
      params: expect.objectContaining({ activo: true, id_empresas: 2 }),
    })

    await obtenerPlanes({})
    expect(get.mock.calls[1][1].params.activo).toBeUndefined()
  })

  it('normaliza un alimento en snake_case', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          {
            id: 3,
            name: 'Rolled oats',
            type: 'cereal',
            calories: 389,
            protein: 17,
            carbohydrates: 66,
            fat: 7,
            fiber: 11,
            unidad_base: 'gramos',
            usos_count: 4,
            estado_preparacion: 'Cocido',
            gramos_por_unidad: 45,
            densidad_g_ml: null,
            fuente_nutricional: 'BEDCA',
            nutricion_verificada: true,
            restricciones_verificadas: false,
            grupo_menu: 'cereal',
            tipos_comida: ['desayuno'],
            porcion_min: 30,
            porcion_max: 90,
            paso_porcion: 5,
          },
        ],
        current_page: 1,
        last_page: 3,
        per_page: 12,
        total: 30,
        from: 1,
        to: 12,
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerAlimentos } =
      await import('@/modules/alimentacion/services/alimentacion.service')

    const { items, paginacion } = await obtenerAlimentos()

    expect(items[0]).toEqual({
      id: 3,
      nombre: 'Rolled oats',
      tipo: 'cereal',
      calorias: 389,
      proteinas: 17,
      carbohidratos: 66,
      grasas: 7,
      fibra: 11,
      unidadBase: 'gramos',
      usos: 4,
      estadoPreparacion: 'Cocido',
      gramosPorUnidad: 45,
      densidadGml: null,
      fuenteNutricional: 'BEDCA',
      nutricionVerificada: true,
      restriccionesVerificadas: false,
      grupoMenu: 'cereal',
      tiposComida: ['desayuno'],
      porcionMin: 30,
      porcionMax: 90,
      pasoPorcion: 5,
    })
    expect(paginacion).toMatchObject({ pagina: 1, ultimaPagina: 3, total: 30 })
  })

  it('obtiene el detalle desde el catálogo y localiza el alimento por su ID', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          { id: 3, nombre: 'Palta', tipo: 'grasa', calorias: 160 },
          { id: 4, nombre: 'Avena', tipo: 'cereal', calorias: 389 },
        ],
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerAlimento } = await import('@/modules/alimentacion/services/alimentacion.service')

    await expect(obtenerAlimento(4)).resolves.toMatchObject({ id: 4, nombre: 'Avena' })
    expect(get).toHaveBeenCalledWith('/alimentos')
  })

  it('normaliza un plan con sus comidas anidadas', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: {
          id: 9,
          user: { id: 2, name: 'Andrea Mendoza' },
          company: { id: 1, name: 'Power Gym' },
          goal: 'Ganar masa muscular',
          start_date: '2026-07-01',
          end_date: '2026-10-01',
          active: true,
          calorias_objetivo: 2400,
          meals: [
            {
              id: 4,
              meal_type: 'desayuno',
              suggested_time: '07:00',
              order: 1,
              foods: [
                {
                  id: 11,
                  food: { id: 10, name: 'Avena', type: 'cereal' },
                  quantity: 60,
                  unit: 'gramos',
                  macros: { calories: 233, protein: 10.2 },
                },
              ],
            },
          ],
        },
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerPlan } = await import('@/modules/alimentacion/services/alimentacion.service')

    const plan = await obtenerPlan(9)

    expect(plan).toMatchObject({
      id: 9,
      usuario: { id: 2, nombre: 'Andrea Mendoza' },
      empresa: { id: 1, nombre: 'Power Gym' },
      objetivo: 'Ganar masa muscular',
      fechaInicio: '2026-07-01',
      activo: true,
      totalComidas: 1,
    })
    expect(plan.objetivos.calorias).toBe(2400)
    expect(plan.comidas[0]).toMatchObject({ tipoComida: 'desayuno', horaSugerida: '07:00' })
    expect(plan.comidas[0].alimentos[0]).toMatchObject({
      alimento: { id: 10, nombre: 'Avena', tipo: 'cereal' },
      cantidad: 60,
      unidad: 'gramos',
    })
    expect(plan.comidas[0].alimentos[0].macros.calorias).toBe(233)
  })

  it('traduce los campos de un 422 al vocabulario del formulario', async () => {
    const { HttpError } = await import('@/core/api/http-error')
    const post = vi.fn().mockRejectedValue(
      new HttpError(422, 'The given data was invalid.', {
        name: ['Obligatorio.'],
        fat: ['No válido.'],
      }),
    )
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearAlimento } = await import('@/modules/alimentacion/services/alimentacion.service')

    await expect(crearAlimento(ALIMENTO_NUEVO)).rejects.toMatchObject({
      status: 422,
      errors: { nombre: ['Obligatorio.'], grasas: ['No válido.'] },
    })
  })

  it('traduce los campos de un 422 de comida', async () => {
    const { HttpError } = await import('@/core/api/http-error')
    const post = vi.fn().mockRejectedValue(
      new HttpError(422, 'Revisa los datos.', {
        hora_sugerida: ['Formato inválido.'],
        foods: ['Añade alimentos.'],
      }),
    )
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearComida } = await import('@/modules/alimentacion/services/alimentacion.service')

    await expect(
      crearComida(1, { tipoComida: 'cena', horaSugerida: 'x', alimentos: [] }),
    ).rejects.toMatchObject({
      status: 422,
      errors: { horaSugerida: ['Formato inválido.'], alimentos: ['Añade alimentos.'] },
    })
  })

  it('manda el payload de una comida con los nombres del esquema', async () => {
    const post = vi.fn().mockResolvedValue({ data: { data: { id: 1 } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearComida } = await import('@/modules/alimentacion/services/alimentacion.service')

    await crearComida(7, {
      tipoComida: 'almuerzo',
      horaSugerida: '13:00',
      alimentos: [{ alimentoId: 5, cantidad: 200, unidad: 'gramos' }],
    })

    expect(post).toHaveBeenCalledWith('/planes-alimentacion/7/comidas', {
      tipo_comida: 'almuerzo',
      hora_sugerida: '13:00',
      alimentos: [{ id_alimentos: 5, cantidad: 200, unidad: 'gramos' }],
    })
  })

  it('no manda al backend campos que no son editables', async () => {
    const post = vi.fn().mockResolvedValue({ data: { data: { id: 1 } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearAlimento } = await import('@/modules/alimentacion/services/alimentacion.service')

    await crearAlimento({ ...ALIMENTO_NUEVO, usos: 99, id: 4 })

    const enviado = post.mock.calls[0][1]
    expect(enviado).not.toHaveProperty('usos')
    expect(enviado).not.toHaveProperty('id')
    expect(enviado.nombre).toBe('Kiwicha cocida')
  })

  it('envía los campos ampliados al editar con los nombres del API', async () => {
    const put = vi.fn().mockResolvedValue({ data: { data: { id: 4 } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put } }))
    const { actualizarAlimento } =
      await import('@/modules/alimentacion/services/alimentacion.service')

    await actualizarAlimento(4, {
      ...ALIMENTO_NUEVO,
      activo: true,
      unidadBase: 'gramos',
      estadoPreparacion: 'Cocido',
      gramosPorUnidad: 45,
      densidadGml: null,
      fuenteNutricional: 'BEDCA',
      nutricionVerificada: true,
      restriccionesVerificadas: false,
      grupoMenu: 'cereal',
      tiposComida: 'desayuno',
      porcionMin: 30,
      porcionMax: 90,
      pasoPorcion: 5,
    })

    expect(put).toHaveBeenCalledWith(
      '/alimentos/4',
      expect.objectContaining({
        activo: true,
        base_unidad: 'gramos',
        estado_preparacion: 'Cocido',
        gramos_por_unidad: 45,
        densidad_g_ml: null,
        fuente_nutricional: 'BEDCA',
        nutricion_verificada: true,
        restricciones_verificadas: false,
        grupo_menu: 'cereal',
        tipos_comida: 'desayuno',
        porcion_min: 30,
        porcion_max: 90,
        paso_porcion: 5,
      }),
    )
  })

  it('agrupa los errores tipos_comida.* en el selector de tipos de comida', async () => {
    const { HttpError } = await import('@/core/api/http-error')
    const put = vi.fn().mockRejectedValue(
      new HttpError(422, 'Revisa los datos.', {
        'tipos_comida.0': ['El primer tipo no es válido.'],
      }),
    )
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put } }))
    const { actualizarAlimento } =
      await import('@/modules/alimentacion/services/alimentacion.service')

    await expect(
      actualizarAlimento(4, { ...ALIMENTO_NUEVO, tiposComida: ['x'] }),
    ).rejects.toMatchObject({
      errors: { tiposComida: ['El primer tipo no es válido.'] },
    })
  })
})
