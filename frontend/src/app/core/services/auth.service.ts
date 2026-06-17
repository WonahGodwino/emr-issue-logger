import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, map } from 'rxjs';
import { tap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface User {
  id: string; userId: string; username: string; email: string;
  fullName: string; role: 'user' | 'admin' | 'super_admin'; createdAt: string;
}

export interface AuthResponse {
  accessToken: string; refreshToken: string; user: User;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    const user = localStorage.getItem('user');
    if (user) this.currentUserSubject.next(JSON.parse(user));
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${environment.apiUrl}/auth/login`, { email, password })
      .pipe(tap(response => {
        localStorage.setItem('accessToken', response.accessToken);
        localStorage.setItem('refreshToken', response.refreshToken);
        localStorage.setItem('user', JSON.stringify(response.user));
        this.currentUserSubject.next(response.user);
      }));
  }

  register(username: string, email: string, password: string, fullName: string): Observable<any> {
    return this.http.post(`${environment.apiUrl}/auth/register`, { username, email, password, fullName });
  }

  logout(): void { localStorage.clear(); this.currentUserSubject.next(null); }
  
  refreshToken(): Observable<any> {
    return this.http.post<{accessToken: string}>(`${environment.apiUrl}/auth/refresh`, {
      refreshToken: localStorage.getItem('refreshToken')
    }).pipe(tap(res => {
      localStorage.setItem('accessToken', res.accessToken);
    }));
  }

  isAuthenticated(): boolean { return !!localStorage.getItem('accessToken'); }
  isLoggedIn(): boolean { return this.isAuthenticated(); }
  getCurrentUser(): User | null { return this.currentUserSubject.value; }
  getAccessToken(): string | null { return localStorage.getItem('accessToken'); }
  
  getRole(): string | null {
    const user = this.getCurrentUser();
    return user ? user.role : null;
  }
  
  isAdmin(): boolean { const role = this.getRole(); return role === 'admin' || role === 'super_admin'; }
  isSuperAdmin(): boolean { return this.getRole() === 'super_admin'; }
}