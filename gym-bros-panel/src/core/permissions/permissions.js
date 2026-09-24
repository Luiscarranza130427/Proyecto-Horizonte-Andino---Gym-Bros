/**
 * Vocabulario cerrado de permisos RBAC del sistema SaaS Gym Bros.
 */
export const PERMISOS = {
  // Usuarios y Personal
  USERS_READ: 'users.read',
  USERS_CREATE: 'users.create',
  USERS_UPDATE: 'users.update',
  USERS_DELETE: 'users.delete',

  // Ejercicios y Rutinas
  EXERCISES_READ: 'exercises.read',
  EXERCISES_CREATE: 'exercises.create',
  EXERCISES_UPDATE: 'exercises.update',
  EXERCISES_DELETE: 'exercises.delete',

  // Nutrición y Alimentación
  NUTRITION_READ: 'nutrition.read',
  NUTRITION_MANAGE: 'nutrition.manage',

  // Membresías de Gimnasio
  MEMBERSHIPS_READ: 'memberships.read',
  MEMBERSHIPS_MANAGE: 'memberships.manage',

  // Notificaciones
  NOTIFICATIONS_READ: 'notifications.read',
  NOTIFICATIONS_SEND: 'notifications.send',

  // Plataforma SaaS (Super Admin)
  COMPANIES_MANAGE: 'companies.manage',
  SUBSCRIPTIONS_MANAGE: 'subscriptions.manage',
  BILLING_MANAGE: 'billing.manage',
  AUDIT_READ: 'audit.read',
  PLATFORM_METRICS: 'platform.metrics',
}
