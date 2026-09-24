import { APP_NAME } from '@/core/config/env'

export function aplicarTitulo(to, _from, fallo) {
  if (fallo) return
  document.title = to.meta.title ? `${to.meta.title} | ${APP_NAME}` : APP_NAME
}
