<script setup>
import { Building2, Camera, CheckCircle2, Clock, MapPin, Users, Zap } from 'lucide-vue-next'
import { computed, ref, useTemplateRef } from 'vue'

import { inicialesDe } from '@/shared/utils/iniciales'
import {
  LOGO_EMPRESA_ALTO,
  LOGO_EMPRESA_ANCHO,
  normalizarLogoEmpresa,
} from '@/shared/utils/logoEmpresa'
import { resolverUrlStorage } from '@/shared/utils/storage'

const props = defineProps({
  perfil: {
    type: Object,
    required: true,
  },
  cargandoFoto: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['cambiar-foto'])

const inputFoto = useTemplateRef('inputFoto')
const vistaPreviaLocal = ref(null)
const procesandoLogo = ref(false)
const errorLogo = ref('')

const iniciales = computed(() => {
  return inicialesDe(props.perfil.nombre ?? '')
})

const avatarUrl = computed(() => {
  if (vistaPreviaLocal.value) return vistaPreviaLocal.value
  const logo = props.perfil.logo || props.perfil.fotoPerfil
  return logo ? resolverUrlStorage(logo) : null
})

function seleccionarArchivo() {
  inputFoto.value?.click()
}

async function alCambiarArchivo(evento) {
  const archivo = evento.target.files?.[0]
  if (!archivo) return

  errorLogo.value = ''
  procesandoLogo.value = true

  try {
    const url = await normalizarLogoEmpresa(archivo)
    vistaPreviaLocal.value = url
    emit('cambiar-foto', {
      archivo,
      url,
      ancho: LOGO_EMPRESA_ANCHO,
      alto: LOGO_EMPRESA_ALTO,
    })
  } catch (error) {
    errorLogo.value = error.message || 'No se pudo preparar el logo.'
  } finally {
    procesandoLogo.value = false
    evento.target.value = ''
  }
}
</script>

<template>
  <header class="perfil-hero gb-tarjeta" aria-label="Resumen corporativo del gimnasio">
    <div class="perfil-hero__principal">
      <!-- Logo con botón de actualización -->
      <div class="perfil-hero__avatar-contenedor">
        <div class="perfil-hero__avatar-marco">
          <div class="perfil-hero__avatar">
            <img
              v-if="avatarUrl"
              :src="avatarUrl"
              :alt="`Logo oficial de ${perfil.nombre}`"
              class="perfil-hero__imagen"
            />
            <span v-else class="perfil-hero__iniciales" aria-hidden="true">
              {{ iniciales }}
            </span>
          </div>

          <button
            type="button"
            class="perfil-hero__btn-camara"
            title="Actualizar logo del gimnasio"
            aria-label="Actualizar logo del gimnasio"
            :disabled="cargandoFoto || procesandoLogo"
            @click="seleccionarArchivo"
          >
            <Camera :size="16" aria-hidden="true" />
          </button>

          <input
            ref="inputFoto"
            type="file"
            accept="image/png,image/jpeg,image/webp"
            class="visually-hidden"
            aria-hidden="true"
            @change="alCambiarArchivo"
          />
        </div>

        <p class="perfil-hero__logo-ayuda">
          Formato automático: {{ LOGO_EMPRESA_ANCHO }} × {{ LOGO_EMPRESA_ALTO }} px
        </p>
        <p v-if="errorLogo" class="perfil-hero__logo-error" role="alert">
          {{ errorLogo }}
        </p>
      </div>

      <!-- Datos de identidad de la empresa -->
      <div class="perfil-hero__identidad">
        <div class="perfil-hero__etiquetas">
          <span class="perfil-hero__badge perfil-hero__badge--rol">
            <CheckCircle2 :size="14" aria-hidden="true" />
            <span>Sede Oficial SaaS</span>
          </span>
          <span class="perfil-hero__badge perfil-hero__badge--estado">
            <Zap :size="14" aria-hidden="true" />
            <span>{{ perfil.plan ?? 'Sin plan informado' }}</span>
          </span>
        </div>

        <h1 class="perfil-hero__nombre">{{ perfil.nombre }}</h1>
        <p class="perfil-hero__gerente">
          <span
            >Gerente / Admin:
            <strong>{{
              perfil.nombre_gerente ?? perfil.gerente ?? 'Sin información'
            }}</strong></span
          >
          <span class="perfil-hero__separador">·</span>
          <span>{{ perfil.correo }}</span>
        </p>

        <div class="perfil-hero__ubicacion">
          <MapPin :size="14" aria-hidden="true" />
          <span
            >{{ perfil.direccion ?? 'Sin dirección' }} ({{ perfil.region ?? 'Sin región' }},
            Perú)</span
          >
        </div>
      </div>
    </div>

    <!-- Estadísticas operativas -->
    <div class="perfil-hero__metricas">
      <div class="perfil-hero__metrica">
        <span class="perfil-hero__metrica-label">
          <Users :size="13" aria-hidden="true" /> Atletas de tu sede
        </span>
        <strong class="perfil-hero__metrica-valor">
          {{
            perfil.estadisticas?.miembrosActivos == null
              ? 'Sin datos'
              : `${perfil.estadisticas.miembrosActivos} miembros`
          }}
        </strong>
      </div>
      <div class="perfil-hero__metrica">
        <span class="perfil-hero__metrica-label">
          <Clock :size="13" aria-hidden="true" /> Horario hoy
        </span>
        <strong class="perfil-hero__metrica-valor">Sin datos</strong>
      </div>
      <div class="perfil-hero__metrica">
        <span class="perfil-hero__metrica-label">
          <Building2 :size="13" aria-hidden="true" /> RUC Sede
        </span>
        <strong class="perfil-hero__metrica-valor">{{ perfil.ruc ?? 'Sin datos' }}</strong>
      </div>
    </div>
  </header>
</template>

<style scoped>
.perfil-hero {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem;
  padding: 1.75rem;
  border-radius: var(--gb-radius-xl);
  border: 1px solid var(--gb-border);
  background: linear-gradient(135deg, var(--gb-surface) 0%, var(--gb-surface-high) 100%);
  box-shadow: var(--gb-relieve);
}

.perfil-hero__principal {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  min-width: 0;
}

.perfil-hero__avatar-contenedor {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.4rem;
  flex-shrink: 0;
}

.perfil-hero__avatar-marco {
  position: relative;
}

.perfil-hero__logo-ayuda,
.perfil-hero__logo-error {
  width: max-content;
  max-width: 12rem;
  margin: 0;
  font-size: 0.625rem;
  line-height: 1.25;
  text-align: center;
}

.perfil-hero__logo-ayuda {
  color: var(--gb-text-muted);
}

.perfil-hero__logo-error {
  color: var(--gb-error);
}

.perfil-hero__avatar {
  display: grid;
  place-items: center;
  width: 5.75rem;
  height: 5.75rem;
  border-radius: var(--gb-radius-lg);
  border: 2px solid var(--gb-red);
  background-color: var(--gb-surface-highest);
  box-shadow: 0 0 16px rgba(229, 9, 20, 0.25);
  overflow: hidden;
  padding: 0.25rem;
}

.perfil-hero__imagen {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.perfil-hero__iniciales {
  color: var(--gb-red-text);
  font-family: var(--gb-fuente-titulo);
  font-size: 1.75rem;
  font-weight: 900;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.perfil-hero__btn-camara {
  position: absolute;
  bottom: -0.25rem;
  right: -0.25rem;
  display: grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  border-radius: var(--gb-radius-full);
  border: 2px solid var(--gb-surface);
  background-color: var(--gb-red);
  color: var(--gb-on-red);
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.5);
  transition:
    transform 0.2s ease,
    background-color 0.2s ease;
}

.perfil-hero__btn-camara:hover {
  background-color: var(--gb-red-hover);
  transform: scale(1.1);
}

.perfil-hero__identidad {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
}

.perfil-hero__etiquetas {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

.perfil-hero__badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.2rem 0.6rem;
  border-radius: var(--gb-radius-pill);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.perfil-hero__badge--rol {
  background-color: rgba(34, 197, 94, 0.15);
  border: 1px solid rgba(34, 197, 94, 0.35);
  color: #22c55e;
}

.perfil-hero__badge--estado {
  background-color: rgba(238, 255, 0, 0.12);
  border: 1px solid rgba(238, 255, 0, 0.3);
  color: var(--gb-accent);
}

.perfil-hero__nombre {
  margin: 0;
  font-family: var(--gb-fuente-titulo);
  font-size: clamp(1.4rem, 2.2vw, 1.85rem);
  font-weight: 900;
  letter-spacing: -0.01em;
  text-transform: uppercase;
  color: var(--gb-text);
  line-height: 1.1;
}

.perfil-hero__gerente {
  margin: 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-soft);
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.4rem;
}

.perfil-hero__gerente strong {
  color: var(--gb-text);
}

.perfil-hero__separador {
  color: var(--gb-text-muted);
}

.perfil-hero__ubicacion {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 600;
}

.perfil-hero__metricas {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding-left: 1.5rem;
  border-left: 1px solid var(--gb-border);
}

.perfil-hero__metrica {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}

.perfil-hero__metrica-label {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.perfil-hero__metrica-valor {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-sm);
  font-weight: 800;
  color: var(--gb-text);
}

@media (max-width: 64rem) {
  .perfil-hero {
    flex-direction: column;
    align-items: stretch;
  }

  .perfil-hero__metricas {
    padding-left: 0;
    padding-top: 1.25rem;
    border-left: 0;
    border-top: 1px solid var(--gb-border);
    justify-content: space-between;
  }
}

@media (max-width: 36rem) {
  .perfil-hero__principal {
    flex-direction: column;
    text-align: center;
    align-items: center;
  }

  .perfil-hero__identidad {
    align-items: center;
  }

  .perfil-hero__etiquetas {
    justify-content: center;
  }

  .perfil-hero__gerente {
    justify-content: center;
  }

  .perfil-hero__metricas {
    flex-direction: column;
    gap: 0.75rem;
    align-items: center;
    text-align: center;
  }
}
</style>
