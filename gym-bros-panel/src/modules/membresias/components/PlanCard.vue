<script setup>
import {
  Check,
  ChevronDown,
  Clock,
  Crown,
  Dumbbell,
  ExternalLink,
  Flame,
  Pencil,
  ShieldCheck,
  Sparkles,
  Trash2,
  Users,
  Zap,
} from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

const props = defineProps({
  plan: {
    type: Object,
    required: true,
  },
  gestionable: {
    type: Boolean,
    default: true,
  },
  enlaceAdquisicion: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['eliminar'])

const formatearMonto = (monto) => {
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency: 'PEN',
    minimumFractionDigits: 2,
  }).format(monto || 0)
}

const servicios = computed(() => {
  if (!props.plan.contenido) return []
  return props.plan.contenido
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
})

const esDestacado = computed(() => {
  const nombre = props.plan.nombre?.toLowerCase() || ''
  return nombre.includes('titanio') || nombre.includes('fuerza') || nombre.includes('pro')
})

const porcentajeDescuento = computed(() => {
  if (
    props.plan.precioOriginal &&
    props.plan.precioInicial &&
    props.plan.precioOriginal > props.plan.precioInicial
  ) {
    return Math.round(
      ((props.plan.precioOriginal - props.plan.precioInicial) / props.plan.precioOriginal) * 100,
    )
  }
  return 0
})

const iconoPlan = computed(() => {
  const nombre = props.plan.nombre?.toLowerCase() || ''
  if (nombre.includes('titanio')) return Crown
  if (nombre.includes('fuerza')) return Dumbbell
  if (nombre.includes('pro') || nombre.includes('anual')) return Sparkles
  if (nombre.includes('impulso')) return Zap
  return Flame
})
</script>

<template>
  <article
    class="plan-card gb-tarjeta"
    :class="{
      'plan-card--destacado': esDestacado,
      'plan-card--inactivo': !plan.activo,
    }"
  >
    <div v-if="esDestacado" class="plan-card__cinta">
      <Sparkles :size="12" aria-hidden="true" />
      <span>Más Popular</span>
    </div>

    <div class="plan-card__cuerpo">
      <header class="plan-card__cabecera">
        <div class="plan-card__icono-caja" aria-hidden="true">
          <component :is="iconoPlan" :size="22" />
        </div>
        <div class="plan-card__titulos">
          <h3 class="plan-card__nombre">{{ plan.nombre }}</h3>
          <p class="plan-card__descripcion">{{ plan.descripcion }}</p>
        </div>
        <span
          class="plan-card__badge-estado"
          :class="
            plan.activo ? 'plan-card__badge-estado--activo' : 'plan-card__badge-estado--inactivo'
          "
        >
          {{ plan.activo ? 'Disponible' : 'Inactivo' }}
        </span>
      </header>

      <div class="plan-card__precio-bloque">
        <div class="plan-card__precio-monto">
          <span class="plan-card__precio-actual">{{ formatearMonto(plan.precioInicial) }}</span>
          <span class="plan-card__precio-periodo">/ {{ plan.duracionDias }} días</span>
        </div>

        <div v-if="porcentajeDescuento > 0" class="plan-card__descuento-fila">
          <span class="plan-card__precio-tachado">{{ formatearMonto(plan.precioOriginal) }}</span>
          <span class="plan-card__descuento-tag">-{{ porcentajeDescuento }}% OFF</span>
        </div>
      </div>

      <dl class="plan-card__specs">
        <div class="plan-card__spec">
          <dt><Users :size="15" aria-hidden="true" /> Usuarios</dt>
          <dd>Hasta {{ plan.limiteUsuarios.toLocaleString('es-PE') }}</dd>
        </div>
        <div class="plan-card__spec">
          <dt><Clock :size="15" aria-hidden="true" /> Vigencia</dt>
          <dd>{{ plan.duracionDias }} días</dd>
        </div>
      </dl>

      <details class="plan-card__servicios">
        <summary class="plan-card__servicios-resumen">
          <ShieldCheck :size="14" aria-hidden="true" />
          <span>Beneficios incluidos</span>
          <span class="plan-card__servicios-cantidad">{{ servicios.length }}</span>
          <ChevronDown :size="16" aria-hidden="true" />
        </summary>
        <ul class="plan-card__servicios-lista">
          <li v-for="(servicio, idx) in servicios" :key="idx" class="plan-card__servicio-item">
            <span class="plan-card__check-icono" aria-hidden="true">
              <Check :size="12" />
            </span>
            <span class="plan-card__servicio-texto">{{ servicio }}</span>
          </li>
          <li
            v-if="servicios.length === 0"
            class="plan-card__servicio-item plan-card__servicio-item--vacio"
          >
            <span>Sin servicios adicionales especificados</span>
          </li>
        </ul>
      </details>
    </div>

    <footer class="plan-card__pie">
      <a
        v-if="plan.enlaceWhatsapp"
        :href="plan.enlaceWhatsapp"
        target="_blank"
        rel="noopener noreferrer"
        class="btn btn-secondary plan-card__btn-whatsapp"
        title="Contactar o consultar por WhatsApp"
      >
        <span>WhatsApp</span>
        <ExternalLink :size="14" aria-hidden="true" />
      </a>
      <button v-else type="button" class="btn btn-secondary plan-card__btn-whatsapp" disabled>
        <span>WhatsApp</span>
        <ExternalLink :size="14" aria-hidden="true" />
      </button>

      <div v-if="gestionable" class="plan-card__acciones-secundarias">
        <RouterLink
          class="btn btn-secondary plan-card__btn-editar"
          :to="{ name: 'plan-editar', params: { id: plan.id } }"
          title="Editar plan"
        >
          <Pencil :size="15" aria-hidden="true" />
          <span>Editar</span>
        </RouterLink>

        <button
          type="button"
          class="btn btn-ghost plan-card__btn-eliminar btn-icono-accion--peligro"
          title="Eliminar plan comercial"
          aria-label="Eliminar plan"
          @click="emit('eliminar', plan)"
        >
          <Trash2 :size="16" aria-hidden="true" />
        </button>
      </div>

      <a
        v-else-if="enlaceAdquisicion"
        :href="enlaceAdquisicion"
        class="btn btn-primary plan-card__btn-adquirir"
      >
        <span>Adquirir plan</span>
        <ExternalLink :size="14" aria-hidden="true" />
      </a>
      <button v-else type="button" class="btn btn-primary plan-card__btn-adquirir" disabled>
        <span>Adquirir plan</span>
        <ExternalLink :size="14" aria-hidden="true" />
      </button>
    </footer>
  </article>
