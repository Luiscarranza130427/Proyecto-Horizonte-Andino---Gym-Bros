<script setup>
import {
  Building2,
  CheckCircle2,
  Clock,
  RotateCw,
  Send,
  ShieldCheck,
  Trash2,
  User,
  Users,
} from 'lucide-vue-next'
import { computed } from 'vue'

import { obtenerMetadatosTipo } from '@/modules/notificaciones/catalogos'
import { formatearFecha } from '@/shared/utils/formato'

const props = defineProps({
  notificacion: { type: Object, required: true },
  modo: {
    type: String,
    default: 'programada',
    validator: (valor) => ['programada', 'enviada', 'recibida'].includes(valor),
  },
  procesando: { type: Boolean, default: false },
})

defineEmits(['enviar-ahora', 'eliminar', 'duplicar'])

const metaTipo = computed(() => obtenerMetadatosTipo(props.notificacion.tipo))

const esProgramada = computed(() => props.modo === 'programada' || !props.notificacion.enviada)
const esRecibida = computed(() => props.modo === 'recibida')

const fechaLegible = computed(() => {
  const fecha = props.notificacion.fechaEnvio || props.notificacion.creadaEn
  if (!fecha) return 'Fecha no disponible'
  try {
    return formatearFecha(fecha, {
      dia: '2-digit',
      mes: 'short',
      año: 'numeric',
      hora: '2-digit',
      minuto: '2-digit',
    })
  } catch {
    return fecha
  }
})

const destinatarioTexto = computed(() => {
  if (props.notificacion.nombreUsuario) {
    return `Usuario: ${props.notificacion.nombreUsuario}`
  }
  if (props.notificacion.nombreEmpresa) {
    return `Empresa: ${props.notificacion.nombreEmpresa}`
  }
  if (props.notificacion.idUsuarios) {
    return `Usuario #${props.notificacion.idUsuarios}`
  }
  if (props.notificacion.idEmpresas) {
    return `Empresa #${props.notificacion.idEmpresas}`
  }
  return 'Todos los usuarios'
})

const iconoDestinatario = computed(() => {
  if (props.notificacion.idUsuarios || props.notificacion.nombreUsuario) {
    return User
  }
  if (props.notificacion.idEmpresas || props.notificacion.nombreEmpresa) {
    return Building2
  }
  return Users
})
</script>

<template>
  <article
    class="notificacion-card gb-tarjeta"
    :class="{ 'notificacion-card--programada': esProgramada }"
  >
    <div class="notificacion-card__cabecera">
      <div class="notificacion-card__metas">
        <span
          class="notificacion-card__tipo-badge"
          :style="{ color: metaTipo.color, backgroundColor: metaTipo.colorFondo }"
        >
          <component :is="metaTipo.icono" :size="14" aria-hidden="true" />
          <span>{{ metaTipo.etiqueta }}</span>
        </span>

        <span class="notificacion-card__destinatario-badge">
          <component :is="iconoDestinatario" :size="14" aria-hidden="true" />
          <span>{{ destinatarioTexto }}</span>
        </span>
      </div>

      <time class="notificacion-card__fecha" :datetime="notificacion.fechaEnvio">
        <component :is="esProgramada ? Clock : Send" :size="14" aria-hidden="true" />
        <span>
          {{ esProgramada ? 'Programada:' : esRecibida ? 'Recibida:' : 'Enviada:' }}
          {{ fechaLegible }}
        </span>
      </time>
    </div>

    <div class="notificacion-card__cuerpo">
      <h3 class="notificacion-card__titulo">{{ notificacion.titulo }}</h3>
      <p class="notificacion-card__mensaje">{{ notificacion.mensaje }}</p>
    </div>

    <footer class="notificacion-card__acciones">
      <template v-if="esProgramada">
        <button
          v-if="!esRecibida"
          type="button"
          class="btn btn-primary btn-sm notificacion-card__btn-enviar"
          :disabled="procesando"
          @click="$emit('enviar-ahora', notificacion.id)"
        >
          <Send :size="14" aria-hidden="true" />
          <span>Enviar ahora</span>
        </button>

        <button
          type="button"
          class="btn btn-ghost btn-sm notificacion-card__btn-eliminar"
          :disabled="procesando"
          title="Cancelar y eliminar notificación"
          @click="$emit('eliminar', notificacion)"
        >
          <Trash2 :size="14" aria-hidden="true" />
          <span>Cancelar</span>
        </button>
      </template>

      <template v-else>
        <div class="notificacion-card__estado-envio">
          <span
            class="notificacion-card__leida-tag"
            :class="{ 'notificacion-card__leida-tag--activa': notificacion.leida }"
          >
            <component
              :is="notificacion.leida ? CheckCircle2 : ShieldCheck"
              :size="14"
              aria-hidden="true"
            />
            <span>{{ notificacion.leida ? 'Leída por usuarios' : 'Entregada' }}</span>
          </span>
        </div>

        <button
          type="button"
          class="btn btn-ghost btn-sm notificacion-card__btn-duplicar"
          @click="$emit('duplicar', notificacion)"
        >
          <RotateCw :size="14" aria-hidden="true" />
          <span>Reutilizar</span>
        </button>
      </template>
    </footer>
  </article>
</template>

<style scoped>
.notificacion-card {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
  transition:
    background-color 0.18s ease,
    border-color 0.18s ease,
    transform 0.18s ease;
}

.notificacion-card:hover {
  background-color: var(--gb-surface-high);
  border-color: var(--gb-border-soft);
  transform: translateY(-1px);
}

.notificacion-card__cabecera {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.notificacion-card__metas {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.notificacion-card__tipo-badge,
.notificacion-card__destinatario-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.25rem 0.625rem;
  border-radius: var(--gb-radius-pill);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

.notificacion-card__destinatario-badge {
  background-color: var(--gb-surface-highest);
  color: var(--gb-text);
  border: 1px solid var(--gb-border);
}

.notificacion-card__fecha {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  white-space: nowrap;
}

.notificacion-card__cuerpo {
  display: grid;
  gap: 0.375rem;
}

.notificacion-card__titulo {
  margin: 0;
  font-size: var(--gb-tipo-md);
  font-family: var(--gb-fuente-titulo);
  color: var(--gb-text);
}

.notificacion-card__mensaje {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  line-height: 1.5;
  white-space: pre-wrap;
}

.notificacion-card__acciones {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 0.625rem;
  padding-top: 0.875rem;
  margin-top: auto;
  border-top: 1px solid var(--gb-border);
}

.notificacion-card__btn-enviar,
.notificacion-card__btn-eliminar,
.notificacion-card__btn-duplicar {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  min-height: 2.125rem;
  padding-inline: 0.875rem;
  font-size: var(--gb-tipo-xxs);
}

.notificacion-card__btn-eliminar:hover:not(:disabled) {
  color: var(--gb-error);
  border-color: var(--gb-error);
}

.notificacion-card__estado-envio {
  margin-right: auto;
}

.notificacion-card__leida-tag {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 500;
}

.notificacion-card__leida-tag--activa {
  color: var(--gb-green);
}

@media (max-width: 42rem) {
  .notificacion-card__cabecera {
    flex-direction: column;
    align-items: flex-start;
  }

  .notificacion-card__acciones {
    justify-content: stretch;
  }

  .notificacion-card__acciones .btn {
    flex: 1;
    justify-content: center;
  }
}
</style>
