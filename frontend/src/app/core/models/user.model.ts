export interface User {
  id: string; userId: string; username: string; email: string;
  fullName: string; role: 'user' | 'admin'; createdAt: string;
  updatedAt: string; isActive: boolean;
}
