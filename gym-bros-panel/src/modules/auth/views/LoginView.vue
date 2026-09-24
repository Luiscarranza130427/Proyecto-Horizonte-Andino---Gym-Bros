<script setup>
import { ArrowRight, Eye, EyeOff, Mail, ShieldCheck } from 'lucide-vue-next'
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useAuthStore } from '@/core/auth/auth.store'
import { solicitarRestablecimientoContrasena } from '@/core/auth/auth.service'

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

const correo = ref('')
const contrasena = ref('')
const mensajeError = ref('')
const mostrarContrasena = ref(false)
const recuperando = ref(false)
const mostrandoRecuperacion = ref(false)
const mensajeRecuperacion = ref('')
const errorRecuperacion = ref('')
const errorCorreoRecuperacion = ref('')
const reintentoEn = ref(0)
const campoCorreo = useTemplateRef('campoCorreo')
let temporizadorReintento = null

const hayError = computed(() => Boolean(mensajeError.value))

onMounted(() => {
  campoCorreo.value?.focus()
})

onBeforeUnmount(() => {
  if (temporizadorReintento) window.clearInterval(temporizadorReintento)
})

function destinoSeguro(redirect) {
  const alDashboard = { name: 'dashboard' }

  if (typeof redirect !== 'string' || !redirect.startsWith('/')) return alDashboard

  const segundoCaracter = redirect.charAt(1)
  if (segundoCaracter === '/' || segundoCaracter === '\\') return alDashboard

  const resuelta = router.resolve(redirect)
  const esRutaConocida = resuelta.matched.length > 0 && resuelta.name !== 'catch-all'

  return esRutaConocida ? redirect : alDashboard
}

async function enviar() {
  mensajeError.value = ''

  if (!correo.value || !contrasena.value) {
    mensajeError.value = 'Introduce tu correo y tu contraseña.'
    return
  }

  try {
    await auth.iniciarSesion({ correo: correo.value, contrasena: contrasena.value })
    await router.replace(destinoSeguro(route.query.redirect))
  } catch (error) {
    mensajeError.value = error.message || 'No se ha podido iniciar sesión.'
  }
}

function segundosDeRetryAfter(retryAfter) {
  const segundos = Number(retryAfter)
  if (Number.isFinite(segundos) && segundos > 0) return Math.ceil(segundos)

  const fecha = Date.parse(retryAfter)
  if (Number.isNaN(fecha)) return 0
  return Math.max(0, Math.ceil((fecha - Date.now()) / 1000))
}

function esperarReintento(segundos) {
  if (temporizadorReintento) window.clearInterval(temporizadorReintento)
  reintentoEn.value = segundos
  if (!segundos) return

  temporizadorReintento = window.setInterval(() => {
    reintentoEn.value = Math.max(0, reintentoEn.value - 1)
    if (!reintentoEn.value) {
      window.clearInterval(temporizadorReintento)
      temporizadorReintento = null
    }
  }, 1000)
}

function abrirRecuperacion() {
  mensajeError.value = ''
  mostrandoRecuperacion.value = true
}

function volverAlLogin() {
  mostrandoRecuperacion.value = false
  mensajeRecuperacion.value = ''
  errorRecuperacion.value = ''
  errorCorreoRecuperacion.value = ''
  esperarReintento(0)
}

async function enviarRecuperacion() {
  if (recuperando.value || reintentoEn.value) return

  mensajeRecuperacion.value = ''
  errorRecuperacion.value = ''
  errorCorreoRecuperacion.value = ''
  if (!correo.value) {
    errorCorreoRecuperacion.value = 'Introduce tu correo electrónico.'
    return
  }

  recuperando.value = true
  try {
    const respuesta = await solicitarRestablecimientoContrasena(correo.value)
    mensajeRecuperacion.value = respuesta.message
  } catch (error) {
    errorCorreoRecuperacion.value = error.status === 422 ? error.errors?.correo?.[0] || '' : ''
    errorRecuperacion.value = error.message || 'No se pudo solicitar el enlace de recuperación.'
    if (error.status === 429) esperarReintento(segundosDeRetryAfter(error.retryAfter))
  } finally {
    recuperando.value = false
  }
}
</script>

