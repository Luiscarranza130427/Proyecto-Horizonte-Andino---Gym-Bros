<script setup>
import { Eye, Pencil } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import { UNIDADES, etiquetaDe } from '@/modules/alimentacion/catalogos'
import AlimentoTipoBadge from '@/modules/alimentacion/components/AlimentoTipoBadge.vue'
import { formatearNumero } from '@/shared/utils/formato'

/**
 * El catálogo se muestra en tarjetas y no en tabla porque de un alimento se
 * consultan cinco cifras del mismo tipo —energía y cuatro macros— que se leen
 * mejor agrupadas por alimento que repartidas en columnas.
 *
 * Las tarjetas no ofrecen retirar del catálogo: esa acción depende de `usos`,
 * que sólo trae la ficha, y un botón que va a fallar es peor que no tenerlo.
 */
const props = defineProps({
  items: { type: Array, required: true },
  paginacion: { type: Object, required: true },
  cargando: { type: Boolean, default: false },
})

defineEmits(['cambiar-pagina'])

const paginas = computed(() => {
  const total = props.paginacion.ultimaPagina
  const actual = props.paginacion.pagina
  if (total <= 5) return Array.from({ length: total }, (_, indice) => indice + 1)

  let inicio = Math.max(1, actual - 2)
  const fin = Math.min(total, inicio + 4)
  inicio = Math.max(1, fin - 4)
  return Array.from({ length: fin - inicio + 1 }, (_, indice) => inicio + indice)
})

/**
 * Referencia de los macros: `g` o `ml` según en qué se mida el alimento.
 * Sin ella las cifras no significan nada, porque todas son «por 100».
 */
function unidad(alimento) {
  return etiquetaDe(UNIDADES, alimento.unidadBase)
}
</script>

<template>
  <section class="rejilla gb-tarjeta" aria-labelledby="titulo-rejilla" :aria-busy="cargando">
    <!-- El título nombra la región y evita que las tarjetas (h3) cuelguen
         directamente del h1 de la página, saltándose un nivel. -->
    <h2 id="titulo-rejilla" class="visually-hidden">Alimentos del catálogo</h2>

    <ul v-if="cargando" class="rejilla__lista" aria-hidden="true">
      <li v-for="tarjeta in 6" :key="tarjeta" class="tarjeta tarjeta--esqueleto">
        <span class="esqueleto esqueleto--titulo"></span>
        <span class="esqueleto esqueleto--energia"></span>
        <span class="esqueleto"></span>
        <span class="esqueleto esqueleto--corto"></span>
      </li>
    </ul>

    <ul v-else class="rejilla__lista">
      <li v-for="alimento in items" :key="alimento.id">
        <article class="tarjeta">
          <header class="tarjeta__cabecera">
            <h3>
              <RouterLink :to="{ name: 'alimento-detalle', params: { id: alimento.id } }">
                {{ alimento.nombre }}
              </RouterLink>
            </h3>
            <AlimentoTipoBadge :tipo="alimento.tipo" />
          </header>

          <p class="tarjeta__energia">
            <strong>{{ formatearNumero(alimento.calorias) }}</strong>
            <span>kcal por 100 {{ unidad(alimento) }}</span>
          </p>

          <dl class="tarjeta__macros">
            <div>
              <dt>Proteínas</dt>
              <dd>{{ formatearNumero(alimento.proteinas) }} g</dd>
            </div>
            <div>
              <dt>Carbohidratos</dt>
              <dd>{{ formatearNumero(alimento.carbohidratos) }} g</dd>
            </div>
            <div>
              <dt>Grasas</dt>
              <dd>{{ formatearNumero(alimento.grasas) }} g</dd>
            </div>
            <div>
              <dt>Fibra</dt>
              <dd>{{ formatearNumero(alimento.fibra) }} g</dd>
            </div>
          </dl>

          <footer class="tarjeta__pie">
            <div class="tarjeta__acciones">
              <RouterLink
                class="gb-boton-icono"
                :to="{ name: 'alimento-detalle', params: { id: alimento.id } }"
                :aria-label="`Ver ${alimento.nombre}`"
                title="Ver"
              >
                <Eye :size="16" aria-hidden="true" />
              </RouterLink>
              <RouterLink
                class="gb-boton-icono"
                :to="{ name: 'alimento-editar', params: { id: alimento.id } }"
                :aria-label="`Editar ${alimento.nombre}`"
                title="Editar"
              >
                <Pencil :size="16" aria-hidden="true" />
              </RouterLink>
            </div>
          </footer>
        </article>
      </li>
    </ul>

    <footer v-if="!cargando && paginacion.total" class="rejilla__paginacion">
      <p>
        Mostrando {{ formatearNumero(paginacion.desde) }}–{{ formatearNumero(paginacion.hasta) }} de
        {{ formatearNumero(paginacion.total) }} alimentos
      </p>
      <nav aria-label="Paginación del catálogo">
        <button
          type="button"
          class="btn btn-ghost"
          :disabled="paginacion.pagina <= 1"
          @click="$emit('cambiar-pagina', paginacion.pagina - 1)"
        >
          Anterior
        </button>
        <button
          v-for="pagina in paginas"
          :key="pagina"
          type="button"
          class="rejilla__pagina"
          :class="{ 'rejilla__pagina--activa': pagina === paginacion.pagina }"
          :aria-current="pagina === paginacion.pagina ? 'page' : null"
          :aria-label="`Página ${pagina}`"
          @click="$emit('cambiar-pagina', pagina)"
        >
          {{ pagina }}
        </button>
        <button
          type="button"
          class="btn btn-ghost"
          :disabled="paginacion.pagina >= paginacion.ultimaPagina"
          @click="$emit('cambiar-pagina', paginacion.pagina + 1)"
        >
          Siguiente
        </button>
      </nav>
    </footer>
  </section>
