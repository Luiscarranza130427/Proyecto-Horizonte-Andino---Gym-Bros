export const bannersRoutes = [
  {
    path: 'banners',
    name: 'banners',
    redirect: { name: 'banners-listado' },
    meta: { title: 'Banners', requiresAuth: true },
    children: [
      {
        path: '',
        name: 'banners-listado',
        component: () => import('@/modules/banners/views/BannersView.vue'),
        meta: { title: 'Banners', requiresAuth: true },
      },
    ],
  },
]