<template>
  <section aria-labelledby="titulo-login">
    <!--
      El título va oculto a la vista, no eliminado: sin ningún encabezado la
      página deja de ser navegable para un lector de pantalla, y el `<section>`
      se quedaría con un `aria-labelledby` apuntando a nada.
    -->
    <h1 id="titulo-login" class="visually-hidden">Iniciar sesión</h1>

    <p
      v-if="!mostrandoRecuperacion && mensajeError"
      id="error-login"
      class="alert alert-danger login__error"
      role="alert"
    >
      {{ mensajeError }}
    </p>

    <form v-if="!mostrandoRecuperacion" novalidate @submit.prevent="enviar">
      <div class="login__campo">
        <label class="form-label" for="correo">Correo electrónico</label>
        <div class="login__control">
          <Mail class="login__icono" :size="16" aria-hidden="true" />
          <input
            id="correo"
            ref="campoCorreo"
            v-model.trim="correo"
            class="form-control"
            type="email"
            name="correo"
            autocomplete="username"
            placeholder="juan.perez@gmail.com"
            required
            :aria-invalid="hayError"
            :aria-describedby="hayError ? 'error-login' : undefined"
          />
        </div>
      </div>

      <div class="login__campo">
        <label class="form-label" for="contrasena">Contraseña</label>
        <div class="login__control">
          <ShieldCheck class="login__icono" :size="16" aria-hidden="true" />
          <input
            id="contrasena"
            v-model="contrasena"
            class="form-control"
            :type="mostrarContrasena ? 'text' : 'password'"
            name="contrasena"
            autocomplete="current-password"
            placeholder="Tu contraseña"
            required
            :aria-invalid="hayError"
            :aria-describedby="hayError ? 'error-login' : undefined"
          />
          <button
            type="button"
            class="login__mostrar"
            :aria-pressed="mostrarContrasena"
            :aria-label="mostrarContrasena ? 'Ocultar contraseña' : 'Mostrar contraseña'"
            @click="mostrarContrasena = !mostrarContrasena"
          >
            <component :is="mostrarContrasena ? EyeOff : Eye" :size="16" aria-hidden="true" />
          </button>
        </div>
      </div>

      <button type="submit" class="btn btn-primary login__enviar" :disabled="auth.cargando">
        <span
          v-if="auth.cargando"
          class="spinner-border spinner-border-sm"
          aria-hidden="true"
        ></span>
        <span>{{ auth.cargando ? 'Entrando…' : 'Entrar al dashboard' }}</span>
        <ArrowRight :size="16" aria-hidden="true" />
      </button>
      <button type="button" class="login__recuperar" @click="abrirRecuperacion">
        Olvidé mi contraseña
      </button>
    </form>

    <section v-else class="login__recuperacion" aria-labelledby="titulo-recuperacion">
      <h2 id="titulo-recuperacion">Recupera tu contraseña</h2>
      <p class="login__recuperacion-texto">
        Recibirás un enlace para cambiar tu contraseña en la web. Después deberás iniciar sesión
        nuevamente.
      </p>

      <p v-if="mensajeRecuperacion" class="alert alert-success login__mensaje" role="status">
        {{ mensajeRecuperacion }}
      </p>
      <p v-if="errorRecuperacion" class="alert alert-danger login__error" role="alert">
        {{ errorRecuperacion }}
      </p>

      <form novalidate @submit.prevent="enviarRecuperacion">
        <div class="login__campo">
          <label class="form-label" for="correo-recuperacion">Correo electrónico</label>
          <div class="login__control">
            <Mail class="login__icono" :size="16" aria-hidden="true" />
            <input
              id="correo-recuperacion"
              v-model.trim="correo"
              class="form-control"
              type="email"
              name="correo"
              autocomplete="email"
              placeholder="juan.perez@gmail.com"
              required
              :disabled="recuperando"
              :aria-invalid="Boolean(errorCorreoRecuperacion)"
              :aria-describedby="errorCorreoRecuperacion ? 'error-correo-recuperacion' : undefined"
            />
          </div>
          <p v-if="errorCorreoRecuperacion" id="error-correo-recuperacion" class="campo__error">
            {{ errorCorreoRecuperacion }}
          </p>
        </div>

        <button
          type="submit"
          class="btn btn-primary login__enviar"
          :disabled="recuperando || reintentoEn > 0"
        >
          <span
            v-if="recuperando"
            class="spinner-border spinner-border-sm"
            aria-hidden="true"
          ></span>
          <span v-else-if="reintentoEn > 0">Reintenta en {{ reintentoEn }} s</span>
          <span v-else>Enviar enlace</span>
        </button>
        <button
          v-if="errorRecuperacion"
          type="button"
          class="btn btn-secondary login__reintentar"
          :disabled="recuperando || reintentoEn > 0"
          @click="enviarRecuperacion"
        >
          Reintentar
        </button>
        <button
          type="button"
          class="login__recuperar"
          :disabled="recuperando"
          @click="volverAlLogin"
        >
          Volver a iniciar sesión
        </button>
      </form>
    </section>
  </section>
</template>

<style scoped>
.login__error {
  padding-block: 0.5rem;
}

.login__campo + .login__campo {
  margin-top: 0.875rem;
}

.login__control {
  position: relative;
}

.login__control > .login__icono,
.login__control > :deep(svg:first-child) {
  position: absolute;
  top: 50%;
  left: 0.875rem;
  z-index: 1;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
  pointer-events: none;
}

.login__control .form-control {
  min-height: 2.75rem;
  padding-left: 2.75rem;
  border-radius: 0.875rem;
}

.login__control .form-control:has(+ .login__mostrar) {
  padding-right: 3rem;
}

.login__mostrar {
  position: absolute;
  top: 50%;
  right: 0.375rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.25rem;
  height: 2.25rem;
  padding: 0;
  background: transparent;
  border: 0;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
}

.login__mostrar:hover {
  color: var(--gb-text);
}

.login__enviar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  width: 100%;
  min-height: 2.875rem;
  margin-top: 1.25rem;
  border-radius: 0.875rem;
}

.login__recuperar {
  display: block;
  width: max-content;
  margin: 0.9rem auto 0;
  padding: 0;
  border: 0;
  background: transparent;
  color: var(--gb-text-soft);
  font-size: var(--gb-tipo-xs);
  text-decoration: underline;
  text-underline-offset: 0.2rem;
}

.login__recuperar:hover:not(:disabled) {
  color: var(--gb-text);
}

.login__recuperacion h2 {
  margin: 0;
  font-size: var(--gb-tipo-md);
}

.login__recuperacion-texto {
  margin: 0.45rem 0 1rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  line-height: 1.45;
}

.login__mensaje {
  margin-bottom: 1rem;
}

.login__reintentar {
  width: 100%;
  margin-top: 0.65rem;
}

@media (max-height: 48rem) and (min-width: 42.01rem) {
  .login__campo + .login__campo {
    margin-top: 0.75rem;
  }

  .login__enviar {
    margin-top: 1rem;
  }
}
</style>
