import { HttpError } from '@/core/api/http-error'

const LATENCIA_MINIMA = 150
const LATENCIA_MAXIMA = 350

function simularLatencia() {
  const tiempo =
    Math.floor(Math.random() * (LATENCIA_MAXIMA - LATENCIA_MINIMA + 1)) + LATENCIA_MINIMA
  return new Promise((resolve) => setTimeout(resolve, tiempo))
}

const ahora = new Date()
const enHoras = (h) => new Date(ahora.getTime() + h * 3600 * 1000).toISOString()
const haceDias = (d) => new Date(ahora.getTime() - d * 24 * 3600 * 1000).toISOString()

const NOTIFICACIONES_INICIALES = [
  {
    id: 1,
    idEmpresas: 1,
    nombreEmpresa: 'Iron Core Miraflores',
    idUsuarios: null,
    nombreUsuario: null,
    tipo: 'recordatorio',
    titulo: 'Mantenimiento preventivo en zona de peso libre',
    mensaje:
      'Estimados socios, el área de mancuernas estará cerrada por mantenimiento técnico este sábado de 14:00 a 18:00.',
    fechaEnvio: enHoras(24),
    leida: false,
    enviada: false,
    creadaEn: haceDias(1),
  },
  {
    id: 2,
    idEmpresas: null,
    nombreEmpresa: null,
    idUsuarios: 1,
    nombreUsuario: 'Carlos Mendoza',
    tipo: 'rutina',
    titulo: 'Nueva rutina de hipertrofia disponible',
    mensaje:
      'Tu entrenador ha actualizado tu bloque de fuerza para las próximas 4 semanas. ¡Revisa los nuevos pesos!',
    fechaEnvio: enHoras(48),
    leida: false,
    enviada: false,
    creadaEn: haceDias(1),
  },
  {
    id: 3,
    idEmpresas: null,
    nombreEmpresa: null,
    idUsuarios: null,
    nombreUsuario: null,
    tipo: 'sistema',
    titulo: 'Actualización de la App Gym Bros 2.4',
    mensaje:
      'Incluye mejoras en el registro de comidas, cálculo automático de macros y nuevo temporizador de descansos.',
    fechaEnvio: enHoras(72),
    leida: false,
    enviada: false,
    creadaEn: haceDias(2),
  },
  {
    id: 4,
    idEmpresas: null,
    nombreEmpresa: null,
    idUsuarios: 2,
    nombreUsuario: 'Lucía Torres',
    tipo: 'alimentacion',
    titulo: 'Plan nutricional ajustado',
    mensaje:
      'Hemos recalculado tu ingesta calórica según tu último pesaje y porcentaje graso. Consulta tu pestaña de nutrición.',
    fechaEnvio: haceDias(1),
    leida: true,
    enviada: true,
    creadaEn: haceDias(1),
  },
  {
    id: 5,
    idEmpresas: 2,
    nombreEmpresa: 'Titan Fitness San Isidro',
    idUsuarios: null,
    nombreUsuario: null,
    tipo: 'suscripcion',
    titulo: 'Renovación de convenio corporativo',
    mensaje:
      'El convenio Gym Bros Gold ha sido extendido por 12 meses más con acceso libre a todas las sedes.',
    fechaEnvio: haceDias(2),
    leida: false,
    enviada: true,
    creadaEn: haceDias(2),
  },
  {
    id: 6,
    idEmpresas: null,
    nombreEmpresa: null,
    idUsuarios: 3,
    nombreUsuario: 'Marcos Rivas',
    tipo: 'recordatorio',
    titulo: 'Tu evaluación física mensual es hoy',
    mensaje:
      'Recuerda asistir con ropa deportiva 15 minutos antes a tu cita con el especialista biométrico.',
    fechaEnvio: haceDias(3),
    leida: true,
    enviada: true,
    creadaEn: haceDias(3),
  },
  {
    id: 7,
    idEmpresas: null,
    nombreEmpresa: null,
    idUsuarios: null,
    nombreUsuario: null,
    tipo: 'sistema',
    titulo: 'Felicitaciones a los finalistas del Desafío Iron 2026',
    mensaje:
      'Más de 400 atletas completaron el desafío de sentadilla y dominadas. Consulta la tabla de líderes en el muro.',
    fechaEnvio: haceDias(5),
    leida: true,
    enviada: true,
    creadaEn: haceDias(5),
  },
]

