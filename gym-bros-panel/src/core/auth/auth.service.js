import api from '@/core/api/api'
import { HttpError } from '@/core/api/http-error'
import { USE_MOCKS } from '@/core/config/env'

const cargarMock = () => import('@/modules/auth/mocks/auth.mock')

export async function iniciarSesion({ correo, contrasena }) {
  if (USE_MOCKS) {
    const { iniciarSesionMock } = await cargarMock()
    return iniciarSesionMock({ correo, contrasena })
  }

  const correoNormalizado = (correo ?? '').trim().toLowerCase()

  try {
    const respuesta = await api.post('/auth/login', {
      email: correoNormalizado,
      password: contrasena,
      correo: correoNormalizado,
      contrasena,
    })

    // Axios no transforma cuerpos: Laravel envía { data: { token, usuario } }.
    const sesion = respuesta.data?.data
    const token = sesion?.token
    const usuarioData = sesion?.usuario
    if (!token) throw new HttpError(502, 'La API no devolvió un token de sesión.')
    if (!usuarioData) throw new HttpError(502, 'La API no devolvió los datos del usuario.')

    const tenantId =
      usuarioData.tenant_id ?? usuarioData.empresa_id ?? usuarioData.id_empresas ?? null
    const nombreCompleto = [usuarioData.nombres, usuarioData.apellidos]
      .filter(Boolean)
      .join(' ')
      .trim()
    const nombre =
      nombreCompleto ||
      usuarioData.nombre_empresa ||
      usuarioData.name ||
      usuarioData.nombre ||
      usuarioData.apodo ||
      correoNormalizado

    return {
      usuario: {
        id: usuarioData.id,
        nombre,
        nombres: usuarioData.nombres ?? '',
        apellidos: usuarioData.apellidos ?? '',
        apodo: usuarioData.apodo ?? '',
        correo: usuarioData.email || usuarioData.correo || correoNormalizado,
        rol: usuarioData.tipo_usuario ?? usuarioData.rol ?? usuarioData.role ?? 'Usuario',
        tenantId,
        foto:
          usuarioData.foto_perfil_url ??
          usuarioData.logo ??
          usuarioData.logo_empresa ??
          usuarioData.foto_perfil ??
          '',
      },
      token,
    }
  } catch (err) {
    const status = err.status ?? err.response?.status ?? 401

    const mensaje =
      status === 404
        ? 'El inicio de sesión aún no está disponible en la API.'
        : status === 401
          ? 'Correo o contraseña incorrectos.'
          : err.message || 'No se pudo iniciar sesión.'
    throw new HttpError(status, mensaje)
  }
}

/** Solicita el correo de recuperación sin revelar si la cuenta existe. */
export async function solicitarRestablecimientoContrasena(correo) {
  const correoNormalizado = (correo ?? '').trim().toLowerCase()

  if (USE_MOCKS) {
    const { solicitarRestablecimientoContrasenaMock } = await cargarMock()
    return solicitarRestablecimientoContrasenaMock(correoNormalizado)
  }

  const { data } = await api.post(
    '/auth/forgot-password',
    { correo: correoNormalizado },
    { headers: { Accept: 'application/json', 'Content-Type': 'application/json' } },
  )

  return { message: data?.message ?? '' }
}

/** Restablece una contraseña con los datos de un enlace de recuperación. */
export async function restablecerContrasena({ correo, token, password, password_confirmation }) {
  if (USE_MOCKS) {
    const { restablecerContrasenaMock } = await cargarMock()
    return restablecerContrasenaMock({ correo, token, password, password_confirmation })
  }

  const { data } = await api.post(
    '/auth/reset-password',
    { correo, token, password, password_confirmation },
    { headers: { Accept: 'application/json', 'Content-Type': 'application/json' } },
  )

  return { message: data?.message ?? '' }
}

export async function cerrarSesion() {
  if (USE_MOCKS) {
    const { cerrarSesionMock } = await cargarMock()
    return cerrarSesionMock()
  }

  try {
    // Revoca el token en Sanctum; antes se llamaba a /logout, que no existe.
    await api.post('/auth/logout')
  } catch {
    // Si la API falla al cerrar sesión en el servidor, cerramos la sesión local
  }
}

export async function pistaDeCredenciales() {
  if (!USE_MOCKS) return null
  const { PISTA_DEMO } = await cargarMock()
  return PISTA_DEMO
}
