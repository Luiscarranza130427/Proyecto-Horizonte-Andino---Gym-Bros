import { createApp } from 'vue'
import { createPinia } from 'pinia'

// Bootstrap primero y los estilos propios después, para que los tokens de
// Gym Bros puedan sobrescribir a los de Bootstrap por orden de cascada.
// No se importa el CSS distribuido completo, sino la selección de parciales que
// el panel usa de verdad: ver `@/assets/styles/bootstrap.scss`.
// Los iconos ya no son una fuente: son SVG en línea (`@/components/base/Icono.vue`).
import '@/assets/styles/bootstrap.scss'
import '@/assets/styles/main.css'

import App from '@/App.vue'
import router from '@/app/router'
import { registrarManejadorNoAutorizado, registrarProveedorDeToken } from '@/core/api/api'
import { useAuthStore } from '@/core/auth/auth.store'

const app = createApp(App)

/*
 * Red de seguridad. Sin esto, un error en el `setup` de cualquier componente
 * deja la pantalla en blanco sin traza: Vue lo captura y no lo propaga a la
 * consola, así que ni el usuario ve nada ni el desarrollador se entera.
 *
 * No se intenta recuperar la aplicación, sólo dejar constancia: adivinar cómo
 * seguir tras un error desconocido produce estados peores que el fallo.
 *
 * Cuando haya un servicio de monitorización (Sentry o similar), este es el
 * punto donde se le envía.
 */
/**
 * Muestra el fallo en pantalla en lugar de dejar el hueco negro.
 *
 * Cuando Vue no puede seguir renderizando, desmonta y `#app` queda vacío: el
 * usuario ve un rectángulo oscuro, sin texto ni botón, y no tiene forma de
 * saber si la aplicación murió o simplemente tarda. Peor aún, no puede contar
 * qué pasó porque no hay nada que contar.
 *
 * Se construye con DOM plano a propósito: si Vue acaba de fallar, montar otro
 * componente de Vue para explicarlo puede fallar igual.
 */
function mostrarPantallaDeError(error, donde) {
  if (document.getElementById('gb-error-fatal')) return

  const capa = document.createElement('div')
  capa.id = 'gb-error-fatal'
  capa.setAttribute('role', 'alert')
  capa.style.cssText = [
    'position:fixed',
    'inset:0',
    'z-index:9999',
    'display:grid',
    'place-items:center',
    'padding:2rem',
    'background:#141414',
    'color:#f5f5f5',
    'font-family:system-ui,sans-serif',
    'text-align:center',
  ].join(';')

  const detalle = String(error?.stack || error?.message || error || 'Error desconocido')

  const caja = document.createElement('div')
  caja.style.cssText = 'max-width:44rem'
  caja.innerHTML =
    '<h1 style="margin:0 0 .75rem;font-size:1.4rem;text-transform:uppercase">' +
    'Algo se rompió en esta pantalla</h1>' +
    '<p style="margin:0 0 1.25rem;color:#a3a3a3">' +
    'La aplicación no pudo continuar. Copia el detalle de abajo si necesitas reportarlo.</p>'

  const pre = document.createElement('pre')
  pre.textContent = `${donde ? `[${donde}] ` : ''}${detalle}`
  pre.style.cssText = [
    'max-height:14rem',
    'margin:0 0 1.25rem',
    'padding:.875rem',
    'overflow:auto',
    'background:#0a0a0a',
    'border:1px solid #2e2e2e',
    'border-radius:.5rem',
    'color:#ff6b6b',
    'font-size:.8rem',
    'text-align:left',
    'white-space:pre-wrap',
  ].join(';')

  const boton = document.createElement('button')
  boton.type = 'button'
  boton.textContent = 'Recargar la página'
  boton.style.cssText =
    'padding:.7rem 1.5rem;background:#e50914;border:0;border-radius:.6rem;' +
    'color:#fff;font-weight:700;cursor:pointer'
  boton.addEventListener('click', () => window.location.reload())

  caja.append(pre, boton)
  capa.append(caja)
  document.body.append(capa)
}

app.config.errorHandler = (error, _instancia, informacion) => {
  console.error(`[Gym Bros] Error no capturado en ${informacion}:`, error)
  mostrarPantallaDeError(error, informacion)
}

// Un error fuera de Vue —en un manejador de eventos, en una promesa suelta—
// también puede dejar la pantalla inservible sin que Vue se entere.
window.addEventListener('error', (evento) => {
  mostrarPantallaDeError(evento.error ?? evento.message, 'window.error')
})

window.addEventListener('unhandledrejection', (evento) => {
  mostrarPantallaDeError(evento.reason, 'promesa sin capturar')
})

// Los avisos de Vue en desarrollo también pasan por aquí; en producción Vue no
// los emite, así que no hay coste en el bundle público.
app.config.warnHandler = (aviso, _instancia, traza) => {
  console.warn(`[Gym Bros] ${aviso}${traza}`)
}

/*
 * Una navegación que falla por un error de carga —un chunk que no se descarga
 * porque se ha desplegado una versión nueva, por ejemplo— deja al usuario
 * parado sin explicación. Al menos queda registrado.
 */
router.onError((error, to) => {
  console.error(`[Gym Bros] La navegación a "${to.fullPath}" falló:`, error)
})

// Pinia antes que el router: los guards consultan el store de autenticación en
// la primera navegación, que se dispara al instalar el router.
app.use(createPinia())
app.use(router)

// El cliente HTTP toma el token del store en cada petición. Así no hay dos
// copias del token y `api.js` sigue sin importar Pinia.
registrarProveedorDeToken(() => useAuthStore().token)

// Un 401 del backend significa que la sesión ya no sirve. Se limpia sólo el
// estado local (`olvidarSesion`) para no volver a llamar al backend y entrar en
// bucle, y se devuelve al usuario al login conservando a dónde quería ir.
registrarManejadorNoAutorizado(() => {
  useAuthStore().olvidarSesion()

  const rutaActual = router.currentRoute.value
  if (rutaActual.name !== 'login') {
    // El `.catch()` no sobra: si el 401 llega mientras hay una navegación en
    // curso, vue-router rechaza esta promesa con un NavigationFailure y quedaría
    // como rechazo sin capturar en la consola. Que la redirección se pierda es
    // aceptable —el guard mandará al login igualmente—; ensuciar la consola con
    // un error que no lo es, no.
    router.push({ name: 'login', query: { redirect: rutaActual.fullPath } }).catch(() => {})
  }
})

app.mount('#app')
