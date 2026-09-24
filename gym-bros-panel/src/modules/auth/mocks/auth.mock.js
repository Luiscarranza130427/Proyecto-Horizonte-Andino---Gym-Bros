import { HttpError } from '@/core/api/http-error'

export const CREDENCIALES_DEMO = {
  correo: 'admin@gymbros.com',
  contrasena: 'admin123',
}

export const PISTA_DEMO = {
  correo: CREDENCIALES_DEMO.correo,
  contrasena: CREDENCIALES_DEMO.contrasena,
}

const LATENCIA_MOCK = 400

const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

export async function iniciarSesionMock({ correo, contrasena }) {
  await esperar(LATENCIA_MOCK)

  const correoNormalizado = (correo ?? '').trim().toLowerCase()
  const demoCorreo = CREDENCIALES_DEMO.correo.toLowerCase()

  if (correoNormalizado !== demoCorreo || contrasena !== CREDENCIALES_DEMO.contrasena) {
    throw new HttpError(401, 'Credenciales incorrectas. Revisa tu correo y contraseña.')
  }

  return {
    usuario: {
      id: 1,
      nombre: 'Administrador Demo',
      correo: CREDENCIALES_DEMO.correo,
      rol: 'admin',
      tenantId: 1,
    },
    token: 'mock-jwt-token-admin-gym-bros-2026',
  }
}

export async function cerrarSesionMock() {
  await esperar(150)
  return { ok: true }
}

export async function solicitarRestablecimientoContrasenaMock(correo) {
  await esperar(250)
  if (!correo)
    throw new HttpError(422, 'Introduce tu correo electrónico.', { correo: ['Obligatorio.'] })
  return {
    message:
      'Si el correo está registrado, recibirás las instrucciones para restablecer tu contraseña.',
  }
}

export async function restablecerContrasenaMock({
  correo,
  token,
  password,
  password_confirmation,
}) {
  await esperar(250)
  const errores = {}
  if (!correo) errores.correo = ['El correo es obligatorio.']
  if (!token) errores.token = ['El enlace de recuperación no es válido o venció.']
  if (!password || password.length < 12) {
    errores.password = ['La contraseña debe tener al menos 12 caracteres.']
  }
  if (password !== password_confirmation) {
    errores.password_confirmation = ['Las contraseñas no coinciden.']
  }
  if (Object.keys(errores).length)
    throw new HttpError(422, 'Revisa los datos introducidos.', errores)
  return { message: 'Tu contraseña fue actualizada. Ya puedes iniciar sesión.' }
}
