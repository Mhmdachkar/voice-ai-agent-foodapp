export type UserRole = 'customer' | 'admin' | 'driver';

export const USER_ROLES: UserRole[] = ['customer', 'admin', 'driver'];

export const userRoleDisplayName: Record<UserRole, string> = {
  customer: 'Customer',
  admin: 'Admin',
  driver: 'Driver',
};

export const userRoleIconName: Record<UserRole, string> = {
  customer: 'person', // you can map to an icon library name
  admin: 'shield',
  driver: 'car',
};

