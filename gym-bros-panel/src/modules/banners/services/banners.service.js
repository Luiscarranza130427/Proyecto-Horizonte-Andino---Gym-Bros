import api from '@/core/api/api'
import { crearNormalizadorDeError, ejecutarPeticion } from '@/core/api/normalizacion'
import { resolverUrlStorage } from '@/shared/utils/storage'

const normalizarError = crearNormalizadorDeError({
  imagen: 'imagen',
  contenido_text: 'contenido',
  texto_boton: 'textoBoton',
  enlace_boton: 'enlaceBoton',
})

function normalizarBanner(datos = {}) {
  return {
    id: datos.id,
    imagen: resolverUrlStorage(datos.imagen ?? datos.imagen_url ?? ''),
    contenido: String(datos.contenido_text ?? datos.contenido ?? '').trim(),
    textoBoton: String(datos.texto_boton ?? datos.textoBoton ?? '').trim(),
    enlaceBoton: String(datos.enlace_boton ?? datos.enlaceBoton ?? '').trim(),
  }
}

function extraerLista(datos) {
  if (Array.isArray(datos?.data)) return datos.data
  if (Array.isArray(datos)) return datos
  return []
}

function crearFormData(datos, incluirImagen) {
  const formulario = new FormData()
  formulario.append('contenido_text', datos.contenido.trim())
  formulario.append('texto_boton', datos.textoBoton.trim())
  formulario.append('enlace_boton', datos.enlaceBoton.trim())
  if (incluirImagen && datos.imagen instanceof File) formulario.append('imagen', datos.imagen)
  return formulario
}

const ejecutar = (peticion) => ejecutarPeticion(peticion, normalizarError)

export async function obtenerBanners() {
  return ejecutar(async () => {
    const { data } = await api.get('/banners')
    return extraerLista(data).map(normalizarBanner)
  })
}

export async function crearBanner(datos) {
  return ejecutar(async () => {
    const { data } = await api.post('/banners', crearFormData(datos, true))
    return normalizarBanner(data.data ?? data)
  })
}

export async function actualizarBanner(id, datos) {
  // PHP no interpreta multipart/form-data en un PUT: el cuerpo llegaba vacío,
  // la API respondía 200 sin cambiar nada y el panel anunciaba el guardado.
  // Se envía como POST y Laravel lo enruta como PUT por `_method`.
  return ejecutar(async () => {
    const formulario = crearFormData(datos, datos.imagen instanceof File)
    formulario.append('_method', 'PUT')
    const { data } = await api.post(`/banners/${id}`, formulario)
    return normalizarBanner(data.data ?? data)
  })
}

export async function eliminarBanner(id) {
  return ejecutar(async () => {
    const { data } = await api.delete(`/banners/${id}`)
    return data.data ?? data
  })
}
