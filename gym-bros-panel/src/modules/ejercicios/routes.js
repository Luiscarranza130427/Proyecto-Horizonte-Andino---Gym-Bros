export const ejerciciosRoutes = [
  {
    path: 'ejercicios',
    name: 'ejercicios',
    redirect: { name: 'ejercicios-listado' },
    meta: { title: 'Ejercicios', requiresAuth: true },
    children: [
      {
        path: '',
        name: 'ejercicios-listado',
        component: () => import('@/modules/ejercicios/views/EjerciciosView.vue'),
        meta: { title: 'Ejercicios', requiresAuth: true },
      },
      {
        path: 'nuevo',
        name: 'ejercicio-nuevo',
        component: () => import('@/modules/ejercicios/views/EjercicioCreateView.vue'),
        meta: { title: 'Nuevo ejercicio', requiresAuth: true },
      },
      {
        path: ':id',
        name: 'ejercicio-detalle',
        component: () => import('@/modules/ejercicios/views/EjercicioDetailView.vue'),
        props: true,
        meta: { title: 'Detalle ejercicio', requiresAuth: true },
      },
      {
        path: ':id/editar',
        name: 'ejercicio-editar',
        component: () => import('@/modules/ejercicios/views/EjercicioEditView.vue'),
        props: true,
        meta: { title: 'Editar ejercicio', requiresAuth: true },
      },
    ],
  },
]