let notificaciones = NOTIFICACIONES_INICIALES.map((n) => ({ ...n }))
let siguienteId = 8

export function reiniciarNotificacionesMock() {
  notificaciones = NOTIFICACIONES_INICIALES.map((n) => ({ ...n }))
  siguienteId = 8
}

export async function contarNoLeidasMock() {
  await simularLatencia()
  return notificaciones.filter((n) => n.enviada && !n.leida).length
}

export async function listarNotificacionesRecibidasMock() {
  await simularLatencia()
  return notificaciones
    .filter((n) => n.enviada)
    .sort((a, b) => new Date(b.fechaEnvio) - new Date(a.fechaEnvio))
}

export async function listarNotificacionesProgramadasMock() {
  await simularLatencia()
  return notificaciones
    .filter((n) => !n.enviada)
    .sort((a, b) => new Date(a.fechaEnvio) - new Date(b.fechaEnvio))
}

export async function listarNotificacionesEnviadasMock({
  pagina = 1,
  porPagina = 6,
  tipo = '',
  busqueda = '',
} = {}) {
  await simularLatencia()

  let filtradas = notificaciones.filter((n) => n.enviada)

  if (tipo) {
    filtradas = filtradas.filter((n) => n.tipo === tipo)
  }

  if (busqueda) {
    const termino = busqueda.toLowerCase().trim()
    filtradas = filtradas.filter(
      (n) =>
        n.titulo.toLowerCase().includes(termino) ||
        n.mensaje.toLowerCase().includes(termino) ||
        (n.nombreEmpresa && n.nombreEmpresa.toLowerCase().includes(termino)) ||
        (n.nombreUsuario && n.nombreUsuario.toLowerCase().includes(termino)),
    )
  }

  filtradas.sort((a, b) => new Date(b.fechaEnvio) - new Date(a.fechaEnvio))

  const total = filtradas.length
  const ultimaPagina = Math.ceil(total / porPagina) || 1
  const inicio = (pagina - 1) * porPagina
  const fin = inicio + porPagina
  const items = filtradas.slice(inicio, fin)

  return {
    items,
    // Mismo contrato que `normalizarListado` da a la respuesta de Laravel.
    paginacion: {
      pagina,
      ultimaPagina,
      porPagina,
      total,
    },
  }
}

export async function crearNotificacionMock(datos) {
  await simularLatencia()

  if (!datos.titulo?.trim() || !datos.mensaje?.trim()) {
    throw new HttpError(422, 'Datos incompletos', {
      titulo: !datos.titulo ? ['El título es obligatorio.'] : undefined,
      mensaje: !datos.mensaje ? ['El mensaje es obligatorio.'] : undefined,
    })
  }

  const esProgramada = Boolean(datos.programar && datos.fechaEnvio)
  const fechaEnvio = esProgramada ? datos.fechaEnvio : new Date().toISOString()

  const nueva = {
    id: siguienteId++,
    idEmpresas: datos.idEmpresas ?? null,
    nombreEmpresa: datos.nombreEmpresa ?? null,
    idUsuarios: datos.idUsuarios ?? null,
    nombreUsuario: datos.nombreUsuario ?? null,
    tipo: datos.tipo || 'otro',
    titulo: datos.titulo.trim(),
    mensaje: datos.mensaje.trim(),
    fechaEnvio,
    leida: false,
    enviada: !esProgramada,
    creadaEn: new Date().toISOString(),
  }

  notificaciones.unshift(nueva)
  return nueva
}

export async function enviarNotificacionAhoraMock(id) {
  await simularLatencia()
  const encontrada = notificaciones.find((n) => n.id === Number(id))
  if (!encontrada) {
    throw new HttpError(404, 'Notificación no encontrada.')
  }

  encontrada.enviada = true
  encontrada.fechaEnvio = new Date().toISOString()
  return encontrada
}

export async function eliminarNotificacionMock(id) {
  await simularLatencia()
  const indice = notificaciones.findIndex((n) => n.id === Number(id))
  if (indice === -1) {
    throw new HttpError(404, 'Notificación no encontrada.')
  }

  notificaciones.splice(indice, 1)
  return { ok: true }
}
