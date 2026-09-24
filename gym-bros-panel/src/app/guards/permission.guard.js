import { useAuthStore } from '@/core/auth/auth.store'

export function guardPermiso(to) {
  if (to.meta.permission) {
    const auth = useAuthStore()
    if (!auth.can(to.meta.permission)) {
      return { name: 'forbidden' }
    }
  }
  return true
}
