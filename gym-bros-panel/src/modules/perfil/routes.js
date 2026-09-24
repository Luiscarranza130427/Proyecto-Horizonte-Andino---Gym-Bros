export const perfilRoutes = [
  {
    path: 'perfil',
    name: 'perfil',
    component: () => import('@/modules/perfil/views/PerfilView.vue'),
    meta: {
      title: 'Mi perfil',
      requiresAuth: true,
    },
  },
]
