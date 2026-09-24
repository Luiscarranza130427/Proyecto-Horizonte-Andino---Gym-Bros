import { storeToRefs } from 'pinia'

import { useTenantStore } from '@/core/tenant/tenant.store'

export function useTenant() {
  const store = useTenantStore()
  const { tenant, tenantId, nombreTenant, esActivo, cargando } = storeToRefs(store)

  return {
    tenant,
    tenantId,
    nombreTenant,
    esActivo,
    cargando,
    cargarTenant: store.cargarTenant,
    fijarTenant: store.fijarTenant,
    limpiarTenant: store.limpiarTenant,
  }
}
