<script setup>
import {
  Building2,
  Calendar,
  CheckCircle2,
  ExternalLink,
  FileBadge,
  Globe,
  Mail,
  MapPin,
  Phone,
  Shield,
  User,
  Zap,
} from 'lucide-vue-next'
import { RouterLink } from 'vue-router'

import { resolverUrlStorage } from '@/shared/utils/storage'

defineProps({
  empresa: {
    type: Object,
    default: () => ({}),
  },
})
</script>

<template>
  <div class="perfil-empresa gb-tarjeta" aria-label="Información de la sede">
    <header class="perfil-empresa__cabecera">
      <div class="perfil-empresa__icono-cabecera" aria-hidden="true">
        <Building2 :size="20" />
      </div>
      <div>
        <h2 class="perfil-empresa__titulo">Sede Vinculada (API)</h2>
        <p class="perfil-empresa__descripcion">
          Información corporativa y datos operativos de tu gimnasio en el sistema.
        </p>
      </div>
    </header>

    <div class="perfil-empresa__contenido">
      <!-- Tarjeta destacada de la empresa -->
      <div class="empresa-hero">
        <div class="empresa-hero__principal">
          <div v-if="empresa.logo" class="empresa-hero__logo-box">
            <img
              :src="resolverUrlStorage(empresa.logo)"
              :alt="`Logo de ${empresa.nombre}`"
              class="empresa-hero__logo"
              @error="(e) => (e.target.style.display = 'none')"
            />
          </div>
          <div class="empresa-hero__info">
            <span class="empresa-hero__badge">
              <CheckCircle2 :size="13" aria-hidden="true" /> Sede Oficial
            </span>
            <h3 class="empresa-hero__nombre">{{ empresa.nombre }}</h3>
            <p class="empresa-hero__ruc">
              {{ empresa.region ? `${empresa.region}, Perú · ` : '' }}RUC:
              {{ empresa.ruc ?? 'Sin información' }}
            </p>
          </div>
        </div>

        <div class="empresa-hero__plan-tag">
          <Zap :size="16" aria-hidden="true" />
          <span>{{ empresa.plan ?? 'Sin plan informado' }}</span>
        </div>
      </div>

      <!-- Ficha de detalles -->
      <dl class="empresa-detalles">
        <div v-if="empresa.nombre_gerente" class="empresa-detalles__fila">
          <dt><User :size="15" aria-hidden="true" /> Administrador / Gerente</dt>
          <dd>{{ empresa.nombre_gerente }}</dd>
        </div>

        <div class="empresa-detalles__fila">
          <dt><MapPin :size="15" aria-hidden="true" /> Dirección física</dt>
          <dd>{{ empresa.direccion ?? 'Sin información' }}</dd>
        </div>

        <div v-if="empresa.telefono" class="empresa-detalles__fila">
          <dt><Phone :size="15" aria-hidden="true" /> Teléfono de contacto</dt>
          <dd>{{ empresa.telefono }}</dd>
        </div>

        <div v-if="empresa.correo" class="empresa-detalles__fila">
          <dt><Mail :size="15" aria-hidden="true" /> Correo corporativo</dt>
          <dd>{{ empresa.correo }}</dd>
        </div>

        <div v-if="empresa.enlace_web" class="empresa-detalles__fila">
          <dt><Globe :size="15" aria-hidden="true" /> Sitio web oficial</dt>
          <dd>
            <a
              :href="empresa.enlace_web"
              target="_blank"
              rel="noopener noreferrer"
              class="empresa-link"
            >
              {{ empresa.enlace_web }}
              <ExternalLink :size="13" aria-hidden="true" />
            </a>
          </dd>
        </div>

        <div v-if="empresa.horario_sabado" class="empresa-detalles__fila">
          <dt><Calendar :size="15" aria-hidden="true" /> Horarios de atención</dt>
          <dd>
            Lunes a Viernes: 6:00 - 22:00 · Sáb: {{ empresa.horario_sabado }} · Dom:
            {{ empresa.horario_domingo }}
          </dd>
        </div>

        <div class="empresa-detalles__fila">
          <dt><FileBadge :size="15" aria-hidden="true" /> Plan SaaS activo</dt>
          <dd>
            {{ empresa.plan ?? 'Sin plan informado' }}
          </dd>
        </div>

        <div class="empresa-detalles__fila">
          <dt><Shield :size="15" aria-hidden="true" /> Permisos asignados</dt>
          <dd>Control de accesos, rutinas de ejercicios, planes de alimentación y reportes.</dd>
        </div>
      </dl>

      <!-- Enlace a gestión de empresa -->
      <div class="perfil-empresa__pie">
        <RouterLink
          :to="{ name: 'empresa-detalle', params: { id: empresa.id } }"
          class="btn btn-secondary"
        >
          <span>Ver ficha completa de la empresa</span>
          <ExternalLink :size="15" aria-hidden="true" />
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<style scoped>
.perfil-empresa {
  padding: 1.75rem;
  border-radius: var(--gb-radius-xl);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
}

