export const SERVICIOS_PLAN = [
  'Gestión de usuarios',
  'Rutinas y ejercicios',
  'Planes de alimentación',
  'Notificaciones',
  'Reportes administrativos',
  'Soporte por WhatsApp',
  'Atención prioritaria',
  'Acompañamiento de implementación',
  'Soporte especializado',
]

export function serviciosDesdeContenido(contenido = '') {
  return String(contenido)
    .split(/\r?\n/)
    .map((servicio) => servicio.replace(/^[-•]\s*/, '').trim())
    .filter(Boolean)
}
