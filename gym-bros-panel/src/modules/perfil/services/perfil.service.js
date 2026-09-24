import api from '@/core/api/api'
import { HttpError } from '@/core/api/http-error'
import { USE_MOCKS } from '@/core/config/env'
import { leerSesion } from '@/core/storage/session.storage'

const cargarMock = () => import('@/modules/perfil/mocks/perfil.mock')

/** Los días tal como los nombran las columnas de `empresas`, sin tildes. */
const DIAS = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo']

/** Los 14 campos de horario de la empresa, con su nombre exacto del esquema. */
function horariosDeLaSemana(empresa = {}) {
  return Object.fromEntries(
    DIAS.flatMap((dia) => [
      [`horario_inicio_${dia}`, empresa[`horario_inicio_${dia}`] ?? ''],
      [`horario_fin_${dia}`, empresa[`horario_fin_${dia}`] ?? ''],
    ]),
  )
}

export async function obtenerPerfil() {
  if (USE_MOCKS) {
    const { obtenerPerfilMock } = await cargarMock()
    return obtenerPerfilMock()
  }

  /*
   * Componer el perfil desde /empresas/{id} y /usuarios. La API no expone
   * `GET /perfil`: sondearlo dejaba un 404 en cada carga de esta pantalla.
   *
   * Aquí NO se inventa nada. Antes esta función rellenaba cada campo vacío con
   * un literal —'Titan Gym', el RUC 20609876541, una dirección de Cajamarca,
   * 340 accesos, una IP— de modo que con la API caída la pantalla mostraba una
   * ficha completa y falsa, sin distinguirse en nada de una real. Un error es
   * preferible: se ve.
   *
   * `/empresas` es obligatorio y su fallo se propaga. `/usuarios` sólo aporta el
   * recuento de miembros, así que su caída deja ese dato en nulo en vez de
   * tumbar la pantalla entera.
   */
  const sesion = leerSesion()
  const usuarioSesion = sesion?.usuario
  const tenantId = usuarioSesion?.tenantId ?? usuarioSesion?.id_empresas ?? null

  try {
    if (!tenantId) throw new HttpError(404, 'Tu sesión no identifica una empresa.')
    const respEmpresa = await api.get(`/empresas/${tenantId}`)
    const empresaDb = respEmpresa.data?.data ?? respEmpresa.data

    if (!empresaDb?.id) {
      throw new HttpError(404, 'La empresa de tu sesión no existe en la API.')
    }

    let totalMiembros = null
    try {
      const respUsuarios = await api.get('/usuarios')
      const listaUsuarios = Array.isArray(respUsuarios.data)
        ? respUsuarios.data
        : (respUsuarios.data?.data ?? [])
      totalMiembros = listaUsuarios.filter((u) => u.id_empresas === empresaDb.id).length
    } catch {
      // Sin recuento: la ficha se muestra igual y ese dato queda vacío.
    }

    return {
      id: empresaDb.id ?? null,
      nombre: empresaDb.nombre ?? '',
      nombre_gerente: empresaDb.nombre_gerente ?? '',
      gerente: empresaDb.nombre_gerente ?? '',
      correo: empresaDb.correo ?? '',
      telefono: empresaDb.telefono ?? '',
      ruc: empresaDb.ruc ?? '',
      region: empresaDb.region ?? '',
      direccion: empresaDb.direccion ?? '',
      enlace_web: empresaDb.enlace_web ?? '',
      logo: empresaDb.logo ?? '',
      fotoPerfil: empresaDb.logo ?? '',
      color_1: empresaDb.color_1 ?? '',
      color_2: empresaDb.color_2 ?? '',
      banner_1: empresaDb.banner_1 ?? '',
      banner_2: empresaDb.banner_2 ?? '',
      banner_3: empresaDb.banner_3 ?? '',
      /*
       * Los CATORCE horarios, uno de apertura y uno de cierre por día.
       *
       * Antes sólo se pasaban lunes, sábado y domingo, así que de martes a
       * viernes la cabecera decía «Sin datos» aunque la API los tuviera. Se
       * derivan de `DIAS` para que no se pueda volver a olvidar uno.
       */
      ...horariosDeLaSemana(empresaDb),
      rol: usuarioSesion?.rol ?? usuarioSesion?.tipo_usuario ?? '',
      rolEtiqueta: usuarioSesion?.rol ?? usuarioSesion?.tipo_usuario ?? '',
      /*
       * El plan sale de `suscripciones`, no de `empresas`, y ese cruce todavía
       * no está resuelto. Va nulo en vez de «Titanio Enterprise», que era un
       * literal: mostrar un plan inventado en una pantalla de facturación es
       * justo donde más caro sale equivocarse.
       */
      plan: null,
      planSaaS: null,
      estado:
        empresaDb.estado === 1 || empresaDb.estado === true
          ? 'activo'
          : empresaDb.estado === 0 || empresaDb.estado === false
            ? 'inactivo'
            : '',
      estadisticas: {
        // `accesosTotales`, `sesionesActivas` y `ultimoAcceso` no existen en la
        // API. Antes eran 340, 1 y «Hoy a las 16:40», fijos en el código.
        accesosTotales: null,
        miembrosActivos: totalMiembros,
        sesionesActivas: null,
        miembroDesde: empresaDb.fecha_registro
          ? new Date(empresaDb.fecha_registro).toLocaleDateString('es-PE', {
              month: 'long',
              year: 'numeric',
            })
          : '',
        ultimoAcceso: '',
      },
      // El backend no registra las sesiones abiertas. La única que había era
      // inventada, con su IP y su navegador.
      sesiones: [],
      preferencias: {
        idioma: 'es',
        tema: 'oscuro',
        notifEmail: true,
        notifPush: true,
        notifPagos: true,
        notifSeguridad: true,
      },
    }
  } catch (err) {
    throw new HttpError(500, err.message || 'Error al obtener datos de la empresa desde la API.')
  }
}

export async function actualizarPerfil(datos) {
  if (USE_MOCKS) {
    const { actualizarPerfilMock } = await cargarMock()
    return actualizarPerfilMock(datos)
  }

  if (!datos.id) throw new HttpError(422, 'No se identificó la empresa que se debe actualizar.')

  const { data } = await api.put(`/empresas/${datos.id}`, datos)
  return data.data ?? data
}

export async function cambiarContrasena({ actual, nueva, confirmacion }) {
  if (USE_MOCKS) {
    const { cambiarContrasenaMock } = await cargarMock()
    return cambiarContrasenaMock({ actual, nueva, confirmacion })
  }

  const { data } = await api.post('/perfil/cambiar-contrasena', {
    password_actual: actual,
    password_nuevo: nueva,
    password_confirmacion: confirmacion,
  })
  return data.data ?? data
}

export async function actualizarPreferencias(preferencias) {
  if (USE_MOCKS) {
    const { actualizarPreferenciasMock } = await cargarMock()
    return actualizarPreferenciasMock(preferencias)
  }

  const { data } = await api.put('/perfil/preferencias', preferencias)
  return data.data ?? data
}

export async function cerrarOtrasSesiones() {
  if (USE_MOCKS) {
    const { cerrarOtrasSesionesMock } = await cargarMock()
    return cerrarOtrasSesionesMock()
  }

  const { data } = await api.post('/perfil/cerrar-otras-sesiones')
  return data.data ?? data
}
