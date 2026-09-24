import heroUrl from '@/assets/images/stitch/command-streams.jpg'

const RESUMEN_DASHBOARD = {
  banner: {
    imagen: heroUrl,
    contenido_text: 'Gestiona tu gimnasio desde un solo lugar',
    texto_boton: 'Ver usuarios',
    enlace_boton: '/usuarios',
  },
  metricas: [
    {
      id: 'empresas',
      etiqueta: 'Empresas',
      valor: 14,
      icono: 'bi-buildings-fill',
      tendencia: {
        valor: 2,
        prefijo: '+',
        sufijo: '',
        detalle: 'nuevas este mes',
        tono: 'positivo',
      },
    },
    {
      id: 'usuarios',
      etiqueta: 'Usuarios',
      valor: 346,
      icono: 'bi-people-fill',
      tendencia: {
        valor: 8.4,
        prefijo: '+',
        sufijo: '%',
        detalle: 'frente al mes anterior',
        tono: 'positivo',
      },
    },
    {
      id: 'entrenadores',
      etiqueta: 'Entrenadores',
      valor: 27,
      icono: 'bi-person-arms-up',
      tendencia: {
        valor: 3.8,
        prefijo: '+',
        sufijo: '%',
        detalle: 'frente al mes anterior',
        tono: 'positivo',
      },
    },
    {
      id: 'rutinas-activas',
      etiqueta: 'Rutinas activas',
      valor: 89,
      icono: 'bi-clipboard2-pulse-fill',
      tendencia: {
        valor: 0,
        prefijo: '',
        sufijo: '%',
        detalle: 'sin cambios esta semana',
        tono: 'neutro',
      },
    },
  ],
  progreso: {
    titulo: 'Usuarios activos',
    descripcion: 'Evolución durante los últimos seis meses',
    unidad: 'usuarios activos',
    etiquetas: ['Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago'],
    valores: [218, 236, 259, 281, 317, 346],
    resumen: {
      etiqueta: 'Total actual',
      valor: 346,
      detalle: '29 usuarios más que el mes anterior',
    },
  },
  ejerciciosPopulares: [
    { id: 1, nombre: 'Press de banca', categoria: 'Pecho', usos: 154 },
    { id: 2, nombre: 'Sentadilla', categoria: 'Piernas', usos: 142 },
    { id: 3, nombre: 'Peso muerto', categoria: 'Fuerza', usos: 119 },
    { id: 4, nombre: 'Prensa de piernas', categoria: 'Piernas', usos: 105 },
    { id: 5, nombre: 'Jalón al pecho', categoria: 'Espalda', usos: 94 },
  ],
  actividadReciente: [
    {
      id: 1,
      titulo: 'Nuevo usuario registrado',
      detalle: 'Carlos Ramírez',
      icono: 'bi-person-plus-fill',
      minutosAtras: 8,
    },
    {
      id: 2,
      titulo: 'Nueva rutina creada',
      detalle: 'Hipertrofia intermedia',
      icono: 'bi-clipboard2-pulse-fill',
      minutosAtras: 26,
    },
    {
      id: 3,
      titulo: 'Empresa actualizada',
      detalle: 'Power Gym',
      icono: 'bi-buildings-fill',
      minutosAtras: 68,
    },
    {
      id: 4,
      titulo: 'Entrenador incorporado',
      detalle: 'Laura Méndez',
      icono: 'bi-person-badge-fill',
      minutosAtras: 155,
    },
  ],
}

const LATENCIA_MINIMA = 300
const LATENCIA_MAXIMA = 600

const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function calcularLatencia() {
  return Math.floor(LATENCIA_MINIMA + Math.random() * (LATENCIA_MAXIMA - LATENCIA_MINIMA + 1))
}

function clonarResumen() {
  return structuredClone(RESUMEN_DASHBOARD)
}

export async function obtenerDashboardMock() {
  await esperar(calcularLatencia())

  const resumen = clonarResumen()
  const ahora = Date.now()

  resumen.actividadReciente = resumen.actividadReciente.map(({ minutosAtras, ...actividad }) => ({
    ...actividad,
    fecha: new Date(ahora - minutosAtras * 60_000).toISOString(),
  }))

  const { banner, ...dashboard } = resumen
  return { dashboard, banner }
}
