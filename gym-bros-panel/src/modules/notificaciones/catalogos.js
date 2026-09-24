import {
  Banknote,
  Bell,
  Building2,
  Clock,
  Dumbbell,
  Megaphone,
  Users,
  Utensils,
} from 'lucide-vue-next'

/**
 * Catálogos y constantes del módulo de Notificaciones.
 *
 * Sigue el contrato de base de datos definido en `docs/MODELO_DE_DATOS.md`:
 * `tipo` ENUM ('recordatorio', 'rutina', 'alimentacion', 'suscripcion', 'sistema', 'otro').
 */

export const TIPOS_NOTIFICACION = [
  {
    valor: 'recordatorio',
    etiqueta: 'Recordatorio',
    descripcion: 'Avisos de asistencia, horarios y seguimiento general.',
    icono: Clock,
    color: '#ffab00',
    colorFondo: 'rgba(255, 171, 0, 0.12)',
  },
  {
    valor: 'rutina',
    etiqueta: 'Rutina',
    descripcion: 'Nuevos entrenamientos asignados o actualizaciones de series.',
    icono: Dumbbell,
    color: '#e50914',
    colorFondo: 'rgba(229, 9, 20, 0.12)',
  },
  {
    valor: 'alimentacion',
    etiqueta: 'Alimentación',
    descripcion: 'Ajustes en el plan nutricional o recordatorios de comidas.',
    icono: Utensils,
    color: '#00e676',
    colorFondo: 'rgba(0, 230, 118, 0.12)',
  },
  {
    valor: 'suscripcion',
    etiqueta: 'Suscripción',
    descripcion: 'Renovaciones de membresía, pagos y promociones.',
    icono: Banknote,
    color: '#38bdf8',
    colorFondo: 'rgba(56, 189, 248, 0.12)',
  },
  {
    valor: 'sistema',
    etiqueta: 'Sistema',
    descripcion: 'Mantenimientos, anuncios globales o alertas de la plataforma.',
    icono: Megaphone,
    color: '#c084fc',
    colorFondo: 'rgba(192, 132, 252, 0.12)',
  },
  {
    valor: 'otro',
    etiqueta: 'Otro',
    descripcion: 'Comunicados varios y mensajes personalizados.',
    icono: Bell,
    color: '#e5e2e1',
    colorFondo: 'rgba(255, 255, 255, 0.1)',
  },
]

export const DESTINATARIOS_ALCANCE = [
  {
    valor: 'todos',
    etiqueta: 'Todos los usuarios',
    descripcion: 'Envío masivo a toda la base de atletas y clientes activos.',
    icono: Users,
  },
  {
    valor: 'empresa',
    etiqueta: 'Por empresa',
    descripcion: 'Dirigido a todos los usuarios afiliados a un gimnasio o sede.',
    icono: Building2,
  },
]

/**
 * Devuelve los metadatos de visualización para un tipo de notificación.
 * @param {string} tipo
 * @returns {object}
 */
export function obtenerMetadatosTipo(tipo) {
  return (
    TIPOS_NOTIFICACION.find((t) => t.valor === tipo) || {
      valor: tipo || 'otro',
      etiqueta: tipo || 'General',
      descripcion: '',
      icono: Bell,
      color: '#e5e2e1',
      colorFondo: 'rgba(255, 255, 255, 0.1)',
    }
  )
}
