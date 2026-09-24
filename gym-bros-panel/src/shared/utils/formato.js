const FORMATEADOR_NUMEROS = new Intl.NumberFormat('es-PE')
const FORMATEADOR_FECHAS = new Intl.DateTimeFormat('es-PE', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
  timeZone: 'UTC',
})
const FORMATEADOR_FECHA_HORA = new Intl.DateTimeFormat('es-PE', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
})
const FORMATEADOR_MONEDA = new Intl.NumberFormat('es-PE', {
  style: 'currency',
  currency: 'PEN',
  minimumFractionDigits: 2,
})

export function formatearNumero(valor) {
  return FORMATEADOR_NUMEROS.format(Number(valor) || 0)
}

export function formatearMoneda(valor) {
  return FORMATEADOR_MONEDA.format(Number(valor) || 0)
}

export function formatearFecha(fecha) {
  const instante = new Date(fecha)
  return Number.isNaN(instante.getTime())
    ? 'Fecha no disponible'
    : FORMATEADOR_FECHAS.format(instante)
}

export function formatearFechaHora(fecha) {
  const instante = new Date(fecha)
  return !fecha || Number.isNaN(instante.getTime())
    ? 'Fecha no disponible'
    : FORMATEADOR_FECHA_HORA.format(instante)
}

export function formatearTiempoRelativo(fecha, ahora = new Date()) {
  const instante = new Date(fecha)
  if (Number.isNaN(instante.getTime())) return 'Fecha no disponible'

  const diferencia = Math.max(0, ahora.getTime() - instante.getTime())
  const minutos = Math.floor(diferencia / 60_000)

  if (minutos < 1) return 'Ahora'
  if (minutos < 60) return `Hace ${minutos} min`

  const horas = Math.floor(minutos / 60)
  if (horas < 24) return `Hace ${horas} h`

  const dias = Math.floor(horas / 24)
  if (dias < 7) return `Hace ${dias} d`

  return new Intl.DateTimeFormat('es-PE', {
    day: '2-digit',
    month: 'short',
  }).format(instante)
}