</template>

<style scoped>
.plan-card {
  position: relative;
  display: flex;
  flex-direction: column;
  height: 100%;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-xl);
  background: var(--gb-surface);
  padding: 1.25rem;
  overflow: hidden;
}

.plan-card--destacado {
  border-color: rgba(var(--gb-red-rgb), 0.58);
}

.plan-card__cinta {
  display: inline-flex;
  align-self: flex-start;
  align-items: center;
  gap: 0.35rem;
  margin: -1.25rem -1.25rem 0.9rem;
  padding: 0.35rem 0.8rem;
  border-bottom-right-radius: var(--gb-radius);
  background: var(--gb-red);
  color: var(--gb-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 800;
}

.plan-card__cuerpo {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.plan-card__cabecera {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.plan-card__icono-caja {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--gb-radius);
  background: rgba(var(--gb-red-rgb), 0.1);
  border: 1px solid rgba(225, 29, 20, 0.3);
  color: var(--gb-red-text);
  flex-shrink: 0;
}

.plan-card__titulos {
  flex: 1;
  min-width: 0;
}

.plan-card__nombre {
  margin: 0;
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  color: var(--gb-text);
  letter-spacing: -0.01em;
}

.plan-card__descripcion {
  margin: 0.25rem 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  line-height: 1.35;
}

.plan-card__badge-estado {
  margin-top: 0.1rem;
  padding: 0.2rem 0.5rem;
  border-radius: var(--gb-radius-pill);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  white-space: nowrap;
}

.plan-card__badge-estado--activo {
  border: 1px solid rgba(34, 197, 94, 0.3);
  background: rgba(34, 197, 94, 0.12);
  color: #22c55e;
}

.plan-card__badge-estado--inactivo {
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.05);
  color: var(--gb-text-muted);
}

.plan-card__precio-bloque {
  padding: 0.25rem 0 1rem;
  border-bottom: 1px solid var(--gb-border);
}

.plan-card__precio-monto {
  display: flex;
  align-items: baseline;
  gap: 0.4rem;
  flex-wrap: wrap;
}

.plan-card__precio-actual {
  font-family: var(--gb-fuente-titulo);
  font-size: 2rem;
  font-weight: 900;
  color: var(--gb-text);
  letter-spacing: -0.02em;
}

.plan-card__precio-periodo {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 600;
}

.plan-card__descuento-fila {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-top: 0.35rem;
}

.plan-card__precio-tachado {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  text-decoration: line-through;
  opacity: 0.75;
}

.plan-card__descuento-tag {
  border: 1px solid rgba(225, 29, 20, 0.35);
  border-radius: var(--gb-radius-sm);
  background: rgba(225, 29, 20, 0.12);
  color: #ff8a93;
  font-size: var(--gb-tipo-xxs);
  font-weight: 800;
  padding: 0.15rem 0.45rem;
}

.plan-card__specs {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.75rem;
  margin: 1rem 0;
}

.plan-card__spec {
  display: grid;
  gap: 0.18rem;
}

.plan-card__spec dt {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.plan-card__spec dd {
  margin: 0;
  color: var(--gb-text);
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
}

.plan-card__servicios {
  border-top: 1px solid var(--gb-border);
  border-bottom: 1px solid var(--gb-border);
}

.plan-card__servicios-resumen {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.85rem 0;
  cursor: pointer;
  list-style: none;
  color: var(--gb-text-soft);
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
}

.plan-card__servicios-resumen::-webkit-details-marker {
  display: none;
}

.plan-card__servicios-resumen:focus-visible {
  outline: 2px solid var(--gb-red-text);
  outline-offset: -0.2rem;
}

.plan-card__servicios-cantidad {
  display: grid;
  width: 1.25rem;
  height: 1.25rem;
  margin-left: auto;
  place-items: center;
  border-radius: 50%;
  background: var(--gb-surface-high);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.plan-card__servicios-resumen svg:last-child {
  transition: transform 160ms ease;
}

.plan-card__servicios[open] .plan-card__servicios-resumen svg:last-child {
  transform: rotate(180deg);
}

.plan-card__servicios-lista {
  list-style: none;
  margin: 0 0 0.9rem;
  padding: 0;
  display: grid;
  gap: 0.5rem;
}

.plan-card__servicio-item {
  display: flex;
  align-items: flex-start;
  gap: 0.55rem;
  color: var(--gb-text);
  font-size: var(--gb-tipo-xs);
  line-height: 1.3;
}

.plan-card__check-icono {
  display: grid;
  place-items: center;
  width: 1.15rem;
  height: 1.15rem;
  border-radius: 50%;
  background: rgba(34, 197, 94, 0.15);
  border: 1px solid rgba(34, 197, 94, 0.35);
  color: #22c55e;
  flex-shrink: 0;
  margin-top: 0.1rem;
}

.plan-card__servicio-item--vacio {
  color: var(--gb-text-muted);
  font-style: italic;
}

.plan-card__pie {
  display: flex;
  align-items: stretch;
  gap: 0.65rem;
  padding-top: 1rem;
}

.plan-card__btn-whatsapp {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  background-color: rgba(37, 211, 102, 0.12);
  border-color: rgba(37, 211, 102, 0.35);
  color: #25d366;
  font-size: var(--gb-tipo-xs);
  padding-inline: 0.85rem;
}

.plan-card__acciones-secundarias {
  display: flex;
  align-items: center;
  gap: 0.45rem;
}

.plan-card__btn-editar {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: var(--gb-tipo-xs);
  padding-inline: 0.9rem;
}

.plan-card__btn-eliminar {
  display: grid;
  place-items: center;
  width: 2.6rem;
  height: 2.6rem;
  padding: 0;
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
}

@media (max-width: 28rem) {
  .plan-card {
    padding: 1.15rem;
  }

  .plan-card__pie {
    flex-direction: column;
    align-items: stretch;
  }

  .plan-card__btn-whatsapp {
    width: 100%;
  }

  .plan-card__acciones-secundarias {
    width: 100%;
    justify-content: space-between;
  }

  .plan-card__btn-editar {
    flex: 1;
    justify-content: center;
  }
}
</style>
