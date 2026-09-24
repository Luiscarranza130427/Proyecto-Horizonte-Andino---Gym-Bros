import { sep } from 'node:path'
import { fileURLToPath, URL } from 'node:url'

import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

/**
 * Retira del build los chunks de `src/mocks/` que nadie referencia.
 *
 * Los servicios cargan sus mocks con `import()` dentro de `if (USE_MOCKS)`. En
 * un build de producción esa condición se pliega a `false` (ver `src/config/env.js`)
 * y Rollup elimina la rama, pero el chunk del mock ya se había creado al construir
 * el grafo de módulos: se quedaba en `dist/` como archivo huérfano, con los datos
 * simulados y las credenciales de demostración dentro, accesible por URL aunque
 * la aplicación no lo cargue nunca.
 *
 * Sólo borra chunks originados en `src/mocks/` y sólo si ningún otro chunk los
 * importa. En un build con VITE_USE_MOCKS=true sí están referenciados, así que
 * este plugin no toca nada y el modo mock sigue funcionando.
 */
function descartarMocksHuerfanos() {
  return {
    name: 'gymbros:descartar-mocks-huerfanos',
    apply: 'build',
    generateBundle(_opciones, bundle) {
      // Se normalizan las barras: en Windows el id puede venir con separador
      // inverso y la comprobación fallaría en silencio.
      const esMock = (salida) =>
        salida.type === 'chunk' &&
        Boolean(salida.facadeModuleId?.split(sep).join('/').includes('/mocks/'))

      const candidatos = Object.entries(bundle).filter(([, salida]) => esMock(salida))
      if (!candidatos.length) return

      /*
       * Se inspecciona el CÓDIGO emitido, no los metadatos del bundle: rolldown
       * sigue listando el mock en `dynamicImports` del chunk que lo importaba
       * aunque el `import()` haya desaparecido al plegarse `USE_MOCKS` a false.
       * Fiarse de esos metadatos hacía que este plugin no borrase nunca nada.
       *
       * Se excluyen los propios mocks del texto examinado: si uno huérfano
       * importase a otro, no deben mantenerse vivos entre ellos.
       */
      const codigoAjeno = Object.values(bundle)
        .filter((salida) => salida.type === 'chunk' && !esMock(salida))
        .map((salida) => salida.code)
        .join(' ')

      const descartados = candidatos
        .map(([nombre]) => nombre)
        .filter((nombre) => !codigoAjeno.includes(nombre.split('/').pop()))

      descartados.forEach((nombre) => delete bundle[nombre])

      // Se deja constancia: un paso de build que borra archivos en silencio es
      // indistinguible de uno que no se ha ejecutado.
      if (descartados.length) {
        this.warn(`Mocks fuera del build (${descartados.length}): ${descartados.join(', ')}`)
      }
    },
  }
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [vue(), descartarMocksHuerfanos()],
  resolve: {
    // Alias `@` -> src. Permite `import api from '@/services/api'` en lugar de
    // rutas relativas frágiles como '../../../services/api'.
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        /*
         * Bootstrap 5.3 sigue escrito con `@import` y la función `if()` de Sass,
         * ambos marcados como obsoletos en Dart Sass. Son avisos de código de
         * terceros que no podemos corregir y que en cada build tapaban la salida
         * útil. Se silencian sólo estas dos categorías: cualquier otro aviso de
         * Sass, incluidos los de nuestro propio SCSS, sigue viéndose.
         */
        silenceDeprecations: ['import', 'if-function', 'global-builtin', 'color-functions'],
      },
    },
  },
  server: {
    port: 5173,
    /*
     * En desarrollo el panel llama a `/api` y pide imágenes a `/storage` en su
     * propio origen, y Vite lo reenvía a Laravel. Así no hay IP de red fija en
     * el código ni en `.env`: antes `VITE_API_BASE_URL` apuntaba a una IP LAN
     * que dejaba de existir al cambiar de red y el panel entero caía.
     *
     * `changeOrigin: false` conserva el Host del panel: Laravel construye las
     * URLs de imágenes (`foto_perfil_url`, `logo_url`...) con ese origen y
     * también pasan por este proxy, desde este equipo o desde otro de la red.
     */
    proxy: Object.fromEntries(
      ['/api', '/storage'].map((ruta) => [
        ruta,
        {
          target:
            loadEnv(mode, process.cwd(), 'VITE_').VITE_API_PROXY_TARGET || 'http://127.0.0.1:8000',
          changeOrigin: false,
        },
      ]),
    ),
  },
}))
