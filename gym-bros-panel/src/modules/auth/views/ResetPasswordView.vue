<script setup>
import { Eye, EyeOff, KeyRound, LockKeyhole, Mail } from 'lucide-vue-next'
import { computed, onMounted, ref, useTemplateRef } from 'vue'
import { RouterLink } from 'vue-router'

import { restablecerContrasena } from '@/core/auth/auth.service'

const correo = ref('')
const token = ref('')
const password = ref('')
const passwordConfirmation = ref('')
const mostrandoPassword = ref(false)
const enviando = ref(false)
const mensaje = ref('')
const errorGeneral = ref('')
const errores = ref({})
const campoPassword = useTemplateRef('campoPassword')

const enlaceIncompleto = computed(() => !correo.value || !token.value)

function limpiarFragmento() {
  const parametros = new URLSearchParams(window.location.hash.slice(1))
  correo.value = parametros.get('correo')?.trim() || ''
  token.value = parametros.get('token') || ''
  window.history.replaceState(null, '', `${window.location.pathname}${window.location.search}`)
}

function validar() {
  const nuevosErrores = {}
  if (password.value.length < 12) {
    nuevosErrores.password = 'La contraseña debe tener al menos 12 caracteres.'
  } else if (!/[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/.test(password.value) || !/\d/.test(password.value)) {
    nuevosErrores.password = 'La contraseña debe incluir letras y números.'
  }
  if (password.value !== passwordConfirmation.value) {
    nuevosErrores.password_confirmation = 'Las contraseñas no coinciden.'
  }
  errores.value = nuevosErrores
  return Object.keys(nuevosErrores).length === 0
}

function errorDe(campo) {
  return errores.value[campo] || ''
}

async function enviar() {
  if (enviando.value || enlaceIncompleto.value || !validar()) return

  errorGeneral.value = ''
  mensaje.value = ''
  enviando.value = true
  try {
    const respuesta = await restablecerContrasena({
      correo: correo.value,
      token: token.value,
      password: password.value,
      password_confirmation: passwordConfirmation.value,
    })
    mensaje.value = respuesta.message
    password.value = ''
    passwordConfirmation.value = ''
  } catch (error) {
    const erroresServidor = error.status === 422 ? error.errors || {} : {}
    errores.value = {
      password: erroresServidor.password?.[0] || '',
      password_confirmation: erroresServidor.password_confirmation?.[0] || '',
      token: erroresServidor.token?.[0] || '',
    }
    errorGeneral.value = error.message || 'No se pudo restablecer la contraseña.'
  } finally {
    enviando.value = false
  }
}

onMounted(() => {
  limpiarFragmento()
  campoPassword.value?.focus()
})
</script>

<template>
  <section class="restablecer" aria-labelledby="titulo-restablecer">
    <header>
      <span class="restablecer__icono" aria-hidden="true"><KeyRound :size="22" /></span>
      <div>
        <h1 id="titulo-restablecer">Crea una nueva contraseña</h1>
        <p>Usa al menos 12 caracteres, incluyendo letras y números.</p>
      </div>
    </header>

    <p v-if="enlaceIncompleto" class="alert alert-danger" role="alert">
      El enlace de recuperación no es válido o está incompleto. Solicita uno nuevo desde el inicio
      de sesión.
    </p>
    <p v-else-if="mensaje" class="alert alert-success" role="status">{{ mensaje }}</p>
    <p v-else-if="errorGeneral" class="alert alert-danger" role="alert">{{ errorGeneral }}</p>

    <form v-if="!mensaje && !enlaceIncompleto" novalidate @submit.prevent="enviar">
      <div class="restablecer__campo">
        <label class="form-label" for="restablecer-correo">Correo electrónico</label>
        <div class="restablecer__control">
          <Mail :size="16" aria-hidden="true" />
          <input
            id="restablecer-correo"
            :value="correo"
            class="form-control"
            type="email"
            disabled
          />
        </div>
      </div>

      <div class="restablecer__campo">
        <label class="form-label" for="restablecer-password">Nueva contraseña</label>
        <div class="restablecer__control">
          <LockKeyhole :size="16" aria-hidden="true" />
          <input
            id="restablecer-password"
            ref="campoPassword"
            v-model="password"
            class="form-control"
            :type="mostrandoPassword ? 'text' : 'password'"
            autocomplete="new-password"
            minlength="12"
            :disabled="enviando"
            :aria-invalid="Boolean(errorDe('password'))"
            :aria-describedby="errorDe('password') ? 'error-restablecer-password' : undefined"
            @input="errores.password = ''"
          />
          <button
            type="button"
            class="restablecer__mostrar"
            :aria-label="mostrandoPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
            :aria-pressed="mostrandoPassword"
            @click="mostrandoPassword = !mostrandoPassword"
          >
            <component :is="mostrandoPassword ? EyeOff : Eye" :size="16" aria-hidden="true" />
          </button>
        </div>
        <p v-if="errorDe('password')" id="error-restablecer-password" class="campo__error">
          {{ errorDe('password') }}
        </p>
      </div>

      <div class="restablecer__campo">
        <label class="form-label" for="restablecer-confirmacion">Confirma la contraseña</label>
        <div class="restablecer__control">
          <LockKeyhole :size="16" aria-hidden="true" />
          <input
            id="restablecer-confirmacion"
            v-model="passwordConfirmation"
            class="form-control"
            :type="mostrandoPassword ? 'text' : 'password'"
            autocomplete="new-password"
            minlength="12"
            :disabled="enviando"
            :aria-invalid="Boolean(errorDe('password_confirmation'))"
            :aria-describedby="
              errorDe('password_confirmation') ? 'error-restablecer-confirmacion' : undefined
            "
            @input="errores.password_confirmation = ''"
          />
        </div>
        <p
          v-if="errorDe('password_confirmation')"
          id="error-restablecer-confirmacion"
          class="campo__error"
        >
          {{ errorDe('password_confirmation') }}
        </p>
      </div>

      <p v-if="errorDe('token')" class="campo__error" role="alert">{{ errorDe('token') }}</p>

      <button type="submit" class="btn btn-primary restablecer__enviar" :disabled="enviando">
        <span v-if="enviando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        <span>{{ enviando ? 'Actualizando…' : 'Actualizar contraseña' }}</span>
      </button>
    </form>

    <RouterLink class="restablecer__volver" :to="{ name: 'login' }"
      >Volver a iniciar sesión</RouterLink
    >
  </section>
</template>

<style scoped>
.restablecer header {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}
.restablecer h1 {
  margin: 0;
  font-size: var(--gb-tipo-lg);
}
.restablecer header p {
  margin: 0.3rem 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}
.restablecer__icono {
  display: grid;
  width: 2.6rem;
  height: 2.6rem;
  place-items: center;
  border: 1px solid rgba(225, 29, 20, 0.3);
  border-radius: var(--gb-radius);
  color: var(--gb-red-text);
  background: rgba(225, 29, 20, 0.1);
}
.restablecer__campo + .restablecer__campo {
  margin-top: 0.9rem;
}
.restablecer__control {
  position: relative;
}
.restablecer__control > svg {
  position: absolute;
  top: 50%;
  left: 0.875rem;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
  pointer-events: none;
}
.restablecer__control .form-control {
  min-height: 2.75rem;
  padding-left: 2.75rem;
  border-radius: 0.875rem;
}
.restablecer__control .form-control:has(+ .restablecer__mostrar) {
  padding-right: 3rem;
}
.restablecer__mostrar {
  position: absolute;
  top: 50%;
  right: 0.375rem;
  display: inline-flex;
  width: 2.25rem;
  height: 2.25rem;
  place-items: center;
  padding: 0;
  border: 0;
  background: transparent;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
}
.restablecer__enviar {
  display: flex;
  width: 100%;
  min-height: 2.875rem;
  margin-top: 1.25rem;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  border-radius: 0.875rem;
}
.restablecer__volver {
  display: block;
  width: max-content;
  margin: 0.9rem auto 0;
  color: var(--gb-text-soft);
  font-size: var(--gb-tipo-xs);
  text-underline-offset: 0.2rem;
}
</style>