.perfil-empresa__cabecera {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding-bottom: 1.25rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid var(--gb-border);
}

.perfil-empresa__icono-cabecera {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--gb-radius-lg);
  background-color: rgba(238, 255, 0, 0.12);
  color: var(--gb-accent);
  flex-shrink: 0;
}

.perfil-empresa__titulo {
  margin: 0;
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  text-transform: uppercase;
  color: var(--gb-text);
}

.perfil-empresa__descripcion {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.perfil-empresa__contenido {
  display: grid;
  gap: 1.5rem;
}

.empresa-hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1.25rem;
  padding: 1.5rem;
  border-radius: var(--gb-radius-lg);
  background: linear-gradient(135deg, var(--gb-surface-high) 0%, var(--gb-surface-highest) 100%);
  border: 1px solid var(--gb-border);
}

.empresa-hero__principal {
  display: flex;
  align-items: center;
  gap: 1.25rem;
  min-width: 0;
}

.empresa-hero__logo-box {
  display: grid;
  place-items: center;
  width: 4rem;
  height: 4rem;
  padding: 0.25rem;
  border-radius: var(--gb-radius-md);
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  overflow: hidden;
  flex-shrink: 0;
}

.empresa-hero__logo {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.empresa-hero__badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.2rem 0.55rem;
  border-radius: var(--gb-radius-pill);
  background-color: rgba(34, 197, 94, 0.15);
  color: #22c55e;
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.4rem;
}

.empresa-hero__nombre {
  margin: 0;
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-lg);
  font-weight: 900;
  text-transform: uppercase;
  color: var(--gb-text);
}

.empresa-hero__ruc {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
  font-family: monospace;
}

.empresa-hero__plan-tag {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.5rem 1rem;
  border-radius: var(--gb-radius-pill);
  background-color: rgba(238, 255, 0, 0.15);
  border: 1px solid rgba(238, 255, 0, 0.3);
  color: var(--gb-accent);
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-sm);
  font-weight: 800;
  text-transform: uppercase;
  white-space: nowrap;
}

.empresa-detalles {
  display: grid;
  gap: 1rem;
  margin: 0;
}

.empresa-detalles__fila {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--gb-border);
}

.empresa-detalles__fila:last-child {
  border-bottom: 0;
  padding-bottom: 0;
}

.empresa-detalles__fila dt {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gb-text-soft);
}

.empresa-detalles__fila dd {
  margin: 0;
  font-size: var(--gb-tipo-sm);
  color: var(--gb-text);
}

.empresa-link {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  color: var(--gb-accent);
  text-decoration: underline;
  text-underline-offset: 3px;
}

.empresa-link:hover {
  color: var(--gb-accent-hover);
}

.perfil-empresa__pie {
  display: flex;
  justify-content: flex-end;
  padding-top: 1rem;
  border-top: 1px solid var(--gb-border);
}

.perfil-empresa__pie .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

@media (max-width: 48rem) {
  .perfil-empresa {
    padding: 1.25rem;
  }

  .empresa-hero {
    flex-direction: column;
    align-items: flex-start;
  }

  .empresa-hero__principal {
    flex-direction: column;
    align-items: flex-start;
  }

  .perfil-empresa__pie .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
