import { useTenantStore } from '@/core/tenant/tenant.store'

export async function guardTenant(to) {
  if (to.meta.requiresTenant) {
    const tenantStore = useTenantStore()
    if (!tenantStore.tenant) {
      await tenantStore.cargarTenant()
    }
  }
  return true
}
