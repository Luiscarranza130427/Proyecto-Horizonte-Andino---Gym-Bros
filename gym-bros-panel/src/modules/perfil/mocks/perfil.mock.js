import { HttpError } from '@/core/api/http-error'

const LATENCIA_MOCK = 300
const esperar = (ms = LATENCIA_MOCK) => new Promise((resolve) => setTimeout(resolve, ms))

let perfilActual = {
  id: 1,
  nombre: 'Luis',
  apellido: 'Carranza',
  correo: 'admin@gymbros.com',
  telefono: '+51 987 654 321',
  tipoDocumento: 'DNI',
  numeroDocumento: '72849102',
  fechaNacimiento: '1995-06-15',
  biografia: 'Administrador general y responsable de la plataforma SaaS Gym Bros.',
  rol: 'admin',
  rolEtiqueta: 'Super Administrador',
  fotoPerfil: '',
  estado: 'activo',
  empresa: {
    id: 1,
    nombre: 'Gym Bros Central HQ',
    ruc: '20609876541',
    plan: 'Titanio Enterprise',
    direccion: 'Av. Javier Prado Este 4200, Lima',
  },
  estadisticas: {
    accesosTotales: 148,
    ultimoAcceso: 'Hoy a las 15:42',
    sesionesActivas: 2,
    miembroDesde: 'Enero 2025',
  },
  sesiones: [
    {
      id: 'sess-01',
      dispositivo: 'Navegador Web (Chrome 128 / Windows 11)',
      ubicacion: 'Lima, Perú',
      ip: '190.237.45.112',
      esActual: true,
      ultimoAcceso: 'Activo ahora',
    },
    {
      id: 'sess-02',
      dispositivo: 'App Móvil Gym Bros (iOS 18 / iPhone 15 Pro)',
      ubicacion: 'Lima, Perú',
      ip: '181.65.12.89',
      esActual: false,
      ultimoAcceso: 'Ayer a las 20:15',
    },
  ],
  preferencias: {
    idioma: 'es',
    tema: 'oscuro',
    notifEmail: true,
    notifPush: true,
    notifPagos: true,
    notifSeguridad: true,
  },
}

export async function obtenerPerfilMock() {
  await esperar()
  return JSON.parse(JSON.stringify(perfilActual))
}

export async function actualizarPerfilMock(datos) {
  await esperar()
  if (!datos.nombre?.trim() || !datos.apellido?.trim()) {
    throw new HttpError(422, 'El nombre y apellido son obligatorios.')
  }

  perfilActual = {
    ...perfilActual,
    nombre: datos.nombre.trim(),
    apellido: datos.apellido.trim(),
    telefono: datos.telefono ?? perfilActual.telefono,
    tipoDocumento: datos.tipoDocumento ?? perfilActual.tipoDocumento,
    numeroDocumento: datos.numeroDocumento ?? perfilActual.numeroDocumento,
    fechaNacimiento: datos.fechaNacimiento ?? perfilActual.fechaNacimiento,
    biografia: datos.biografia ?? perfilActual.biografia,
    fotoPerfil: datos.fotoPerfil !== undefined ? datos.fotoPerfil : perfilActual.fotoPerfil,
  }

  return JSON.parse(JSON.stringify(perfilActual))
}

export async function cambiarContrasenaMock({ actual, nueva, confirmacion }) {
  await esperar()
  if (!actual || !nueva || !confirmacion) {
    throw new HttpError(422, 'Completa todos los campos de contraseña.')
  }
  if (nueva.length < 6) {
    throw new HttpError(422, 'La nueva contraseña debe tener al menos 6 caracteres.')
  }
  if (nueva !== confirmacion) {
    throw new HttpError(422, 'La confirmación de la contraseña no coincide.')
  }
  if (actual !== 'admin123') {
    throw new HttpError(401, 'La contraseña actual ingresada es incorrecta.')
  }

  return { exito: true, mensaje: 'Contraseña actualizada correctamente.' }
}

export async function actualizarPreferenciasMock(nuevasPreferencias) {
  await esperar()
  perfilActual.preferencias = {
    ...perfilActual.preferencias,
    ...nuevasPreferencias,
  }
  return JSON.parse(JSON.stringify(perfilActual.preferencias))
}

export async function cerrarOtrasSesionesMock() {
  await esperar()
  perfilActual.sesiones = perfilActual.sesiones.filter((s) => s.esActual)
  perfilActual.estadisticas.sesionesActivas = 1
  return { exito: true, mensaje: 'Se cerraron todas las demás sesiones activas.' }
}
