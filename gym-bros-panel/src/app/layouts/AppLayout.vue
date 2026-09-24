<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import AuthLayout from '@/app/layouts/AuthLayout.vue'
import DashboardLayout from '@/app/layouts/DashboardLayout.vue'
import PlatformLayout from '@/app/layouts/PlatformLayout.vue'
import TenantLayout from '@/app/layouts/TenantLayout.vue'

const route = useRoute()

const layoutActual = computed(() => {
  if (route.meta.layout === 'auth') return AuthLayout
  if (route.meta.layout === 'platform') return PlatformLayout
  if (route.meta.layout === 'tenant') return TenantLayout
  return DashboardLayout
})
</script>

<template>
  <component :is="layoutActual" />
</template>
