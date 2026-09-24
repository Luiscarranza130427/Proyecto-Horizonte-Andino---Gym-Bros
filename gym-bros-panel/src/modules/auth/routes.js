export const authRoutes = [
  {
    path: '/login',
    component: () => import('@/app/layouts/AuthLayout.vue'),
    children: [
      {
        path: '',
        name: 'login',
        component: () => import('@/modules/auth/views/LoginView.vue'),
        meta: { guestOnly: true, title: 'Iniciar sesión' },
      },
    ],
  },
  {
    path: '/restablecer-contrasena',
    component: () => import('@/app/layouts/AuthLayout.vue'),
    children: [
      {
        path: '',
        name: 'restablecer-contrasena',
        component: () => import('@/modules/auth/views/ResetPasswordView.vue'),
        meta: { title: 'Restablecer contraseña' },
      },
    ],
  },
]
