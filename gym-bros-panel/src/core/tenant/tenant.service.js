import api from '@/core/api/api'
import { HttpError } from '@/core/api/http-error'
import { USE_MOCKS } from '@/core/config/env'
import { leerSesion } from '@/core/storage/session.storage'

export async function obtenerTenantActual() {
  if (USE_MOCKS) {
    return {
      id: 1,
      nombre: 'Gym Bros Central',
      slug: 'gym-bros-central',
      activo: true,
      planSaaS: 'Enterprise',
      limiteUsuarios: 1000,
      logo: '',
      color1: '#2563EB',
      color2: '#111827',
    }
  }

  // La API no expone /tenant/current: la empresa de la sesión se pide por su id.
  // GET /empresas/{id} ya está limitado por la API a la empresa del usuario.
  const sesion = leerSesion()
  const usuarioSesion = sesion?.usuario
  const tenantId = usuarioSesion?.tenantId ?? usuarioSesion?.id_empresas ?? null
  if (!tenantId) throw new HttpError(401, 'Tu sesión no identifica una empresa.')

  const { data: respuesta } = await api.get(`/empresas/${tenantId}`)
  const empresa = respuesta?.data ?? respuesta
  if (!empresa?.id) throw new HttpError(404, 'La empresa de tu sesión no existe en la API.')

  return {
    id: empresa.id,
    nombre: empresa.nombre ?? '',
    slug: empresa.nombre ? empresa.nombre.toLowerCase().replace(/\s+/g, '-') : '',
    logo: empresa.logo_url || empresa.logo || '',
    color1: empresa.color_1 ?? '',
    color2: empresa.color_2 ?? '',
    banner1: empresa.banner_1 || '',
    region: empresa.region ?? '',
    direccion: empresa.direccion || '',
    telefono: empresa.telefono || '',
    correo: empresa.correo || '',
    enlaceWeb: empresa.enlace_web || '',
    activo: empresa.estado === 1 || empresa.estado === true,
    planSaaS: null,
    limiteUsuarios: null,
  }
}