</template>

<style scoped>
.rejilla {
  overflow: hidden;
  border-radius: var(--gb-radius-lg);
}

.rejilla__lista {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(17rem, 1fr));
  gap: 0.875rem;
  margin: 0;
  padding: 0.875rem;
  list-style: none;
}

.tarjeta {
  display: grid;
  align-content: start;
  gap: 0.75rem;
  height: 100%;
  padding: 1rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  transition: border-color 0.18s ease;
}

.tarjeta:hover {
  border-color: var(--gb-text-muted);
}

.tarjeta__cabecera {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.5rem;
}

.tarjeta__cabecera h3 {
  margin: 0;
  min-width: 0;
  font-size: var(--gb-tipo-base);
  line-height: 1.3;
}

.tarjeta__cabecera a {
  color: var(--gb-text);
  text-decoration: none;
}

.tarjeta__cabecera a:hover {
  color: var(--gb-red-text);
}

.tarjeta__energia {
  display: flex;
  align-items: baseline;
  gap: 0.375rem;
  margin: 0;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid var(--gb-border);
}

.tarjeta__energia strong {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-xl);
  font-variant-numeric: tabular-nums;
  font-weight: 800;
  line-height: 1;
}

.tarjeta__energia span {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.tarjeta__macros {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.625rem 0.75rem;
  margin: 0;
}

.tarjeta__macros dt {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.tarjeta__macros dd {
  margin: 0.125rem 0 0;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
  font-variant-numeric: tabular-nums;
}

.tarjeta__pie {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  padding-top: 0.75rem;
  border-top: 1px solid var(--gb-border);
}

.tarjeta__acciones {
  display: flex;
  gap: 0.25rem;
}

.tarjeta__acciones .gb-boton-icono {
  width: 2.125rem;
  height: 2.125rem;
  color: var(--gb-text-muted);
  text-decoration: none;
}

.tarjeta--esqueleto {
  gap: 0.875rem;
}

.esqueleto {
  display: block;
  width: 100%;
  height: 0.75rem;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
  animation: pulso 1.2s ease-in-out infinite alternate;
}

.esqueleto--titulo {
  width: 70%;
  height: 1rem;
}

.esqueleto--energia {
  width: 45%;
  height: 2rem;
  border-radius: var(--gb-radius);
}

.esqueleto--corto {
  width: 55%;
}

@keyframes pulso {
  to {
    opacity: 0.45;
  }
}

.rejilla__paginacion {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1rem;
  background-color: var(--gb-surface-lowest);
  border-top: 1px solid var(--gb-border);
}

.rejilla__paginacion p {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.rejilla__paginacion nav {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.rejilla__paginacion .btn {
  min-height: 2.125rem;
  padding: 0.375rem 0.75rem;
  font-size: var(--gb-tipo-xxs);
}

.rejilla__pagina {
  display: grid;
  place-items: center;
  width: 2.125rem;
  height: 2.125rem;
  background-color: transparent;
  border: 1px solid transparent;
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.rejilla__pagina:hover {
  background-color: var(--gb-surface-high);
  color: var(--gb-text);
}

.rejilla__pagina--activa {
  background-color: var(--gb-red);
  color: var(--gb-on-red);
}

@media (max-width: 58rem) {
  .rejilla__paginacion {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
